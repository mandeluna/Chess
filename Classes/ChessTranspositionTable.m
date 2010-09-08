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

-(void)clear {
    
}

-(id)initWithBits:(int)nBits {
    if (self = [super init]) {
        int capacity = 1<<nBits;
        
        array = [[NSMutableArray arrayWithCapacity:capacity] retain];
        used = [[NSMutableArray arrayWithCapacity:50000] retain];
        ChessTTEntry *entry = [[ChessTTEntry alloc] init];
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
    
    if (!((-1 == entry.valueType) || (entry.depth < depth) || (entry.timeStamp < timeStamp))) {
        return;
    }
    
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
