//
//  Logger.m
//  Chess
//
//  Created by Steve Wart on 2025-08-01.
//

#import <Foundation/Foundation.h>
#import "Logger.h"

NSString *debug_path = @"/tmp/engine_debug.log";
id lock = @[];

#include <stdio.h>
#include <math.h>

#include <stdio.h>
#include <math.h>

#include <stdio.h>
#include <math.h>
#include <string.h>

void format_duration(double seconds, char* buffer, size_t buffer_size) {
    // Handle negative values
    int is_negative = 0;
    if (seconds < 0) {
        is_negative = 1;
        seconds = -seconds;
    }

    // Calculate hours, minutes, and remaining seconds
    int total_seconds = (int)seconds;
    int hours = total_seconds / 3600;
    int remaining_seconds = total_seconds % 3600;
    int minutes = remaining_seconds / 60;
    int secs = remaining_seconds % 60;
    
    // Get the fractional part (microseconds)
    double fractional_seconds = seconds - total_seconds;
    int microseconds = (int)round(fractional_seconds * 1e6);
    
    // Format the string
    if (is_negative) {
        if (microseconds > 0) {
            snprintf(buffer, buffer_size, "-%02d:%02d:%02d.%06d",
                    hours, minutes, secs, microseconds);
        } else {
            snprintf(buffer, buffer_size, "-%02d:%02d:%02d",
                    hours, minutes, secs);
        }
    } else {
        if (microseconds > 0) {
            snprintf(buffer, buffer_size, "%02d:%02d:%02d.%06d",
                    hours, minutes, secs, microseconds);
        } else {
            snprintf(buffer, buffer_size, "%02d:%02d:%02d",
                    hours, minutes, secs);
        }
    }
    
    // Ensure null-termination (snprintf should do this, but it's good practice)
    buffer[buffer_size - 1] = '\0';
}

@implementation Logger

@synthesize level;

+ (instancetype)defaultLogger {
    static Logger *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
    });
    return sharedInstance;
}

// Override allocWithZone to prevent allocations
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self defaultLogger];
}

NSTimeInterval start_seconds;

- (instancetype)init {
    if (self = [super init]) {
        start_seconds = [[NSDate now] timeIntervalSince1970];
    }
    return self;
}

- (void)logMessage:(NSString *)message {
    NSLog(@"%@", message);
}


- (void) logDebug: (NSString *)str {
    if (level == None) {
        return;
    }
    @synchronized (lock) {
        char buffer[32];
        NSError *error;
        NSFileManager *filemanager = [NSFileManager defaultManager];
        if (![filemanager fileExistsAtPath: debug_path]) {
            [filemanager createFileAtPath: debug_path contents:nil attributes:nil];
        }
        
        // append string to log file
        NSFileHandle *log = [NSFileHandle fileHandleForWritingAtPath: debug_path];
        [log seekToEndOfFile];

        NSTimeInterval interval = ([[NSDate now] timeIntervalSince1970]) - start_seconds;
        format_duration(interval, buffer, sizeof(buffer));
        NSString *report = [NSString stringWithFormat:@"%s %@\n", buffer, str];
        [log writeData: [report dataUsingEncoding:NSUTF8StringEncoding]];
        NSLog(@"%@", str);

        if (![log synchronizeAndReturnError:&error]) {
            NSLog(@"%@", error);
            return;
        }
    }
}

- (void) raiseExceptionName: (NSString *)name reason: (NSString *)reason {
    NSArray *callStack = [NSThread callStackSymbols];
    NSString *report = [NSString stringWithFormat:@"%@: %@", name, callStack];
    [self logDebug:report];

    NSLog(@"%@: %@", name, callStack);

    NSException *exception = [NSException exceptionWithName:name
                                                     reason:reason userInfo:nil];
    [exception raise];
}

@end
