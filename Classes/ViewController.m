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
    piecesTransform = CATransform3DMakeScale(boardDirection, boardDirection, 1.0);    
    
    boardLayer.transform = boardTransform;
    
    for (int i=0; i < 64; i++) {
        SquareLayer *squareLayer = [squares objectAtIndex:i];
        squareLayer.pieceLayer.transform = piecesTransform;
    }

    for (int i=0; i < 16; i++) {
        CATextLayer *labelLayer = [labels objectAtIndex:i];
        labelLayer.transform = piecesTransform;
    }
}

//
// the argument is the color of the last player to move
//
-(void)updateBoardLabels:(BOOL)white {
	
    NSArray *whiteMoves = [board.whitePlayer findValidMoves];
    NSArray *blackMoves = [board.blackPlayer findValidMoves];
    NSArray *moves = (board.activePlayer == board.whitePlayer) ? whiteMoves : blackMoves;

    NSString *statusMessage;
  
    // no moves for the active player (findValidMoves returns an empty array, but findPossibleMoves returns nil)
    if ([moves count] == 0) {
        statusMessage = @"Checkmate";
        autoPlay = NO;
        isClockTicking = NO;
        [board.searchAgent cancelSearch];
        [self.playButton setEnabled:NO];
    }
	else if (board.halfmoveClock >= 100) {
		statusMessage = @"Draw (50 move rule)";
        autoPlay = NO;
        isClockTicking = NO;
        [board.searchAgent cancelSearch];
        [self.playButton setEnabled:NO];
	}
    else {
        statusMessage = white ? @"White‘s move" : @"Black‘s move";
    }

    self.gameStatusLabel.text = [NSString stringWithFormat:@"%@", statusMessage];
    self.moveListTextView.text = [self formatMoveHistory:YES];
}

-(NSString *)formatMoveHistory:(BOOL)unicodeGlyphs {
    NSString *result = @"";
  
    int moveNumber = startingBoard.fullmoveNumber;
    BOOL whiteToPlay = startingBoard.activePlayer == startingBoard.whitePlayer;
    ChessBoard *workingBoard = [startingBoard copy];

    for (int i = 0; i < [history count]; i++) {
        // normally white starts, but if we loaded from a FEN string, the first move might be black
        // increment the move number on black's move (full move number starts at 1 from starting position)
        if ((whiteToPlay && (i % 2 == 0)) || (!whiteToPlay && (i % 2 == 1))) {
            result = [result stringByAppendingFormat:@"%d. ", moveNumber];
            moveNumber++;
        }
        ChessMove *move = history[i];
        result = [result stringByAppendingString:[move sanStringForBoard:workingBoard unicodeGlyphs:unicodeGlyphs]];
        [workingBoard nextMove:move];
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
        labelLayer.foregroundColor = [UIColor whiteColor].CGColor;
        
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
        labelLayer.foregroundColor = [UIColor whiteColor].CGColor;
        
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
    m.transform = piecesTransform;
    
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

-(NSArray *)captureSquares {
    NSArray *moves = board.activePlayer == board.whitePlayer ?
        [board.whitePlayer findPossibleMoves] :
        [board.blackPlayer findPossibleMoves];

    NSMutableArray *result = [NSMutableArray array];
    for (ChessMove *move in moves) {
        if (move.capturedPiece != 0) {
            [result addObject:@(move.destinationSquare)];
        }
    }
    
    return result;
}

-(void)updateKingAttackIndicator {
    ChessMove *attack = [self kingAttack];
    
    if (attack != nil) {
        [self addKingAttackIndicatorTo:attack.destinationSquare];
    }
    else {
        [self removeAttackIndicationLayers];
    }
}

-(void)completedMove:(ChessMove *)move white:(BOOL)aBool {
    if (board == nil) {
        return;
    }
    
    [history addObject:move];
    [self.undoButton setEnabled:YES];
    [self updateBoardLabels:aBool];
    [self updateKingAttackIndicator];
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
        
        startingBoard = [board copy];
        
        [self updateBoardLabels:board.activePlayer == board.whitePlayer];
        [self applyStartNewGame];
        [self updateKingAttackIndicator];
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
    startingBoard = [board copy];

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
    isClockTicking = YES;

    [self updateBoardLabels:YES];
}

-(IBAction)newGame {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Game Options" message:@"" preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Switch Sides" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self switchSides];
  }]];
  NSString *autoPlayLabel = autoPlay ? @"Manual play" : @"Autoplay";
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
    
  [board.searchAgent startSearchThread];
}

-(IBAction)play {
    [self selectPiece:nil];
    [self removeMoveIndicationLayers];
    [board.searchAgent startSearchThread];
}

//
// undo the last move
//
-(IBAction)undoMove {
    if (0 == [history count])
        return;
    
    [self selectPiece:nil];
    [self removeMoveIndicationLayers];
    [self applyUndoMove];
    [self updateKingAttackIndicator];
}

-(IBAction)exportMoveList {
    [[UIPasteboard generalPasteboard] setString: [self formatMoveHistory:NO]];
}

-(void)applyUndoMove {
    ChessMove *move = [history lastObject];
    [move retain];
    [history removeLastObject];
    
    if ([history count] == 0) {
        [self.undoButton setEnabled:NO];
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
  
  if ((board.activePlayer == board.whitePlayer && boardDirection < 0) ||
      (board.activePlayer == board.blackPlayer && boardDirection > 0)) {
    [self play];
  }
}

-(BOOL)isPlayerWhite {

    return boardDirection > 0;
}

#pragma mark Private

- (void)selectPiece:(ChessPieceLayer *)pieceLayer {
    if (selectedPiece)
    {
        selectedPiece.zPosition -= 1;
        [selectedPiece needsDisplay];
    }
    selectedPiece = pieceLayer;
    
    if (selectedPiece)
    {
        selectedPiece.zPosition += 1;
        [selectedPiece needsDisplay];
    }
}

- (ChessPieceLayer *)playerLayerAtTouchPoint:(CGPoint)touchPoint {
    for (SquareLayer *squareLayer in squares) {
        ChessPieceLayer *candidate = squareLayer.pieceLayer;
        if ((candidate != selectedPiece) && [candidate hitTest:touchPoint]) {
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

- (CALayer *)createCaptureIndicationLayer:(CGFloat)width color:(UIColor *)color {
    // Create the content layer
    CALayer *contentLayer = [CALayer layer];
    contentLayer.frame = CGRectMake(0, 0, width, width);
    contentLayer.backgroundColor = color.CGColor;
    
    // Create the inverse mask
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, width), NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Fill entire context with black (opaque)
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, width, width));
    
    // Clear the rounded rectangle area (make it transparent)
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    
    UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, width, width)
                                                           cornerRadius:width/4.0];
    CGContextAddPath(context, roundedPath.CGPath);
    CGContextFillPath(context);
    
    UIImage *maskImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Create and apply the mask layer
    CALayer *maskLayer = [CALayer layer];
    maskLayer.frame = contentLayer.bounds;
    maskLayer.contents = (__bridge id)maskImage.CGImage;
    
    contentLayer.mask = maskLayer;
    
    return contentLayer;
}

-(void)addMoveCaptureIndicationLayerTo:(CALayer *)square {
    CGFloat width = square.bounds.size.width;
    CALayer *spot = [self createCaptureIndicationLayer:width color:[self highlightColor]];
    spot.name = @"spot";
    
    [spot setPosition:(CGPointMake(square.bounds.size.width / 2, square.bounds.size.height / 2))];
    [square addSublayer:spot];
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
    NSArray *captureSquares = [self captureSquares];
    
    if (0 == [list count])
        return;
    
    SquareLayer *thisLayer = [squares objectAtIndex:square];
    [self addMoveStartIndicationLayerTo:thisLayer];

    for (ChessMove *move in list) {
        SquareLayer *destLayer = [squares objectAtIndex:move.destinationSquare];
        if ([captureSquares containsObject:@(move.destinationSquare)]) {
            [self addMoveCaptureIndicationLayerTo:destLayer];
        }
        else {
            [self addMoveIndicationLayerTo:destLayer];
        }
    }
}

-(void)showMovesFrom:(SquareLayer *)squareLayer {
    [self showMovesAt:squareLayer.squarePosition];
}

#pragma mark UITouch events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (![board.searchAgent isReady])
        return;
        
    UITouch *theTouch = [touches anyObject];
    if (nil == theTouch)
        return;

    CGPoint touchPoint = [theTouch locationInView:theTouch.view];
    touchPoint = [boardLayer convertPoint:touchPoint fromLayer:theTouch.view.layer];
    int selectionIndex = [self squareIndexForLayerLocation:touchPoint];
    
    // touch down outside of board
    if (selectionIndex < 0)
        return;
    
    // clear previous move indicators
    for (int i=0; i<64; i++) {
        SquareLayer *squareLayer = [squares objectAtIndex:i];
        [self removeMoveIndicationLayerFrom:squareLayer];
    }

    SquareLayer *squareLayer = [squares objectAtIndex:selectionIndex];
    ChessPieceLayer *candidate = squareLayer.pieceLayer;

    // support two tap placement of pieces instead of forcing drag and drop
    if (selectedPiece != nil) {
        // if the pieces are on the same side, select and highlight the new piece without requiring a second tap
        if ((selectedPiece != candidate) &&
            ((candidate.isWhite && selectedPiece.isWhite) || (!candidate.isWhite && !selectedPiece.isWhite))) {
            [self selectPiece:candidate];
            candidate.sourceSquare = squareLayer.squarePosition;
            [self showMovesFrom:squareLayer];
            return;
        }
        else if (selectedPiece != candidate) {
            [self dropPieceAt:selectionIndex];
            return;
        }
    }

    // second tap on a piece should clear selection
    if (selectedPiece == candidate) {
        [self selectPiece:nil];
        [self removeMoveIndicationLayers];
        return;
    }

    [self selectPiece:candidate];
    
    // need to be able to return piece to original position for invalid moves
    candidate.sourceSquare = squareLayer.squarePosition;
    [self showMovesFrom:squareLayer];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *theTouch = [touches anyObject];
    if (nil == theTouch)
        return;
    
    if (selectedPiece) {
        CGPoint touchPoint = [theTouch locationInView:theTouch.view];
        touchPoint = [boardLayer convertPoint:touchPoint fromLayer:theTouch.view.layer];
        
        // disable animations for tracking the movement of pieces
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        selectedPiece.position = touchPoint;
        [CATransaction commit];
        
        int squareIndex = [self squareIndexForLayerLocation:touchPoint];
        
        // stop tracking outside of board
        if (squareIndex < 0)
            return;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *theTouch = [touches anyObject];
    if (nil == theTouch)
        return;
    
    if (!selectedPiece) {
        return;
    }
    CGPoint touchPoint = [theTouch locationInView:theTouch.view];
    touchPoint = [boardLayer convertPoint:touchPoint fromLayer:theTouch.view.layer];
    
    int destIndex = [self squareIndexForLayerLocation:touchPoint];

    if (destIndex != selectedPiece.sourceSquare) {
        [self dropPieceAt:destIndex];
    }
    else {
        // animate the piece to its original position
        SquareLayer *originLayer = squares[selectedPiece.sourceSquare];
        selectedPiece.position = originLayer.position;
    }
}

- (void)dropPieceAt:(int)destIndex {
    BOOL moveIsValid = NO;
    SquareLayer *destinationCell = nil;
    
    if (destIndex >= 0) {
        destinationCell = [squares objectAtIndex:destIndex];
        moveIsValid = (([board.activePlayer isWhitePlayer] && boardDirection > 0) ||
                       (![board.activePlayer isWhitePlayer] && boardDirection < 0));
        moveIsValid = (moveIsValid && [board.activePlayer isValidMoveFrom:selectedPiece.sourceSquare
                                                                       to:destinationCell.squarePosition]);
    }
    
    // if the move is not valid, animate the piece back to its original position
    if ((destIndex < 0) || (!moveIsValid))
    {
        destIndex = selectedPiece.sourceSquare;
        destinationCell = [squares objectAtIndex:destIndex];
        // animate the piece to the center point of the destination cell
        selectedPiece.position = destinationCell.position;
    }
    else if (moveIsValid) {
        [self movePieceFrom:selectedPiece.sourceSquare to:destIndex];
    }
    
    // clear move indicators
    for (int i=0; i<64; i++) {
        SquareLayer *squareLayer = [squares objectAtIndex:i];
        [self removeMoveIndicationLayerFrom:squareLayer];
    }
    
    // clear the selection
    [self selectPiece:nil];
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
    [self.playButton setEnabled:NO];
    [self.view setNeedsDisplay];
}

// notification callback for think thread
//
-(void)stoppedThinking: (NSNotification *)notification {
    [self.playButton setEnabled:YES];

    NSDictionary *info = notification.object;
    if (info[@"bestmove"] == nil) {
        self.gameStatusLabel = info[@"reason"];
        [board.searchAgent cancelSearch];
        autoPlay = NO;
    }
    int encodedMode = [info[@"bestmove"] intValue];
    ChessMove *move = [ChessMove decodeFrom:encodedMode];

    [board movePieceFrom:move.sourceSquare to:move.destinationSquare];

    if (autoPlay) {
        // wait before starting another search so things don't get too crazy
        [board.searchAgent performSelector:@selector(startSearchThread) withObject:nil afterDelay:0.5];
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

    if (isClockTicking) {
        if ((board.whitePlayer == board.activePlayer)) {
            elapsedTimeWhite += duration;
            self.whiteGameClock.text = [@"White " stringByAppendingString:[self formatDuration:elapsedTimeWhite]];
        }
        else {
            elapsedTimeBlack += duration;
            self.blackGameClock.text = [@"Black " stringByAppendingString:[self formatDuration:elapsedTimeBlack]];
        }
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
    [_moveListExportButton release];
    [super dealloc];
}

@end
