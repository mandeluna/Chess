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

@interface ChessMailViewController : UIViewController <ChessUserAgent> {
    
    CALayer *boardLayer;
    NSDictionary *playerLayers;
    ChessPieceLayer *selectedPlayer;
    CGPoint boardIndexForSelectedPlayer;
    
    int numPlayers;
    int numPlayerRows;
    
    BOOL shouldShowTextLayers;
    
    ChessBoard *board;
    NSMutableArray *history;
    NSMutableArray *redoList;
    BOOL animateMove;
    BOOL autoPlay;
}

@property(nonatomic, retain) NSDictionary *playerLayers;
@property(nonatomic, retain) NSMutableArray *history;
@property(nonatomic, retain) NSMutableArray *redoList;

-(void)newGame;

@end

