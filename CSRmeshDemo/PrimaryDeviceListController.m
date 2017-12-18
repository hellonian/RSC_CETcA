 //
//  PrimaryDeviceListController.m
//  BluetoothAcTEC
//
//  Created by hua on 10/12/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "PrimaryDeviceListController.h"
#import <MBProgressHUD.h>
#import "CSRDatabaseManager.h"

@interface PrimaryDeviceListController ()<MBProgressHUDDelegate>
{
    NSUInteger wizardMode;
    NSData *authCode;
}
@property (nonatomic,copy) NSString *targetAddress;
@property (assign, nonatomic) int16_t lightAddress;
@property (copy, nonatomic) NSString *lightName;
//@property (nonatomic, strong) NSMutableArray *lightAdrs;

@property (nonatomic) CSRmeshDevice *selectedDevice;
@property (nonatomic,strong) MBProgressHUD *hud;
@property (nonatomic,strong) MBProgressHUD *juhua;

@end

@implementation PrimaryDeviceListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Add";
    
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backClick)];
    self.navigationItem.leftBarButtonItem = back;
//    self.lightAdrs = [NSMutableArray array];
//    [self fixLayout];
//    
//    self.lightPanel.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
////        [[BleSupportManager shareInstance] resetScanning];
//        [self.lightPanel.mj_header endRefreshing];
//        
//
//    }];
}

- (void)backClick {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reGetData" object:self];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDiscoverDeviceNotification:) name:kCSRmeshManagerDidDiscoverDeviceNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateAppearanceNotification:)
                                                 name:kCSRmeshManagerDidUpdateAppearanceNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayAssociationProgress:)
                                                 name:kCSRmeshManagerDeviceAssociationProgressNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceAssociationFailed:)
                                                 name:kCSRmeshManagerDeviceAssociationFailedNotification
                                               object:nil];
    
    _juhua = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _juhua.mode = MBProgressHUDModeIndeterminate;
    _juhua.delegate = self;
    [[CSRBluetoothLE sharedInstance]setScanner:YES source:self];
    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:YES];
    [self queryPrimaryMeshNode];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[CSRDevicesManager sharedInstance] deleteDevicesInArray];
    
    //Notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDidDiscoverDeviceNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDidUpdateAppearanceNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDeviceAssociationProgressNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDeviceAssociationFailedNotification
                                                  object:nil];
    
    // Stop the BLE scan
    [[CSRBluetoothLE sharedInstance]setScanner:NO source:self];
    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:NO];
}

-(void)didDiscoverDeviceNotification:(NSNotification *)notification{
    if (![self alreadyDiscoveredDeviceFilteringWithDeviceUUID:(NSUUID *)notification.userInfo[kDeviceUuidString]]) {
        NSLog(@"uuid>>notification>> %@",notification.userInfo[kDeviceUuidString]);
        [[CSRDevicesManager sharedInstance] addDeviceWithUUID:notification.userInfo[kDeviceUuidString] andRSSI:notification.userInfo[kDeviceRssiString]];
        [self queryPrimaryMeshNode];
    }
}
-(BOOL)alreadyDiscoveredDeviceFilteringWithDeviceUUID:(NSUUID *)uuid{
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

- (void)didUpdateAppearanceNotification:(NSNotification *)notification
{
    NSData *updatedDeviceHash = notification.userInfo [kDeviceHashString];
    NSNumber *appearanceValue = notification.userInfo [kAppearanceValueString];
    NSData *shortName = notification.userInfo [kShortNameString];
    if (![self alreadyDiscoveredDeviceFilteringWithDeviceHash:notification.userInfo[kDeviceHashString]]) {
        [[CSRDevicesManager sharedInstance] updateAppearance:updatedDeviceHash appearanceValue:appearanceValue shortName:shortName];
        [self queryPrimaryMeshNode];
    }
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



//获取数据
- (void)queryPrimaryMeshNode {
    [self.itemCluster removeAllObjects];
//    [self.lightAdrs removeAllObjects];
    
    CSRDevicesManager *devManager = [CSRDevicesManager sharedInstance];
    for (CSRmeshDevice *device in [devManager unassociatedMeshDevices]) {
        NSLog(@"uuid>>pri>> %@",device.uuid);
        [self.itemCluster insertObject:device atIndex:0];
    }
    if ([self.itemCluster count]>0) {
        [_juhua hideAnimated:YES];
    }
    [self updateCollectionView];
}

#pragma mark - Logic

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//    NSString *adr = [self.itemCluster objectAtIndex:[self dataIndexOfCellAtIndexPath:indexPath]];
//    int16_t lightAdr = [[self.lightAdrs objectAtIndex:[self dataIndexOfCellAtIndexPath:indexPath]] intValue];

    PrimaryItemCell *cell = (PrimaryItemCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.alpha = 0.7;
    
    _selectedDevice = [self.itemCluster objectAtIndex:[self dataIndexOfCellAtIndexPath:indexPath]];
    
    if (_selectedDevice) {
        
        if (_selectedDevice.isAssociated) {
            NSArray *array = [[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects];
            [array enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([deviceEntity.deviceHash isEqualToData:_selectedDevice.deviceHash]) {
                    
                    [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:deviceEntity];
                    [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:deviceEntity];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
                    [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
                }
            }];
        }
        
//        if (!_selectedDevice.isAssociated) {
        
            [[CSRDevicesManager sharedInstance] setAttentionPreAssociation:_selectedDevice.deviceHash attentionState:@(1) withDuration:@(6000)];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Are you sure to add the selected device？" message:nil preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self associateDevice];
            }];
            [alert addAction:cancel];
            [alert addAction:confirm];
            [self presentViewController:alert animated:YES completion:nil];
//        }
    }
}
-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    PrimaryItemCell *cell = (PrimaryItemCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.alpha = 1;
}

-(void) associateDevice {
    [[CSRBluetoothLE sharedInstance]setScanner:NO source:self];
    
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
            
            
        } else if (_selectedDevice) {
            
            wizardMode = CSRWizardPopoverMode_SecurityCode;
            
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
    
    [[CSRDevicesManager sharedInstance].unassociatedMeshDevices removeAllObjects];
    if (_selectedDevice.appearanceShortname) {
        [[CSRDevicesManager sharedInstance] associateDeviceFromCSRDeviceManager:_selectedDevice.deviceHash authorisationCode:nil];
        
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
        _hud.delegate = self;
        _hud.label.font = [UIFont systemFontOfSize:13];
        _hud.label.numberOfLines = 0;
        _hud.label.text = @"Associating device: 0%";
    }
}

#pragma mark - 入网过程进度条

- (void)displayAssociationProgress:(NSNotification *)notification {
    NSNumber *completedSteps = notification.userInfo[@"stepsCompleted"];
    NSNumber *totalSteps = notification.userInfo[@"totalSteps"];
    
    if ([completedSteps floatValue] <= [totalSteps floatValue] && [completedSteps floatValue] > 0) {
        CGFloat completed = [completedSteps floatValue]/[totalSteps floatValue];
        _hud.label.text = [NSString stringWithFormat:@"Associating device: %.0f%%", (completed * 100)];
        _hud.progress = completed;
        if (completed >= 1) {
            
            [self.hud hideAnimated:YES];

        }
        [self.itemCluster removeObject:_selectedDevice];
        [self updateCollectionView];
        
        
    } else {
        
        NSLog(@"ERROR: There was and issue with device association");
        
    }
  
}

- (void)deviceAssociationFailed:(NSNotification *)notification
{
    _hud.label.text = [NSString stringWithFormat:@"Association error: %@", notification.userInfo[@"error"]];
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hudd {
    [hudd removeFromSuperview];
    hudd = nil;
}

@end
