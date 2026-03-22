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
#import "ChessEngine-Swift.h"

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

@synthesize player, board, generator, myMove, transTable, historyTable, shouldCancelSearch, status, uciOptions;

#pragma mark derived properties

-(int)score {
  return myMove.value;
}

-(BOOL)isReady {
    return self.status == ChessSearchStatusCompleted;
}

-(BOOL)isSearching {
    return self.status == ChessSearchStatusInProgress;
}

#pragma mark initialize

+ (void)initialize{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = @{
        time_limit_key : @1000.0,
        depth_limit_key : @-1,
        node_limit_key : @50000
    };

    [defaults registerDefaults:appDefaults];
}

Logger *logger;

-(id)init {

    if (self = [super init]) {
        historyTable = [[ChessHistoryTable alloc] init];
        nodesVisited = ttHits = alphaBetaCuts = stamp = 0;
        time_limit = [[NSUserDefaults standardUserDefaults] doubleForKey:time_limit_key];
        depth_limit = (int)[[NSUserDefaults standardUserDefaults] integerForKey:depth_limit_key];
        node_limit = (long)[[NSUserDefaults standardUserDefaults] integerForKey:node_limit_key];
        status = ChessSearchStatusCompleted;
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
    [self setHashSizeMB:128];  // default: bits=20, ~1M entries
}

-(void)setHashSizeMB:(int)mb {
    // Each ObjC TT entry costs ~128 bytes; bits = floor(log2(mb) + 13) maps:
    //   1 MB → bits 13 (~8k entries)
    //   4 MB → bits 15 (~32k entries)
    //  32 MB → bits 18 (~256k entries)  ← previous default
    // 128 MB → bits 20 (~1M entries)
    // 512 MB → bits 22 (~4M entries)
    int bits = 0;
    int val = MAX(1, mb);
    while (val > 1) { bits++; val >>= 1; }
    bits = MIN(MAX(bits + 13, 10), 24);
    transTable = [[ChessTranspositionTable alloc] initWithBits:bits];
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

-(void)validateVariation:(int *)variation {
    int *pv = variation;
    int count = pv[0];
    if (count < 1) {
        return;
    }
    ChessBoard *board = [self.board copy];
    
    count = pv[0];
    for (int i = 1; i < count + 1; i++) {
        ChessMove *move = [ChessMove decodeFrom:pv[i]];
        ChessMove *validatedMove = [board moveWithUci:[move uciString]];
        if (validatedMove == nil) {
            [logger logError:@"%@ is not a valid move", move];
            break;
        }
        [board nextMove:validatedMove];
    }
#if !__has_feature(objc_arc)
    [board release];
#endif
}

#pragma mark searching

// used for generating principal variation report info -- this is I/O bound so presumably
// we can take a little extra time to validate the moves. If one of them results in an illegal
// move (e.g. due to a king attack), don't report any further results.
// TODO: the real problem is that the engine is giving good scores to illegal moves
-(NSArray *)pvMoves:(ChessBoard *)board {
    NSMutableArray *result = [NSMutableArray array];

    int *av = bestVariation;
    int count = av[0];
    if (count < 1) {
        av = activeVariation;
        count = av[0];
    }
    // If neither bestVariation nor activeVariation has moves yet (e.g. before
    // depth 1 completes), return an empty array.  The previous fallback to
    // variations[0] could emit stale moves from a prior search position, which
    // CuteChess/GUIs flag as illegal.  The "***" sentinel was also emitted
    // verbatim in the UCI pv field, which is always illegal.
    if (count < 1) {
        return result;
    }
    ChessBoard *newBoard = [board copy];
    count = av[0];
    for (int i = 1; i < count; i++) {
        ChessMove *move = [ChessMove decodeFrom:av[i]];
        if (![newBoard.activePlayer isValidMove:move]) {
            [logger logWarning:@"PV[%d] illegal move %@, pv=%@, board=%@",
                i, [move sanStringForBoard:board], [self formatVariations:av size:count], [board generateFEN]];
            break;
        }
        [newBoard nextMove:move];
        [result addObject:[move uciString]];
    }
#if !__has_feature(objc_arc)
    [newBoard release];
#endif
    return result;
}

-(void)copyVariation:(ChessMove *)move {
    int count = 0;
    int *av = variations[ply];

    if (ply < 9) {
      int *mv = variations[ply + 1];
      count = mv[0];
      for (int i = 1; i < count + 1; i++) {
          av[i + 1] = mv[i];
      }
    }
    av[0] = count + 1;
    av[1] = [move encodedMove];
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

    if (self.shouldCancelSearch) {
        [generator recycleMoveList:moveList];
        return nil;
    }

    // sort move list; promote TT best move to front if available
    [moveList sortUsing:historyTable];
    ChessTTEntry *rootEntry = [transTable lookupBoard:theBoard];
    if (rootEntry && rootEntry.bestMoveIndex) {
        [moveList promoteMoveIndex:rootEntry.bestMoveIndex];
    }

    // and search
    int a = alpha;
    int b = beta;
    BOOL notFirst = NO;

    ChessMove *move = [moveList next];

    while (nil != move) {
        if (ply >= [boardList count]) {
            NSString *reason = [NSString stringWithFormat:@"ply=%d", ply];
            [generator recycleMoveList:moveList];
            [logger raiseExceptionName:@"invalid index into boardList" reason:reason];
        }
        ChessBoard *newBoard = [boardList objectAtIndex:ply];
        [newBoard copyBoard:theBoard];
        [newBoard nextMove:move];

        ply++;

        int score = -[self ngSearch:newBoard depth:depth-1 alpha:-b beta:-a];

        if (notFirst && (score > a) && (score < beta) && (depth > 1)) {
            score = -[self ngSearch:newBoard depth:depth-1 alpha:-beta beta:-score];
        }

        notFirst = YES;
        ply--;

        if (self.shouldCancelSearch) {
            [generator recycleMoveList:moveList];
            return nil;
        }

        if (score != kAlphaBetaIllegal) {
            if (score > bestScore) {
                if (ply < 10) {
                    [self copyVariation:move];
                }
                goodMove = [move copy];
#if !__has_feature(objc_arc)
          [goodMove autorelease];
#endif
                goodMove.value = score;
                [self assignActiveVariation];
                bestScore = score;
            }
            // see if we can cut off the search
            if (score > a) {
                a = score;
                if (a >= beta) {
                    [transTable storeBoard:theBoard value:score type:(kValueBoundary | (ply & 1)) depth:depth stamp:stamp bestMove:([move sourceSquare] << 6) | [move destinationSquare]];
                    [historyTable addMove:move ply:depth];
                    alphaBetaCuts++;
                    [generator recycleMoveList:moveList];
                    return goodMove;
                }
            }
            b = a + 1;
        }
        move = [moveList next];
        [self checkForCancellation];
    }
    int bestMoveIdx = goodMove ? (([goodMove sourceSquare] << 6) | [goodMove destinationSquare]) : 0;
    [transTable storeBoard:theBoard value:bestScore type:(kValueAccurate | (ply & 1)) depth:depth stamp:stamp bestMove:bestMoveIdx];
    [generator recycleMoveList:moveList];

    return goodMove;
}

//
// A basic alpha-beta algorithm, based on negaMax rather than from the textbooks
//
-(int)ngSearch:(ChessBoard *)theBoard depth:(int)depth alpha:(int)initialAlpha beta:(int)initialBeta {

    assert(initialAlpha < initialBeta);

    if (self.shouldCancelSearch) {
        return kAlphaBetaMinVal;
    }

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

    // sort move list; promote TT best move to front if available
    [moveList sortUsing:historyTable];
    if (entry && entry.bestMoveIndex) {
        [moveList promoteMoveIndex:entry.bestMoveIndex];
    }

    // and search
    int bestMoveIdx = 0;
    int a = alpha;
    int b = beta;
    BOOL notFirst = NO;

    ChessMove *move = [moveList next];
    while (nil != move) {
        ChessBoard *newBoard = [boardList objectAtIndex:ply];
        [newBoard copyBoard:theBoard];
        [newBoard nextMove:move];

        // search recursively
        ply++;

        int score = -[self ngSearch:newBoard depth:depth-1 alpha:-b beta:-a];

        if (notFirst && (score > a) && (score < beta) && (depth > 1)) {
            score = -[self ngSearch:newBoard depth:depth-1 alpha:-beta beta:-score];
        }
        notFirst = YES;
        ply--;

        if (self.shouldCancelSearch) {
            [generator recycleMoveList:moveList];
            return bestScore;
        }

        if (score != kAlphaBetaIllegal) {
            if (score > bestScore) {
                if (ply < 10) {
                    [self copyVariation:move];
                }
                bestScore = score;
                bestMoveIdx = ([move sourceSquare] << 6) | [move destinationSquare];
            }
            if (score > a) {
                a = score;
                if (a >= beta) {
                    [transTable storeBoard:theBoard value:score type:(kValueBoundary | (ply & 1)) depth:depth stamp:stamp bestMove:bestMoveIdx];
                    [historyTable addMove:move ply:depth];
                    alphaBetaCuts++;
                    [generator recycleMoveList:moveList];
                    return score;
                }
            }
            b = a + 1;
        }
        [self checkForCancellation];
        move = [moveList next];
    }

    [transTable storeBoard:theBoard value:bestScore type:(kValueAccurate | (ply & 1)) depth:depth stamp:stamp bestMove:bestMoveIdx];
    [generator recycleMoveList:moveList];

    return bestScore;
}

//
// A variant of alpha-beta considering only captures and null moves to obtain a quiet position,
// e.g. one that is unlikely to change heavily in the very near future.
//
-(int)quiesce:(ChessBoard *)theBoard alpha:(int)initialAlpha beta:(int)initialBeta {

    assert(initialAlpha < initialBeta);

    if (self.shouldCancelSearch) {
        return initialAlpha;
    }

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
    while (nil != move) {
        ChessBoard *newBoard = [boardList objectAtIndex:ply];
        [newBoard copyBoard:theBoard];
        [newBoard nextMove:move];

        // search recursively
        ply++;

        int score = -[self quiesce:newBoard alpha:-beta beta:-alpha];

        ply--;

        if (self.shouldCancelSearch) {
            [generator recycleMoveList:moveList];
            return bestScore;
        }

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
                    int mi = ([move sourceSquare] << 6) | [move destinationSquare];
                    [transTable storeBoard:theBoard value:score type:(kValueBoundary | (ply & 1)) depth:0 stamp:stamp bestMove:mi];
                    [historyTable addMove:move ply:1];
                    alphaBetaCuts++;
                    [generator recycleMoveList:moveList];
                    return bestScore;
                }
            }
        }
        move = [moveList next];
        [self checkForCancellation];
    }

    [transTable storeBoard:theBoard value:bestScore type:(kValueAccurate | (ply & 1)) depth:0 stamp:stamp bestMove:0];
    [generator recycleMoveList:moveList];

    return bestScore;
}

#pragma mark thinking

- (void)performSearchWithUCIParams:(NSDictionary<NSString *, id> *)uciParams {
    [self performSearchWithUCIParams: uciParams
                      updateCallback:^(NSDictionary *info) {
        [self printUCIInfo: info];
    }
                     completionCallback:^(NSDictionary *finalInfo, ChessSearchStatus status) {
        [self printCompletionInfo: finalInfo];
    }];
}

- (void)performSearchWithUCIParams:(NSDictionary<NSString *, id> *)uciParams
                    updateCallback:(UpdateCallback)updateCallback
                completionCallback:(CompletionCallback)completionCallback
{
    if (self.status != ChessSearchStatusCompleted) {
        [logger logError:@"Unable to start search with UCI parameters %@", uciParams];
        if (completionCallback) completionCallback(nil, ChessSearchStatusInProgress);
        return;
    }
    [logger logDebug:@"Starting search with UCI parameters %@", uciParams];

    self.status = ChessSearchStatusInProgress;
    self.shouldCancelSearch = NO;

    // Extract common UCI parameters
    int uci_depth = (int)[uciParams[@"depth"] integerValue];
    int uci_nodes = (int)[uciParams[@"nodes"] integerValue];
    int64_t time_limit_ms = [uciParams[@"movetime"] integerValue];
    if (uci_depth > 0) {
        depth_limit = uci_depth;
        node_limit = -1;
        time_limit = -1;
    }
    if (uci_nodes > 0) {
        node_limit = uci_nodes;
        time_limit = -1;
        depth_limit = -1;
    }
    if (time_limit_ms > 0) {
        time_limit = (double)time_limit_ms / MSEC_PER_SEC;
        node_limit = -1;
        depth_limit = -1;
    }
    infinite = [uciParams[@"infinite"] boolValue];

    if (!transTable) {
        [self initializeTranspositionTable];
    }

    [self setActivePlayer:board.activePlayer];

    myMove = [ChessMove nullMove];

    NSInteger score = [board.activePlayer evaluate];
    int depth = 1;
    ChessMove *bestMove;

    ply = 0;
    [historyTable clear];
    [transTable clear];

    startTime = [[NSDate date] timeIntervalSince1970];
    nodesVisited = previousNodeCount = ttHits = alphaBetaCuts = 0;
    bestVariation[0] = 0;
    activeVariation[0] = 0;

    dispatch_queue_t dispatch_queue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0);

    if ([board hasUserAgent]) {
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"StartedThinking" object:nil];
    }

    // Search loop
    while (status == ChessSearchStatusInProgress) {
        ChessMove *theMove = [self negaScout:board depth:depth alpha:kAlphaBetaMinVal beta:kAlphaBetaMaxVal];

        NSMutableDictionary *updateInfo = [[self reportInfo:board] mutableCopy];
        updateInfo[@"depth"] = @(depth);

        // Check cancellation BEFORE checking theMove == nil: a cancelled search
        // may return nil from negaScout even though the position has legal moves.
        if (self.shouldCancelSearch) {
            self.status = ChessSearchStatusStopped;
            updateInfo[@"stop_reason"] = @"search cancelled";
            // myMove may still be nil if cancelled before depth 1 completes;
            // the completion handler will treat a nil/null move gracefully.
        }
        else if (theMove == nil) {
            // No legal moves (checkmate / stalemate).
            self.status = ChessSearchStatusStopped;
            updateInfo[@"stop_reason"] = @"no more moves";
        }
        else {
            // Completed a full depth iteration — commit the result.
            score = theMove.value;
            self.myMove = theMove;
            [self assignBestVariation];
            updateInfo[@"score"] = @{ @"cp": @(score) };
            dispatch_async(dispatch_queue, ^{
                updateCallback([updateInfo copy]);
            });
            depth++;
            // Enforce depth limit here (after a complete iteration), not inside the search.
            if (depth_limit > 0 && depth > depth_limit) {
                self.status = ChessSearchStatusStopped;
            }
            // Stop iterative deepening once a forced mate/loss is confirmed —
            // deeper iterations can only replay the same trivial TT path.
            if (score >= kAlphaBetaMaxVal || score <= kAlphaBetaMinVal) {
                self.status = ChessSearchStatusStopped;
            }
        }
    }

    [logger logDebug:@"Completed search with UCI parameters %@", uciParams];

    NSMutableDictionary *completionInfo = [[self reportInfo:board] mutableCopy];
    completionInfo[@"depth"] = @(depth);

    if (myMove != nil) {
        bestMove = [myMove copy];
#if !__has_feature(objc_arc)
    [bestMove autorelease];
#endif
    }
    else {
        // TODO: what is the point of nullMove -- do we even use this for anything?
        bestMove = [ChessMove nullMove];
    }
    completionInfo[@"bestmove"] = [bestMove uciString];

    if (completionCallback) {
        dispatch_async(dispatch_queue, ^{
            // send one final batch of update info
            if (updateCallback) { updateCallback([completionInfo copy]); }
            completionCallback([completionInfo copy], self->status);
        });
    }

    // Final completion
    self.shouldCancelSearch = NO;
    self.status = ChessSearchStatusCompleted;
}

-(NSDictionary *)reportInfo:(ChessBoard *)board {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval time_spent = now - startTime;

    long currentNPS = (double)nodesVisited / time_spent;
    NSArray *pvMoves = [self pvMoves:board];
    
    return @{
        @"nodes" : @(nodesVisited),
        @"time" : @((int)(time_spent * MSEC_PER_SEC)),
        @"nps" : @(currentNPS),
        @"pv" : pvMoves,
        @"hashfull" : [transTable hashfull],
        @"lastReport" : @(now)
    };
}

-(void)checkForCancellation {
    if (status != ChessSearchStatusInProgress) {
        return;
    }

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval time_spent = now - startTime;
    BOOL stop_nodes = (node_limit > 0) && (nodesVisited > node_limit);
    BOOL stop_time = (time_limit > 0) && (time_spent > time_limit);

    if (!infinite && (stop_nodes || stop_time)) {
        // Set the cancellation flag; the outer iterative-deepening loop decides
        // whether to commit the result of the current depth.  Depth limits are
        // enforced by the outer loop, not here.
        self.shouldCancelSearch = YES;
    }
}

-(void)findMove:(void (^)(NSString *move))completion {
    [self findMove:completion update:nil];
}

-(void)findMove:(void (^)(NSString *move))completion
         update:(nullable void (^)(NSDictionary *info))update {
    if (![self isReady]) {
        [logger logDebug: @"findmove: Search already in progress" ];
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @autoreleasepool {
            [self performSearchWithUCIParams: [NSDictionary dictionary]
                              updateCallback:^(NSDictionary *info) {
                [self printUCIInfo: info];
                if (update) update(info);
            }
                          completionCallback:^(NSDictionary *info, ChessSearchStatus status) {
                completion(info[@"bestmove"]);
            }];
        }
    });
}

-(void)cancelSearch {
    self.shouldCancelSearch = YES;
}

-(void)startSearchThread {
    if ([board hasUserAgent]) {
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"StartedThinking" object:nil];
    }
    
    NSDictionary *searchParameters = @{
        // to be populated by UI settings, otherwise we just take the defaults
    };

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @autoreleasepool {
            [self performSearchWithUCIParams: searchParameters
                              updateCallback:^(NSDictionary<NSString *,id> *info) { NSLog(@"%@", self.statusString); }
                          completionCallback:^(NSDictionary<NSString *,id> *finalInfo, ChessSearchStatus status) {

                NSMutableDictionary *info = [finalInfo mutableCopy];
                info[@"bestmove"] = @([self->myMove encodedMove]);
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"StoppedThinking" object:info];
            }];
        }
    });
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

    if (nodesVisited > 0) {
        resultString = [resultString stringByAppendingFormat:@" [nodes %ld]", nodesVisited];
    }

    if (board.halfmoveClock > 50) {
        resultString = [resultString stringByAppendingFormat:@" [halfmoves %d]", board.halfmoveClock];
    }

    return resultString;
}

- (void)printCompletionInfo:(NSDictionary *)info {
    NSString *info_string = [NSString stringWithFormat: @"info string %@", info[@"stop_reason"]];
    printf("%s\n", [info_string UTF8String]);
    printf("bestmove %s\n", [info[@"bestmove"] UTF8String]);
    fflush(stdout);
    [logger logDebug: @"> %@", info_string];
    [logger logDebug: @"> bestmove %@", info[@"bestmove"]];

    if ([board hasUserAgent]) {
      [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"StoppedThinking" object:info[@"bestmove"]];
    }
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
            results = [results stringByAppendingFormat:@"%@", [move uciString]];
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
