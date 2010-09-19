//
//  ChessMoveGenerator.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChessConstants.h"

@class ChessPlayer;
@class ChessMove;
@class ChessMoveList;

typedef struct {
    int count;
    int *moves;
} moveValueList;

@interface ChessMoveGenerator : NSObject {

    ChessPlayer *myPlayer;
    char myPieces[64];
    char itsPieces[64];
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

@property(nonatomic, retain) ChessMove *kingAttack;

// public

-(char *)attackSquares;
-(ChessMoveList *)findAllPossibleMovesFor:(ChessPlayer *)player;
-(char *)findAttackSquaresFor:(ChessPlayer *)player;
-(ChessMoveList *)findPossibleMovesFor:(ChessPlayer *)player;
-(ChessMoveList *)findPossibleMovesFor:(ChessPlayer *)player at:(int)square;
-(ChessMoveList *)findQuiescenceMovesFor:(ChessPlayer *)player;
-(ChessMoveList *)moveList;
-(void)profileGenerationFor:(ChessPlayer *)player;
-(void)recycleMoveList:(ChessMoveList *)aChessMoveList;

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
-(BOOL)checkAttack:(moveValueList *)squares fromPieces:(int *)pieces;
-(BOOL)checkUnprotectedAttack:(moveValueList *)squares fromPiece:(int)piece;

// moves-general

-(void)moveBishopAt:(int)square;
-(void)moveBlackKingAt:(int)square;
-(void)moveKingAt:(int)square;
-(void)moveKnightAt:(int)square;
-(void)movePawnAt:(int)square;
-(void)movePiece:(int)piece along:(moveValueList *)rayList at:(int)square;
-(void)moveQueenAt:(int)square;
-(void)moveRookAt:(int)square;
-(void)moveWhiteKingAt:(int)square;

@end
