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
    
}

// initialize
-(void)atAllPut:(int)wordValue {
    memset_pattern4(entries, &wordValue, sizeof(int) * HISTORY_TABLE_SIZE);
}

-(void)clear {
    [self atAllPut:0];
}

// sorting
-(BOOL)sorts:(ChessMove *)move1 before:(ChessMove *)move2 {
    
    return ((entries[[move1 sourceSquare] << 6] + [move1 destinationSquare]) >
            (entries[[move2 sourceSquare] << 6] + [move2 destinationSquare]));
}


@end
