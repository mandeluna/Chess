//
//  TimerSettingsController.h
//  Chess
//
//  Created by Steve Wart on 2013-07-11.
//
//

#import <UIKit/UIKit.h>

@class TimerModel;

@interface TimerSettingsController : UITableViewController {
    IBOutlet UISwitch *timerToggleSwitch;
}

@property(nonatomic, retain) TimerModel *selectedTimer;

-(IBAction)toggleTimer:(id)sender;

@end
