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

@implementation ViewController

@synthesize history, redoList, board, usePopoverController, remoteInstanceName;

#pragma mark initialize

-(BOOL)isWhiteCell:(int)index {
    
    int row = index / 8;
    int col = index % 8;
    
    return ((row % 2) && !(col % 2)) || (!(row % 2) && (col % 2));
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
    }
	else if (board.halfmoveClock >= 100) {
		statusMessage = @"Draw (50 move rule)";
        autoPlay = NO;
        isClockTicking = NO;
        [board.searchAgent cancelSearch];
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
#if !__has_feature(objc_arc)
    [workingBoard release];
#endif
    return result;
}

#pragma mark ChessUserAgent protocol

-(void)gameReset {
    
    // disable animations for game reset
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    [self.chessboardView removeMoveIndicationLayers];
    
    [CATransaction commit];
}

-(void)addedPiece:(NSNotification *)notification {
  NSDictionary *description = notification.object;
  NSNumber *piece = [description objectForKey:@"piece"];
  NSNumber *square = [description objectForKey:@"square"];
  NSNumber *white = [description objectForKey:@"white"];
  [self.chessboardView addPiece:[piece intValue] at:[square intValue] white:[white boolValue]];
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
        [self.chessboardView addKingAttackIndicatorTo:attack.destinationSquare];
    }
    else {
        [self.chessboardView removeAttackIndicationLayers];
    }
}

-(void)completedMove:(ChessMove *)move white:(BOOL)aBool {
    if (board == nil) {
        return;
    }
    
    [history addObject:move];
    [self updateBoardLabels:aBool];
    [self updateKingAttackIndicator];
}

-(void)movedPiece:(NSNotification *)notification {
    NSDictionary *description = notification.object;
    NSNumber *from = [description objectForKey:@"from"];
    NSNumber *to = [description objectForKey:@"to"];
    [self.chessboardView movePieceFrom:[from intValue] to:[to intValue]];
}

-(void)removedPiece:(NSNotification *)notification {
  NSDictionary *description = notification.object;
  NSNumber *piece = [description objectForKey:@"piece"];
  NSNumber *square = [description objectForKey:@"square"];
  [self.chessboardView removePiece:[piece intValue] at:[square intValue]];
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
    
    [self.chessboardView removePiece:oldPiece at:square];
    [self.chessboardView addPiece:newPiece at:square white:isWhitePlayer];
}

//
// result == 0   : white lost
// result == 0.5 : draw
// result == 1   : white won
//
-(void)finishedGame:(NSNotification *)notification {
//  NSDictionary *description = notification.object;
//  NSNumber *white = [description objectForKey:@"white"];
//  NSNumber *stalemate = [description objectForKey:@"stalemate"];

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
        
#if !__has_feature(objc_arc)
        if (startingBoard) {
            [startingBoard release];
        }
#endif
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
#if !__has_feature(objc_arc)
        if (startingBoard) {
            [startingBoard release];
        }
#endif
    startingBoard = [board copy];

    [self applyStartNewGame];
}

-(void)applyStartNewGame {
    autoPlay = NO;
    self.history = [NSMutableArray array];
    self.redoList = [NSMutableArray array];

    [self.chessboardView removeAttackIndicationLayers];

    elapsedTimeBlack = elapsedTimeWhite = 0.0;
    isClockTicking = YES;

    [self updateBoardLabels:YES];
}

-(IBAction)newGame {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Game Options" message:@"" preferredStyle:UIAlertControllerStyleAlert];
  NSString *autoPlayLabel = autoPlay ? @"Manual play" : @"Autoplay";
  [alert addAction:[UIAlertAction actionWithTitle:autoPlayLabel style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self autoPlay];
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Reset Board" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
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
    [self.chessboardView selectSquare: -1];
    [self.chessboardView removeMoveIndicationLayers];
    [board.searchAgent startSearchThread];
}

//
// undo the last move
//
-(IBAction)previousMove {
    if (0 == [history count])
        return;
    
    [self.chessboardView selectSquare: -1];
    [self.chessboardView removeMoveIndicationLayers];
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
    
    [board undoMove:move];

    [move release];
}

//
// flip the board upside down
//
-(IBAction)switchSides {
    [self.chessboardView switchSides];
}

-(BOOL)isPlayerWhite {
    return [self.chessboardView isWhiteOnBottom];
}

#pragma mark ChessboardViewDelegate methods

-(void)showMovesAt:(int)square {
    if (![board.searchAgent isReady])
        return;
    
    BOOL whiteToPlay = [self isPlayerWhite];
    
    // if human player is black, don't show moves for white pieces, and vice-versa
    if ((board.activePlayer == board.whitePlayer && !whiteToPlay) ||
        (board.activePlayer == board.blackPlayer && whiteToPlay)) {
        return;
    }

    [self.chessboardView removeMoveIndicationLayers];

    NSArray *moves = [board.activePlayer findValidMovesAt:square];
    NSArray *captureSquares = [self captureSquares];
    
    [self.chessboardView addMoveIndicationLayersAt:square moves:moves captures:captureSquares];
}

-(SelectionContext *)chessboardView:(ChessBoardView *)chessboardView
                       shouldSelect:(NSInteger)square
               withCurrentSelection:(SelectionContext *)selection {

    if (![board.searchAgent isReady]) {
        return nil;
    }

    SelectionContext *candidate = [self.chessboardView selectionInfoFor:square];

    // if we have a current selection, this is a destination selection attempt
    if (selection.square == candidate.square) {
        return nil;
    }

    // no current selection -- this is a piece selection attempt
    int piece = [board.activePlayer pieceAt:(int)square];

    if (piece <= 0) {
        return nil;
    }

    candidate.moves = [board.activePlayer findValidMovesAt:(int)square];
    candidate.captures = [self captureSquares];

    return candidate;
}

-(void)chessboardView:(ChessBoardView *)chessboardView
     didMovePieceFrom:(NSInteger)sourceIndex
                   to:(NSInteger)destIndex {

    [self movePieceFrom:(int)sourceIndex to:(int)destIndex];
}

- (NSInteger)chessboardView:(ChessBoardView * _Nonnull)chessboardView pieceFor:(NSInteger)square { 
    return [board.activePlayer pieceAt:(int)square];
}


#pragma mark callbacks

//
// notification callback for think thread
//
-(void)startedThinking {
    [self.view setNeedsDisplay];
}

// notification callback for think thread
//
-(void)stoppedThinking: (NSNotification *)notification {
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
    [notificationCenter addObserver:self selector:@selector(previousMove:) name:@"UndoMove" object:nil];
    [notificationCenter addObserver:self selector:@selector(validateGamePosition) name:@"ValidateGamePosition" object:nil];
    
    if (self.chessboardView != nil) {
        self.chessboardView.delegate = self;
    }
    
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

#if !__has_feature(objc_arc)
- (void)dealloc {
    [board release];
    
    [redoList release]; redoList = nil;
    [history release]; history = nil;
    [_moveListExportButton release];
    [super dealloc];
}
#endif

@end
