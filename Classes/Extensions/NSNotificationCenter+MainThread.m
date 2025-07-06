//
<<<<<<< HEAD
//  NSNotificationCenter.m
=======
//  NSNotificationCenter+MainThread.m
>>>>>>> c2bb170 (Resolved issues with UI updates from background thread)
//  Chess
//
//  Created by Steve Wart on 2025-07-06.
//


#import "NSNotificationCenter+MainThread.h"
 
@implementation NSNotificationCenter (MainThread)
 
- (void)postNotificationOnMainThread:(NSNotification *)notification
{
	[self performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
}
 
- (void)postNotificationOnMainThreadName:(NSString *)aName object:(id)anObject
{
	NSNotification *notification = [NSNotification notificationWithName:aName object:anObject];
	[self postNotificationOnMainThread:notification];
}
 
- (void)postNotificationOnMainThreadName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo
{
	NSNotification *notification = [NSNotification notificationWithName:aName object:anObject userInfo:aUserInfo];
	[self postNotificationOnMainThread:notification];
}
 
<<<<<<< HEAD
@end
=======
@end
>>>>>>> c2bb170 (Resolved issues with UI updates from background thread)
