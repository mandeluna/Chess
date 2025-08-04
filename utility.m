//
//  utility.m
//  Chess
//
//  Created by Steve Wart on 2025-08-01.
//

#import <Foundation/Foundation.h>

NSString *debug_path = @"/tmp/engine_debug.log";
id lock = @[];

void logDebug(NSString *str) {
    @synchronized (lock) {
        NSError *error;
        NSFileManager *filemanager = [NSFileManager defaultManager];
        if (![filemanager fileExistsAtPath: debug_path]) {
            [filemanager createFileAtPath: debug_path contents:nil attributes:nil];
        }

        // append string to log file
        NSFileHandle *log = [NSFileHandle fileHandleForWritingAtPath: debug_path];
        [log seekToEndOfFile];

        NSString *report = [NSString stringWithFormat:@"%@\n", str];
        [log writeData: [report dataUsingEncoding:NSUTF8StringEncoding]];

        if (![log synchronizeAndReturnError:&error]) {
            NSLog(@"%@", error);
            return;
        }
    }
}

void raiseException(NSString *name, NSString *reason) {
    NSArray *callStack = [NSThread callStackSymbols];
//    NSString *report = [NSString stringWithFormat:@"%@: %@", name, callStack];
//    logDebug(report);

    NSLog(@"%@: %@", name, callStack);

    NSException *exception = [NSException exceptionWithName:name
                                                     reason:reason userInfo:nil];
    [exception raise];
}

