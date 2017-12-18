//
//  LightClusterViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/11.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "LightClusterViewController.h"
#import "CSRAppStateManager.h"
#import "LightClusterCell.h"
#import <CSRmesh/MeshServiceApi.h>
#import "CSRBluetoothLE.h"
#import "CSRDevicesManager.h"
#import "PrimaryDeviceListController.h"
#import "DeviceDetailViewController.h"
#import "ImproveTouchingExperience.h"
#import "ControlMaskView.h"
#import "CSRMeshUtilities.h"
#import "CSRDeviceEntity.h"
#import "UIView+DarkEffect.h"
#import "DeviceModel.h"
#import "DataModelManager.h"
#import "CSRDatabaseManager.h"
#import "AreaModel.h"
#import "AreaViewController.h"

#define kMinBrighness 13

CGFloat const gestureMinimumTranslation = 20.0;
typedef enum :NSInteger {
    kCameraMoveDirectionNone,
    kCameraMoveDirectionUpOrDown,
    kCameraMoveDirectionLeftOrRight
} CameraMoveDirection;

@interface LightClusterViewController ()<CSRBluetoothLEDelegate>
{
    CameraMoveDirection direction;
    BOOL isHorizontal;
}
@property (nonatomic,strong) UIPanGestureRecognizer *panDetect;
@property (nonatomic,strong) UITapGestureRecognizer *tapDetect;
@property (nonatomic,strong) UILongPressGestureRecognizer *longPressDetect;

@property (nonatomic,weak) LightClusterCell *controlTarget;
@property (nonatomic,assign) BOOL slideBegin;
@property (nonatomic,assign) NSInteger originBrightness;

@property (nonatomic,strong) ImproveTouchingExperience *improver;
@property (nonatomic,weak) LightClusterCell *panCell;

@property (nonatomic,strong) ControlMaskView *maskView;

@property (nonatomic, retain) CSRAreaEntity *areaEntity;

@property (nonatomic,copy) NSMutableArray *deviceEntitys;

@end

@implementation LightClusterViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.improver = [[ImproveTouchingExperience alloc] init];
    
    self.allowGroupEdit = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceState:) name:@"setPowerStateSuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reGetData) name:@"reGetData" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(physicalButtonActionCall:) name:@"physicalButtonActionCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setAllDevicesTime) name:@"setAllDevicesTime" object:nil];
    
    self.tapDetect = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionForTap:)];
    self.tapDetect.numberOfTapsRequired = 1;
    self.tapDetect.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:self.tapDetect];
    
    self.longPressDetect = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(actionForLongPress:)];
    [self.view addGestureRecognizer:self.longPressDetect];
    
    self.panDetect = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(actionForPan:)];
    self.panDetect.delegate = self.lightPanel;
    [self.view addGestureRecognizer:self.panDetect];
    
    [self queryPrimaryMeshNode];
    [self updateCollectionView];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [DataModelManager shareInstance];
    [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
    
}

//开关灯时图标颜色反馈
- (void)updateDeviceState:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *state = userInfo[@"state"];
    NSNumber *deviceId = userInfo[@"deviceId"];
    
    [self.itemCluster enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj isKindOfClass:[DeviceModel class]]) {
            DeviceModel *device = (DeviceModel *)obj;
            if ([device.deviceId isEqualToNumber:deviceId]) {
                device.powerState = state;
                *stop = YES;
            }
        }
        else if ([obj isKindOfClass:[AreaModel class]]){
            AreaModel *area = (AreaModel *)obj;
            for (DeviceModel *device in area.devices) {
                if ([device.deviceId isEqualToNumber:deviceId]) {
                    device.powerState = state;
                    *stop = YES;
                }
            }
        }
        
    }];
    [self updateCollectionView];
    
}


//删灯或者加灯后重新获取数据
- (void)reGetData {
    [self queryPrimaryMeshNode];
    [[LightModelApi sharedInstance] getState:@(0) success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
        
    } failure:^(NSError * _Nullable error) {
        
    }];
    [self updateCollectionView];
}

//获取数据
- (void)queryPrimaryMeshNode {
    [self.itemCluster removeAllObjects];
    [self.deviceEntitys removeAllObjects];
    [self.itemCluster addObjectsFromArray:@[@0,@1]];
    
    NSMutableArray *deviceIdWasInAreaArray =[[NSMutableArray alloc] init];
    NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
    if (areaMutableArray != nil || [areaMutableArray count] != 0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"areaName" ascending:YES]; //@"name"
        [areaMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        [areaMutableArray enumerateObjectsUsingBlock:^(CSRAreaEntity *area, NSUInteger idx, BOOL * _Nonnull stop) {
            
            AreaModel *areaModel = [[AreaModel alloc] init];
            areaModel.areaID = area.areaID;
            areaModel.areaName = area.areaName;
            NSMutableArray *devices = [[NSMutableArray alloc] init];
            for (CSRDeviceEntity *deviceEntity in area.devices) {
                [deviceIdWasInAreaArray addObject:deviceEntity.deviceId];
                
                DeviceModel *deviceModel = [[DeviceModel alloc] init];
                deviceModel.deviceId = deviceEntity.deviceId;
                deviceModel.name = deviceEntity.name;
                deviceModel.shortName = deviceEntity.shortName;
                deviceModel.isForGroup = YES;
                [devices addObject:deviceModel];
            }
            areaModel.devices = devices;
            
            [self.itemCluster insertObject:areaModel atIndex:0];

        }];
    }
    
    
    NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
    if (mutableArray != nil || [mutableArray count] != 0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        for (CSRDeviceEntity *deviceEntity in mutableArray) {
            if (![deviceEntity.shortName isEqualToString:@"RC350"]&&![deviceEntity.shortName isEqualToString:@"RC351"]) {
                [self.deviceEntitys addObject:deviceEntity];
                
                if (![deviceIdWasInAreaArray containsObject:deviceEntity.deviceId]) {
                    NSLog(@"uuid>>light>>%@",deviceEntity.uuid);
                    DeviceModel *deviceModel = [[DeviceModel alloc] init];
                    deviceModel.deviceId = deviceEntity.deviceId;
                    deviceModel.name = deviceEntity.name;
                    deviceModel.shortName = deviceEntity.shortName;
                    deviceModel.isForGroup = NO;
                    [self.itemCluster insertObject:deviceModel atIndex:0];
                }
            }
        }
    }
    
}

//获取设备状态接口、调光接口 的 反馈
- (void)updateItemClusterDeviceId:(NSNumber *)deviceId level:(NSNumber *)level powerState:(NSNumber *)powerState {
    NSLog(@"成功获取设备状态 deviceId：%@  level：%@  powerState：%@",deviceId,level,powerState);
    
    [self.itemCluster enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj isKindOfClass:[DeviceModel class]]) {
            DeviceModel *device = (DeviceModel *)obj;
            if ([device.deviceId isEqualToNumber:deviceId]) {
                
                device.level = level;
                device.powerState = powerState;
                *stop = YES;
            }
        }
        else if ([obj isKindOfClass:[AreaModel class]]) {
            AreaModel *area = (AreaModel *) obj;
            for (DeviceModel *device in area.devices) {
                if ([device.deviceId isEqualToNumber:deviceId]) {
                    
                    device.level = level;
                    device.powerState = powerState;
                    *stop = YES;
                }
            }
        }
        
    }];
    [self updateCollectionView];
    
}

//物理按钮反馈
- (void)physicalButtonActionCall: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *state = userInfo[@"powerState"];
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSNumber *level = userInfo[@"level"];
    
    [self.itemCluster enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj isKindOfClass:[DeviceModel class]]) {
            DeviceModel *device = (DeviceModel *)obj;
            if ([device.deviceId isEqualToNumber:deviceId]) {
                device.powerState = @([state integerValue]);
                device.level = level;
                *stop = YES;
            }
        }
        else if ([obj isKindOfClass:[AreaModel class]]) {
            AreaModel *area = (AreaModel *) obj;
            for (DeviceModel *device in area.devices) {
                if ([device.deviceId isEqualToNumber:deviceId]) {
                    device.level = level;
                    device.powerState = @([state integerValue]);
                    *stop = YES;
                }
            }
        }
    }];
    [self updateCollectionView];
}


- (void)actionForTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint touch = [sender locationInView:self.view];
        UIView *hitObject = [self.view hitTest:touch withEvent:nil];
        
        if ([hitObject isKindOfClass:[LightClusterCell class]]) {
            LightClusterCell *cell = (LightClusterCell *)hitObject;
            cell.ignoreUpdate = NO;
            BOOL isGroup = cell.isGroup;
            
            if (isGroup) {
                __block BOOL exist=NO;
                [cell.groupMember enumerateObjectsUsingBlock:^(DeviceModel *device, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([device.powerState boolValue]) {
                        exist = YES;
                        [[CSRDevicesManager sharedInstance] setPowerState:device.deviceId state:@(0)];
                    }
                }];
                if (!exist) {
                    [cell.groupMember enumerateObjectsUsingBlock:^(DeviceModel *device, NSUInteger idx, BOOL * _Nonnull stop) {
                        [[CSRDevicesManager sharedInstance] setPowerState:device.deviceId state:@(1)];
                    }];
                }
                
            }else{
                NSNumber *possibleDeviceId = cell.deviceID;
                if ([possibleDeviceId isEqualToNumber:@100000]) {
                    NSNumber *controlNum = cell.groupId;
                    
                    if ([controlNum isEqualToNumber:@1]) {
                        if ([[MeshServiceApi sharedInstance] getActiveBearer] == 0) {
//                            [[CSRBluetoothLE sharedInstance] setScanner:YES source:self];
//                            [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:YES];
                            PrimaryDeviceListController *pdlvc = [[PrimaryDeviceListController alloc] initWithItemPerSection:3 cellIdentifier:@"PrimaryItemCell"];
                            [self.navigationController pushViewController:pdlvc animated:YES];
                        }
                    }
                    
                    if ([controlNum isEqualToNumber:@0]) {
                        __block BOOL exist=NO;
                        [self.itemCluster enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([obj isKindOfClass:[DeviceModel class]]) {
                                DeviceModel *device = (DeviceModel *)obj;
                                if ([device.powerState boolValue]) {
                                    [[PowerModelApi sharedInstance] setPowerState:@(0) state:@(0) success:nil failure:nil];
//                                    [[PowerModelApi sharedInstance] setPowerState:@(0)
//                                                                            state:@(0)
//                                                                          success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable state) {
//                                                                              NSLog(@"state :%@", state);
//
//                                                                          } failure:^(NSError * _Nullable error) {
//                                                                              NSLog(@"error %@", error);
//                                                                          }];
                                    exist = YES;
                                    *stop = YES;
                                }
                            }
                            else if ([obj isKindOfClass:[AreaModel class]]) {
                                AreaModel *area = (AreaModel *) obj;
                                for (DeviceModel *device in area.devices) {
                                    if ([device.powerState boolValue]) {
                                        [[PowerModelApi sharedInstance] setPowerState:@(0) state:@(0) success:nil failure:nil];
//                                        [[PowerModelApi sharedInstance] setPowerState:@(0)
//                                                                                state:@(0)
//                                                                              success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable state) {
//                                                                                  NSLog(@"state :%@", state);
//
//                                                                              } failure:^(NSError * _Nullable error) {
//                                                                                  NSLog(@"error %@", error);
//                                                                              }];
                                        exist = YES;
                                        *stop = YES;
                                    }
                                }
                            }
//                            [[PowerModelApi sharedInstance] getState:@(0) success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable state) {
//
//                            } failure:^(NSError * _Nullable error) {
//
//                            }];
                        }];
                        if (exist) {
                            [self.itemCluster enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([obj isKindOfClass:[DeviceModel class]]) {
                                    DeviceModel *device = (DeviceModel *)obj;
                                    device.powerState = @(0);
                                }
                                if ([obj isKindOfClass:[AreaModel class]]) {
                                    AreaModel *area = (AreaModel *) obj;
                                    for (DeviceModel *device in area.devices) {
                                        device.powerState = @(0);
                                    }
                                }
                            }];
                            
                        }
                        
                        if (!exist) {
                            [[PowerModelApi sharedInstance] setPowerState:@(0) state:@(1) success:nil failure:nil];
//                            [[PowerModelApi sharedInstance] setPowerState:@(0)
//                                                                    state:@(1)
//                                                                  success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable state) {
//                                                                      NSLog(@"state :%@", state);
//
//                                                                  } failure:^(NSError * _Nullable error) {
//                                                                      NSLog(@"error %@", error);
//                                                                  }];
                            [self.itemCluster enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([obj isKindOfClass:[DeviceModel class]]) {
                                    DeviceModel *device = (DeviceModel *)obj;
                                    device.powerState = @(1);
                                }
                                if ([obj isKindOfClass:[AreaModel class]]) {
                                    AreaModel *area = (AreaModel *) obj;
                                    for (DeviceModel *device in area.devices) {
                                        device.powerState = @(1);
                                    }
                                }
                            }];
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"quanguanquankai" object:nil userInfo:@{@"allPowerState":@(!exist)}];
                        [self updateCollectionView];
                    }
                    
                }
                else
                {
                    [self actionWhenSelectCell:cell];
                    
                    if (self.allowGroupEdit) {
                        [cell showDeleteButton:YES];
                        [self.itemCluster enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([obj isKindOfClass:[DeviceModel class]]) {
                                DeviceModel *deviceModel = (DeviceModel *)obj;
                                if ([deviceModel.deviceId isEqualToNumber:cell.deviceID]) {
                                    deviceModel.isShowDeleteBtn = YES;
                                    *stop = YES;
                                }
                            }
                        }];
                        if (self.delegate && [self.delegate respondsToSelector:@selector(lightClusterControllerUpdateNumberOfSelectedLight:)]) {
                            [self.delegate lightClusterControllerUpdateNumberOfSelectedLight:[self numberOfLightBeenSelected]];  
                        }
                    }
                    
                    DeviceModel *deviceModel = [self.itemCluster objectAtIndex:[self dataIndexOfCellAtIndexPath:cell.myIndexpath]];
                    CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:deviceModel.deviceId];
                    if ([device.modelsSet containsObject:@(CSRMeshModelLIGHT)]) {
                        [[CSRDevicesManager sharedInstance] setSelectedDevice:device];
                        if (device) {

                            __block CSRmeshDevice *deviceb = device;
                            [self.itemCluster enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([obj isKindOfClass:[DeviceModel class]]) {
                                    DeviceModel *model = (DeviceModel *)obj;
                                    if ([model.deviceId isEqualToNumber:deviceb.deviceId]) {
                                        BOOL powerState = ![model.powerState boolValue];
                                        [[CSRDevicesManager sharedInstance] setPowerState:model.deviceId state:[NSNumber numberWithBool:powerState]];
//                                        if ([model.shortName isEqualToString:@"D350BT"] && powerState) {
//                                            [[LightModelApi sharedInstance] getState:device.deviceId success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
//                                                
//                                            } failure:^(NSError * _Nullable error) {
//                                                
//                                            }];
//                                        }
//                                        *stop = YES;
                                    }
                                }
                            }];
                        }
                    }
                }
            }
        }
    }
}

-(void) actionForLongPress:(UILongPressGestureRecognizer*)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint touch = [sender locationInView:sender.view];
        UIView *hitObject = [self.view hitTest:touch withEvent:nil];
        
        if ([hitObject isKindOfClass:[LightClusterCell class]]) {
            LightClusterCell *cell = (LightClusterCell *)hitObject;
            
            if (!cell.isGroup && ![cell.deviceID isEqualToNumber:@100000]) {

                DeviceDetailViewController *vc = [[DeviceDetailViewController alloc] init];
                
                DeviceModel *deviceModel = [self.itemCluster objectAtIndex:[self dataIndexOfCellAtIndexPath:cell.myIndexpath]];
                CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:deviceModel.deviceId];
                if ([device.modelsSet containsObject:@(CSRMeshModelLIGHT)]) {
                    [[CSRDevicesManager sharedInstance] setSelectedDevice:device];
                    
                    vc.powerState = deviceModel.powerState;
                    vc.level = deviceModel.level;
                    vc.lightDevice = device;
                    [self.deviceEntitys enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([deviceEntity.deviceId isEqualToNumber:deviceModel.deviceId]) {
                            vc.deviceEntity = deviceEntity;
                            *stop = YES;
                        }
                    }];
                    
                    
                }
                vc.handle = ^(){
                    [self reGetData];
                };
                
                UINavigationController *messenger = [[UINavigationController alloc] initWithRootViewController:vc];
                messenger.modalPresentationStyle = UIModalPresentationPopover;
                
                [self presentViewController:messenger animated:YES completion:nil];
                
                UIPopoverPresentationController *popover = messenger.popoverPresentationController;
                popover.permittedArrowDirections = UIPopoverArrowDirectionDown | UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight;
                popover.sourceRect = cell.bounds;
                popover.sourceView = cell;
            
            }
            else if (cell.isGroup) {
                AreaViewController *avc = [[AreaViewController alloc] initWithItemPerSection:3 cellIdentifier:@"LightClusterCell"];
                avc.navigationItem.title = cell.name;
                avc.areaMembers = [NSMutableArray arrayWithArray:cell.groupMember];
                avc.areaId = cell.groupId;
                avc.block = ^(){
                    [self reGetData];
                };
                [self.navigationController pushViewController:avc animated:YES];
            }
        }
    }
}

- (void)actionForPan:(UIPanGestureRecognizer*)sender {
    CGPoint translation = [sender translationInView:self.view];
    CGPoint touch = [sender locationInView:self.view];
    UIView *hitObject = [self.view hitTest:touch withEvent:nil];
    LightClusterCell *cell = (LightClusterCell*)hitObject;
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            direction = kCameraMoveDirectionNone;
            if ([hitObject isKindOfClass:[LightClusterCell class]]) {
                [self.improver beginImproving];
                
                _panCell = cell;
                _panCell.ignoreUpdate = YES;
                if (!cell.isGroup && ![cell.deviceID isEqualToNumber:@100000] && cell.isDimmer) {
                    self.controlTarget = cell;
                    self.slideBegin = YES;
                    [self.itemCluster enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj isKindOfClass:[DeviceModel class]]) {
                            DeviceModel *device = (DeviceModel *)obj;
                            if ([device.deviceId isEqualToNumber:cell.deviceID]) {
                                self.originBrightness = [device.level integerValue];
                            }
                        }
                    }];
                    return;
                }
                
                if (cell.isGroup) {
                    self.controlTarget = cell;
                    self.slideBegin = YES;
                    self.originBrightness = [self evenBrightnessOfLightCluster:cell.groupMember];
                    return;
                }
                
                
            }
        
            self.controlTarget = nil;
            self.slideBegin = NO;
            
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            if (direction == kCameraMoveDirectionNone) {
                direction= [self determineCameraDirectionIfNeeded:translation];
            }
            switch (direction) {
                case kCameraMoveDirectionUpOrDown:
                {
//                    NSLog(@"Start moving up of down");
                    isHorizontal = NO;
                
                    break;
                }
                 case kCameraMoveDirectionLeftOrRight:
                {
//                    NSLog(@"Start moving left of right");
                    isHorizontal = YES;
//                    NSLog(@"%f >>> %f",touch.x,touch.y);
                    NSInteger updateBrightness = [self.improver improveTouching:touch referencePoint:self.controlTarget.center primaryBrightness:self.originBrightness];//////
//                    NSLog(@">>>>>>>>> %ld  <<<<<<<< %f-- %f",(long)updateBrightness,touch.x,touch.y);
                    _panCell.isAlloc = YES;
                    if (updateBrightness < kMinBrighness) {
                        updateBrightness = kMinBrighness;
                    }
                    if (self.slideBegin && self.controlTarget) {
                        CGFloat brightness = updateBrightness/255.0;
                        [_panCell updateBrightness:brightness];
                        [self adjustLightBrightnessByTouching:touch];
                    }
                    
                    break;
                }
                    
                    
                default:
                    break;
            }
            
            
            
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            if (isHorizontal == YES) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    _panCell.ignoreUpdate = NO;
                });
                if (self.slideBegin && self.controlTarget) {
                    [self adjustLightBrightnessByTouching:touch];
                    self.controlTarget = nil;
                    self.slideBegin = NO;
                    [self hideBrightnessControlMaskView];
                }
            }
            
            break;
        }
        default:
        {
            self.controlTarget = nil;
            self.slideBegin = NO;
            [self hideBrightnessControlMaskView];
            break;
        }
    }
    
}

- (NSInteger)evenBrightnessOfLightCluster:(NSArray*)array {
    __block NSInteger evenBrightness = 0;
    if (array.count>0) {
        [array enumerateObjectsUsingBlock:^(DeviceModel *device, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([device.shortName isEqualToString:@"D350BT"]) {
                NSInteger fixStatus = [device.level integerValue]? [device.level integerValue]:0;
                evenBrightness += fixStatus;
            }
        }];
        return evenBrightness/array.count;
    }
    return 0;
}

- (CameraMoveDirection)determineCameraDirectionIfNeeded:(CGPoint)translation
{
    if (direction != kCameraMoveDirectionNone)
        return direction;
    if (fabs(translation.x) > gestureMinimumTranslation)
    {
        BOOL gestureHorizontal = NO;
        if (translation.y ==0.0)
            gestureHorizontal = YES;
        else
            gestureHorizontal = (fabs(translation.x / translation.y) >5.0);
        if (gestureHorizontal)
            return kCameraMoveDirectionLeftOrRight;
    }
    else if (fabs(translation.y) > gestureMinimumTranslation)
    {
        BOOL gestureVertical = NO;
        if (translation.x ==0.0)
            gestureVertical = YES;
        else
            gestureVertical = (fabs(translation.y / translation.x) >5.0);
        if (gestureVertical)
            return kCameraMoveDirectionUpOrDown;
    }
    return direction;
}

//brightness
- (void)adjustLightBrightnessByTouching:(CGPoint)touch{
    NSInteger updatedBrightness = [self.improver improveTouching:touch referencePoint:self.controlTarget.center primaryBrightness:self.originBrightness];
    if (updatedBrightness < kMinBrighness) {
        updatedBrightness = kMinBrighness;
    }
    CGFloat alphaRespond = updatedBrightness/255.0;
    
    [self updateBrightnessControlMaskView:alphaRespond brightness:updatedBrightness];
    
    if (self.controlTarget.isGroup) {
        [self.controlTarget.groupMember enumerateObjectsUsingBlock:^(DeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([model.shortName isEqualToString:@"S350BT"]) {
                if (updatedBrightness) {
                     [[CSRDevicesManager sharedInstance] setPowerState:model.deviceId state:@(1)];
                }else {
                     [[CSRDevicesManager sharedInstance] setPowerState:model.deviceId state:@(0)];
                }
            }else {
                CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:model.deviceId];
                if ([device.modelsSet containsObject:@(CSRMeshModelLIGHT)]) {
                    [device setLevel:updatedBrightness];
                }
            }
        }];
        
        
    }else{
        NSLog(@"+ + + + + + + %ld",updatedBrightness);
        CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:self.controlTarget.deviceID];
        if ([device.modelsSet containsObject:@(CSRMeshModelLIGHT)]) {
            [device setLevel:updatedBrightness];
        }
//        [[LightModelApi sharedInstance] setLevel:self.controlTarget.deviceID level:[NSNumber numberWithInteger:updatedBrightness] success:nil failure:nil];
        
    }
}

- (void)updateBrightnessControlMaskView:(CGFloat)alpha brightness:(NSInteger)brightness {
    if (!self.maskView.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:self.maskView];
    }
    long percentage = ((float)brightness)*100/255.0;
    [self.maskView updateProgress:alpha withText:[NSString stringWithFormat:@"%li",percentage]];
}

- (void)hideBrightnessControlMaskView {
    [self.maskView removeFromSuperview];
}


- (ControlMaskView*)maskView {
    if (!_maskView) {
        _maskView = [[ControlMaskView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _maskView;
}

#pragma mark - LightClusterCellDelegate

- (void)specialFlowLayoutCollectionViewSuperCell:(UICollectionViewCell *)cell didClickOnDeleteButton:(UIButton *)sender {
    LightClusterCell *lightCell = (LightClusterCell *)cell;
    if (lightCell.isGroup) {
        if (lightCell.groupMember!=nil && lightCell.groupMember.count >0) {
            [lightCell.groupMember enumerateObjectsUsingBlock:^(DeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
                for (CSRDeviceEntity *localDeviceEntity in self.deviceEntitys) {
                    if ([localDeviceEntity.deviceId isEqualToNumber:model.deviceId]) {
                        NSNumber *groupIndex = [self getValueByIndex:localDeviceEntity];
                        
                        [[GroupModelApi sharedInstance] setModelGroupId:localDeviceEntity.deviceId
                                                                modelNo:@(0xff)
                                                             groupIndex:groupIndex // index of the array where that value was located
                                                               instance:@(0)
                                                                groupId:@(0) //0 for deleting
                                                                success:^(NSNumber *deviceId,
                                                                          NSNumber *modelNo,
                                                                          NSNumber *groupIndex,
                                                                          NSNumber *instance,
                                                                          NSNumber *desired) {
                                                                    
                                                                    uint16_t *dataToModify = (uint16_t*)localDeviceEntity.groups.bytes;
                                                                    NSMutableArray *desiredGroups = [NSMutableArray new];
                                                                    for (int count=0; count < localDeviceEntity.groups.length/2; count++, dataToModify++) {
                                                                        NSNumber *groupValue = @(*dataToModify);
                                                                        [desiredGroups addObject:groupValue];
                                                                    }
                                                                    
                                                                    if (groupIndex && [groupIndex integerValue]<desiredGroups.count) {
                                                                        
                                                                        NSNumber *areaValue = [desiredGroups objectAtIndex:[groupIndex integerValue]];
                                                                        
                                                                        CSRAreaEntity *areaEntity = [[[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"CSRAreaEntity" withPredicate:@"areaID == %@", areaValue] firstObject];
                                                                        
                                                                        if (areaEntity) {
                                                                            
                                                                            [_areaEntity removeDevicesObject:localDeviceEntity];
                                                                        }
                                                                        
                                                                        
                                                                        NSMutableData *myData = (NSMutableData*)localDeviceEntity.groups;
                                                                        uint16_t desiredValue = [desired unsignedShortValue];
                                                                        int groupIndexInt = [groupIndex intValue];
                                                                        if (groupIndexInt>-1) {
                                                                            uint16_t *groups = (uint16_t *) myData.mutableBytes;
                                                                            *(groups + groupIndexInt) = desiredValue;
                                                                        }
                                                                        localDeviceEntity.groups = (NSData*)myData;
                                                                        
                                                                        [[CSRDatabaseManager sharedInstance] saveContext];
                                                                    }
                                                                    
                                                                    
                                                                } failure:^(NSError *error) {
                                                                    NSLog(@"mesh timeout");
                                                                    
                                                                }];
                        
                        [NSThread sleepForTimeInterval:0.3];
                        *stop = YES;
                        
                    }
                }
            }];
        }
        
        NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
        [areaMutableArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[CSRAreaEntity class]]) {
                CSRAreaEntity *areaEntity = obj;
                if ([areaEntity.areaID isEqualToNumber:lightCell.groupId]) {
                    [[CSRDevicesManager sharedInstance] removeAreaWithAreaId:areaEntity.areaID];
                    [[CSRAppStateManager sharedInstance].selectedPlace removeAreasObject:areaEntity];
                    [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:areaEntity];
                    
                    *stop = YES;
                }
                
            }
        }];
        [self reGetData];
    }
    else
    {
        [lightCell showDeleteButton:NO];
        if (self.delegate && [self.delegate respondsToSelector:@selector(lightClusterControllerUpdateNumberOfSelectedLight:)]) {
            [self.delegate lightClusterControllerUpdateNumberOfSelectedLight:[self numberOfLightBeenSelected]];
        }
        [self.itemCluster enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[DeviceModel class]]) {
                DeviceModel *deviceModel = (DeviceModel *)obj;
                if ([deviceModel.deviceId isEqualToNumber:lightCell.deviceID]) {
                    deviceModel.isShowDeleteBtn = NO;
                    *stop = YES;
                }
            }
        }];
        [self actionWhenCancelSelectCell:cell];
    }
}

//子类使用到的方法
- (void)disableSomeFeatureOfSuper {
    self.longPressDetect.enabled = NO;
}

- (void)onlyYou:(NSNumber *)deviceId {
//    [self.lightPanel.visibleCells enumerateObjectsUsingBlock:^(LightClusterCell *cell,NSUInteger idx,BOOL *stop){
//        if (![cell.deviceID isEqualToNumber:deviceId]) {
//            [cell showDeleteButton:NO];
//        }
//    }];
    [self.itemCluster enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[DeviceModel class]]) {
            DeviceModel *deviceModel = (DeviceModel *)obj;
            if ([deviceModel.deviceId isEqualToNumber:deviceId]) {
                deviceModel.isShowDeleteBtn = YES;
            }else {
                deviceModel.isShowDeleteBtn = NO;
            }
        }
    }];
    [self.lightPanel reloadData];
}

- (void)actionWhenSelectCell:(UICollectionViewCell*)cell {
    //override in subclass
}

- (void)actionWhenCancelSelectCell:(UICollectionViewCell *)cell {
    //override in subclass
}

//- (void)updateReusedCell:(UICollectionViewCell*)cell {
//    if ([cell isKindOfClass:[LightClusterCell class]]) {
//        LightClusterCell *lightClusterCell = (LightClusterCell*)cell;
//
//        NSInteger index = [self dataIndexOfCellAtIndexPath:lightClusterCell.myIndexpath];
//        id profile = [self.itemCluster objectAtIndex:index];
//
//        if ([profile isKindOfClass:[CSRDeviceEntity class]]) {
//            CSRDeviceEntity *singleLightProfile = profile;
//
//            if (!singleLightProfile.isAssociated) {
//                [lightClusterCell showOfflineUI];
//            }
//            else {
//                [lightClusterCell removeOfflineUI];
//            }
//        }
//    }
//}

//添加分组时判断已经选择了几个单灯
- (NSInteger)numberOfLightBeenSelected {
    __block NSInteger count = 0;
    
    [self.lightPanel.visibleCells enumerateObjectsUsingBlock:^(LightClusterCell *cell,NSUInteger idx,BOOL *stop){
        if ([cell isGroupOrganizingSelected]) {
            count += 1;
        }
    }];
   
    return count;
}

//点导航栏左键group开始添加组的编辑
- (void)beginGroupOrganizing {
    self.allowGroupEdit = YES;
    
    [self.itemCluster enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[AreaModel class]]) {
            AreaModel *areaModel = (AreaModel *)obj;
            areaModel.isShowDeleteBtn = YES;
        }
    }];
    [self.lightPanel reloadData];
}

//点done键结束组的编辑
- (void)endGroupOrganizing {
    self.allowGroupEdit = NO;
    
    [self.itemCluster enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[AreaModel class]]) {
            AreaModel *areaModel = (AreaModel *)obj;
            areaModel.isShowDeleteBtn = NO;
        }
        if ([obj isKindOfClass:[DeviceModel class]]) {
            DeviceModel *deviceModel = (DeviceModel *) obj;
            deviceModel.isShowDeleteBtn = NO;
        }
    }];
    [self.lightPanel reloadData];
    
}

//点文件夹键开始添加分组
- (void)groupOrganizingFinalStep {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.color = [UIColor whiteColor];
    [self.view addSubview:spinner];
    spinner.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [spinner startAnimating];
    
    NSNumber *areaIdNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRAreaEntity"];
    NSString *name = [NSString stringWithFormat:@"group %@",areaIdNumber];
    _areaEntity = [[CSRDevicesManager sharedInstance] addMeshArea:name];
    [[CSRAppStateManager sharedInstance].selectedPlace addAreasObject:_areaEntity];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    __block NSMutableArray *theAddArray = [[NSMutableArray alloc] init];
    [self.lightPanel.visibleCells enumerateObjectsUsingBlock:^(LightClusterCell *cell,NSUInteger idx,BOOL *stop){
        if ([cell isGroupOrganizingSelected]) {
            [theAddArray addObject:cell.deviceID];
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:cell.deviceID];
            NSNumber *groupIndex = [self getValueByIndex:deviceEntity];
            if (![groupIndex  isEqual:@(-1)])
            {
                [[GroupModelApi sharedInstance] setModelGroupId:deviceEntity.deviceId
                                                        modelNo:@(0xff)
                                                     groupIndex:groupIndex // index of the array where there is first 0 or -1
                                                       instance:@(0)
                                                        groupId:_areaEntity.areaID //id of area
                                                        success:^(NSNumber *deviceId,
                                                                  NSNumber *modelNo,
                                                                  NSNumber *groupIndex,
                                                                  NSNumber *instance,
                                                                  NSNumber *desired) {
                                                            
                                                            NSMutableData *myData = (NSMutableData*)deviceEntity.groups;
                                                            uint16_t desiredValue = [desired unsignedShortValue];
                                                            int groupIndexInt = [groupIndex intValue];
                                                            if (groupIndexInt>-1) {
                                                                uint16_t *groups = (uint16_t *) myData.mutableBytes;
                                                                *(groups + groupIndexInt) = desiredValue;
                                                            }
                                                            
                                                            deviceEntity.groups = (NSData*)myData;
                                                            NSLog(@"deviceEntity.groups :%@", myData);
                                                            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId: desired];
                                                            
                                                            if (areaEntity) {
                                                                //NSLog(@"deviceEntity2 :%@", deviceEntity);
                                                                [_areaEntity addDevicesObject:deviceEntity];
                                                            }
                                                            [[CSRDatabaseManager sharedInstance] saveContext];
                                                            
                                                            
                                                        } failure:^(NSError *error) {
                                                            NSLog(@"mesh timeout");
                                                            
                                                        }];
            } else {
                NSLog(@"Device has 4 areas or something went wrong");
            }
            [NSThread sleepForTimeInterval:0.3];
        }
    }];
    
    
    [self performSelector:@selector(lastStepOfgroupOrganizingFinalStep:) withObject:spinner afterDelay:4];

}

- (void)lastStepOfgroupOrganizingFinalStep:(UIActivityIndicatorView*)spin{
    [spin stopAnimating];
    [self reGetData];
}

//method to getIndexByValue
- (NSNumber *) getValueByIndex:(CSRDeviceEntity*)deviceEntity
{
    uint16_t *dataToModify = (uint16_t*)deviceEntity.groups.bytes;
    
    for (int count=0; count < deviceEntity.groups.length/2; count++, dataToModify++) {
        if (*dataToModify == [_areaEntity.areaID unsignedShortValue]) {
            return @(count);
            
        } else if (*dataToModify == 0){
            return @(count);
        }
    }
    
    return @(-1);
}

- (NSMutableArray *)deviceEntitys {
    if (!_deviceEntitys) {
        _deviceEntitys = [[NSMutableArray alloc] init];
    }
    return _deviceEntitys;
}

- (void)setAllDevicesTime {
    for (CSRDeviceEntity *deviceEntity in self.deviceEntitys) {
        [[DataModelManager shareInstance] setDeviceTime:deviceEntity.deviceId];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
