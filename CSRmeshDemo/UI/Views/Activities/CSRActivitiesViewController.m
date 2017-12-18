//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRActivitiesViewController.h"
#import "CSRActivitiesTableViewCell.h"
#import "CSRmeshStyleKit.h"
#import <CSRmesh/MeshServiceApi.h>

@interface CSRActivitiesViewController () {

    NSInteger selectedIndex;
}
@end

@implementation CSRActivitiesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _activitiesArray = [NSMutableArray arrayWithObjects:@"Movie Night", @"Leaving home", nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_activitiesArray count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSRActivitiesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CSRActivitiesTableViewCellIdentifier];
    
    if (!cell) {
        cell = [[CSRActivitiesTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRActivitiesTableViewCellIdentifier];
    }
    
    cell.activityNameLabel.text = [_activitiesArray objectAtIndex:indexPath.row];
    cell.activityImageView.image = [CSRmeshStyleKit imageOfLight_on];
    
    //Create accessory view for each cell
    UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 0., 65., 65.)];
    [accessoryButton setBackgroundImage:[CSRmeshStyleKit imageOfAccessoryGear ] forState:UIControlStateNormal];
    [accessoryButton addTarget:self action:(@selector(accessoryButtonTapped:)) forControlEvents:UIControlEventTouchUpInside];
    accessoryButton.tag = indexPath.row;
    
    cell.accessoryView = accessoryButton;
    
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
}

#pragma mark - Accessory type action

- (void)accessoryButtonTapped:(UIButton*)sender
{
    UIButton *accessoryButton = (UIButton *)sender;
    selectedIndex = accessoryButton.tag;
}

- (IBAction)addArea:(id)sender
{
    
}

@end
