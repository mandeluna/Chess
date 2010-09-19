//
//  ChessHistoryTable.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "ChessHistoryTable.h"
#import "ChessMove.h"

@implementation ChessHistoryTable


// accessing
-(void)addMove:(ChessMove *)move {
    int index = (move.sourceSquare << 6) + move.destinationSquare;
    //NSLog(@"adding entry with index %d", index);
    entries[index] = entries[index+1];
}

// initialize
-(void)atAllPut:(int)wordValue {
//    memset_pattern4(entries, &wordValue, sizeof(int) * HISTORY_TABLE_SIZE);
    for (int i=0; i<HISTORY_TABLE_SIZE; i++) {
        entries[i] = wordValue;
    }
}

-(void)clear {
    [self atAllPut:0];
}

// sorting
-(BOOL)sorts:(ChessMove *)move1 before:(ChessMove *)move2 {
    
    int a = ([move1 sourceSquare] << 6) + [move1 destinationSquare];
    int b = ([move2 sourceSquare] << 6) + [move2 destinationSquare];
    
    //NSLog(@"comparing entries[%d]=%d to entries[%d]=%d", a, entries[a], b, entries[b]);
    
    return (entries[a] > entries[b]);
}


@end
