//
//  DeviceModelManager.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/1/16.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "DeviceModelManager.h"
#import "CSRDeviceEntity.h"
#import "CSRAppStateManager.h"

#import <CSRmesh/PowerModelApi.h>
#import <CSRmesh/LightModelApi.h>

#import "DataModelManager.h"

#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"

@interface DeviceModelManager ()<LightModelApiDelegate,PowerModelApiDelegate>
{
    NSTimer *timer;
    NSNumber *currentLevel;
    UIGestureRecognizerState currentState;
    PanGestureMoveDirection moveDirection;
    NSNumber *currentChannel;
    
    NSTimer *CTTimer;
    NSNumber *CTCurrentCT;
    UIGestureRecognizerState CTCurrentState;
    
    NSTimer *colorTimer;
    UIColor *currentColor;
    UIGestureRecognizerState colorCurrentState;
    
    BOOL appControlling;
    BOOL groupControlling;
    
    NSData *applyCmd;
    NSInteger applyRetryCount;
    NSNumber *applyDeviceID;
}

@property (nonatomic, strong) NSMutableDictionary *mcNameDataDic;

@end

@implementation DeviceModelManager

+ (DeviceModelManager *)sharedInstance {
    static dispatch_once_t onceToken;
    static DeviceModelManager *shared = nil;
    dispatch_once(&onceToken, ^{
        shared = [[DeviceModelManager alloc] init];
    });
    return shared;
}

- (id)init {
    self = [super init];
    if (self) {
        _allDevices = [NSMutableArray new];
        [[LightModelApi sharedInstance] addDelegate:self];
        [[PowerModelApi sharedInstance] addDelegate:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(physicalButtonActionCall:) name:@"physicalButtonActionCall" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(RGBCWDeviceActionCall:) name:@"RGBCWDeviceActionCall" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fanControllerCall:) name:@"fanControllerCall" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(multichannelActionCall:) name:@"multichannelActionCall" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(childrenModelState:)
                                                     name:@"childrenModelState"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(remoteControlScene:)
                                                     name:@"remoteControlScene"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(remoteControlGroup:)
                                                     name:@"remoteControlGroup"
                                                   object:nil];
        
        [DataModelManager shareInstance];
        
        NSSet *allDevices = [CSRAppStateManager sharedInstance].selectedPlace.devices;
        if (allDevices != nil && [allDevices count] != 0) {
            for (CSRDeviceEntity *deviceEntity in allDevices) {
                if ([CSRUtilities belongToMainVCDevice:deviceEntity.shortName] || [CSRUtilities belongToLightSensor:deviceEntity.shortName]) {
                    DeviceModel *model = [[DeviceModel alloc] init];
                    model.deviceId = deviceEntity.deviceId;
                    model.shortName = deviceEntity.shortName;
                    model.name = deviceEntity.name;
                    
                    model.powerState = @0;
                    model.channel1PowerState = NO;
                    model.channel2PowerState = NO;
                    model.channel3PowerState = NO;
                    model.level = @0;
                    model.channel1Level = 0;
                    model.channel2Level = 0;
                    model.channel3Level = 0;
                    
                    [_allDevices addObject:model];
                }
            }
        }
    }
    return self;
}

- (void)getAllDevicesState {
    [[MeshServiceApi sharedInstance] setRetryCount:@0];
    [[LightModelApi sharedInstance] getState:@(0) success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
    } failure:^(NSError * _Nullable error) {
    }];
    [[MeshServiceApi sharedInstance] setRetryCount:@3];
}

#pragma mark - LightModelApiDelegate

- (void)didGetLightState:(NSNumber *)deviceId red:(NSNumber *)red green:(NSNumber *)green blue:(NSNumber *)blue level:(NSNumber *)level powerState:(NSNumber *)powerState colorTemperature:(NSNumber *)colorTemperature supports:(NSNumber *)supports meshRequestId:(NSNumber *)meshRequestId {
    NSLog(@"调光回调 deviceId--> %@ powerState--> %@ level--> %@ colorTemperature--> %@ supports--> %@ \n red -> %@ -> green -> %@ blue -> %@ ",deviceId,powerState,level,colorTemperature,supports,red,green,blue);
    if (groupControlling) {
        return;
    }
    
    DeviceModel *model;
    for (DeviceModel *m in _allDevices) {
        if ([m.deviceId isEqualToNumber:deviceId]) {
            model = m;
            break;
        }
    }
    if (!model) {
        model = [[DeviceModel alloc] init];
        model.deviceId = deviceId;
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        model.shortName = device.shortName;
        model.name = device.name;
        [_allDevices addObject:model];
    }
    model.isleave = NO;
    if ([CSRUtilities belongToFanController:model.shortName]) {
        model.fanState = [powerState boolValue];
        model.lampState = [supports boolValue];
        NSInteger l = [level integerValue];
        if (l > 0 && l <= 85) {
            model.fansSpeed = 0;
        }else if (l > 85 && l <= 170) {
            model.fansSpeed = 1;
        }else if (l > 170 && l <= 255) {
            model.fansSpeed = 2;
        }
    }else if ([CSRUtilities belongToTwoChannelDimmer:model.shortName]
              || [CSRUtilities belongToSocketTwoChannel:model.shortName]
              || [CSRUtilities belongToTwoChannelCurtainController:model.shortName]
              || [CSRUtilities belongToTwoChannelSwitch:model.shortName]) {
        model.channel1PowerState = [powerState boolValue];
        model.channel1Level = [level integerValue] > 3 ? [level integerValue] : 3;
        model.channel2PowerState = [red boolValue];
        model.channel2Level = [green integerValue] > 3 ? [green integerValue] : 3;
        model.powerState = @([powerState boolValue] || [red boolValue]);
        NSInteger l = [level integerValue] > [green integerValue] ? [level integerValue] : [green integerValue];
        model.level = @(l > 3 ? l : 3);
    }else if ([CSRUtilities belongToThreeChannelSwitch:model.shortName]
              || [CSRUtilities belongToThreeChannelDimmer:model.shortName]) {
        model.channel1PowerState = [powerState boolValue];
        model.channel1Level =  [level integerValue] > 3 ? [level integerValue] : 3;
        model.channel2PowerState = [red boolValue];
        model.channel2Level = [green integerValue] > 3 ? [green integerValue] : 3;
        model.channel3PowerState = [blue boolValue];
        model.channel3Level = [colorTemperature integerValue] > 3 ? [colorTemperature integerValue] : 3;
        model.powerState = @([powerState boolValue] || [red boolValue] || [blue boolValue]);
        NSInteger l = ([level integerValue] > [green integerValue] ? [level integerValue] : [green integerValue]) > [colorTemperature integerValue] ? ([level integerValue] > [green integerValue] ? [level integerValue] : [green integerValue]) : [colorTemperature integerValue];
        model.level = @(l > 3 ? l : 3);
    }else if ([CSRUtilities belongToThermoregulator:model.shortName]) {
        model.powerState = powerState;
        model.channel1PowerState = [powerState boolValue];
        model.level = level;
        model.channel1Level = [level integerValue];
        model.red = red;
        model.green = green;
        model.blue = blue;
        model.colorTemperature = colorTemperature;
        model.supports = supports;
    }else {
        model.powerState = powerState;
        model.channel1PowerState = [powerState boolValue];
        model.level = [level integerValue] > 3 ? level : @3;
        model.channel1Level = [level integerValue] > 3 ? [level integerValue] : 3;
        model.red = red;
        model.green = green;
        model.blue = blue;
        model.colorTemperature = colorTemperature;
        model.supports = supports;
    }
    
    if (appControlling) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(1)}];
}

#pragma mark - PowerModelApiDelegate

- (void)didGetPowerState:(NSNumber *)deviceId state:(NSNumber *)state meshRequestId:(NSNumber *)meshRequestId {
    if (groupControlling) {
        return;
    }
    NSLog(@"开关回调 deviceId --> %@ powerState--> %@",deviceId,state);
    DeviceModel *model;
    for (DeviceModel *m in _allDevices) {
        if ([m.deviceId isEqualToNumber:deviceId]) {
            model = m;
            break;
        }
    }
    if (!model) {
        model = [[DeviceModel alloc] init];
        model.deviceId = deviceId;
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        model.shortName = device.shortName;
        model.name = device.name;
        [_allDevices addObject:model];
    }
    model.isleave = NO;
    model.powerState = state;
    model.channel1PowerState = [state boolValue];
    model.channel2PowerState = [state boolValue];
    model.channel3PowerState = [state boolValue];
    model.fanState = [state boolValue];
    model.lampState = [state boolValue];
    
    if (appControlling) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"state":state,@"deviceId":deviceId,@"channel":@(1)}];
}


#pragma mark - private methods

- (DeviceModel *)getDeviceModelByDeviceId:(NSNumber *)deviceId {
    if (deviceId) {
        for (DeviceModel *model in _allDevices) {
            if ([model.deviceId isEqualToNumber:deviceId]) {
                return model;
            }
        }
    }
    return nil;
}

- (void)setPowerStateWithDeviceId:(NSNumber *)deviceId channel:(NSNumber *)channel withPowerState:(BOOL)powerState {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelAppControlling) object:nil];
    appControlling = YES;
    [self performSelector:@selector(cancelAppControlling) withObject:nil afterDelay:4.0];
    
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    if ([channel integerValue] == 1) {
        if ([deviceId integerValue] > 32768) {
            [[PowerModelApi sharedInstance] setPowerState:deviceId state:@(powerState) success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable state) {
                
            } failure:^(NSError * _Nullable error) {
                NSLog(@"error : %@",error);
                DeviceModel *model = [self getDeviceModelByDeviceId:deviceId];
                model.isleave = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"chennel":@(1)}];
            }];
            DeviceModel *model = [self getDeviceModelByDeviceId:deviceId];
            model.powerState = @(powerState);
            model.channel1PowerState = powerState;
            model.channel2PowerState = powerState;
            model.channel3PowerState = powerState;
            model.fanState = powerState;
            model.lampState = powerState;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@1}];
        }else {
            groupControlling = YES;
            [[PowerModelApi sharedInstance] setPowerState:deviceId state:@(powerState) success:nil failure:nil];
            CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:deviceId];
            for (CSRDeviceEntity *member in area.devices) {
                for (DeviceModel *model in _allDevices) {
                    if ([model.deviceId isEqualToNumber:member.deviceId]) {
                        model.powerState = @(powerState);
                        model.channel1PowerState = powerState;
                        model.channel2PowerState = powerState;
                        model.channel3PowerState = powerState;
                        model.fanState = powerState;
                        model.lampState = powerState;
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceId,@"channel":@1}];
                        break;
                    }
                }
            }
        }
        
    }else {
        DeviceModel *d = [self getDeviceModelByDeviceId:deviceId];
        NSInteger l = 0;
        if ([channel integerValue] == 2) {
            
            l = d.channel1Level;
            
            d.channel1PowerState = powerState;
            if ([CSRUtilities belongToTwoChannelSwitch:d.shortName]
                || [CSRUtilities belongToTwoChannelDimmer:d.shortName]
                || [CSRUtilities belongToSocketTwoChannel:d.shortName]
                || [CSRUtilities belongToTwoChannelCurtainController:d.shortName]) {
                d.powerState = @(d.channel1PowerState || d.channel2PowerState);
            }else if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]
                      || [CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@2}];
            
        }else if ([channel integerValue] == 3) {
            
            l = d.channel2Level;
            
            d.channel2PowerState = powerState;
            if ([CSRUtilities belongToTwoChannelSwitch:d.shortName]
                || [CSRUtilities belongToTwoChannelDimmer:d.shortName]
                || [CSRUtilities belongToSocketTwoChannel:d.shortName]
                || [CSRUtilities belongToTwoChannelCurtainController:d.shortName]) {
                d.powerState = @(d.channel1PowerState || d.channel2PowerState);
            }else if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]
                      || [CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@3}];
            
        }else if ([channel integerValue] == 5) {
            
            l = d.channel3Level;
            
            d.channel3PowerState = powerState;
            if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]
                || [CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@5}];
            
        }else if ([channel integerValue] == 4) {
            
            l =  d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level;
            
            d.channel1PowerState = powerState;
            d.channel2PowerState = powerState;
            if ([CSRUtilities belongToTwoChannelSwitch:d.shortName]
                || [CSRUtilities belongToTwoChannelDimmer:d.shortName]
                || [CSRUtilities belongToSocketTwoChannel:d.shortName]
                || [CSRUtilities belongToTwoChannelCurtainController:d.shortName]) {
                d.powerState = @(d.channel1PowerState || d.channel2PowerState);
            }else if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]
                      || [CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@4}];
            
        }else if ([channel integerValue] == 7) {
            
            l = d.channel2Level > d.channel3Level ? d.channel2Level : d.channel3Level;
            
            d.channel2PowerState = powerState;
            d.channel3PowerState = powerState;
            if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]
                || [CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@7}];
            
        }else if ([channel integerValue] == 6) {
            
            l = d.channel1Level > d.channel3Level ? d.channel1Level : d.channel3Level;
            d.channel1PowerState = powerState;
            d.channel3PowerState = powerState;
            if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]
                || [CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@6}];
            
        }else if ([channel integerValue] == 8) {
            
            d.channel1PowerState = powerState;
            d.channel2PowerState = powerState;
            d.channel3PowerState = powerState;
            l = (d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) > d.channel3Level ? (d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) : d.channel3Level;
            if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]
                || [CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@8}];
            
        }
        Byte byte[] = {0x51, 0x05, [channel integerValue]-1, 0x00, 0x01, powerState, l};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:7];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:deviceId data:cmd];
    }
}

- (void)setLevelWithDeviceId:(NSNumber *)deviceId channel:(NSNumber *)channel withLevel:(NSNumber *)level withState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction {
    currentState = state;
    currentLevel = level;
    moveDirection = direction;
    currentChannel = channel;
    if (state == UIGestureRecognizerStateBegan) {
        if (timer) {
            [timer invalidate];
            timer = nil;
        }
        timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(timerMethod:) userInfo:deviceId repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
}

- (void)timerMethod:(NSTimer *)infotimer {
    @synchronized (self) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelAppControlling) object:nil];
        appControlling = YES;
        [self performSelector:@selector(cancelAppControlling) withObject:nil afterDelay:4.0];
        
        NSNumber *deviceId = infotimer.userInfo;
        if (moveDirection == PanGestureMoveDirectionHorizontal) {
            if ([currentChannel integerValue] == 1) {
                
                if ([deviceId integerValue] > 32768) {
                    [[LightModelApi sharedInstance] setLevel:deviceId level:currentLevel success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                        
                    } failure:^(NSError * _Nullable error) {
                        NSLog(@"error : >>>> %@",error);
                        DeviceModel *model = [self getDeviceModelByDeviceId:deviceId];
                        model.isleave = YES;
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(1)}];
                    }];
                    
                    DeviceModel *model = [self getDeviceModelByDeviceId:deviceId];
                    if ([currentLevel integerValue] == 0) {
                        model.powerState = @(0);
                        model.channel1PowerState = 0;
                        model.channel2PowerState = 0;
                        model.channel3PowerState = 0;
                        model.fanState = 0;
                        model.lampState = 0;
                    }else {
                        model.powerState = @(1);
                        model.channel1PowerState = 1;
                        model.channel2PowerState = 1;
                        model.channel3PowerState = 1;
                        model.fanState = 1;
                        model.lampState = 1;
                        
                        model.level = currentLevel;
                        model.channel1Level = [currentLevel integerValue];
                        model.channel2Level = [currentLevel integerValue];
                        model.channel3Level = [currentLevel integerValue];
                        if ([CSRUtilities belongToFanController:model.shortName]) {
                            NSInteger l = [currentLevel integerValue];
                            if (l > 0 && l <= 85) {
                                model.fansSpeed = 0;
                            }else if (l > 85 && l <= 170) {
                                model.fansSpeed = 1;
                            }else if (l > 170 && l <= 255) {
                                model.fansSpeed = 2;
                            }
                        }
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@1}];
                }else {
                    groupControlling = YES;
                    [[LightModelApi sharedInstance] setLevel:deviceId level:currentLevel success:nil failure:nil];
                    
                    CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:deviceId];
                    for (CSRDeviceEntity *member in area.devices) {
                        for (DeviceModel *model in _allDevices) {
                            if ([model.deviceId isEqualToNumber:member.deviceId]) {
                                if ([currentLevel integerValue] == 0) {
                                    model.powerState = @(0);
                                    model.channel1PowerState = 0;
                                    model.channel2PowerState = 0;
                                    model.channel3PowerState = 0;
                                    model.fanState = 0;
                                    model.lampState = 0;
                                }else {
                                    model.powerState = @(1);
                                    model.channel1PowerState = 1;
                                    model.channel2PowerState = 1;
                                    model.channel3PowerState = 1;
                                    model.fanState = 1;
                                    model.lampState = 1;
                                    
                                    model.level = currentLevel;
                                    model.channel1Level = [currentLevel integerValue];
                                    model.channel2Level = [currentLevel integerValue];
                                    model.channel3Level = [currentLevel integerValue];
                                    if ([CSRUtilities belongToFanController:model.shortName]) {
                                        NSInteger l = [currentLevel integerValue];
                                        if (l > 0 && l <= 85) {
                                            model.fansSpeed = 0;
                                        }else if (l > 85 && l <= 170) {
                                            model.fansSpeed = 1;
                                        }else if (l > 170 && l <= 255) {
                                            model.fansSpeed = 2;
                                        }
                                    }
                                }
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceId,@"channel":@1}];
                                break;
                            }
                        }
                    }
                }
                
            }else {
                BOOL p = [currentLevel integerValue] == 0 ? NO : YES;
                Byte byte[] = {0x51, 0x05, [currentChannel integerValue]-1, 0x00, 0x03, p, [currentLevel integerValue]};
                NSData *cmd = [[NSData alloc]initWithBytes:byte length:7];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:deviceId data:cmd];
                
                DeviceModel *d = [self getDeviceModelByDeviceId:deviceId];
                if ([currentChannel integerValue] == 2) {
                    if ([currentLevel integerValue] == 0) {
                        d.channel1PowerState = 0;
                    }else {
                        d.channel1PowerState = 1;
                        d.channel1Level = [currentLevel integerValue];
                    }
                    if ([CSRUtilities belongToTwoChannelDimmer:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState);
                        d.level = @(d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level);
                    }else if ([CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                        d.level = @((d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) > d.channel3Level ? (d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) : d.channel3Level);
                    }else if ([CSRUtilities belongToTwoChannelSwitch:d.shortName]
                              || [CSRUtilities belongToSocketTwoChannel:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState);
                    }else if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@2}];
                }else if ([currentChannel integerValue] == 3) {
                    if ([currentLevel integerValue] == 0) {
                        d.channel2PowerState = 0;
                    }else {
                        d.channel2PowerState = 1;
                        d.channel2Level = [currentLevel integerValue];
                    }
                    if ([CSRUtilities belongToTwoChannelDimmer:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState);
                        d.level = @(d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level);
                    }else if ([CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                        d.level = @((d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) > d.channel3Level ? (d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) : d.channel3Level);
                    }else if ([CSRUtilities belongToTwoChannelSwitch:d.shortName]
                              || [CSRUtilities belongToSocketTwoChannel:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState);
                    }else if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@3}];
                }else if ([currentChannel integerValue] == 5) {
                    if ([currentLevel integerValue] == 0) {
                        d.channel3PowerState = 0;
                    }else {
                        d.channel3PowerState = 1;
                        d.channel3Level = [currentLevel integerValue];
                    }
                    if ([CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                        d.level = @((d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) > d.channel3Level ? (d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) : d.channel3Level);
                    }else if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@5}];
                }else if ([currentChannel integerValue] == 4) {
                    if ([currentLevel integerValue] == 0) {
                        d.channel1PowerState = 0;
                        d.channel2PowerState = 0;
                    }else {
                        d.channel1PowerState = 1;
                        d.channel1Level = [currentLevel integerValue];
                        d.channel2PowerState = 1;
                        d.channel2Level = [currentLevel integerValue];
                    }
                    if ([CSRUtilities belongToTwoChannelDimmer:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState);
                        d.level = @(d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level);
                    }else if ([CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                        d.level = @((d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) > d.channel3Level ? (d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) : d.channel3Level);
                    }else if ([CSRUtilities belongToTwoChannelSwitch:d.shortName]
                              || [CSRUtilities belongToSocketTwoChannel:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState);
                    }else if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@4}];
                }else if ([currentChannel integerValue] == 6) {
                    if ([currentLevel integerValue] == 0) {
                        d.channel1PowerState = 0;
                        d.channel3PowerState = 0;
                    }else {
                        d.channel1PowerState = 1;
                        d.channel1Level = [currentLevel integerValue];
                        d.channel3PowerState = 1;
                        d.channel3Level = [currentLevel integerValue];
                    }
                    if ([CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                        d.level = @((d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) > d.channel3Level ? (d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) : d.channel3Level);
                    }else if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@6}];
                }else if ([currentChannel integerValue] == 7) {
                    if ([currentLevel integerValue] == 0) {
                        d.channel2PowerState = 0;
                        d.channel3PowerState = 0;
                    }else {
                        d.channel2PowerState = 1;
                        d.channel2Level = [currentLevel integerValue];
                        d.channel3PowerState = 1;
                        d.channel3Level = [currentLevel integerValue];
                    }
                    if ([CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                        d.level = @((d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) > d.channel3Level ? (d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) : d.channel3Level);
                    }else if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@7}];
                }else if ([currentChannel integerValue] == 8) {
                    if ([currentLevel integerValue] == 0) {
                        d.channel1PowerState = 0;
                        d.channel2PowerState = 0;
                        d.channel3PowerState = 0;
                    }else {
                        d.channel1PowerState = 1;
                        d.channel1Level = [currentLevel integerValue];
                        d.channel2PowerState = 1;
                        d.channel2Level = [currentLevel integerValue];
                        d.channel3PowerState = 1;
                        d.channel3Level = [currentLevel integerValue];
                    }
                    if ([CSRUtilities belongToThreeChannelDimmer:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                        d.level = @((d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) > d.channel3Level ? (d.channel1Level > d.channel2Level ? d.channel1Level : d.channel2Level) : d.channel3Level);
                    }else if ([CSRUtilities belongToThreeChannelSwitch:d.shortName]) {
                        d.powerState = @(d.channel1PowerState || d.channel2PowerState || d.channel3PowerState);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@8}];
                }
            }
        }
        
        if (currentState == UIGestureRecognizerStateEnded) {
            NSLog(@"定时器结束！！");
            [timer invalidate];
            timer = nil;
        }
    }
}

-(void)setColorTemperatureWithDeviceId:(NSNumber *)deviceId withColorTemperature:(NSNumber *)colorTemperature withState:(UIGestureRecognizerState)state {
    CTCurrentState = state;
    CTCurrentCT = colorTemperature;
    if (state == UIGestureRecognizerStateBegan) {
        if (CTTimer) {
            [CTTimer invalidate];
            CTTimer = nil;
        }
        CTTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(CTTimerMethod:) userInfo:deviceId repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:CTTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)CTTimerMethod:(NSTimer *)infotimer {
    @synchronized (self) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelAppControlling) object:nil];
        appControlling = YES;
        [self performSelector:@selector(cancelAppControlling) withObject:nil afterDelay:4.0];
        
        NSNumber *deviceId = infotimer.userInfo;
        [[LightModelApi sharedInstance] setColorTemperature:deviceId temperature:CTCurrentCT duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
            
        } failure:^(NSError * _Nullable error) {
            DeviceModel *model = [self getDeviceModelByDeviceId:deviceId];
            model.isleave = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(1)}];
        }];
        
        if ([deviceId integerValue] > 32768) {
            DeviceModel *model = [self getDeviceModelByDeviceId:deviceId];
            model.powerState = @1;
            model.colorTemperature = CTCurrentCT;
            model.supports = @1;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@1}];
        }else {
            groupControlling = YES;
            CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:deviceId];
            for (CSRDeviceEntity *member in area.devices) {
                for (DeviceModel *model in _allDevices) {
                    if ([model.deviceId isEqualToNumber:member.deviceId]) {
                        model.powerState = @1;
                        model.colorTemperature = CTCurrentCT;
                        model.supports = @1;
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceId,@"channel":@1}];
                        break;
                    }
                }
            }
        }
        
        if (CTCurrentState == UIGestureRecognizerStateEnded) {
            NSLog(@"色温定时器结束");
            [CTTimer invalidate];
            CTTimer = nil;
        }
    }
}

-(void)setColorWithDeviceId:(NSNumber *)deviceId withColor:(UIColor *)color {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelAppControlling) object:nil];
    appControlling = YES;
    [self performSelector:@selector(cancelAppControlling) withObject:nil afterDelay:4.0];
    
    if ([deviceId integerValue] > 32768) {
        [[LightModelApi sharedInstance] setColor:deviceId color:color duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
            
        } failure:^(NSError * _Nullable error) {
            DeviceModel *model = [self getDeviceModelByDeviceId:deviceId];
            model.isleave = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(1)}];
        }];
        
        DeviceModel *model = [self getDeviceModelByDeviceId:deviceId];
        model.powerState = @1;
        CGFloat red,green,blue,alpha;
        if ([color getRed:&red green:&green blue:&blue alpha:&alpha]) {
            model.red = @(red * 255);
            model.green = @(green * 255);
            model.blue = @(blue * 255);
        }
    }else {
        groupControlling = YES;
        [[LightModelApi sharedInstance] setColor:deviceId color:color duration:@0 success:nil failure:nil];
        
        CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:deviceId];
        for (CSRDeviceEntity *member in area.devices) {
            for (DeviceModel *model in _allDevices) {
                if ([model.deviceId isEqualToNumber:member.deviceId]) {
                    model.powerState = @1;
                    CGFloat red,green,blue,alpha;
                    if ([color getRed:&red green:&green blue:&blue alpha:&alpha]) {
                        model.red = @(red * 255);
                        model.green = @(green * 255);
                        model.blue = @(blue * 255);
                    }
                    model.supports = @0;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceId,@"channel":@1}];
                    break;
                }
            }
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@1}];
}

-(void)setColorWithDeviceId:(NSNumber *)deviceId withColor:(UIColor *)color withState:(UIGestureRecognizerState)state {
    
    colorCurrentState = state;
    currentColor = color;
    if (state == UIGestureRecognizerStateBegan) {
        if (colorTimer) {
            [colorTimer invalidate];
            colorTimer = nil;
        }
        colorTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(colorTimerMethod:) userInfo:deviceId repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:colorTimer forMode:NSRunLoopCommonModes];
    }
    
}

- (void)colorTimerMethod:(NSTimer *)infoTimer {
    @synchronized (self) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelAppControlling) object:nil];
        appControlling = YES;
        [self performSelector:@selector(cancelAppControlling) withObject:nil afterDelay:4.0];
        
        NSNumber *deviceId = infoTimer.userInfo;
        
        if ([deviceId integerValue] > 32768) {
            [[LightModelApi sharedInstance] setColor:deviceId color:currentColor duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                
            } failure:^(NSError * _Nullable error) {
                DeviceModel *model = [self getDeviceModelByDeviceId:deviceId];
                model.isleave = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(1)}];
            }];
            
            DeviceModel *model = [self getDeviceModelByDeviceId:deviceId];
            model.powerState = @1;
            CGFloat red,green,blue,alpha;
            if ([currentColor getRed:&red green:&green blue:&blue alpha:&alpha]) {
                model.red = @(red * 255);
                model.green = @(green * 255);
                model.blue = @(blue * 255);
            }
            model.supports = @0;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@1}];
        }else {
            groupControlling = YES;
            [[LightModelApi sharedInstance] setColor:deviceId color:currentColor duration:@0 success:nil failure:nil];
            
            CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:deviceId];
            for (CSRDeviceEntity *member in area.devices) {
                for (DeviceModel *model in _allDevices) {
                    if ([model.deviceId isEqualToNumber:member.deviceId]) {
                        model.powerState = @1;
                        CGFloat red,green,blue,alpha;
                        if ([currentColor getRed:&red green:&green blue:&blue alpha:&alpha]) {
                            model.red = @(red * 255);
                            model.green = @(green * 255);
                            model.blue = @(blue * 255);
                        }
                        model.supports = @0;
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceId,@"channel":@1}];
                        break;
                    }
                }
            }
        }
        
        if (colorCurrentState == UIGestureRecognizerStateEnded) {
            NSLog(@"颜色定时器结束");
            [colorTimer invalidate];
            colorTimer = nil;
        }
    }
}

//物理按钮反馈
- (void)physicalButtonActionCall: (NSNotification *)notification {
    if (groupControlling) {
        return;
    }
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *state = userInfo[@"powerState"];
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSNumber *level = userInfo[@"level"];
    DeviceModel *model;
    for (DeviceModel *m in _allDevices) {
        if ([m.deviceId isEqualToNumber:deviceId]) {
            model = m;
            break;
        }
    }
    if (!model) {
        model = [[DeviceModel alloc] init];
        model.deviceId = deviceId;
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        model.shortName = device.shortName;
        model.name = device.name;
        [_allDevices addObject:model];
    }
    model.isleave = NO;
    
    if ([CSRUtilities belongToOneChannelCurtainController:model.shortName]
        || [CSRUtilities belongToHOneChannelCurtainController:model.shortName]) {
        BOOL b = [level integerValue] == 255 ? NO : YES;
        model.powerState = @(b);
        model.channel1PowerState = b;
        model.level = level;
        model.channel1Level = [level integerValue];
    }else {
        model.powerState = state;
        model.channel1PowerState = [state boolValue];
        model.level = [level integerValue] > 3 ? level : @3;
        model.channel1Level = [level integerValue] > 3 ? [level integerValue] : 3;
    }
    
    if (appControlling) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(1)}];
}

- (void)RGBCWDeviceActionCall: (NSNotification *)notification {
    if (groupControlling) {
        return;
    }
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSNumber *state = userInfo[@"powerState"];
    NSNumber *supports = userInfo[@"supports"];
    NSNumber *temperature = userInfo[@"temperature"];
    NSNumber *red = userInfo[@"red"];
    NSNumber *green = userInfo[@"green"];
    NSNumber *blue = userInfo[@"blue"];
    NSNumber *level = userInfo[@"level"];
    DeviceModel *model;
    for (DeviceModel *m in _allDevices) {
        if ([m.deviceId isEqualToNumber:deviceId]) {
            model = m;
            break;
        }
    }
    if (!model) {
        model = [[DeviceModel alloc] init];
        model.deviceId = deviceId;
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        model.shortName = device.shortName;
        model.name = device.name;
        [_allDevices addObject:model];
    }
    model.isleave = NO;
    model.powerState = state;
    model.channel1PowerState = [state boolValue];
    model.level = [level integerValue] > 3 ? level : @3;
    model.channel1Level = [level integerValue] > 3 ? [level integerValue] : 3;
    model.supports = supports;
    model.colorTemperature = temperature;
    model.red = red;
    model.green = green;
    model.blue = blue;
    
    if (appControlling) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(1)}];
}

- (void)fanControllerCall: (NSNotification *)notification {
    if (groupControlling) {
        return;
    }
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSNumber *fanState = userInfo[@"fanState"];
    NSNumber *fanSpeed = userInfo[@"fanSpeed"];
    NSNumber *lampState = userInfo[@"lampState"];
    DeviceModel *model;
    for (DeviceModel *m in _allDevices) {
        if ([m.deviceId isEqualToNumber:deviceId]) {
            model = m;
            break;
        }
    }
    if (!model) {
        model = [[DeviceModel alloc] init];
        model.deviceId = deviceId;
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        model.shortName = device.shortName;
        model.name = device.name;
        [_allDevices addObject:model];
    }
    model.isleave = NO;
    model.fanState = [fanState boolValue];
    model.fansSpeed = [fanSpeed intValue];
    model.lampState = [lampState boolValue];
    model.powerState = @([fanState boolValue] || [lampState boolValue]);
    
    if (appControlling) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(1)}];
}

- (void)multichannelActionCall:(NSNotification *)notification {
    if (groupControlling) {
        return;
    }
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSNumber *channel = userInfo[@"channel"];
    NSNumber *level = userInfo[@"level"];
    NSNumber *state = userInfo[@"state"];
    DeviceModel *model;
    for (DeviceModel *m in _allDevices) {
        if ([m.deviceId isEqualToNumber:deviceId]) {
            model = m;
            break;
        }
    }
    if (!model) {
        model = [[DeviceModel alloc] init];
        model.deviceId = deviceId;
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        model.shortName = device.shortName;
        model.name = device.name;
        [_allDevices addObject:model];
    }
    model.isleave = NO;
    if ([channel integerValue] == 2) {
        model.channel1PowerState = [state boolValue];
        model.channel1Level = [level integerValue] > 3 ? [level integerValue] : 3;
    }else if ([channel integerValue] == 3) {
        model.channel2PowerState = [state boolValue];
        model.channel2Level = [level integerValue] > 3 ? [level integerValue] : 3;
    }else if ([channel integerValue] == 5) {
        model.channel3PowerState = [state boolValue];
        model.channel3Level = [level integerValue] > 3 ? [level integerValue] : 3;
    }else if ([channel integerValue] == 4) {
        model.channel1PowerState = [state boolValue];
        model.channel1Level = [level integerValue] > 3 ? [level integerValue] : 3;
        model.channel2PowerState = [state boolValue];
        model.channel2Level = [level integerValue] > 3 ? [level integerValue] : 3;
    }else if ([channel integerValue] == 7) {
        model.channel2PowerState = [state boolValue];
        model.channel2Level = [level integerValue] > 3 ? [level integerValue] : 3;
        model.channel3PowerState = [state boolValue];
        model.channel3Level = [level integerValue] > 3 ? [level integerValue] : 3;
    }else if ([channel integerValue] == 6) {
        model.channel1PowerState = [state boolValue];
        model.channel1Level = [level integerValue] > 3 ? [level integerValue] : 3;
        model.channel3PowerState = [state boolValue];
        model.channel3Level = [level integerValue] > 3 ? [level integerValue] : 3;
    }else if ([channel integerValue] == 8) {
        model.channel1PowerState = [state boolValue];
        model.channel1Level = [level integerValue] > 3 ? [level integerValue] : 3;
        model.channel2PowerState = [state boolValue];
        model.channel2Level = [level integerValue] > 3 ? [level integerValue] : 3;
        model.channel3PowerState = [state boolValue];
        model.channel3Level = [level integerValue] > 3 ? [level integerValue] : 3;
    }
    if ([CSRUtilities belongToTwoChannelDimmer:model.shortName]
        || [CSRUtilities belongToTwoChannelSwitch:model.shortName]
        || [CSRUtilities belongToSocketTwoChannel:model.shortName]) {
        model.powerState = @(model.channel1PowerState || model.channel2PowerState);
        model.level = @(model.channel1Level > model.channel2Level ? model.channel1Level : model.channel2Level);
    }else if ([CSRUtilities belongToThreeChannelSwitch:model.shortName]
              || [CSRUtilities belongToThreeChannelDimmer:model.shortName]) {
        model.powerState = @(model.channel1PowerState || model.channel2PowerState || model.channel3PowerState);
        model.level = @((model.channel1Level > model.channel2Level ? model.channel1Level : model.channel2Level) > model.channel3Level ? (model.channel1Level > model.channel2Level ? model.channel1Level : model.channel2Level) : model.channel3Level);
    }else if ([CSRUtilities belongToTwoChannelCurtainController:model.shortName]) {
        if ([channel integerValue] == 2) {
            model.channel1PowerState = [state boolValue];
            model.channel1Level = [level integerValue];
        }else if ([channel integerValue] == 3) {
            model.channel2PowerState = [state boolValue];
            model.channel2Level = [level integerValue];
        }else if ([channel integerValue] == 4) {
            model.channel1PowerState = [state boolValue];
            model.channel1Level = [level integerValue];
            model.channel2PowerState = [state boolValue];
            model.channel2Level = [level integerValue];
        }
        model.powerState = @(model.channel1PowerState || model.channel2PowerState);
        model.level = @(model.channel1Level > model.channel2Level ? model.channel1Level : model.channel2Level);
        model.curtainRange = [userInfo[@"CURTAINRANGE"] integerValue];
        model.curtainDirection = [userInfo[@"CURTAINDIRECTION"] integerValue];
    }else if ([CSRUtilities belongToOneChannelCurtainController:model.shortName]
              || [CSRUtilities belongToHOneChannelCurtainController:model.shortName]) {
        if ([channel integerValue] == 2) {
            model.channel1PowerState = [state boolValue];
            model.channel1Level = [level integerValue];
            model.powerState = state;
            model.level = level;
        }
        model.curtainRange = [userInfo[@"CURTAINRANGE"] integerValue];
        model.curtainDirection = [userInfo[@"CURTAINDIRECTION"] integerValue];
    }else {
        model.powerState = @(model.channel1PowerState);
        model.level = @(model.channel1Level > 3 ? model.channel1Level : 3);
    }
    
    if (appControlling) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":channel}];
    
}

- (void)childrenModelState: (NSNotification *)notification {
    if (groupControlling) {
        return;
    }
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSNumber *state1 = userInfo[@"state1"];
    NSNumber *state2 = userInfo[@"state2"];
    
    DeviceModel *model;
    for (DeviceModel *m in _allDevices) {
        if ([m.deviceId isEqualToNumber:deviceId]) {
            model = m;
            break;
        }
    }
    if (!model) {
        model = [[DeviceModel alloc] init];
        model.deviceId = deviceId;
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        model.shortName = device.shortName;
        model.name = device.name;
        [_allDevices addObject:model];
    }
    model.isleave = NO;
    model.childrenState1 = [state1 boolValue];
    model.childrenState2 = [state2 boolValue];
    
    if (appControlling) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@4}];
}

- (void)colorfulAction:(NSNumber *)deviceId timeInterval:(NSTimeInterval)timeInterval hues:(NSArray *)huesAry colorSaturation:(NSNumber *)colorSat rgbSceneId:(NSNumber *)rgbSceneId {
    NSDictionary *infoDic = [self.allTimers objectForKey:[NSString stringWithFormat:@"%@",deviceId]];
    if (infoDic) {
        NSNumber *sceneId = [infoDic objectForKey:@"rgbSceneId"];
        NSTimer *timer = [infoDic objectForKey:@"timer"];
        [timer invalidate];
        timer = nil;
        [self.allTimers removeObjectForKey:[NSString stringWithFormat:@"%@",deviceId]];
        [self.allTimerColorfulNums removeObjectForKey:[NSString stringWithFormat:@"%@",deviceId]];
        if (![sceneId isEqualToNumber:rgbSceneId]) {
            timer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(colorfulTimerMethod:) userInfo:@{@"deviceId":deviceId,@"hues":huesAry,@"colorSaturation":colorSat} repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            [self.allTimers setObject:@{@"rgbSceneId":rgbSceneId,@"timer":timer} forKey:[NSString stringWithFormat:@"%@",deviceId]];
            [self.allTimerColorfulNums setObject:@0 forKey:[NSString stringWithFormat:@"%@",deviceId]];
        }
    }else {
        timer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(colorfulTimerMethod:) userInfo:@{@"deviceId":deviceId,@"hues":huesAry,@"colorSaturation":colorSat} repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        [self.allTimers setObject:@{@"rgbSceneId":rgbSceneId,@"timer":timer} forKey:[NSString stringWithFormat:@"%@",deviceId]];
        [self.allTimerColorfulNums setObject:@0 forKey:[NSString stringWithFormat:@"%@",deviceId]];
    }
}

- (void)colorfulTimerMethod:(NSTimer *)infoTimer {
    NSDictionary *infoDic = infoTimer.userInfo;
    NSNumber *deviceId = [infoDic objectForKey:@"deviceId"];
    NSArray *huesAry = [infoDic objectForKey:@"hues"];
    NSNumber *colorSat = [infoDic objectForKey:@"colorSaturation"];
    NSInteger colorfulNum = [[self.allTimerColorfulNums objectForKey:[NSString stringWithFormat:@"%@",deviceId]] integerValue];
    UIColor *color = [UIColor colorWithHue:[[huesAry objectAtIndex:colorfulNum] floatValue] saturation:[colorSat floatValue] brightness:1.0 alpha:1.0];
    [[LightModelApi sharedInstance] setColor:deviceId color:color duration:@0 success:nil failure:nil];
    colorfulNum ++;
    if (colorfulNum==6) {
        colorfulNum = 0;
    }
    [self.allTimerColorfulNums setObject:[NSNumber numberWithInteger:colorfulNum] forKey:[NSString stringWithFormat:@"%@",deviceId]];
}

- (void)invalidateColofulTimerWithDeviceId:(NSNumber *)deviceId {
    NSDictionary *infoDic = [self.allTimers objectForKey:[NSString stringWithFormat:@"%@",deviceId]];
    if (infoDic) {
        NSTimer *timer = [infoDic objectForKey:@"timer"];
        [timer invalidate];
        timer = nil;
        [self.allTimers removeObjectForKey:[NSString stringWithFormat:@"%@",deviceId]];
        [self.allTimerColorfulNums removeObjectForKey:[NSString stringWithFormat:@"%@",deviceId]];
    }
}

- (void)regetHues:(NSArray *)huesAry deviceId:(NSNumber *)deviceId sceneId:(NSNumber *)sceneId {
    NSDictionary *infoDic = [self.allTimers objectForKey:[NSString stringWithFormat:@"%@",deviceId]];
    if (infoDic) {
        NSNumber *rgbSceneId = [infoDic objectForKey:@"rgbSceneId"];
        if ([rgbSceneId isEqualToNumber:sceneId]) {
            NSTimer *timer = [infoDic objectForKey:@"timer"];
            NSTimeInterval timeInterval = [timer timeInterval];
            NSNumber *colorSat = [(NSDictionary *)timer.userInfo objectForKey:@"colorSaturation"];
            [timer invalidate];
            timer = nil;
            [self.allTimers removeObjectForKey:[NSString stringWithFormat:@"%@",deviceId]];
            
            timer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(colorfulTimerMethod:) userInfo:@{@"deviceId":deviceId,@"hues":huesAry,@"colorSaturation":colorSat} repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            [self.allTimers setObject:@{@"rgbSceneId":rgbSceneId,@"timer":timer} forKey:[NSString stringWithFormat:@"%@",deviceId]];
        }
    }
}

- (void)regetColorSaturation:(float)sat deviceId:(NSNumber *)deviceId sceneId:(NSNumber *)sceneId {
    NSDictionary *infoDic = [self.allTimers objectForKey:[NSString stringWithFormat:@"%@",deviceId]];
    if (infoDic) {
        NSNumber *rgbSceneId = [infoDic objectForKey:@"rgbSceneId"];
        if ([rgbSceneId isEqualToNumber:sceneId]) {
            NSTimer *timer = [infoDic objectForKey:@"timer"];
            NSTimeInterval timeInterval = [timer timeInterval];
            NSArray *huesAry = [(NSDictionary *)timer.userInfo objectForKey:@"hues"];
            [timer invalidate];
            timer = nil;
            [self.allTimers removeObjectForKey:[NSString stringWithFormat:@"%@",deviceId]];
            
            timer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(colorfulTimerMethod:) userInfo:@{@"deviceId":deviceId,@"hues":huesAry,@"colorSaturation":[NSNumber numberWithFloat:sat]} repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            [self.allTimers setObject:@{@"rgbSceneId":rgbSceneId,@"timer":timer} forKey:[NSString stringWithFormat:@"%@",deviceId]];
        }
    }
}

- (void)regetColofulTimerInterval:(NSTimeInterval)interval deviceId:(NSNumber *)deviceId sceneId:(NSNumber *)sceneId {
    NSDictionary *infoDic = [self.allTimers objectForKey:[NSString stringWithFormat:@"%@",deviceId]];
    if (infoDic) {
        NSNumber *rgbSceneId = [infoDic objectForKey:@"rgbSceneId"];
        if ([rgbSceneId isEqualToNumber:sceneId]) {
            NSTimer *timer = [infoDic objectForKey:@"timer"];
            NSDictionary *timerInfoDic = (NSDictionary *)timer.userInfo;
            [timer invalidate];
            timer = nil;
            [self.allTimers removeObjectForKey:[NSString stringWithFormat:@"%@",deviceId]];
            
            timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(colorfulTimerMethod:) userInfo:timerInfoDic repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            [self.allTimers setObject:@{@"rgbSceneId":rgbSceneId,@"timer":timer} forKey:[NSString stringWithFormat:@"%@",deviceId]];
        }
    }
}

- (NSMutableDictionary *)allTimers {
    if (!_allTimers) {
        _allTimers = [[NSMutableDictionary alloc] init];
    }
    return _allTimers;
}

- (NSMutableDictionary *)allTimerColorfulNums {
    if (!_allTimerColorfulNums) {
        _allTimerColorfulNums = [[NSMutableDictionary alloc] init];
    }
    return  _allTimerColorfulNums;
}

- (void)controlScene:(NSNumber *)sceneId {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelAppControlling) object:nil];
    appControlling = YES;
    [self performSelector:@selector(cancelAppControlling) withObject:nil afterDelay:4.0];
    
    SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:sceneId];
    for (SceneMemberEntity *member in scene.members) {
        for (DeviceModel *model in _allDevices) {
            if ([model.deviceId isEqualToNumber:member.deviceID]) {
                if ([CSRUtilities belongToSwitch:model.shortName]) {
                    if ([member.eveType integerValue] == 17) {
                        model.channel1PowerState = NO;
                        model.powerState = @0;
                    }else if ([member.eveType integerValue] == 16) {
                        model.channel1PowerState = YES;
                        model.powerState = @1;
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@1}];
                }else if ([CSRUtilities belongToTwoChannelSwitch:model.shortName]) {
                    if ([member.channel integerValue] == 1) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel1PowerState = NO;
                        }else if ([member.eveType integerValue] == 16) {
                            model.channel1PowerState = YES;
                        }
                    }else if ([member.channel integerValue] == 2) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel2PowerState = NO;
                        }else if ([member.eveType integerValue] == 16) {
                            model.channel2PowerState = YES;
                        }
                    }
                    model.powerState = @(model.channel1PowerState || model.channel2PowerState);
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@([member.channel integerValue]+1)}];
                }else if ([CSRUtilities belongToThreeChannelSwitch:model.shortName]) {
                    if ([member.channel integerValue] == 1) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel1PowerState = NO;
                        }else if ([member.eveType integerValue] == 16) {
                            model.channel1PowerState = YES;
                        }
                    }else if ([member.channel integerValue] == 2) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel2PowerState = NO;
                        }else if ([member.eveType integerValue] == 16) {
                            model.channel2PowerState = YES;
                        }
                    }else if ([member.channel integerValue] == 4) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel3PowerState = NO;
                        }else if ([member.eveType integerValue] == 16) {
                            model.channel3PowerState = YES;
                        }
                    }
                    model.powerState = @(model.channel1PowerState || model.channel2PowerState || model.channel3PowerState);
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@([member.channel integerValue]+1)}];
                }else if ([CSRUtilities belongToDimmer:model.shortName]) {
                    if ([member.eveType integerValue] == 17) {
                        model.channel1PowerState = NO;
                        model.powerState = @0;
                    }else if ([member.eveType integerValue] == 18) {
                        model.channel1PowerState = YES;
                        model.channel1Level = [member.eveD0 integerValue];
                        model.powerState = @1;
                        model.level = member.eveD0;
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@1}];
                }else if ([CSRUtilities belongToTwoChannelDimmer:model.shortName]) {
                    if ([member.channel integerValue] == 1) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel1PowerState = NO;
                        }else if ([member.eveType integerValue] == 18) {
                            model.channel1PowerState = YES;
                            model.channel1Level = [member.eveD0 integerValue];
                        }
                    }else if ([member.channel integerValue] == 2) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel2PowerState = NO;
                        }else if ([member.eveType integerValue] == 18) {
                            model.channel2PowerState = YES;
                            model.channel2Level = [member.eveD0 integerValue];
                        }
                    }
                    model.powerState = @(model.channel1PowerState || model.channel2PowerState);
                    model.level = @(model.channel1Level > model.channel2Level ? model.channel1Level : model.channel2Level);
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@([member.channel integerValue]+1)}];
                }else if ([CSRUtilities belongToThreeChannelDimmer:model.shortName]) {
                    if ([member.channel integerValue] == 1) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel1PowerState = NO;
                        }else if ([member.eveType integerValue] == 18) {
                            model.channel1PowerState = YES;
                            model.channel1Level = [member.eveD0 integerValue];
                        }
                    }else if ([member.channel integerValue] == 2) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel2PowerState = NO;
                        }else if ([member.eveType integerValue] == 18) {
                            model.channel2PowerState = YES;
                            model.channel2Level = [member.eveD0 integerValue];
                        }
                    }else if ([member.channel integerValue] == 4) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel3PowerState = NO;
                        }else if ([member.eveType integerValue] == 18) {
                            model.channel3PowerState = YES;
                            model.channel3Level = [member.eveD0 integerValue];
                        }
                    }
                    model.powerState = @(model.channel1PowerState || model.channel2PowerState || model.channel3PowerState);
                    model.level = @((model.channel1Level > model.channel2Level ? model.channel1Level : model.channel2Level) > model.channel3Level ? (model.channel1Level > model.channel2Level ? model.channel1Level : model.channel2Level) : model.channel3Level);
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@([member.channel integerValue]+1)}];
                }else if ([CSRUtilities belongToCWDevice:model.shortName]) {
                    if ([member.eveType integerValue] == 17) {
                        model.channel1PowerState = NO;
                        model.powerState = @0;
                    }else if ([member.eveType integerValue] == 25) {
                        model.channel1PowerState = YES;
                        model.powerState = @1;
                        model.channel1Level = [member.eveD0 integerValue];
                        model.colorTemperature = @([member.eveD2 integerValue] * 256 + [member.eveD1 integerValue]);
                        model.level = member.eveD0;
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@1}];
                }else if ([CSRUtilities belongToRGBDevice:model.shortName]) {
                    if ([member.eveType integerValue] == 17) {
                        model.channel1PowerState = NO;
                        model.powerState = @0;
                    }else if ([member.eveType integerValue] == 20) {
                        model.channel1PowerState = YES;
                        model.channel1Level = [member.eveD0 integerValue];
                        model.red = member.eveD1;
                        model.green = member.eveD2;
                        model.blue = member.eveD3;
                        model.powerState = @1;
                        model.level = member.eveD0;
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@1}];
                }else if ([CSRUtilities belongToRGBCWDevice:model.shortName]) {
                    if ([member.eveType integerValue] == 17) {
                        model.channel1PowerState = NO;
                        model.powerState = @0;
                    }else if ([member.eveType integerValue] == 20) {
                        model.channel1PowerState = YES;
                        model.channel1Level = [member.eveD0 integerValue];
                        model.red = member.eveD1;
                        model.green = member.eveD2;
                        model.blue = member.eveD3;
                        model.supports = @0;
                        model.powerState = @1;
                        model.level = member.eveD0;
                        model.supports = @0;
                    }else if ([member.eveType integerValue] == 25) {
                        model.channel1PowerState = YES;
                        model.channel1Level = [member.eveD0 integerValue];
                        model.colorTemperature = @([member.eveD2 integerValue] * 256 + [member.eveD1 integerValue]);
                        model.supports = @1;
                        model.powerState = @1;
                        model.level = member.eveD0;
                        model.supports = @1;
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@1}];
                }else if ([CSRUtilities belongToSocketOneChannel:model.shortName]) {
                    if ([member.eveType integerValue] == 17) {
                        model.channel1PowerState = NO;
                        model.powerState = @0;
                    }else if ([member.eveType integerValue] == 16) {
                        if (!model.childrenState1) {
                            model.channel1PowerState = YES;
                            model.powerState = @1;
                        }
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@1}];
                }else if ([CSRUtilities belongToSocketTwoChannel:model.shortName]) {
                    if ([member.channel integerValue] == 1) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel1PowerState = NO;
                        }else if ([member.eveType integerValue] == 16) {
                            if (!model.childrenState1) {
                                model.channel1PowerState = YES;
                            }
                        }
                    }else if ([member.channel integerValue] == 2) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel2PowerState = NO;
                        }else if ([member.eveType integerValue] == 16) {
                            if (!model.childrenState2) {
                                model.channel2PowerState = YES;
                            }
                        }
                    }
                    model.powerState = @(model.channel1PowerState || model.channel2PowerState);
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@([member.channel integerValue]+1)}];
                }else if ([CSRUtilities belongToOneChannelCurtainController:model.shortName]
                          || [CSRUtilities belongToHOneChannelCurtainController:model.shortName]) {
                    if ([member.eveType integerValue] == 17) {
                        model.channel1PowerState = NO;
                        model.powerState = @0;
                    }else if ([member.eveType integerValue] == 18) {
                        model.channel1PowerState = YES;
                        model.channel1Level = [member.eveD0 integerValue];
                        model.powerState = @1;
                        model.level = member.eveD0;
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@1}];
                }else if ([CSRUtilities belongToTwoChannelCurtainController:model.shortName]) {
                    if ([member.channel integerValue] == 1) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel1PowerState = NO;
                        }else if ([member.eveType integerValue] == 18) {
                            model.channel1PowerState = YES;
                            model.channel1Level = [member.eveD0 integerValue];
                        }
                    }else if ([member.channel integerValue] == 2) {
                        if ([member.eveType integerValue] == 17) {
                            model.channel2PowerState = NO;
                        }else if ([member.eveType integerValue] == 18) {
                            model.channel2PowerState = YES;
                            model.channel2Level = [member.eveD0 integerValue];
                        }
                    }
                    model.powerState = @(model.channel1PowerState || model.channel2PowerState);
                    model.level = @(model.channel1Level > model.channel2Level ? model.channel1Level : model.channel2Level);
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@([member.channel integerValue]+1)}];
                }else if ([CSRUtilities belongToFanController:model.shortName]) {
                    model.fanState = [member.eveD0 boolValue];
                    model.fansSpeed = [member.eveD1 intValue];
                    model.lampState = [member.eveD2 boolValue];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@1}];
                }else if ([CSRUtilities belongToMusicController:model.shortName]) {
                    model.mcCurrentChannel = [member.channel integerValue];
                    model.mcStatus = [member.eveD0 integerValue];
                    model.mcVoice = [member.eveD1 integerValue];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceID,@"channel":@1}];
                }
                break;
            }
        }
    }
}

- (void)cancelAppControlling {
    appControlling = NO;
    groupControlling = NO;
}

- (void)remoteControlScene: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *sceneIndex = userInfo[@"sceneIndex"];
    SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:sceneIndex];
    if (scene) {
        [self controlScene:scene.sceneID];
    }
}

- (void)remoteControlGroup: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *grouId = userInfo[@"groupId"];
    NSNumber *powerState = userInfo[@"powerState"];
    CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:grouId];
    if (area && [area.devices count]>0) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelAppControlling) object:nil];
        appControlling = YES;
        [self performSelector:@selector(cancelAppControlling) withObject:nil afterDelay:4.0];
        
        for (CSRDeviceEntity *member in area.devices) {
            for (DeviceModel *model in _allDevices) {
                if ([model.deviceId isEqualToNumber:member.deviceId]) {
                    model.powerState = powerState;
                    model.channel1PowerState = [powerState boolValue];
                    model.channel2PowerState = [powerState boolValue];
                    model.channel3PowerState = [powerState boolValue];
                    model.fanState = [powerState boolValue];
                    model.lampState = [powerState boolValue];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":member.deviceId,@"channel":@1}];
                    break;
                }
            }
        }
    }
}

- (void)refreshMCChannels:(NSNumber *)deviceID mcLiveChannels:(NSInteger)mcLiveChannels mcExistChannels:(NSInteger)mcExistChannels {
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceID]) {
            model.mcLiveChannels = mcLiveChannels;
            model.mcExistChannels = mcExistChannels;
            if ([CSRUtilities belongToMusicController:model.shortName]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"noticeSceneSettingVC" object:self userInfo:@{@"deviceId":deviceID}];
                if (mcLiveChannels == 0) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMCChannelState" object:self userInfo:@{@"deviceId":deviceID}];
                }else {
                    NSString *hex = [CSRUtilities stringWithHexNumber:mcLiveChannels];
                    NSString *bin = [CSRUtilities getBinaryByhex:hex];
                    for (int i = 0; i < [bin length]; i ++) {
                        NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
                        if ([bit boolValue]) {
                            NSInteger mccc = pow(2, i);
                            model.mcCurrentChannel = mccc;
                            //获取音乐控制器的工作状态
                            NSData *cmd;
                            if (mccc < 256) {
                                Byte byte[] = {0xb6, 0x03, 0x20, 0x00, mccc};
                                cmd = [[NSData alloc] initWithBytes:byte length:5];
                            }else {
                                Byte byte[] = {0xb6, 0x03, 0x20, mccc/256, mccc%256};
                                cmd = [[NSData alloc] initWithBytes:byte length:5];
                            }
                            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:deviceID data:cmd];
                            break;
                        }
                    }
                }
            }else if ([CSRUtilities belongToSonosMusicController:model.shortName]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMCChannels" object:self userInfo:@{@"deviceId":deviceID}];
            }
            break;
        }
    }
}

- (void)refreshDeviceID:(NSNumber *)deviceID mcChannelValid:(NSInteger)mcChannelValid mcStatus:(NSInteger)mcStatus mcVoice:(NSInteger)mcVoice mcSong:(NSInteger)song {
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceID] && model.mcCurrentChannel == mcChannelValid) {
            model.mcStatus = mcStatus;
            model.mcVoice = mcVoice;
            model.mcSong = song;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMCChannelState" object:self userInfo:@{@"deviceId":deviceID}];
            return;
        }
    }
}

- (void)refreshDeviceID:(NSNumber *)deviceID mcCurrentChannel:(NSInteger)mcCurrentChannel {
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceID]) {
            model.mcCurrentChannel = mcCurrentChannel;
            
            //获取音乐控制器的工作状态
            NSData *cmd;
            if (mcCurrentChannel < 256) {
                Byte byte[] = {0xb6, 0x03, 0x20, 0x00, mcCurrentChannel};
                cmd = [[NSData alloc] initWithBytes:byte length:5];
            }else {
                Byte byte[] = {0xb6, 0x03, 0x20, mcCurrentChannel/256, mcCurrentChannel%256};
                cmd = [[NSData alloc] initWithBytes:byte length:5];
            }
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:deviceID data:cmd];
            break;
        }
    }
}

- (void)findDevice:(NSNumber *)deviceID getSongName:(NSInteger)channel {
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceID]) {
            if (model.mcCurrentChannel != -1) {
                NSString *hex = [CSRUtilities stringWithHexNumber:model.mcCurrentChannel];
                NSString *bin = [CSRUtilities getBinaryByhex:hex];
                for (int i = 0; i < [bin length]; i ++) {
                    NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
                    if ([bit boolValue]) {
                        if (channel == i) {
                            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getSongNameDelayMethod) object:nil];
                            [self.mcNameDataDic removeAllObjects];
                            applyRetryCount = 0;
                            applyDeviceID = deviceID;
                            [self performSelector:@selector(getSongNameDelayMethod) withObject:nil afterDelay:8];
                            Byte byte[] = {0xea, 0x81, channel, 0x00, 0x00};
                            applyCmd = [[NSData alloc] initWithBytes:byte length:5];
                            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:deviceID data:applyCmd];
                        }
                        break;
                    }
                }
            }
            break;
        }
    }
}

- (void)getSongNameDelayMethod {
    if (applyRetryCount < 4) {
        applyRetryCount ++;
        [self performSelector:@selector(getSongNameDelayMethod) withObject:nil afterDelay:8];
        NSMutableArray *ary = [self.mcNameDataDic objectForKey:applyDeviceID];
        if (ary) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
            [ary sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            NSInteger count = [ary[0][@"count"] integerValue];
            for (int i=1; i<=count; i++) {
                BOOL idx = NO;
                for (NSDictionary *dic in ary) {
                    if ([dic[@"index"] intValue] == i) {
                        idx = YES;
                        break;
                    }
                }
                if (!idx) {
                    Byte *bytes = (Byte *)[applyCmd bytes];
                    Byte cbyte[] = {0xea, 0x81, bytes[2], 0x01, i};
                    NSData *cmd = [[NSData alloc] initWithBytes:cbyte length:5];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:applyDeviceID data:cmd];
                    [NSThread sleepForTimeInterval:0.5];
                }
            }
        }else {
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:applyDeviceID data:applyCmd];
        }
    }
}

- (NSMutableDictionary *)mcNameDataDic {
    if (!_mcNameDataDic) {
        _mcNameDataDic = [[NSMutableDictionary alloc] init];
    }
    return _mcNameDataDic;
}

- (void)postSongNameDeviceID:(NSNumber *)deviceID channel:(NSInteger)channel count:(NSInteger)count index:(NSInteger)index encoding:(NSInteger)encoding data:(NSData *)data {
    DeviceModel *model = [self getDeviceModelByDeviceId:deviceID];
    if (model.mcCurrentChannel != -1) {
        NSString *hex = [CSRUtilities stringWithHexNumber:model.mcCurrentChannel];
        NSString *bin = [CSRUtilities getBinaryByhex:hex];
        for (int i = 0; i < [bin length]; i ++) {
            NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
            if ([bit boolValue]) {
                if (channel == i) {
                    NSMutableArray *ary = [self.mcNameDataDic objectForKey:deviceID];
                    if (!ary) {
                        ary = [[NSMutableArray alloc] init];
                        [ary addObject:@{@"channel":@(channel),@"count":@(count),@"index":@(index),@"encoding":@(encoding),@"data":data}];
                        [self.mcNameDataDic setObject:ary forKey:deviceID];
                    }else {
                        BOOL compliance = YES;
                        for (NSDictionary *dic in ary) {
                            if (channel != [dic[@"channel"] integerValue] || count != [dic[@"count"] integerValue] || index == [dic[@"index"] integerValue] || encoding != [dic[@"encoding"] integerValue]) {
                                compliance = NO;
                                break;
                            }
                        }
                        if (compliance) {
                            [ary addObject:@{@"channel":@(channel),@"count":@(count),@"index":@(index),@"encoding":@(encoding),@"data":data}];

                        }
                    }
                    NSLog(@"%@", ary);
                    if ([ary count] == count) {
                        NSMutableData *nameData = [[NSMutableData alloc] init];
                        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
                        [ary sortUsingDescriptors:[NSArray arrayWithObject:sort]];
                        for (NSDictionary *dic in ary) {
                            [nameData appendData:dic[@"data"]];
                        }
                        
                        NSInteger encoding = [ary[0][@"encoding"] integerValue];
                        NSString *name;
                        if (encoding == 0) {
                            NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
                            name = [[NSString alloc] initWithData:nameData encoding:enc];
                            
                        }else if (encoding == 1) {
                            name = [[NSString alloc] initWithData:nameData encoding:NSUTF8StringEncoding];
                        }
                        
                        model.songName = name;
                        NSLog(@"~~> %@   %@",nameData, name);
                        [self.mcNameDataDic removeObjectForKey:deviceID];
                        
                        if (applyDeviceID) {
                            if ([deviceID isEqualToNumber:applyDeviceID]) {
                                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getSongNameDelayMethod) object:nil];
                            }
                        }
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMCSongName" object:self userInfo:@{@"deviceId":deviceID}];
                    }
                }
                break;
            }
        }
    }
}

- (void)clearMCName {
    [self.mcNameDataDic removeAllObjects];
    self.mcNameDataDic = nil;
}

- (void)controlMC:(NSNumber *)deviceID data:(NSData *)cmd {
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:deviceID data:cmd];
}

- (void)refreshNetworkConnectionStatus:(NSNumber *)deviceID staus:(BOOL)status {
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceID]) {
            if (status) {
                Byte byte[] = {0xea, 0x77, 0x01};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:deviceID data:cmd];
            }else {
                CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID];
                device.ipAddress = nil;
                device.port = nil;
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshNetworkConnectionStatus"
                                                                object:self
                                                              userInfo:@{@"deviceId":deviceID, @"type":@(7), @"staus":@(status)}];
            break;
        }
    }
}

- (void)refreshIPAddress:(NSNumber *)deviceID IPAddress:(NSString *)ip {
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceID]) {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID];
            device.ipAddress = ip;
            [[CSRDatabaseManager sharedInstance] saveContext];
            
//            Byte byte[] = {0xea, 0x77, 0x03};
//            NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
//            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:deviceID data:cmd];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshNetworkConnectionStatus"
                                                                object:self
                                                              userInfo:@{@"deviceId":deviceID, @"type":@(1), @"staus":ip}];
            break;
        }
    }
}

- (void)refreshSubnetMask:(NSNumber *)deviceID subnetMask:(NSString *)sub {
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceID]) {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID];
            device.subnetMask = sub;
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            Byte byte[] = {0xea, 0x77, 0x02};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:deviceID data:cmd];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshNetworkConnectionStatus"
                                                                object:self
                                                              userInfo:@{@"deviceId":deviceID, @"type":@(3), @"staus":sub}];
            
            break;
        }
    }
}

- (void)refreshGateway:(NSNumber *)deviceID gateway:(NSString *)gateway {
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceID]) {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID];
            device.gateway = gateway;
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            Byte byte[] = {0xea, 0x77, 0x04};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:deviceID data:cmd];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshNetworkConnectionStatus"
                                                                object:self
                                                              userInfo:@{@"deviceId":deviceID, @"type":@(2), @"staus":gateway}];
            
            break;
        }
    }
}

- (void)refreshDNS:(NSNumber *)deviceID DNS:(NSString *)dns {
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceID]) {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID];
            device.dns = dns;
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshNetworkConnectionStatus"
                                                                object:self
                                                              userInfo:@{@"deviceId":deviceID, @"type":@(4), @"staus":dns}];
            
            break;
        }
    }
}

- (void)refreshPort:(NSNumber *)deviceID port:(NSInteger)port {
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceID]) {
           CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID];
            device.port = @(port);
            [[CSRDatabaseManager sharedInstance] saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshPort"
                                                                object:self
                                                              userInfo:@{@"deviceId":deviceID, @"port":@(port)}];
            break;
        }
    }
}

- (void)refreshSongList:(NSNumber *)deviceID songs:(NSString *)songs {
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceID]) {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID];
            device.remoteBranch = songs;
            [[CSRDatabaseManager sharedInstance] saveContext];
            break;
        }
    }
}

- (void)flashThermoregulatorState:(NSNumber *)deviceID channel:(int)tchanel tpower:(int)tpower tmoshi:(int)tmoshi tfengxiang:(int)tfengxiang tfengsu:(int)tfengsu twendu:(int)twendu {
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceID]) {
            [model.stateDic setObject:@[@(tpower), @(tfengsu), @(twendu), @(tmoshi), @(tfengxiang)] forKey:@(tchanel)];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceID,@"channel":@(tchanel)}];
            break;
        }
    }
}

@end
