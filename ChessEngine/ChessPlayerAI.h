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
typedef void (^CompletionCallback)(NSDictionary* finalInfo, ChessSearchStatus status);

@interface ChessPlayerAI : NSObject {
    ChessBoard *board;
    NSArray *boardList;
    int boardListIndex;
    __weak ChessPlayer *player;
    ChessHistoryTable *historyTable;
    ChessTranspositionTable *transTable;
    ChessMoveGenerator *generator;
    int variations[VARIATIONS_SIZE][VARIATIONS_SIZE];
    int activeVariation[VARIATIONS_SIZE];
    int bestVariation[VARIATIONS_SIZE];

    // reporting status
    NSMutableDictionary *reportInfo;
    long nodesVisited;
    long previousNodeCount;
    int ttHits;
    int stamp;
    int alphaBetaCuts;
    NSTimeInterval startTime;
    int ply;

    ChessMove *myMove;
    BOOL shouldCancelSearch;
    ChessSearchStatus status;

    // UCI options
    NSDictionary *uciOptions;
    int depth_limit;                 // maximum number of plies to recurse
    long node_limit;                 // maximum number of nodes to visit
    NSTimeInterval time_limit;       // maximum number of seconds of searching
    BOOL infinite;                   // ignore depth, time & node limits
    int max_depth;                   // furthest depth traversed
    long max_nodes;                  // total nodes visited
}

// board owns the player
@property(nonatomic, weak) ChessPlayer *player;
@property(nonatomic, retain) ChessBoard *board;
@property(nonatomic, retain) ChessMoveGenerator *generator;
@property(nonatomic, readonly) ChessTranspositionTable *transTable;
@property(nonatomic, readonly) ChessHistoryTable *historyTable;
@property(atomic, copy) ChessMove *myMove;

@property(nonatomic, retain) NSDictionary *uciOptions;

@property(nonatomic, copy) UpdateCallback updateCallback;
@property(nonatomic, copy) CompletionCallback completionCallback;

@property(atomic, readonly) BOOL isSearching;
@property(atomic, assign) BOOL shouldCancelSearch;
@property(atomic, assign) ChessSearchStatus status;

// initialize

-(void)setActivePlayer:(ChessPlayer *)player;
-(void)reset;
-(void)reset:(ChessBoard *)board;

// searching

- (void)performSearchWithUCIParams:(NSDictionary<NSString *, id> *)uciParams
                    updateCallback:(UpdateCallback) updateCallback
                completionCallback:(CompletionCallback)completionBlock;
-(void)performSearchWithUCIParams:(NSDictionary<NSString *, id> *)uciParams;
-(void)copyVariation:(ChessMove *)move;
-(ChessMove *)negaScout:(ChessBoard *)theBoard depth:(int)depth alpha:(int)initialAlpha beta:(int)initialBeta;
-(int)ngSearch:(ChessBoard *)theBoard depth:(int)depth alpha:(int)initialAlpha beta:(int)initialBeta;
-(int)quiesce:(ChessBoard *)theBoard alpha:(int)initialAlpha beta:(int)initialBeta;

// thinking

-(BOOL)isReady;
-(void)startSearchThread;
-(void)cancelSearch;
-(void)findMove:(void (^)(NSString *move))completion;
-(void)findMove:(void (^)(NSString *move))completion
         update:(nullable void (^)(NSDictionary *info))update;

// engine

-(NSString *)statusString;
-(void)printUCIInfo:(NSDictionary *)info;
-(void)printCompletionInfo:(NSDictionary *)info;
-(void)initializeTranspositionTable;
-(void)initializeBestVariation;
-(void)initializeActiveVariation;
-(void)assignBestVariation;
-(NSArray *)pvMoves:(ChessBoard *)board;

@end
