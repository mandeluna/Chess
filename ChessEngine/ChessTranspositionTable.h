//
//  ChessTranspositionTable.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-28.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChessBoard;
@class ChessTTEntry;

@interface ChessTranspositionTable : NSObject {

    NSMutableArray *array;
    NSMutableArray *used;
    int collisions;
}

// initialize

-(void)clear;
-(id)initWithBits:(int)nBits;
-(void)storeBoard:(ChessBoard *)aBoard value:(int)value type:(int)valueType depth:(int)depth stamp:(int)timeStamp;

// lookup

-(ChessTTEntry *)lookupBoard:(ChessBoard *)aBoard;

@end
