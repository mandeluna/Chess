//
//  ChessMailViewController.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-15.
//  Copyright Steven Wart 2010. All rights reserved.
//

#import "ChessMailViewController.h"
#import "ChessSettingsViewController.h"

#import "ChessBoard.h"
#import "ChessPlayer.h"
#import "ChessPieceLayer.h"
#import "SquareLayer.h"
#import "ChessPlayerAI.h"
#import "ChessMove.h"
#import "ChessMoveList.h"
#import "ChessMoveGenerator.h"
#import "WaitingAlertView.h"

#import "Picker.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVAudioSession.h>

// The Bonjour application protocol, which must:
// 1) be no longer than 14 characters
// 2) contain only lower-case letters, digits, and hyphens
// 3) begin and end with lower-case letter or digit
// It should also be descriptive and human-readable
// See the following for more information:
// http://developer.apple.com/networking/bonjour/faq.html
#define kGameIdentifier		@"chessmail"

#define	DEFAULT_VOICE_ID	(@"DefaultName")
#define BONJOUR_DOMAIN		(@"local")
#define MAX_VOICE_CHAT_PACKET_SIZE (1500)

static void InterruptionListenerCallback (void	*inUserData, UInt32	interruptionState);
static void RouteChangedListener(void* _self, AudioSessionPropertyID inID, UInt32 inDataSize, const void* inData);

const int kDestinationSquareMask = 0x3F;        // lower six bits of least significant byte is destination square (0-63)
const int kSourceSquareMask = 0x3F00;           // lower six bits of second byte is source square (0-63)
const int kMovingPieceMask = 0x070000;          // lower three bits of third byte is moving piece (0-6)
const int kCapturedPieceMask = 0x07000000;      // lower three bits of most significant byte is captured piece (0-6)
const int kGameEventTypeMask = 0xF0000000;      // upper four bits of most significant byte is move type (0-15)

@interface ChessMailViewController(Private)
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

// game kit support
-(void)setupBonjourConnections;
-(void)endSession;
-(void)terminateNetworkConnections;
-(void)send:(const GameEvent)message;
-(void)gameStarted;

// voice chat support
- (void)setup;
- (void)presentPicker:(NSString*)name;
- (void)acceptVoiceChatInvitation;
- (void)startVoiceChat;

@end

@interface ChessMailViewController(VoiceChatClient)

#pragma mark Voice Chat convenience methods

-(void) setupVoiceChat;
-(void) voiceChatSend:(NSData *)data;
-(void) stopVoiceChat;

#pragma mark Voice Chat audio session methods

-(void) setupAudioSession;
-(void) resetAudioSessionProperties;
-(void) handleAudioInterruption:(BOOL) isBeginInterrupt;

@end

#pragma mark ===
@implementation ChessMailViewController
@synthesize history, redoList, board, usePopoverController, remoteInstanceName;

#pragma mark Action Sheet delegate

- (void) showNetworkAlert:(NSString*)title
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:@"Check your network settings"
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
    [alertView release];
}

enum {
    kIndexPlayOnline,
    kIndexPlayComputer,
    kIndexSwitchSides,
    kIndexSetupBoard,
	kAutoPlay,
    kNumActions
} actionIndexes;

-(void)actionSheetCancel:(UIActionSheet *)actionSheet {
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    [gameSelectionActionSheet release];
    gameSelectionActionSheet = nil;
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
			// TODO - game is not prompting to resign game in progress
			// TODO - maybe you can have multiple games in progress
        case kIndexPlayOnline:
			[self startNewGame];
            if (session || outStream)
                [self terminateNetworkConnections];
			[self playOnline];
            break;
        case kIndexPlayComputer:
            [self startNewGame];
            // maybe there is already a session with someone online?
            if (session || outStream)
                [self terminateNetworkConnections];
            if ([board.activePlayer isWhitePlayer] && boardDirection < 0) // computer is black
                [self thinkAndMove];
            break;
        case kIndexSwitchSides:
            [self switchSides];
        case kIndexSetupBoard:
            [self setupBoard];
            break;
        case kAutoPlay:
            [self autoPlay];
            break;
        default:
            NSLog(@"Unknown action index %d", buttonIndex);
    }
    
    [gameSelectionActionSheet release];
    gameSelectionActionSheet = nil;
}


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
    
    [self updatePlayerLabels];
}

-(void)updatePlayerLabels {
    
    BOOL localPlayerHasGameKitAlias = NO;   // todo: check if GKLocalPlayer is authenticated
    
    NSString *localPlayerLabel = localPlayerHasGameKitAlias ? @"alias" : NSUserName();
    NSString *opponentLabel = remoteParticipantID ? remoteParticipantID : @"Computer";

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

-(void)addedPiece:(int)piece at:(int)square white:(BOOL)isWhite {
    
    ChessPieceLayer *m = [self newPiece:piece white:isWhite];
    m.chessBoard = self;
    SquareLayer *s = [squares objectAtIndex:square];
    m.position = s.position;
    s.pieceLayer = m;
}

-(void)completedMove:(ChessMove *)move white:(BOOL)aBool {
    
    if (!board)
        return;
    
    [history addObject:move];
    [undoButton setEnabled:YES];

    [self validateGamePosition];
	
	[self updateBoardLabels:aBool];
}

-(void)movedPiece:(int)piece from:(int)sourceSquare to:(int)destSquare {
    
    SquareLayer *sourceSquareLayer = [squares objectAtIndex:sourceSquare];
    ChessPieceLayer *sourceLayer = sourceSquareLayer.pieceLayer;
    SquareLayer *destSquareLayer = [squares objectAtIndex:destSquare];
    
    sourceLayer.position = destSquareLayer.position;
    sourceSquareLayer.pieceLayer = nil;
    destSquareLayer.pieceLayer = sourceLayer;
}

-(void)removedPiece:(int)piece at:(int)square {
    
    SquareLayer *squareLayer = [squares objectAtIndex:square];
    [squareLayer.pieceLayer removeFromSuperlayer];
    [squareLayer setNeedsDisplay];
    squareLayer.pieceLayer = nil;
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
-(void)finishedGame:(BOOL)result {
    
    self.board = nil;
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
    
    // if game is in progress, prompt to quit game
    if (kGameStateNormal == gameState)
    {
        startNewGameAlertView = [[UIAlertView alloc] initWithTitle:@"Resign from game in progress?"
                                                           message:@"There is a game already underway. Do you want to resign and start over?"
                                                          delegate:self
                                                 cancelButtonTitle:@"Keep playing"
                                                  otherButtonTitles:@"New Game", nil];
        [startNewGameAlertView show];
        return;
    }
    [self applyStartNewGame];
}

-(void)applyStartNewGame {
    
    if (!board) {
        ChessBoard *newBoard = [[ChessBoard alloc] init];
        newBoard.generator = [[ChessMoveGenerator alloc] init];
        newBoard.searchAgent = [[ChessPlayerAI alloc] init];
        [newBoard resetGame];
        self.board = newBoard;
        [newBoard release];
    }
    board.userAgent = self;
    [board initializeNewBoard];
    self.history = [NSMutableArray array];
    self.redoList = [NSMutableArray array];
    
    playerRandomChoice = 0;
    opponentRandomChoice = 0;
    
    [undoButton setEnabled:NO];
    [redoButton setEnabled:NO];
    
    [self validateGamePosition];
}

-(IBAction)newGame {
    
    // toggle the action sheet if the button is selected multiple times
    if (gameSelectionActionSheet)
    {
        [gameSelectionActionSheet dismissWithClickedButtonIndex:0 animated:YES];
        [gameSelectionActionSheet release];
        gameSelectionActionSheet = nil;
        return;
    }
    
    // TODO: depending on the state of the game, we should change the options available here
    //
    // if you're already playing a game
    // -- against a computer: "Restart Game", "Request Hint", "Undo Move"
    // -- against an online opponent: "Resign", "Propose Draw", "Request Undo"
    // if you're not playing yet: "Play Online", "Play Computer", "Switch Sides", "Setup Board"
    
    gameSelectionActionSheet = [[UIActionSheet alloc] initWithTitle:@"New Game"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Play Online", @"Play Computer", @"Switch Sides", @"Setup Board", @"Auto Play", nil];
    
    [gameSelectionActionSheet showFromBarButtonItem:newGameButton animated:YES];
}


-(void)movePieceFrom:(int)sourceSquare to:(int)destSquare {
    
    if (!board)
        return;
    
    // true if it's the computer's move
    // TODO: check if it's the online opponent's move
    if ([board.searchAgent isThinking])
        return;
    
    ChessMove *theMove = [board movePieceFrom:sourceSquare to:destSquare];
    
    if ((outStream) ||  // playing against wifi peer
        (session))      // playing against nearby peer
    {
        GameEvent gameEvent;
        gameEvent.eventType = kNormalMoveRequest;
        gameEvent.encodedMove = [theMove encodedMove];
        [self send:gameEvent];
    }
    else {
        // assume that if no session is present, we are playing against the computer
        // TODO: allow manual play without a remote session?
        // TODO: allow manual board setup
        moveExpected = YES;
        [board.searchAgent startThinking];
    }
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
// we are ready for I/O but our opponent might not be (in fact, one of us is going to get here before the other is ready)
//
-(void)gameStarted {
    
	// make sure the two devices don't generate the same random number
	srand(CACurrentMediaTime());

    // only one button, we need the delay to ensure both peers are set up, now send a random number
    playerRandomChoice = rand();
	NSLog(@"generated playerRandomChoice=%d", playerRandomChoice);
    
    GameEvent gameEvent;
    gameEvent.eventType = kSelectSideRequest;
    gameEvent.encodedMove = playerRandomChoice;
    [self send:gameEvent];
    [self startVoiceChat];        
}

-(void)resolvePlayerSides {
    
    NSString *message;
    
    // whoever has the larger random number is white
    if (opponentRandomChoice > playerRandomChoice)
    {
        message = @"You will play as black";
        if (boardDirection > 0)
            [self switchSides];
    }
    else if (opponentRandomChoice < playerRandomChoice) {
        message = @"You will play as white";
        if (boardDirection < 0)
            [self switchSides];
    }
	else {
        message = [NSString stringWithFormat:@"Coin flip was a tie. You got %d and opponent got %d - imagine that! Trying again...", playerRandomChoice, opponentRandomChoice];
		[self gameStarted];
	}
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Game started"
                                                        message:message
                                                       delegate:nil cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
    [alertView show];
    [alertView autorelease];
}

//
// TODO: sanity check on data
//

-(void)receivedGameEvent:(GameEvent)gameEvent {
    
    switch (gameEvent.eventType)
    {
        case kNormalMoveRequest:
        {
            ChessMove *move = [ChessMove decodeFrom:gameEvent.encodedMove];
            [board movePieceFrom:move.sourceSquare to:move.destinationSquare];
            break;
        }
        case kUndoMoveRequest:          // opponent wants to undo
        {
            // TODO: stop local player's clock if it's running
            NSString *message = [NSString stringWithFormat:@"Your opponent %@ requests to take back the move %@",
                                 remoteParticipantID, [history lastObject]];
            undoMoveRequestAlertView = [[UIAlertView alloc] initWithTitle:@"Sorry for the interruption"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Allow", @"Deny", nil];
            [undoMoveRequestAlertView show];
            break;
        }
        case kUndoMoveResponse:         // opponent's response to our request to undo a move
        {
            int buttonIndex = gameEvent.encodedMove;
            if (buttonIndex == 1)
            {
                [self applyUndoMove];
            }
            else
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Request denied"
                                                                    message:@"Sorry, your opponent will not permit you to take back your move"
                                                                   delegate:nil cancelButtonTitle:nil
                                                          otherButtonTitles:@"OK", nil];
                [alertView show];
                [alertView release];
            }
            [undoMoveWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
            [undoMoveWaitAlertView release];
            undoMoveWaitAlertView = nil;
            break;
        }
        case kSelectSideRequest:
        {
            opponentRandomChoice = gameEvent.encodedMove;
			
            // TODO: we may be receiving opponent's encoded value before we sent ours...
            // there is a race condition here
            if (playerRandomChoice != 0)
            {
                [self resolvePlayerSides];
            }
            else
                NSLog(@"receiving opponent's encoded value before we sent ours...");
            
            break;
        }
        case kSelectSideResponse:       // opponent agrees or disagrees with suggestion to choose sides
        {
            break;
        }
        case kSelectSideArbitrationResponse: // opponent and local player couldn't agree, so we use random arbitration
        {
            break;
        }
        case kProposeDrawRequest:       // opponent thinks game is going nowhere and would like to call it a draw
        {
            break;
        }
        case kProposeDrawResponse:      // opponent either agreed or disagreed with proposal to draw the game
        {
            break;
        }
        case kProposeResignRequest:     // opponent thinks we are hopeless
        {
            break;
        }
        case kResignRequest:            // opponent has resigned (w00t!)
        {
            NSString *message = [NSString stringWithFormat:@"%@ has resigned", remoteParticipantID];
            NSString *colorString = [NSString stringWithFormat:@"%@ wins", [self myColorLabel]];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:colorString
                                                                message:message delegate:nil
                                                      cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            [alertView release];
            break;
        }
        default:
            NSLog(@"unknown game event type %d ", gameEvent.eventType);
    }
}

//
// undo the last move
//
-(IBAction)undoMove {
    
    if (!board)
        return;
    
    if (0 == [history count])
        return;
    
    if (outStream || session)      // playing against nearby peer
    {
        // ask permission before undoing the move
        undoMoveWaitAlertView = [[WaitingAlertView alloc] initWithTitle:@"Please wait..."
                                                           message:@"Your opponent is considering your request"
                                                          delegate:nil
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:nil];
        [undoMoveWaitAlertView show];
        
        GameEvent gameEvent;
        gameEvent.eventType = kUndoMoveRequest;
        [self send:gameEvent];
    }
    else {
        [self applyUndoMove];
    }

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
}

-(void)playOnline {
    if (session || outStream)
    {
        [self terminateNetworkConnections];
    }
    
    GKPeerPickerController *peerPicker = [[GKPeerPickerController alloc] init];
    peerPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby | GKPeerPickerConnectionTypeOnline;
    peerPicker.delegate = self;
    [peerPicker show];
}

- (void)peerPickerController:(GKPeerPickerController *)peerPicker didSelectConnectionType:(GKPeerPickerConnectionType)type {
    
    if(type == GKPeerPickerConnectionTypeOnline) {
        [peerPicker dismiss];
        [peerPicker autorelease];
        
        [self setupBonjourConnections];
    }
}

//
// This method is "optional, but expected"
//
- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)gkPicker {
    
    gkPicker.delegate = nil;
    // The controller dismisses the dialog automatically.
    [gkPicker autorelease];
}

//
// create a new session or return a previously created session to the peer picker.
// The session that your application returns to the peer picker must advertise itself as a peer (GKSessionModePeer).
//
- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type {
    
    session = [[GKSession alloc] initWithSessionID:kGameIdentifier displayName:nil sessionMode:GKSessionModePeer];
    return session;
}

//
// Tells the delegate that the controller connected a peer to the session. This method is optional but expected. (required)
//
- (void)peerPickerController:(GKPeerPickerController *)gkPicker didConnectPeer:(NSString *)peerID toSession:(GKSession *)theSession {
    
    // Assumes our object will also become the session's delegate.
    session.delegate = self;
    [session setDataReceiveHandler: self withContext:nil];
    // Remove the picker.
    gkPicker.delegate = nil;
    [gkPicker dismiss];
    [gkPicker autorelease];
    
    self.remoteInstanceName = peerID;
    
    // Start your game
    [self gameStarted];
}

-(void)setupBonjourConnections{
    
    [server release];
    server = nil;
    
    [inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inStream release];
    inStream = nil;
    inReady = NO;
    
    [outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outStream release];
    outStream = nil;
    outReady = NO;
    
    server = [TCPServer new];
    [server setDelegate:self];
    NSError* error;
    if(server == nil || ![server start:&error]) {
        NSLog(@"Failed creating server: %@", error);
        [self showNetworkAlert:@"Failed creating server"];
        return;
    }
    
    //Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
    if(![server enableBonjourWithDomain:BONJOUR_DOMAIN applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] name:nil]) {
        [self showNetworkAlert:@"Failed advertising server"];
        return;
    }
    
    [self presentPicker:nil];
    
    //Create and advertise a new game and discover other available games
    [self setupVoiceChat];
}

#pragma mark Peer Picker dialogs

//
// Make sure to let the user know what name is being used for Bonjour advertisement.
// This way, other players can browse for and connect to this game.
// Note that this may be called while the alert is already being displayed, as
// Bonjour may detect a name conflict and rename dynamically.
//
// TODO: taken from an old WiTap sample - seems odd to allocate a view which then
// allocates its own view controller. This behaves badly on the ipad and should be
// updated
//
// TODO: check for the presence of networking. The GKPeerPicker will turn on bluetooth
// but if wifi isn't available, we shouldn't show the "online" option
//
- (void) presentPicker:(NSString*)name {
	if (!picker) {
		picker = [[Picker alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] type:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier]];
		picker.delegate = self;
	}
	
	picker.gameName = name;
	
    pickerModalViewController = [[UIViewController alloc] init];
    pickerModalViewController.view = picker;
    pickerModalViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    [picker sizeToFit];
    [self presentModalViewController:pickerModalViewController animated:YES];
}

- (void) destroyPicker {
    if (!picker)
        return;
    
    [self dismissModalViewControllerAnimated:YES];
    [pickerModalViewController release];
    pickerModalViewController = nil;
	[picker release];
	picker = nil;
}

//
// Added encoded chess moves to packet header and changed argument to uint32_t
// TODO: add error detection
// TODO: add additional message protocol
// Moves are validated before they are sent, but someone could cheat with a hacked client
//
- (void) send:(const GameEvent)message {    
    VoiceMessageHeader msgHdr;
    msgHdr.length = htons(sizeof(GameEvent));
    msgHdr.type = kGamePacketType;
    GameMessage gameMessage;
    gameMessage.header = msgHdr;
    gameMessage.move = message;
    
    NSLog(@"Sending move data: %d bytes", (int)sizeof(GameMessage));
	if (outStream && [outStream hasSpaceAvailable]) {
		if ([outStream write:(const uint8_t *)&gameMessage maxLength:sizeof(GameMessage)] == -1)
		{
			[self showNetworkAlert:@"Failed sending data to peer"];
			return;
		}
	}
    else if (session) {
        NSError *error = nil;
        NSData *theData = [NSData dataWithBytes:&gameMessage length:sizeof(GameMessage)];
        if (![session sendDataToAllPeers:theData withDataMode:GKSendDataReliable error:&error])
        {
            // unable to send data
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Unable to send data"
                                                                message:[error description]
                                                               delegate:nil
                                                      cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
            [alertView show];
            [alertView release];
        }        
    }
}

- (void) openStreams
{
	inStream.delegate = self;
	[inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[inStream open];
	outStream.delegate = self;
	[outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[outStream open];
}

- (void) browserViewController:(BrowserViewController*)bvc didResolveInstance:(NSNetService*)netService
{
	if (!netService) {
		[self setup];
		return;
	}
	
	self.remoteInstanceName = [[NSString stringWithFormat:@"%@,%@,%@",
                           [netService name], [netService type], [netService domain]] retain];
	
	if (![netService getInputStream:&inStream outputStream:&outStream]) {
		[self showNetworkAlert:@"Failed connecting to server"];
		return;
	}
	
	[self openStreams];
}

#pragma mark VoiceChatClient required

// voice chat client's participant ID
- (NSString *)participantID
{
	return session.peerID;	
}

- (void)voiceChatService:(GKVoiceChatService *)voiceChatService sendData:(NSData *)data toParticipantID:(NSString *)participantID
{	
	//Notice the participantID is not used in the send method.  This is because our application only has 1 (!) connection.
	//If we were connected to a server where there were N possible destinations for this message, the participantID would be used 
	//to distinguish which of the N participants we intend to send the data to.
//	[self performSelectorOnMainThread:@selector(voiceChatSend:) withObject:data waitUntilDone:NO];
    
    [session sendData: data toPeers:[NSArray arrayWithObject: participantID] withDataMode: GKSendDataReliable error: nil];
}

-(void)setupBoard {
    
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
// Load the players list, if there is a saved game in progress or from the defaults
//
- (NSArray *)loadSavedPlayers {
    NSString *errorDesc = nil;
    NSPropertyListFormat format;
    NSString *plistPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:@"players.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:@"players" ofType:@"plist"];
    }
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSArray *playerArray = (NSArray *)[NSPropertyListSerialization
                                          propertyListFromData:plistXML
                                          mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                          format:&format
                                          errorDescription:&errorDesc];
    if (!playerArray) {
        NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
    }
    
    return playerArray;
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

//
// If we display an error or an alert that the remote disconnected, handle dismissal and return to setup
//
- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == suggestedMoveAlertView)
    {
        [suggestedMoveAlertView release];
        suggestedMoveAlertView = nil;
        
        if (buttonIndex == 1)
        {
            [board movePieceFrom:moveHint.sourceSquare to:moveHint.destinationSquare];
            if (outStream || session)      // playing against nearby peer
            {
                GameEvent gameEvent;
                gameEvent.eventType = kNormalMoveRequest;
                gameEvent.encodedMove = [moveHint encodedMove];
                [self send:gameEvent];
            }        
            [moveHint release];
        }
    }
    else if (alertView == voiceChatInvitationAlertView)
    {
        if (buttonIndex == 1)
        {
            [self acceptVoiceChatInvitation];
        }
        else {
            [pendingParticipantID release];
            pendingParticipantID = nil;
        }
        [voiceChatInvitationAlertView release];
        voiceChatInvitationAlertView = nil;
    }
    else if (alertView == startNewGameAlertView)
    {
        if (buttonIndex == 1)
        {
            GameEvent gameEvent;
            gameEvent.eventType = kResignRequest;   // player is ending game already underway
            [self send:gameEvent];
            [self applyStartNewGame];
        }
        [startNewGameAlertView release];
        startNewGameAlertView = nil;
    }
    else if (alertView == undoMoveRequestAlertView)
    {
		NSLog(@"Undo move request alert view");
        GameEvent gameEvent;
        gameEvent.eventType = kUndoMoveResponse;
        gameEvent.encodedMove = buttonIndex;        // let the receiver decipher the button index
        if (buttonIndex == 1)                       // allow
        {
            [self applyUndoMove];
        }
		else
		{
			NSLog(@"Request declined");
		}
        [undoMoveRequestAlertView release];
        undoMoveRequestAlertView = nil;
    }
}

//
// notification callback for think thread
//
-(void)stoppedThinking {
    
    [hintButton setEnabled:YES];
    [playButton setEnabled:YES];
    
    ChessMove *move = board.searchAgent.myMove;
    
    NSLog(@"Stopped thinking: move = %@", move);
    
    if (!moveExpected) {
        
        moveHint = [move retain];
        
        suggestedMoveAlertView = [[UIAlertView alloc] initWithTitle:@"Suggested move"
                                                        message:[move description]
                                                       delegate:self
                                              cancelButtonTitle:@"No thanks" otherButtonTitles:@"Accept", nil];
        [suggestedMoveAlertView show];
        
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
    
    if ([board.searchAgent isThinking]) {
        label.text = [board.searchAgent statusString];
        [board.searchAgent checkClock];
    }
}

#pragma mark view loading

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateStatus:)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startedThinking)
                                                 name:@"StartedThinking" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stoppedThinking)
                                                 name:@"StoppedThinking" object:nil];

    animateMove = NO;
    autoPlay = NO;
    
    // initial view with white at the bottom of the board
    boardDirection = 1.0;
    gameScale = 1.0;
    boardScale = 0.925;
    gameState = kGameStateNotStarted;
    
    [self addBoardLayer];
    [self addSquares];
    [self addLabels];

    [self updateBoardTransforms];
    [self startNewGame];
    
    // TODO: this should be cleaned up in viewDidUnload
    currentMessageBuffer = [[NSMutableData alloc] initWithLength:0];
    currentMessageHeader = NULL;    
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

- (void)terminateNetworkConnections {
    
    // deal with GameKit bluetooth sessions
    if (session){
        [self endSession];
    }
    
    AudioSessionSetActive(NO);
	
	[inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[inStream release];
    inStream = nil;
	
	[outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[outStream release];
    outStream = nil;
	
	[server release];
    server = nil;
	[picker release];
    picker = nil;
	
	if(currentMessageHeader) free(currentMessageHeader);
    currentMessageHeader = nil;
	[currentMessageBuffer release];
    currentMessageBuffer = nil;
}

- (void)dealloc {
    
    [squares release];
    [labels release];
    
    if (board) {
        [board release];
    }
    [redoList release]; redoList = nil;
    [history release]; history = nil;
    
    [self terminateNetworkConnections];
    
    [super dealloc];
}

@end

@implementation ChessMailViewController (NSStreamDelegate)

- (void) stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode
{
	switch(eventCode) {
		case NSStreamEventOpenCompleted:
		{
			[self destroyPicker];
			
			[server release];
			server = nil;
			
			if (stream == inStream)
				inReady = YES;
			else
				outReady = YES;
            
			
			if (inReady && outReady) {
                [self gameStarted];
			}
			break;
		}
			
            //The bulk of the code in this case is written to remain a good, non-blocking citizen
		case NSStreamEventHasBytesAvailable:
		{
			if (stream == inStream) {
				uint16_t maxLength = 0;
				GameEvent gameEvent;
				NSInteger recvLen = 0;
				unsigned char buffer[MAX_VOICE_CHAT_PACKET_SIZE];
                bzero(buffer, MAX_VOICE_CHAT_PACKET_SIZE);
				
				//STEP 1: Figure out how much more we need to pull
				if (currentMessageHeader != NULL) {
					//if we are working on a message from a previous callback
					maxLength = currentMessageHeader->length - [currentMessageBuffer length];
				} else {
					//or We should be retreiving our message header
					maxLength = sizeof(VoiceMessageHeader) - [currentMessageBuffer length];
				}	
				
				//Step 2: Pull what we need
				recvLen = [inStream read:(uint8_t *)buffer maxLength:maxLength];
				
				if(recvLen <= 0) {
					if ([stream streamStatus] != NSStreamStatusAtEnd)
						[self showNetworkAlert:@"Failed reading data from peer"];
				} else {					
					
					//Step 3: save the received bytes into our working buffer
					[currentMessageBuffer appendBytes:buffer length:recvLen];
					
					if(recvLen != maxLength) return;  //since we did not finish receiving the bytes for the message we should return
					
					//Step4: we have either finished reading the message header
					if (NULL == currentMessageHeader) {
						
						VoiceMessageHeader *messageHeader = calloc(sizeof(VoiceMessageHeader), 1);
						memcpy(messageHeader, [currentMessageBuffer bytes], sizeof(VoiceMessageHeader));
						
						messageHeader->length  = ntohs(messageHeader->length);
						currentMessageHeader = messageHeader;
						[currentMessageBuffer setLength:0];
						
						//now return to get the actual message in the next callback
						return;
						
					} else { // or we have finished reading the actual message					
						
						if (currentMessageHeader->type == kVoicePacketType) {
							[vcService receivedData:[NSData dataWithData:currentMessageBuffer] fromParticipantID:remoteInstanceName];
                            
						} else if (currentMessageHeader->type == kGamePacketType){ 							
							//We received a remote move, update the board
							[currentMessageBuffer getBytes:&gameEvent length:currentMessageHeader->length];
                            
                            [self receivedGameEvent:gameEvent];
                            
						}
                        else {
                            [self showNetworkAlert:[NSString stringWithFormat:@"received unknown message type %d",
                                                    currentMessageHeader->type]];
                        }

					}
					
					// all done. clear the working buffer
					if(currentMessageHeader) free(currentMessageHeader);
					currentMessageHeader = NULL;
					[currentMessageBuffer setLength:0];
					
				}
			}
			break;
		}
		case NSStreamEventEndEncountered:
		{
			UIAlertView*			alertView;
			
			NSLog(@"%s", (char *)_cmd);
			
			alertView = [[UIAlertView alloc] initWithTitle:@"Peer Disconnected!"
                                                   message:nil delegate:nil cancelButtonTitle:nil
                                         otherButtonTitles:@"Continue", nil];
			[alertView show];
			[alertView release];
			[self stopVoiceChat];
			hasTCPServer = NO;
			break;
		}
		default:
			NSLog(@"Received unhandled eventCode %d", eventCode);
	}
}
@end

@implementation ChessMailViewController (TCPServerDelegate)

- (void) serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)string
{
	NSLog(@"serverDidEnableBonjour:%s", _cmd);
	[self presentPicker:string];
}

- (void)didAcceptConnectionForServer:(TCPServer*)tcpServer inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr
{
	
	if (inStream || outStream || server != tcpServer)
		return;
	
	[server release];
	server = nil;
	
	inStream = istr;
	[inStream retain];
	outStream = ostr;
	[outStream retain];
	
	[self openStreams];
	
	hasTCPServer = YES;
}

@end

@implementation ChessMailViewController (VoiceChatClient)

#pragma mark Voice Chat Client methods
-(void) setupVoiceChat {
    
	vcService = [GKVoiceChatService defaultVoiceChatService];
	vcService.client = self;

    // TODO: move chat client into a separate class
//    MyChatClient *myClient = [[MyChatClient alloc] initWithSession: session];
//    [GKVoiceChatService defaultVoiceChatService].client = myClient;
	
	hasTCPServer = NO; //use this ivar to differentiate which devices is initiating the chat
	    
    //set up the audio session
#ifdef USE_BASIC_AVSESSION 
	//most simple setup, not including routes, interruptions, or hardware sample rate preferences
	NSError *error = nil;
	AVAudioSession *audioSession = [AVAudioSession sharedInstance]; 
	[audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error: &error]; 
	[audioSession setActive: YES error: &error]; 
	
#else
	
	//more advanced path
	didStartVoiceChat = NO;
	interruptedVoiceChat = NO;
	[self setupAudioSession];
	
#endif
}

-(void)startVoiceChat {
    
    /*
     We usually only need to call start on one side, so we use the hasTCPServer to determine who should call start
     We also don't want to call startVoiceChat if we are already in the middle of a voice chat.
     */
    if (!hasTCPServer && !didStartVoiceChat) {
        [self resetAudioSessionProperties];
        
        didStartVoiceChat = [vcService startVoiceChatWithParticipantID:remoteInstanceName error:nil];
        remoteParticipantID = [remoteInstanceName copy];
        
        if (didStartVoiceChat) {
            //Do something with the UI
        } else {
            //Do something with the UI
        }
    }
}

//convenience method that wrap the voice chat service stop voice chat.
-(void) stopVoiceChat
{
	if(!remoteParticipantID) return;
	
	[vcService stopVoiceChatWithParticipantID:remoteParticipantID];
	[remoteParticipantID release];
	remoteParticipantID = nil;
}

//The important takeaway is that you need some way to unwrap and wrap your voice chat packets.
-(void) voiceChatSend:(NSData *)data
{
	if(outStream && [outStream hasSpaceAvailable]){
		
		
		VoiceMessageHeader messageHeader;
		messageHeader.type = kVoicePacketType;
		messageHeader.length = htons((uint16_t)[data length]);
		
		if(-1 == [outStream write:(const uint8_t *)&messageHeader maxLength:sizeof(VoiceMessageHeader)]){
			[self stopVoiceChat];
			[self showNetworkAlert:@"Failed sending data to peer"];
			return;
		}
		
		if(-1 == [outStream write:[data bytes] maxLength:[data length]]){
			[self stopVoiceChat];
			[self showNetworkAlert:@"Failed sending data to peer"];
			return;
		}
		
	}else{
		
		[self stopVoiceChat];
	}
}

- (void)voiceChatService:(GKVoiceChatService *)voiceChatService didStartWithParticipantID:(NSString *)participantID
{
	NSLog(@"voiceChatService:didStartWithParticipantID:");
	didStartVoiceChat = YES;
	//Put some UI up indicating the voice chat started
}

- (void)voiceChatService:(GKVoiceChatService *)voiceChatService didNotStartWithParticipantID:(NSString *)participantID error:(NSError *)error
{
	NSLog(@"voiceChatService:didNotStartWithParticipantID: error = %@", error);
	didStartVoiceChat = NO;
	//Indicate in the UI that the voice chat did not start
}

- (void)voiceChatService:(GKVoiceChatService *)voiceChatService didStopWithParticipantID:(NSString *)participantID error:(NSError *)error
{
	NSLog(@"voiceChatService:didStopWithParticipantID: error = %@", error);
	didStartVoiceChat = NO;
	//Indicate in the UI that the voice chat stopped	
}

- (void)voiceChatService:(GKVoiceChatService *)voiceChatService didReceiveInvitationFromParticipantID:(NSString *)participantID callID:(NSInteger)callID
{
	NSLog(@"voiceChatService:didReceiveInvitationFromParticipantID:");
    
    voiceChatInvitationAlertView = [[UIAlertView alloc] initWithTitle:@"Voice Chat Invitation"
                                                    message:[NSString stringWithFormat:@"%@ requests permission to talk", participantID]
                                                   delegate:self cancelButtonTitle:@"Deny" otherButtonTitles:@"Accept", nil];
    [voiceChatInvitationAlertView show];
    
    pendingParticipantID = [participantID retain];
    pendingCallID = callID;
}

-(void)acceptVoiceChatInvitation
{
    didStartVoiceChat = YES;
	remoteParticipantID = remoteInstanceName;
	[self resetAudioSessionProperties];
	[vcService acceptCallID:pendingCallID error:nil];
    
    // for some reason we aren't using the participant ID sent in the invitation callback
    [pendingParticipantID release];
    pendingParticipantID = nil;
}

#pragma mark Voice Chat audio session convenience methods

/* sets up the audio session to handle interrupts and play the sound to the device we desire */
-(void) setupAudioSession
{
	AudioSessionInitialize (
							NULL,
							NULL,
							InterruptionListenerCallback,
							self
							);
	
	AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, RouteChangedListener, self);
	[self resetAudioSessionProperties];
}

/* Sets the properties of the audio session and sets the session to active */
-(void) resetAudioSessionProperties
{
	UInt32	dataSize,
	sessionCategory;
	CFStringRef currentRoute;
	OSStatus result;
	Float64 sampleRate;
	
	sessionCategory  = kAudioSessionCategory_PlayAndRecord;
	result = AudioSessionSetProperty (
									  kAudioSessionProperty_AudioCategory,
									  sizeof (sessionCategory),
									  &sessionCategory
									  );	
	sampleRate = 44100.0; //8000.0 if no other audio going to be played
	dataSize = sizeof(sampleRate);
	
	result = AudioSessionSetProperty (
									  kAudioSessionProperty_PreferredHardwareSampleRate,
									  dataSize,
									  &sampleRate
									  );
	
	dataSize = sizeof(CFStringRef);
	
	currentRoute = NULL;
	
	result = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &dataSize, &currentRoute);
	
	if([(NSString *) currentRoute hasPrefix: @"Receiver"]){
		
		UInt32 route = kAudioSessionOverrideAudioRoute_Speaker;
		dataSize = sizeof(route);
		result = AudioSessionSetProperty (
										  kAudioSessionProperty_OverrideAudioRoute,
										  dataSize,
										  &route
										  );
	}
	
	AudioSessionSetActive(YES);	
}

- (void) handleAudioInterruption:(BOOL) isBeginInterrupt
{	
	if(isBeginInterrupt){
		
		if(didStartVoiceChat){
			interruptedVoiceChat = YES;
			[vcService stopVoiceChatWithParticipantID:remoteParticipantID]; //don't call convenience stopVoiceChat, since we want to remember who we were talking to
		}else{
			interruptedVoiceChat = NO;
		}		
	}else{
		if(interruptedVoiceChat){
			
			NSError *error = nil;
			interruptedVoiceChat = NO;
			
			[self resetAudioSessionProperties]; //make sure our audio session is active again
			
			//if we are still connected to the last person we chatted with
			if([remoteInstanceName isEqualToString:remoteParticipantID]){
				didStartVoiceChat = [vcService startVoiceChatWithParticipantID:remoteParticipantID error:&error];
			}else{
				//else clear the remoteParticipantID
				[remoteParticipantID release];
				remoteParticipantID = nil;
			}
			
			if(didStartVoiceChat){
				//Do something with the UI
			}else{
				//Do something with the UI
			}
		}else{
			[self resetAudioSessionProperties];
			
		}
	}
}
@end

#pragma mark Voice Chat audio session callback routines

/*Make sure you implement the interruption listener, so that if your client gets a call, you can resume your audio later */
static void InterruptionListenerCallback (void	*inUserData, UInt32	interruptionState) 
{
	ChessMailViewController *app  = (ChessMailViewController *) inUserData;
	[app handleAudioInterruption:(interruptionState == kAudioSessionBeginInterruption)];
}

/* callback routine ensures that the loud speaker is used on the iPhone */
static void RouteChangedListener(void* _self, AudioSessionPropertyID inID, UInt32 inDataSize, const void* inData)
{ 
	UInt32 dataSize;
	CFStringRef currentRoute;
	OSStatus result;
	
	currentRoute = NULL;
	dataSize = sizeof(CFStringRef);
	result = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &dataSize, &currentRoute);
	
	if([(NSString *) currentRoute hasPrefix: @"Receiver"]){
		
		UInt32 route = kAudioSessionOverrideAudioRoute_Speaker;
		dataSize = sizeof(route);
		result = AudioSessionSetProperty (
										  kAudioSessionProperty_OverrideAudioRoute,
										  dataSize,
										  &route
										  );
	}		
}

@implementation ChessMailViewController(GKSessionDelegate)

-(void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
    
    switch (state)
    {
        case GKPeerStateConnected:
            // TODO: Inform your game that a peer is connected.
            self.remoteInstanceName = peerID;
            break;
        case GKPeerStateConnecting:
            // TODO: Inform your game that a peer is connecting.
            break;
        case GKPeerStateUnavailable:
            // TODO: Inform your game that a peer is unavailable.
            break;
        case GKPeerStateAvailable:
            // TODO: Inform your game that a peer is available.
            break;
        case GKPeerStateDisconnected:
            // TODO: Inform your game that a peer has left.
            [self endSession];
            break;
    }
}

-(void)mySendDataToPeers: (NSData *) data
{
    // TODO: check for errors here
    [session sendDataToAllPeers: data withDataMode:GKSendDataReliable error: nil];
}

//
// Your application can either choose to process the data immediately, or retain it and process it
// later within your application. Your application should avoid lengthy computations within this method.
//
//  TODO: consolidate common functionality with TCPServer data stream implementation used for wifi connections
//
-(void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{
    NSUInteger dataSize = [data length];
    GameEvent gameEvent = { 0 };
    
    if (dataSize < sizeof(VoiceMessageHeader)) {
        [self showNetworkAlert:[NSString stringWithFormat:@"Insufficient data to read voice message header: got %d", dataSize]];
        return;
    }

    VoiceMessageHeader *messageHeader = calloc(sizeof(VoiceMessageHeader), 1);
    memcpy(messageHeader, [data bytes], sizeof(VoiceMessageHeader));

    messageHeader->length = ntohs(messageHeader->length);
    
    // the move data are the 32-bits following the voice message header
    NSRange dataRange = { sizeof(VoiceMessageHeader), dataSize - sizeof(VoiceMessageHeader) };
    NSLog(@"Receiving data starting at %d with a length of %d bytes", dataRange.location, dataRange.length);

    if (messageHeader->type == kVoicePacketType)
    {
        void *bytes = (void *)[data bytes];
        bytes += dataRange.location;
        NSData *dataWithoutHeader = [NSData dataWithBytesNoCopy:bytes length:dataRange.length];
        [vcService receivedData:dataWithoutHeader fromParticipantID:remoteInstanceName];
    }
    else if (messageHeader->type == kGamePacketType)
    {
        //We received a remote move, update the board
        [data getBytes:&gameEvent range:dataRange];
        
        [self receivedGameEvent:gameEvent];
    }
    else {
        [self showNetworkAlert:[NSString stringWithFormat:@"Received unknown message type %d", messageHeader->type]];
    }

    free(messageHeader);
}

-(void)endSession {
    // terminate voice session
    [self stopVoiceChat];
    
    [session disconnectFromAllPeers];
    session.available = NO;
    [session setDataReceiveHandler: nil withContext: nil];
    session.delegate = nil;
    [session release];
    session = nil;
}

@end

