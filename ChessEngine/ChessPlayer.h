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

    __weak ChessPlayer *opponent;
    __weak ChessBoard *board;
    
    unsigned char *pieces;
    int materialValue;
    int positionalValue;
    int numPawns;
    int enpassantSquare;
    int castlingRookSquare;
    int castlingStatus;
}

// board owns both players; players should have weak references to each other and to the board
@property(nonatomic, weak) ChessPlayer *opponent;
@property(nonatomic, weak) ChessBoard *board;
@property(nonatomic, readonly) int castlingRookSquare;
@property(nonatomic, readonly) int castlingStatus;
@property(nonatomic, assign) int enpassantSquare;
@property(nonatomic, readonly) int materialValue;
@property(nonatomic, readonly) int positionalValue;
@property(nonatomic, readonly) int numPawns;

// instance creation
-(ChessPlayer *)initFromPlayer:(ChessPlayer *)player;

// initialize

-(void)prepareNextMove;

// adding/removing

-(void)addBlackPieces;
-(void)addPiece:(int)piece at:(int)square;
-(void)addWhitePieces;
-(void)movePiece:(int)piece from:(int)start to:(int)end;
-(void)removePiece:(int)piece at:(int)square;
-(void)replacePiece:(int)piece with:(int)anotherPiece at:(int)square;
-(void)removeAllPieces;

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
-(void)setCastlingFlags:(int)flags;
-(void)clearCastlingFlags:(int)flags;

// accessing

-(int)pieceAt:(int)square;
-(unsigned char *)pieces;
-(int)num_pieces;

// testing

// false if active player's castling is permanently disabled (e.g. by a king or rook move or capture)
-(BOOL)isCastlingEnabledKingSide;
-(BOOL)isCastlingEnabledQueenSide;

// false if active player's castling is permanently or temporarily disabled (e.g. by a king or rook move or capture)
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
