//
//  ChessTTEntry.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-28.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "ChessTTEntry.h"


@implementation ChessTTEntry

@synthesize value, valueType, depth, hashLock, timeStamp;

-(ChessTTEntry *)initializeWithEntry:(ChessTTEntry *)entry {
  ChessTTEntry *newEntry = [self init];
  
  newEntry.value = entry.value;
  newEntry.valueType = entry.valueType;
  newEntry.depth = entry.depth;
  newEntry.hashLock = entry.hashLock;
  newEntry.timeStamp = entry.timeStamp;
  
  return newEntry;
}

#pragma mark copying

// shallow copy
-(id)copyWithZone:(NSZone *)zone {
  return [[ChessTTEntry alloc] initializeWithEntry:self];
}

-(void)clear {
  value = valueType = timeStamp = depth = -1;
}

@end
