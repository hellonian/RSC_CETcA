//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRApplicationSettingsViewController.h"
#import "CSRSwitchableTableViewCell.h"
#import "CSRDetailsTableViewCell.h"
#import "CSRActionTableViewCell.h"
#import "CSRUtilities.h"
#import "CSRConstants.h"
#import "CSRmeshStyleKit.h"
#import "CSRAppStateManager.h"
#import "CSRmeshSettings.h"
#import "CSRBluetoothLE.h"
#import "CSRDevicesManager.h"
#import "CSRAssociatedGatewaysListViewController.h"

@interface CSRApplicationSettingsViewController () <CSRBluetoothLEDelegate>
{
    NSString *bearerOptionName;
    BOOL isCurrentBearerModeAutomatic;
    BOOL isManualSelectionCoverVisible;
}


@property (nonatomic) NSArray *settings;
@property (nonatomic) NSString *segueID;

@end

@implementation CSRApplicationSettingsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set image on back button
    _backButton.backgroundColor = [UIColor clearColor];
    [_backButton setBackgroundImage:[CSRmeshStyleKit imageOfBack_arrow] forState:UIControlStateNormal];
    [_backButton addTarget:self action:(@selector(back:)) forControlEvents:UIControlEventTouchUpInside];
    
    // pass the value to parent/super for inheritance and cover display
    self.isModal = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshView)
                                                 name:kCSRGatewayConnectionStatusChangedNotification
                                               object:nil];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Set current bearer mode
    isManualSelectionCoverVisible = ![CSRAppStateManager sharedInstance].isBearerModeAutomatic;
    
    switch ([CSRAppStateManager sharedInstance].bearerType) {
        case 0:
            bearerOptionName = @"Bluetooth";
            break;
            
        case 1:
            bearerOptionName = @"Gateway";
            break;
            
        case 2:
            bearerOptionName = @"Cloud";
            break;
            
        default:
            break;
    }
    
//    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:YES];

}

- (void) viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    
    [self refreshView];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRGatewayConnectionStatusChangedNotification
                                                  object:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.view = nil;
}

- (void)refreshView
{
    
    if ([[CSRAppStateManager sharedInstance].selectedPlace.gateways count] > 0) {
        
        _settings = @[
                      @{@"name":@"Automatic switch"},
                      @{@"name":@"Manual switch"},
                      @{@"name":@"Associated gateways", @"detail":@"Manage the Gateways you have associated.", @"segueID":@"associatedGatewaysSegue"}];
        
        
    } else {
        
        _settings = @[
                      @{@"name":@"Automatic switch"},
                      @{@"name":@"Manual switch"},
                      @{@"name":@"Connect to the Cloud...", @"detail" : @"Do you want to connect your place to the Cloud to be able to control it when you are not inside?", @"segueID":@"gatewaySetupSegue"}];
        
//        [self selectedBearerOption:@0];
        
    }
    
    [_tableView reloadData];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Communication channel";
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35.;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_settings count];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.;
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }

    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(15, 8, 320, 20);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [CSRUtilities colorFromHex:kColorBlueCSR];
    label.font = [UIFont boldSystemFontOfSize:18];
    label.text = sectionTitle;

    UIView *view = [[UIView alloc] init];
    [view addSubview:label];

    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
        
    NSDictionary *settingsItemDict = (NSDictionary *)[_settings objectAtIndex:indexPath.row];

    
    if ([settingsItemDict[@"name"] isEqualToString:@"Automatic switch"]) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:CSRSwitchableCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRSwitchableCellIdentifier];
        }
        
        ((CSRSwitchableTableViewCell *)cell).titleLabel.text = settingsItemDict[@"name"];
        // TODO: check for bearer state
        ((CSRSwitchableTableViewCell *)cell).stateSwitch.on = [CSRAppStateManager sharedInstance].isBearerModeAutomatic;
        [((CSRSwitchableTableViewCell *)cell).stateSwitch addTarget:self action:@selector(changeBearerSelectionMode:) forControlEvents:UIControlEventValueChanged];
        
    } else if ([settingsItemDict[@"name"] isEqualToString:@"Manual switch"]) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:CSRDetailsCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRDetailsCellIdentifier];
        }
        
        ((CSRDetailsTableViewCell *)cell).titleLabel.text = settingsItemDict[@"name"];
        ((CSRDetailsTableViewCell *)cell).detailsLabel.text = bearerOptionName;
        ((CSRDetailsTableViewCell *)cell).cover.hidden = isManualSelectionCoverVisible;
        ((CSRDetailsTableViewCell *)cell).cover.userInteractionEnabled = isManualSelectionCoverVisible;
        
    } else if ([settingsItemDict[@"name"] isEqualToString:@"Connect to the Cloud..."]) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"Cell3"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell3"];
        }
        
        cell.textLabel.text = settingsItemDict[@"name"];
        
        if (settingsItemDict[@"detail"]) {
            cell.detailTextLabel.numberOfLines = 2;
            cell.detailTextLabel.text = settingsItemDict[@"detail"];
        }
        
    } else if ([settingsItemDict[@"name"] isEqualToString:@"Associated gateways"]) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"Cell3"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell3"];
        }
        
        cell.textLabel.text = settingsItemDict[@"name"];
        
        if (settingsItemDict[@"detail"]) {
            cell.detailTextLabel.text = settingsItemDict[@"detail"];
        }
        
    }
    
    if (cell) {
        
        return cell;
        
    } else {
        
        return nil;
        
    }
    
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.row == 1) {
        
        if (isManualSelectionCoverVisible) {
            
            [self openPicker:nil];
            
        }
        
    }
    
    if (indexPath.row == 2) {
        
        if (_settings && [_settings count] > 0) {
            
            id obj = [_settings objectAtIndex:indexPath.row];
            
            if ([obj isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *settingsItemDict = (NSDictionary *)obj;
                
                if ([[settingsItemDict allKeys] count] > 0) {
                    
                    _segueID = settingsItemDict[@"segueID"];
                    
                }
                
            }
            
        }
        
        if (![CSRUtilities isStringEmpty:_segueID]) {
            
            [self performSegueWithIdentifier:_segueID sender:self];
            
        }
        
    }
    
    return nil;
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

#pragma mark - Actions

- (IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openPicker:(id)sender
{
    
    if (!isCurrentBearerModeAutomatic) {
        
        [self performSegueWithIdentifier:@"bearerOptionsPickerSegue" sender:self];
        
    }
    
}


#pragma mark - Navigation Bar item menthods

- (IBAction)showSearch:(id)sender
{
    
}

#pragma mark - <CSRBearerPickerDelegate>

- (id)selectedBearerOption:(CSRSelectedBearerType)bearerType
{
    
    switch (bearerType) {
        
        case CSRSelectedBearerType_Bluetooth:
        {
            
            if (((CSRBluetoothLE *)[CSRBluetoothLE sharedInstance]).cbCentralManagerState == CBCentralManagerStatePoweredOn) {
            
                bearerOptionName = @"Bluetooth";
                [[CSRAppStateManager sharedInstance] switchConnectionForSelectedBearerType:(CSRSelectedBearerType)bearerType];
                
            } else {
                
                NSString *stateMessage;
                
                if (((CSRBluetoothLE *)[CSRBluetoothLE sharedInstance]).cbCentralManagerState == CBCentralManagerStatePoweredOff) {
                    
                    stateMessage = @"Bluetooth is currently powered off.";
                    
                } else if (((CSRBluetoothLE *)[CSRBluetoothLE sharedInstance]).cbCentralManagerState == CBCentralManagerStateUnauthorized) {
                    
                    stateMessage = @"The app is not authorized to use Bluetooth Low Energy.";
                    
                } else if (((CSRBluetoothLE *)[CSRBluetoothLE sharedInstance]).cbCentralManagerState == CBCentralManagerStateUnsupported) {
                    
                    stateMessage = @"The platform/hardware doesn't support Bluetooth Low Energy.";
                    
                } else {
                    
                    stateMessage = @"Bluetooth state is unknown.";
                }
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Bluetooth"
                                                                                         message:stateMessage
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
                
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK"
                                                                       style:UIAlertActionStyleCancel
                                                                     handler:^(UIAlertAction *action) {}];
                
                [alertController addAction:cancelAction];
                
                [self presentViewController:alertController animated:YES completion:nil];
                
            }
        }
            break;
            
        case CSRSelectedBearerType_Gateway:
        {
            if ([[CSRAppStateManager sharedInstance].selectedPlace.gateways count] > 0 && ([[CSRAppStateManager sharedInstance].currentGateway.state intValue] == 2 || [[CSRAppStateManager sharedInstance].currentGateway.state intValue] == 3)) {
                
                bearerOptionName = @"Gateway";
                
                [[CSRAppStateManager sharedInstance] switchConnectionForSelectedBearerType:(CSRSelectedBearerType)bearerType];
                
            } else if ([[CSRAppStateManager sharedInstance].selectedPlace.gateways count] > 0 && [[CSRAppStateManager sharedInstance].currentGateway.state intValue] == 1) {
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Gateway connection"
                                                                                         message:@"Gateway configuration needs to be completed.\nGo to Settings and finish configuration in the Associated Gateways option."
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
                
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK"
                                                                       style:UIAlertActionStyleCancel
                                                                     handler:^(UIAlertAction *action) {
                                                                     }];
                
                [alertController addAction:cancelAction];
                
                [self presentViewController:alertController animated:YES completion:nil];
                
            } else {
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Gateway connection"
                                                                                         message:@"Do you want to connect your place to the Cloud to be able to control it when you are not inside?"
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
                
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                       style:UIAlertActionStyleCancel
                                                                     handler:^(UIAlertAction *action) {
                                                                     }];
                
                UIAlertAction *connectAction = [UIAlertAction actionWithTitle:@"Connect"
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction *action) {
                                                                          [self performSegueWithIdentifier:@"gatewaySetupSegue" sender:self];
                                                                      }];
                
                [alertController addAction:cancelAction];
                [alertController addAction:connectAction];
                
                [self presentViewController:alertController animated:YES completion:nil];
                
            }
            
            
        }
            break;
            
        case CSRSelectedBearerType_Cloud:
        {
            
            
            if ([[CSRAppStateManager sharedInstance].selectedPlace.gateways count] > 0 && [[CSRAppStateManager sharedInstance].currentGateway.state intValue] == 3) {
                
                bearerOptionName = @"Cloud";
                
                [[CSRAppStateManager sharedInstance] switchConnectionForSelectedBearerType:(CSRSelectedBearerType)bearerType];
                
            } else if ([[CSRAppStateManager sharedInstance].selectedPlace.gateways count] > 0 && [[CSRAppStateManager sharedInstance].currentGateway.state intValue] == 2)  {
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Cloud connection"
                                                                                         message:@"Cloud configuration needs to be completed.\nGo to Settings and finish configuration in the Associated Gateways option."
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
                
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK"
                                                                       style:UIAlertActionStyleCancel
                                                                     handler:^(UIAlertAction *action) {
                                                                     }];
                
                [alertController addAction:cancelAction];
                
                [self presentViewController:alertController animated:YES completion:nil];
                
            } else {
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Cloud connection"
                                                                                         message:@"Do you want to connect your place to the Cloud to be able to control it when you are not inside?"
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
                
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                       style:UIAlertActionStyleCancel
                                                                     handler:^(UIAlertAction *action) {
                                                                     }];
                
                UIAlertAction *connectAction = [UIAlertAction actionWithTitle:@"Connect"
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction *action) {
                                                                          [self performSegueWithIdentifier:@"gatewaySetupSegue" sender:self];
                                                                      }];
                
                [alertController addAction:cancelAction];
                [alertController addAction:connectAction];
                
                [self presentViewController:alertController animated:YES completion:nil];
                
            }
        }
            break;
            
        default:
            break;
    }

    [_tableView reloadData];
    
    return nil;
}

#pragma mark - Switch cell action

- (IBAction)changeBearerSelectionMode:(id)sender
{
    UISwitch *bearerModeSwitch = (UISwitch *)sender;
    
    if (bearerModeSwitch.on) {
        
        [CSRAppStateManager sharedInstance].isBearerModeAutomatic = YES;
        isManualSelectionCoverVisible = ![CSRAppStateManager sharedInstance].isBearerModeAutomatic;

    } else {
        
        if ([[CSRAppStateManager sharedInstance].selectedPlace.gateways count] > 0) {
        
            [CSRAppStateManager sharedInstance].isBearerModeAutomatic = NO;
            isManualSelectionCoverVisible = ![CSRAppStateManager sharedInstance].isBearerModeAutomatic;
            
        } else {
            
        }
        
    }
    
//    [_tableView reloadData];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([segue.identifier isEqualToString:@"bearerOptionsPickerSegue"]) {
        
        CSRBearerPickerViewController *vc = segue.destinationViewController;
        vc.delegate = self;
        vc.popoverPresentationController.delegate = self;
        vc.popoverPresentationController.presentedViewController.view.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        vc.popoverPresentationController.presentedViewController.view.layer.borderWidth = 0.5;
        
        CGFloat popoverHeight = 46 + ([[[CSRAppStateManager sharedInstance] getAvaialableBearersList] count] * 44.0);
        
        vc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20., popoverHeight);
    }
}

@end
