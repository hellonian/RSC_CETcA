//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRGatewayDetailsViewController.h"
#import "CSRGatewayDetailsTableViewCell.h"
#import "CSRGatewayConnectionViewController.h"
#import "CSRAppStateManager.h"
#import "CSRDatabaseManager.h"
#import "CSRmeshStyleKit.h"
#import "CSRConstants.h"
#import "CSRUtilities.h"
#import <CSRmesh/ConfigModelApi.h>
#import "CSRAppStateManager.h"

@interface CSRGatewayDetailsViewController () <UITableViewDataSource, UITableViewDelegate, UIPopoverPresentationControllerDelegate>
{
    NSArray *gatewayDetails;
    UIImage *gatewayStateIconImage;
    NSString *gatewayStateString;
    CSRGatewayConnectionMode connectionMode;
}

@end

@implementation CSRGatewayDetailsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    //Adjust navigation controller appearance
    self.showNavMenuButton = NO;
    self.showNavSearchButton = NO;
    
    [super adjustNavigationControllerAppearance];
    
    //Set navigation buttons
    _backButton = [[UIBarButtonItem alloc] init];
    _backButton.image = [CSRmeshStyleKit imageOfBack_arrow];
    _backButton.action = @selector(back:);
    _backButton.target = self;
    
    [super addCustomBackButtonItem:_backButton];
    
    //Add table delegates
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    
    _titleLabel.text = _gatewayEntity.name;
    
    _gatewayIcon.image = [CSRmeshStyleKit imageOfGateway_on];
    _gatewayIcon.image = [_gatewayIcon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _gatewayIcon.tintColor = [CSRUtilities colorFromHex:kColorTeal500];

    
    [self checkGatewayState];
    
    [self refreshTableDetails:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)refreshTableDetails:(id)sender
{
    
    gatewayDetails = @[@{@"detailName":@"UUID", @"detailValue":_gatewayEntity.uuid},
                       @{@"detailName":@"IP", @"detailValue":_gatewayEntity.host},
                       @{@"detailName":@"Device ID", @"detailValue":[NSString stringWithFormat:@"%@ (0x%04x)", _gatewayEntity.deviceId, [_gatewayEntity.deviceId unsignedShortValue]]}];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [gatewayDetails count];
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
    
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CSRGatewayDetailsTableCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRGatewayDetailsTableCellIdentifier];
    }
    
    ((CSRGatewayDetailsTableViewCell *)cell).detailName.text = ((NSDictionary *)[gatewayDetails objectAtIndex:indexPath.row])[@"detailName"];
    ((CSRGatewayDetailsTableViewCell *)cell).detailValue.text = ((NSDictionary *)[gatewayDetails objectAtIndex:indexPath.row])[@"detailValue"];
    
    return cell;
    
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"connectionPopoverSegue"]) {
        CSRGatewayConnectionViewController *vc = segue.destinationViewController;
        vc.gatewayEntity = _gatewayEntity;
        vc.mode = connectionMode;
        vc.popoverPresentationController.delegate = self;
        vc.popoverPresentationController.presentedViewController.view.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        vc.popoverPresentationController.presentedViewController.view.layer.borderWidth = 0.5;
        
        vc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20., 205.);
    }
}


#pragma mark - Actions

- (IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)deleteButtonTapped:(id)sender
{
    
    if ([[CSRAppStateManager sharedInstance].currentGateway.uuid isEqualToString:_gatewayEntity.uuid]) {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Do you want to remove %@?", _gatewayEntity.name]
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                         }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Yes"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         
                                                         switch ([_gatewayEntity.state intValue]) {
                                                              
                                                             case 0:
                                                             case 1:
                                                             case 2:
                                                             {
                                                                 connectionMode = CSRGatewayConnectionMode_DeleteGateway;
                                                                 [self performSegueWithIdentifier:@"connectionPopoverSegue" sender:self];
                                                                 
                                                             }
                                                                 break;
                                                                 
                                                             case 3:
                                                             {
                                                                 connectionMode = CSRGatewayConnectionMode_DeleteCloud;
                                                                 [self performSegueWithIdentifier:@"connectionPopoverSegue" sender:self];
                                                             }
                                                                 break;
                                                                 
                                                             default:
                                                                 break;
                                                         }
                                                         
                                                     }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
    } else {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"You have to be connected to %@ to delete?\n Please switch to WIFI of a gatway you wish to delete and try again.", _gatewayEntity.name]
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action) {
                                                             }];
        
        
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];

    }
    
}

- (IBAction)enableLocalConnection:(id)sender
{
    connectionMode = CSRGatewayConnectionMode_Local;
    [self performSegueWithIdentifier:@"connectionPopoverSegue" sender:self];
}

- (IBAction)enableCloudConnection:(id)sender
{
    connectionMode = CSRGatewayConnectionMode_Cloud;
    [self performSegueWithIdentifier:@"connectionPopoverSegue" sender:self];
}

#pragma mark - Gateway state

- (void)checkGatewayState
{
    
    switch ((CSRGatewayState)[_gatewayEntity.state intValue]) {
            
        case CSRGateWayState_Associated:
            _stateIconImageView.image = [CSRmeshStyleKit imageOfWarning_state];
            _stateIconImageView.image = [_stateIconImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            _stateIconImageView.tintColor = [UIColor blueColor];
            _stateLabel.text = @"No Local or Cloud connection";
            _enableLocalGatewayButton.hidden = NO;
            _enableLocalGatewayButton.enabled = YES;
            _enableCloudButton.hidden = NO;
            _enableCloudButton.enabled = YES;
            break;
            
        case CSRGateWayState_Local:
            _stateIconImageView.image = [CSRmeshStyleKit imageOfCloud_state_off];
            _stateIconImageView.image = [_stateIconImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            _stateIconImageView.tintColor = [UIColor blueColor];
            _stateLabel.text = @"Local Gateway or Cloud not configured";
            _enableLocalGatewayButton.hidden = YES;
            _enableLocalGatewayButton.enabled = YES;
            _enableCloudButton.hidden = NO;
            _enableCloudButton.enabled = YES;
            break;
            
        case CSRGateWayState_Cloud:
            _stateIconImageView.image = [CSRmeshStyleKit imageOfCloud_state_on];
            _stateIconImageView.image = [_stateIconImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            _stateIconImageView.tintColor = [UIColor blueColor];
            _stateLabel.text = @"Gateway with Cloud enabled";
            _enableLocalGatewayButton.hidden = YES;
            _enableLocalGatewayButton.enabled = NO;
            _enableCloudButton.hidden = YES;
            _enableCloudButton.enabled = NO;
            break;
            
        default:
            break;
    }
    
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // Return no adaptive presentation style, use default presentation behaviour
    return UIModalPresentationNone;
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return NO;
}

@end
