//
<<<<<<< HEAD
//  NSNotificationCenter.h
=======
//  NSNotificationCenter+MainThread.h
>>>>>>> c2bb170 (Resolved issues with UI updates from background thread)
//  Chess
//
//  Created by Steve Wart on 2025-07-06.
//


@interface NSNotificationCenter (MainThread)
 
- (void)postNotificationOnMainThread:(NSNotification *)notification;
- (void)postNotificationOnMainThreadName:(NSString *)aName object:(id)anObject;
- (void)postNotificationOnMainThreadName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;
 
<<<<<<< HEAD
@end
=======
@end
>>>>>>> c2bb170 (Resolved issues with UI updates from background thread)
