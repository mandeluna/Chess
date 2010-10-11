//
//  ChessMailViewController.h
//  ChessMail
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
@class ChessSettingsViewController;

enum {
	kVoicePacketType = 0, kGamePacketType = 1
};

typedef struct {
	uint8_t type;
	uint16_t length;
	uint16_t padding; //to 4 bytes total
} VoiceMessageHeader;


@interface ChessMailViewController : UIViewController <ChessUserAgent, UIActionSheetDelegate, BrowserViewControllerDelegate, TCPServerDelegate, GKVoiceChatClient, GKPeerPickerControllerDelegate, GKSessionDelegate> {
    
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
	NSString			*remoteInstanceName;    //name of game counterparty
	NSString			*remoteParticipantID;   //last voice chat counterparty
    
    // TODO: update session management to use GKSessions
    GKSession           *session;
}

@property(nonatomic, retain) NSMutableArray *history;
@property(nonatomic, retain) NSMutableArray *redoList;
@property(nonatomic, retain) ChessBoard *board;
@property(nonatomic, assign) BOOL usePopoverController;

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
-(void)playOnline;
-(void)setupBoard;

-(BOOL)isPlayerWhite;

#pragma mark VoiceChatClient protocol required methods
- (NSString *)participantID; //voice chat client protocol required method

- (void)voiceChatService:(GKVoiceChatService *)voiceChatService 
				sendData:(NSData *)data 
		 toParticipantID:(NSString *)participantID;

@end

