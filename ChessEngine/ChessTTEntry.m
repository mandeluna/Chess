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

-(void)clear {
    
    value = valueType = timeStamp = depth = -1;
}

@end
