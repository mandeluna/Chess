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
#import "NSNotificationCenter+MainThread.h"

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

-(ChessBoard *)initializeWithBoard:(ChessBoard *)aBoard {
  ChessBoard *board = [self init];

  board.whitePlayer = aBoard.whitePlayer;
  board.blackPlayer = aBoard.blackPlayer;
  board.activePlayer = aBoard.activePlayer;
  board.generator = aBoard.generator;
  board.searchAgent = aBoard.searchAgent;
  board.hashKey = aBoard.hashKey;
  board.hashLock = aBoard.hashLock;

  return board;
}

#pragma mark Initialize

-(void)resetGame {
  _hashKey = _hashLock = 0;

#if !__has_feature(objc_arc)
  self.whitePlayer = [[[ChessPlayer alloc] init] autorelease];
  self.blackPlayer = [[[ChessPlayer alloc] init] autorelease];
#else
  self.whitePlayer = [[ChessPlayer alloc] init];
  self.blackPlayer = [[ChessPlayer alloc] init];
#endif

  _whitePlayer.opponent = _blackPlayer;
  _whitePlayer.board = self;
  _blackPlayer.opponent = _whitePlayer;
  _blackPlayer.board = self;
  _activePlayer = _whitePlayer;
  [_searchAgent reset:self];
}

-(void)initializeNewBoard {
  [_whitePlayer removeAllPieces];
  [_blackPlayer removeAllPieces];
  [self resetGame];
  [_whitePlayer addWhitePieces];
  [_blackPlayer addBlackPieces];
  _activePlayer = _whitePlayer;
}

-(id)init {
  if (self = [super init]) {
    _generator = [[ChessMoveGenerator alloc] init];
    _searchAgent = [[ChessPlayerAI alloc] init];
  }
  return self;
}

#if !__has_feature(objc_arc)
-(void)dealloc {
  [_whitePlayer release];
  [_blackPlayer release];
  [_generator release];
  [_searchAgent release];
  [super dealloc];
}
#endif

#pragma mark Copying

-(ChessBoard *)duplicateBoard:(ChessBoard *)aBoard {
  [_whitePlayer copyPlayer:aBoard.whitePlayer];
  [_blackPlayer copyPlayer:aBoard.blackPlayer];
  _activePlayer = [aBoard.activePlayer isWhitePlayer] ? _whitePlayer : _blackPlayer;
  _hashKey = [aBoard hashKey];
  _hashLock = [aBoard hashLock];
  _hasUserAgent = NO;
#if !__has_feature(objc_arc)
  _searchAgent = [aBoard.searchAgent retain];
  _generator = [aBoard.generator retain];
#else
  self.searchAgent = aBoard.searchAgent;
  self.generator = aBoard.generator;
#endif
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

  _whitePlayer.opponent = _blackPlayer;
  _blackPlayer.opponent = _whitePlayer;
  _whitePlayer.board = self;
  _blackPlayer.board = self;
  self.hasUserAgent = NO;
}

// deep copy
-(id)copyWithZone:(NSZone *)zone {
//  ChessBoard *copy = NSCopyObject(self, 0, nil);
  ChessBoard *copy = [[ChessBoard alloc] initializeWithBoard:self];
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
  return [self printPieces];
}

//  ╔═╤═╤═╤═╤═╤═╤═╤═╗╮
//  ║♜│♞│♝│♛│♚│♝│♞│♜║8
//  ╟─┼─┼─┼─┼─┼─┼─┼─╢┊
//  ║♟│♟│♟│♟│♟│♟│♟│♟║7
//  ╟─┼─┼─┼─┼─┼─┼─┼─╢┊
//  ║ │░│ │░│ │░│ │░║6
//  ╟─┼─┼─┼─┼─┼─┼─┼─╢┊
//  ║░│ │░│ │░│ │░│ ║5
//  ╟─┼─┼─┼─┼─┼─┼─┼─╢┊
//  ║ │░│ │░│ │░│ │░║4
//  ╟─┼─┼─┼─┼─┼─┼─┼─╢┊
//  ║░│ │░│ │░│ │░│ ║3
//  ╟─┼─┼─┼─┼─┼─┼─┼─╢┊
//  ║♙│♙│♙│♙│♙│♙│♙│♙║2
//  ╟─┼─┼─┼─┼─┼─┼─┼─╢┊
//  ║♖│♘│♗│♕│♔│♗│♘│♖║1
//  ╚═╧═╧═╧═╧═╧═╧═╧═╝┊
//  ╰a┈b┈c┈d┈e┈f┈g┈h┈╯

NSArray *whiteEmoji = @[@"♙", @"♘", @"♗", @"♖", @"♕", @"♔"];
NSArray *blackEmoji = @[@"♟", @"♞", @"♝", @"♜", @"♛", @"♚"];

-(NSString *)printPieces {
  NSMutableString *result = [NSMutableString string];

//  [result appendString: [NSString stringWithFormat: @"\nkey: %d, lock: %d", _hashKey, _hashLock]];
  NSString *nextString = (_activePlayer == _whitePlayer) ? @"White to Move" : @"Black to Move";
  [result appendString: nextString];

  [result appendString: @"\n╔═╤═╤═╤═╤═╤═╤═╤═╗╮"];

  // print the board from rank 8 at the top
  for (int rank = 8; rank >= 1; rank--) {
    for (int file = 'a'; file <= 'h'; file++) {
      int col = file - 'a';
      int row = rank - 1;
      int square = row * 8 + col;
      
      if (col == 0) {
        [result appendString:@"\n"];
        if (row < 7) {
          [result appendString:@"╟─┼─┼─┼─┼─┼─┼─┼─╢┊\n"];
        }
        [result appendString:@"║"];
      }
      unsigned char black =_blackPlayer.pieces[square];
      unsigned char white =_whitePlayer.pieces[square];

      if (black) {
        [result appendString: blackEmoji[black - 1]];
      }
      else if (white) {
        [result appendString: whiteEmoji[white - 1]];
      }
      else {
        [result appendString: @" "];
      }
      if (col == 7) {
        [result appendString: [NSString stringWithFormat:@"║%d", rank]];
      }
      else {
        [result appendString:@"│"];
      }
    }
  }

  [result appendString: @"\n╚═╧═╧═╧═╧═╧═╧═╧═╝┊"];
  [result appendString: @"\n╰a┈b┈c┈d┈e┈f┈g┈h┈╯"];
  return result;
}

@end
