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

#pragma mark Initialize

@interface ChessBoard(Private)
-(void)initializeNewBoard;
@end

@implementation ChessBoard

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
    _hashKey = _hashLock = 0;
    self.whitePlayer = [[[ChessPlayer alloc] init] autorelease];
    self.blackPlayer = [[[ChessPlayer alloc] init] autorelease];
    _whitePlayer.opponent = _blackPlayer;
    _whitePlayer.board = self;
    _blackPlayer.opponent = _whitePlayer;
    _blackPlayer.board = self;
    _activePlayer = _whitePlayer;
    [_searchAgent reset:self];
}

-(void)initializeNewBoard {
    [self resetGame];
    [_whitePlayer addWhitePieces];
    [_blackPlayer addBlackPieces];
}

-(id)init {
    if (self = [super init]) {
        _generator = [[ChessMoveGenerator alloc] init];
        _searchAgent = [[ChessPlayerAI alloc] init];
    }
    return self;
}

-(void)dealloc {
    [_whitePlayer release];
    [_blackPlayer release];
    [_generator release];
    [_searchAgent release];
    [super dealloc];
}

#pragma mark Copying

-(ChessBoard *)duplicateBoard:(ChessBoard *)aBoard {
    [_whitePlayer copyPlayer:aBoard.whitePlayer];
    [_blackPlayer copyPlayer:aBoard.blackPlayer];
    _activePlayer = [aBoard.activePlayer isWhitePlayer] ? _whitePlayer : _blackPlayer;
    _hashKey = [aBoard hashKey];
    _hashLock = [aBoard hashLock];
    _hasUserAgent = NO;
    _searchAgent = [aBoard.searchAgent retain];
    _generator = [aBoard.generator retain];
    
    return self;
}

-(void)postCopy {
    
    if (_activePlayer == _whitePlayer) {
        _whitePlayer = [_whitePlayer copy];
        _blackPlayer = [_blackPlayer copy];
        _activePlayer = _whitePlayer;
    }
    else {
        _whitePlayer = [_whitePlayer copy];
        _blackPlayer = [_blackPlayer copy];
        _activePlayer = _blackPlayer;
    }
    
    [_searchAgent retain];
    [_generator retain];
    _whitePlayer.opponent = _blackPlayer;
    _blackPlayer.opponent = _whitePlayer;
    _whitePlayer.board = self;
    _blackPlayer.board = self;
    self.hasUserAgent = NO;
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
    return _hashKey;
}

-(int)hashLock {
    return _hashLock;
}

-(void)updateHash:(int)piece at:(int)square from:(ChessPlayer *)player {
    int index = (player == _whitePlayer) ? piece : piece + 6;
    _hashKey = _hashKey ^ HashKeys[index][square];
    _hashLock = _hashLock ^ HashLocks[index][square];
}

#pragma mark Moving

-(ChessMove *)movePieceFrom:(int)sourceSquare to:(int)destSquare {
    
    if ([_searchAgent isThinking]) {
        return nil;
    }
    
    ChessMove *theMove = nil;
    
    NSArray *moves = [_activePlayer findPossibleMovesAt:sourceSquare];
    
    for (ChessMove *move in moves) {
        if (destSquare == [move destinationSquare]) {
            [self nextMove:move];
            theMove = move;
            break;
        }
    }
    
    [_searchAgent setActivePlayer:_activePlayer];
    
    return theMove;
}

-(void)nextMove:(ChessMove *)aMove {
    
  [_activePlayer applyMove:aMove];

  if (self.hasUserAgent) {
    NSDictionary *description = @{ @"move" : aMove, @"white" : [NSNumber numberWithBool:_activePlayer.isWhitePlayer]};
    NSNotification *notification = [NSNotification notificationWithName:@"CompletedMove" object:description];
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
  }
  
    _activePlayer = (_whitePlayer == _activePlayer) ? _blackPlayer : _whitePlayer;
    [_activePlayer prepareNextMove];
}

-(void)nullMove {
    
    _activePlayer = (_whitePlayer == _activePlayer) ? _blackPlayer : _whitePlayer;
    [_activePlayer prepareNextMove];
}

-(void)undoMove:(ChessMove *)aMove {
    
  _activePlayer = (_whitePlayer == _activePlayer) ? _blackPlayer : _whitePlayer;
  [_activePlayer undoMove:aMove];

  if (self.hasUserAgent) {
    NSDictionary *description = @{ @"move" : aMove, @"white" : [NSNumber numberWithBool:_activePlayer.isWhitePlayer]};
    NSNotification *notification = [NSNotification notificationWithName:@"UndoMove" object:description];
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
  }
}

#pragma mark Printing

-(NSString *)description {
    return [NSString stringWithFormat:@"%@ (%d %d)", [super description], _hashKey, _hashLock];
}

-(void)printWhitePieces {
    printf("\n ==== white ====");
    for (int i=0; i<64; i++) {
        if (0 == (i % 8)) {
            printf("\n");
        }
        printf("%2d", _whitePlayer.pieces[i]);
    }
    printf("\n ===============\n");
}

-(void)printBlackPieces {
    printf("\n ==== black ====");
    for (int i=0; i<64; i++) {
        if (0 == (i % 8)) {
            printf("\n");
        }
        printf("%2d", _blackPlayer.pieces[i]);
    }
    printf("\n ===============\n");
}

-(void)printPieces {
    
    printf("\n board: %d %d", _hashKey, _hashLock);
    [self printWhitePieces];
    [self printBlackPieces];
}

@end
