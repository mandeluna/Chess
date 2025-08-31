//
//  Logger.h
//  Chess
//
//  Created by Steve Wart on 2025-08-01.
//

#import <Foundation/Foundation.h>

enum LogLevel {
    None,
    Info,
    Debug,
    Error,
    Verbose
};

@interface Logger : NSObject {
    enum LogLevel level;
    NSString *sessionId;
}

@property (nonatomic, assign) enum LogLevel level;
@property (nonatomic, readonly) NSString *sessionId;

// The shared instance accessor
+ (instancetype)defaultLogger;

// Prevent instantiation
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)copy NS_UNAVAILABLE;
- (instancetype)mutableCopy NS_UNAVAILABLE;

- (void) logMessage:(NSString *)message;
- (void) log:(NSString *)message level:(enum LogLevel) level;
- (void) logDebug:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);
- (void) logInfo:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);
- (void) logError:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);
- (void) logVerbose:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);
- (void) logException: (NSException *)exception;

- (void) raiseExceptionName: (NSString *)name reason: (NSString *)reason;
- (NSString *) timestamp;

@end
