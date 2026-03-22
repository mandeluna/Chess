//
//  ChessTTEntry.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-28.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ChessTTEntry : NSObject <NSCopying> {

    int value;
    int valueType;
    int depth;
    int hashLock;
    int timeStamp;
    int bestMoveIndex;  // (sourceSquare << 6) | destinationSquare; 0 = none
}

@property(nonatomic, assign) int value;
@property(nonatomic, assign) int valueType;
@property(nonatomic, assign) int depth;
@property(nonatomic, assign) int hashLock;
@property(nonatomic, assign) int timeStamp;
@property(nonatomic, assign) int bestMoveIndex;

-(ChessTTEntry *)initializeWithEntry:(ChessTTEntry *)entry;
-(void)clear;

@end
