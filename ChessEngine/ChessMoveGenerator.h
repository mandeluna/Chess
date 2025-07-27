//
//  ChessMoveGenerator.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChessPlayer;
@class ChessMove;
@class ChessMoveList;

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

typedef struct {

    int count;
    int *moves;

} DirectionalMoveList;

typedef struct {

    int count;
    DirectionalMoveList *directionalMoves;

} PossibleMoveList;

@interface ChessMoveGenerator : NSObject {

    ChessPlayer *myPlayer;
    unsigned char *myPieces;
    unsigned char *itsPieces;
    int castlingStatus;
    int enpassantSquare;
    BOOL forceCaptures;
    NSMutableArray *moveList;
    int firstMoveIndex;
    int lastMoveIndex;
    NSMutableArray *streamList;
    int streamListIndex;
    char attackSquares[64];
    ChessMove *kingAttack;
}

@property(nonatomic, assign) ChessMove *kingAttack;

// public
-(char *)attackSquares;
-(ChessMoveList *)findAllPossibleMovesFor:(ChessPlayer *)player;
-(ChessMoveList *)findPossibleMovesFor:(ChessPlayer *)player;
-(ChessMoveList *)findPossibleMovesFor:(ChessPlayer *)player at:(int)square;
-(ChessMoveList *)findQuiescenceMovesFor:(ChessPlayer *)player;
-(ChessMoveList *)moveList;
-(void)profileGenerationFor:(ChessPlayer *)player;
-(void)recycleMoveList:(ChessMoveList *)aChessMoveList;

// debugging

-(float)moveListUsage;

// moves-pawns

-(void)blackPawnCaptureAt:(int)square direction:(int)dir;
-(void)blackPawnPushAt:(int)square;
-(void)moveBlackPawnAt:(int)square;
-(void)whitePawnCaptureAt:(int)square direction:(int)dir;
-(void)whitePawnPushAt:(int)square;
-(void)moveWhitePawnAt:(int)square;
-(void)promotePawn:(ChessMove *)move;

// support

-(BOOL)canCastleBlackKingSide;
-(BOOL)canCastleBlackQueenSide;
-(BOOL)canCastleWhiteKingSide;
-(BOOL)canCastleWhiteQueenSide;
-(BOOL)checkAttack:(DirectionalMoveList *)squares fromPieces:(int *)pieces;
-(BOOL)checkUnprotectedAttack:(DirectionalMoveList *)squares fromPiece:(int)piece;

// moves-general

-(void)moveBishopAt:(int)square;
-(void)moveBlackKingAt:(int)square;
-(void)moveKingAt:(int)square;
-(void)moveKnightAt:(int)square;
-(void)movePawnAt:(int)square;
-(void)movePiece:(int)piece along:(DirectionalMoveList *)rayList at:(int)square;
-(void)moveQueenAt:(int)square;
-(void)moveRookAt:(int)square;
-(void)moveWhiteKingAt:(int)square;

@end
