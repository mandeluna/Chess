//
//  ChessMailAppDelegate_iphone.m
//  ChessMail
//
//  Created by Steve Wart on 10-10-06.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "ChessMailAppDelegate_iphone.h"
#import "ChessMailViewController.h"


@implementation ChessMailAppDelegate_iphone

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    BOOL result = [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    viewController.usePopoverController = NO;
    
    return result;
}

@end
