//
//  ChessHistoryTable.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-21.
//  Copyright 2010 Steven Wart. All rights reserved.
//
// This class is a history table for our 'killer heuristic'. It remembers moves that have proven effective
// in the past and is later used to prioritize newly generated moves according to the effectiveness of the
// particular move in the past.
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
    memset_pattern4(entries, &wordValue, sizeof(int) * HISTORY_TABLE_SIZE);
}

-(void)clear {
    [self atAllPut:0];
}

// sorting
-(NSComparisonResult)sorts:(ChessMove *)move1 before:(ChessMove *)move2 {
  
  int a = ([move1 sourceSquare] << 6) + [move1 destinationSquare];
  int b = ([move2 sourceSquare] << 6) + [move2 destinationSquare];
  
  return entries[b] - entries[a];
  
//  sorts: move1 before: move2
//    ^(self at: (move1 sourceSquare bitShift: 6) + move1 destinationSquare) >
//      (self at: (move2 sourceSquare bitShift: 6) + move2 destinationSquare)
}

@end
