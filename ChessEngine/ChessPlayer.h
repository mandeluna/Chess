//
//  ChessPlayer.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChessBoard;
@class ChessMove;

@interface ChessPlayer : NSObject <NSCopying> {

    ChessPlayer *opponent;
    ChessBoard *board;
    
//    char pieces[64];
    unsigned char *pieces;
    int materialValue;
    int positionalValue;
    int numPawns;
    int enpassantSquare;
    int castlingRookSquare;
    int castlingStatus;
}

@property(nonatomic, retain) ChessPlayer *opponent;
@property(nonatomic, retain) ChessBoard *board;
@property(nonatomic, readonly) int castlingRookSquare;
@property(nonatomic, readonly) int castlingStatus;
@property(nonatomic, readonly) int enpassantSquare;
@property(nonatomic, readonly) int materialValue;
@property(nonatomic, readonly) int positionalValue;
@property(nonatomic, readonly) int numPawns;

// instance creation
-(ChessPlayer *)initializeWithPlayer:(ChessPlayer *)player;

// initialize

-(void)prepareNextMove;

// adding/removing

-(void)addBlackPieces;
-(void)addPiece:(int)piece at:(int)square;
-(void)addWhitePieces;
-(void)movePiece:(int)piece from:(int)start to:(int)end;
-(void)removePiece:(int)piece at:(int)square;
-(void)replacePiece:(int)piece with:(int)anotherPiece at:(int)square;

// moving

-(void)applyCastleKingSideMove:(ChessMove *)move;
-(void)applyCastleQueenSideMove:(ChessMove *)move;
-(void)applyDoublePushMove:(ChessMove *)move;
-(void)applyEnPassantMove:(ChessMove *)move;
-(void)applyMove:(ChessMove *)move;
-(void)applyNormalMove:(ChessMove *)move;
-(void)applyPromotion:(ChessMove *)move;
-(void)applyResign:(ChessMove *)move;
-(void)applyStaleMate:(ChessMove *)move;
-(void)updateCastlingStatus:(ChessMove *)move;

// accessing

-(int)pieceAt:(int)square;
-(unsigned char *)pieces;

// testing

-(BOOL)canCastleKingSide;
-(BOOL)canCastleQueenSide;
-(BOOL)isValidMove:(ChessMove *)move;
-(BOOL)isValidMoveFrom:(int)sourceSquare to:(int)destSquare;
-(BOOL)isWhitePlayer;

// copying

-(void)copyPlayer:(ChessPlayer *)anotherPlayer;

// evaluation

-(int)evaluate;
-(int)evaluatePosition;
-(int)evaluateMaterial;
-(int)positionalValue;

// moves-general

-(NSArray *)findPossibleMoves;
-(NSArray *)findPossibleMovesAt:(int)square;
-(NSArray *)findQuiescenceMoves;
-(NSArray *)findValidMoves;
-(NSArray *)findValidMovesAt:(int)square;

// undo

-(void)undoCastlingKingSideMove:(ChessMove *)move;
-(void)undoCastlingQueenSideMove:(ChessMove *)move;
-(void)undoDoublePushMove:(ChessMove *)move;
-(void)undoEnpassantMove:(ChessMove *)move;
-(void)undoMove:(ChessMove *)move;
-(void)undoNormalMove:(ChessMove *)move;
-(void)undoPromotion:(ChessMove *)move;
-(void)undoResign:(ChessMove *)move;
-(void)undoStaleMate:(ChessMove *)move;

@end
