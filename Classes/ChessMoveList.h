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

// sorting
-(void)sort:(int)i to:(int)j using:(ChessHistoryTable *)sorter;
-(void)sortUsing:(ChessHistoryTable *)sorter;

@end
