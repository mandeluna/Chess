//
//  ChessMailAppDelegate.h
//  ChessMail
//
//  Created by Steve Wart on 10-08-15.
//  Copyright Steven Wart 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChessMailViewController;

@interface ChessMailAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ChessMailViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ChessMailViewController *viewController;

@end

