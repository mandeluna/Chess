//
//  ChessBoard.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChessMoveGenerator;
@class ChessPlayer;
@class ChessPlayerAI;
@class ChessMove;

@interface ChessBoard : NSObject <NSCopying> {

}

@property(nonatomic, retain) ChessPlayer *whitePlayer;
@property(nonatomic, retain) ChessPlayer *blackPlayer;
@property(nonatomic, assign) ChessPlayer *activePlayer;
@property(nonatomic, assign) ChessMoveGenerator *generator;
@property(nonatomic, assign) ChessPlayerAI *searchAgent;
@property(nonatomic, assign) int hashKey;
@property(nonatomic, assign) int hashLock;
@property(nonatomic, assign) BOOL hasUserAgent;


// initialize
-(void)resetGame;
-(void)initializeNewBoard;

// copying
-(ChessBoard *)duplicateBoard:(ChessBoard *)aBoard;
-(id)copyWithZone:(NSZone *)zone;

// hashing
-(int)hashKey;
-(int)hashLock;
-(void)updateHash:(int)piece at:(int)square from:(ChessPlayer *)player;

// moving
-(ChessMove *)movePieceFrom:(int)sourceSquare to:(int)destSquare;
-(void)nextMove:(ChessMove *)aMove;
-(void)nullMove;
-(void)undoMove:(ChessMove *)aMove;

// printing
-(NSString *)description;
-(void)printPieces;

@end
