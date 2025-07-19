//
//  ChessPlayerAI.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

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

@interface ChessPlayerAI(Private)

-(void)initializeTranspositionTable;

@end

@implementation ChessPlayerAI

@synthesize player, board, generator, myMove, useNegaScout;

#pragma mark initialize

+ (void)initialize{

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary
                                 dictionaryWithObject:[NSNumber numberWithBool:YES]
                                 forKey:@"UseNegaScout"];

    [defaults registerDefaults:appDefaults];
}

-(id)init {

    if (self = [super init]) {
        historyTable = [[ChessHistoryTable alloc] init];
        nodesVisited = ttHits = alphaBetaCuts = stamp = 0;
        useNegaScout = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseNegaScout"];
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
        NSMutableArray *boards = [NSMutableArray arrayWithCapacity:NUM_MOVES];
        for (int i=0; i<NUM_MOVES; i++) {
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
//
-(void)initializeTranspositionTable {

    transTable = [[ChessTranspositionTable alloc] initWithBits:16]; // 1 << 16 entries
    //    transTable = [[ChessTranspositionTable alloc] initWithBits:18]; // 1 << 18 entries
    // [256k entries improve utilization on ipad] but startup on iPhone 3G is painfully slow
}

#pragma mark searching

-(void)copyVariation:(ChessMove *)move {

    int count = 0;
    int *av = variations[ply];

    if (ply < 9) {
      int *mv = variations[ply+1];
      count = mv[0];
      // av replaceFrom:3 to:count+2 with:mv startingAt:2
      // translate from Smalltalk 1-origin index to 0-origin
//      [self replace:av from:2 to:count+2 with:mv startingAt:1];
      for (int i=2; i<count+2; i++) {
          av[i] = mv[i];
      }
    }
    av[0] = count+1;
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
// An implementation of the MTD(f) algorithm. See:
// http://www.cs.vu.nl/~aske/mtdf.html
//
-(ChessMove *)mtdfSearch:(ChessBoard *)theBoard score:(int)estimate depth:(int)depth {

    int value = estimate;
    int low = kAlphaBetaMinVal;
    int high = kAlphaBetaMaxVal;
    ChessMove *goodMove = nil;

    while (low < high) {
        int beta = (value == low) ? value + 1 : value;
        ChessMove *move = [self searchMove:theBoard depth:depth alpha:beta-1 beta:beta];
        if (stopThinking)
            return move;

        if (nil == move)
            return move;

        value = [move value];

        if (value < beta) {
            high = value;
        }
        //
        // NOTE: It is important that we do *NOT* return a move from a search which didn't reach the beta goal
        // (e.g., value < beta). This is because all it means is that we didn't reach beta and the move returned
        // is not the move 'closest' to beta but just one that triggered cut-off. In other words, if we'd take a
        // move which value is less than beta it could mean that this move is a *LOT* worse than beta.
        //
        else {
            low = value;
            goodMove = move;
          // activeVariation replaceFrom:1 to:activeVariation size with:variations first startingAt:1
          // translate from Smalltalk 1-origin index to 0-origin
//          [self replace:activeVariation from:0 to:VARIATIONS_SIZE with:variations[0] startingAt:0];
          for (int i=0; i<VARIATIONS_SIZE; i++) {
              activeVariation[i] = variations[0][i];
          }
        }
    }
    return goodMove;
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

//    NSLog(@"*** negaScout processing moveList size = %d, depth = %d", [moveList count], depth);
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

        // retain the move so it doesn't get deallocated while we recurse
#if !__has_feature(objc_arc)
        [move retain];
#endif
        ChessBoard *newBoard = [boardList objectAtIndex:ply];
        [newBoard duplicateBoard:theBoard];
        [newBoard nextMove:move];

        // search recursively
        ply++;

        int score = -[self ngSearch:newBoard depth:depth-1 alpha:-b beta:-a];

        if (notFirst && (score > a) && (score < beta) && (depth > 1)) {
            score = -[self ngSearch:newBoard depth:depth-1 alpha:-beta beta:-score];
        }

        notFirst = YES;
        ply--;

        if (stopThinking) {
            [generator recycleMoveList:moveList];
#if !__has_feature(objc_arc)
          [move release];
#endif
            return move;
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

                // activeVariation replaceFrom:1 to:activeVariation size with:variations first startingAt:1
//                [self replace:activeVariation from:0 to:VARIATIONS_SIZE with:variations[0] startingAt:0];
              for (int i=0; i<VARIATIONS_SIZE; i++) {
                  activeVariation[i] = variations[0][i];
              }
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
#if !__has_feature(objc_arc)
          [move release];
#endif
                    return goodMove;
                }
            }
            b = a + 1;
        }

        // undo the previous retain
#if !__has_feature(objc_arc)
          [move release];
#endif

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

    if ([moveList isEmpty]) {
        [generator recycleMoveList:moveList];
        return bestScore;
    }

    // and search
    int a = alpha;
    int b = beta;
    BOOL notFirst = NO;

    ChessMove *move = [moveList next];
    while (move) {

#if !__has_feature(objc_arc)
          [move retain];
#endif

        ChessBoard *newBoard = [boardList objectAtIndex:ply];
        [newBoard duplicateBoard:theBoard];
        [newBoard nextMove:move];

        // search recursively
        ply++;
        int score = -[self ngSearch:newBoard depth:depth-1 alpha:-b beta:-a];

        if (notFirst && (score > a) && (score < beta) && (depth > 1)) {
            score = -[self ngSearch:newBoard depth:depth-1 alpha:-beta beta:-score];
        }
        notFirst = YES;
        ply--;

        if (stopThinking) {
            [generator recycleMoveList:moveList];
#if !__has_feature(objc_arc)
          [move release];
#endif
            return score;
        }

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
#if !__has_feature(objc_arc)
          [move release];
#endif
                    return score;
                }
            }
            b = a + 1;
        }

#if !__has_feature(objc_arc)
          [move release];
#endif

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
    int counter = 0;
    while (move) {

        counter++;

#if !__has_feature(objc_arc)
          [move retain];
#endif

        ChessBoard *newBoard = [boardList objectAtIndex:ply];
        [newBoard duplicateBoard:theBoard];
        [newBoard nextMove:move];

        // search recursively
        ply++;
        int score = -[self quiesce:newBoard alpha:-beta beta:-alpha];

        if (stopThinking) {
            [generator recycleMoveList:moveList];
#if !__has_feature(objc_arc)
          [move release];
#endif
            return score;
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
#if !__has_feature(objc_arc)
          [move release];
#endif
                    return bestScore;
                }
            }
        }

#if !__has_feature(objc_arc)
          [move release];
#endif
        move = [moveList next];
    }

    [transTable storeBoard:theBoard value:bestScore type:(kValueAccurate | (ply & 1)) depth:0 stamp:stamp];
    [generator recycleMoveList:moveList];

//    NSLog(@"quiesce:alpha:beta: bestScore = %d", bestScore);

    return bestScore;
}

//
// A basic alpha-beta algorithm, based on negaMax rather than from the textbooks
//
-(int)search:(ChessBoard *)theBoard depth:(int)depth alpha:(int)initialAlpha beta:(int)initialBeta {
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

    if ([moveList isEmpty]) {
        [generator recycleMoveList:moveList];
        return bestScore;
    }

    // Sort move list according to history heuristics
    [moveList sortUsing:historyTable];

    // and search
    ChessMove *move = [moveList next];
    while (move) {

        ChessBoard *newBoard = [[boardList objectAtIndex:ply] duplicateBoard:theBoard];
        [newBoard nextMove:move];

        // search recursively
        ply++;
        int score = -[self search:newBoard depth:depth-1 alpha:-beta beta:-alpha];
        ply--;

        if (stopThinking) {
            [generator recycleMoveList:moveList];
            return score;
        }

        if (score != kAlphaBetaIllegal) {
            if (score > bestScore) {
                if (ply < 10) {
                    [self copyVariation:move];
                }
                bestScore = score;
            }
            if (score > alpha) {
                alpha = score;
                if (score >= beta) {
                    [transTable storeBoard:theBoard value:score type:(kValueBoundary | (ply & 1)) depth:depth stamp:stamp];
                    [historyTable addMove:move];
                    alphaBetaCuts++;
                    [generator recycleMoveList:moveList];
                    return score;
                }
            }
        }
        move = [moveList next];
    }

    [transTable storeBoard:theBoard value:bestScore type:(kValueAccurate | (ply & 1)) depth:depth stamp:stamp];
    [generator recycleMoveList:moveList];

    return bestScore;
}

//
// Modified version to return the move rather than the score
//
-(ChessMove *)searchMove:(ChessBoard *)theBoard depth:(int)depth alpha:(int)initialAlpha beta:(int)initialBeta {
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

    if ([moveList isEmpty]) {
        [generator recycleMoveList:moveList];
        return nil;
    }

    // Sort move list according to history heuristics
    [moveList sortUsing:historyTable];

    // and search
    ChessMove *move = [moveList next];
    while (move) {

        ChessBoard *newBoard = [[boardList objectAtIndex:ply] duplicateBoard:theBoard];
        [newBoard nextMove:move];

        // search recursively
        ply++;
        int score = -[self search:newBoard depth:depth-1 alpha:-beta beta:-alpha];
        ply--;

        if (stopThinking) {
            [generator recycleMoveList:moveList];
            return move;
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
                bestScore = score;
            }
            if (score > alpha) {
                alpha = score;
                if (score >= beta) {
                    [transTable storeBoard:theBoard value:score type:(kValueBoundary | (ply & 1)) depth:depth stamp:stamp];
                    [historyTable addMove:move];
                    alphaBetaCuts++;
                    [generator recycleMoveList:moveList];
                    return goodMove;
                }
            }
        }
        move = [moveList next];
    }

    [transTable storeBoard:theBoard value:bestScore type:(kValueAccurate | (ply & 1)) depth:depth stamp:stamp];
    [generator recycleMoveList:moveList];

    return goodMove;
}

#pragma mark thinking

-(BOOL)isThinking {

    return isThinking;
}

-(void)stopThinking {
  stopThinking = YES;
}

-(void)startThinking {

    if ([self isThinking]) {
        return;
    }

  NSLog(@"Started thinking: NegaScout %s ", useNegaScout ? "enabled" : "disabled");

  if (!transTable) {
        // [NSThread detachNewThreadSelector:@selector(initializeTranspositionTable) toTarget:self withObject:nil];
        [self initializeTranspositionTable];
        // TODO: wait for above to complete then return and start thinking
    }

    [self setActivePlayer:board.activePlayer];

    myMove = [ChessMove nullMove];
    [NSThread detachNewThreadSelector:@selector(thinkThread) toTarget:self withObject:nil];
}

-(void)findMove: (void (^)(ChessMove *move))completion {
  dispatch_async(dispatch_get_main_queue(), ^(){
    NSLog(@"Finding move");

    if (!transTable) {
        [self initializeTranspositionTable];
    }
    [self setActivePlayer:board.activePlayer];

    myMove = [ChessMove nullMove];
    
    [self findMove];
    completion(myMove);
  });
}

-(void)findMove {
  isThinking = YES;
  [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"StartedThinking" object:nil];

  stopThinking = NO;
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

  while (nodesVisited < 50000) {

    ChessMove *theMove = nil;

    if (useNegaScout) {
      theMove = [self negaScout:board depth:depth alpha:kAlphaBetaMinVal beta:kAlphaBetaMaxVal];
    }
    else {
      theMove = [self mtdfSearch:board score:score depth:depth];
    }

    if (!theMove || stopThinking) {
      // the clock has run out. take the best move we have
      isThinking = NO;
      [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"StoppedThinking" object:nil];
      return;
    }

    myMove = theMove;
    // bestVariation replaceFrom:1 to:bestVariation size with:activeVariation startingAt:1
    //[self replace:bestVariation from:0 to:VARIATIONS_SIZE with:activeVariation startingAt:0];
    for (int i=0; i<VARIATIONS_SIZE; i++) {
      bestVariation[i] = activeVariation[i];
    }

    score = theMove.value;
    depth++;
  }
  isThinking = NO;
  [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"StoppedThinking" object:nil];
}

-(void)thinkThread {
  @autoreleasepool {
    [self findMove];
  }
}

//
// return the number of seconds to process each move
//
-(long)timeToThink {
    return 5.0;
}

#pragma mark accessing

-(NSString *)statusString {

    NSString *resultString = @"";
//    if (myMove && ![myMove isNullMove]) {
//        resultString = [resultString stringByAppendingFormat:@"%5.2f ", (myMove.value * 0.01)];
//    }

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
            NSString *moveString = [[ChessMove decodeFrom:encodedMove] moveString];
            resultString = [resultString stringByAppendingFormat:@"%@ ", moveString];
        }
    }

    resultString = [resultString stringByAppendingFormat:@"[%d]", nodesVisited];

    return resultString;
}


@end
