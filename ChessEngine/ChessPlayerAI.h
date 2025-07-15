//
//  ChessPlayerAI.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>

#define VARIATIONS_SIZE  11

@class ChessBoard;
@class ChessPlayer;
@class ChessMove;
@class ChessHistoryTable;
@class ChessTranspositionTable;
@class ChessMoveGenerator;

@interface ChessPlayerAI : NSObject {
    
    ChessBoard *board;
    NSArray *boardList;
    int boardListIndex;
    ChessPlayer *player;
    ChessHistoryTable *historyTable;
    ChessTranspositionTable *transTable;
    ChessMoveGenerator *generator;
    int variations[VARIATIONS_SIZE][VARIATIONS_SIZE];
    int activeVariation[VARIATIONS_SIZE];
    int bestVariation[VARIATIONS_SIZE];
    int nodesVisited;
    int ttHits;
    int stamp;
    int alphaBetaCuts;
    long startTime;
    int ply;
    ChessMove *myMove;
    BOOL isThinking;
    BOOL stopThinking;
    BOOL useNegaScout;
}

@property(nonatomic, assign) ChessPlayer *player;
@property(nonatomic, assign) ChessBoard *board;
@property(nonatomic, assign) ChessMoveGenerator *generator;
@property(nonatomic, copy) ChessMove *myMove;
@property(nonatomic, assign) BOOL useNegaScout;

// initialize

-(void)setActivePlayer:(ChessPlayer *)player;
-(void)reset;
-(void)reset:(ChessBoard *)board;

// searching

-(void)copyVariation:(ChessMove *)move;
-(ChessMove *)mtdfSearch:(ChessBoard *)theBoard score:(int)estimate depth:(int)depth;
-(ChessMove *)negaScout:(ChessBoard *)theBoard depth:(int)depth alpha:(int)initialAlpha beta:(int)initialBeta;
-(int)ngSearch:(ChessBoard *)theBoard depth:(int)depth alpha:(int)initialAlpha beta:(int)initialBeta;
-(int)quiesce:(ChessBoard *)theBoard alpha:(int)initialAlpha beta:(int)initialBeta;
-(int)search:(ChessBoard *)theBoard depth:(int)depth alpha:(int)initialAlpha beta:(int)initialBeta;
-(ChessMove *)searchMove:(ChessBoard *)theBoard depth:(int)depth alpha:(int)initialAlpha beta:(int)initialBeta;

// thinking

-(BOOL)isThinking;
-(void)startThinking;
-(void)thinkThread;
-(void)findMove: (void (^)(ChessMove *move))completion;
-(long)timeToThink;
-(void)checkClock;

// accessing

-(NSString *)statusString;

@end
