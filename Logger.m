//
//  Logger.m
//  Chess
//
//  Created by Steve Wart on 2025-08-01.
//

#import <Foundation/Foundation.h>
#import "Logger.h"

#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>

// NSDate only offers millisecond precision
void get_microsecond_timestamp(char *buffer, size_t buffer_size) {
    struct timeval tv;
    struct tm tm_info;
    time_t seconds;
    char microsec_part[7];
    
    gettimeofday(&tv, NULL);
    seconds = tv.tv_sec;
    
    localtime_r(&seconds, &tm_info);  // Thread-safe version
    
    snprintf(microsec_part, sizeof(microsec_part), ".%06d", (int)tv.tv_usec);
    snprintf(buffer, buffer_size,
             "%04d-%02d-%02d %02d:%02d:%02d%s",
             tm_info.tm_year + 1900,
             tm_info.tm_mon + 1,
             tm_info.tm_mday,
             tm_info.tm_hour,
             tm_info.tm_min,
             tm_info.tm_sec,
             microsec_part);
}

NSString *debug_path = @"/tmp/engine_debug.log";
id lock = @[];


@implementation Logger {
    NSDateFormatter *formatter;
    struct timeval time;
}

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

- (instancetype)init {
    if (self = [super init]) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd:MM:yy HH:mm:ss"];
    }
    return self;
}

- (void) logMessage:(NSString *)message {
    char timestamp[32];

    if (level == None) {
        return;
    }

    @synchronized (lock) {
        NSError *error;

        NSFileManager *filemanager = [NSFileManager defaultManager];
        if (![filemanager fileExistsAtPath: debug_path]) {
            [filemanager createFileAtPath: debug_path contents:nil attributes:nil];
        }
        
        // append string to log file
        NSFileHandle *log = [NSFileHandle fileHandleForWritingAtPath: debug_path];
        [log seekToEndOfFile];

        get_microsecond_timestamp(timestamp, sizeof(timestamp));

        NSString *report = [NSString stringWithFormat:@"%s %@\n", timestamp, message];
        [log writeData: [report dataUsingEncoding:NSUTF8StringEncoding]];

        if (![log synchronizeAndReturnError:&error]) {
            NSLog(@"%@", error);
            return;
        }
    }
}

- (void) logDebug:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logMessage:formattedString];
}

- (void) raiseExceptionName: (NSString *)name reason: (NSString *)reason {
    NSArray *callStack = [NSThread callStackSymbols];
    [self logDebug:@"%@: %@", name, callStack];
    NSLog(@"%@: %@", name, callStack);

    NSException *exception = [NSException exceptionWithName:name
                                                     reason:reason userInfo:nil];
    [exception raise];
}

@end
