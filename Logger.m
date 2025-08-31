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

#include <signal.h>
void (*signal(int signum, void (*sighandler)(int)))(int);
void initializeSignalHandlers(void);

// NSDate only offers millisecond precision
void get_microsecond_timestamp(char *buffer, size_t buffer_size) {
    struct timeval tv;
    struct tm tm_info;
    time_t seconds;
    char microsec_part[8];  // 6 digits + 1 decimal + terminator
    
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

void
clean_exit_on_sig(int sig_num)
{
    NSArray *callStack = [NSThread callStackSymbols];
    [[Logger defaultLogger] logError:@"Signal %d received: %@", sig_num, callStack];
    NSLog(@"Signal %d received: %@", sig_num, callStack);
    exit(sig_num);
}

void initializeSignalHandlers(void) {
    signal(SIGABRT , clean_exit_on_sig);
    signal(SIGILL , clean_exit_on_sig);
    signal(SIGFPE , clean_exit_on_sig);
    signal(SIGSEGV, clean_exit_on_sig);
}

id lock = @[];

@implementation Logger {
    NSDateFormatter *formatter;
    struct timeval time;
}

@synthesize level, sessionId;

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
        sessionId = [self initializeSessionId];
        initializeSignalHandlers();
    }
    return self;
}

- (NSString *)base64randomString {
    unsigned long long session;
    arc4random_buf(&session, sizeof(session));
    NSData *data = [NSData dataWithBytes:&session length:sizeof(session)];
    return [data base64EncodedStringWithOptions:0];
}

- (NSString *)initializeSessionId {
    NSCharacterSet *filter = [NSCharacterSet characterSetWithCharactersInString:@"=<>:\"/\\|?*"];
    NSString *base64 = [self base64randomString];
    return [[base64 componentsSeparatedByCharactersInSet:filter] componentsJoinedByString:@""];
}

- (NSString *)debug_path {
    return [NSString stringWithFormat:@"/tmp/engine_debug_%@.log", sessionId];
}

- (NSString *)timestamp {
    char timestamp[32];
    get_microsecond_timestamp(timestamp, sizeof(timestamp));
    return [NSString stringWithFormat:@"%s", timestamp];
}

- (void) logMessage:(NSString *)message {
    char timestamp[32];
    NSString *debug_path = [self debug_path];

    // log level Info or greater
    if (level == None) {
        return;
    }

    @synchronized (lock) {
        NSError *error = nil;

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
            if (error) {
                NSLog(@"Sync failed: %@", error.localizedDescription);
            } else {
                NSLog(@"Sync failed with unknown error initializing log file: %@", debug_path);
            }
            return;
        }

        [log closeFile];
    }
}

- (void) log:(NSString *)message level:(enum LogLevel) level {
    if (self.level < level) {
        return;
    }
    [self logMessage:message];
}

- (void) logInfo:(NSString *)format, ... {
    // log level Info or greater
    if (level < Info) {
        return;
    }
    va_list args;
    va_start(args, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logMessage:formattedString];
}

- (void) logDebug:(NSString *)format, ... {
    // log level Debug or greater
    if (level < Debug) {
        return;
    }
    va_list args;
    va_start(args, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logMessage:formattedString];
}

- (void) logError:(NSString *)format, ... {
    // log level Error or greater
    if (level < Error) {
        return;
    }
    va_list args;
    va_start(args, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logMessage:formattedString];
}

- (void) logVerbose:(NSString *)format, ... {
    // log level Verbose or greater
    if (level < Verbose) {
        return;
    }
    va_list args;
    va_start(args, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logMessage:formattedString];
}

- (void) logException: (NSException *)exception {
    NSArray *callStack = [NSThread callStackSymbols];
    [self logError:@"%@: %@", exception.name, callStack];
    NSLog(@"%@: %@", exception.name, callStack);
}

- (void) raiseExceptionName: (NSString *)name reason: (NSString *)reason {
    NSException *exception = [NSException exceptionWithName:name
                                                     reason:reason userInfo:nil];
    [self logException:exception];
    [exception raise];
}

@end
