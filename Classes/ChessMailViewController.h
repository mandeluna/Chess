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
//    NSDictionary *playerLayers;
    NSMutableArray *squares;
    ChessPieceLayer *selectedPlayer;
    int selectionIndex;
    
    int numPlayers;
    int numPlayerRows;
    
    BOOL shouldShowTextLayers;
    
    ChessBoard *board;
    NSMutableArray *history;
    NSMutableArray *redoList;
    BOOL animateMove;
    BOOL autoPlay;
}

//@property(nonatomic, retain) NSDictionary *playerLayers;
@property(nonatomic, retain) NSMutableArray *history;
@property(nonatomic, retain) NSMutableArray *redoList;
@property(nonatomic, retain) ChessBoard *board;

// initialize

-(void)addSquares;
-(ChessPieceLayer *)newPiece:(int)piece white:(BOOL)isWhite;
-(SquareLayer *)newSquare;

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
-(IBAction)findBestMove;    // hint
-(IBAction)newGame;
-(void)movePieceFrom:(int)sourceSquare to:(int)destSquare;
-(IBAction)redoMove;
-(IBAction)thinkAndMove;    // play
-(IBAction)undoMove;

@end

