//
//  ViewController.m
//  
//
//  Created by Steve Wart on 10-08-15.
//  Copyright Steven Wart 2010. All rights reserved.
//

#import "ViewController.h"
#import "ViewController.h"

#import "ChessBoard.h"
#import "ChessPlayer.h"
#import "ChessPieceLayer.h"
#import "SquareLayer.h"
#import "ChessPlayerAI.h"
#import "ChessMove.h"
#import "ChessMoveList.h"
#import "ChessMoveGenerator.h"


const int kDestinationSquareMask = 0x3F;        // lower six bits of least significant byte is destination square (0-63)
const int kSourceSquareMask = 0x3F00;           // lower six bits of second byte is source square (0-63)
const int kMovingPieceMask = 0x070000;          // lower three bits of third byte is moving piece (0-6)
const int kCapturedPieceMask = 0x07000000;      // lower three bits of most significant byte is captured piece (0-6)
const int kGameEventTypeMask = 0xF0000000;      // upper four bits of most significant byte is move type (0-15)

@interface ViewController(Private)
- (void)addGameLayer;
- (float)boardWidth;
- (float)cellWidth;
- (float)playerWidth;
- (int)squareIndexForLayerLocation:(CGPoint)screenLoc;
- (CGPoint)centerPointOfCellForBoardIndex:(CGPoint)boardPoint;
- (void)updateBoardTransforms;
- (void)updatePlayerLabels;
- (void)switchSides;
- (void)playOnline;
- (void)startNewGame;
- (void)applyStartNewGame;
- (void)applyUndoMove;
- (void)receivedGameEvent:(GameEvent)gameEvent;
- (void)resolvePlayerSides;

@end

#pragma mark ===
@implementation ViewController

@synthesize history, redoList, board, usePopoverController, remoteInstanceName;

#pragma mark Action Sheet delegate

#pragma mark initialize

-(BOOL)isWhiteCell:(int)index {
    
    int row = index / 8;
    int col = index % 8;
    
    return ((row % 2) && !(col % 2)) || (!(row % 2) && (col % 2));
}

-(void)updateBoardTransforms {
    
    CGFloat boardRotation = boardDirection > 0 ? 0.0 : M_PI;
    
    boardTransform = CATransform3DMakeRotation(boardRotation, 0.0, 0.0, 1.0);
    boardTransform = CATransform3DScale(boardTransform, boardScale, boardScale, 1.0);
    playerTransform = CATransform3DMakeScale(boardDirection, boardDirection, 1.0);    
    
    boardLayer.transform = boardTransform;
    
    for (int i=0; i < 64; i++) {
        SquareLayer *squareLayer = [squares objectAtIndex:i];
        squareLayer.pieceLayer.transform = playerTransform;
    }

    for (int i=0; i < 16; i++) {
        CATextLayer *labelLayer = [labels objectAtIndex:i];
        labelLayer.transform = playerTransform;
    }
}

-(void)updatePlayerLabels {
    
    BOOL localPlayerHasGameKitAlias = NO;   // todo: check if GKLocalPlayer is authenticated
    
    NSString *localPlayerLabel = localPlayerHasGameKitAlias ? @"alias" : NSUserName();
    NSString *opponentLabel = @"Computer";

    if (boardDirection > 0) {
        blackPlayerLabel.text = opponentLabel;
        whitePlayerLabel.text = localPlayerLabel;
    }
    else {
        whitePlayerLabel.text = opponentLabel;
        blackPlayerLabel.text = localPlayerLabel;
    }
}

//
// the argument is the color of the last player to move
//
-(void)updateBoardLabels:(BOOL)white {
	
	NSString *message = white ? @"Black to move" : @"White to move";
	NSArray *moves;
	
	if (white) {
		moves = [board.blackPlayer findValidMoves];
	}
	else {
		moves = [board.whitePlayer findValidMoves];
	}
	
	if (moves == nil) {
		message = @"Checkmate";
	}
	else if ([moves count] == 0) {
		message = @"Stalemate";
	}
	
	gameStatusLabel.text = message;
}

-(void)removeLabels {
    
    for (CATextLayer *labelLayer in labels) {
        [labelLayer removeFromSuperlayer];
    }
    
    [labels removeAllObjects];
}

-(void)addLabels {
    
    labels = [NSMutableArray arrayWithCapacity:16];
    [labels retain];
    
    CGFloat w = [self cellWidth];

    for (int i = 0; i < 8; i++) {
        
        CATextLayer *labelLayer = [CATextLayer layer];
        labelLayer.foregroundColor = [UIColor darkGrayColor].CGColor;
        
        CGPoint loc = [self centerPointOfCellForBoardIndex:CGPointMake(i, -1)];
        loc.y = loc.y + 9.0f;
        
        labelLayer.position = loc;
        labelLayer.string = [NSString stringWithFormat:@"%c",'A' + (i & 7)];
        labelLayer.bounds = CGRectMake(0, 0, 18.0f, 18.0f);
        labelLayer.alignmentMode = kCAAlignmentCenter;
        labelLayer.fontSize = 12.0f;
        
//        labelLayer.borderColor = [UIColor greenColor].CGColor;
//        labelLayer.borderWidth = 1.0;
        
        [boardLayer addSublayer:labelLayer];
        [labels addObject:labelLayer];
    }
    
    for (int i = 0; i < 8; i++) {
        
        CATextLayer *labelLayer = [CATextLayer layer];
        labelLayer.foregroundColor = [UIColor darkGrayColor].CGColor;
        
        CGPoint loc = [self centerPointOfCellForBoardIndex:CGPointMake(-1, i)];
        loc.x = loc.x + w/2 - 9.0;
        
        labelLayer.position = loc;
        labelLayer.string = [NSString stringWithFormat:@"%c",'1' + i];
        labelLayer.bounds = CGRectMake(0, 0, 18.0f, 18.0f);
        labelLayer.alignmentMode = kCAAlignmentCenter;
        labelLayer.fontSize = 12.0f;
       
//        labelLayer.borderColor = [UIColor yellowColor].CGColor;
//        labelLayer.borderWidth = 1.0;
        
        [boardLayer addSublayer:labelLayer];
        [labels addObject:labelLayer];
    }
}

-(void)addSquares {
    
    CGColorRef white = [UIColor whiteColor].CGColor;
    CGColorRef black = [UIColor lightGrayColor].CGColor;
    
    squares = [NSMutableArray arrayWithCapacity:64];
    [squares retain];
    
    CGFloat w = [self cellWidth];
    
    for (int index = 0; index < 64; index++) {
        
        SquareLayer *square = [SquareLayer layer];
        square.bounds = CGRectMake(0, 0, w, w);
        
        square.backgroundColor = [self isWhiteCell:index] ? white : black;
        square.borderColor = [UIColor redColor].CGColor;
        
        square.squarePosition = index;
        [squares addObject:square];
        square.name = [NSString stringWithFormat:@"%c%c",'a' + (index & 7), '1' + (index >> 3)];
        float x = index % 8;
        float y = index / 8;
        CGPoint loc = [self centerPointOfCellForBoardIndex:(CGPointMake(x, y))];
        square.position = loc;
        
        [boardLayer addSublayer:square];
    }
}

static NSString *imageNames[12] = {
    @"whitePawnImage.png",
    @"whiteKnightImage.png",
    @"whiteBishopImage.png",
    @"whiteRookImage.png",
    @"whiteQueenImage.png",
    @"whiteKingImage.png",
    
    @"blackPawnImage.png",
    @"blackKnightImage.png",
    @"blackBishopImage.png",
    @"blackRookImage.png",
    @"blackQueenImage.png",
    @"blackKingImage.png"    
};

-(ChessPieceLayer *)newPiece:(int)piece white:(BOOL)isWhite {
    
    int index = isWhite ? piece - 1 : piece + 5;
    
    ChessPieceLayer *m = [[ChessPieceLayer alloc] init];
    UIImage *image = [UIImage imageNamed:(imageNames[index])];
    m.contents = (id)image.CGImage;
    m.isWhite = isWhite;
    m.piece = piece;
    CGFloat w = [self cellWidth];
    m.bounds = CGRectMake(0,0, w, w);
    m.shadowColor = [UIColor blackColor].CGColor;
    m.transform = playerTransform;
    
    [boardLayer addSublayer:m];
    
    return m;
}

#pragma mark ===
#pragma mark ChessUserAgent protocol

-(void)gameReset {
    
    // disable animations for game reset
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    for (SquareLayer *square in squares) {
        if (square.pieceLayer) {
            [square.pieceLayer removeFromSuperlayer];
            [square setNeedsDisplay];
            square.pieceLayer = nil;
        }
        square.borderWidth = 0;
    }
    
    [CATransaction commit];
}

-(void)addedPiece:(NSNotification *)notification {
  NSDictionary *description = notification.object;
  NSNumber *piece = [description objectForKey:@"piece"];
  NSNumber *square = [description objectForKey:@"square"];
  NSNumber *white = [description objectForKey:@"white"];
  [self addedPiece:[piece intValue] at:[square intValue] white:[white boolValue]];
}

-(void)addedPiece:(int)piece at:(int)square white:(BOOL)isWhite {
    
    ChessPieceLayer *m = [[self newPiece:piece white:isWhite] autorelease];
    m.chessBoard = self;
    SquareLayer *s = [squares objectAtIndex:square];
    m.position = s.position;
    s.pieceLayer = m;
}

-(void)completedMove:(NSNotification *)notification {
  NSDictionary *description = notification.object;
  ChessMove *move = [description objectForKey:@"move"];
  NSNumber *white = [description objectForKey:@"white"];
  [self completedMove:move white:[white boolValue]];
}

-(void)completedMove:(ChessMove *)move white:(BOOL)aBool {
    
  if (!board)
      return;
  
  [history addObject:move];
  [undoButton setEnabled:YES];

  [self validateGamePosition];
	[self updateBoardLabels:aBool];
}

-(void)movedPiece:(NSNotification *)notification {
  NSDictionary *description = notification.object;
  NSNumber *piece = [description objectForKey:@"piece"];
  NSNumber *from = [description objectForKey:@"from"];
  NSNumber *to = [description objectForKey:@"to"];
  [self movedPiece:[piece intValue] from:[from intValue] to:[to intValue]];
}

-(void)movedPiece:(int)piece from:(int)sourceSquare to:(int)destSquare {
    
    SquareLayer *sourceSquareLayer = [squares objectAtIndex:sourceSquare];
    ChessPieceLayer *sourceLayer = sourceSquareLayer.pieceLayer;
    SquareLayer *destSquareLayer = [squares objectAtIndex:destSquare];
    
    sourceLayer.position = destSquareLayer.position;
    sourceSquareLayer.pieceLayer = nil;
    destSquareLayer.pieceLayer = sourceLayer;
}

-(void)removedPiece:(NSNotification *)notification {
  NSDictionary *description = notification.object;
  NSNumber *piece = [description objectForKey:@"piece"];
  NSNumber *square = [description objectForKey:@"square"];
  [self removedPiece:[piece intValue] at:[square intValue]];
}

-(void)removedPiece:(int)piece at:(int)square {
    
    SquareLayer *squareLayer = [squares objectAtIndex:square];
    [squareLayer.pieceLayer removeFromSuperlayer];
    [squareLayer setNeedsDisplay];
    squareLayer.pieceLayer = nil;
}

-(void)replacedPiece:(NSNotification *)notification {
  NSDictionary *description = notification.object;
  NSNumber *old = [description objectForKey:@"old"];
  NSNumber *new = [description objectForKey:@"new"];
  NSNumber *square = [description objectForKey:@"square"];
  NSNumber *white = [description objectForKey:@"white"];
  [self replacedPiece:[old intValue] with:[new intValue] at:[square intValue] white:[white boolValue]];
}

-(void)replacedPiece:(int)oldPiece with:(int)newPiece at:(int)square white:(BOOL)isWhitePlayer {
    
    [self removedPiece:oldPiece at:square];
    [self addedPiece:newPiece at:square white:isWhitePlayer];
}

//
// result == 0   : white lost
// result == 0.5 : draw
// result == 1   : white won
//
-(void)finishedGame:(NSNotification *)notification {
  NSDictionary *description = notification.object;
  NSNumber *white = [description objectForKey:@"white"];
  NSNumber *stalemate = [description objectForKey:@"stalemate"];

  self.board = nil;
}

-(void)undoMove:(NSNotification *)notification {
  NSDictionary *description = notification.object;
  ChessMove *move = [description objectForKey:@"move"];
  NSNumber *white = [description objectForKey:@"white"];
  [self undoMove:move white:[white boolValue]];
}

-(void)undoMove:(ChessMove *)move white:(BOOL)isWhitePlayer {
    
    if (!board)
        return;
    
    [redoList addObject:move];
    [redoButton setEnabled:YES];
    
    [self validateGamePosition];
}

-(void)printBoard:(BOOL)isWhitePlayer {
    printf("\n === display ===");
    for (int i=0; i<64; i++) {
        if (0 == (i % 8)) {
            printf("\n");
        }
        SquareLayer *layer = [squares objectAtIndex:i];
        printf("%2d", layer.pieceLayer.piece);
    }
    printf("\n ===============\n");
}

-(void)printWhitePieces {
    printf("\n ==== white ====");
    for (int i=0; i<64; i++) {
        if (0 == (i % 8)) {
            printf("\n");
        }
        printf("%2d", board.whitePlayer.pieces[i]);
    }
    printf("\n ===============\n");
}

-(void)printBlackPieces {
    printf("\n ==== black ====");
    for (int i=0; i<64; i++) {
        if (0 == (i % 8)) {
            printf("\n");
        }
        printf("%2d", board.blackPlayer.pieces[i]);
    }
    printf("\n ===============\n");
}

//
// this method does nothing but validate what you see (on the screen) is what you get (from the board)
//
-(void)validateGamePosition {
    
#if __has_feature(objc_arc)
  NSLog(@"ARC is enabled");
#else
  NSLog(@"ARC is not enabled");
#endif

  for (int i=0; i<64; i++) {
        
        int piece = 0;
        BOOL screenIsWhite = NO;
        BOOL screenHasPiece = NO;
        
        SquareLayer *square = [squares objectAtIndex:i];
        
        if (square.pieceLayer) {
            screenHasPiece = YES;
            piece = square.pieceLayer.piece;
            screenIsWhite = [[NSNumber numberWithBool:square.pieceLayer.isWhite] boolValue];
        }
        
        int p = [board.whitePlayer pieceAt:i];
        
        if ([board.whitePlayer castlingRookSquare] == i) {
            p = kRook;
        }
        
        // 1. screen has a white piece at i
        if (screenHasPiece && screenIsWhite) {
            if (p != piece) {
                [self printBoard:screenIsWhite];
                [self printWhitePieces];
                NSLog(@"position %d broken: user agent piece (%d) does not match game model piece (%d)", i, piece, p);
                return;
            }
        }
        // 2. screen has a black piece or no piece at i but board has a white piece at i
        else if (p) {
            [self printBoard:screenIsWhite];
            [self printWhitePieces];
            NSLog(@"white broken: game model has a white piece at (%d)", i);
            return;
        }
        
        p = [board.blackPlayer pieceAt:i];
        
        if ([board.blackPlayer castlingRookSquare] == i) {
            p = kRook;
        }
        
        // 3. screen has a black piece at i
        if (screenHasPiece && !screenIsWhite) {
            if (p != piece) {
                [self printBoard:screenIsWhite];
                [self printBlackPieces];
                NSLog(@"position %d broken: user agent piece (%d) does not match game model piece (%d)", i, piece, p);
                return;
            }
        }
        // 4. screen has a white piece or no piece at i but board has a black piece at i
        else if (p) {
            [self printBoard:screenIsWhite];
            [self printBlackPieces];
            NSLog(@"black broken: game model has a black piece at (%d)", i);
            return;
        }
    }
}

#pragma mark ===
#pragma mark playing

-(IBAction)autoPlay {
    
    autoPlay = !autoPlay;
    if (autoPlay) {
        [self thinkAndMove];
    }
}

-(IBAction)play {
    
    [self thinkAndMove];
}

//
// hint
//
-(IBAction)findBestMove {
    
    if ([board.searchAgent isThinking])
        return;
    
    moveExpected = NO;
    [board.searchAgent startThinking];
}


-(void)startNewGame {
    [self applyStartNewGame];
}

-(void)applyStartNewGame {
    
  if (!board) {
    ChessBoard *newBoard = [[ChessBoard alloc] init];
    [newBoard resetGame];
    newBoard.hasUserAgent = YES;
    self.board = newBoard;
    [newBoard release];
  }
  [board initializeNewBoard];
  label.text = @"";
  autoPlay = NO;
  self.history = [NSMutableArray array];
  self.redoList = [NSMutableArray array];
  
  playerRandomChoice = 0;
  opponentRandomChoice = 0;
  
  [undoButton setEnabled:NO];
  [redoButton setEnabled:NO];
  
  [self validateGamePosition];
  if (board.activePlayer == board.whitePlayer && boardDirection < 0) {
    [board.searchAgent startThinking];
  }
}

-(IBAction)newGame {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Game Options" message:@"" preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Switch Sides" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self switchSides];
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Auto Play" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self autoPlay];
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Restart Board" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
    [self startNewGame];
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  
  [self presentViewController:alert animated:YES completion:nil];
}

-(void)movePieceFrom:(int)sourceSquare to:(int)destSquare {
    
  if (!board)
      return;
  
  // true if it's the computer's move
  // TODO: check if it's the online opponent's move
  if ([board.searchAgent isThinking])
      return;
  
  [board movePieceFrom:sourceSquare to:destSquare];
    
  moveExpected = YES;
  [board.searchAgent startThinking];
}

//
// redo the last undone move
//
-(IBAction)redoMove {
    
    if (0 == [redoList count])
        return;
    
    ChessMove *move = [redoList lastObject];
    [move retain];
    [redoList removeLastObject];
    
    if ([redoList count] == 0) {
        [redoButton setEnabled:NO];
    }
    
    [board nextMove:move];
    [move release];
}

//
// play
//
-(IBAction)thinkAndMove {
    
    if ([board.searchAgent isThinking])
        return;
    
    moveExpected = YES;
    [board.searchAgent startThinking];
}

-(NSString *)myColorLabel {
    return (boardDirection > 0) ? @"White" : @"Black";
}

//
// undo the last move
//
-(IBAction)undoMove {
    
    if (!board)
        return;
    
    if (0 == [history count])
        return;
    
  [self applyUndoMove];
}

-(void)applyUndoMove {
    
    ChessMove *move = [history lastObject];
    [move retain];
    [history removeLastObject];
    
    if ([history count] == 0) {
        [undoButton setEnabled:NO];
    }
    
    [board undoMove:move];
    [move release];
}

//
// flip the board upside down
//
-(void)switchSides {
    
  boardDirection *= -1;
  
  [self updateBoardTransforms];
  [self updatePlayerLabels];
  
  if ((board.activePlayer == board.whitePlayer && boardDirection < 0) ||
      (board.activePlayer == board.blackPlayer && boardDirection > 0)) {
    [self thinkAndMove];
  }
}

-(BOOL)isPlayerWhite {

    return boardDirection > 0;
}

#pragma mark Private

- (void)selectPlayer:(ChessPieceLayer *)playerLayer {
    if (selectedPlayer)
    {
        selectedPlayer.shadowOpacity = 0.0;
        selectedPlayer.zPosition -= 1;
        [selectedPlayer needsDisplay];
    }
    selectedPlayer = playerLayer;
    
    if (selectedPlayer)
    {
        selectedPlayer.shadowOpacity = 1.0;
        selectedPlayer.zPosition += 1;
        [selectedPlayer needsDisplay];
    }
}

- (ChessPieceLayer *)playerLayerAtTouchPoint:(CGPoint)touchPoint {
    
    for (SquareLayer *squareLayer in squares) {
        
        ChessPieceLayer *candidate = squareLayer.pieceLayer;
        
        if ((candidate != selectedPlayer) && [candidate hitTest:touchPoint]) {
            return candidate;
        }
    }
    return nil;
}

#pragma mark user feedback

-(void)showMovesAt:(int)square {
    
    if (!board)
        return;
    
    if ([board.searchAgent isThinking])
        return;
    
    // if human player is black, don't show moves for white pieces, and vice-versa
    if ((![board.activePlayer isWhitePlayer] && boardDirection > 0) ||
        ([board.activePlayer isWhitePlayer] && boardDirection < 0))
        return;
    
    for (int i=0; i<64; i++) {
        SquareLayer *squareLayer = [squares objectAtIndex:i];
        squareLayer.borderWidth = 0;
    }
    
    NSArray *list = [board.activePlayer findValidMovesAt:square];
    
    if (0 == [list count])
        return;
    
    SquareLayer *thisLayer = [squares objectAtIndex:square];
    thisLayer.borderWidth = 1.0;
    
    for (ChessMove *move in list) {
        SquareLayer *destLayer = [squares objectAtIndex:move.destinationSquare];
        destLayer.borderWidth = 1.0;
    }
}

-(void)showMovesFrom:(SquareLayer *)squareLayer {
    
    [self showMovesAt:squareLayer.squarePosition];
}

-(void)enteredSquare:(SquareLayer *)squareLayer {
    // TODO: wantsDroppedMorph
}

#pragma mark UITouch events

//
// only support single touch for now
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if ([board.searchAgent isThinking])
        return;
        
    UITouch *theTouch = [touches anyObject];
    if (nil == theTouch)
        return;

    CGPoint touchPoint = [theTouch locationInView:theTouch.view];
    touchPoint = [boardLayer convertPoint:touchPoint fromLayer:theTouch.view.layer];
    int startIndex = [self squareIndexForLayerLocation:touchPoint];
    
    // touch down outside of board
    if (startIndex < 0)
        return;
    
    selectionIndex = startIndex;
    
    // clear previous move indicators
    for (int i=0; i<64; i++) {
        SquareLayer *squareLayer = [squares objectAtIndex:i];
        squareLayer.borderWidth = 0;
    }
    
    [self selectPlayer:nil];
    
    SquareLayer *squareLayer = [squares objectAtIndex:selectionIndex];
    ChessPieceLayer *candidate = squareLayer.pieceLayer;
    [self selectPlayer:candidate];
    
    // need to be able to return piece to original position for invalid moves
    candidate.sourceSquare = squareLayer.squarePosition;
    
    [self showMovesFrom:squareLayer];
    
    label.text = [NSString stringWithFormat:@"%d", selectionIndex];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *theTouch = [touches anyObject];
    if (nil == theTouch)
        return;
    
    if (selectedPlayer) {
        CGPoint touchPoint = [theTouch locationInView:theTouch.view];
        touchPoint = [boardLayer convertPoint:touchPoint fromLayer:theTouch.view.layer];
        
        // disable animations for tracking the movement of pieces
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        selectedPlayer.position = touchPoint;
        [CATransaction commit];
        
        int squareIndex = [self squareIndexForLayerLocation:touchPoint];
        
        // stop tracking outside of board
        if (squareIndex < 0)
            return;
        
        SquareLayer *squareBelow = [squares objectAtIndex:squareIndex];
        
        [self enteredSquare:squareBelow];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *theTouch = [touches anyObject];
    if (nil == theTouch)
        return;
    
    if (selectedPlayer) {
        CGPoint touchPoint = [theTouch locationInView:theTouch.view];
        touchPoint = [boardLayer convertPoint:touchPoint fromLayer:theTouch.view.layer];
        
        int destIndex = [self squareIndexForLayerLocation:touchPoint];
        
        BOOL moveIsValid = NO;
        SquareLayer *destinationCell = nil;
        
        if (destIndex >= 0) {
            destinationCell = [squares objectAtIndex:destIndex];
            moveIsValid = (([board.activePlayer isWhitePlayer] && boardDirection > 0) ||
                           (![board.activePlayer isWhitePlayer] && boardDirection < 0));
            moveIsValid = (moveIsValid && [board.activePlayer isValidMoveFrom:selectedPlayer.sourceSquare
                                                                           to:destinationCell.squarePosition]);
        }        
        
        // if the move is not valid, animate the piece back to its original position
        if ((destIndex < 0) || (!moveIsValid))
        {
            destIndex = selectionIndex;
            destinationCell = [squares objectAtIndex:destIndex];
            // animate the player to the center point of the destination cell
            selectedPlayer.position = destinationCell.position;
        }
        else {
            [self movePieceFrom:selectionIndex to:destIndex];
        }
        
        // clear move indicators
        for (int i=0; i<64; i++) {
            SquareLayer *squareLayer = [squares objectAtIndex:i];
            squareLayer.borderWidth = 0;
        }
        
        // clear the selection
        [self selectPlayer:nil];
    }
}

// reposition the board in the center of the screen
///
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration {
    
    // board isn't big enough in landscape mode, scale down the board (iPad only)
    if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        
        boardScale = 0.925;
    }
    else {
        boardScale = 1.0;
    }

    
    [boardLayer setPosition:(CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2))];
    
    [self updateBoardTransforms];
}

// set the minimum boundary to fit the screen
- (float)boardWidth {
    return fmin(self.view.frame.size.width, self.view.frame.size.height);
}

- (float)cellWidth {
    return [self boardWidth] * boardScale * gameScale / 8.0;   
}

- (float)playerWidth {
    return 0.85f * [self cellWidth];
}


//
// Add the layer representing the chessboard
//
- (void)addBoardLayer {
    
    boardLayer = [CALayer layer];
    
    float width = [self boardWidth] * boardScale;
    CGRect bounds = CGRectMake(0, 0, width, width);
    boardLayer.bounds = bounds;
    boardLayer.geometryFlipped = YES;
//    boardLayer.borderColor = [UIColor magentaColor].CGColor;
//    boardLayer.borderWidth = 1.0;
    
    // position the board in the center of the parent view
    [boardLayer setPosition:(CGPointMake([self view].bounds.size.width/2, [self view].bounds.size.height/2))];
    [[self view].layer addSublayer:boardLayer];    
}

//
// Convert the board layer coordinates to a 0-origin index in board coordinates
// board coordinates are [0..63]
//
- (int)squareIndexForLayerLocation:(CGPoint)screenLoc {
    
    float i = 0;
    float j = 0;
    
    if (screenLoc.x > boardLayer.bounds.size.width) {
        return -1;        
    }
    else if (screenLoc.x <= 0) {
        return -1;
    }
    else {
        i = trunc((screenLoc.x / boardLayer.bounds.size.width) * 8);
    }
    
    if (screenLoc.y > boardLayer.bounds.size.height) {
        return -1;        
    }
    else if (screenLoc.y <= 0) {
        return -1;
    }
    else {
        j = trunc((screenLoc.y / boardLayer.bounds.size.height) * 8);
    }
    
    return j * 8 + i;
}

//
// return the x,y coordinates of the center of the cell in board coordinates
// board coordinates are i,j in [0-7, 0-7]
//
- (CGPoint)centerPointOfCellForBoardIndex:(CGPoint)boardPoint {
    
    float cellWidth = [self cellWidth];
    float x = cellWidth / 2 + boardPoint.x * cellWidth;
    float y = cellWidth / 2 + boardPoint.y * cellWidth;
    
    return CGPointMake(x, y);
}

#pragma mark callbacks

//
// notification callback for think thread
//
-(void)startedThinking {
    [hintButton setEnabled:NO];
    [playButton setEnabled:NO];
    [self.view setNeedsDisplay];
}

// notification callback for think thread
//
-(void)stoppedThinking {
    
  [hintButton setEnabled:YES];
  [playButton setEnabled:YES];
  
  ChessMove *move = board.searchAgent.myMove;
  
  NSLog(@"Stopped thinking: move = %@", move);
  
  if (!moveExpected) {
    moveHint = [move retain];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Suggested move" message:[move description] preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"No thanks" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
      // cancel action
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Accept" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
      // accept action
    }]];

    moveExpected = YES;
  }
  else {
    [board movePieceFrom:move.sourceSquare to:move.destinationSquare];
  }

  if (autoPlay) {
    [board.searchAgent startThinking];
  }
}

//
// Callback for display link to show search agent progress and to progress autoPlay mode
//
-(void)updateStatus:(CADisplayLink *)sender {
  label.text = [board.searchAgent statusString];
}

#pragma mark view loading

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
#if __has_feature(objc_arc)
  NSLog(@"ARC is enabled");
#else
  NSLog(@"ARC is not enabled");
#endif

  CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateStatus:)];
  [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  
  [notificationCenter addObserver:self selector:@selector(startedThinking) name:@"StartedThinking" object:nil];
  [notificationCenter addObserver:self selector:@selector(stoppedThinking) name:@"StoppedThinking" object:nil];

  [notificationCenter addObserver:self selector:@selector(gameReset) name:@"GameReset" object:nil];
  [notificationCenter addObserver:self selector:@selector(addedPiece:) name:@"AddedPiece" object:nil];
  [notificationCenter addObserver:self selector:@selector(completedMove:) name:@"CompletedMove" object:nil];
  [notificationCenter addObserver:self selector:@selector(movedPiece:) name:@"MovedPiece" object:nil];
  [notificationCenter addObserver:self selector:@selector(removedPiece:) name:@"RemovedPiece" object:nil];
  [notificationCenter addObserver:self selector:@selector(replacedPiece:) name:@"ReplacedPiece" object:nil];
  [notificationCenter addObserver:self selector:@selector(finishedGame:) name:@"FinishedGame" object:nil];
  [notificationCenter addObserver:self selector:@selector(undoMove:) name:@"UndoMove" object:nil];
  [notificationCenter addObserver:self selector:@selector(validateGamePosition) name:@"ValidateGamePosition" object:nil];
  
  boardDirection = 1.0;
  gameScale = 1.0;
  boardScale = 0.925;
  gameState = kGameStateNotStarted;
  
  [self addBoardLayer];
  [self addSquares];
  [self addLabels];

  [self updateBoardTransforms];
  [self startNewGame];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    
    if (usePopoverController)
        return YES;
    
    else
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
}

- (void)dealloc {
  [squares release];
  [labels release];
  [board release];
  
  [redoList release]; redoList = nil;
  [history release]; history = nil;
  [super dealloc];
}

@end
