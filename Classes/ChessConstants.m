//
//  ChessConstants.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "ChessConstants.h"


// castling constants

static int CastlingDone;
static int CastlingDisableKingSide;
static int CastlingDisableQueenSide;
static int CastlingDisableAll;
static int CastlingEnableKingSide;
static int CastlingEnableQueenSide;

// piece values

static int PieceValues[6];  // one for each piece constant

@implementation ChessConstants

#pragma mark initialization

+(void)initialize {
    
    [self initializeCastlingConstants];
    [self initializePieceValues];
}

+(void)initializeCastlingConstants {
    
    CastlingDone = 1 << 0;
    CastlingDisableKingSide = 1 << 1;
    CastlingDisableQueenSide = 1 << 2;
    CastlingDisableAll = CastlingDisableQueenSide | CastlingDisableKingSide;
    CastlingEnableKingSide = CastlingDone | CastlingDisableKingSide;
    CastlingEnableQueenSide = CastlingDone | CastlingDisableQueenSide;    
}

+(void)initializePieceValues {
    
    PieceValues[kPawn] = 100;
    PieceValues[kKnight] = 300;
    PieceValues[kBishop] = 350;
    PieceValues[kRook] = 500;
    PieceValues[kQueen] = 900;
    PieceValues[kKing] = 2000;
}

@end
