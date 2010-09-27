//
//  ChessConstants.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NUM_PLIES   100                 // size of streamList array
#define NUM_MOVES   30 * NUM_PLIES      // size of moveList array

// piece constants

enum {
    kEmptySquare = 0,
    kPawn,
    kKnight,
    kBishop,
    kRook,
    kQueen,
    kKing
};

// castling constants

#define kCastlingDone                   1
#define kCastlingDisableKingSide        2
#define kCastlingDisableQueenSide       4
#define kCastlingDisableAll             (kCastlingDisableQueenSide | kCastlingDisableKingSide)
#define kCastlingEnableKingSide         (kCastlingDone | kCastlingDisableKingSide)
#define kCastlingEnableQueenSide        (kCastlingDone | kCastlingDisableQueenSide)

// bishop movers

static int BishopMovers[2] = {kBishop, kQueen};

// rook movers

static int RookMovers[2] = {kRook, kQueen};

// square constants
// used in castling determination -- canCastle(White|Black)(King|Queen)Side

static int A1 =  0, B1 =  1, C1 =  2, D1 =  3, E1 =  4, F1 =  5, G1 =  6, H1 =  7;
static int A2 =  8, B2 =  9, C2 = 10, D2 = 11, E2 = 12, F2 = 13, G2 = 14, H2 = 15;
static int A3 = 16, B3 = 17, C3 = 18, D3 = 19, E3 = 20, F3 = 21, G3 = 22, H3 = 23;
static int A4 = 24, B4 = 25, C4 = 26, D4 = 27, E4 = 28, F4 = 29, G4 = 30, H4 = 31;
static int A5 = 32, B5 = 33, C5 = 34, D5 = 35, E5 = 36, F5 = 37, G5 = 38, H5 = 39;
static int A6 = 40, B6 = 41, C6 = 42, D6 = 43, E6 = 44, F6 = 45, G6 = 46, H6 = 47;
static int A7 = 48, B7 = 49, C7 = 50, D7 = 51, E7 = 52, F7 = 53, G7 = 54, H7 = 55;
static int A8 = 56, B8 = 57, C8 = 58, D8 = 59, E8 = 60, F8 = 61, G8 = 62, H8 = 63;

@interface ChessConstants : NSObject {

}

@end
