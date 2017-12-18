//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRBearerPickerViewController.h"
#import "CSRBearerOptionTableViewCell.h"
#import "CSRAppStateManager.h"
#import "CSRAssociatedGatewaysListViewController.h"

@interface CSRBearerPickerViewController ()
{
    NSArray *bearerOptionsArray;
}

@end

@implementation CSRBearerPickerViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    bearerOptionsArray = [[CSRAppStateManager sharedInstance] getAvaialableBearersList];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.superview.layer.cornerRadius = 0;
    
    //shadow
    self.view.layer.shadowColor = [UIColor grayColor].CGColor;
    self.view.layer.shadowOffset = CGSizeMake(5, 5);
    self.view.layer.shadowOpacity = 1;
    self.view.layer.shadowRadius = 1.0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [bearerOptionsArray count];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.;
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
    
    CSRBearerOptionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CSRBearerOptionCellIdentifier];
    
    if (!cell) {
        cell = [[CSRBearerOptionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRBearerOptionCellIdentifier];
    }
    
    if (bearerOptionsArray && [bearerOptionsArray count] > 0) {
        cell.bearerNameLabel.text = (NSString *)[bearerOptionsArray objectAtIndex:indexPath.row];
    }
    
    return cell;
    
}

//TODO: define action when table cell was touched
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if ([[CSRAppStateManager sharedInstance].selectedPlace.gateways count] == 1) {
    
        [self dismissViewControllerAnimated:YES completion:^(){
//            [[CSRAppStateManager sharedInstance] setCurrentGateway:[[CSRAppStateManager sharedInstance].selectedPlace.gateways anyObject]];
//            [[CSRAppStateManager sharedInstance] setCurrentGateway:_gatewayEntity];
            [_delegate selectedBearerOption:(CSRSelectedBearerType)indexPath.row];
            
        }];
        
//    } else {
//        
//        [self performSegueWithIdentifier:@"selectGatewaySegue" sender:self];
//        
//    }
    return indexPath;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"selectGatewaySegue"]) {
        
        UINavigationController *navController = (UINavigationController*)[segue destinationViewController];
        CSRAssociatedGatewaysListViewController *vc = (CSRAssociatedGatewaysListViewController*)[navController topViewController];
        vc.parentVC = self;
        vc.mode = 1;
    }
}


#pragma mark - <CSRBearerPickerDelegate>

- (id)selectedBearerOption:(id)option
{
    return option;
}

@end
