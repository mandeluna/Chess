//
//  ChessBoard.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "ChessBoard.h"
#import "ChessMoveGenerator.h"
#import "ChessPlayerAI.h"
#import "ChessPlayer.h"
#import "ChessMove.h"
#import "ChessUserAgent.h"

#pragma mark Initialize

@interface ChessBoard(Private)
-(void)initializeNewBoard;
@end

@implementation ChessBoard
@synthesize whitePlayer, blackPlayer, activePlayer, generator, searchAgent, userAgent;

#pragma mark Class Methods

static int HashKeys[12][64];
static int HashLocks[12][64];

+(void)initializeHashKeys {
    
    srand(23648646);
    for (int i=0; i < 12; i++) {
        for (int j=0; j < 64; j++) {
            HashKeys[i][j] = rand();
            HashLocks[i][j] = rand();
        }
    }
    
}

+(void)initialize {
    
    [self initializeHashKeys];
}

#pragma mark Initialize

-(void)resetGame {
    hashKey = hashLock = 0;
    self.whitePlayer = [[[ChessPlayer alloc] init] autorelease];
    self.blackPlayer = [[[ChessPlayer alloc] init] autorelease];
    whitePlayer.opponent = blackPlayer;
    whitePlayer.board = self;
    blackPlayer.opponent = whitePlayer;
    blackPlayer.board = self;
    activePlayer = whitePlayer;
    [searchAgent reset:self];
    if (userAgent) {
        [userAgent gameReset];
    }
}

-(void)initializeNewBoard {
    [self resetGame];
    [whitePlayer addWhitePieces];
    [blackPlayer addBlackPieces];
}

-(void)dealloc {
    self.whitePlayer = nil;
    self.blackPlayer = nil;
    [super dealloc];
}

#pragma mark Copying

-(ChessBoard *)duplicateBoard:(ChessBoard *)aBoard {
    [whitePlayer copyPlayer:aBoard.whitePlayer];
    [blackPlayer copyPlayer:aBoard.blackPlayer];
    activePlayer = [aBoard.activePlayer isWhitePlayer] ? whitePlayer : blackPlayer;
    hashKey = [aBoard hashKey];
    hashLock = [aBoard hashLock];
    userAgent = nil;
    
    return self;
}

-(void)postCopy {
    
    if (activePlayer == whitePlayer) {
        whitePlayer = [whitePlayer copy];
        blackPlayer = [blackPlayer copy];        
        activePlayer = whitePlayer;
    }
    else {
        whitePlayer = [whitePlayer copy];
        blackPlayer = [blackPlayer copy];        
        activePlayer = blackPlayer;
    }
    
    whitePlayer.opponent = blackPlayer;
    blackPlayer.opponent = whitePlayer;
    whitePlayer.board = self;
    blackPlayer.board = self;
    self.userAgent = nil;
}

-(id)copyWithZone:(NSZone *)zone {

    // shallow copy
    // NSLog(@"copying chess board");
    ChessBoard *copy = NSCopyObject(self, 0, nil);
    
    [copy postCopy];
    
    return copy;
}

#pragma mark Hashing

-(int)hashKey {
    return hashKey;
}

-(int)hashLock {
    return hashLock;
}

-(void)updateHash:(int)piece at:(int)square from:(ChessPlayer *)player {
    int index = (player == whitePlayer) ? piece : piece + 6;
    hashKey = hashKey ^ HashKeys[index][square];
    hashLock = hashLock ^ HashLocks[index][square];
}

#pragma mark Moving

-(void)movePieceFrom:(int)sourceSquare to:(int)destSquare {
    
    if ([searchAgent isThinking]) {
        return;
    }
    
    NSArray *moves = [activePlayer findPossibleMovesAt:sourceSquare];
    
    for (ChessMove *move in moves) {
        if (destSquare == [move destinationSquare]) {
            [self nextMove:move];
            break;
        }
    }
    
    [searchAgent setActivePlayer:activePlayer];
}

-(void)nextMove:(ChessMove *)aMove {
    
    [activePlayer applyMove:aMove];
    
    if (userAgent) {
        [userAgent completedMove:aMove white:[activePlayer isWhitePlayer]];
    }
    
    activePlayer = (whitePlayer == activePlayer) ? blackPlayer : whitePlayer;
    [activePlayer prepareNextMove];
}

-(void)nullMove {
    
    activePlayer = (whitePlayer == activePlayer) ? blackPlayer : whitePlayer;
    [activePlayer prepareNextMove];
}

-(void)undoMove:(ChessMove *)aMove {
    
    activePlayer = (whitePlayer == activePlayer) ? blackPlayer : whitePlayer;
    [activePlayer undoMove:aMove];
    
    if (userAgent) {
        [userAgent undoMove:aMove white:activePlayer.isWhitePlayer];
    }
}

#pragma mark Printing

-(NSString *)description {
    
    return [NSString stringWithFormat:@"%@ (%d %d)", [super description], hashKey, hashLock];
}

@end
