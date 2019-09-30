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
#import "SocketForSceneVC.h"
#import "TwoChannelDimmerVC.h"
#import "DeviceModelManager.h"


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

@property (nonatomic,strong) UIView *curtainDetailSelectedView;

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
    
    [self.selectedDevices removeAllObjects];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = WIDTH*8.0/640.0;
    flowLayout.minimumInteritemSpacing = WIDTH*8.0/640.0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, floor(WIDTH*3/160.0));
    flowLayout.itemSize = CGSizeMake(floor(WIDTH*5/16.0),floor(WIDTH*9/32.0));
    
    _devicesCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout cellIdentifier:@"MainCollectionViewCell"];
    _devicesCollectionView.mainDelegate = self;
    
    if (self.selectMode == DeviceListSelectMode_ForGroup) {
        
        if (self.originalMembers!=nil && [self.originalMembers count] != 0) {
            
            for (SingleDeviceModel *singleDevice in self.originalMembers) {
                singleDevice.isForList = YES;
                singleDevice.isSelected = YES;
                [self.selectedDevices addObject:singleDevice.deviceId];
            }
            [_devicesCollectionView.dataArray addObjectsFromArray:self.originalMembers];
        }
        
        __block NSMutableArray *deviceIdWasInAreaArray =[[NSMutableArray alloc] init];
        NSSet *areas =  [CSRAppStateManager sharedInstance].selectedPlace.areas;
        if (areas != nil && [areas count] != 0) {
            [areas enumerateObjectsUsingBlock:^(CSRAreaEntity *area, BOOL * _Nonnull stop) {
                for (CSRDeviceEntity *deviceEntity in area.devices) {
                    [deviceIdWasInAreaArray addObject:deviceEntity.deviceId];
                }
            }];
        }
        
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if (mutableArray != nil || [mutableArray count] != 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                if (([CSRUtilities belongToMainVCDevice:deviceEntity.shortName]) && ![deviceIdWasInAreaArray containsObject:deviceEntity.deviceId]) {
                    SingleDeviceModel *singleDevice = [[SingleDeviceModel alloc] init];
                    singleDevice.deviceId = deviceEntity.deviceId;
                    singleDevice.deviceName = deviceEntity.name;
                    singleDevice.deviceShortName = deviceEntity.shortName;
                    singleDevice.curtainDirection = deviceEntity.remoteBranch;
                    singleDevice.isForList = YES;
                    singleDevice.isSelected = NO;
                    
                    __block BOOL exist = 0;
                    [_devicesCollectionView.dataArray enumerateObjectsUsingBlock:^(SingleDeviceModel *singleDevice, NSUInteger idx, BOOL * _Nonnull newstop) {
                        if ([singleDevice.deviceId isEqualToNumber:deviceEntity.deviceId]) {
                            exist = YES;
                            *newstop = YES;
                        }
                    }];

                    if (!exist) {
                        [_devicesCollectionView.dataArray addObject:singleDevice];
                    }
                    
                }
            }];
        }
        
        
    }else if (self.selectMode == DeviceListSelectMode_SelectGroup) {
        
        NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
        if (areaMutableArray && [areaMutableArray count] != 0) {
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
                
                [_devicesCollectionView.dataArray addObject:model];
            }
        }
        
    }else if (self.selectMode == DeviceListSelectMode_SelectScene) {
        
        NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.scenes allObjects] mutableCopy];
        if (areaMutableArray && [areaMutableArray count] != 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sceneID" ascending:YES];
            [areaMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            for (SceneEntity *sceneEntity in areaMutableArray) {
                if (sceneEntity.members && [sceneEntity.members count]!=0) {
                    SceneListSModel *model = [[SceneListSModel alloc] init];
                    model.sceneId = sceneEntity.sceneID;
                    model.iconId = sceneEntity.iconID;
                    model.sceneName = sceneEntity.sceneName;
                    model.memnbers = sceneEntity.members;
                    model.rcIndex = sceneEntity.rcIndex;
                    [_devicesCollectionView.dataArray addObject:model];
                }
            }
        }
        
    }else if (self.selectMode == DeviceListSelectMode_ForLightSensor) {
        NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
        if (areaMutableArray && [areaMutableArray count] != 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [areaMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            
            for (CSRAreaEntity *area in areaMutableArray) {
                __block BOOL exist = NO;
                [area.devices enumerateObjectsUsingBlock:^(CSRDeviceEntity  *deviceEntity, BOOL * _Nonnull stop) {
                    if ([deviceEntity.shortName isEqualToString:@"D1-10IB"]||[deviceEntity.shortName isEqualToString:@"D0/1-10IB"]||[deviceEntity.shortName isEqualToString:@"D1-10VIBH"]) {
                        exist = YES;
                        *stop = YES;
                    }
                }];
                if (exist) {
                    GroupListSModel *model = [[GroupListSModel alloc] init];
                    model.areaIconNum = area.areaIconNum;
                    model.areaID = area.areaID;
                    model.areaName = area.areaName;
                    model.areaImage = area.areaImage;
                    model.sortId = area.sortId;
                    model.devices = area.devices;
                    model.isForList = YES;
                    if ([self.originalMembers containsObject:area.areaID]) {
                        model.isSelected = YES;
                        [self.selectedDevices addObject:area.areaID];
                    }
                    [_devicesCollectionView.dataArray addObject:model];
                }
            }
        }
        
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if (mutableArray && [mutableArray count] != 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([deviceEntity.shortName isEqualToString:@"D1-10IB"]||[deviceEntity.shortName isEqualToString:@"D0/1-10IB"]||[deviceEntity.shortName isEqualToString:@"D1-10VIBH"]) {
                    SingleDeviceModel *singleDevice = [[SingleDeviceModel alloc] init];
                    singleDevice.deviceId = deviceEntity.deviceId;
                    singleDevice.deviceName = deviceEntity.name;
                    singleDevice.deviceShortName = deviceEntity.shortName;
                    singleDevice.isForList = YES;
                    if ([self.originalMembers containsObject:deviceEntity.deviceId]) {
                        singleDevice.isSelected = YES;
                        [self.selectedDevices addObject:deviceEntity.deviceId];
                    }
                    [_devicesCollectionView.dataArray addObject:singleDevice];
                }
            }];
        }
        
    }else {
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if (mutableArray != nil || [mutableArray count] != 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([CSRUtilities belongToMainVCDevice:deviceEntity.shortName]) {
                    SingleDeviceModel *singleDevice = [[SingleDeviceModel alloc] init];
                    singleDevice.deviceId = deviceEntity.deviceId;
                    singleDevice.deviceName = deviceEntity.name;
                    singleDevice.deviceShortName = deviceEntity.shortName;
                    singleDevice.isForList = YES;
                    __block BOOL exist = 0;
                    [self.originalMembers enumerateObjectsUsingBlock:^(SingleDeviceModel *originalDevice, NSUInteger idx, BOOL * _Nonnull stopp) {
                        if ([originalDevice.deviceId isEqualToNumber:singleDevice.deviceId]) {
                            exist = YES;
                            *stopp = YES;
                        }
                    }];
                    if (exist) {
                        singleDevice.isSelected = YES;
                    }else {
                        singleDevice.isSelected = NO;
                    }
                    [_devicesCollectionView.dataArray addObject:singleDevice];
                }
            }];
        }
        
        if (self.originalMembers != nil && [self.originalMembers count]!=0) {
            for (SingleDeviceModel *singleDevice in self.originalMembers) {
                [self.selectedDevices addObject:singleDevice.deviceId];
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
    /*
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
            cell.seleteButton.hidden = NO;
            [self.originalMembers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stoppp) {
//                if ([obj isKindOfClass:[SingleDeviceModel class]]) {
//                    SingleDeviceModel *deviceEntity = (SingleDeviceModel *)obj;
//                    if ([cell.deviceId isEqualToNumber:deviceEntity.deviceId]) {
//                        cell.seleteButton.selected = YES;
//                        [cell.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
//                        [self.selectedDevices addObject:cell.deviceId];
//                        *stoppp = YES;
//                    }
//                }
                if ([obj isKindOfClass:[CSRAreaEntity class]]) {
                    CSRAreaEntity *area = (CSRAreaEntity *)obj;
                    if ([area.areaID isEqualToNumber:cell.groupId]) {
                        cell.seleteButton.selected = YES;
                        [cell.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
                        [self.selectedDevices addObject:cell.groupId];
                        *stoppp = YES;
                    }
                }
                
                if ([obj isKindOfClass:[SceneEntity class]]) {
                    SceneEntity *scene = (SceneEntity *)obj;
                    if ([scene.rcIndex isEqualToNumber:cell.sceneId]) {
                        cell.seleteButton.selected = YES;
                        [cell.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
                        [self.selectedDevices addObject:cell.sceneId];
                        *stoppp = YES;
                    }
                }
            }];
        }];
    });
     */
}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)mainCollectionViewDelegateSelectAction:(id)cell {
    if (self.selectMode == DeviceListSelectMode_Single || self.selectMode == DeviceListSelectMode_ForDrop) {
        if ([cell isKindOfClass:[MainCollectionViewCell class]]) {
            MainCollectionViewCell *mainCell = (MainCollectionViewCell *)cell;
            if (mainCell.selected) {
                if (![self.selectedDevices containsObject:mainCell.deviceId]) {
                    [self.selectedDevices addObject:mainCell.deviceId];
                    
                    [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell * enCell, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (![enCell.deviceId isEqualToNumber:mainCell.deviceId] && enCell.selected && [self.selectedDevices containsObject:enCell.deviceId]) {
                            [self.selectedDevices removeObject:enCell.deviceId];
                            enCell.selected = NO;
                            [enCell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                        }
                    }];
                    
                    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:mainCell.deviceId];
                    if ([CSRUtilities belongToTwoChannelDimmer:deviceEntity.shortName] || [CSRUtilities belongToSocket:deviceEntity.shortName] || [CSRUtilities belongToFanController:deviceEntity.shortName]) {
                        [self mainCollectionViewDelegateLongPressAction:cell];
                    }else if ([CSRUtilities belongToCurtainController:deviceEntity.shortName]) {
                        self.curtainDetailSelectedView = [self curtainDetailSelectedView:mainCell.deviceId];
                        [self.view addSubview:self.curtainDetailSelectedView];
                        [self.curtainDetailSelectedView autoCenterInSuperview];
                        [self.curtainDetailSelectedView autoSetDimensionsToSize:CGSizeMake(271, 166)];
                    }
                    
                }
            }else {
                if ([self.selectedDevices containsObject:mainCell.deviceId]) {
                    [self.selectedDevices removeObject:mainCell.deviceId];
                }
            }
        }
        
    }else if (self.selectMode == DeviceListSelectMode_SelectScene) {
        if ([cell isKindOfClass:[MainCollectionViewCell class]]) {
            MainCollectionViewCell *mainCell = (MainCollectionViewCell *)cell;
            
            if (mainCell.selected) {
                if (![self.selectedDevices containsObject:mainCell.sceneId]) {
                    [self.selectedDevices addObject:mainCell.sceneId];
                    
                    [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell * enCell, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (![enCell.sceneId isEqualToNumber:mainCell.sceneId] && enCell.selected && [self.selectedDevices containsObject:enCell.sceneId]) {
                            [self.selectedDevices removeObject:enCell.sceneId];
                            enCell.selected = NO;
                            [enCell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                        }
                    }];
                    
                }
            }else {
                if ([self.selectedDevices containsObject:mainCell.sceneId]) {
                    [self.selectedDevices removeObject:mainCell.sceneId];
                }
            }
            
        }
        
    }else if (self.selectMode == DeviceListSelectMode_SelectGroup) {
        if ([cell isKindOfClass:[MainCollectionViewCell class]]) {
            MainCollectionViewCell *mainCell = (MainCollectionViewCell *)cell;
            if (mainCell.selected) {
                if (![self.selectedDevices containsObject:mainCell.groupId]) {
                    [self.selectedDevices addObject:mainCell.groupId];
                    
                    [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell * enCell, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (![enCell.groupId isEqualToNumber:mainCell.groupId] && enCell.selected && [self.selectedDevices containsObject:enCell.groupId]) {
                            [self.selectedDevices removeObject:enCell.groupId];
                            enCell.selected = NO;
                            [enCell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                        }
                    }];
                    
                }
            }else {
                if ([self.selectedDevices containsObject:mainCell.groupId]) {
                    [self.selectedDevices removeObject:mainCell.groupId];
                }
            }
        }
        
    }else if (self.selectMode == DeviceListSelectMode_ForLightSensor) {
        if ([cell isKindOfClass:[MainCollectionViewCell class]]) {
            MainCollectionViewCell *mainCell = (MainCollectionViewCell *)cell;
            if (mainCell.selected) {
                if ([mainCell.deviceId isEqualToNumber:@2000] && ![self.selectedDevices containsObject:mainCell.groupId]) {
                    [self.selectedDevices addObject:mainCell.groupId];
                    
                    [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell * enCell, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([enCell.deviceId isEqualToNumber:@2000]) {
                            if (![enCell.groupId isEqualToNumber:mainCell.groupId] && enCell.selected && [self.selectedDevices containsObject:enCell.groupId]) {
                                [self.selectedDevices removeObject:enCell.groupId];
                                enCell.selected = NO;
                                [enCell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                            }
                        }else {
                            if (enCell.selected && [self.selectedDevices containsObject:enCell.deviceId]) {
                                [self.selectedDevices removeObject:enCell.deviceId];
                                enCell.selected = NO;
                                [enCell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                            }
                        }
                    }];
                }else if ([mainCell.groupId isEqualToNumber:@2000] && ![self.selectedDevices containsObject:mainCell.deviceId]) {
                    [self.selectedDevices addObject:mainCell.deviceId];
                    
                    [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell * enCell, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([enCell.groupId isEqualToNumber:@2000]) {
                            if (![enCell.deviceId isEqualToNumber:mainCell.deviceId] && enCell.selected && [self.selectedDevices containsObject:enCell.deviceId]) {
                                [self.selectedDevices removeObject:enCell.deviceId];
                                enCell.selected = NO;
                                [enCell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                            }
                        }else {
                            if (enCell.selected && [self.selectedDevices containsObject:enCell.groupId]) {
                                [self.selectedDevices removeObject:enCell.groupId];
                                enCell.selected = NO;
                                [enCell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                            }
                        }
                    }];
                }
                
            }else {
                if ([self.selectedDevices containsObject:mainCell.groupId]) {
                    [self.selectedDevices removeObject:mainCell.groupId];
                }
                if ([self.selectedDevices containsObject:mainCell.deviceId]) {
                    [self.selectedDevices removeObject:mainCell.deviceId];
                }
            }
        }
    }else {
        if ([cell isKindOfClass:[MainCollectionViewCell class]]) {
            MainCollectionViewCell *mainCell = (MainCollectionViewCell *)cell;
            if (mainCell.selected) {
                [self.selectedDevices addObject:mainCell.deviceId];
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:mainCell.deviceId];
                if (([CSRUtilities belongToTwoChannelDimmer:deviceEntity.shortName] || [CSRUtilities belongToSocket:deviceEntity.shortName]) && self.selectMode != DeviceListSelectMode_ForGroup) {
                    [self mainCollectionViewDelegateLongPressAction:cell];
                }
            }else {
                if ([self.selectedDevices containsObject:mainCell.deviceId]) {
                    [self.selectedDevices removeObject:mainCell.deviceId];
                }
            }
            [_devicesCollectionView.dataArray enumerateObjectsUsingBlock:^(SingleDeviceModel *singleModel, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([singleModel.deviceId isEqualToNumber:mainCell.deviceId]) {
                    singleModel.isSelected = mainCell.selected;
                    *stop = YES;
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

- (NSMutableArray *)selectedDevices {
    if (!_selectedDevices) {
        _selectedDevices = [[NSMutableArray alloc] init];
    }
    return _selectedDevices;
}

#pragma mark - MainCollectionViewDelegate

- (void)mainCollectionViewDelegatePanBrightnessWithTouchPoint:(CGPoint)touchPoint withOrigin:(CGPoint)origin toLight:(NSNumber *)deviceId groupId:(NSNumber *)groupId withPanState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
    if (state == UIGestureRecognizerStateBegan) {
        self.originalLevel = model.level;
        [self.improver beginImproving];
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:deviceId withLevel:self.originalLevel withState:state direction:direction];
        return;
    }
    if (state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateEnded) {
        NSInteger updateLevel = [self.improver improveTouching:touchPoint referencePoint:origin primaryBrightness:[self.originalLevel integerValue]];

        CGFloat percentage = updateLevel/255.0*100;
        [self showControlMaskLayerWithAlpha:updateLevel/255.0 text:[NSString stringWithFormat:@"%.f",percentage]];

        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:deviceId withLevel:@(updateLevel) withState:state direction:direction];
        
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
        if ([CSRUtilities belongToRGBDevice:deviceEntity.shortName]||[CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]||[CSRUtilities belongToRGBNoLevelDevice:deviceEntity.shortName]||[CSRUtilities belongToRGBCWNoLevelDevice:deviceEntity.shortName]) {
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
                    [self.curtainKindView autoSetDimensionsToSize:CGSizeMake(271, 166)];
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
            fanVC.forSelected = YES;
            fanVC.buttonNum = self.buttonNum;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:fanVC];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
            
        }else if ([CSRUtilities belongToSocket:deviceEntity.shortName]) {
            SocketForSceneVC *socketVC = [[SocketForSceneVC alloc] init];
            socketVC.deviceId = mainCell.deviceId;
            socketVC.buttonNum = self.buttonNum;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:socketVC];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
        }else if ([CSRUtilities belongToTwoChannelDimmer:deviceEntity.shortName]) {
            TwoChannelDimmerVC *TDVC = [[TwoChannelDimmerVC alloc] init];
            TDVC.deviceId = mainCell.deviceId;
            TDVC.forSelected = YES;
            TDVC.buttonNum = self.buttonNum;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:TDVC];
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

- (UIView *)curtainDetailSelectedView:(NSNumber *)deviceId {
    if (!_curtainDetailSelectedView) {
        _curtainDetailSelectedView = [[UIView alloc] initWithFrame:CGRectZero];
        _curtainDetailSelectedView.backgroundColor = [UIColor whiteColor];
        _curtainDetailSelectedView.alpha = 0.9;
        _curtainDetailSelectedView.layer.cornerRadius = 14;
        _curtainDetailSelectedView.layer.masksToBounds = YES;
        _curtainDetailSelectedView.tag = [deviceId integerValue];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 271, 30)];
        titleLabel.text = @"选择开启或者关闭";
        titleLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [_curtainDetailSelectedView addSubview:titleLabel];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 271, 1)];
        line.backgroundColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        [_curtainDetailSelectedView addSubview:line];
        
        UIButton *horizontalBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 31, 135, 135)];
        horizontalBtn.tag = 11;
        [horizontalBtn addTarget:self action:@selector(curtainDetailSelectedAction:) forControlEvents:UIControlEventTouchUpInside];
        [_curtainDetailSelectedView addSubview:horizontalBtn];
        
        UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(135, 31, 1, 135)];
        line1.backgroundColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        [_curtainDetailSelectedView addSubview:line1];
        
        UIButton *verticalBtn = [[UIButton alloc] initWithFrame:CGRectMake(136, 31, 135, 135)];
        verticalBtn.tag = 22;
        [verticalBtn addTarget:self action:@selector(curtainDetailSelectedAction:) forControlEvents:UIControlEventTouchUpInside];
        [_curtainDetailSelectedView addSubview:verticalBtn];
        
        CSRDeviceEntity *curtainEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        if ([curtainEntity.remoteBranch isEqualToString:@"ch"]) {
            [horizontalBtn setImage:[UIImage imageNamed:@"curtainHOpen"] forState:UIControlStateNormal];
            [verticalBtn setImage:[UIImage imageNamed:@"curtainHClose"] forState:UIControlStateNormal];
        }else if ([curtainEntity.remoteBranch isEqualToString:@"cv"]) {
            [horizontalBtn setImage:[UIImage imageNamed:@"curtainVOpen"] forState:UIControlStateNormal];
            [verticalBtn setImage:[UIImage imageNamed:@"curtainVClose"] forState:UIControlStateNormal];
        }
        
    }
    return _curtainDetailSelectedView;
}

- (void)curtainDetailSelectedAction:(UIButton *)button {
    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance]getDeviceModelByDeviceId:[NSNumber numberWithInteger:_curtainDetailSelectedView.tag]];
    if (_buttonNum) {
        if (button.tag == 11) {
            [deviceModel addValue:@2 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
        }else if (button.tag == 22) {
            [deviceModel addValue:@3 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
        }
    }
    [self.curtainDetailSelectedView removeFromSuperview];
    self.curtainDetailSelectedView = nil;
}

@end
