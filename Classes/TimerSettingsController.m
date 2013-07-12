//
//  TimerSettingsController.m
//  Chess
//
//  Created by Steve Wart on 2013-07-11.
//
//

#import "TimerSettingsController.h"
#import "TimerModel.h"

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
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section
    if (_selectedTimer == nil) {
        return 1;
    }
    else {
        return [[TimerModel availableModels] count] + 2;
    }
}

-(IBAction)toggleTimer:(id)sender {
    if (_selectedTimer) {
        _selectedTimer = nil;
    }
    else {
        _selectedTimer = [[TimerModel availableModels] objectAtIndex:0];
    }
    [self.tableView reloadData];
}

- (void)configureTimerToggleCell:(UITableViewCell *)cell {
    // XXX it would be nice to configure these as prototype cells, but we need dynamic entries
    // alternatively create a custom UITableView subclass and load from a nib
    UISwitch *timerSwitch = nil;
    for (UIView *subview in [cell contentView].subviews) {
        if ([subview isKindOfClass:[UISwitch class]]) {
            timerSwitch = (UISwitch *)subview;
        }
    }
    if (timerSwitch == nil) {
        NSLog(@"Unable to locate toggle switch in prototype cell");
        abort();
    }
    [timerSwitch setOn:(_selectedTimer != nil)];
}

- (void)configureCustomizeCell:(UITableViewCell *)cell {
}

- (void)configureModelEntryCell:(UITableViewCell *)cell forRow:(int)row {
    // XXX it would be nice to configure these as prototype cells, but we need dynamic entries
    // alternatively create a custom UITableView subclass and load from a nib
    UILabel *shortLabel = nil;
    UITextView *longDescriptionTextView = nil;
    for (UIView *subview in [cell contentView].subviews) {
        NSLog(@"subview: %@", subview);
        if ([subview isKindOfClass:[UILabel class]]) {
            shortLabel = (UILabel *)subview;
        }
        if ([subview isKindOfClass:[UITextView class]]) {
            longDescriptionTextView = (UITextView *)subview;
        }
    }
    if (shortLabel == nil) {
        NSLog(@"Unable to locate short label in prototype cell");
        abort();
    }
    if (longDescriptionTextView == nil) {
        NSLog(@"Unable to locate description text view in prototype cell");
        abort();
    }
    
    TimerModel *model = [[TimerModel availableModels] objectAtIndex:row - 1];
    shortLabel.text = model.typeString;
    longDescriptionTextView.text = model.longDescription;
    
    if (model == _selectedTimer) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *tableCellIdentifier;
    
    if ([indexPath row] == 0) {
        tableCellIdentifier = @"TimerToggle";
    }
    else if ([indexPath row] == [[TimerModel availableModels] count] + 1) {
        tableCellIdentifier = @"Customize";
    }
    else {
        tableCellIdentifier = @"ModelEntry";
    }
    
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier] autorelease];
	}
    
    if ([indexPath row] == 0) {
        [self configureTimerToggleCell:cell];
    }
    else if ([indexPath row] == [[TimerModel availableModels] count] + 1) {
        [self configureCustomizeCell:cell];
    }
    else {
        [self configureModelEntryCell:cell forRow:[indexPath row]];
    }
	
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

@end
