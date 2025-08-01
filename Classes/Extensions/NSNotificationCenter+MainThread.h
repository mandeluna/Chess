//
//  NSNotificationCenter+MainThread.h
//  Chess
//
//  Created by Steve Wart on 2025-07-06.
//
#import <Foundation/Foundation.h>

@interface NSNotificationCenter (MainThread)
 
- (void)postNotificationOnMainThread:(NSNotification *)notification;
- (void)postNotificationOnMainThreadName:(NSString *)aName;
- (void)postNotificationOnMainThreadName:(NSString *)aName object:(id)anObject;
- (void)postNotificationOnMainThreadName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;
 
@end
