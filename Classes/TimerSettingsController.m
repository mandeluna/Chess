//
//  TimerSettingsController.m
//  Chess
//
//  Created by Steve Wart on 2013-07-11.
//
//

#import "TimerSettingsController.h"
#import "TimerModel.h"
#import "TimerDetailController.h"

@interface TimerSettingsController ()

@end

@implementation TimerSettingsController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [timerToggleSwitch setOn:(_selectedTimer != nil)];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (!timerToggleSwitch.on) {
        return 1;
    }
    else {
        return [super numberOfSectionsInTableView:tableView];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [super tableView:tableView numberOfRowsInSection:section];
}

-(IBAction)toggleTimer:(id)sender {
    if (_selectedTimer) {
        _selectedTimer = nil;
    }
    [self.tableView reloadData];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"TimerTypeDisclosure"]) {
        TimerDetailController *detailController = (TimerDetailController *)segue.destinationViewController;
        detailController.model = _selectedTimer;
    }
}

- (void)tableView:tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    _selectedTimer = [[TimerModel availableModels] objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"TimerTypeDisclosure" sender:self];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 1) {
        TimerModel *timer = [[TimerModel availableModels] objectAtIndex:indexPath.row];
        if (timer == _selectedTimer) {
            cell.imageView.image = [UIImage imageNamed:@"checkmark20x14.png"];
        }
        else {
            cell.imageView.image = nil;
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        _selectedTimer = [[TimerModel availableModels] objectAtIndex:indexPath.row];
        [self.tableView reloadData];
    }
}

@end
