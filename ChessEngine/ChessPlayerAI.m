//
//  ChessPlayerAI.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "Logger.h"
#import "ChessConstants.h"
#import "ChessPlayerAI.h"
#import "ChessPlayer.h"
#import "ChessMove.h"
#import "ChessBoard.h"
#import "ChessHistoryTable.h"
#import "ChessMoveList.h"
#import "ChessMoveGenerator.h"
#import "ChessTTEntry.h"
#import "ChessTranspositionTable.h"
#import "NSNotificationCenter+MainThread.h"

#define kAlphaBetaGiveUp        (-29990)
#define kAlphaBetaIllegal       (-31000)
#define kAlphaBetaMaxVal        (30000)
#define kAlphaBetaMinVal        (-30000)
#define kValueAccurate          2
#define kValueBoundary          4
#define kValueLowerBound        4
#define kValueUpperBound        5
#define kValueThreshold         200


NSString *CancelExceptionName = @"CancelSearchException";

@implementation ChessPlayerAI

@synthesize player, board, generator, myMove, depth_limit, node_limit, time_limit, transTable, historyTable, ply, startTime, nodesVisited, previousNodeCount, ttHits, alphaBetaCuts, currentNPS, isSearching, shouldCancelSearch, status;

#pragma mark derived properties

-(int)score {
  return myMove.value;
}

-(BOOL)isReady {
    return self.status == ChessSearchStatusStopped;
}

#pragma mark initialize

+ (void)initialize{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = @{
        time_limit_key : @5000.0,  // should be 1-5 seconds, but that wreaks havoc with debugging
        depth_limit_key : @20,
        node_limit_key : @50000
    };

    [defaults registerDefaults:appDefaults];
}

Logger *logger;

-(id)init {

    if (self = [super init]) {
        historyTable = [[ChessHistoryTable alloc] init];
        nodesVisited = ttHits = alphaBetaCuts = stamp = 0;
        self.time_limit = [[NSUserDefaults standardUserDefaults] doubleForKey:time_limit_key];
        self.depth_limit = (int)[[NSUserDefaults standardUserDefaults] integerForKey:depth_limit_key];
        self.node_limit = (long)[[NSUserDefaults standardUserDefaults] integerForKey:node_limit_key];
        self.status = ChessSearchStatusStopped;
        logger = [Logger defaultLogger];
        [self reset];
    }

    return self;
}

-(void)setActivePlayer:(ChessPlayer *)aPlayer {

    self.player = aPlayer;
    self.board = aPlayer.board;
    self.generator = board.generator;

    [self reset];
}

-(void)reset {
  if (transTable) {
    [transTable clear];
  }

  [historyTable clear];
}

-(void)reset:(ChessBoard *)aBoard {

    [self reset];

    if (!boardList) {
        NSMutableArray *boards = [NSMutableArray arrayWithCapacity:NUM_PLIES];
        for (int i=0; i<NUM_PLIES; i++) {
            ChessBoard *newBoard = [aBoard copy];
            [boards addObject:newBoard];
#if !__has_feature(objc_arc)
          [newBoard release];
#endif
        }
        boardListIndex = 0;
        boardList = [NSArray arrayWithArray:boards];
#if !__has_feature(objc_arc)
          [boardList retain];
#endif
    }
    self.board = aBoard;
}

#if !__has_feature(objc_arc)
-(void)dealloc {
    [boardList release];
    [super dealloc];
}
#endif


#pragma mark private

//
// Initialize the transposition table. Note: For now we only use 64k entries since they're somewhat space intensive.
// If we should get a serious speedup at some point we may want to increase the transposition table - 256k seems like a good idea;
// but right now 256k entries cost us roughly 10MB of space. So we use only 64k entries (2.5MB of space).
// If you have doubts about the size of the transition table (e.g., if you think it's too small or too big) then modify the value
// below and have a look at ChessTranspositionTable>>clear which can print out some valuable statistics.
// TODO: this should be a run-time setting
// TODO: depth 10 seems unattainable without intelligently sorting the move list
//
-(void)initializeTranspositionTable {

    transTable = [[ChessTranspositionTable alloc] initWithBits:16]; // 64k entries (maxes out at depth 7)
//    transTable = [[ChessTranspositionTable alloc] initWithBits:18]; // 256k entries (~34Mb, max depth 8)
//    transTable = [[ChessTranspositionTable alloc] initWithBits:20]; // 1024k entries (~86Mb, max depth 9)
    // [256k entries improve utilization on ipad] but startup on iPhone 3G is painfully slow
    // timing on MacBook Air M1 (2021 model)
}

-(void)initializeBestVariation {
    bestVariation[0] = 0;
}

-(void)initializeActiveVariation {
    activeVariation[0] = 0;
}

-(void)assignBestVariation {
    memcpy(bestVariation, activeVariation, VARIATIONS_SIZE * sizeof(int));
}

-(void)assignActiveVariation {
    memcpy(activeVariation, variations[0], VARIATIONS_SIZE * sizeof(int));
}

#pragma mark searching

-(NSArray *)pvMoves {
    int *pv = bestVariation;
    int count = pv[0];
    if (count < 1) {
        return @[];
    }
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    count = pv[0];
    for (int i = 1; i < count + 1; i++) {
        ChessMove *move = [ChessMove decodeFrom:pv[i]];
        result[i - 1] = [move uciString];
    }
    return result;
}

-(void)copyVariation:(ChessMove *)move {
    int count = 0;
    int *av = variations[ply];

    if (ply < 9) {
      int *mv = variations[ply + 1];
      count = mv[0];
      for (int i = 1; i < count + 2; i++) {
          av[i + 1] = mv[i];
      }
    }
    av[0] = count + 1;
    av[1] = [move encodedMove];
}

//  Destructively replace elements from start to stop in the array
//  starting at index, repStart, in the replacement array.
-(void)replace:(int[])array from:(int)start to:(int)stop with:(int[])replacement startingAt:(int)repStart {
  int index, repOff;
  repOff = repStart - start;
  for (index = start; index < stop; index++) {
    array[index] = replacement[repOff + index];
  }
}

//
// Modified version to return the move rather than the score
//
-(ChessMove *)negaScout:(ChessBoard *)theBoard depth:(int)depth alpha:(int)initialAlpha beta:(int)initialBeta {

    assert(initialAlpha < initialBeta);

    if (ply < 10) {
        variations[ply][0] = 0;
    }
    ply = 0;
    int alpha = initialAlpha;
    int beta = initialBeta;
    int bestScore = kAlphaBetaMinVal;
    ChessMove *goodMove = nil;

    // generate new moves
    ChessMoveList *moveList = [generator findPossibleMovesFor:theBoard.activePlayer];

    if (nil == moveList)
        return nil;

    if ([moveList count] == 0) {
        [generator recycleMoveList:moveList];
        return nil;
    }

    // sort move list according to history heuristics
    [moveList sortUsing:historyTable];

    // and search
    int a = alpha;
    int b = beta;
    BOOL notFirst = NO;

    ChessMove *move = [moveList next];
    int count = 0;

    while (nil != move) {
        count++;
        if (ply >= [boardList count]) {
            NSString *reason = [NSString stringWithFormat:@"ply=%d", ply];
            [logger raiseExceptionName:@"invalid index into boardList" reason:reason];
        }
        ChessBoard *newBoard = [boardList objectAtIndex:ply];
        [newBoard copyBoard:theBoard];
        [newBoard nextMove:move];

        ply++;

        [self checkForCancellation];

        int score = -[self ngSearch:newBoard depth:depth-1 alpha:-b beta:-a];

        if (notFirst && (score > a) && (score < beta) && (depth > 1)) {
            score = -[self ngSearch:newBoard depth:depth-1 alpha:-beta beta:-score];
        }

        notFirst = YES;
        ply--;

        if (score != kAlphaBetaIllegal) {
            if (score > bestScore) {
                if (ply < 10) {
                    [self copyVariation:move];
                }
                goodMove = [move copy];
#if !__has_feature(objc_arc)
          [goodMove autorelease];
#endif
                [logger logDebug:@"found good move %@, score=%d, count=%d", goodMove, score, count];
                goodMove.value = score;
                [self assignActiveVariation];
                bestScore = score;
            }
            // see if we can cut off the search
            if (score > a) {
                a = score;
                if (a >= beta) {
                    [transTable storeBoard:theBoard value:score type:(kValueBoundary | (ply & 1)) depth:depth stamp:stamp];
                    [historyTable addMove:move];
                    alphaBetaCuts++;
                    [generator recycleMoveList:moveList];
                    return goodMove;
                }
            }
            b = a + 1;
        }
        move = [moveList next];
    }
    [transTable storeBoard:theBoard value:bestScore type:(kValueAccurate | (ply & 1)) depth:depth stamp:stamp];
    [generator recycleMoveList:moveList];

    return goodMove;
}

//
// A basic alpha-beta algorithm, based on negaMax rather than from the textbooks
//
-(int)ngSearch:(ChessBoard *)theBoard depth:(int)depth alpha:(int)initialAlpha beta:(int)initialBeta {

  assert(initialAlpha < initialBeta);

    if (ply < 10) {
        variations[ply][0] = 0;
    }

    if (0 == depth) {
        return [self quiesce:theBoard alpha:initialAlpha beta:initialBeta];
    }
    nodesVisited++;

    // if there's already something in the transposition table, skip the entire search
    ChessTTEntry *entry = [transTable lookupBoard:theBoard];
    int alpha = initialAlpha;
    int beta = initialBeta;

    if (entry && (entry.depth >= depth)) {
        ttHits++;
        if ((entry.valueType & 1) == (ply & 1)) {
            beta = MAX(entry.value, initialBeta);
        }
        else {
            alpha = MAX(-entry.value, initialAlpha);
        }
        if (beta > initialBeta)
            return beta;
        if (alpha >= initialBeta)
            return alpha;
    }
    int bestScore = kAlphaBetaMinVal;

    // generate new moves
    ChessMoveList *moveList = [generator findPossibleMovesFor:theBoard.activePlayer];
    if (nil == moveList)
        return -kAlphaBetaIllegal;

    if ([moveList isEmpty] || self.shouldCancelSearch) {
        [generator recycleMoveList:moveList];
        return bestScore;
    }

    // and search
    int a = alpha;
    int b = beta;
    BOOL notFirst = NO;

    ChessMove *move = [moveList next];
    while (move) {
        ChessBoard *newBoard = [boardList objectAtIndex:ply];
        [newBoard copyBoard:theBoard];
        [newBoard nextMove:move];

        // search recursively
        ply++;

        if (ply > max_depth) {
          max_depth = ply;
        }

        int score = -[self ngSearch:newBoard depth:depth-1 alpha:-b beta:-a];

        if (notFirst && (score > a) && (score < beta) && (depth > 1)) {
            score = -[self ngSearch:newBoard depth:depth-1 alpha:-beta beta:-score];
        }
        notFirst = YES;
        ply--;

        [self checkForCancellation];

        if (score != kAlphaBetaIllegal) {
            if (score > bestScore) {
                if (ply < 10) {
                    [self copyVariation:move];
                }
                bestScore = score;
            }
            if (score > a) {
                a = score;
                if (a >= beta) {
                    [transTable storeBoard:theBoard value:score type:(kValueBoundary | (ply & 1)) depth:depth stamp:stamp];
                    [historyTable addMove:move];
                    alphaBetaCuts++;
                    [generator recycleMoveList:moveList];
                    return score;
                }
            }
            b = a + 1;
        }
        move = [moveList next];
    }

    [transTable storeBoard:theBoard value:bestScore type:(kValueAccurate | (ply & 1)) depth:depth stamp:stamp];
    [generator recycleMoveList:moveList];

    return bestScore;
}

//
// A variant of alpha-beta considering only captures and null moves to obtain a quiet position,
// e.g. one that is unlikely to change heavily in the very near future.
//
-(int)quiesce:(ChessBoard *)theBoard alpha:(int)initialAlpha beta:(int)initialBeta {

    assert(initialAlpha < initialBeta);

    if (ply < 10) {
        variations[ply][0] = 0;
    }
    nodesVisited++;

    // see if there's already something in the transposition table
    ChessTTEntry *entry = [transTable lookupBoard:theBoard];
    int alpha = initialAlpha;
    int beta = initialBeta;

    ChessMoveList *moveList = nil;

    if (entry) {
        ttHits++;
        if ((entry.valueType & 1) == (ply & 1)) {
            beta = MAX(entry.value, initialBeta);
        }
        else {
            alpha = MAX(-entry.value, initialAlpha);
        }
        if (beta > initialBeta)
            return beta;
        if (alpha >= initialBeta)
            return alpha;
    }

    // Always generate moves if ply < 2 so that we don't miss a move that
    // would bring the king under attack (e.g., make an invalid move).
    if (ply < 2) {
        moveList = [generator findQuiescenceMovesFor:theBoard.activePlayer];
        if (!moveList) {
            return -kAlphaBetaIllegal;
        }
    }

    // Evaluate the current position, assuming that we have a non-capturing move.
    int bestScore = [theBoard.activePlayer evaluate];

    // This method will recurse until it finds checkmate so we need to check early to see if the user agent
    // has accepted an early result. This does not seem to be a problem in Squeak because the Smalltalk
    // process is suspended and will be gc'd during the thinkStep (which is invoked from the Morphic
    // animation step). In our case, we are emulating this in findMove() but NSThread does not have the
    // ability to suspend/resume in the same as as invokers of Smalltalk processes
    if (!self.isSearching || self.shouldCancelSearch) {
        if (moveList) {
            [generator recycleMoveList:moveList];
        }
        return bestScore;
    }

    // TODO: What follows is clearly not the Right Thing to do. The score we just evaluated doesn't
    // take into account that we may be under attack at this point. I've seen it happening various times that
    // the static evaluation triggered a cut-off which was plain wrong in the position at hand.
    //
	// There seem to be three ways to deal with the problem. #1 is just deepen the search.
    // If we go one ply deeper we will most likely find the problem (although that's not entirely certain).
    // #2 is to improve the evaluator function and make it so that the current evaluator is only an estimate saying
    // if it's 'likely' that a non-capturing move will do. The more sophisticated evaluator should then take into account
    // which pieces are under attack. Unfortunately that could make the AI play very passive, e.g., avoiding situations
    // where pieces are under attack even if these attacks are outweighed by other factors.
    // #3 would be to insert a null move here to see *if* we are under attack or not (I've played with this)
    // but for some reason the resulting search seemed to explode rapidly.
    // I'm uncertain if that's due to the transposition table being too small (I don't *really* think so but it may be)
    // or if I've just got something else wrong.
    //
    if (bestScore > alpha) {
        alpha = bestScore;
        if (bestScore >= beta) {
            if (moveList) {
                [generator recycleMoveList:moveList];
            }
            return bestScore;
        }
    }

    // generate new moves
    if (!moveList) {
        moveList = [generator findQuiescenceMovesFor:theBoard.activePlayer];
        if (!moveList)
            return -kAlphaBetaIllegal;
    }

    if ([moveList isEmpty]) {
        [generator recycleMoveList:moveList];
        return bestScore;
    }

    // sort move list according to history heuristics
    [moveList sortUsing:historyTable];

    // and search
    ChessMove *move = [moveList next];
    while (move) {
        ChessBoard *newBoard = [boardList objectAtIndex:ply];
        [newBoard copyBoard:theBoard];
        [newBoard nextMove:move];
        
        [self checkForCancellation];

        // search recursively
        ply++;
        int score = -[self quiesce:newBoard alpha:-beta beta:-alpha];

        if (self.shouldCancelSearch) {
            [generator recycleMoveList:moveList];
            return bestScore;
        }
        ply--;

        if (kAlphaBetaIllegal != score) {
            if (score > bestScore) {
                if (ply < 10) {
                    [self copyVariation:move];
                }
                bestScore = score;
            }

            // see if we can cut off the search
            if (score > alpha) {
                alpha = score;
                if (score >= beta) {
                    [transTable storeBoard:theBoard value:score type:(kValueBoundary | (ply & 1)) depth:0 stamp:stamp];
                    [historyTable addMove:move];
                    alphaBetaCuts++;
                    [generator recycleMoveList:moveList];
                    return bestScore;
                }
            }
        }
        move = [moveList next];
    }

    [transTable storeBoard:theBoard value:bestScore type:(kValueAccurate | (ply & 1)) depth:0 stamp:stamp];
    [generator recycleMoveList:moveList];

    return bestScore;
}

#pragma mark thinking

/*
 * TODO: The dispatch callbacks do not seem to be working either in Objective-C nor Swift implementations
 * All we frankly care about is getting the results written to stdout, so we generate the output instead
 */
- (void)performSearchWithUCIParams:(NSDictionary<NSString *, id> *)uciParams {
    if (![self isReady]) {
        [logger logDebug:@"performSearchWithUCIParams: Search already in progress"];
        return;
    }
    [self performSearchWithUCIParams: uciParams
                      updateCallback:^(NSDictionary<NSString *,id> *info) {
        [self printUCIInfo: info];
    }
                     completionBlock:^(NSDictionary<NSString *,id> *finalInfo, ChessSearchStatus status) {
        [self printCompletionInfo: finalInfo];
    }];
}

- (void)performSearchWithUCIParams:(NSDictionary<NSString *, id> *)uciParams
                    updateCallback:(void (^)(NSDictionary<NSString *, id> *info))updateCallback
                   completionBlock:(void (^)(NSDictionary<NSString *, id> *finalInfo, ChessSearchStatus status))completionBlock
{
    if (![self isReady]) {
        NSLog(@"Unable to start search with UCI parameters %@", uciParams);
        if (completionBlock) completionBlock(nil, ChessSearchStatusInProgress);
        return;
    }
    [logger logDebug:@"Starting search with UCI parameters %@", uciParams];

    // 1. Copy the blocks to heap (equivalent to @escaping)
    UpdateCallback updateCallbackCopy = updateCallback ? Block_copy(updateCallback) : nil;
    CompletionCallback completionBlockCopy = completionBlock ? Block_copy(completionBlock) : nil;

    // 2. Create weak self reference to avoid retain cycles
    __weak typeof(self) weakSelf = self;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        self.isSearching = YES;
        self.shouldCancelSearch = NO;

        // Extract common UCI parameters
        int uci_depth = (int)[uciParams[@"depth"] integerValue];
        int uci_nodes = (int)[uciParams[@"nodes"] integerValue];
        int64_t time_limit_ms = [uciParams[@"movetime"] integerValue];
        if (uci_depth > 0) {
            self.depth_limit = uci_depth;
            self.node_limit = -1;
            self.time_limit = -1;
        }
        if (uci_nodes > 0) {
            self.node_limit = uci_nodes;
            self.time_limit = -1;
            self.depth_limit = -1;
        }
        if (time_limit_ms > 0) {
            self.time_limit = (double)time_limit_ms / MSEC_PER_SEC;
            self.node_limit = -1;
            self.depth_limit = -1;
        }
        self.infinite = [uciParams[@"infinite"] boolValue];

        if (!transTable) {
            [self initializeTranspositionTable];
        }

        [self setActivePlayer:board.activePlayer];

        myMove = [ChessMove nullMove];

        // 3. Strong reference only during execution
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            if (completionBlockCopy) Block_release(completionBlockCopy);
            if (updateCallbackCopy) Block_release(updateCallbackCopy);
            return;
        }

        self.status = ChessSearchStatusInProgress;
        NSInteger score = [board.activePlayer evaluate];
        self.depth = 1;
        ChessMove *bestMove;
        NSMutableDictionary *info = [NSMutableDictionary new];

        ply = 0;
        [historyTable clear];
        [transTable clear];

        self.startTime = [[NSDate date] timeIntervalSince1970];
        self.time_spent = 0;
        nodesVisited = previousNodeCount = ttHits = alphaBetaCuts = 0;
        bestVariation[0] = 0;
        activeVariation[0] = 0;

        if ([board hasUserAgent]) {
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"StartedThinking" object:nil];
        }

        // Search loop
        while (status == ChessSearchStatusInProgress) {

            @try {
                ChessMove *theMove = [self negaScout:board depth:_depth alpha:kAlphaBetaMinVal beta:kAlphaBetaMaxVal];
                if (theMove == nil) {
                    self.status = ChessSearchStatusStopped;
                    info[@"stop_reason"] = @"no more moves";
                }
                // don't cancel until we have a move
               else if (self.shouldCancelSearch) {
                    if (myMove && ![myMove isNullMove]) {
                        self.status = ChessSearchStatusStopped;
                        info[@"stop_reason"] = @"search stopped";
                    }
                }
                else {
                    score = theMove.value;
                    myMove = [theMove copy];
                    [self assignBestVariation];

                    _depth++;
                }
            }
            @catch (NSException *exception) {
                if (![exception.name isEqualToString:CancelExceptionName]) {
                    NSArray *callStack = [NSThread callStackSymbols];
                    [logger logDebug:@"%@: %@\n%@", [exception name], [exception reason], callStack];
                    @throw;
                }
                info[@"stop_reason"] = [exception reason];
                [logger logDebug:@"search terminated: %@", [exception reason]];
            }

            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            self.time_spent = now - startTime;
            long currentNPS = (double)nodesVisited / _time_spent;
            NSArray *pvMoves = [self pvMoves];

            // Prepare UCI info
            info[@"depth"] = @(_depth);
            info[@"score"] = @{ @"cp": @(score) }; // centipawns
            info[@"nodes"] = @(nodesVisited);
            info[@"time"] = @((int)(_time_spent * MSEC_PER_SEC));   // convert seconds to ms
            info[@"nps"] = @(currentNPS);
            info[@"pv"] = pvMoves;
            info[@"hashfull"] = [transTable hashfull];

            // Send periodic update
            [self printUCIInfo: info];
            if (updateCallbackCopy) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    updateCallbackCopy([info copy]);
                });
            }
        }

        [logger logDebug:@"Completed search with UCI parameters %@", uciParams];

        bestMove = myMove ? [myMove copy] : [ChessMove nullMove];
        info[@"bestmove"] = [bestMove uciString];
        // TODO: this should be invoked from completion block
        [self printCompletionInfo: info];

        // Final completion
        strongSelf.isSearching = NO;
        strongSelf.shouldCancelSearch = NO;

        if (completionBlockCopy) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlockCopy([info copy], status);
                if ([board hasUserAgent]) {
                  [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"StoppedThinking" object:nil];
                }
                Block_release(completionBlockCopy);
            });
        }
        if (updateCallbackCopy) Block_release(updateCallbackCopy);
    });
}

-(void)checkForCancellation {
    BOOL stop_nodes = (node_limit > 0) && (nodesVisited > node_limit);
    BOOL stop_depth = (depth_limit > 0) && (_depth > depth_limit);
    BOOL stop_time = ((time_limit > 0) && (self.time_spent > time_limit));
    
    if (!_infinite && (stop_nodes || stop_depth || stop_time)) {
        NSString *reason;
            
        if (stop_time) {
            reason = [NSString stringWithFormat: @"time limit exceeded (time spent = %d)", (int)(_time_spent * 1000)];
        }
        else if (stop_depth) {
            reason = @"depth limit exceeded";
        }
        else if (stop_nodes) {
            reason = @"node limit exceeded";
        }
        else {
            reason = @"stopped search"; // shouldn't happen
        }

        self.status = ChessSearchStatusStopped;
        @throw [NSException exceptionWithName:CancelExceptionName reason:reason userInfo:nil];
    }
}

-(void)findMove: (void (^)(NSString *move))completion {

    if (![self isReady]) {
        [logger logDebug: @"findmove: Search already in progress" ];
        return;
    }
    [self performSearchWithUCIParams: [NSDictionary dictionary]
                      updateCallback:^(NSDictionary<NSString *,id> *info) {
        [self printUCIInfo: info];
    }
                     completionBlock:^(NSDictionary<NSString *,id> *info, ChessSearchStatus status) {
        completion(info[@"bestmove"]);
    }];
}

-(ChessMove *)bestMove {
    [self setActivePlayer:board.activePlayer];

    ChessMove *best = [ChessMove nullMove];
    ChessMoveList *moveList = [generator findPossibleMovesFor:board.activePlayer];
    if (moveList == nil) {
        return nil;
    }
    ChessMove *move = [moveList next];
    // we aren't recursing, so just grab the topmost board
    ChessBoard *newBoard = [boardList objectAtIndex:0];

    while (move != nil) {
        [newBoard copyBoard:board];
        [newBoard nextMove:move];
        // TODO: evaluation should be smarter
        move.value = [newBoard.activePlayer evaluate];

        if ([move value] > [best value]) {
            best = move;
        }
        move = [moveList next];
    }
    
    return best;
}

-(void)cancelSearch {
    self.shouldCancelSearch = YES;
}

-(void)startSearchThread {
    if (self.isSearching) {
      return;
    }

    @synchronized (self) {
        if (!transTable) {
            [self initializeTranspositionTable];
        }

        [self setActivePlayer:board.activePlayer];

        myMove = [ChessMove nullMove];
        [NSThread detachNewThreadSelector:@selector(searchThread) toTarget:self withObject:nil];
    }
}

// TODO: remove this code
-(void)searchThread {
    if (self.isSearching || self.shouldCancelSearch) {
      return;
    }
    self.isSearching = YES;
    self.shouldCancelSearch = NO;

  if ([board hasUserAgent]) {
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"StartedThinking" object:nil];
  }

  @autoreleasepool {

    int score = [board.activePlayer evaluate];
    int depth = 1;
    stamp++;
    ply = 0;
    [historyTable clear];
    [transTable clear];

    startTime = [[NSDate date] timeIntervalSince1970];
    nodesVisited = ttHits = alphaBetaCuts = 0;
    bestVariation[0] = 0;
    activeVariation[0] = 0;

    while (nodesVisited < node_limit) {

      ChessMove *theMove = [self negaScout:board depth:depth alpha:kAlphaBetaMinVal beta:kAlphaBetaMaxVal];

      if (!theMove || self.shouldCancelSearch) {
        // the clock has run out. take the best move we have
        if ([board hasUserAgent]) {
          [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"StoppedThinking" object:nil];
        }
        self.isSearching = NO;
        self.shouldCancelSearch = NO;
        break;
      }
      score = theMove.value;
      myMove = [theMove copy];
      memcpy(bestVariation, activeVariation, VARIATIONS_SIZE * sizeof(int));

      depth++;

      NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
      NSTimeInterval time_spent = now - startTime;

      if ((time_spent > time_limit) || (max_depth > depth_limit)) {
        break;
      }
    }
    self.isSearching = NO;
    self.shouldCancelSearch = NO;
    if ([board hasUserAgent]) {
      [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"StoppedThinking" object:nil];
    }
  }
}

#pragma mark accessing

-(NSString *)statusString {

    NSString *resultString = @"";
    if (myMove && ![myMove isNullMove]) {
        resultString = [resultString stringByAppendingFormat:@"%5.2f ", (myMove.value * 0.01)];
    }

    int *av = bestVariation;
    int count = av[0];

    if (count <= 0) {
        av = activeVariation;
        count = av[0];
    }

    if (count <= 0) {
        resultString = [resultString stringByAppendingString:@"***"];
        av = variations[0];
        count = av[0];
        count = MIN(count,3);
    }

    for (int i=1; i<count+1; i++) {
        int encodedMove = av[i];
        if (encodedMove) {
            NSString *moveString = [[ChessMove decodeFrom:encodedMove] uciString];
            resultString = [resultString stringByAppendingFormat:@"%@ ", moveString];
        }
    }

    resultString = [resultString stringByAppendingFormat:@"[%ld]", nodesVisited];

    return resultString;
}

- (void)printCompletionInfo:(NSDictionary *)info {
    NSString *info_string = [NSString stringWithFormat: @"info string %@", info[@"stop_reason"]];
    printf("%s\n", [info_string UTF8String]);
    printf("bestmove %s\n", [info[@"bestmove"] UTF8String]);
    [logger logDebug: @"> %@", info_string];
    [logger logDebug: @"> bestmove %@", info[@"bestmove"]];
    fflush(stdout);
}

- (void)printUCIInfo:(NSDictionary *)info {
    NSMutableString *output = [NSMutableString stringWithString:@"info"];

    // Depth
    if (info[@"depth"]) {
        [output appendFormat:@" depth %@", info[@"depth"]];
    }

    // Nodes
    if (info[@"nodes"]) {
        [output appendFormat:@" nodes %@", info[@"nodes"]];
    }

    // Time (in ms)
    if (info[@"time"]) {
        [output appendFormat:@" time %@", info[@"time"]];
    }

    // the hash is x permill full
    if (info[@"hashfull"]) {
        [output appendFormat:@" hashfull %@", info[@"hashfull"]];
    }

    // Nodes per second
    if (info[@"nps"]) {
        [output appendFormat:@" nps %@", info[@"nps"]];
    }

    // Score (cp or mate)
    if (info[@"score"]) {
        NSDictionary *scoreDict = info[@"score"];
        if (scoreDict[@"cp"]) {
            [output appendFormat:@" score cp %@", scoreDict[@"cp"]];
            if (scoreDict[@"mate"]) {
                [output appendFormat:@" mate %@", scoreDict[@"mate"]];
            }
        } else if (scoreDict[@"mate"]) {
            [output appendFormat:@" score mate %@", scoreDict[@"mate"]];
        }
    }

    // Principal Variation
    if (info[@"pv"]) {
        NSArray *pv = info[@"pv"];
        if ([pv isKindOfClass:[NSArray class]] && pv.count > 0) {
            [output appendFormat:@" pv %@", [pv componentsJoinedByString:@" "]];
        }
    }

    // Current move being searched
    if (info[@"currmove"]) {
        [output appendFormat:@" currmove %@", info[@"currmove"]];
    }

    [logger logDebug: @"> %@", output];
    printf("%s\n", [output UTF8String]);
    fflush(stdout);
}

-(NSString *)formatVariations:(int[]) array size:(int)count {
    NSString *results = [NSString string];
    
    for (int i = 0; i < count; i++) {
        if (i == 0) {
            results = [results stringByAppendingFormat:@"%d", array[i]];
        }
        else if (array[i] == 0) {
            results = [results stringByAppendingString:@"0"];
        }
        else {
            ChessMove *move = [ChessMove decodeFrom:array[i]];
            results = [results stringByAppendingFormat:@"%@", [move sanString]];
        }
        if (i < count - 1) {
            results = [results stringByAppendingString:@" "];
        }
    }

    return [NSString stringWithFormat:@"[%@]", results];
}

-(NSString *)description {
  NSString *results = [NSString stringWithFormat:@"ChessPlayerAI ply: %d, ttHits: %d, nv: %ld", ply, ttHits, nodesVisited];
  NSString *avString = [self formatVariations: activeVariation size: VARIATIONS_SIZE];
  NSString *bvString = [self formatVariations: bestVariation size: VARIATIONS_SIZE];
  results = [results stringByAppendingFormat:@"\nactiveVariation: %@", avString];
  results = [results stringByAppendingFormat:@"\nbestVariation: %@", bvString];
  results = [results stringByAppendingString:@"\nvariations:"];
  for (int i = 0; i < VARIATIONS_SIZE; i++) {
    NSString *vString = [self formatVariations: variations[i] size: VARIATIONS_SIZE];
    results = [results stringByAppendingFormat:@"\n[%d]: %@", i, vString];
  }
  return results;
}


@end
