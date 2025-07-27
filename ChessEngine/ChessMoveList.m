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
#import "NSArray+quickSort.h"

@implementation ChessMoveList


#pragma mark accessing

//
// Stream>>contents returns a copy of the contents; renamed here to correspond to cocoa memory usage hints
//
-(NSArray *)copyContents {
    NSArray *contentsCopy = [collection subarrayWithRange:NSMakeRange(startIndex, readLimit + 1)];

#if !__has_feature(objc_arc)
  return [contentsCopy retain];
#else
  return contentsCopy;
#endif
}

-(int)startIndex {
    return startIndex;
}

-(void)on:(NSMutableArray *)anArray from:(int)firstIndex to:(int)lastIndex {

  int len;
#if !__has_feature(objc_arc)
  collection = [anArray retain];
#else
  collection = anArray;
#endif
  startIndex = firstIndex;
  readLimit = (lastIndex > (len = (int)[collection count])) ? len - 1 : lastIndex - 1;
  position = firstIndex;
}

#pragma mark stream protocol

-(BOOL)atEnd {
    return (position > readLimit);
}

-(int)count {
    return readLimit + 1;
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

-(void)sortUsing:(ChessHistoryTable *)sorter {

  [collection sortSubArrayFrom:startIndex to:readLimit using:^NSComparisonResult(ChessMove *a, ChessMove *b) {
    return [sorter sorts:a before:b];
  }];
}

#pragma mark printing

// show first two moves and last move in the collection and next moves string
-(NSString *)descriptionOfSubArrayFrom:(int)start to:(int)end {
  NSString *result = @"[";
  
  for (int i = start; (i < end) && (i < start + 2); i++) {
    ChessMove *next = [collection objectAtIndex:i];
    result = [result stringByAppendingFormat:@"%@", next];
    if ((i < end - 1) && (i < start + 1)) {
      result = [result stringByAppendingString:@" "];
    }
  }
  
  result = [result stringByAppendingString:@"..."];
  result = [result stringByAppendingFormat:@"%@", [collection objectAtIndex: end]];
  result = [result stringByAppendingFormat:@"] (%d items)", end - start + 1];

  return result;
}

-(NSString *)description {
  NSString *result = @"";
  NSString *abbreviatedCollectionString = [self descriptionOfSubArrayFrom:0 to:readLimit];
  NSString *nextMovesString = [self descriptionOfSubArrayFrom:startIndex to:readLimit];
  
  result = [NSString stringWithFormat:@"position: %d (next: %@)", position, [collection objectAtIndex:position]];
  result = [result stringByAppendingFormat:@"\nreadLimit: %d", readLimit];
  result = [result stringByAppendingFormat:@"\nstartIndex: %d", startIndex];
  result = [result stringByAppendingFormat:@"\nnext moves: %@", nextMovesString];
  result = [result stringByAppendingFormat:@"\ncollection: %@", abbreviatedCollectionString];
  
  return result;
}

@end
