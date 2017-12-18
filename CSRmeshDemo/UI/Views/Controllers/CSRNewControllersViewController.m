//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSRNewControllersViewController.h"
#import "CSRControllerAssociationVC.h"
#import "CSRDevicesManager.h"
#import "CSRUtilities.h"
#import "CSRConstants.h"
#import "CSRControllerDetailsVC.h"
#import "CSRmeshStyleKit.h"
#import "CSRBluetoothLE.h"

@interface CSRNewControllersViewController () {
    NSInteger selectedDeviceIndex;
    CSRControllerEntity *controllerEntity;
}

@property (nonatomic, retain) NSArray *controllersArray;
@property (nonatomic, retain) NSMutableArray *onlyControllersArray;

@end

@implementation CSRNewControllersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _onlyControllersArray = [NSMutableArray new];
    _addControllersTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[CSRBluetoothLE sharedInstance]setScanner:YES source:self];
    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:YES];

    
    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDiscoverPhone:)
                                                 name:kCSRmeshManagerDidDiscoverDeviceNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateAppearance:)
                                                 name:kCSRmeshManagerDidUpdateAppearanceNotification
                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(doneDismissAction:)
//                                                 name:@"doneDismiss"
//                                               object:nil];
    
    [_activityIndicator startAnimating];
    selectedDeviceIndex = -1;
    _associateBarButtonItem.enabled = NO;
}

- (void) dismissAndPush:(CSRControllerEntity *)ctrlEnt
{
    controllerEntity = ctrlEnt;
    [self performSegueWithIdentifier:@"controllerEditSegue" sender:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [[CSRDevicesManager sharedInstance].unassociatedMeshDevices removeAllObjects];
    [_onlyControllersArray removeAllObjects];
    
    // Stop the BLE scan
    [[CSRBluetoothLE sharedInstance]setScanner:NO source:self];
    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:NO];

}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _onlyControllersArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newControllersTableCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"newControllersTableCell"];
    }
    
    CSRmeshDevice *device = [_onlyControllersArray objectAtIndex:indexPath.row];
    
    if (device) {
        [_activityIndicator stopAnimating];
        NSString *deviceName = [[NSString alloc] initWithData:device.appearanceShortname encoding:NSUTF8StringEncoding];
        
        if (![CSRUtilities isStringEmpty:deviceName]) {
            deviceName = deviceName;
            
        } else {
            deviceName = @"Retrieving device name";
        }
        
        cell.textLabel.text = deviceName;
        cell.detailTextLabel.text = device.uuid.UUIDString;
        cell.imageView.image = [CSRmeshStyleKit imageOfControllerDevice];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (selectedDeviceIndex == indexPath.row) {
            cell.textLabel.textColor = [CSRUtilities colorFromHex:kColorAmber600];
            cell.detailTextLabel.textColor = [CSRUtilities colorFromHex:kColorAmber600];
            
        } else {
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
            
        }
        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedDeviceIndex = indexPath.row;
    _associateBarButtonItem.enabled = YES;
}
    
- (void)setCellColor:(UIColor *)color forCell:(UITableViewCell *)cell
{
    cell.textLabel.textColor = color;
    cell.detailTextLabel.textColor = color;
}


#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return NO;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"controllerAssociationSegue"]) {
        CSRControllerAssociationVC *vc = segue.destinationViewController;
        vc.popoverPresentationController.delegate = self;
        vc.popoverPresentationController.presentedViewController.view.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        vc.popoverPresentationController.presentedViewController.view.layer.borderWidth = 0.5;
        vc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20, 190);
        
        vc.controllerDelegate = self;
        vc.parent = self;
    
        NSIndexPath *selectedIndexPath = [_addControllersTableView indexPathForSelectedRow];
        vc.meshDevice = (CSRmeshDevice*)[_onlyControllersArray objectAtIndex:selectedIndexPath.row];
    }
    if ([segue.identifier isEqualToString:@"controllerEditSegue"]) {
        CSRControllerDetailsVC *vc = [segue destinationViewController];
        vc.controllerEntity = controllerEntity;

    }
}

- (IBAction)backAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)associateControllerAction:(id)sender {
    
    [self performSegueWithIdentifier:@"controllerAssociationSegue" sender:nil];
}

#pragma mark - Notifications handlers

-(void)didDiscoverPhone:(NSNotification *)notification
{
    if (![self alreadyDiscoveredDeviceFilteringWithDeviceUUID:(NSUUID *)notification.userInfo[kDeviceUuidString]]) {
        [[CSRDevicesManager sharedInstance] addDeviceWithUUID:notification.userInfo [kDeviceUuidString] andRSSI:notification.userInfo [kDeviceRssiString]];
    }
}

- (void)didUpdateAppearance:(NSNotification *)notification
{
    NSData *updatedDeviceHash = notification.userInfo [kDeviceHashString];
    NSNumber *appearanceValue = notification.userInfo [kAppearanceValueString];
    NSData *shortName = notification.userInfo [kShortNameString];
    
    if (![self alreadyDiscoveredDeviceFilteringWithDeviceHash:notification.userInfo[kDeviceHashString]]) {
        [[CSRDevicesManager sharedInstance] updateAppearance:updatedDeviceHash appearanceValue:appearanceValue shortName:shortName];
        NSMutableArray *allDevicesArray = [[CSRDevicesManager sharedInstance] unassociatedMeshDevices];
        
        [allDevicesArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CSRmeshDevice *meshDevice = (CSRmeshDevice*)obj;
            if ([meshDevice.appearanceValue isEqualToNumber:@(CSRApperanceNameController)]) {
                
                if (![_onlyControllersArray containsObject:meshDevice]) {
                    [_onlyControllersArray addObject:meshDevice];
                }
            }
        }];
        
        [_addControllersTableView reloadData];
    }
    
    //stop animation of spinner
    if ([_onlyControllersArray count] > 0) {
        [_activityIndicator stopAnimating];
    }
}

#pragma mark - Device filtering

- (BOOL)alreadyDiscoveredDeviceFilteringWithDeviceUUID:(NSUUID *)uuid
{
    NSArray *enumarationArray = [NSArray arrayWithArray:[[CSRDevicesManager sharedInstance] unassociatedMeshDevices]];
    __block BOOL retValue = NO;
    
    [enumarationArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CSRmeshDevice *meshDevice = (CSRmeshDevice *)obj;
        if ([meshDevice.uuid.UUIDString isEqualToString:uuid.UUIDString]) {
             retValue = YES;
            *stop = YES;
        }

    }];
    
    return retValue;
}

- (BOOL)alreadyDiscoveredDeviceFilteringWithDeviceHash:(NSData *)data
{
    NSArray *enumarationArray = [NSArray arrayWithArray:[[CSRDevicesManager sharedInstance] unassociatedMeshDevices]];
    __block BOOL retValue = NO;
    
    [enumarationArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CSRmeshDevice *meshDevice = (CSRmeshDevice *)obj;
        if ([meshDevice.deviceHash isEqualToData:data]) {
            retValue = YES;
            *stop = YES;
        }
        
    }];
    
    return retValue;
}

@end
