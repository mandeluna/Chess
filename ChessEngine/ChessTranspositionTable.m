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
    for (ChessTTEntry *entry in used) {
        [entry clear];
    }
    [used removeAllObjects];
    collisions = 0;
}

// the hash is x permill full, the engine should send this info regularly
-(NSString *)hashfull {
  return [NSString stringWithFormat:@"%d", (int)([used count] * 1000.0 / [array count])];
}

-(NSString *)description {
  return [NSString stringWithFormat:@"TT entries: %lu (%d%%), collisions: %d",
                      (unsigned long)[used count], (int)([used count] * 100.0 / [array count]), collisions];
}

-(id)initWithBits:(int)nBits {
    if (self = [super init]) {
        int capacity = 1<<nBits;

        array = [NSMutableArray arrayWithCapacity:capacity];
        used = [NSMutableArray array];
#if !__has_feature(objc_arc)
    [array retain];
    [used retain];
#endif
        ChessTTEntry *entry = [[ChessTTEntry alloc] init];
        [entry clear];
        for (int i=0; i<capacity; i++) {
            ChessTTEntry *copy = [entry copy];
            #if !__has_feature(objc_arc)
                [copy autorelease];
            #endif
          array[i] = copy;
        }
        #if !__has_feature(objc_arc)
        [entry release];
        #endif
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

  if ((entry.valueType != -1) && (entry.depth > depth) && (entry.timeStamp >= timeStamp)) {
    return;
  }


    entry.hashLock = aBoard.hashLock;
    entry.value = value;
    entry.valueType = valueType;
    entry.depth = depth;
    entry.timeStamp = timeStamp;
}

#if !__has_feature(objc_arc)
-(void)dealloc {

    [super dealloc];
    [array release];
    [used release];
}
#endif

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
