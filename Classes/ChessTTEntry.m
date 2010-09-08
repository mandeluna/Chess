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

#pragma mark copying

-(id)copyWithZone:(NSZone *)zone {
    
    // shallow copy
    id copy = NSCopyObject(self, 0, zone);
    
    return copy;
}

@end
