//
//  TimerModel.h
//  Chess
//
//  Created by Steve Wart on 2013-07-11.
//
//

#import <Foundation/Foundation.h>

typedef enum TimerType {
    kTimerTypeTraditional,      // e.g. 40/2, 20/1 means 40 moves within 2 hours, 20 moves in each subsequent hour
    kTimerTypeSuddenDeath,      // e.g. G/30 means each player has 30 minutes to complete the game
    kTimerTypeMixed,            // e.g. 40/2, G/1 means 2 hours for first 40 moves, then sudden death in 1 hour
    kTimerTypeHandicap,         // e.g. B/30/W/10 means white has 10 minutes to complete all moves, black has 30
    kTimerTypeRapidTransit,     // e.g. T/30 means each player has a maximum of 30 seconds per move
    kTimerTypeFischer           // e.g. 40/20 Fischer increment means 40 minutes sudden death with 20 seconds added per move
} TimerType;

@interface TimerModel : NSObject

@property(nonatomic, assign) int primaryMoveLimit;      // -1 if sudden death, or moves to complete within primary time limit
@property(nonatomic, assign) int primaryTimeLimit;      // 1-9 means hours, 10-60 means minutes, other values not valid
@property(nonatomic, assign) int secondaryMoveLimit;    // -1 if sudden death, or moves for secondary time limit
@property(nonatomic, assign) int secondaryTimeLimit;    // same as primary time limit
@property(nonatomic, assign) TimerType timerType;
@property(nonatomic, retain) NSString *typeString;

+ (NSArray *)availableModels;
+ (void)initialize;

- (NSString *)longDescription;
- (id)initWithType:(TimerType)timerType fromString:(NSString *)typeString;

@end
