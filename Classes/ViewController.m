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

#import <Chamonix-Swift.h>


const int kDestinationSquareMask = 0x3F;        // lower six bits of least significant byte is destination square (0-63)
const int kSourceSquareMask = 0x3F00;           // lower six bits of second byte is source square (0-63)
const int kMovingPieceMask = 0x070000;          // lower three bits of third byte is moving piece (0-6)
const int kCapturedPieceMask = 0x07000000;      // lower three bits of most significant byte is captured piece (0-6)
const int kGameEventTypeMask = 0xF0000000;      // upper four bits of most significant byte is move type (0-15)

@implementation ViewController

@synthesize history, redoList, board, usePopoverController, remoteInstanceName;

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

//
// the argument is the color of the last player to move
//
-(void)updateBoardLabels:(BOOL)white {
	
  NSArray *whiteMoves = [board.whitePlayer findPossibleMoves];
	NSArray *blackMoves = [board.blackPlayer findPossibleMoves];
  NSArray *moves = (board.activePlayer == board.whitePlayer) ? whiteMoves : blackMoves;

  NSString *statusMessage;
  
  if ((blackMoves == nil) || (whiteMoves == nil)) {
    // if blackmoves is nil, black has checkmated white
    // if whitemoves is nil, white has checkmated black

    statusMessage = @"Checkmate";
    // TODO: highlight stricken king
    autoPlay = NO;
    [board.searchAgent cancelSearch];
    [self.playButton setEnabled:NO];
  }
	else if ([moves count] == 0) {
		statusMessage = @"Draw";
    autoPlay = NO;
    [board.searchAgent cancelSearch];
    [self.playButton setEnabled:NO];
	}
  else {
    statusMessage = white ? @"White to move" : @"Black to move";
  }
	
  statusMessage = [statusMessage stringByAppendingFormat:@"\n(Move %d, ½ move [%d/100])", board.fullmoveNumber, board.halfmoveClock];

  self.gameStatusLabel.text = statusMessage;
  self.moveListLabel.text = [self formatMoveHistory];

}

-(NSString *)formatMoveHistory {
  NSString *result = @"";
  
// TODO: fix incorrect move number when loading FEN string
// int startIndex = board.fullmoveNumber - (int)[history count];

  for (int i=0; i < [history count]; i++) {
    ChessMove *move = history[i];
    result = [result stringByAppendingFormat:@"%d. %@", i + 1, [move sanString]];
    if (i < [history count] - 1) {
      result = [result stringByAppendingString:@" "];
    }
  }
  return result;
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
        [self removeMoveIndicationLayerFrom:square];
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

-(ChessMove *)kingAttack {
    [board.whitePlayer findPossibleMoves];
    if ([board.generator kingAttack]) {
        return [board.generator kingAttack];
    }

    [board.blackPlayer findPossibleMoves];
    if ([board.generator kingAttack]) {
        return [board.generator kingAttack];
    }
    return nil;
}

-(void)completedMove:(ChessMove *)move white:(BOOL)aBool {
    if (board == nil) {
        return;
    }
    
    [history addObject:move];
    [self.undoButton setEnabled:YES];
    [self updateBoardLabels:aBool];
    
    ChessMove *attack = [self kingAttack];
    
    if (attack != nil) {
        [self addKingAttackIndicatorTo:attack.destinationSquare];
    }
    else {
        [self removeAttackIndicationLayers];
    }
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
  [self.playButton setEnabled:YES];

  [self updateBoardLabels:isWhitePlayer];
}

#pragma mark playing

-(IBAction)autoPlay {
    
    autoPlay = !autoPlay;
    if (autoPlay) {
        [self play];
    }
}

-(IBAction)findBestMove {
    
    if (![board.searchAgent isReady])
        return;
    
    moveExpected = NO;
    [board.searchAgent startSearchThread];
}


-(void)editFENString {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Edit board positions"
                                                                             message:@"Enter positions in Forsyth-Edward Notation"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"FEN";
        textField.text = [board generateFEN];
        textField.keyboardType = UIKeyboardTypeDefault;
        // Further customization like secureTextEntry, delegate, etc.
    }];
    
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
        UITextField *inputTextField = alertController.textFields.firstObject;
        NSString *enteredText = inputTextField.text;
        [board initializeSearch];
        [board initializeNewBoard];
        [board initializeFromFEN: enteredText];
        [self applyStartNewGame];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)startNewGame {
    if (!board) {
      ChessBoard *newBoard = [[ChessBoard alloc] init];
      [newBoard resetGame];
      newBoard.hasUserAgent = YES;
      self.board = newBoard;
      [newBoard release];
    }
    [board initializeSearch];
    [board initializeNewBoard];

    [self applyStartNewGame];
}

-(void)applyStartNewGame {
    autoPlay = NO;
    self.history = [NSMutableArray array];
    self.redoList = [NSMutableArray array];

    [self.undoButton setEnabled:NO];
    [self.playButton setEnabled:YES];
    [self removeAttackIndicationLayers];

    elapsedTimeBlack = elapsedTimeWhite = 0.0;

    [self updateBoardLabels:YES];
}

-(IBAction)newGame {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Game Options" message:@"" preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Switch Sides" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self switchSides];
  }]];
  NSString *autoPlayLabel = autoPlay ? @"Human Plays" : @"Computer Plays";
  [alert addAction:[UIAlertAction actionWithTitle:autoPlayLabel style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self autoPlay];
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Restart Board" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
    [self startNewGame];
  }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Edit Board" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
      [self editFENString];
    }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  
  [self presentViewController:alert animated:YES completion:nil];
}

-(void)movePieceFrom:(int)sourceSquare to:(int)destSquare {
    
  if (!board)
      return;

  if (![board.searchAgent isReady])
      return;
  
  [board movePieceFrom:sourceSquare to:destSquare];
    
  moveExpected = YES;
  [board.searchAgent startSearchThread];
}

-(IBAction)play {
    moveExpected = YES;
    [board.searchAgent startSearchThread];
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
        [self.undoButton setEnabled:NO];
    }
    
    [board undoMove:move];

    ChessMove *attack = [self kingAttack];
    
    if (attack != nil) {
        [self addKingAttackIndicatorTo:attack.destinationSquare];
    }
    else {
        [self removeAttackIndicationLayers];
    }

    [move release];
}

//
// flip the board upside down
//
-(void)switchSides {
    
  boardDirection *= -1;
  
  [self updateBoardTransforms];
  
  if ((board.activePlayer == board.whitePlayer && boardDirection < 0) ||
      (board.activePlayer == board.blackPlayer && boardDirection > 0)) {
    [self play];
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

-(UIColor *)highlightColor {
    return [UIColor colorWithRed:0.2 green:0.6 blue:0.2 alpha:0.5];
}

-(UIColor *)kingCheckColor {
    return [UIColor colorWithRed:0.6 green:0.2 blue:0.2 alpha:1.0];
}

-(void)addMoveStartIndicationLayerTo:(CALayer *)square {
    CALayer *spot = [CALayer layer];
    spot.bounds = square.bounds;
    spot.backgroundColor = [[self highlightColor] CGColor];
    spot.name = @"spot";
    
    [spot setPosition:(CGPointMake(square.bounds.size.width / 2, square.bounds.size.height / 2))];
    [square addSublayer:spot];
}

-(void)addMoveIndicationLayerTo:(CALayer *)square {
    CGSize squareRect = square.bounds.size;
    CALayer *spot = [CALayer layer];
    spot.bounds = CGRectMake(0, 0, squareRect.width / 3, squareRect.height / 3);
    spot.cornerRadius = square.bounds.size.width / 6;
    spot.backgroundColor = [[self highlightColor] CGColor];
    spot.name = @"spot";
    
    [spot setPosition:(CGPointMake(squareRect.width / 2, squareRect.height / 2))];
    [square addSublayer:spot];
}

-(void)removeMoveIndicationLayers {
    for (int i=0; i<64; i++) {
        SquareLayer *squareLayer = [squares objectAtIndex:i];
        [self removeMoveIndicationLayerFrom:squareLayer];
    }
}

-(void)removeAttackIndicationLayers {
    for (int i=0; i<64; i++) {
        SquareLayer *squareLayer = [squares objectAtIndex:i];
        [self removeAttackIndicationLayerFrom:squareLayer];
    }
}

-(void)removeMoveIndicationLayerFrom:(CALayer *)square {
    CALayer *sublayer = [square.sublayers firstObject];
    if ([sublayer.name isEqualToString:@"spot"]) {
        [sublayer removeFromSuperlayer];
    }
}

-(void)removeAttackIndicationLayerFrom:(CALayer *)square {
    CALayer *sublayer = [square.sublayers firstObject];
    if ([sublayer.name isEqualToString:@"attack"]) {
        [sublayer removeFromSuperlayer];
    }
}

-(void)addKingAttackIndicatorTo:(int)destination {
    // radial-gradient(ellipse at center, rgb(255, 0, 0) 0%, rgb(231, 0, 0) 25%, rgba(169, 0, 0, 0) 89%, rgba(158, 0, 0, 0) 100%)
    CALayer *square = squares[destination];
    CGSize squareRect = square.bounds.size;
    CAGradientLayer *attack = [CAGradientLayer layer];
    attack.frame = square.bounds;
    attack.type = kCAGradientLayerRadial;
    attack.colors = @[
        (__bridge id)[[UIColor colorWithRed:1.0 green:0 blue:0 alpha:1.0] CGColor],
        (__bridge id)[[UIColor colorWithRed:(231.0/255.0) green:0 blue:0 alpha:1.0] CGColor],
        (__bridge id)[[UIColor colorWithRed:(169/255.0) green:0 blue:0 alpha:0.0] CGColor],
        (__bridge id)[[UIColor colorWithRed:(158.0/255.0) green:0 blue:0 alpha:0.0] CGColor],
    ];
    attack.locations = @[@(0), @(0.25), @(0.89), @(1.0)];
    attack.startPoint = CGPointMake(0.5, 0.5);
    attack.endPoint = CGPointMake(1.15, 1.15);
    attack.name = @"attack";
    
    [attack setPosition:(CGPointMake(squareRect.width / 2, squareRect.height / 2))];
    [square addSublayer:attack];
}

-(void)showMovesAt:(int)square {
    if (![board.searchAgent isReady])
        return;
    
    // if human player is black, don't show moves for white pieces, and vice-versa
    if ((![board.activePlayer isWhitePlayer] && boardDirection > 0) ||
        ([board.activePlayer isWhitePlayer] && boardDirection < 0))
        return;

    [self removeMoveIndicationLayers];

    NSArray *list = [board.activePlayer findValidMovesAt:square];
    
    if (0 == [list count])
        return;
    
    SquareLayer *thisLayer = [squares objectAtIndex:square];
    [self addMoveStartIndicationLayerTo:thisLayer];

    for (ChessMove *move in list) {
        SquareLayer *destLayer = [squares objectAtIndex:move.destinationSquare];
        [self addMoveIndicationLayerTo:destLayer];
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
    if (![board.searchAgent isReady])
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
        [self removeMoveIndicationLayerFrom:squareLayer];
    }
    
    [self selectPlayer:nil];
    
    SquareLayer *squareLayer = [squares objectAtIndex:selectionIndex];
    ChessPieceLayer *candidate = squareLayer.pieceLayer;
    [self selectPlayer:candidate];
    
    // need to be able to return piece to original position for invalid moves
    candidate.sourceSquare = squareLayer.squarePosition;
    
    [self showMovesFrom:squareLayer];
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
            [self removeMoveIndicationLayerFrom:squareLayer];
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
    [self.hintButton setEnabled:NO];
    [self.playButton setEnabled:NO];
    [self.view setNeedsDisplay];
}

// notification callback for think thread
//
-(void)stoppedThinking: (NSNotification *)notification {
    
  [self.hintButton setEnabled:YES];
  [self.playButton setEnabled:YES];
  
  NSDictionary *info = notification.object;
  if (info[@"bestmove"] == nil) {
    self.gameStatusLabel = info[@"reason"];
    [board.searchAgent cancelSearch];
    autoPlay = NO;
  }
  int encodedMode = [info[@"bestmove"] intValue];
  ChessMove *move = [ChessMove decodeFrom:encodedMode];
  
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
    [board.searchAgent startSearchThread];
  }
}

-(NSString *)formatDuration:(NSTimeInterval)duration {
  int hours = (int)duration / 3600;
  int minutes = (int)duration / 60;
  int seconds = (int)duration % 60;
  if (hours > 0) {
    minutes = minutes % 60;
    return [NSString stringWithFormat:@"%0d:%02d:%02d", hours, minutes, seconds];
  }
  return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

//
// Callback for display link to show search agent progress and to progress autoPlay mode
//
-(void)updateStatus:(CADisplayLink *)sender {
  self.engineInfoLabel.text = [board.searchAgent statusString];
  NSTimeInterval duration = sender.targetTimestamp - sender.timestamp;
  if (board.whitePlayer == board.activePlayer) {
    elapsedTimeWhite += duration;
    self.whiteGameClock.text = [@"White " stringByAppendingString:[self formatDuration:elapsedTimeWhite]];
  }
  else {
    elapsedTimeBlack += duration;
    self.blackGameClock.text = [@"Black " stringByAppendingString:[self formatDuration:elapsedTimeBlack]];
  }
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
  [notificationCenter addObserver:self selector:@selector(stoppedThinking:) name:@"StoppedThinking" object:nil];

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
