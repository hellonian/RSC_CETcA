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

@interface DeviceModelManager ()<LightModelApiDelegate,PowerModelApiDelegate>
{
    NSTimer *timer;
    NSNumber *currentLevel;
    UIGestureRecognizerState currentState;
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
        
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if (mutableArray != nil && [mutableArray count] != 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            for (CSRDeviceEntity *deviceEntity in mutableArray) {
                if ([deviceEntity.shortName isEqualToString:@"S350BT"] || [deviceEntity.shortName isEqualToString:@"D350BT"]) {
                    
                    [[LightModelApi sharedInstance] getState:deviceEntity.deviceId success:nil failure:nil];
                    
                    DeviceModel *model = [[DeviceModel alloc] init];
                    model.deviceId = deviceEntity.deviceId;
                    model.shortName = deviceEntity.shortName;
                    [_allDevices addObject:model];
                }
            }
        }
    }
    return self;
}

#pragma mark - LightModelApiDelegate

- (void)didGetLightState:(NSNumber *)deviceId red:(NSNumber *)red green:(NSNumber *)green blue:(NSNumber *)blue level:(NSNumber *)level powerState:(NSNumber *)powerState colorTemperature:(NSNumber *)colorTemperature supports:(NSNumber *)supports meshRequestId:(NSNumber *)meshRequestId {
    [_allDevices enumerateObjectsUsingBlock:^(DeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
            model.powerState = powerState;
            model.level = level;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId}];
            NSLog(@"调光回调 powerState--> %@ --> %@",powerState,level);
            *stop = YES;
        }
    }];
}

#pragma mark - PowerModelApiDelegate

- (void)didGetPowerState:(NSNumber *)deviceId state:(NSNumber *)state meshRequestId:(NSNumber *)meshRequestId {
    [_allDevices enumerateObjectsUsingBlock:^(DeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
            model.powerState = state;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"state":state,@"deviceId":deviceId}];
            NSLog(@"开关回调 powerState--> %@",state);
            *stop = YES;
        }
    }];
}


#pragma mark - private methods

- (DeviceModel *)getDeviceModelByDeviceId:(NSNumber *)deviceId {
    for (DeviceModel *model in _allDevices) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
            return model;
        }
    }
    return nil;
}

- (void)setPowerStateWithDeviceId:(NSNumber *)deviceId withPowerState:(NSNumber *)powerState {
    [[PowerModelApi sharedInstance] setPowerState:deviceId state:powerState success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable state) {
        
    } failure:^(NSError * _Nullable error) {
        
    }];
}

- (void)setLevelWithDeviceId:(NSNumber *)deviceId withLevel:(NSNumber *)level withState:(UIGestureRecognizerState)state {
    currentState = state;
    currentLevel = level;
    if (state == UIGestureRecognizerStateBegan) {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.12 target:self selector:@selector(timerMethod:) userInfo:deviceId repeats:YES];
        [timer fire];
    }
}

- (void)timerMethod:(NSTimer *)infotimer {
    @synchronized (self) {
        
        NSNumber *deviceId = infotimer.userInfo;
        [[LightModelApi sharedInstance] setLevel:deviceId level:currentLevel success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
            
        } failure:^(NSError * _Nullable error) {
            
        }];
        if (currentState == UIGestureRecognizerStateEnded) {
            [timer invalidate];
            timer = nil;
        }
    }
}



@end
