//
//  ViewController.h
//  
//
//  Created by Steve Wart on 10-08-15.
//  Copyright Steven Wart 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <GameKit/GameKit.h>
#import "BrowserViewController.h"
#import "Picker.h"
#import "TCPServer.h"

#import "ChessUserAgent.h"

@class ChessBoard;
@class ChessPieceLayer;
@class SquareLayer;
@class ChessMove;
@class ViewController;
@class WaitingAlertView;

enum {
	kVoicePacketType = 0,
    kGamePacketType
};

// TODO: add game clocks
// TODO: provide option for timed game play
// TODO: add move lists
// TODO: show captured pieces
// TODO: show labels for online opponents
// TODO: status icon to indicate opponent is online
// TODO: status icon to indicate opponent has voice chat enabled
// TODO: provide button to enable/disable voice chat (mute local, mute remote)
// TODO: provide indicator showing voice chat volume during game
// TODO: save game state when quitting
// TODO: restore game state on startup
// TODO: provide option to reconnect with opponent restoring saved game in progress
// TODO: add support for Game Center sessions (GKMatch)
// TODO: set up leaderboards and tournament invitations
// TODO: provide different theme choices for the gameboard and players
// TODO: fix layout of subviews when screen is rotated into landscape mode

// TODO: negotiate which player will be white
// -- at the start of the game, both players have the white pieces facing them
// -- once the network negotiation is complete, we have an alert in NSStreamEventOpenCompleted
// -- need this for BT sessions & GKMatch sessions
// -- game state should be as follows:
//    1. Initial state == invalid: black player undefined, white player specified twice
// We need to enforce that white goes first,
// that one player cannot move when it's another player's turn (can we reuse isThinking flag for computer play?)
// We should keep track of the time spent on each move by each player
// -- if clocks get out of sync, we need a way to resynchronize them
// Assume that each player's computer will enforce the legality of each move
// We should encode # check and ++ double attack (there are a few operators we need - check wikipedia)
// We need to notify users of checkmate and stalemate
// If the board state is repeated more than 3 times (or is it 3 times or more) we should offer the opportunity to draw the game
// -- in general players need options to agree on a draw, or to resign

enum {
    kNormalMoveRequest,         // just moving a piece
    kUndoMoveRequest,           // ask the other player if it's okay to undo a move
    kUndoMoveResponse,          // agree or decline undo request
    kSelectSideRequest,         // request to play as white or black or choose random arbitration
    kSelectSideResponse,        // agree or disagree opponent's request to play white or black
    kSelectSideArbitrationResponse, // random abitration mechanism in case player and opponent can't agree who goes first
    kProposeDrawRequest,        // propose that the game is a draw
    kProposeDrawResponse,       // agree or decline draw proposal
    kProposeResignRequest,      // suggest the other player resign the game
    kResignRequest              // agree to resign or resign unilaterally
};

enum {
    kGameStateNormal,           // game is in progress
    kGameStateNotStarted,       // game hasn't started yet, need to agree which player is white
    kGameStateUndoRequested     // waiting for confirmation to undo a move
};

typedef struct {
    uint8_t eventType;
    uint32_t encodedMove;
} GameEvent;

typedef struct {
	uint16_t length;
	uint8_t type;
} VoiceMessageHeader;

typedef struct {
    VoiceMessageHeader header;
    GameEvent move;
} GameMessage;


@interface ViewController : UIViewController <ChessUserAgent, UIActionSheetDelegate,
	UIPopoverControllerDelegate,
	BrowserViewControllerDelegate, TCPServerDelegate, NSStreamDelegate,
														GKVoiceChatClient, GKPeerPickerControllerDelegate, GKSessionDelegate>
{
    CALayer *boardLayer;
    NSMutableArray *squares;
    NSMutableArray *labels;
    ChessPieceLayer *selectedPlayer;
    int selectionIndex;
    
    ChessBoard *board;
    NSMutableArray *history;
    NSMutableArray *redoList;
    BOOL animateMove;
    BOOL autoPlay;
    BOOL moveExpected;  // YES if the AI should execute the move, otherwise just display a hint
    
    IBOutlet UILabel *label;
    IBOutlet UIBarButtonItem *newGameButton;
    IBOutlet UIBarButtonItem *playButton;
    IBOutlet UIBarButtonItem *undoButton;
    IBOutlet UIBarButtonItem *redoButton;
    IBOutlet UIBarButtonItem *hintButton;
    
    IBOutlet UILabel *whitePlayerLabel;
    IBOutlet UILabel *blackPlayerLabel;
    
    CATransform3D boardTransform;   // for scaling to display/hide labels and flipping board to switch sides
    CATransform3D playerTransform;  // for flipping pieces to compensate for flipping board
    CGFloat boardDirection;         // white is at the top of the screen if this is 1
    CGFloat gameScale;              // game is scaled down for landscape display
    CGFloat boardScale;             // board is scaled down to display labels
    
    ChessMove *moveHint;
    
    BOOL usePopoverController;      // true if we are running on an iPad
    
    // data connections from witap example
    Picker*				picker;
	TCPServer*			server;
	NSInputStream*		inStream;
	NSOutputStream*		outStream;
	BOOL				inReady;
	BOOL				outReady;
    
	//ivars for voice chat
	BOOL				hasTCPServer;
	BOOL				interruptedVoiceChat;
	BOOL				didStartVoiceChat;
	GKVoiceChatService  *vcService;
	VoiceMessageHeader	*currentMessageHeader;
	NSMutableData		*currentMessageBuffer;
	NSString			*remoteInstanceName;    // name of game counterparty
	NSString			*remoteParticipantID;   // last voice chat counterparty
    
    NSString            *pendingParticipantID;  // participant ID of requesting caller
    NSInteger           pendingCallID;          // call ID of requesting caller 
    
    // TODO: update session management to use GKSessions
    GKSession           *session;
    
    // need to keep track of it so we can dismiss it if user attempts to invoke it multiple times
    UIActionSheet       *gameSelectionActionSheet;
    
    UIViewController    *pickerModalViewController;
															
    // this class is the delegate for several different alert views, so we need to keep track of them in the callback
    UIAlertView         *suggestedMoveAlertView;
    UIAlertView         *voiceChatInvitationAlertView;
    UIAlertView         *startNewGameAlertView;
    UIAlertView         *undoMoveRequestAlertView;  // displayed when opponent requests to take back a move
    WaitingAlertView    *undoMoveWaitAlertView;     // displayed while waiting for opponent to respond to above request
    
    int gameState;
    int playerRandomChoice;
    int opponentRandomChoice;
    
    IBOutlet UILabel    *gameStatusLabel;
    IBOutlet UILabel    *whiteGameClockLabel;
    IBOutlet UILabel    *blackGameClockLabel;
    IBOutlet UILabel    *moveListLabel;
    IBOutlet UIButton   *whitePlayerOnlineButton;
    IBOutlet UIButton   *blackPlayerOnlineButton;
    IBOutlet UIButton   *whitePlayerChatStatusButton;
    IBOutlet UIButton   *blackPlayerChatStatusButton;
    IBOutlet UIView     *whitePlayerChatVolumeView;
    IBOutlet UIView     *blackPlayerChatVolumeView;
}

@property(nonatomic, retain) NSMutableArray *history;
@property(nonatomic, retain) NSMutableArray *redoList;
@property(nonatomic, retain) ChessBoard *board;
@property(nonatomic, assign) BOOL usePopoverController;
@property(nonatomic, retain) NSString *remoteInstanceName;

typedef enum {
    kSegmentIndexNew = 0,
    kSegmentIndexHint,
    kSegmentIndexPlay,
    kSegmentIndexAuto,
    kSegmentIndexUndo,
    kSegmentIndexRedo
} SegmentIndex;

// initialize

-(void)addSquares;
-(ChessPieceLayer *)newPiece:(int)piece white:(BOOL)isWhite;

// chess user agent

-(void)gameReset;
-(void)addedPiece:(int)piece at:(int)square white:(BOOL)isWhitePlayer;
-(void)completedMove:(ChessMove *)move white:(BOOL)aBool;
-(void)movedPiece:(int)piece from:(int)sourceSquare to:(int)destSquare;
-(void)removedPiece:(int)piece at:(int)square;
-(void)replacedPiece:(int)oldPiece with:(int)newPiece at:(int)square white:(BOOL)isWhitePlayer;
-(void)finishedGame:(BOOL)result;
-(void)undoMove:(ChessMove *)move white:(BOOL)isWhitePlayer;
-(void)validateGamePosition;

// action sheet delegate

-(void)actionSheetCancel:(UIActionSheet *)actionSheet;
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;

// playing

-(IBAction)autoPlay;
-(IBAction)play;
-(IBAction)findBestMove;    // hint
-(IBAction)newGame;
-(IBAction)redoMove;
-(IBAction)thinkAndMove;    // play
-(IBAction)undoMove;

-(void)movePieceFrom:(int)sourceSquare to:(int)destSquare;

-(BOOL)isPlayerWhite;

#pragma mark VoiceChatClient protocol required methods
- (NSString *)participantID; //voice chat client protocol required method

- (void)voiceChatService:(GKVoiceChatService *)voiceChatService 
				sendData:(NSData *)data 
		 toParticipantID:(NSString *)participantID;

@end

