//
//  ChessMailViewController.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-15.
//  Copyright Steven Wart 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChessUserAgent.h"

#define BOARD_GRID_COUNT 8.0f

@class ChessBoard;
@class ChessPieceLayer;
@class SquareLayer;
@class ChessMove;

@interface ChessMailViewController : UIViewController <ChessUserAgent> {
    
    CALayer *boardLayer;
    NSMutableArray *squares;
    ChessPieceLayer *selectedPlayer;
    int selectionIndex;
    
    int numPlayers;
    int numPlayerRows;
    
    ChessBoard *board;
    NSMutableArray *history;
    NSMutableArray *redoList;
    BOOL animateMove;
    BOOL autoPlay;
    BOOL moveExpected;  // YES if the AI should execute the move, otherwise just display a hint
    
    IBOutlet UILabel *label;
    IBOutlet UIButton *hintButton;
    IBOutlet UIButton *playButton;
    IBOutlet UIButton *autoPlayButton;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    IBOutlet UIProgressView *percentFullIndicator;
}

@property(nonatomic, retain) NSMutableArray *history;
@property(nonatomic, retain) NSMutableArray *redoList;
@property(nonatomic, retain) ChessBoard *board;

// initialize

-(void)addSquares;
-(ChessPieceLayer *)newPiece:(int)piece white:(BOOL)isWhite;
-(SquareLayer *)squareLayer;    // return a new instance with a retain count of +0

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

@end

