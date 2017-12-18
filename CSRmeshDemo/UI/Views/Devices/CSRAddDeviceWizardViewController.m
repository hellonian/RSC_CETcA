//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRAddDeviceWizardViewController.h"
#import "CSRNewDeviceTableViewCell.h"
#import "CSRmeshStyleKit.h"
#import "CSRUtilities.h"
#import "CSRMeshUtilities.h"
#import "CSRConstants.h"
#import "CSRBluetoothLE.h"
#import "CSRDevicesManager.h"
#import "CSRmeshSettings.h"
#import "CSRDatabaseManager.h"
#import "CSRWizardPopoverViewController.h"
#import "CSRPlaceEntity.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceDetailsViewController.h"
#import "CSRBridgeRoaming.h"

@interface CSRAddDeviceWizardViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
{
    BOOL scanState;
    BOOL updateRequired;
    NSInteger selectedDeviceIndex;
    NSUInteger wizardMode;
    NSData *deviceHash;
    NSData *authCode;
    
}

@end

@implementation CSRAddDeviceWizardViewController

#pragma mark - View lifecycle

- (id)init
{
    self = [super init];
    
    if (self != nil)
    {
        self.showNavMenuButton = NO;
        self.showNavSearchButton = NO;
    }
    
    return self;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Detected devices list";
    [self setNeedsStatusBarAppearanceUpdate];
    
    //Set navigation buttons
//    _backButton = [[UIBarButtonItem alloc] init];
//    _backButton.image = [CSRmeshStyleKit imageOfBack_arrow];
//    _backButton.action = @selector(back:);
//    _backButton.target = self;
    
//    [super addCustomBackButtonItem:_backButton];
    
    _devicesTableView.delegate = self;
    _devicesTableView.dataSource = self;
    
    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDiscoverDeviceNotification:)
                                                 name:kCSRmeshManagerDidDiscoverDeviceNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateAppearanceNotification:)
                                                 name:kCSRmeshManagerDidUpdateAppearanceNotification
                                               object:nil];
    
    scanState = NO;
    updateRequired = NO;
    
    [_activityIndicatorView startAnimating];
    
    //Set initially selected row index to NONE
    selectedDeviceIndex = -1;
    
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(reloadTableDataOnMainThread) userInfo:nil repeats:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _deviceEntity = nil;
    _selectedDevice = nil;
    deviceHash = nil;
    authCode = nil;
//    _uuidStringFromQRScan = nil;
//    _acStringFromQRScan = nil;
    
    // Start the BLE scan
    [[CSRBluetoothLE sharedInstance]setScanner:YES source:self];
//    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:YES];
    
    // Disable 'Associate' buttons
    _associateDeviceButton.enabled = NO;
    
    //Set initial UUID and AC strings to
//    _uuidStringFromQRScan = @"";
//    _acStringFromQRScan = @"";
    
    [_devicesTableView reloadData];
    
    //hide the table view if there is no bridge connection
    
    if ([CSRAppStateManager sharedInstance].bearerType == CSRSelectedBearerType_Bluetooth)
    {
        if ([[CSRBridgeRoaming sharedInstance] numberOfConnectedBridges] >= 1) {
            _noBridgeConnectionView.hidden = YES;
            
        } else {
            _devicesListView.hidden = YES;
        }
    }
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [[CSRDevicesManager sharedInstance].unassociatedMeshDevices removeAllObjects];
    [[CSRDevicesManager sharedInstance] deleteDevicesInArray];
    
    //Notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:kCSRmeshManagerDidDiscoverDeviceNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:kCSRmeshManagerDidUpdateAppearanceNotification
                                               object:nil];
    // Stop the BLE scan
    [[CSRBluetoothLE sharedInstance]setScanner:NO source:self];
    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:NO];
}

- (void)dealloc
{
    self.view = nil;
}


- (void) dismissAndPush:(CSRDeviceEntity *)dvcEnt
{
    _deviceEntity = dvcEnt;
    [self performSegueWithIdentifier:@"editAssociatedDevice" sender:nil];
}


#pragma mark - Setup Device List screen

- (void)setupDeviceList
{
    [[[CSRDevicesManager sharedInstance] unassociatedMeshDevices] removeAllObjects];
    _devicesListView.hidden = NO;
}

#pragma mark - Actions

- (IBAction)back:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)cancelAll:(id)sender
{
    [[[CSRDevicesManager sharedInstance] unassociatedMeshDevices] removeAllObjects];
    _deviceEntity = nil;
    _selectedDevice = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCSRmeshManagerDidDiscoverDeviceNotification object:nil];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Association actions

- (IBAction)devicesListAssociate:(id)sender
{
    //Notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDidDiscoverDeviceNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDidUpdateAppearanceNotification
                                                  object:nil];

    CSRPlaceEntity *placeEntity = [CSRAppStateManager sharedInstance].selectedPlace;
    
    if (placeEntity.passPhrase) {
        
        NSData *localHash = [[MeshServiceApi sharedInstance] getDeviceHashFromUuid:(CBUUID*)_selectedDevice.uuid];
        CSRmeshDevice *localDevice = [[CSRDevicesManager sharedInstance] checkPreviouslyScannedDevicesWithDeviceHash:localHash];
    
        // Check if device was previously scanned (QR) and there is database entry for it
        if (_selectedDevice && localDevice) {
            
            wizardMode = CSRWizardPopoverMode_AssociationFromDeviceList;
            authCode = localDevice.authCode;
            [self performSegueWithIdentifier:@"wizardPopoverSegue" sender:self];

        } else if (_selectedDevice) {
            
            wizardMode = CSRWizardPopoverMode_SecurityCode;
            [self performSegueWithIdentifier:@"wizardPopoverSegue" sender:self];
        }
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert!!"
                                                                                 message:@"You should be place owner to associate a device"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             
                                                         }];
        
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];

    }
}

#pragma mark - Steps animation

- (void)animateStepsBetweenFirstView:(UIView *)firstView andSecondView:(UIView *)secondView
{
    
    [secondView setTransform:(CGAffineTransformMakeScale(0.8f, 0.8f))];
    secondView.alpha = 0.f;
    secondView.hidden = NO;
    
    [UIView animateWithDuration:0.5
                          delay:0.1
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         firstView.alpha = 0.f;
                         [firstView setTransform:(CGAffineTransformMakeScale(1.2f, 1.2f))];
                         
                         secondView.alpha = 1.f;
                         [secondView setTransform:(CGAffineTransformMakeScale(1.0f, 1.0f))];

    } completion:^(BOOL finished) {
        firstView.hidden = YES;
        
    }];
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[CSRDevicesManager sharedInstance] unassociatedMeshDevices] count];
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
    CSRNewDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CSRNewDeviceTableViewCellIdentifier];
    
    if (!cell) {
        cell = [[CSRNewDeviceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRNewDeviceTableViewCellIdentifier];
    }
    
    CSRmeshDevice *device;
    
    if ([[CSRDevicesManager sharedInstance] unassociatedMeshDevices].count > 0) {
        device = [[[CSRDevicesManager sharedInstance] unassociatedMeshDevices] objectAtIndex:indexPath.row];
    }
    
    if (device) {
        
        NSString *deviceName;
            
        if (![CSRUtilities isStringEmpty:[[NSString alloc] initWithData:device.appearanceShortname encoding:NSUTF8StringEncoding]]) {
            deviceName = [[NSString alloc] initWithData:device.appearanceShortname encoding:NSUTF8StringEncoding];
            
            [cell.deviceActivityIndicator stopAnimating];
            cell.deviceActivityIndicator.hidden = YES;
            
            
        } else {
            deviceName = @"Retrieving device name";
            
            [cell.deviceActivityIndicator startAnimating];
            cell.deviceActivityIndicator.hidden = NO;
            
        }
            
        cell.deviceNameLabel.text = deviceName;
        cell.deviceUUIDLabel.text = device.uuid.UUIDString;
        if ([CSRUtilities isString:deviceName containsCharacters:@"Light"]) {
            cell.iconImageView.image = [CSRmeshStyleKit imageOfLightDevice_on];
            cell.iconImageView.image = [cell.iconImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconImageView.tintColor = [UIColor darkGrayColor];
        } else if ([CSRUtilities isString:deviceName containsCharacters:@"Switch"]) {
            cell.iconImageView.image = [CSRmeshStyleKit imageOfOnOff];
            cell.iconImageView.image = [cell.iconImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconImageView.tintColor = [UIColor darkGrayColor];
        } else if ([CSRUtilities isString:deviceName containsCharacters:@"Sensor"]) {
            cell.iconImageView.image = [CSRmeshStyleKit imageOfSensorDevice];
            cell.iconImageView.image = [cell.iconImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconImageView.tintColor = [UIColor darkGrayColor];
        } else if ([CSRUtilities isString:deviceName containsCharacters:@"Heater"]) {
            cell.iconImageView.image = [CSRmeshStyleKit imageOfHeaterDevice];
            cell.iconImageView.image = [cell.iconImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconImageView.tintColor = [UIColor darkGrayColor];
        } else {
            cell.iconImageView.image = [CSRmeshStyleKit imageOfMesh_device];
            cell.iconImageView.image = [cell.iconImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconImageView.tintColor = [UIColor darkGrayColor];

        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (selectedDeviceIndex == indexPath.row) {
        [self setCellColor:[CSRUtilities colorFromHex:kColorAmber600] forCell:cell];
    } else {
       [self setCellColor:[UIColor darkGrayColor] forCell:cell];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSRNewDeviceTableViewCell *cell = (CSRNewDeviceTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [self setCellColor:[CSRUtilities colorFromHex:kColorAmber600] forCell:cell];

    selectedDeviceIndex = indexPath.row;
    _selectedDevice = nil;
    
    NSArray *unassociatedMeshDevices = [[CSRDevicesManager sharedInstance] unassociatedMeshDevices];
    
    if (unassociatedMeshDevices && indexPath.row<unassociatedMeshDevices.count>0 && indexPath.row<unassociatedMeshDevices.count) {
        
        _selectedDevice = [unassociatedMeshDevices objectAtIndex:indexPath.row];
    }
    
    if (_selectedDevice) {
        
        if (!_selectedDevice.isAssociated) {
            
            [[CSRDevicesManager sharedInstance] setAttentionPreAssociation:_selectedDevice.deviceHash attentionState:@(1) withDuration:@(6000)];
            _associateDeviceButton.enabled = YES;
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSRNewDeviceTableViewCell *cell = (CSRNewDeviceTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [self setCellColor:[UIColor darkGrayColor] forCell:cell];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


#pragma mark UITableViewCell helper

- (void)setCellColor:(UIColor *)color forCell:(UITableViewCell *)cell
{
    CSRNewDeviceTableViewCell *selectedCell = (CSRNewDeviceTableViewCell*)cell;
    selectedCell.deviceNameLabel.textColor = color;
    selectedCell.deviceUUIDLabel.textColor = color;
    selectedCell.iconImageView.tintColor = color;
}

#pragma mark - Table reload

- (void)reloadTable
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [_devicesTableView reloadData];
    }];
}

#pragma mark - Notifications handlers

-(void)didDiscoverDeviceNotification:(NSNotification *)notification
{
    if (![self alreadyDiscoveredDeviceFilteringWithDeviceUUID:(NSUUID *)notification.userInfo[kDeviceUuidString]]) {
        [[CSRDevicesManager sharedInstance] addDeviceWithUUID:notification.userInfo [kDeviceUuidString] andRSSI:notification.userInfo [kDeviceRssiString]];
    
        [self reloadTable];
    }

    if ([[[CSRDevicesManager sharedInstance] unassociatedMeshDevices] count] > 0) {
        
        [_activityIndicatorView stopAnimating];
        
    }
}

- (void)didUpdateAppearanceNotification:(NSNotification *)notification
{
    NSData *updatedDeviceHash = notification.userInfo [kDeviceHashString];
    NSNumber *appearanceValue = notification.userInfo [kAppearanceValueString];
    NSData *shortName = notification.userInfo [kShortNameString];
    if (![self alreadyDiscoveredDeviceFilteringWithDeviceHash:notification.userInfo[kDeviceHashString]]) {
        [[CSRDevicesManager sharedInstance] updateAppearance:updatedDeviceHash appearanceValue:appearanceValue shortName:shortName];
        [self reloadTable];
    }
    
    updateRequired = YES;
}

#pragma mark - Hmmmm


- (void)reloadTableDataOnMainThread
{
    if (updateRequired) {
        updateRequired = NO;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_devicesTableView reloadData];
        }];
    }
}

#pragma mark - Device filtering

- (BOOL)alreadyDiscoveredDeviceFilteringWithDeviceUUID:(NSUUID *)uuid
{
    for (id value in [[CSRDevicesManager sharedInstance] unassociatedMeshDevices]) {
        if ([value isKindOfClass:[CSRmeshDevice class]]) {
            CSRmeshDevice *device = value;
            if ([device.uuid.UUIDString isEqualToString:uuid.UUIDString]) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)alreadyDiscoveredDeviceFilteringWithDeviceHash:(NSData *)data
{
    for (id value in [[CSRDevicesManager sharedInstance] unassociatedMeshDevices]) {
        if ([value isKindOfClass:[CSRmeshDevice class]]) {
            CSRmeshDevice *device = value;
            if ([device.deviceHash isEqualToData:data]) {
                return YES;
            }
        }
    }
    
    return NO;
}

#pragma mark - Alert controller

- (void)showAlertViewControllerWithMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Validation"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                         }];
    
    
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([segue.identifier isEqualToString:@"wizardPopoverSegue"]) {
        [[CSRDevicesManager sharedInstance].unassociatedMeshDevices removeAllObjects];
        
        CSRWizardPopoverViewController *vc = segue.destinationViewController;
        vc.mode = wizardMode;
        vc.meshDevice = _selectedDevice;
        vc.authCode = authCode;
        vc.deviceHash = deviceHash;
        vc.deviceDelegate = self;
        
        vc.popoverPresentationController.delegate = self;
        vc.popoverPresentationController.presentedViewController.view.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        vc.popoverPresentationController.presentedViewController.view.layer.borderWidth = 0.5;
        
        vc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20., 150.);
    }
    if ([segue.identifier isEqualToString:@"editAssociatedDevice"]) {
        CSRDeviceDetailsViewController *vc = segue.destinationViewController;
        vc.deviceEntity = _deviceEntity;

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
