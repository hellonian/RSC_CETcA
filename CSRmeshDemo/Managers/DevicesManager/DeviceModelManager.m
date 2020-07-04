//
//  DeviceModelManager.m
//  CSRmeshDemo
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
}

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
        
        [DataModelManager shareInstance];
        
        NSSet *allDevices = [CSRAppStateManager sharedInstance].selectedPlace.devices;
        if (allDevices != nil && [allDevices count] != 0) {
            for (CSRDeviceEntity *deviceEntity in allDevices) {
                if ([CSRUtilities belongToMainVCDevice:deviceEntity.shortName] || [CSRUtilities belongToLightSensor:deviceEntity.shortName]) {
                    DeviceModel *model = [[DeviceModel alloc] init];
                    model.deviceId = deviceEntity.deviceId;
                    model.shortName = deviceEntity.shortName;
                    model.name = deviceEntity.name;
                    [_allDevices addObject:model];
                }
            }
        }
    }
    return self;
}

- (void)getAllDevicesState {
    __block BOOL success = NO;
    [[MeshServiceApi sharedInstance] setRetryCount:@0];
    [[LightModelApi sharedInstance] getState:@(0) success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
        success = YES;
    } failure:^(NSError * _Nullable error) {
    }];
    [[MeshServiceApi sharedInstance] setRetryCount:@6];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!success) {
            [self getAllDevicesState];
        }
    });
}

#pragma mark - LightModelApiDelegate

- (void)didGetLightState:(NSNumber *)deviceId red:(NSNumber *)red green:(NSNumber *)green blue:(NSNumber *)blue level:(NSNumber *)level powerState:(NSNumber *)powerState colorTemperature:(NSNumber *)colorTemperature supports:(NSNumber *)supports meshRequestId:(NSNumber *)meshRequestId {
    NSLog(@"调光回调 deviceId--> %@ powerState--> %@ level--> %@ colorTemperature--> %@ supports--> %@ \n red -> %@ -> green -> %@ blue -> %@ ",deviceId,powerState,level,colorTemperature,supports,red,green,blue);
    BOOL exist = NO;
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
            exist = YES;
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
            }else if ([CSRUtilities belongToTwoChannelCurtainController:model.shortName]) {
                model.channel1PowerState = [powerState boolValue];
                model.channel1Level = [level integerValue];
                model.channel2PowerState = [red boolValue];
                model.channel2Level = [green integerValue];
                model.powerState = @([powerState boolValue] || [red boolValue]);
                NSInteger l = [level integerValue] > [green integerValue] ? [level integerValue] : [green integerValue];
                model.level = @(l);
            }else if ([CSRUtilities belongToOneChannelCurtainController:model.shortName]) {
                model.powerState = powerState;
                model.channel1PowerState = [powerState boolValue];
                model.level = level;
                model.channel1Level = [level integerValue];
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
            break;
        }
    }
    
    if (!exist) {
        DeviceModel *model = [[DeviceModel alloc] init];
        model.deviceId = deviceId;
        model.isleave = NO;
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        model.shortName = device.shortName;
        model.name = device.name;
        
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
        [_allDevices addObject:model];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(1)}];
}

#pragma mark - PowerModelApiDelegate

- (void)didGetPowerState:(NSNumber *)deviceId state:(NSNumber *)state meshRequestId:(NSNumber *)meshRequestId {
    NSLog(@"开关回调 deviceId --> %@ powerState--> %@",deviceId,state);
    BOOL exist = NO;
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
            model.isleave = NO;
            model.powerState = state;
            model.channel1PowerState = [state boolValue];
            model.channel2PowerState = [state boolValue];
            model.channel3PowerState = [state boolValue];
            model.fanState = [state boolValue];
            model.lampState = [state boolValue];
            break;
        }
    }
    if (!exist) {
        DeviceModel *model = [[DeviceModel alloc] init];
        model.deviceId = deviceId;
        model.isleave = NO;
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        model.shortName = device.shortName;
        model.name = device.name;
        model.powerState = state;
        model.channel1PowerState = [state boolValue];
        model.channel2PowerState = [state boolValue];
        model.channel3PowerState = [state boolValue];
        model.fanState = [state boolValue];
        model.lampState = [state boolValue];
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

- (void)setPowerStateWithDeviceId:(NSNumber *)deviceId withPowerState:(NSNumber *)powerState {
    [[PowerModelApi sharedInstance] setPowerState:deviceId state:powerState success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable state) {
        
    } failure:^(NSError * _Nullable error) {
        NSLog(@"error : %@",error);
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
        model.isleave = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"chennel":@(3)}];
    }];
    
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
        NSNumber *deviceId = infotimer.userInfo;
        if (moveDirection == PanGestureMoveDirectionHorizontal) {
            if ([currentChannel integerValue] == 1) {
                [[LightModelApi sharedInstance] setLevel:deviceId level:currentLevel success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                    
                } failure:^(NSError * _Nullable error) {
                    NSLog(@"error : >>>> %@",error);
                    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
                    model.isleave = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(3)}];
                }];
            }else {
                Byte byte[] = {0x51, 0x05, [currentChannel integerValue]-1, 0x00, 0x03, 01, [currentLevel integerValue]};
                NSData *cmd = [[NSData alloc]initWithBytes:byte length:7];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:deviceId data:cmd];
            }
        }
        
        if (currentState == UIGestureRecognizerStateEnded) {
            NSLog(@"定时器结束！！");
            [timer invalidate];
            timer = nil;
        }
    }
}

- (void)setLevelWithGroupId:(NSNumber *)deviceId withLevel:(NSNumber *)level withState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction {
    currentState = state;
    currentLevel = level;
    moveDirection = direction;
    if (state == UIGestureRecognizerStateBegan) {
        if (timer) {
            [timer invalidate];
            timer = nil;
        }
        timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(groupTimerMethod:) userInfo:deviceId repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
}

- (void)groupTimerMethod:(NSTimer *)infotimer {
    @synchronized (self) {
        NSNumber *deviceId = infotimer.userInfo;
        if (moveDirection == PanGestureMoveDirectionHorizontal) {
            if (currentState == UIGestureRecognizerStateBegan || currentState == UIGestureRecognizerStateChanged) {
                [[LightModelApi sharedInstance] setLevel:deviceId level:currentLevel success:nil failure:^(NSError * _Nullable error) {
                    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
                    model.isleave = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(3)}];
                }];
            }else if (currentState == UIGestureRecognizerStateEnded) {
                [[LightModelApi sharedInstance] setLevel:deviceId level:currentLevel success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                    
                } failure:^(NSError * _Nullable error) {
                    NSLog(@"error : >>>> %@",error);
                    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
                    model.isleave = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(3)}];
                }];
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
        NSNumber *deviceId = infotimer.userInfo;
        [[LightModelApi sharedInstance] setColorTemperature:deviceId temperature:CTCurrentCT duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
            
        } failure:^(NSError * _Nullable error) {
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
            model.isleave = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(3)}];
        }];
        
        if (CTCurrentState == UIGestureRecognizerStateEnded) {
            NSLog(@"~~~~~~~~~~~~~~~~色温定时器结束！！😇😇😇😇😇");
            [CTTimer invalidate];
            CTTimer = nil;
        }
    }
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
        NSNumber *deviceId = infoTimer.userInfo;
        [[LightModelApi sharedInstance] setColor:deviceId color:currentColor duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
            
        } failure:^(NSError * _Nullable error) {
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
            model.isleave = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(3)}];
        }];
        
        if (colorCurrentState == UIGestureRecognizerStateEnded) {
            NSLog(@"################ 颜色定时器结束 👀👀👀👀👀👀👀👀👀👀👀👀");
            [colorTimer invalidate];
            colorTimer = nil;
        }
    }
}

//物理按钮反馈
- (void)physicalButtonActionCall: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *state = userInfo[@"powerState"];
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSNumber *level = userInfo[@"level"];
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
            model.isleave = NO;
            model.powerState = state;
            model.channel1PowerState = [state boolValue];
            model.level = [level integerValue] > 3 ? level : @3;
            model.channel1Level = [level integerValue] > 3 ? [level integerValue] : 3;
            //旧款窗帘逻辑错误的矫正
            if ([model.shortName isEqualToString:@"C300IB"] || [model.shortName isEqualToString:@"C300IBH"]) {
                model.powerState = [level integerValue] == 255? @(0):@(1);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(1)}];
            return;
        }
    }
}

- (void)RGBCWDeviceActionCall: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSNumber *state = userInfo[@"powerState"];
    NSNumber *supports = userInfo[@"supports"];
    NSNumber *temperature = userInfo[@"temperature"];
    NSNumber *red = userInfo[@"red"];
    NSNumber *green = userInfo[@"green"];
    NSNumber *blue = userInfo[@"blue"];
    NSNumber *level = userInfo[@"level"];
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(1)}];
            return;
        }
    }
}

- (void)fanControllerCall: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSNumber *fanState = userInfo[@"fanState"];
    NSNumber *fanSpeed = userInfo[@"fanSpeed"];
    NSNumber *lampState = userInfo[@"lampState"];
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
            model.isleave = NO;
            model.fanState = [fanState boolValue];
            model.fansSpeed = [fanSpeed intValue];
            model.lampState = [lampState boolValue];
            model.powerState = @([fanState boolValue] || [lampState boolValue]);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@(1)}];
            return;
        }
    }
}

- (void)multichannelActionCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSNumber *channel = userInfo[@"channel"];
    NSNumber *level = userInfo[@"level"];
    NSNumber *state = userInfo[@"state"];
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
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
            }else if ([CSRUtilities belongToOneChannelCurtainController:model.shortName]) {
                if ([channel integerValue] == 2) {
                    model.channel1PowerState = [state boolValue];
                    model.channel1Level = [level integerValue];
                    model.powerState = state;
                    model.level = level;
                }
            }else {
                model.powerState = @(model.channel1PowerState);
                model.level = @(model.channel1Level > 3 ? model.channel1Level : 3);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":channel}];
            return;
        }
    }
}

- (void)childrenModelState: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSNumber *state1 = userInfo[@"state1"];
    NSNumber *state2 = userInfo[@"state2"];
    [_allDevices enumerateObjectsUsingBlock:^(DeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
            model.childrenState1 = [state1 boolValue];
            model.childrenState2 = [state2 boolValue];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId,@"channel":@4}];
            *stop = YES;
        }
    }];
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


@end
