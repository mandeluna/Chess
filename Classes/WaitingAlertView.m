//
//  WaitingAlertView.m
//  ChessMail
//
//  Created by Steve Wart on 10-10-17.
//  Copyright 2010 Steven Wart. All rights reserved.
//

#import "WaitingAlertView.h"


@implementation WaitingAlertView


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        activityIndicator = [[UIActivityIndicatorView alloc]
                                                      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self addSubview:activityIndicator];
        [activityIndicator startAnimating];
        [activityIndicator release];                                           
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)layoutSubviews {
    int aw = self.bounds.size.width;
    int ah = self.bounds.size.height;
    int iw = activityIndicator.bounds.size.width;
    int ih = activityIndicator.bounds.size.height;
    [activityIndicator setFrame:CGRectMake((aw - iw)/2, ah - ih - 35.0, iw, ih)];    
}

- (void)dealloc {
    activityIndicator = nil;
    [super dealloc];
}


@end
