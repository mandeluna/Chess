//
//  TimerDetailController.h
//  Chess
//
//  Created by Steve Wart on 2013-07-12.
//
//

#import <UIKit/UIKit.h>

@class TimerModel;

@interface TimerDetailController : UITableViewController {
	
	IBOutlet UILabel *typeLabel;
	IBOutlet UILabel *shortDescriptionLabel;
	IBOutlet UITextView *longDescriptionTextView;
	IBOutlet UITextField *primaryValueField;
	IBOutlet UIStepper *primaryValueStepper;
	IBOutlet UITextField * primaryTimeField;
	IBOutlet UIStepper *primaryTimeStepper;
	IBOutlet UITextField *secondaryValueField;
	IBOutlet UIStepper *secondaryValueStepper;
	IBOutlet UITextField *secondaryTimeField;
	IBOutlet UIStepper *secondaryTimeStepper;
	
}

@property(nonatomic, retain) TimerModel *model;

@end
