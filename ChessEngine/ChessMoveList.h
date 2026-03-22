//
//  ChessMoveList.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-22.
//  Copyright 2010 Steven Wart. All rights reserved.
//
//  A streaming class
//

#import <Foundation/Foundation.h>

@class ChessHistoryTable;
@class ChessMove;

@interface ChessMoveList : NSObject {

    NSMutableArray *collection;
    int startIndex;
    int position;
    int readLimit;
}

// accessing

-(NSArray *)copyContents;
-(int)startIndex;
-(void)on:(NSMutableArray *)anArray from:(int)firstIndex to:(int)lastIndex;

// stream protocol

-(BOOL)atEnd;
-(ChessMove *)next;
-(int)count;
-(BOOL)isEmpty;

// sorting

-(void)sortUsing:(ChessHistoryTable *)sorter;
-(void)promoteMoveIndex:(int)hashIndex;

@end
