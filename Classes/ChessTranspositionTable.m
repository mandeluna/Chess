//
//  ChessTranspositionTable.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-28.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "ChessTranspositionTable.h"
#import "ChessTTEntry.h"
#import "ChessBoard.h"

@implementation ChessTranspositionTable

#pragma mark initialize

//
// Set the following to true for printing information about the fill rate and number of collisions.
// The transposition table should have *plenty* of free space (it should rarely exceed 30% fill rate)
// and *very* few collisions (those require us to evaluate positions repeatedly that we've evaluated before -- bad idea!)
//
-(void)clear {
    
    if (1) {
        if ([array count] > 0) {
            NSLog(@"entries used:   %d (%2d%%)", [used count], ([used count] * 100 / [array count]));
            
            if (collisions > 0)
                NSLog(@"collisions:     %d (%2d%%)", collisions, (collisions * 100 / [array count]));
        }
    }
    for (ChessTTEntry *entry in used) {
        [entry clear];
    }
    [used removeAllObjects];

    collisions = 0;
}

-(id)initWithBits:(int)nBits {
    if (self = [super init]) {
        int capacity = 1<<nBits;
        
        array = [[NSMutableArray arrayWithCapacity:capacity] retain];
        used = [[NSMutableArray arrayWithCapacity:50000] retain];
        ChessTTEntry *entry = [[ChessTTEntry alloc] init];
        [entry clear];
        for (int i=0; i<capacity; i++) {
            [array addObject:[[entry copy] autorelease]];
        }
        [entry release];
        collisions = 0;
    }
    return self;
}

-(void)storeBoard:(ChessBoard *)aBoard value:(int)value type:(int)valueType depth:(int)depth stamp:(int)timeStamp {
    
    int key = [aBoard hashKey] & ([array count] - 1);
    ChessTTEntry *entry = [array objectAtIndex:key];
    
    if (-1 == entry.valueType) {
        [used addObject:entry];
    }
    else {
        if (entry.hashLock != aBoard.hashLock) {
            collisions++;
        }
    }
    
//    (entry valueType = -1 
//     or:[entry depth <= depth
//         or:[entry timeStamp < timeStamp]]) ifFalse:[^self].
    
    if (entry.valueType != -1) return;
    if (entry.depth > depth) return;
    if (entry.timeStamp >= timeStamp) return;
    
    
    entry.hashLock = aBoard.hashLock;
    entry.value = value;
    entry.valueType = valueType;
    entry.depth = depth;
    entry.timeStamp = timeStamp;
}

-(void)dealloc {
    
    [super dealloc];
    [array release];
    [used release];
}

#pragma mark lookup

-(ChessTTEntry *)lookupBoard:(ChessBoard *)aBoard {
    
    int key = [aBoard hashKey] & ([array count] - 1);
    ChessTTEntry *entry = [array objectAtIndex:key];
    
    if (nil == entry)
        return nil;
    
    if (-1 == entry.valueType)
        return nil;
    
    if (entry.hashLock != aBoard.hashLock)
        return nil;
    
    return entry;
}


@end
