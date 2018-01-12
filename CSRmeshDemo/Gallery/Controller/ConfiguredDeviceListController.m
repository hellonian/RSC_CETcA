//
//  ConfiguredDeviceListController.m
//  BluetoothAcTEC
//
//  Created by hua on 10/15/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "ConfiguredDeviceListController.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceEntity.h"
#import "LightClusterCell.h"
#import "DeviceModel.h"
#import <MBProgressHUD.h>
#import "LightSceneBringer.h"

@interface ConfiguredDeviceListController ()<MBProgressHUDDelegate>
@property (nonatomic,assign) SelectMode selectMode;
@property (nonatomic,copy) ConfiguredDeviceListHandle handle;
@property (nonatomic,strong) NSDictionary *primaryInfo;
@property (nonatomic,strong) NSMutableArray *selectDeviceAddress;
@property (nonatomic,copy) NSString *currentSceneName;
@property (nonatomic,assign)NSInteger currentImage;

@end

@implementation ConfiguredDeviceListController

static NSString * const sceneListKey = @"com.actec.bluetooth.sceneListKey";

- (void)prepareEditingCurrentSceneProfile:(NSString*)sceneName sceneMemberInfo:(NSDictionary *)sceneMemberInfo isNewAdd:(BOOL)isnewadd image:(NSInteger)image{
    //will trigger "- (void)updateReusedCell:(UICollectionViewCell *)cell" to mark the current member
    self.selectMode = Multiple;
    [self.selectDeviceAddress removeAllObjects];
//    [self.selectDeviceAddress addObjectsFromArray:sceneMemberInfo.allKeys];
    _primaryInfo = [[NSDictionary alloc] initWithDictionary:sceneMemberInfo];
    _currentSceneName = sceneName;
    _isnewadd = isnewadd;
    _currentImage = image;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Choose Light";
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finishSelectingDevice)];
    self.navigationItem.rightBarButtonItem = done;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self disableSomeFeatureOfSuper];
    [self fixLayout];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)queryPrimaryMeshNode {
    //override,only load the single light
    [self.itemCluster removeAllObjects];
    
    NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
    if (mutableArray != nil || [mutableArray count] != 0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        for (CSRDeviceEntity *deviceEntity in mutableArray) {
            if (![deviceEntity.shortName isEqualToString:@"RC350"]) {
                DeviceModel *model = [[DeviceModel alloc] init];
                model.deviceId = deviceEntity.deviceId;
                model.name = deviceEntity.name;
                model.shortName = deviceEntity.shortName;
                [self.itemCluster insertObject:model atIndex:0];
            }
        }
    }
    [self updateCollectionView];
    
}

#pragma mark - Override 

- (void)actionWhenSelectCell:(UICollectionViewCell *)cell {
    LightClusterCell *lightCell = (LightClusterCell*)cell;
    //only the single light pass to here
    [self.itemCluster enumerateObjectsUsingBlock:^(DeviceModel *deviceModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([deviceModel.deviceId isEqualToNumber:lightCell.deviceID]) {
            deviceModel.isShowDeleteBtn = YES;
        }
    }];
    
    if (self.selectMode == Single) {
        [self.selectDeviceAddress removeAllObjects];
        [self.selectDeviceAddress addObject:lightCell.deviceID];
        //exclude
        [self onlyYou:lightCell.deviceID];
        [self enableDoneItem];
        return;
    }
    
    if (self.selectMode == Multiple) {
        if (![self.selectDeviceAddress containsObject:lightCell.deviceID]) {
            [self.selectDeviceAddress addObject:lightCell.deviceID];
            [self enableDoneItem];
            
        }
        return;
    }
}

- (void)enableDoneItem {
    if ([self.selectDeviceAddress count] > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }else{
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)actionWhenCancelSelectCell:(UICollectionViewCell *)cell {
    LightClusterCell *lightCell = (LightClusterCell*)cell;
    //mark in super already
    
    if (self.selectMode == Single) {
        [self.selectDeviceAddress removeAllObjects];
        [self enableDoneItem];
        return;
    }
    
    if (self.selectMode == Multiple) {
        [self.selectDeviceAddress removeObject:lightCell.deviceID];
        [self enableDoneItem];
        return;
    }
}

- (void)updateReusedCell:(UICollectionViewCell *)cell {
    //
    if ([cell isKindOfClass:[LightClusterCell class]]) {
        LightClusterCell *lightClusterCell = (LightClusterCell*)cell;
        
        if ([self.selectDeviceAddress containsObject:lightClusterCell.deviceID]) {
            [lightClusterCell showDeleteButton:YES];
        }
        
        NSInteger index = [self dataIndexOfCellAtIndexPath:lightClusterCell.myIndexpath];
        CSRDeviceEntity *deviceEntity = [self.itemCluster objectAtIndex:index];
        
        if (!deviceEntity.isAssociated) {
            [lightClusterCell showOfflineUI];
        }
    }
}

#pragma mark - Final Handle

- (void)finishSelectingDevice {
    if (self.handle) {
        self.handle(self.selectDeviceAddress);
        self.handle = nil;
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    if (self.selectMode == Multiple) {
        [self finishSceneOrganizing];
        return;
    }
    NSLog(@"返回3333");
    
}

- (void)finishSceneOrganizing {
    if (_isnewadd == NO) {
        [self edit:_currentSceneName];
    }
    else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add New Scene" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UITextField *textField = alert.textFields.firstObject;
            if (textField.text.length != 0) {
                [self edit:textField.text];
            }
        }];
        [alert addAction:cancel];
        [alert addAction:confirm];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"Enter a new scene name";
        }];
        [self presentViewController:alert animated:YES completion:nil];
        
    }
}
-(void)edit:(NSString *)sceneName{
    
    BOOL exist = NO;
    
    if (self.currentSceneName && [self.currentSceneName isEqualToString:sceneName]) {
        exist = NO;
    }
    else {
        exist = [self checkSceneName:sceneName];
    }
    
    if (exist) {
        [self showTextHud:@"Scene name conflict!"];
        return;
    }
    
    LightSceneBringer *sceneProfile = [[LightSceneBringer alloc] init];
    sceneProfile.profileName = sceneName;
    
    //for the offline device
    if (self.primaryInfo) {
        [sceneProfile.groupMember addEntriesFromDictionary:self.primaryInfo];
    }
    
    for (NSString *key in sceneProfile.groupMember.allKeys) {
        if (![self.selectDeviceAddress containsObject:key]) {
            [sceneProfile.groupMember removeObjectForKey:key];
        }
    }
    if (_isnewadd) {
        NSInteger rIndex = arc4random()%20 + 800;
        sceneProfile.sceneImage = rIndex;   //[UIImage imageNamed:[NSString stringWithFormat:@"scence%li.png",(long)rIndex]];
    }else {
        sceneProfile.sceneImage = _currentImage;
    }
    
    
    if (self.selectDeviceAddress.count >0) {
        NSArray *existLightCluster = [self lightBringerWithAddress:self.selectDeviceAddress];
        
        for (DeviceModel *deviceModel in existLightCluster) {
            //update by key-value
            if ([deviceModel.shortName isEqualToString:@"S350BT"]) {
                deviceModel.level = @(0);
            }
            if ([deviceModel.shortName isEqualToString:@"D350BT"] && [deviceModel.powerState isEqualToNumber:@(0)]) {
                deviceModel.level = @(0);
            }
            if (deviceModel.level) {
                [sceneProfile addLightMember:deviceModel.deviceId shortName:deviceModel.shortName poweState:deviceModel.powerState brightness:deviceModel.level];
            }
        }
    }

    [self addNewSceneProfile:[sceneProfile archive] profileName:sceneName];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)checkSceneName:(NSString*)newName {
    NSArray *sceneList = [[NSUserDefaults standardUserDefaults] arrayForKey:sceneListKey];
    __block BOOL isExist = NO;
    if ([sceneList count]==0) {
        return NO;
    }
    
    [sceneList enumerateObjectsUsingBlock:^(NSString *profileName,NSUInteger idx, BOOL *stop){
        if ([profileName isEqualToString:newName]) {
            isExist = YES;
            *stop = YES;
        }
    }];
    
    return isExist;
    
}

- (void)showTextHud:(NSString *)text {
    MBProgressHUD *successHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    successHud.mode = MBProgressHUDModeText;
    successHud.label.text = text;
    successHud.label.numberOfLines = 0;
    successHud.delegate = self;
    [successHud hideAnimated:YES afterDelay:1.5f];
}

- (NSArray*)lightBringerWithAddress:(NSArray*)deviceIDs {
    NSMutableArray *member = [[NSMutableArray alloc] init];
    
    [self.itemCluster enumerateObjectsUsingBlock:^(DeviceModel *device, NSUInteger idx, BOOL * _Nonnull stop) {
        for (NSNumber *deviceId in deviceIDs) {
            if ([deviceId isEqualToNumber:device.deviceId]) {
                [member addObject:device];
            }
        }
    }];
    return member;
}

- (void)addNewSceneProfile:(NSData*)profileData profileName:(NSString*)pName {
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    NSArray *list = [center arrayForKey:sceneListKey];
    NSMutableArray *updatedList = [[NSMutableArray alloc]init];
    
    if (list) {
        [updatedList addObjectsFromArray:list];
    }
    
    if (![updatedList containsObject:pName]) {
        [updatedList addObject:pName];
        [center setObject:updatedList forKey:sceneListKey];
    }
    
    [center setObject:profileData forKey:pName];
    [center synchronize];
}

- (void)setSelectDeviceHandle:(ConfiguredDeviceListHandle)handle {
    self.handle = nil;
    self.handle = handle;
}

- (NSMutableArray*)selectDeviceAddress {
    if (!_selectDeviceAddress) {
        _selectDeviceAddress = [[NSMutableArray alloc] init];
    }
    
    return _selectDeviceAddress;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    
    [hud removeFromSuperview];
    
    hud = nil;
    
}


@end
