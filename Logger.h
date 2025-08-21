//
//  Logger.h
//  Chess
//
//  Created by Steve Wart on 2025-08-01.
//

#import <Foundation/Foundation.h>

enum DebugLevel {
    None,
    Error,
    Verbose
};

@interface Logger : NSObject {
    enum DebugLevel level;
}

@property (nonatomic, assign) enum DebugLevel level;

// The shared instance accessor
+ (instancetype)defaultLogger;

// Prevent instantiation
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)copy NS_UNAVAILABLE;
- (instancetype)mutableCopy NS_UNAVAILABLE;

- (void) logDebug:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);
- (void) logMessage:(NSString *)message;
- (void) raiseExceptionName: (NSString *)name reason: (NSString *)reason;
- (NSString *) timestamp;

@end
