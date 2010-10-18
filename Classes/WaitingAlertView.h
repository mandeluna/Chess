//
//  WaitingAlertView.h
//  ChessMail
//
//  Created by Steve Wart on 10-10-17.
//  Copyright 2010 Steven Wart. All rights reserved.
//
//  Display an alert view with an activity indicator
//

#import <UIKit/UIKit.h>


@interface WaitingAlertView : UIAlertView {
    UIActivityIndicatorView *activityIndicator;
}

@end
