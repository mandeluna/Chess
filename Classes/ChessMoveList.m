//
//  ChessMoveList.m
//  ChessMail
//
//  Created by Steve Wart on 10-08-22.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "ChessMoveList.h"
#import "ChessMove.h"
#import "ChessHistoryTable.h"

@implementation ChessMoveList


#pragma mark accessing

//
// Stream>>contents returns a copy of the contents; renamed here to correspond to cocoa memory usage hints
//
-(NSArray *)copyContents {
    
    NSRange range;
    
    if (startIndex > readLimit) {
        NSException *exception = [NSException exceptionWithName:@"InvalidMoveList"
                                                         reason:@"ChessMoveList is invalid"
                                                       userInfo:nil];
        [exception raise];
    }
    
    // collection copyFrom:startIndex to:readLimit
    range.location = startIndex;
    range.length = readLimit - startIndex + 1;
    
    NSArray *contentsCopy = [collection subarrayWithRange:range];
    return [contentsCopy retain];
}

-(NSMutableArray *)originalContents {
    
    return collection;
}

-(int)startIndex {
    return startIndex;
}

-(void)on:(NSMutableArray *)anArray from:(int)firstIndex to:(int)lastIndex {

    // TODO: this is spinning
//    NSLog(@" - creating moveList firstIndex = %d, lastIndex = %d", firstIndex, lastIndex);

    int len;
    
    if (startIndex < 0) {
        NSException *exception = [NSException exceptionWithName:@"Illegal index"
                                                         reason:@"stream index cannot be negative"
                                                       userInfo:nil];
        [exception raise];
    }
    
    startIndex = firstIndex;
    collection = [anArray retain];
    readLimit = (lastIndex > (len = [collection count])) ? len : lastIndex;
    position = (firstIndex <= 1) ? 0 : firstIndex - 1;
}

-(void)dealloc {
    [collection release];
    [super dealloc];
}

#pragma mark stream protocol

-(BOOL)atEnd {
    return (position >= readLimit);
}

-(int)count {
    return readLimit+1;
}

//
// Answer whether the receiver's contents has no elements
//
-(BOOL)isEmpty {
  
    // returns true if both the set of past and future sequence values
    // of the receiver are empty. Otherwise returns false
    
    return ([self atEnd] && (-1 == position));
    
}

-(ChessMove *)next {
    if (position >= readLimit)
        return nil;
    
    return [collection objectAtIndex:position++];
}

#pragma mark sorting

//
// Sort elements i through j of the collection to be nondescending
// according to sorter
//
// can't really use an NSComparator because we may be sharing the 
// contents with other move lists. So we sort in-place.
//
// TODO: there may be a more optimal approach. The Squeak version of
// this code appears to have been ported from something that was
// originally written in C
//
-(void)sort:(int)i to:(int)j using:(ChessHistoryTable *)sorter {
    
    ChessMove *di, *dj, *dij, *tt, *dk, *dl;
    int n;
    
    // the prefix d means that data at that index
    if ((n = j + 1 - i) <= 1)
        return;
    
    // sort di, dj
    di = [collection objectAtIndex:i];
    dj = [collection objectAtIndex:j];
    
    if (![sorter sorts:di before:dj]) {
        // swap in collection and in our copy of the elements
        [di retain];
        [dj retain];
        [collection replaceObjectAtIndex:i withObject:dj];
        [collection replaceObjectAtIndex:j withObject:di];
        [di release];
        [dj release];
        tt = di; di = dj; dj = tt;
    }

    if (n > 2) {     // more than 2 elements
        int ij = (i + j) / 2;   // ij is the midpoint of i and j
        dij = [collection objectAtIndex:ij];  // sort di, dij, dj. Make dij be their median
        if ([sorter sorts:di before:dij]) {     // i.e. should di precede dij?
            if (![sorter sorts:dij before:dj]) {    // i.e. should dij preced dj?
                [dij retain]; // keep removed objects from being deallocated
                [dj retain];
                [collection replaceObjectAtIndex:ij withObject:dj];
                [collection replaceObjectAtIndex:j withObject:dij];
                [dij release];
                [dj release];
                dij = dj;
            }
        } else {    // i.e. di should come after dij
            [dij retain];
            [di retain];
            [collection replaceObjectAtIndex:ij withObject:di];
            [collection replaceObjectAtIndex:i withObject:dij];
            [dij release];
            [di release];
            dij = di;
        }
    }

    if (n > 3) {    // more than 3 elements
        // find k>i and l<j such that dk, dij, dl are in reverse order
        // swap k and l. Repeat this procedure until k and l pass each other
        int k = i, l = j;
        
        do {
            // decrement l while dl succeeds dij
            do {
                l--;
                dl = [collection objectAtIndex:l];
            }
            while((k <= l) && [sorter sorts:dij before:dl]);
            // increment k while dij succeeds dk
            do {
                k++;
                dk = [collection objectAtIndex:k];
            }
            while((k <= l) && [sorter sorts:dk before:dij]);
            
            if (k <= l) {
                [dl retain];
                [dk retain];
                [collection replaceObjectAtIndex:l withObject:dk];
                [collection replaceObjectAtIndex:k withObject:dl];
                [dl release];
                [dk release];
            }
        }
        while (k <= l);
        
        // now l<k (either 1 or 2 less), and di through dl ar all less than
        // or equal to dk through dj. Sort those two segments
        [self sort:i to:l using:sorter];
        [self sort:k to:j using:sorter];
    }
}

-(void)sortUsing:(ChessHistoryTable *)sorter {
    
    [self sort:startIndex to:readLimit using:sorter];
}

@end
