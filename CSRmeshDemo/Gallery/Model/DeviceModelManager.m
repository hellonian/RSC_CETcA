//
//  DeviceModelManager.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/16.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
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
        [DataModelManager shareInstance];
        
        NSSet *allDevices = [CSRAppStateManager sharedInstance].selectedPlace.devices;
        if (allDevices != nil && [allDevices count] != 0) {
            for (CSRDeviceEntity *deviceEntity in allDevices) {
                if ([CSRUtilities belongToDimmer:deviceEntity.shortName] || [CSRUtilities belongToSwitch:deviceEntity.shortName]) {
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
    NSSet *allDevices = [CSRAppStateManager sharedInstance].selectedPlace.devices;
    if (allDevices != nil && [allDevices count] != 0) {
        for (CSRDeviceEntity *deviceEntity in allDevices) {
            if ([CSRUtilities belongToDimmer:deviceEntity.shortName] || [CSRUtilities belongToSwitch:deviceEntity.shortName]) {
                
                [[LightModelApi sharedInstance] getState:deviceEntity.deviceId success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {

                } failure:^(NSError * _Nullable error) {
                    NSLog(@">>> error : %@",error);
                    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceEntity.deviceId];
                    model.isleave = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceEntity.deviceId}];
                }];

            }
        }
    }
}

#pragma mark - LightModelApiDelegate

- (void)didGetLightState:(NSNumber *)deviceId red:(NSNumber *)red green:(NSNumber *)green blue:(NSNumber *)blue level:(NSNumber *)level powerState:(NSNumber *)powerState colorTemperature:(NSNumber *)colorTemperature supports:(NSNumber *)supports meshRequestId:(NSNumber *)meshRequestId {
    __block BOOL exist;
    [_allDevices enumerateObjectsUsingBlock:^(DeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
            NSLog(@"调光回调 deviceId--> %@ powerState--> %@ --> %@ ",deviceId,powerState,level);
            model.powerState = powerState;
            model.level = level;
            model.isleave = NO;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId}];
            
            exist = YES;
            *stop = YES;
        }
    }];
    if (!exist) {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        DeviceModel *model = [[DeviceModel alloc] init];
        model.deviceId = deviceEntity.deviceId;
        model.shortName = deviceEntity.shortName;
        model.name = deviceEntity.name;
        model.powerState = powerState;
        model.level = level;
        model.isleave = NO;
        [_allDevices addObject:model];
        [[DataModelManager shareInstance] setDeviceTime:deviceEntity.deviceId];
    }
}

#pragma mark - PowerModelApiDelegate

- (void)didGetPowerState:(NSNumber *)deviceId state:(NSNumber *)state meshRequestId:(NSNumber *)meshRequestId {
    __block BOOL exist;
    [_allDevices enumerateObjectsUsingBlock:^(DeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
            NSLog(@"开关回调 deviceId --> %@ powerState--> %@",deviceId,state);
            model.powerState = state;
            model.isleave = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"state":state,@"deviceId":deviceId}];
            
            exist = YES;
            *stop = YES;
        }
    }];
    if (!exist) {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        DeviceModel *model = [[DeviceModel alloc] init];
        model.deviceId = deviceEntity.deviceId;
        model.shortName = deviceEntity.shortName;
        model.name = deviceEntity.name;
        model.powerState = state;
        model.isleave = NO;
        [_allDevices addObject:model];
        [[DataModelManager shareInstance] setDeviceTime:deviceEntity.deviceId];
    }
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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId}];
    }];
    
}

- (void)setLevelWithDeviceId:(NSNumber *)deviceId withLevel:(NSNumber *)level withState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction{
    currentState = state;
    currentLevel = level;
    moveDirection = direction;
    if (state == UIGestureRecognizerStateBegan && !timer) {
        timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(timerMethod:) userInfo:deviceId repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
}

- (void)timerMethod:(NSTimer *)infotimer {
    @synchronized (self) {
        NSNumber *deviceId = infotimer.userInfo;
        if (moveDirection == PanGestureMoveDirectionHorizontal) {
            [[LightModelApi sharedInstance] setLevel:deviceId level:currentLevel success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                
            } failure:^(NSError * _Nullable error) {
                NSLog(@"error : >>>> %@",error);
                DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
                model.isleave = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId}];
            }];
        }
        
        if (currentState == UIGestureRecognizerStateEnded) {
            NSLog(@"定时器结束！！🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔");
            [timer invalidate];
            timer = nil;
        }
    }
}

//物理按钮反馈
- (void)physicalButtonActionCall: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *state = userInfo[@"powerState"];
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSNumber *level = userInfo[@"level"];
    __block NSNumber *passLevel = level;
    [_allDevices enumerateObjectsUsingBlock:^(DeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
            model.powerState = [NSNumber numberWithBool:[state boolValue]];
            
            if ([passLevel integerValue] < 3) {
                passLevel = @3;
            }
            model.level = passLevel;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId}];
            NSLog(@"物理按钮反馈>>>%@",level);
            *stop = YES;
        }
    }];
    
}

@end
