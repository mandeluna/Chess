//
//  NSArray+quickSort.h
//  Chess
//
//  Created by Steve Wart on 2025-07-23.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Sorting)

-(void)sortSubArrayFrom:(int)i to:(int)j using:(NSComparator)sorter;

@end
