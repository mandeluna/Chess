//
//  ChessHistoryTable.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HISTORY_TABLE_SIZE  4096+64

@class ChessMove;

@interface ChessHistoryTable : NSObject {

    int entries[HISTORY_TABLE_SIZE];
}

// accessing
-(void)addMove:(ChessMove *)move;

// initialize
-(void)atAllPut:(int)wordValue;
-(void)clear;

// sorting
-(BOOL)sorts:(ChessMove *)move before:(ChessMove *)anotherMove;

@end
