//
//  DeviceListViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/31.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "DeviceListViewController.h"
#import "MainCollectionView.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceEntity.h"
#import "MainCollectionViewCell.h"
#import "SingleDeviceModel.h"
#import "DeviceModelManager.h"
#import "ImproveTouchingExperience.h"
#import "ControlMaskView.h"
#import "CSRUtilities.h"
#import "CSRAreaEntity.h"
#import "SceneEntity.h"
#import "SceneListSModel.h"
#import "GroupListSModel.h"
#import "DeviceViewController.h"

#import "CSRDatabaseManager.h"
#import "PureLayout.h"
#import "CurtainViewController.h"
#import "FanViewController.h"
#import "TwoChannelDimmerVC.h"
#import "DeviceModelManager.h"
#import "TwoChannelSwitchVC.h"
#import "SocketViewController.h"

#import "SelectModel.h"

@interface DeviceListViewController ()<MainCollectionViewDelegate>

@property (nonatomic,strong) MainCollectionView *devicesCollectionView;
@property (nonatomic,strong) NSMutableArray *selectedDevices;
@property (nonatomic,copy) DeviceListSelectedHandle handle;
@property (nonatomic,strong) NSNumber *originalLevel;
@property (nonatomic,strong) ImproveTouchingExperience *improver;
@property (nonatomic,strong) ControlMaskView *maskLayer;

@property (nonatomic,strong) UIView *curtainKindView;
@property (nonatomic,strong) NSNumber *selectedCurtainDeviceId;
@property (nonatomic,strong) UIView *translucentBgView;

@property (nonatomic,strong) UIView *channelsSelectedView;
@property (nonatomic,strong) NSNumber *channelCurrentDeviceID;

@end

@implementation DeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.hidden = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Select", @"Localizable");
    self.view.backgroundColor = [UIColor colorWithRed:195/255.0 green:195/255.0 blue:195/255.0 alpha:1];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.bounds = CGRectMake(0, 0, 80, 40);
    [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
    [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
    [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [btn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = back;
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(finishSelectingDevice)];
    self.navigationItem.rightBarButtonItem = done;
    if (self.selectMode == DeviceListSelectMode_ForDrop) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    _selectedDevices = [[NSMutableArray alloc] init];
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = WIDTH*8.0/640.0;
    flowLayout.minimumInteritemSpacing = WIDTH*8.0/640.0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, floor(WIDTH*3/160.0));
    flowLayout.itemSize = CGSizeMake(floor(WIDTH*5/16.0),floor(WIDTH*9/32.0));
    
    _devicesCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout cellIdentifier:@"MainCollectionViewCell"];
    _devicesCollectionView.mainDelegate = self;
    
    if (self.selectMode == DeviceListSelectMode_ForGroup) {
        
        NSMutableArray *deviceIds = [[NSMutableArray alloc] init];
        NSSet *areas =  [CSRAppStateManager sharedInstance].selectedPlace.areas;
        for (CSRAreaEntity *area in areas) {
            if ([area.devices count]>0) {
                for (CSRDeviceEntity *device in area.devices) {
                    if ([_originalMembers count]>0) {
                        __block BOOL exist = NO;
                        [_originalMembers enumerateObjectsUsingBlock:^(SelectModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([sMod.deviceID isEqualToNumber:device.deviceId]) {
                                exist = YES;
                                *stop = YES;
                            }
                        }];
                        if (!exist) {
                            [deviceIds addObject:device.deviceId];
                        }
                    }else {
                        [deviceIds addObject:device.deviceId];
                    }
                }
            }
        }
        
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if ([mutableArray count]>0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            
            for (CSRDeviceEntity *device in mutableArray) {
                if (([kDimmers containsObject:device.shortName] || [kSwitchs containsObject:device.shortName] || [kCWDevices containsObject:device.shortName] || [kRGBDevices containsObject:device.shortName] || [kRGBCWDevices containsObject:device.shortName] || [kOneChannelCurtainController containsObject:device.shortName] || [kTwoChannelCurtainController containsObject:device.shortName] || [kFanController containsObject:device.shortName] || [kSockets containsObject:device.shortName] || [kTwoChannelDimmers containsObject:device.shortName] || [kTwoChannelSwitchs containsObject:device.shortName]) && ![deviceIds containsObject:device.deviceId]) {
                    SingleDeviceModel *model = [[SingleDeviceModel alloc] init];
                    model.deviceId = device.deviceId;
                    model.deviceName = device.name;
                    model.deviceShortName = device.shortName;
                    model.isForList = YES;
                    if ([_originalMembers count]>0) {
                        __block BOOL exist = NO;
                        [_originalMembers enumerateObjectsUsingBlock:^(SelectModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([sMod.deviceID isEqualToNumber:device.deviceId]) {
                                exist = YES;
                                [_selectedDevices addObject:sMod];
                                *stop = YES;
                            }
                        }];
                        if (exist) {
                            model.isSelected = YES;
                        }else {
                            model.isSelected = NO;
                        }
                    }else {
                        model.isSelected = NO;
                    }
                    [_devicesCollectionView.dataArray addObject:model];
                }
            }
        }
        
    }else if (self.selectMode == DeviceListSelectMode_SelectGroup) {
        
        NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
        if ([areaMutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [areaMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            
            for (CSRAreaEntity *area in areaMutableArray) {
                GroupListSModel *model = [[GroupListSModel alloc] init];
                model.areaIconNum = area.areaIconNum;
                model.areaID = area.areaID;
                model.areaName = area.areaName;
                model.areaImage = area.areaImage;
                model.sortId = area.sortId;
                model.devices = area.devices;
                model.isForList = YES;
                if ([_originalMembers count]>0) {
                    __block BOOL exist = NO;
                    [_originalMembers enumerateObjectsUsingBlock:^(SelectModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([sMod.deviceID isEqualToNumber:area.areaID]) {
                            exist = YES;
                            [_selectedDevices addObject:sMod];
                            *stop = YES;
                        }
                    }];
                    if (exist) {
                        model.isSelected = YES;
                    }else {
                        model.isSelected = NO;
                    }
                }else {
                    model.isSelected = NO;
                }
                
                [_devicesCollectionView.dataArray addObject:model];
            }
        }
        
    }else if (self.selectMode == DeviceListSelectMode_SelectScene) {
        
        NSMutableArray *sceneMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.scenes allObjects] mutableCopy];
        if ([sceneMutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sceneID" ascending:YES];
            [sceneMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            for (SceneEntity *scene in sceneMutableArray) {
                SceneListSModel *model = [[SceneListSModel alloc] init];
                model.sceneId = scene.sceneID;
                model.iconId = scene.iconID;
                model.sceneName = scene.sceneName;
                model.memnbers = scene.members;
                model.rcIndex = scene.rcIndex;
                if ([_originalMembers count]>0) {
                    __block BOOL exist = NO;
                    [_originalMembers enumerateObjectsUsingBlock:^(SelectModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([sMod.channel isEqualToNumber:scene.rcIndex]) {
                            exist = YES;
                            [_selectedDevices addObject:sMod];
                            *stop = YES;
                        }
                    }];
                    if (exist) {
                        model.isSelected = YES;
                    }else {
                        model.isSelected = NO;
                    }
                }else {
                    model.isSelected = NO;
                }
                [_devicesCollectionView.dataArray addObject:model];
            }
        }
        
    }else if (self.selectMode == DeviceListSelectMode_ForLightSensor) {
        NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
        if ([areaMutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [areaMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            
            for (CSRAreaEntity *area in areaMutableArray) {
                if ([area.devices count]>0) {
                    __block BOOL exist = NO;
                    [area.devices enumerateObjectsUsingBlock:^(CSRDeviceEntity  *deviceEntity, BOOL * _Nonnull stop) {
                        if (![deviceEntity.shortName isEqualToString:@"D1-10IB"]&&![deviceEntity.shortName isEqualToString:@"D0/1-10IB"]&&![deviceEntity.shortName isEqualToString:@"D1-10VIBH"]) {
                            exist = YES;
                            *stop = YES;
                        }
                    }];
                    if (!exist) {
                        GroupListSModel *model = [[GroupListSModel alloc] init];
                        model.areaIconNum = area.areaIconNum;
                        model.areaID = area.areaID;
                        model.areaName = area.areaName;
                        model.areaImage = area.areaImage;
                        model.sortId = area.sortId;
                        model.devices = area.devices;
                        model.isForList = YES;
                        
                        if ([_originalMembers count]>0) {
                            __block BOOL exist = NO;
                            [_originalMembers enumerateObjectsUsingBlock:^(SelectModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([sMod.deviceID isEqualToNumber:area.areaID]) {
                                    exist = YES;
                                    [_selectedDevices addObject:sMod];
                                    *stop = YES;
                                }
                            }];
                            if (exist) {
                                model.isSelected = YES;
                            }else {
                                model.isSelected = NO;
                            }
                        }else {
                            model.isSelected = NO;
                        }
                        
                        [_devicesCollectionView.dataArray addObject:model];
                    }
                }
            }
        }
        
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if ([mutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([deviceEntity.shortName isEqualToString:@"D1-10IB"]||[deviceEntity.shortName isEqualToString:@"D0/1-10IB"]||[deviceEntity.shortName isEqualToString:@"D1-10VIBH"]) {
                    SingleDeviceModel *singleDevice = [[SingleDeviceModel alloc] init];
                    singleDevice.deviceId = deviceEntity.deviceId;
                    singleDevice.deviceName = deviceEntity.name;
                    singleDevice.deviceShortName = deviceEntity.shortName;
                    singleDevice.isForList = YES;
                    if ([_originalMembers count]>0) {
                        __block BOOL exist = NO;
                        [_originalMembers enumerateObjectsUsingBlock:^(SelectModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([sMod.deviceID isEqualToNumber:deviceEntity.deviceId]) {
                                exist = YES;
                                [_selectedDevices addObject:sMod];
                                *stop = YES;
                            }
                        }];
                        if (exist) {
                            singleDevice.isSelected = YES;
                        }else {
                            singleDevice.isSelected = NO;
                        }
                    }else {
                        singleDevice.isSelected = NO;
                    }
                    [_devicesCollectionView.dataArray addObject:singleDevice];
                }
            }];
        }
        
    }else if (self.selectMode == DeviceListSelectMode_SelectRGBCWDevice) {
        NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
        if ([areaMutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [areaMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            for (CSRAreaEntity *area in areaMutableArray) {
                if ([area.devices count]>0) {
                    __block BOOL exist = NO;
                    [area.devices enumerateObjectsUsingBlock:^(CSRDeviceEntity  *deviceEntity, BOOL * _Nonnull stop) {
                        if (![CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
                            exist = YES;
                            *stop = YES;
                        }
                    }];
                    if (!exist) {
                        GroupListSModel *model = [[GroupListSModel alloc] init];
                        model.areaIconNum = area.areaIconNum;
                        model.areaID = area.areaID;
                        model.areaName = area.areaName;
                        model.areaImage = area.areaImage;
                        model.sortId = area.sortId;
                        model.devices = area.devices;
                        model.isForList = YES;
                        if ([_originalMembers count]>0) {
                            __block BOOL exist = NO;
                            [_originalMembers enumerateObjectsUsingBlock:^(SelectModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([sMod.deviceID isEqualToNumber:area.areaID]) {
                                    exist = YES;
                                    [_selectedDevices addObject:sMod];
                                    *stop = YES;
                                }
                            }];
                            if (exist) {
                                model.isSelected = YES;
                            }else {
                                model.isSelected = NO;
                            }
                        }else {
                            model.isSelected = NO;
                        }
                        [_devicesCollectionView.dataArray addObject:model];
                    }
                }
            }
        }
        
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if ([mutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
                    SingleDeviceModel *singleDevice = [[SingleDeviceModel alloc] init];
                    singleDevice.deviceId = deviceEntity.deviceId;
                    singleDevice.deviceName = deviceEntity.name;
                    singleDevice.deviceShortName = deviceEntity.shortName;
                    singleDevice.isForList = YES;
                    if ([_originalMembers count]>0) {
                        __block BOOL exist = NO;
                        [_originalMembers enumerateObjectsUsingBlock:^(SelectModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([sMod.deviceID isEqualToNumber:deviceEntity.deviceId]) {
                                exist = YES;
                                [_selectedDevices addObject:sMod];
                                *stop = YES;
                            }
                        }];
                        if (exist) {
                            singleDevice.isSelected = YES;
                        }else {
                            singleDevice.isSelected = NO;
                        }
                    }else {
                        singleDevice.isSelected = NO;
                    }
                    [_devicesCollectionView.dataArray addObject:singleDevice];
                }
            }];
        }
    }else if (self.selectMode == DeviceListSelectMode_SelectRGBDevice) {
        NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
        if ([areaMutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [areaMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            for (CSRAreaEntity *area in areaMutableArray) {
                if ([area.devices count]>0) {
                    __block BOOL exist = NO;
                    [area.devices enumerateObjectsUsingBlock:^(CSRDeviceEntity  *deviceEntity, BOOL * _Nonnull stop) {
                        if (![CSRUtilities belongToRGBDevice:deviceEntity.shortName] && ![CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
                            exist = YES;
                            *stop = YES;
                        }
                    }];
                    if (!exist) {
                        GroupListSModel *model = [[GroupListSModel alloc] init];
                        model.areaIconNum = area.areaIconNum;
                        model.areaID = area.areaID;
                        model.areaName = area.areaName;
                        model.areaImage = area.areaImage;
                        model.sortId = area.sortId;
                        model.devices = area.devices;
                        model.isForList = YES;
                        if ([_originalMembers count]>0) {
                            __block BOOL exist = NO;
                            [_originalMembers enumerateObjectsUsingBlock:^(SelectModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([sMod.deviceID isEqualToNumber:area.areaID]) {
                                    exist = YES;
                                    [_selectedDevices addObject:sMod];
                                    *stop = YES;
                                }
                            }];
                            if (exist) {
                                model.isSelected = YES;
                            }else {
                                model.isSelected = NO;
                            }
                        }else {
                            model.isSelected = NO;
                        }
                        [_devicesCollectionView.dataArray addObject:model];
                    }
                }
            }
        }
        
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if ([mutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([CSRUtilities belongToRGBDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
                    SingleDeviceModel *singleDevice = [[SingleDeviceModel alloc] init];
                    singleDevice.deviceId = deviceEntity.deviceId;
                    singleDevice.deviceName = deviceEntity.name;
                    singleDevice.deviceShortName = deviceEntity.shortName;
                    singleDevice.isForList = YES;
                    if ([_originalMembers count]>0) {
                        __block BOOL exist = NO;
                        [_originalMembers enumerateObjectsUsingBlock:^(SelectModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([sMod.deviceID isEqualToNumber:deviceEntity.deviceId]) {
                                exist = YES;
                                [_selectedDevices addObject:sMod];
                                *stop = YES;
                            }
                        }];
                        if (exist) {
                            singleDevice.isSelected = YES;
                        }else {
                            singleDevice.isSelected = NO;
                        }
                    }else {
                        singleDevice.isSelected = NO;
                    }
                    [_devicesCollectionView.dataArray addObject:singleDevice];
                }
            }];
        }
    }else if (self.selectMode == DeviceListSelectMode_SelectCWDevice) {
        NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
        if ([areaMutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [areaMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            for (CSRAreaEntity *area in areaMutableArray) {
                if ([area.devices count]>0) {
                    __block BOOL exist = NO;
                    [area.devices enumerateObjectsUsingBlock:^(CSRDeviceEntity  *deviceEntity, BOOL * _Nonnull stop) {
                        if (![CSRUtilities belongToCWDevice:deviceEntity.shortName] && ![CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
                            exist = YES;
                            *stop = YES;
                        }
                    }];
                    if (!exist) {
                        GroupListSModel *model = [[GroupListSModel alloc] init];
                        model.areaIconNum = area.areaIconNum;
                        model.areaID = area.areaID;
                        model.areaName = area.areaName;
                        model.areaImage = area.areaImage;
                        model.sortId = area.sortId;
                        model.devices = area.devices;
                        model.isForList = YES;
                        if ([_originalMembers count]>0) {
                            __block BOOL exist = NO;
                            [_originalMembers enumerateObjectsUsingBlock:^(SelectModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([sMod.deviceID isEqualToNumber:area.areaID]) {
                                    exist = YES;
                                    [_selectedDevices addObject:sMod];
                                    *stop = YES;
                                }
                            }];
                            if (exist) {
                                model.isSelected = YES;
                            }else {
                                model.isSelected = NO;
                            }
                        }else {
                            model.isSelected = NO;
                        }
                        [_devicesCollectionView.dataArray addObject:model];
                    }
                }
            }
        }
        
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if ([mutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([CSRUtilities belongToCWDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
                    SingleDeviceModel *singleDevice = [[SingleDeviceModel alloc] init];
                    singleDevice.deviceId = deviceEntity.deviceId;
                    singleDevice.deviceName = deviceEntity.name;
                    singleDevice.deviceShortName = deviceEntity.shortName;
                    singleDevice.isForList = YES;
                    if ([_originalMembers count]>0) {
                        __block BOOL exist = NO;
                        [_originalMembers enumerateObjectsUsingBlock:^(SelectModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([sMod.deviceID isEqualToNumber:deviceEntity.deviceId]) {
                                exist = YES;
                                [_selectedDevices addObject:sMod];
                                *stop = YES;
                            }
                        }];
                        if (exist) {
                            singleDevice.isSelected = YES;
                        }else {
                            singleDevice.isSelected = NO;
                        }
                    }else {
                        singleDevice.isSelected = NO;
                    }
                    [_devicesCollectionView.dataArray addObject:singleDevice];
                }
            }];
        }
    }else {
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if ([mutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            
            for (CSRDeviceEntity *device in mutableArray) {
                if ([kDimmers containsObject:device.shortName] || [kSwitchs containsObject:device.shortName] || [kCWDevices containsObject:device.shortName] || [kRGBDevices containsObject:device.shortName] || [kRGBCWDevices containsObject:device.shortName] || [kOneChannelCurtainController containsObject:device.shortName] || [kTwoChannelCurtainController containsObject:device.shortName] || [kFanController containsObject:device.shortName] || [kSockets containsObject:device.shortName] || [kTwoChannelDimmers containsObject:device.shortName] || [kTwoChannelSwitchs containsObject:device.shortName]) {
                    SingleDeviceModel *model = [[SingleDeviceModel alloc] init];
                    model.deviceId = device.deviceId;
                    model.deviceName = device.name;
                    model.deviceShortName = device.shortName;
                    model.isForList = YES;
                    if ([_originalMembers count]>0) {
                        __block BOOL exist = NO;
                        [_originalMembers enumerateObjectsUsingBlock:^(SelectModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([sMod.deviceID isEqualToNumber:device.deviceId]) {
                                exist = YES;
                                [_selectedDevices addObject:sMod];
                                *stop = YES;
                            }
                        }];
                        if (exist) {
                            model.isSelected = YES;
                        }else {
                            model.isSelected = NO;
                        }
                    }else {
                        model.isSelected = NO;
                    }
                    
                    [_devicesCollectionView.dataArray addObject:model];
                }
            }
        }
    }
    
    [self.view addSubview:_devicesCollectionView];
    [_devicesCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint * main_top;
    if (@available(iOS 11.0, *)) {
        main_top = [NSLayoutConstraint constraintWithItem:_devicesCollectionView
                                                attribute:NSLayoutAttributeTop
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self.view.safeAreaLayoutGuide
                                                attribute:NSLayoutAttributeTop
                                               multiplier:1.0
                                                 constant:WIDTH*3/160.0];
    } else {
        main_top = [NSLayoutConstraint constraintWithItem:_devicesCollectionView
                                                attribute:NSLayoutAttributeTop
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self.view
                                                attribute:NSLayoutAttributeTop
                                               multiplier:1.0
                                                 constant:WIDTH*3/160.0+64.0];
    }
    NSLayoutConstraint * main_left = [NSLayoutConstraint constraintWithItem:_devicesCollectionView
                                                                  attribute:NSLayoutAttributeLeft
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeLeft
                                                                 multiplier:1.0
                                                                   constant:WIDTH*3/160.0];
    NSLayoutConstraint * main_right = [NSLayoutConstraint constraintWithItem:_devicesCollectionView
                                                                   attribute:NSLayoutAttributeRight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeRight
                                                                  multiplier:1.0
                                                                    constant:0];
    NSLayoutConstraint * main_bottom = [NSLayoutConstraint constraintWithItem:_devicesCollectionView
                                                                    attribute:NSLayoutAttributeBottom
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:0];
    
    [NSLayoutConstraint  activateConstraints:@[main_top,main_left,main_bottom,main_right]];
    
    
    self.improver = [[ImproveTouchingExperience alloc] init];
}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)removeOtherSeletedDevice:(NSNumber *)deviceID {
    [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell * enCell, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![enCell.deviceId isEqualToNumber:deviceID] && enCell.seleteButton.selected) {
            enCell.seleteButton.selected = NO;
            [_devicesCollectionView.dataArray enumerateObjectsUsingBlock:^(SingleDeviceModel  *device, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([device.deviceId isEqualToNumber:enCell.deviceId]) {
                    device.isSelected = NO;
                    *stop = YES;
                }
            }];
            [_selectedDevices enumerateObjectsUsingBlock:^(SelectModel *mod, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([mod.deviceID isEqualToNumber:enCell.deviceId]) {
                    [_selectedDevices removeObject:mod];
                    *stop = YES;
                }
            }];
        }
    }];
}

- (void)mainCollectionViewDelegateSelectAction:(id)cell {
    
    if ([cell isKindOfClass:[MainCollectionViewCell class]]) {
        MainCollectionViewCell *mainCell = (MainCollectionViewCell *)cell;
        [_devicesCollectionView.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[SingleDeviceModel class]]) {
                SingleDeviceModel *sMod = (SingleDeviceModel *)obj;
                if ([sMod.deviceId isEqualToNumber:mainCell.deviceId]) {
                    sMod.isSelected = mainCell.seleteButton.selected;
                    *stop = YES;
                }
            }else if ([obj isKindOfClass:[GroupListSModel class]]) {
                GroupListSModel *gMod = (GroupListSModel *)obj;
                if ([gMod.areaID isEqualToNumber:mainCell.groupId]) {
                    gMod.isSelected = mainCell.seleteButton.selected;
                    *stop = YES;
                }
            }else if ([obj isKindOfClass:[SceneListSModel class]]) {
                SceneListSModel *sMod = (SceneListSModel *)obj;
                if ([sMod.rcIndex isEqualToNumber:mainCell.rcIndex]) {
                    sMod.isSelected = mainCell.seleteButton.selected;
                    *stop = YES;
                }
            }
        }];
        
        if (mainCell.seleteButton.selected) {
            if (_selectMode == DeviceListSelectMode_SelectGroup) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.deviceID = mainCell.groupId;
                mod.channel = @(32);
                mod.sourceID = _sourceID;
                [_selectedDevices addObject:mod];
                [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell * enCell, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (![enCell.groupId isEqualToNumber:mainCell.groupId] && enCell.seleteButton.selected) {
                        enCell.seleteButton.selected = NO;
                        [_devicesCollectionView.dataArray enumerateObjectsUsingBlock:^(GroupListSModel  *gMod, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([gMod.areaID isEqualToNumber:enCell.groupId]) {
                                gMod.isSelected = NO;
                                *stop = YES;
                            }
                        }];
                        [_selectedDevices enumerateObjectsUsingBlock:^(SelectModel *mod, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([mod.deviceID isEqualToNumber:enCell.groupId]) {
                                [_selectedDevices removeObject:mod];
                                *stop = YES;
                            }
                        }];
                    }
                }];
            }else if (_selectMode == DeviceListSelectMode_SelectScene) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.deviceID = @(0);
                mod.channel = mainCell.rcIndex;
                mod.sourceID = _sourceID;
                [_selectedDevices addObject:mod];
                [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell * enCell, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (![enCell.rcIndex isEqualToNumber:mainCell.rcIndex] && enCell.seleteButton.selected) {
                        enCell.seleteButton.selected = NO;
                        [_devicesCollectionView.dataArray enumerateObjectsUsingBlock:^(SceneListSModel  *sMod, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([sMod.rcIndex isEqualToNumber:enCell.rcIndex]) {
                                sMod.isSelected = NO;
                                *stop = YES;
                            }
                        }];
                        [_selectedDevices enumerateObjectsUsingBlock:^(SelectModel *mod, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([mod.channel isEqualToNumber:enCell.rcIndex]) {
                                [_selectedDevices removeObject:mod];
                                *stop = YES;
                            }
                        }];
                    }
                }];
            }else if (_selectMode == DeviceListSelectMode_ForGroup) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.deviceID = mainCell.deviceId;
                mod.channel = @(1);
                mod.sourceID = _sourceID;
                [_selectedDevices addObject:mod];
            }else if (_selectMode == DeviceListSelectMode_ForLightSensor
                      || _selectMode == DeviceListSelectMode_SelectRGBCWDevice
                      || _selectMode == DeviceListSelectMode_SelectRGBDevice
                      || _selectMode == DeviceListSelectMode_SelectCWDevice) {
                SelectModel *mod = [[SelectModel alloc] init];
                if ([mainCell.deviceId isEqualToNumber:@2000]) {
                    mod.deviceID = mainCell.groupId;
                    mod.channel = @(32);
                }else {
                    mod.deviceID = mainCell.deviceId;
                    mod.channel = @(1);
                }
                mod.sourceID = _sourceID;
                [_selectedDevices addObject:mod];
                
                [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell * enCell, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([mainCell.deviceId isEqualToNumber:@2000]) {
                        if (![enCell.groupId isEqualToNumber:mainCell.groupId] && enCell.seleteButton.selected) {
                            enCell.seleteButton.selected = NO;
                            [_devicesCollectionView.dataArray enumerateObjectsUsingBlock:^(GroupListSModel  *gMod, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([gMod.areaID isEqualToNumber:enCell.groupId]) {
                                    gMod.isSelected = NO;
                                    *stop = YES;
                                }
                            }];
                            [_selectedDevices enumerateObjectsUsingBlock:^(SelectModel *mod, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([mod.deviceID isEqualToNumber:enCell.groupId]) {
                                    [_selectedDevices removeObject:mod];
                                    *stop = YES;
                                }
                            }];
                        }
                    }else {
                        if (![enCell.deviceId isEqualToNumber:mainCell.deviceId] && enCell.seleteButton.selected) {
                            enCell.seleteButton.selected = NO;
                            [_devicesCollectionView.dataArray enumerateObjectsUsingBlock:^(SingleDeviceModel  *device, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([device.deviceId isEqualToNumber:enCell.deviceId]) {
                                    device.isSelected = NO;
                                    *stop = YES;
                                }
                            }];
                            [_selectedDevices enumerateObjectsUsingBlock:^(SelectModel *mod, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([mod.deviceID isEqualToNumber:enCell.deviceId]) {
                                    [_selectedDevices removeObject:mod];
                                    *stop = YES;
                                }
                            }];
                        }
                    }
                }];
                
            }else {
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:mainCell.deviceId];
                if ([CSRUtilities belongToSocketTwoChannel:deviceEntity.shortName]
                    || [CSRUtilities belongToTwoChannelDimmer:deviceEntity.shortName]
                    || [CSRUtilities belongToTwoChannelSwitch:deviceEntity.shortName]
                    || [CSRUtilities belongToTwoChannelCurtainController:deviceEntity.shortName]
                    || [CSRUtilities belongToFanController:deviceEntity.shortName]) {
                    _channelCurrentDeviceID = mainCell.deviceId;
                    [self.view addSubview:self.translucentBgView];
                    [self.view addSubview:self.channelsSelectedView];
                    [self.channelsSelectedView autoCenterInSuperview];
                    [self.channelsSelectedView autoSetDimensionsToSize:CGSizeMake(271, 166)];
                    if (_selectMode == DeviceListSelectMode_Single || _selectMode == DeviceListSelectMode_ForDrop) {
                        [self removeOtherSeletedDevice:mainCell.deviceId];
                    }
                }else {
                    SelectModel *mod = [[SelectModel alloc] init];
                    mod.deviceID = mainCell.deviceId;
                    mod.channel = @1;
                    mod.sourceID = _sourceID;
                    
                    [_selectedDevices addObject:mod];
                    if (_selectMode == DeviceListSelectMode_Single || _selectMode == DeviceListSelectMode_ForDrop) {
                        [self removeOtherSeletedDevice:mainCell.deviceId];
                    }
                }
            }
        }else {
            [_selectedDevices enumerateObjectsUsingBlock:^(SelectModel *mod, NSUInteger idx, BOOL * _Nonnull stop) {
                if (_selectMode == DeviceListSelectMode_SelectGroup) {
                    if ([mod.deviceID isEqualToNumber:mainCell.groupId]) {
                        [_selectedDevices removeObject:mod];
                        *stop = YES;
                    }
                }else if (_selectMode == DeviceListSelectMode_SelectScene) {
                    if ([mod.channel isEqualToNumber:mainCell.rcIndex]) {
                        [_selectedDevices removeObject:mod];
                        *stop = YES;
                    }
                }else {
                    if ([mod.deviceID isEqualToNumber:mainCell.deviceId]) {
                        [_selectedDevices removeObject:mod];
                        *stop = YES;
                    }
                }
            }];
        }
    }
    if (self.selectMode == DeviceListSelectMode_ForDrop) {
        if ([self.selectedDevices count]>0) {
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }else {
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    }
}

- (void)finishSelectingDevice {
    if (self.handle) {
        self.handle(self.selectedDevices);
        self.handle = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}

- (void)getSelectedDevices:(DeviceListSelectedHandle)handle {
    self.handle = nil;
    self.handle = handle;
}


#pragma mark - MainCollectionViewDelegate

- (void)mainCollectionViewDelegatePanBrightnessWithTouchPoint:(CGPoint)touchPoint withOrigin:(CGPoint)origin toLight:(NSNumber *)deviceId groupId:(NSNumber *)groupId withPanState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
    if (state == UIGestureRecognizerStateBegan) {
        self.originalLevel = model.level;
        [self.improver beginImproving];
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:deviceId channel:@1 withLevel:self.originalLevel withState:state direction:direction];
        return;
    }
    if (state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateEnded) {
        NSInteger updateLevel = [self.improver improveTouching:touchPoint referencePoint:origin primaryBrightness:[self.originalLevel integerValue]];

        CGFloat percentage = updateLevel/255.0*100;
        [self showControlMaskLayerWithAlpha:updateLevel/255.0 text:[NSString stringWithFormat:@"%.f",percentage]];

        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:deviceId channel:@1 withLevel:@(updateLevel) withState:state direction:direction];
        
        if (state == UIGestureRecognizerStateEnded) {
            [self hideControlMaskLayer];
        }
        return;
    }
}

- (void)mainCollectionViewDelegateLongPressAction:(id)cell {
    MainCollectionViewCell *mainCell = (MainCollectionViewCell *)cell;
    if ([mainCell.groupId isEqualToNumber:@2000]) {
        
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:mainCell.deviceId];
        if ([CSRUtilities belongToRGBDevice:deviceEntity.shortName]||[CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
                DeviceViewController *dvc = [[DeviceViewController alloc] init];
                dvc.deviceId = mainCell.deviceId;
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:dvc];
                nav.modalPresentationStyle = UIModalPresentationPopover;
                nav.popoverPresentationController.sourceRect = mainCell.bounds;
                nav.popoverPresentationController.sourceView = mainCell;
            
                [self presentViewController:nav animated:YES completion:nil];
        }else if ([CSRUtilities belongToCurtainController:deviceEntity.shortName]) {
            
            if (!deviceEntity.remoteBranch || deviceEntity.remoteBranch.length == 0) {
                _selectedCurtainDeviceId = mainCell.deviceId;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
                    [[UIApplication sharedApplication].keyWindow addSubview:self.curtainKindView];
                    [self.curtainKindView autoCenterInSuperview];
                    [self.curtainKindView autoSetDimensionsToSize:CGSizeMake(271, 165)];
                });
            }else {
                CurtainViewController *curtainVC = [[CurtainViewController alloc] init];
                curtainVC.deviceId = mainCell.deviceId;
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:curtainVC];
                nav.modalPresentationStyle = UIModalPresentationPopover;
                [self presentViewController:nav animated:YES completion:nil];
                nav.popoverPresentationController.sourceRect = mainCell.bounds;
                nav.popoverPresentationController.sourceView = mainCell;
            }
            
        }else if ([CSRUtilities belongToFanController:deviceEntity.shortName]) {
            FanViewController *fanVC = [[FanViewController alloc] init];
            fanVC.deviceId = mainCell.deviceId;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:fanVC];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
            
        }else if ([CSRUtilities belongToTwoChannelDimmer:deviceEntity.shortName]) {
            TwoChannelDimmerVC *TDVC = [[TwoChannelDimmerVC alloc] init];
            TDVC.deviceId = mainCell.deviceId;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:TDVC];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
        }else if ([CSRUtilities belongToTwoChannelSwitch:deviceEntity.shortName]) {
            TwoChannelSwitchVC *tsvc = [[TwoChannelSwitchVC alloc] init];
            tsvc.deviceId = mainCell.deviceId;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:tsvc];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
        }else if ([CSRUtilities belongToSocket:deviceEntity.shortName]) {
            SocketViewController *socketVC = [[SocketViewController alloc] init];
            socketVC.deviceId = mainCell.deviceId;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:socketVC];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
        }else{
            DeviceViewController *dvc = [[DeviceViewController alloc] init];
            dvc.deviceId = mainCell.deviceId;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:dvc];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
        }
        
    }
}

- (void)hideControlMaskLayer {
    if (_maskLayer && _maskLayer.superview) {
        [self.maskLayer removeFromSuperview];
    }
}

- (void)showControlMaskLayerWithAlpha:(CGFloat)percentage text:(NSString*)text {
    if (!_maskLayer.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:self.maskLayer];
    }
    [self.maskLayer updateProgress:percentage withText:text];
}

#pragma mark - lazy

- (ControlMaskView*)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [[ControlMaskView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _maskLayer;
}

- (UIView *)translucentBgView {
    if (!_translucentBgView) {
        _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _translucentBgView.backgroundColor = [UIColor blackColor];
        _translucentBgView.alpha = 0.4;
    }
    return _translucentBgView;
}

- (UIView *)channelsSelectedView {
    if (!_channelsSelectedView) {
        _channelsSelectedView = [[UIView alloc] initWithFrame:CGRectZero];
        _channelsSelectedView.backgroundColor = [UIColor whiteColor];
        _channelsSelectedView.alpha = 0.9;
        _channelsSelectedView.layer.cornerRadius = 14;
        _channelsSelectedView.layer.masksToBounds = YES;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 271, 30)];
        titleLabel.text = AcTECLocalizedStringFromTable(@"Select", @"Localizable");
        titleLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [_channelsSelectedView addSubview:titleLabel];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 271, 1)];
        line.backgroundColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        [_channelsSelectedView addSubview:line];
        
        UIButton *allSelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 31, 271, 44)];
        [allSelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        [allSelectBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateSelected];
        [allSelectBtn setTitle:AcTECLocalizedStringFromTable(@"ChannelAll", @"Localizable") forState:UIControlStateNormal];
        [allSelectBtn setTitleColor:[UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1] forState:UIControlStateNormal];
        allSelectBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        allSelectBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        allSelectBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, -20);
        allSelectBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 40, 0, -40);
        allSelectBtn.tag = 1;
        [allSelectBtn addTarget:self action:@selector(channelsSelectedViewTouchDownAction:) forControlEvents:UIControlEventTouchDown];
        [allSelectBtn addTarget:self action:@selector(channelsSelectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpInside];
        [allSelectBtn addTarget:self action:@selector(channelsSelectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpOutside];
        [_channelsSelectedView addSubview:allSelectBtn];
        
        UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(60, 75, 211, 1)];
        line1.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
        [_channelsSelectedView addSubview:line1];
        
        UIButton *channel1SelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 76, 271, 44)];
        [channel1SelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        [channel1SelectBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateSelected];
        [channel1SelectBtn setTitle:AcTECLocalizedStringFromTable(@"Channel1", @"Localizable") forState:UIControlStateNormal];
        [channel1SelectBtn setTitleColor:[UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1] forState:UIControlStateNormal];
        channel1SelectBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        channel1SelectBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        channel1SelectBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, -20);
        channel1SelectBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 40, 0, -40);
        channel1SelectBtn.tag = 2;
        [channel1SelectBtn addTarget:self action:@selector(channelsSelectedViewTouchDownAction:) forControlEvents:UIControlEventTouchDown];
        [channel1SelectBtn addTarget:self action:@selector(channelsSelectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpInside];
        [channel1SelectBtn addTarget:self action:@selector(channelsSelectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpOutside];
        [_channelsSelectedView addSubview:channel1SelectBtn];
        
        UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(60, 120, 221, 1)];
        line2.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
        [_channelsSelectedView addSubview:line2];
        
        UIButton *channel2SelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 121, 271, 44)];
        [channel2SelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        [channel2SelectBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateSelected];
        [channel2SelectBtn setTitle:AcTECLocalizedStringFromTable(@"Channel2", @"Localizable") forState:UIControlStateNormal];
        [channel2SelectBtn setTitleColor:[UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1] forState:UIControlStateNormal];
        channel2SelectBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        channel2SelectBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        channel2SelectBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, -20);
        channel2SelectBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 40, 0, -40);
        channel2SelectBtn.tag = 3;
        [channel2SelectBtn addTarget:self action:@selector(channelsSelectedViewTouchDownAction:) forControlEvents:UIControlEventTouchDown];
        [channel2SelectBtn addTarget:self action:@selector(channelsSelectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpInside];
        [channel2SelectBtn addTarget:self action:@selector(channelsSelectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpOutside];
        [_channelsSelectedView addSubview:channel2SelectBtn];
    }
    return _channelsSelectedView;
}

- (void)channelsSelecteAction:(NSNumber *)channel {
    __block BOOL exist= NO;
    [_selectedDevices enumerateObjectsUsingBlock:^(SelectModel *mod, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([mod.deviceID isEqualToNumber:_channelCurrentDeviceID]) {
            exist = YES;
            mod.channel = channel;
            *stop = YES;
        }
    }];
    if (!exist) {
        SelectModel *mod = [[SelectModel alloc] init];
        mod.deviceID = _channelCurrentDeviceID;
        mod.channel = channel;
        mod.sourceID = _sourceID;
        [_selectedDevices addObject:mod];
    }
}

- (void)channelsSelectedViewTouchDownAction:(UIButton *)button {
    button.selected = !button.selected;
    switch (button.tag) {
        case 1:
            if (button.selected) {
                UIButton *channel1SelectBtn = (UIButton *)[button.superview viewWithTag:2];
                if (channel1SelectBtn.selected) {
                    channel1SelectBtn.selected = NO;
                }
                UIButton *channel2SelectBtn = (UIButton *)[button.superview viewWithTag:3];
                if (channel2SelectBtn.selected) {
                    channel2SelectBtn.selected = NO;
                }
                [self channelsSelecteAction:@(1)];
            }
            break;
        case 2:
            if (button.selected) {
                UIButton *allSelectBtn = (UIButton *)[button.superview viewWithTag:1];
                if (allSelectBtn.selected) {
                    allSelectBtn.selected = NO;
                }
                UIButton *channel2SelectBtn = (UIButton *)[button.superview viewWithTag:3];
                if (channel2SelectBtn.selected) {
                    channel2SelectBtn.selected = NO;
                }
                [self channelsSelecteAction:@(2)];
            }
            break;
        case 3:
            if (button.selected) {
                UIButton *allSelectBtn = (UIButton *)[button.superview viewWithTag:1];
                if (allSelectBtn.selected) {
                    allSelectBtn.selected = NO;
                }
                UIButton *channel1SelectBtn = (UIButton *)[button.superview viewWithTag:2];
                if (channel1SelectBtn.selected) {
                    channel1SelectBtn.selected = NO;
                }
                [self channelsSelecteAction:@(3)];
            }
            break;
        default:
            break;
    }
}

- (void)channelsSelectedViewTouchInsideAction:(UIButton *)button {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.channelsSelectedView removeFromSuperview];
        self.channelsSelectedView = nil;
        [self.translucentBgView removeFromSuperview];
        self.translucentBgView = nil;
        if (self.selectMode == DeviceListSelectMode_ForDrop) {
            if ([self.selectedDevices count]>0) {
                self.navigationItem.rightBarButtonItem.enabled = YES;
            }else {
                self.navigationItem.rightBarButtonItem.enabled = NO;
            }
        }
    });
}

@end
