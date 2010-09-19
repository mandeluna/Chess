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

static int CastlingDone;
static int CastlingDisableKingSide;
static int CastlingDisableQueenSide;
static int CastlingDisableAll;
static int CastlingEnableKingSide;
static int CastlingEnableQueenSide;

// piece values

static int PieceValues[6];  // one for each piece constant

// center scores

static int PieceCenterScores[7][64] = {
    
    // PieceCenterScores[kEmptySquare] -- placeholder
    
    { 0 },

    // PieceCenterScores[kPawn]

    { 0 },

    // PieceCenterScores[kKnight]
    {
        -4,	0,	0,	0,	0,	0,	0,	-4,
        -4,	0,	2,	2,	2,	2,	0,	-4,
        -4,	2,	3,	2,	2,	3,	2,	-4,
        -4,	1,	2,	5,	5,	2,	2,	-4,
        -4,	1,	2,	5,	5,	2,	2,	-4,
        -4,	2,	3,	2,	2,	3,	2,	-4,
        -4,	0,	2,	2,	2,	2,	0,	-4,
        -4,	0,	0,	0,	0,	0,	0,	-4
    },

    // PieceCenterScores[kBishop]
    {
        -2,	-2,	-2,	-2,	-2,	-2,	-2,	-2,
        -2,	0,	0,	0,	0,	0,	0,	-2,
        -2,	0,	1,	1,	1,	1,	0,	-2,
        -2,	0,	1,	2,	2,	1,	0,	-2,
        -2,	0,	1,	2,	2,	1,	0,	-2,
        -2,	0,	1,	1,	1,	1,	0,	-2,
        -2,	0,	0,	0,	0,	0,	0,	-2,
        -2,	-2,	-2,	-2,	-2,	-2,	-2,	-2
    },

    // PieceCenterScores[kRook]
    
    { 0 },
    
    // PieceCenterScores[kQueen]
    {
        -3,	0,	0,	0,	0,	0,	0,	-3,
        -2,	0,	0,	0,	0,	0,	0,	-2,
        -2,	0,	1,	1,	1,	1,	0,	-2,
        -2,	0,	1,	2,	2,	1,	0,	-2,
        -2,	0,	1,	2,	2,	1,	0,	-2,
        -2,	0,	1,	1,	1,	1,	0,	-2,
        -2,	0,	0,	0,	0,	0,	0,	-2,
        -3,	0,	0,	0,	0,	0,	0,	-3
    },
    
    // PieceCenterScores[kKing]
    
    { 0 }
};

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

+(void)initializeCastlingConstants;
+(void)initializePieceValues;

@end
