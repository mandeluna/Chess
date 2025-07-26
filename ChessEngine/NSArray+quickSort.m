//
//  NSArray+quickSort.m
//  Chess
//
//  Created by Steve Wart on 2025-07-23.
//

#import "NSArray+quickSort.h"

@implementation NSMutableArray (Sorting)

- (void)swapIndex:(NSInteger)i withIndex:(NSInteger)j {
    if (i == j) return;
    id temp = self[i];
#if !__has_feature(objc_arc)
    [temp retain];
#endif
    self[i] = self[j];
    self[j] = temp;
#if !__has_feature(objc_arc)
    [temp release];
#endif
}

- (NSInteger)medianOfThreeWithLow:(NSInteger)low high:(NSInteger)high comparator:(NSComparisonResult (^)(id obj1, id obj2))comparator {
    NSInteger mid = low + (high - low) / 2;
    
    if (comparator(self[low], self[mid]) == NSOrderedDescending) {
        [self swapIndex:low withIndex:mid];
    }
    if (comparator(self[low], self[high]) == NSOrderedDescending) {
        [self swapIndex:low withIndex:high];
    }
    if (comparator(self[mid], self[high]) == NSOrderedDescending) {
        [self swapIndex:mid withIndex:high];
    }
    
    return mid;
}

- (NSInteger)partitionWithLow:(NSInteger)low high:(NSInteger)high comparator:(NSComparisonResult (^)(id obj1, id obj2))comparator {
    NSInteger pivotIndex = [self medianOfThreeWithLow:low high:high comparator:comparator];
    id pivotValue = self[pivotIndex];
    
    [self swapIndex:pivotIndex withIndex:high];
    
    NSInteger i = low;
    for (NSInteger j = low; j < high; j++) {
        if (comparator(self[j], pivotValue) != NSOrderedDescending) {
            [self swapIndex:i withIndex:j];
            i++;
        }
    }
    
    [self swapIndex:i withIndex:high];
    return i;
}

- (void)quickSortWithLowIndex:(NSInteger)low highIndex:(NSInteger)high comparator:(NSComparisonResult (^)(id obj1, id obj2))comparator {
    if (low < high) {
        NSInteger pivot = [self partitionWithLow:low high:high comparator:comparator];
        [self quickSortWithLowIndex:low highIndex:pivot - 1 comparator:comparator];
        [self quickSortWithLowIndex:pivot + 1 highIndex:high comparator:comparator];
    }
}

//
// Sort elements i through j of the self to be nondescending
// according to sorter
//
-(void)sortSubArrayFrom:(int)i to:(int)j using:(NSComparator)comparator {
  [self quickSortWithLowIndex:i highIndex:j comparator:comparator];
}

@end
