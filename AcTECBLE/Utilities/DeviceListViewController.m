//
//  DeviceListViewController.m
//  AcTECBLE
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
#import "DeviceModelManager.h"
#import "SocketViewController.h"

#import "SelectModel.h"

#import "MusicControllerVC.h"
#import "SonosMusicControllerVC.h"
#import "SonosSelectModel.h"
#import "SonosSceneSettingVC.h"


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

@property (nonatomic,strong) NSNumber *channelCurrentDeviceID;

@property (nonatomic, strong) UIView *twoChannelSelectedView;

@property (nonatomic, strong) UIView *threeChannelSelectedView;

@property (nonatomic, strong) UIView *mcChannelSelectedView;
@property (nonatomic, strong) UIView *mcSonosChannelSelectionView;

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
    flowLayout.minimumLineSpacing = 0;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.itemSize = CGSizeZero;
    
    _devicesCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout cellIdentifier:@"MainCollectionViewCell"];
    _devicesCollectionView.mainDelegate = self;
    
    [self loadData];
    
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

- (void)viewDidLayoutSubviews {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    CGFloat w = self.view.bounds.size.width;
    flowLayout.minimumLineSpacing = floor(w*8.0/640.0);
    flowLayout.minimumInteritemSpacing = floor(w*8.0/640.0);
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, floor(w*3/160.0));
    flowLayout.itemSize = CGSizeMake(w*5/16.0, w*9/32.0);
    _devicesCollectionView.collectionViewLayout = flowLayout;
}

- (void)loadData {
    [_devicesCollectionView.dataArray removeAllObjects];
    [_selectedDevices removeAllObjects];
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
                if (([kDimmers containsObject:device.shortName]
                     || [kSwitchs containsObject:device.shortName]
                     || [kCWDevices containsObject:device.shortName]
                     || [kRGBDevices containsObject:device.shortName]
                     || [kRGBCWDevices containsObject:device.shortName]
                     || [kOneChannelCurtainController containsObject:device.shortName]
                     || [kTwoChannelCurtainController containsObject:device.shortName]
                     || [kFanController containsObject:device.shortName]
                     || [kSocketsOneChannel containsObject:device.shortName]
                     || [kSocketsTwoChannel containsObject:device.shortName]
                     || [kTwoChannelDimmers containsObject:device.shortName]
                     || [kTwoChannelSwitchs containsObject:device.shortName]
                     || [kThreeChannelSwitchs containsObject:device.shortName]
                     || [kThreeChannelDimmers containsObject:device.shortName]
                     || [kHOneChannelCurtainController containsObject:device.shortName]
                     || [kDALIDeviceTwo containsObject:device.shortName])
                    && ![deviceIds containsObject:device.deviceId]) {
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
                if ([scene.srDeviceId integerValue]>0) {
                    
                }else {
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
    }else if (self.selectMode == DeviceListSelectMode_Multiple) {
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if ([mutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            
            for (CSRDeviceEntity *device in mutableArray) {
                if ([kDimmers containsObject:device.shortName]
                    || [kSwitchs containsObject:device.shortName]
                    || [kCWDevices containsObject:device.shortName]
                    || [kRGBDevices containsObject:device.shortName]
                    || [kRGBCWDevices containsObject:device.shortName]
                    || [kOneChannelCurtainController containsObject:device.shortName]
                    || [kTwoChannelCurtainController containsObject:device.shortName]
                    || [kFanController containsObject:device.shortName]
                    || [kSocketsOneChannel containsObject:device.shortName]
                    || [kSocketsTwoChannel containsObject:device.shortName]
                    || [kTwoChannelDimmers containsObject:device.shortName]
                    || [kTwoChannelSwitchs containsObject:device.shortName]
                    || [kThreeChannelSwitchs containsObject:device.shortName]
                    || [kMusicController containsObject:device.shortName]
                    || [kThreeChannelDimmers containsObject:device.shortName]
                    || [kHOneChannelCurtainController containsObject:device.shortName]
                    || [kSonosMusicController containsObject:device.shortName]
                    || [kDALIDeviceTwo containsObject:device.shortName]) {
                    
                    BOOL exist = NO;
                    for (SceneMemberEntity *m in self.originalMembers) {
                        if ([m.deviceID isEqualToNumber:device.deviceId]) {
                            exist = YES;
                            break;
                        }
                    }
                    
                    if (!exist) {
                        SingleDeviceModel *model = [[SingleDeviceModel alloc] init];
                        model.deviceId = device.deviceId;
                        model.deviceName = device.name;
                        model.deviceShortName = device.shortName;
                        model.curtainDirection = device.remoteBranch;
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
    }else if (self.selectMode == DeviceListSelectMode_MusicController) {
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if ([mutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            for (CSRDeviceEntity *deviceEntity in mutableArray) {
                if ([CSRUtilities belongToMusicController:deviceEntity.shortName]
                    || [CSRUtilities belongToSonosMusicController:deviceEntity.shortName]) {
                    SingleDeviceModel *singleDevice = [[SingleDeviceModel alloc] init];
                    singleDevice.deviceId = deviceEntity.deviceId;
                    singleDevice.deviceName = deviceEntity.name;
                    singleDevice.deviceShortName = deviceEntity.shortName;
                    singleDevice.isForList = YES;
                    singleDevice.isSelected = NO;
                    if ([_originalMembers count] > 0) {
                        for (SelectModel *sMod in _originalMembers) {
                            if ([sMod.deviceID isEqualToNumber:deviceEntity.deviceId]) {
                                singleDevice.isSelected = YES;
                                break;
                            }
                        }
                    }
                    [_devicesCollectionView.dataArray addObject:singleDevice];
                }
            }
        }
    }else if (self.selectMode == DeviceListSelectMode_SingleRegardlessChannelPlus) {
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if ([mutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            
            for (CSRDeviceEntity *device in mutableArray) {
                SingleDeviceModel *model = [[SingleDeviceModel alloc] init];
                model.deviceId = device.deviceId;
                model.deviceName = device.name;
                model.deviceShortName = device.shortName;
                model.isForList = YES;
                model.isSelected = NO;
                
                [_devicesCollectionView.dataArray addObject:model];
            }
        }
    }else {
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if ([mutableArray count] > 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            
            for (CSRDeviceEntity *device in mutableArray) {
                if ([kDimmers containsObject:device.shortName]
                    || [kSwitchs containsObject:device.shortName]
                    || [kCWDevices containsObject:device.shortName]
                    || [kRGBDevices containsObject:device.shortName]
                    || [kRGBCWDevices containsObject:device.shortName]
                    || [kOneChannelCurtainController containsObject:device.shortName]
                    || [kTwoChannelCurtainController containsObject:device.shortName]
                    || [kHOneChannelCurtainController containsObject:device.shortName]
                    || [kFanController containsObject:device.shortName]
                    || [kSocketsOneChannel containsObject:device.shortName]
                    || [kSocketsTwoChannel containsObject:device.shortName]
                    || [kTwoChannelDimmers containsObject:device.shortName]
                    || [kTwoChannelSwitchs containsObject:device.shortName]
                    || [kThreeChannelSwitchs containsObject:device.shortName]
                    || [kThreeChannelDimmers containsObject:device.shortName]
                    || [kDALIDeviceTwo containsObject:device.shortName]) {
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
}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)removeOtherSeletedDevice:(NSNumber *)deviceID {
    for (SingleDeviceModel *s in _devicesCollectionView.dataArray) {
        if ([s.deviceId isEqualToNumber:deviceID] && !s.isSelected) {
            s.isSelected = YES;
        }else if (![s.deviceId isEqualToNumber:deviceID] && s.isSelected) {
            s.isSelected = NO;
            for (SelectModel *m in _selectedDevices) {
                if ([m.deviceID isEqualToNumber:s.deviceId]) {
                    [_selectedDevices removeObject:m];
                    break;
                }
            }
        }
    }
    [_devicesCollectionView reloadData];
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
                for (GroupListSModel  *gMod in _devicesCollectionView.dataArray) {
                    if ([gMod.areaID isEqualToNumber:mainCell.groupId] && !gMod.isSelected) {
                        gMod.isSelected = YES;
                    }else if (![gMod.areaID isEqualToNumber:mainCell.groupId] && gMod.isSelected) {
                        gMod.isSelected = NO;
                        for (SelectModel *m in _selectedDevices) {
                            if ([m.deviceID isEqualToNumber:gMod.areaID]) {
                                [_selectedDevices removeObject:m];
                                break;
                            }
                        }
                    }
                }
                [_devicesCollectionView reloadData];
            }else if (_selectMode == DeviceListSelectMode_SelectScene) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.deviceID = @(0);
                mod.channel = mainCell.rcIndex;
                mod.sourceID = _sourceID;
                [_selectedDevices addObject:mod];
                for (SceneListSModel  *sMod in _devicesCollectionView.dataArray) {
                    if ([sMod.rcIndex isEqualToNumber:mainCell.rcIndex] && !sMod.isSelected) {
                        sMod.isSelected = YES;
                    }else if (![sMod.rcIndex isEqualToNumber:mainCell.rcIndex] && sMod.isSelected) {
                        sMod.isSelected = NO;
                        for (SelectModel *m in _selectedDevices) {
                            if ([m.channel isEqualToNumber:sMod.rcIndex]) {
                                [_selectedDevices removeObject:m];
                                break;
                            }
                        }
                    }
                }
                [_devicesCollectionView reloadData];
            }else if (_selectMode == DeviceListSelectMode_ForGroup) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.deviceID = mainCell.deviceId;
                mod.channel = @(1);
                mod.sourceID = _sourceID;
                [_selectedDevices addObject:mod];
                _originalMembers = [NSArray arrayWithArray:_selectedDevices];
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
                
                for (MainCollectionViewCell *eCell in _devicesCollectionView.visibleCells) {
                    if ([mainCell.deviceId isEqualToNumber:@2000]) {
                        if (![eCell.groupId isEqualToNumber:mainCell.groupId] && eCell.seleteButton.selected) {
                            eCell.seleteButton.selected = NO;
                            for (id obj in _devicesCollectionView.dataArray) {
                                if ([obj isKindOfClass:[GroupListSModel class]]) {
                                    GroupListSModel *gMod = (GroupListSModel *)obj;
                                    if ([gMod.areaID isEqualToNumber:eCell.groupId]) {
                                        gMod.isSelected = NO;
                                        break;
                                    }
                                }
                            }
                            for (SelectModel *mod in _selectedDevices) {
                                if ([mod.deviceID isEqualToNumber:eCell.groupId] || [mod.deviceID isEqualToNumber:eCell.deviceId]) {
                                    [_selectedDevices removeObject:mod];
                                    break;
                                }
                            }
                        }
                    }else {
                        if (![eCell.deviceId isEqualToNumber:mainCell.deviceId] && eCell.seleteButton.selected) {
                            eCell.seleteButton.selected = NO;
                            for (id obj in _devicesCollectionView.dataArray) {
                                if ([obj isKindOfClass:[SingleDeviceModel class]]) {
                                    SingleDeviceModel *device = (SingleDeviceModel *)obj;
                                    if ([device.deviceId isEqualToNumber:eCell.deviceId]) {
                                        device.isSelected = NO;
                                        break;
                                    }
                                }
                            }
                            for (SelectModel *mod in _selectedDevices) {
                                if ([mod.deviceID isEqualToNumber:eCell.deviceId] || [mod.deviceID isEqualToNumber:eCell.groupId]) {
                                    [_selectedDevices removeObject:mod];
                                    break;
                                }
                            }
                        }
                    }
                }
                
            }else if (_selectMode == DeviceListSelectMode_SingleRegardlessChannel
                      || _selectMode == DeviceListSelectMode_SingleRegardlessChannelPlus) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.deviceID = mainCell.deviceId;
                mod.channel = @1;
                mod.sourceID = _sourceID;
                
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:mainCell.deviceId];
                if ([CSRUtilities belongToSocketTwoChannel:deviceEntity.shortName]
                || [CSRUtilities belongToTwoChannelDimmer:deviceEntity.shortName]
                || [CSRUtilities belongToTwoChannelSwitch:deviceEntity.shortName]
                || [CSRUtilities belongToTwoChannelCurtainController:deviceEntity.shortName]
                    || [CSRUtilities belongToFanController:deviceEntity.shortName]) {
                    mod.channel = @4;
                }else if ([CSRUtilities belongToThreeChannelSwitch:deviceEntity.shortName]
                          || [CSRUtilities belongToThreeChannelDimmer:deviceEntity.shortName]) {
                    mod.channel = @8;
                }
                
                [_selectedDevices addObject:mod];
                [self removeOtherSeletedDevice:mainCell.deviceId];
            }else if (_selectMode == DeviceListSelectMode_MusicController) {
                CSRDeviceEntity *deviceE = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:mainCell.deviceId];
                if ([CSRUtilities belongToMusicController:deviceE.shortName]) {
                    _channelCurrentDeviceID = mainCell.deviceId;
                    [self.view addSubview:self.translucentBgView];
                    [self.view addSubview:self.mcChannelSelectedView];
                    [self.mcChannelSelectedView autoCenterInSuperview];
                    [self.mcChannelSelectedView autoSetDimensionsToSize:CGSizeMake(271, 165)];
                    [self removeOtherSeletedDevice:mainCell.deviceId];
                    self.navigationItem.rightBarButtonItem.enabled = NO;
                }else if ([CSRUtilities belongToSonosMusicController:deviceE.shortName]) {
                    if ([deviceE.sonoss count]>0) {
                        _channelCurrentDeviceID = mainCell.deviceId;
                        [self.view addSubview:self.translucentBgView];
                        [self.view addSubview:self.mcSonosChannelSelectionView];
                        [self.mcSonosChannelSelectionView autoCenterInSuperview];
                        [self.mcSonosChannelSelectionView autoSetDimensionsToSize:CGSizeMake(271, 31+[deviceE.sonoss count]*45+44)];
                        [self removeOtherSeletedDevice:mainCell.deviceId];
                        self.navigationItem.rightBarButtonItem.enabled = NO;
                    }else {
                        mainCell.seleteButton.selected = NO;
                    }
                }
                
            }else {
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:mainCell.deviceId];
                if ([CSRUtilities belongToSocketTwoChannel:deviceEntity.shortName]
                    || [CSRUtilities belongToTwoChannelDimmer:deviceEntity.shortName]
                    || [CSRUtilities belongToTwoChannelSwitch:deviceEntity.shortName]
                    || [CSRUtilities belongToTwoChannelCurtainController:deviceEntity.shortName]
                    || [CSRUtilities belongToFanController:deviceEntity.shortName]) {
                    _channelCurrentDeviceID = mainCell.deviceId;
                    [self.view addSubview:self.translucentBgView];
                    [self.view addSubview:self.twoChannelSelectedView];
                    [self.twoChannelSelectedView autoCenterInSuperview];
                    [self.twoChannelSelectedView autoSetDimensionsToSize:CGSizeMake(271, 166)];
                    if (_selectMode == DeviceListSelectMode_Single || _selectMode == DeviceListSelectMode_ForDrop) {
                        [self removeOtherSeletedDevice:mainCell.deviceId];
                    }
                }else if ([CSRUtilities belongToThreeChannelSwitch:deviceEntity.shortName]
                          || [CSRUtilities belongToThreeChannelDimmer:deviceEntity.shortName]) {
                    _channelCurrentDeviceID = mainCell.deviceId;
                    [self.view addSubview:self.translucentBgView];
                    [self.view addSubview:self.threeChannelSelectedView];
                    [self.threeChannelSelectedView autoCenterInSuperview];
                    [self.threeChannelSelectedView autoSetDimensionsToSize:CGSizeMake(271, 211)];
                    if (_selectMode == DeviceListSelectMode_Single || _selectMode == DeviceListSelectMode_ForDrop) {
                        [self removeOtherSeletedDevice:mainCell.deviceId];
                    }
                }else if ([CSRUtilities belongToSonosMusicController:deviceEntity.shortName]
                          || [CSRUtilities belongToMusicController:deviceEntity.shortName]) {
                    SonosSceneSettingVC *sss = [[SonosSceneSettingVC alloc] init];
                    sss.deviceID = deviceEntity.deviceId;
                    sss.sonosSceneSettingHandle = ^(NSArray * _Nonnull sModels) {
                        int i = 0;
                        for (SonosSelectModel *sModel in sModels) {
                            if (sModel.selected && ![_selectedDevices containsObject:sModel]) {
                                [_selectedDevices addObject:sModel];
                                i ++;
                            }
                        }
                        if (i==0) {
                            mainCell.seleteButton.selected = NO;
                        }
                    };
                    [self.navigationController pushViewController:sss animated:YES];
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
        if ([CSRUtilities belongToOneChannelCurtainController:deviceEntity.shortName]
            || [CSRUtilities belongToTwoChannelCurtainController:deviceEntity.shortName]
            || [CSRUtilities belongToHOneChannelCurtainController:deviceEntity.shortName]) {
            
            if (([CSRUtilities belongToOneChannelCurtainController:deviceEntity.shortName]
                || [CSRUtilities belongToTwoChannelCurtainController:deviceEntity.shortName])
                && deviceEntity.remoteBranch.length == 0) {
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
                curtainVC.reloadDataHandle = ^{
                    [self loadData];
                    [_devicesCollectionView reloadData];
                };
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:curtainVC];
                if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
                    nav.modalPresentationStyle = UIModalPresentationFullScreen;
                }else {
                    nav.modalPresentationStyle = UIModalPresentationPopover;
                }
                [self presentViewController:nav animated:YES completion:nil];
                nav.popoverPresentationController.sourceRect = mainCell.bounds;
                nav.popoverPresentationController.sourceView = mainCell;
            }
            
        }else if ([CSRUtilities belongToFanController:deviceEntity.shortName]) {
            FanViewController *fanVC = [[FanViewController alloc] init];
            fanVC.deviceId = mainCell.deviceId;
            fanVC.reloadDataHandle = ^{
                [self loadData];
                [_devicesCollectionView reloadData];
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:fanVC];
            if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
                nav.modalPresentationStyle = UIModalPresentationFullScreen;
            }else {
                nav.modalPresentationStyle = UIModalPresentationPopover;
            }
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
            
        }else if ([CSRUtilities belongToSocketOneChannel:deviceEntity.shortName]
                  || [CSRUtilities belongToSocketTwoChannel:deviceEntity.shortName]) {
            SocketViewController *socketVC = [[SocketViewController alloc] init];
            socketVC.deviceId = mainCell.deviceId;
            socketVC.reloadDataHandle = ^{
                [self loadData];
                [_devicesCollectionView reloadData];
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:socketVC];
            if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
                nav.modalPresentationStyle = UIModalPresentationFullScreen;
            }else {
                nav.modalPresentationStyle = UIModalPresentationPopover;
            }
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
        }else if ([CSRUtilities belongToMusicController:deviceEntity.shortName]) {
            MusicControllerVC *mcvc = [[MusicControllerVC alloc] init];
            mcvc.deviceId = mainCell.deviceId;
            mcvc.reloadDataHandle = ^{
                [self loadData];
                [_devicesCollectionView reloadData];
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mcvc];
            if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
                nav.modalPresentationStyle = UIModalPresentationFullScreen;
            }else {
                nav.modalPresentationStyle = UIModalPresentationPopover;
            }
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
        }else if ([CSRUtilities belongToSonosMusicController:deviceEntity.shortName]) {
            SonosMusicControllerVC *sonosVC = [[SonosMusicControllerVC alloc] init];
            sonosVC.deviceId = mainCell.deviceId;
            sonosVC.reloadDataHandle = ^{
                [self loadData];
                [_devicesCollectionView reloadData];
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:sonosVC];
            if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
                nav.modalPresentationStyle = UIModalPresentationFullScreen;
            }else {
                nav.modalPresentationStyle = UIModalPresentationPopover;
            }
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
        }else {
            DeviceViewController *dvc = [[DeviceViewController alloc] init];
            dvc.deviceId = mainCell.deviceId;
            dvc.reloadDataHandle = ^{
                [self loadData];
                [_devicesCollectionView reloadData];
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:dvc];
            if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
                nav.modalPresentationStyle = UIModalPresentationFullScreen;
            }else {
                nav.modalPresentationStyle = UIModalPresentationPopover;
            }
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

- (UIView *)threeChannelSelectedView {
    if (!_threeChannelSelectedView) {
        _threeChannelSelectedView = [[UIView alloc] initWithFrame:CGRectZero];
        _threeChannelSelectedView.backgroundColor = [UIColor whiteColor];
        _threeChannelSelectedView.alpha = 0.9;
        _threeChannelSelectedView.layer.cornerRadius = 14;
        _threeChannelSelectedView.layer.masksToBounds = YES;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 271, 30)];
        titleLabel.text = AcTECLocalizedStringFromTable(@"Select", @"Localizable");
        titleLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [_threeChannelSelectedView addSubview:titleLabel];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 271, 1)];
        line.backgroundColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        [_threeChannelSelectedView addSubview:line];
        
        UIButton *channel1SelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 31, 271, 44)];
        [channel1SelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        [channel1SelectBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateSelected];
        [channel1SelectBtn setTitle:AcTECLocalizedStringFromTable(@"Channel1", @"Localizable") forState:UIControlStateNormal];
        [channel1SelectBtn setTitleColor:[UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1] forState:UIControlStateNormal];
        channel1SelectBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        channel1SelectBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        channel1SelectBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, -20);
        channel1SelectBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 40, 0, -40);
        channel1SelectBtn.tag = 2;
        [channel1SelectBtn addTarget:self action:@selector(selectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpInside];
        [channel1SelectBtn addTarget:self action:@selector(selectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpOutside];
        [_threeChannelSelectedView addSubview:channel1SelectBtn];
        
        UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(60, 75, 211, 1)];
        line1.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
        [_threeChannelSelectedView addSubview:line1];
        
        UIButton *channel2SelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 76, 271, 44)];
        [channel2SelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        [channel2SelectBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateSelected];
        [channel2SelectBtn setTitle:AcTECLocalizedStringFromTable(@"Channel2", @"Localizable") forState:UIControlStateNormal];
        [channel2SelectBtn setTitleColor:[UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1] forState:UIControlStateNormal];
        channel2SelectBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        channel2SelectBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        channel2SelectBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, -20);
        channel2SelectBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 40, 0, -40);
        channel2SelectBtn.tag = 3;
        [channel2SelectBtn addTarget:self action:@selector(selectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpInside];
        [channel2SelectBtn addTarget:self action:@selector(selectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpOutside];
        [_threeChannelSelectedView addSubview:channel2SelectBtn];
        
        UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(60, 120, 211, 1)];
        line2.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
        [_threeChannelSelectedView addSubview:line2];
        
        UIButton *channel3SelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 121, 271, 44)];
        [channel3SelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        [channel3SelectBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateSelected];
        [channel3SelectBtn setTitle:AcTECLocalizedStringFromTable(@"Channel3", @"Localizable") forState:UIControlStateNormal];
        [channel3SelectBtn setTitleColor:[UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1] forState:UIControlStateNormal];
        channel3SelectBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        channel3SelectBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        channel3SelectBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, -20);
        channel3SelectBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 40, 0, -40);
        channel3SelectBtn.tag = 5;
        [channel3SelectBtn addTarget:self action:@selector(selectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpInside];
        [channel3SelectBtn addTarget:self action:@selector(selectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpOutside];
        [_threeChannelSelectedView addSubview:channel3SelectBtn];
        
        UIView *line3 = [[UIView alloc] initWithFrame:CGRectMake(0, 165, 271, 1)];
        line3.backgroundColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        [_threeChannelSelectedView addSubview:line3];
        
        UIButton *cancel = [[UIButton alloc] initWithFrame:CGRectMake(0, 166, 135, 44)];
        cancel.tag = 31;
        [cancel setTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") forState:UIControlStateNormal];
        [cancel setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [cancel addTarget:self action:@selector(channelViewCancelAction:) forControlEvents:UIControlEventTouchUpInside];
        [cancel addTarget:self action:@selector(channelViewTouchDown:) forControlEvents:UIControlEventTouchDown];
        [cancel addTarget:self action:@selector(channelViewTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        [_threeChannelSelectedView addSubview:cancel];
        
        UIView *line4 = [[UIView alloc] initWithFrame:CGRectMake(135, 166, 1, 44)];
        line4.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
        [_threeChannelSelectedView addSubview:line4];
        
        UIButton *save = [UIButton buttonWithType:UIButtonTypeCustom];
        save.tag = 32;
        [save setFrame:CGRectMake(136, 166, 135, 44)];
        [save setTitle:AcTECLocalizedStringFromTable(@"Save", @"Localizable") forState:UIControlStateNormal];
        [save setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [save addTarget:self action:@selector(threeChannelViewSaveAction:) forControlEvents:UIControlEventTouchUpInside];
        [save addTarget:self action:@selector(channelViewTouchDown:) forControlEvents:UIControlEventTouchDown];
        [save addTarget:self action:@selector(channelViewTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        [_threeChannelSelectedView addSubview:save];
    }
    return _threeChannelSelectedView;
}

- (void)channelViewCancelAction:(UIButton *) button {
    [button setBackgroundColor:[UIColor whiteColor]];
    
    for (MainCollectionViewCell *mainCell in _devicesCollectionView.visibleCells) {
        if ([mainCell.deviceId isEqualToNumber:_channelCurrentDeviceID]) {
            mainCell.seleteButton.selected = NO;
            break;
        }
    }
    for (SelectModel *mod in _selectedDevices) {
        if ([mod.deviceID isEqualToNumber:_channelCurrentDeviceID]) {
            [_selectedDevices removeObject:mod];
            break;;
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (button.tag == 31) {
            if (_threeChannelSelectedView) {
                [_threeChannelSelectedView removeFromSuperview];
                _threeChannelSelectedView = nil;
            }
        }else if (button.tag == 21) {
            if (_twoChannelSelectedView) {
                [_twoChannelSelectedView removeFromSuperview];
                _twoChannelSelectedView = nil;
            }
        }else if (button.tag == 41) {
            if (_mcChannelSelectedView) {
                [_mcChannelSelectedView removeFromSuperview];
                _mcChannelSelectedView = nil;
                self.navigationItem.rightBarButtonItem.enabled = YES;
            }
        }else if (button.tag == 51) {
            if (_mcSonosChannelSelectionView) {
                [_mcSonosChannelSelectionView removeFromSuperview];
                _mcSonosChannelSelectionView = nil;
                self.navigationItem.rightBarButtonItem.enabled = YES;
            }
        }
        
        if (_translucentBgView) {
            [_translucentBgView removeFromSuperview];
            _translucentBgView = nil;
        }
        
        if (self.selectMode == DeviceListSelectMode_ForDrop) {
            if ([self.selectedDevices count]>0) {
                self.navigationItem.rightBarButtonItem.enabled = YES;
            }else {
                self.navigationItem.rightBarButtonItem.enabled = NO;
            }
        }
    });
}

- (void)threeChannelViewSaveAction:(UIButton *) button {
    [button setBackgroundColor:[UIColor whiteColor]];
    UIButton *channel1SelectBtn = (UIButton *)[button.superview viewWithTag:2];
    UIButton *channel2SelectBtn = (UIButton *)[button.superview viewWithTag:3];
    UIButton *channel3SelectBtn = (UIButton *)[button.superview viewWithTag:5];
    if (channel1SelectBtn.selected && channel2SelectBtn.selected && channel3SelectBtn.selected) {
        [self channelsSelecteAction:@(8)];
    }else if (channel1SelectBtn.selected && channel2SelectBtn.selected && !channel3SelectBtn.selected){
        [self channelsSelecteAction:@(4)];
    }else if (channel1SelectBtn.selected && !channel2SelectBtn.selected && channel3SelectBtn.selected){
        [self channelsSelecteAction:@(6)];
    }else if (!channel1SelectBtn.selected && channel2SelectBtn.selected && channel3SelectBtn.selected){
        [self channelsSelecteAction:@(7)];
    }else if (channel1SelectBtn.selected && !channel2SelectBtn.selected && !channel3SelectBtn.selected){
        [self channelsSelecteAction:@(2)];
    }else if (!channel1SelectBtn.selected && channel2SelectBtn.selected && !channel3SelectBtn.selected){
        [self channelsSelecteAction:@(3)];
    }else if (!channel1SelectBtn.selected && !channel2SelectBtn.selected && channel3SelectBtn.selected){
        [self channelsSelecteAction:@(5)];
    }else if (!channel1SelectBtn.selected && !channel2SelectBtn.selected && !channel3SelectBtn.selected){
        [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell *mainCell, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([mainCell.deviceId isEqualToNumber:_channelCurrentDeviceID]) {
                mainCell.seleteButton.selected = NO;
                *stop = YES;
            }
        }];
        
        [_selectedDevices enumerateObjectsUsingBlock:^(SelectModel *mod, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([mod.deviceID isEqualToNumber:_channelCurrentDeviceID]) {
                [_selectedDevices removeObject:mod];
                *stop = YES;
            }
        }];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.threeChannelSelectedView removeFromSuperview];
        self.threeChannelSelectedView = nil;
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

- (void)twoChannelViewSaveAction:(UIButton *) button {
    [button setBackgroundColor:[UIColor whiteColor]];
    UIButton *channel1SelectBtn = (UIButton *)[button.superview viewWithTag:2];
    UIButton *channel2SelectBtn = (UIButton *)[button.superview viewWithTag:3];
    if (channel1SelectBtn.selected && channel2SelectBtn.selected) {
        [self channelsSelecteAction:@(4)];
    }else if (channel1SelectBtn.selected && !channel2SelectBtn.selected) {
        [self channelsSelecteAction:@(2)];
    }else if (!channel1SelectBtn.selected && channel2SelectBtn.selected) {
        [self channelsSelecteAction:@(3)];
    }else if (!channel1SelectBtn.selected && !channel2SelectBtn.selected) {
        for (MainCollectionViewCell *mainCell in _devicesCollectionView.visibleCells) {
            if ([mainCell.deviceId isEqualToNumber:_channelCurrentDeviceID]) {
                mainCell.seleteButton.selected = NO;
                break;
            }
        }
        for (SelectModel *mod in _selectedDevices) {
            if ([mod.deviceID isEqualToNumber:_channelCurrentDeviceID]) {
                [_selectedDevices removeObject:mod];
                break;;
            }
        }
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.twoChannelSelectedView removeFromSuperview];
        self.twoChannelSelectedView = nil;
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

- (void)channelViewTouchDown:(UIButton *) button {
    [button setBackgroundColor:[UIColor colorWithRed:235/255.0 green:235/255.0 blue:235/255.0 alpha:1]];
}

- (void)channelViewTouchUpOutside:(UIButton *) button {
    [button setBackgroundColor:[UIColor whiteColor]];
}

- (void)selectedViewTouchInsideAction:(UIButton *)button {
    
    button.selected = !button.selected;
    
}

- (UIView *)twoChannelSelectedView {
    if (!_twoChannelSelectedView) {
        _twoChannelSelectedView = [[UIView alloc] initWithFrame:CGRectZero];
        _twoChannelSelectedView.backgroundColor = [UIColor whiteColor];
        _twoChannelSelectedView.alpha = 0.9;
        _twoChannelSelectedView.layer.cornerRadius = 14;
        _twoChannelSelectedView.layer.masksToBounds = YES;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 271, 30)];
        titleLabel.text = AcTECLocalizedStringFromTable(@"Select", @"Localizable");
        titleLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [_twoChannelSelectedView addSubview:titleLabel];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 271, 1)];
        line.backgroundColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        [_twoChannelSelectedView addSubview:line];
        
        UIButton *channel1SelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 31, 271, 44)];
        [channel1SelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        [channel1SelectBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateSelected];
        [channel1SelectBtn setTitle:AcTECLocalizedStringFromTable(@"Channel1", @"Localizable") forState:UIControlStateNormal];
        [channel1SelectBtn setTitleColor:[UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1] forState:UIControlStateNormal];
        channel1SelectBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        channel1SelectBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        channel1SelectBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, -20);
        channel1SelectBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 40, 0, -40);
        channel1SelectBtn.tag = 2;
        [channel1SelectBtn addTarget:self action:@selector(selectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpInside];
        [channel1SelectBtn addTarget:self action:@selector(selectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpOutside];
        [_twoChannelSelectedView addSubview:channel1SelectBtn];
        
        UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(60, 75, 211, 1)];
        line1.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
        [_twoChannelSelectedView addSubview:line1];
        
        UIButton *channel2SelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 76, 271, 44)];
        [channel2SelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        [channel2SelectBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateSelected];
        [channel2SelectBtn setTitle:AcTECLocalizedStringFromTable(@"Channel2", @"Localizable") forState:UIControlStateNormal];
        [channel2SelectBtn setTitleColor:[UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1] forState:UIControlStateNormal];
        channel2SelectBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        channel2SelectBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        channel2SelectBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, -20);
        channel2SelectBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 40, 0, -40);
        channel2SelectBtn.tag = 3;
        [channel2SelectBtn addTarget:self action:@selector(selectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpInside];
        [channel2SelectBtn addTarget:self action:@selector(selectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpOutside];
        [_twoChannelSelectedView addSubview:channel2SelectBtn];
        
        UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(0, 120, 271, 1)];
        line2.backgroundColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        [_twoChannelSelectedView addSubview:line2];
        
        UIButton *cancel = [[UIButton alloc] initWithFrame:CGRectMake(0, 121, 135, 44)];
        cancel.tag = 21;
        [cancel setTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") forState:UIControlStateNormal];
        [cancel setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [cancel addTarget:self action:@selector(channelViewCancelAction:) forControlEvents:UIControlEventTouchUpInside];
        [cancel addTarget:self action:@selector(channelViewTouchDown:) forControlEvents:UIControlEventTouchDown];
        [cancel addTarget:self action:@selector(channelViewTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        [_twoChannelSelectedView addSubview:cancel];
        
        UIView *line4 = [[UIView alloc] initWithFrame:CGRectMake(135, 121, 1, 44)];
        line4.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
        [_twoChannelSelectedView addSubview:line4];
        
        UIButton *save = [UIButton buttonWithType:UIButtonTypeCustom];
        save.tag = 22;
        [save setFrame:CGRectMake(136, 121, 135, 44)];
        [save setTitle:AcTECLocalizedStringFromTable(@"Save", @"Localizable") forState:UIControlStateNormal];
        [save setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [save addTarget:self action:@selector(twoChannelViewSaveAction:) forControlEvents:UIControlEventTouchUpInside];
        [save addTarget:self action:@selector(channelViewTouchDown:) forControlEvents:UIControlEventTouchDown];
        [save addTarget:self action:@selector(channelViewTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        [_twoChannelSelectedView addSubview:save];
    }
    return _twoChannelSelectedView;
}

- (UIView *)curtainKindView {
    if (!_curtainKindView) {
        _curtainKindView = [[UIView alloc] initWithFrame:CGRectZero];
        _curtainKindView.backgroundColor = [UIColor whiteColor];
        _curtainKindView.alpha = 0.9;
        _curtainKindView.layer.cornerRadius = 14;
        _curtainKindView.layer.masksToBounds = YES;

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 271, 30)];
        titleLabel.text = AcTECLocalizedStringFromTable(@"ChooseTypeOfCurtain", @"Localizable");
        titleLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [_curtainKindView addSubview:titleLabel];

        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 271, 1)];
        line.backgroundColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        [_curtainKindView addSubview:line];

        UIButton *horizontalBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 31, 135, 135)];
        [horizontalBtn addTarget:self action:@selector(selectTypeOfCurtain:) forControlEvents:UIControlEventTouchUpInside];
        [_curtainKindView addSubview:horizontalBtn];

        UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(135, 31, 1, 135)];
        line1.backgroundColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        [_curtainKindView addSubview:line1];

        UIButton *verticalBtn = [[UIButton alloc] initWithFrame:CGRectMake(136, 31, 135, 135)];
        [verticalBtn addTarget:self action:@selector(selectTypeOfCurtain:) forControlEvents:UIControlEventTouchUpInside];
        [_curtainKindView addSubview:verticalBtn];
        
        CSRDeviceEntity *selectedCurtainDeviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_selectedCurtainDeviceId];

        if ([CSRUtilities belongToOneChannelCurtainController:selectedCurtainDeviceEntity.shortName]) {
            horizontalBtn.tag = 11;
            [horizontalBtn setImage:[UIImage imageNamed:@"curtainHImage"] forState:UIControlStateNormal];
            verticalBtn.tag = 22;
            [verticalBtn setImage:[UIImage imageNamed:@"curtainVImage"] forState:UIControlStateNormal];
        }else if ([CSRUtilities belongToTwoChannelCurtainController:selectedCurtainDeviceEntity.shortName]) {
            horizontalBtn.tag = 33;
            [horizontalBtn setImage:[UIImage imageNamed:@"curtainHHImage"] forState:UIControlStateNormal];
            verticalBtn.tag = 44;
            [verticalBtn setImage:[UIImage imageNamed:@"curtainVVImage"] forState:UIControlStateNormal];
        }
    }
    return _curtainKindView;
}

- (void)selectTypeOfCurtain:(UIButton *)sender {
    CSRDeviceEntity *selectedCurtainDeviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_selectedCurtainDeviceId];
    if (sender.tag == 11) {
        selectedCurtainDeviceEntity.remoteBranch = @"ch";
    }else if (sender.tag == 22) {
        selectedCurtainDeviceEntity.remoteBranch = @"cv";
    }else if (sender.tag == 33) {
        selectedCurtainDeviceEntity.remoteBranch = @"chh";
    }else if (sender.tag == 44) {
        selectedCurtainDeviceEntity.remoteBranch = @"cvv";
    }
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self loadData];
    [_devicesCollectionView reloadData];
    
    [self.curtainKindView removeFromSuperview];
    self.curtainKindView = nil;
    [self.translucentBgView removeFromSuperview];
    self.translucentBgView = nil;
}

- (UIView *)mcChannelSelectedView {
    if (!_mcChannelSelectedView) {
        _mcChannelSelectedView = [[UIView alloc] initWithFrame:CGRectZero];
        _mcChannelSelectedView.backgroundColor = [UIColor whiteColor];
        _mcChannelSelectedView.alpha = 0.9;
        _mcChannelSelectedView.layer.cornerRadius = 14;
        _mcChannelSelectedView.layer.masksToBounds = YES;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 271, 30)];
        titleLabel.text = AcTECLocalizedStringFromTable(@"select_the_channel", @"Localizable");
        titleLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [_mcChannelSelectedView addSubview:titleLabel];
        
        for (int i = 0; i < 2; i ++) {
            for (int j = 0; j < 4; j ++) {
                UIButton *btn = [[UIButton alloc] init];
                btn.frame = CGRectMake(j*68, 31+i*45, 67, 44);
                btn.tag = i*4 + j + 100;
                [btn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                [btn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateSelected];
                [btn setTitle:[NSString stringWithFormat:@"%d", i*4 + j] forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1] forState:UIControlStateNormal];
                [btn addTarget:self action:@selector(mcChannelSelectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpInside];
                [_mcChannelSelectedView addSubview:btn];
            }
        }
        
        UIButton *cancel = [[UIButton alloc] initWithFrame:CGRectMake(0, 121, 135, 44)];
        cancel.tag = 41;
        [cancel setTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") forState:UIControlStateNormal];
        [cancel setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [cancel addTarget:self action:@selector(channelViewCancelAction:) forControlEvents:UIControlEventTouchUpInside];
        [cancel addTarget:self action:@selector(channelViewTouchDown:) forControlEvents:UIControlEventTouchDown];
        [cancel addTarget:self action:@selector(channelViewTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        [_mcChannelSelectedView addSubview:cancel];
        
        UIView *line4 = [[UIView alloc] initWithFrame:CGRectMake(135, 121, 1, 44)];
        line4.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
        [_mcChannelSelectedView addSubview:line4];
        
        UIButton *save = [UIButton buttonWithType:UIButtonTypeCustom];
        save.tag = 42;
        [save setFrame:CGRectMake(136, 121, 135, 44)];
        [save setTitle:AcTECLocalizedStringFromTable(@"Save", @"Localizable") forState:UIControlStateNormal];
        [save setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [save addTarget:self action:@selector(mcChannelViewSaveAction:) forControlEvents:UIControlEventTouchUpInside];
        [save addTarget:self action:@selector(channelViewTouchDown:) forControlEvents:UIControlEventTouchDown];
        [save addTarget:self action:@selector(channelViewTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        [_mcChannelSelectedView addSubview:save];
    }
    return _mcChannelSelectedView;
}

- (void)mcChannelSelectedViewTouchInsideAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    for (int i = 0; i < 16; i ++) {
        UIButton *btn = (UIButton *)[sender.superview viewWithTag:i+100];
        if (btn && btn.selected && btn.tag != sender.tag) {
            btn.selected = NO;
        }
    }
}

- (void)mcChannelViewSaveAction:(UIButton *)sender {
    NSInteger mcChannel = 0;
    for (int i = 0; i < 16; i ++) {
        UIButton *btn = (UIButton *)[sender.superview viewWithTag:i+100];
        if (btn && btn.selected) {
            mcChannel = mcChannel + pow(2, i);
        }
    }
    if (mcChannel == 0) {
        for (MainCollectionViewCell *mainCell in _devicesCollectionView.visibleCells) {
            if ([mainCell.deviceId isEqualToNumber:_channelCurrentDeviceID]) {
                mainCell.seleteButton.selected = NO;
                break;
            }
        }
        for (SelectModel *mod in _selectedDevices) {
            if ([mod.deviceID isEqualToNumber:_channelCurrentDeviceID]) {
                [_selectedDevices removeObject:mod];
                break;
            }
        }
    }else {
        BOOL exist = NO;
        for (SelectModel *mod in _selectedDevices) {
            if ([mod.deviceID isEqualToNumber:_channelCurrentDeviceID]) {
                mod.channel = @(mcChannel);
                exist = YES;
                break;
            }
        }
        if (!exist) {
            SelectModel *mod = [[SelectModel alloc] init];
            mod.deviceID = _channelCurrentDeviceID;
            mod.channel = @(mcChannel);
            [_selectedDevices addObject:mod];
        }
    }
    
    if (_mcChannelSelectedView) {
        [_mcChannelSelectedView removeFromSuperview];
        _mcChannelSelectedView = nil;
    }
    if (_translucentBgView) {
        [_translucentBgView removeFromSuperview];
        _translucentBgView = nil;
    }
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (UIView *)mcSonosChannelSelectionView {
    if (!_mcSonosChannelSelectionView) {
        _mcSonosChannelSelectionView = [[UIView alloc] initWithFrame:CGRectZero];
        _mcSonosChannelSelectionView.backgroundColor = [UIColor whiteColor];
        _mcSonosChannelSelectionView.alpha = 0.9;
        _mcSonosChannelSelectionView.layer.cornerRadius = 14;
        _mcSonosChannelSelectionView.layer.masksToBounds = YES;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 271, 30)];
        titleLabel.text = AcTECLocalizedStringFromTable(@"select_the_channel", @"Localizable");
        titleLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [_mcSonosChannelSelectionView addSubview:titleLabel];
        
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_channelCurrentDeviceID];
        NSArray *sonos = [device.sonoss allObjects];
        for (int i = 0; i < [device.sonoss count]; i ++) {
            SonosEntity *s = [sonos objectAtIndex:i];
            UIButton *btn = [[UIButton alloc] init];
            btn.frame = CGRectMake(0, 31+i*45, 271, 44);
            btn.tag = [s.channel integerValue]+100;
            [btn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
            [btn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateSelected];
            [btn setTitle:s.name forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1] forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(mcSonosChannelSelectedViewTouchInsideAction:) forControlEvents:UIControlEventTouchUpInside];
            [_mcSonosChannelSelectionView addSubview:btn];
        }
        
        UIButton *cancel = [[UIButton alloc] initWithFrame:CGRectMake(0, 31+[sonos count]*45, 135, 44)];
        cancel.tag = 51;
        [cancel setTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") forState:UIControlStateNormal];
        [cancel setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [cancel addTarget:self action:@selector(channelViewCancelAction:) forControlEvents:UIControlEventTouchUpInside];
        [cancel addTarget:self action:@selector(channelViewTouchDown:) forControlEvents:UIControlEventTouchDown];
        [cancel addTarget:self action:@selector(channelViewTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        [_mcSonosChannelSelectionView addSubview:cancel];
        
        UIView *line4 = [[UIView alloc] initWithFrame:CGRectMake(135, 211, 1, 44)];
        line4.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
        [_mcSonosChannelSelectionView addSubview:line4];
        
        UIButton *save = [UIButton buttonWithType:UIButtonTypeCustom];
        save.tag = 52;
        [save setFrame:CGRectMake(136, 31+[sonos count]*45, 135, 44)];
        [save setTitle:AcTECLocalizedStringFromTable(@"Save", @"Localizable") forState:UIControlStateNormal];
        [save setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [save addTarget:self action:@selector(mcSonosChannelViewSaveAction:) forControlEvents:UIControlEventTouchUpInside];
        [save addTarget:self action:@selector(channelViewTouchDown:) forControlEvents:UIControlEventTouchDown];
        [save addTarget:self action:@selector(channelViewTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        [_mcSonosChannelSelectionView addSubview:save];
    }
    return _mcSonosChannelSelectionView;
}

- (void)mcSonosChannelSelectedViewTouchInsideAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_channelCurrentDeviceID];
    NSArray *sonoss = [device.sonoss allObjects];
    for (int i = 0; i < [sonoss count]; i ++) {
        SonosEntity *s = [sonoss objectAtIndex:i];
        UIButton *btn = (UIButton *)[sender.superview viewWithTag:[s.channel integerValue]+100];
        if (btn && btn.selected && btn.tag != sender.tag) {
            btn.selected = NO;
        }
    }
}

- (void)mcSonosChannelViewSaveAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_channelCurrentDeviceID];
    NSArray *sonoss = [device.sonoss allObjects];
    NSInteger mcChannel = 0;
    for (int i = 0; i < [sonoss count]; i ++) {
        SonosEntity *s = [sonoss objectAtIndex:i];
        UIButton *btn = (UIButton *)[sender.superview viewWithTag:[s.channel integerValue]+100];
        if (btn && btn.selected) {
            mcChannel = mcChannel + pow(2, [s.channel integerValue]);
        }
    }
    if (mcChannel == 0) {
        for (MainCollectionViewCell *mainCell in _devicesCollectionView.visibleCells) {
            if ([mainCell.deviceId isEqualToNumber:_channelCurrentDeviceID]) {
                mainCell.seleteButton.selected = NO;
                break;
            }
        }
        for (SelectModel *mod in _selectedDevices) {
            if ([mod.deviceID isEqualToNumber:_channelCurrentDeviceID]) {
                [_selectedDevices removeObject:mod];
                break;
            }
        }
    }else {
        BOOL exist = NO;
        for (SelectModel *mod in _selectedDevices) {
            if ([mod.deviceID isEqualToNumber:_channelCurrentDeviceID]) {
                mod.channel = @(mcChannel);
                exist = YES;
                break;
            }
        }
        if (!exist) {
            SelectModel *mod = [[SelectModel alloc] init];
            mod.deviceID = _channelCurrentDeviceID;
            mod.channel = @(mcChannel);
            [_selectedDevices addObject:mod];
        }
    }
    
    if (_mcSonosChannelSelectionView) {
        [_mcSonosChannelSelectionView removeFromSuperview];
        _mcSonosChannelSelectionView = nil;
    }
    if (_translucentBgView) {
        [_translucentBgView removeFromSuperview];
        _translucentBgView = nil;
    }
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

@end
