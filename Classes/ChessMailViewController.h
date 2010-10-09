//
//  ChessMailViewController.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-15.
//  Copyright Steven Wart 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChessUserAgent.h"
#import <QuartzCore/QuartzCore.h>

@class ChessBoard;
@class ChessPieceLayer;
@class SquareLayer;
@class ChessMove;
@class ChessSettingsViewController;

@interface ChessMailViewController : UIViewController <ChessUserAgent> {
    
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
    IBOutlet UIBarButtonItem *settingsButton;
    
    CATransform3D boardTransform;   // for scaling to display/hide labels and flipping board to switch sides
    CATransform3D playerTransform;  // for flipping pieces to compensate for flipping board
    CGFloat boardDirection;         // white is at the top of the screen if this is 1
    CGFloat gameScale;              // game is scaled down for landscape display
    CGFloat boardScale;             // board is scaled down to display labels
    
    ChessMove *moveHint;
    
    ChessSettingsViewController *settingsController;
    UINavigationController *settingsNavigationController;
    UIPopoverController *settingsPopoverController;
    
    BOOL usePopoverController;      // true if we are running on an iPad
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

// playing

-(IBAction)autoPlay;
-(IBAction)play;
-(IBAction)findBestMove;    // hint
-(IBAction)newGame;
-(void)movePieceFrom:(int)sourceSquare to:(int)destSquare;
-(IBAction)redoMove;
-(IBAction)thinkAndMove;    // play
-(IBAction)undoMove;
-(IBAction)displaySettings;

@end

