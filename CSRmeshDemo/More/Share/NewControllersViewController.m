//
//  NewControllersViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/15.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "NewControllersViewController.h"
#import "CSRmeshDevice.h"
#import "CSRUtilities.h"
#import "CSRmeshStyleKit.h"
#import "CSRConstants.h"
#import "CSRBluetoothLE.h"
#import "CSRDevicesManager.h"
#import "ControllerAssociationVC.h"
#import "ControllerDetailVC.h"

@interface NewControllersViewController ()<UITableViewDelegate,UITableViewDataSource,UIPopoverPresentationControllerDelegate,CSRControllerAssociated>
{
    NSInteger selectedDeviceIndex;
}

@property (nonatomic, retain) NSArray *controllersArray;
@property (nonatomic, retain) NSMutableArray *onlyControllersArray;

@end

@implementation NewControllersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"Select a controller";
    UIBarButtonItem *associate = [[UIBarButtonItem alloc] initWithTitle:@"Associate" style:UIBarButtonItemStylePlain target:self action:@selector(associateAction)];
    self.navigationItem.rightBarButtonItem = associate;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    _onlyControllersArray = [NSMutableArray new];
    _addControllersTableView.delegate = self;
    _addControllersTableView.dataSource = self;
    _addControllersTableView.rowHeight = 60.0f;
    _addControllersTableView.backgroundView = [[UIView alloc] init];
    _addControllersTableView.backgroundColor = [UIColor clearColor];
    
    [_activityIndicator startAnimating];
    selectedDeviceIndex = -1;
    
    [[CSRBluetoothLE sharedInstance]setScanner:YES source:self];
    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDiscoverPhone:)
                                                 name:kCSRmeshManagerDidDiscoverDeviceNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateAppearance:)
                                                 name:kCSRmeshManagerDidUpdateAppearanceNotification
                                               object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [[CSRDevicesManager sharedInstance].unassociatedMeshDevices removeAllObjects];
    [_onlyControllersArray removeAllObjects];
    
    // Stop the BLE scan
    [[CSRBluetoothLE sharedInstance]setScanner:NO source:self];
    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:NO];
    
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

- (void)associateAction {
    ControllerAssociationVC *cavc = [[ControllerAssociationVC alloc] init];
    cavc.modalPresentationStyle = UIModalPresentationPopover;
    cavc.popoverPresentationController.delegate = self;
    cavc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20, 190);
    cavc.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    
    cavc.controllerDelegate = self;
    cavc.parent = self;
    
    NSIndexPath *selectedIndexPath = [_addControllersTableView indexPathForSelectedRow];
    cavc.meshDevice = (CSRmeshDevice*)[_onlyControllersArray objectAtIndex:selectedIndexPath.row];
    
    [self presentViewController:cavc animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _onlyControllersArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.imageView.image = [CSRmeshStyleKit imageOfControllerDevice];
        cell.detailTextLabel.numberOfLines = 0;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedDeviceIndex = indexPath.row;
    self.navigationItem.rightBarButtonItem.enabled = YES;
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
        
        [_activityIndicator removeFromSuperview];
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

- (void) dismissAndPush:(CSRControllerEntity *)ctrlEnt
{
    ControllerDetailVC *dvc = [[ControllerDetailVC alloc] init];
    dvc.controllerEntity = ctrlEnt;
    [self.navigationController pushViewController:dvc animated:YES];
}

@end
