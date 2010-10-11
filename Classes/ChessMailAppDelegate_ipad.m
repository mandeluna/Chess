//
//  ChessMailAppDelegate_ipad.m
//  ChessMail
//
//  Created by Steve Wart on 10-10-06.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "ChessMailAppDelegate_ipad.h"
#import "ChessMailViewController.h"

@implementation ChessMailAppDelegate_ipad

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    BOOL result = [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    viewController.usePopoverController = YES;
    
    return result;
}

@end
