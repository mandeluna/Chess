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

typedef NS_ENUM(NSUInteger, ChessSearchStatus) {
    ChessSearchStatusInProgress,
    ChessSearchStatusCompleted,
    ChessSearchStatusStopped
};

typedef void (^UpdateCallback)(NSDictionary *info);
typedef void (^CompletionCallback)(NSString* bestMove, NSDictionary* finalInfo, ChessSearchStatus status);

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
    int previousNodeCount;
    int ttHits;
    int stamp;
    int alphaBetaCuts;
    NSTimeInterval startTime;
    int ply;
    ChessMove *myMove;
    NSThread *currentThread;
    BOOL isSearching;
    BOOL shouldCancelSearch;
    int depth_limit;                // maximum number of plies to recurse
    int node_limit;                 // maximum number of nodes to visit
    NSTimeInterval time_limit;      // maximum number of seconds of searching
    int max_depth;                  // furthest depth traversed
    int max_nodes;                  // total nodes visited
    BOOL debug;                     // UCI debug value
}

@property(nonatomic, assign) ChessPlayer *player;
@property(nonatomic, assign) ChessBoard *board;
@property(nonatomic, assign) ChessMoveGenerator *generator;
@property(nonatomic, readonly) ChessTranspositionTable *transTable;
@property(nonatomic, readonly) ChessHistoryTable *historyTable;
@property(nonatomic, copy) ChessMove *myMove;

@property(nonatomic, assign) int depth_limit;
@property(nonatomic, assign) int node_limit;
@property(nonatomic, assign) NSTimeInterval time_limit;

@property(nonatomic, assign) int ply;
@property(nonatomic, assign) NSTimeInterval startTime;
@property(nonatomic, assign) int nodesVisited;
@property(nonatomic, assign) int previousNodeCount;
@property(nonatomic, assign) int ttHits;
@property(nonatomic, assign) int alphaBetaCuts;
@property(nonatomic, assign) int currentNPS;
@property(nonatomic, assign) BOOL debug;
@property(nonatomic, assign) BOOL isSearching;
@property(nonatomic, assign) BOOL shouldCancelSearch;

// initialize

-(void)setActivePlayer:(ChessPlayer *)player;
-(void)reset;
-(void)reset:(ChessBoard *)board;

// searching

- (void)performSearchWithUCIParams:(NSDictionary<NSString *, id> *)uciParams
                    updateCallback:(void (^)(NSDictionary<NSString *, id> *info))updateCallback
                   completionBlock:(void (^)(NSString *bestMove, NSDictionary<NSString *, id> *finalInfo, ChessSearchStatus status))completionBlock;
-(void)performSearchWithUCIParams:(NSDictionary<NSString *, id> *)uciParams;
-(void)copyVariation:(ChessMove *)move;
-(ChessMove *)negaScout:(ChessBoard *)theBoard depth:(int)depth alpha:(int)initialAlpha beta:(int)initialBeta;
-(int)ngSearch:(ChessBoard *)theBoard depth:(int)depth alpha:(int)initialAlpha beta:(int)initialBeta;
-(int)quiesce:(ChessBoard *)theBoard alpha:(int)initialAlpha beta:(int)initialBeta;

// thinking

-(BOOL)isThinking;
-(void)startSearchThread;
-(void)cancelSearch;
-(void)searchThread;
-(void)findMove: (void (^)(NSString *move))completion;
-(void)bestMove;

// engine

-(NSString *)statusString;
-(void)printUCIInfo:(NSDictionary *)info;
-(void)printCompletionInfo:(NSDictionary *)info;
-(void)initializeTranspositionTable;
-(void)initializeBestVariation;
-(void)initializeActiveVariation;
-(void)assignBestVariation;
-(NSArray *)pvMoves;

@end
