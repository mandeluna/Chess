//
//  TimerModel.m
//  Chess
//
//  Created by Steve Wart on 2013-07-11.
//
//

#import "TimerModel.h"

static NSArray *timerTypes;
static NSArray *availableModels;

@implementation TimerModel {
	NSString *_shortDescription;
}

#pragma mark Class Methods

+ (NSArray *)availableModels {
    return availableModels;
}

// Return a traditional 40/2, 20/1 timer: 40 moves within 2 hours, 20 moves in each subsequent hour
+ (TimerModel *)traditional4020 {
    return [[TimerModel alloc] initWithType:kTimerTypeTraditional fromString:@"40/2, 20/1"];
}
 
// Return a sudden death G/30 timer: each player has 30 minutes to complete the game
+ (TimerModel *)suddenDeathG30 {
    return [[TimerModel alloc] initWithType:kTimerTypeSuddenDeath fromString:@"G/30"];
}

// Return a mixed 40/2, G/1 timer: 2 hours for first 40 moves, then sudden death in 1 hour
+ (TimerModel *)mixed402G1 {
    return [[TimerModel alloc] initWithType:kTimerTypeMixed fromString:@"40/2, G/1"];
}

// Return a handicap B/30/W/10 timer: white has 10 minutes to complete all moves, black has 30
+ (TimerModel *)handicapB10W30 {
    return [[TimerModel alloc] initWithType:kTimerTypeHandicap fromString:@"B/30/W/10"];
}

// return a rapid transit T/30 timer: each player has a maximum of 30 seconds per move
+ (TimerModel *)rapidTransit30 {
    return [[TimerModel alloc] initWithType:kTimerTypeRapidTransit fromString:@"T/30"];
}

// return a 40/20 Fischer timer: 40 minutes sudden death with 20 seconds added per move
+ (TimerModel *)fischer4020 {
    return [[TimerModel alloc] initWithType:kTimerTypeFischer fromString:@"40/20"];
}

+ (void)initializeAvailableModels {
    availableModels = @[
        [TimerModel traditional4020],
        [TimerModel suddenDeathG30],
        [TimerModel mixed402G1],
        [TimerModel handicapB10W30],
        [TimerModel rapidTransit30],
        [TimerModel fischer4020]
    ];
    [availableModels retain];
}

+ (void)initializeTimerTypes {
    timerTypes = @[
        @"Traditional",
        @"Sudden death",
        @"Mixed",
        @"Handicap",
        @"Rapid transit",
        @"Fischer"    
    ];
    [timerTypes retain];
}

+ (void)initialize {
    [self initializeTimerTypes];
    [self initializeAvailableModels];
}

- (id)initWithType:(TimerType)timerType fromString:(NSString *)descriptionString {
    if (self = [super init]) {
        self.timerType = timerType;
        [self parseDescription:descriptionString];
        _shortDescription = [descriptionString copy];
    }
    return self;
}

- (void)dealloc {
    [_shortDescription release];
    [super dealloc];
}

#pragma mark description methods

- (void)parseDescription:(NSString *)descriptionString {
    NSScanner *scanner = [[NSScanner alloc] initWithString:descriptionString];
    NSCharacterSet *skipChars = [NSCharacterSet characterSetWithCharactersInString:@",/ "];
    NSCharacterSet *labelChars = [NSCharacterSet characterSetWithCharactersInString:@"GTBW"];
    NSString *parsedChar = @" ";
    int intValue;
    
    if ((_timerType == kTimerTypeRapidTransit) ||
        (_timerType == kTimerTypeSuddenDeath)) {
        [scanner scanCharactersFromSet:labelChars intoString:&parsedChar];
        if ([parsedChar isEqualToString:@"G"]) {
            _primaryMoveLimit = -1;
        }
    }
    else {
        [scanner scanInt:&_primaryMoveLimit];
    }
                                                  
    [scanner scanCharactersFromSet:skipChars intoString:NULL];
    [scanner scanInt:&intValue];
    if (intValue < 10) {
        intValue *= 60;
    }
    _primaryTimeLimit = intValue;
    
    // Rapid transit and sudden death do now have secondary values
    if ((_timerType == kTimerTypeRapidTransit) ||
        (_timerType == kTimerTypeSuddenDeath)) {
        return;
    }
    
    [scanner scanCharactersFromSet:skipChars intoString:NULL];

    if ((_timerType == kTimerTypeRapidTransit) ||
        (_timerType == kTimerTypeSuddenDeath) ||
        (_timerType == kTimerTypeMixed)) {
        [scanner scanCharactersFromSet:labelChars intoString:&parsedChar];
        if ([parsedChar isEqualToString:@"G"]) {
            _secondaryMoveLimit = -1;
        }
    }
    else {
        [scanner scanInt:&_secondaryMoveLimit];
    }
    
    [scanner scanCharactersFromSet:skipChars intoString:NULL];
    [scanner scanCharactersFromSet:skipChars intoString:NULL];
    [scanner scanInt:&intValue];
    if (intValue < 10) {
        intValue *= 60;
    }
    _secondaryTimeLimit = intValue;
}

// TODO generate different descriptions based on timer type
- (NSString *)longDescription {
    return [NSString stringWithFormat:@"%@ timer: %d/%d, %d/%d",
            self.typeString, _primaryMoveLimit, _primaryTimeLimit, _secondaryMoveLimit, _secondaryTimeLimit];
}

- (NSString *)shortDescription {
	return _shortDescription;
}

- (NSString *)typeString {
	return [timerTypes objectAtIndex:_timerType];
}

@end
