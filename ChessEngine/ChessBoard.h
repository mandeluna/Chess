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

@interface ChessBoard : NSObject {

}

@property(nonatomic, retain) ChessPlayer *whitePlayer;
@property(nonatomic, retain) ChessPlayer *blackPlayer;
@property(nonatomic, assign) ChessPlayer *activePlayer;
@property(nonatomic, retain) ChessMoveGenerator *generator;
@property(nonatomic, retain) ChessPlayerAI *searchAgent;
@property(nonatomic, assign) int hashKey;
@property(nonatomic, assign) int hashLock;

// instance creation (ARC support)
+(ChessBoard *)initializeWithBoard:(ChessBoard *)aBoard;

// initialize
-(void)resetGame;
-(void)initializeNewBoard;
-(ChessBoard *)initializeWithBoard:(ChessBoard *)aBoard;

// copying
-(ChessBoard *)duplicateBoard:(ChessBoard *)aBoard;

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

@end
