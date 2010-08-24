//
//  ChessUserAgent.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ChessUserAgent

-(void)gameReset;
-(void)addedPiece:(int)piece at:(int)square white:(BOOL)isWhitePlayer;
-(void)movedPiece:(int)piece from:(int)sourceSquare to:(int)destSquare;
-(void)removedPiece:(int)piece at:(int)square;
-(void)replacedPiece:(int)oldPiece with:(int)newPiece at:(int)square white:(BOOL)isWhitePlayer;
-(void)finishedGame:(BOOL)result;

@end
