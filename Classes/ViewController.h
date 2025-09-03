//
//  ViewController.h
//  
//
//  Created by Steve Wart on 2010-08-15.
//  Copyright Steven Wart 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class ChessBoard;
@class ChessPieceLayer;
@class SquareLayer;
@class ChessMove;
@class ViewController;

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

@interface ViewController : UIViewController <UIActionSheetDelegate, UIPopoverControllerDelegate>
{
    CALayer *boardLayer;
    NSMutableArray *squares;
    NSMutableArray *labels;
    ChessPieceLayer *selectedPiece;
    
    ChessBoard *board;
    ChessBoard *startingBoard;
    NSMutableArray *history;
    NSMutableArray *redoList;
    BOOL animateMove;
    BOOL autoPlay;

    NSTimeInterval elapsedTimeWhite;
    NSTimeInterval elapsedTimeBlack;
    BOOL isClockTicking;
    
    CATransform3D boardTransform;   // for scaling to display/hide labels and flipping board to switch sides
    CATransform3D piecesTransform;  // for flipping pieces to compensate for flipping board
    CGFloat boardDirection;         // white is at the top of the screen if this is 1
    CGFloat gameScale;              // game is scaled down for landscape display
    CGFloat boardScale;             // board is scaled down to display labels
    
    ChessMove *moveHint;
}

@property(nonatomic, retain) NSMutableArray *history;
@property(nonatomic, retain) NSMutableArray *redoList;
@property(nonatomic, retain) ChessBoard *board;
@property(nonatomic, assign) BOOL usePopoverController;
@property(nonatomic, retain) NSString *remoteInstanceName;

@property(nonatomic, retain) IBOutlet UILabel *gameStatusLabel;
@property(nonatomic, retain) IBOutlet UILabel *whiteGameClock;
@property(nonatomic, retain) IBOutlet UILabel *blackGameClock;
@property(nonatomic, retain) IBOutlet UILabel *moveListLabel;
@property(nonatomic, retain) IBOutlet UILabel *engineInfoLabel;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *startButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *playButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *undoButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *hintButton;


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

-(void)finishedGame:(NSNotification *)notification;

-(void)gameReset;
-(void)addedPiece:(int)piece at:(int)square white:(BOOL)isWhitePlayer;
-(void)completedMove:(ChessMove *)move white:(BOOL)aBool;
-(void)movedPiece:(int)piece from:(int)sourceSquare to:(int)destSquare;
-(void)removedPiece:(int)piece at:(int)square;
-(void)replacedPiece:(int)oldPiece with:(int)newPiece at:(int)square white:(BOOL)isWhitePlayer;
-(void)undoMove:(ChessMove *)move white:(BOOL)isWhitePlayer;

// playing

-(IBAction)autoPlay;
-(IBAction)play;
-(IBAction)findBestMove;
-(IBAction)newGame;
-(IBAction)undoMove;

-(void)movePieceFrom:(int)sourceSquare to:(int)destSquare;

-(BOOL)isPlayerWhite;

-(NSString *)formatMoveHistory;

@end

