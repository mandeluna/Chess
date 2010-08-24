//
//  ChessConstants.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>

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

// moves

#define BETWEEN07(i) ((i >= 0) && (i <= 7))

typedef struct {
    int count;
    int *moves;
} moveValueList;

static moveValueList KingMoves[64];
static moveValueList RookMoves[64];
static moveValueList BishopMoves[64];
static moveValueList KnightMoves[64];

// center scores

static int PieceCenterScores[6][64] = {

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

// use 1-origin offsets so we can terminate a list of constants with 0
// used in castling determination -- canCastle(White|Black)(King|Queen)Side

static int A1 =  1, B1 =  2, C1 =  3, D1 =  4, E1 =  5, F1 =  6, G1 =  7, H1 =  8;
static int A2 =  9, B2 = 10, C2 = 11, D2 = 12, E2 = 13, F2 = 14, G2 = 15, H2 = 16;
static int A3 = 17, B3 = 18, C3 = 19, D3 = 20, E3 = 21, F3 = 22, G3 = 23, H3 = 24;
static int A4 = 25, B4 = 26, C4 = 27, D4 = 28, E4 = 29, F4 = 30, G4 = 31, H4 = 32;
static int A5 = 33, B5 = 34, C5 = 35, D5 = 36, E5 = 37, F5 = 38, G5 = 39, H5 = 40;
static int A6 = 41, B6 = 42, C6 = 43, D6 = 44, E6 = 45, F6 = 46, G6 = 47, H6 = 48;
static int A7 = 49, B7 = 50, C7 = 51, D7 = 52, E7 = 53, F7 = 54, G7 = 55, H7 = 56;
static int A8 = 57, B8 = 58, C8 = 59, D8 = 60, E8 = 61, F8 = 62, G8 = 63, H8 = 64;

@interface ChessConstants : NSObject {

}

+(void)initializeCastlingConstants;
+(void)initializePieceValues;
+(void)initializeMoves;
+(void)initializeKnightMoves;
+(void)initializeRookMoves;
+(void)initializeBishopMoves;
+(void)initializeKingMoves;
+(void)initializeBishopMovers;
+(void)initializeRookMovers;

@end
