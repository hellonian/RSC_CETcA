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
//#import <CSRmesh/MeshServiceApi.h>

#import "DataModelManager.h"

#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"

@interface DeviceModelManager ()<LightModelApiDelegate,PowerModelApiDelegate>
{
    NSTimer *timer;
    NSNumber *currentLevel;
    UIGestureRecognizerState currentState;
    PanGestureMoveDirection moveDirection;
    
    NSTimer *CTTimer;
    NSNumber *CTCurrentCT;
    UIGestureRecognizerState CTCurrentState;
    
    NSTimer *colorTimer;
    UIColor *currentColor;
    UIGestureRecognizerState colorCurrentState;
    
    NSTimer *colorfulTimer;
    NSArray *hues;
    NSInteger colorfulNum;
    CGFloat colorSaturation;
    NSNumber *colorfulSceneId;
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
    /*
    NSSet *allDevices = [CSRAppStateManager sharedInstance].selectedPlace.devices;
    if (allDevices != nil && [allDevices count] != 0) {
        for (CSRDeviceEntity *deviceEntity in allDevices) {
            if ([CSRUtilities belongToDimmer:deviceEntity.shortName] || [CSRUtilities belongToSwitch:deviceEntity.shortName] || [CSRUtilities belongToLightSensor:deviceEntity.shortName]) {

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
     */
}

#pragma mark - LightModelApiDelegate

- (void)didGetLightState:(NSNumber *)deviceId red:(NSNumber *)red green:(NSNumber *)green blue:(NSNumber *)blue level:(NSNumber *)level powerState:(NSNumber *)powerState colorTemperature:(NSNumber *)colorTemperature supports:(NSNumber *)supports meshRequestId:(NSNumber *)meshRequestId {
    NSLog(@"调光回调 deviceId--> %@ powerState--> %@ level--> %@ colorTemperature--> %@ supports--> %@ \n red -> %@ -> green -> %@ blue -> %@ ",deviceId,powerState,level,colorTemperature,supports,red,green,blue);
    __block BOOL exist=NO ;
    [_allDevices enumerateObjectsUsingBlock:^(DeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
            model.powerState = powerState;
            model.level = level;
            model.isleave = NO;
            model.colorTemperature = colorTemperature;
            model.supports = supports;
            model.red = red;
            model.green = green;
            model.blue = blue;
            
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
        model.colorTemperature = colorTemperature;
        model.supports = supports;
        model.red = red;
        model.green = green;
        model.blue = blue;
        [_allDevices addObject:model];
    }
}

#pragma mark - PowerModelApiDelegate

- (void)didGetPowerState:(NSNumber *)deviceId state:(NSNumber *)state meshRequestId:(NSNumber *)meshRequestId {
    NSLog(@"开关回调 deviceId --> %@ powerState--> %@",deviceId,state);
    __block BOOL exist;
    [_allDevices enumerateObjectsUsingBlock:^(DeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.deviceId isEqualToNumber:deviceId]) {
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

-(void)setColorTemperatureWithDeviceId:(NSNumber *)deviceId withColorTemperature:(NSNumber *)colorTemperature withState:(UIGestureRecognizerState)state {
    CTCurrentState = state;
    CTCurrentCT = colorTemperature;
    if (state == UIGestureRecognizerStateBegan && !CTTimer) {
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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId}];
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
    if (state == UIGestureRecognizerStateBegan && !colorTimer) {
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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId}];
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
            model.isleave = NO;
            model.level = passLevel;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId}];
            NSLog(@"物理按钮反馈>>>%@",level);
            *stop = YES;
        }
    }];
    
}

- (void)colorfulAction:(NSNumber *)deviceId timeInterval:(NSTimeInterval)timeInterval hues:(NSArray *)huesAry colorSaturation:(NSNumber *)colorSat rgbSceneId:(NSNumber *)rgbSceneId{
    if (!colorfulTimer) {
        colorfulTimer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(colorfulTimerMethod:) userInfo:deviceId repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:colorfulTimer forMode:NSRunLoopCommonModes];
        hues = huesAry;
        colorfulNum = 0;
        colorSaturation = [colorSat floatValue];
        colorfulSceneId = rgbSceneId;
    }else {
        [self invalidateColofulTimer];
        NSLog(@"%@  %@",rgbSceneId,colorfulSceneId);
        if (![rgbSceneId isEqualToNumber:colorfulSceneId]) {
            colorfulTimer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(colorfulTimerMethod:) userInfo:deviceId repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:colorfulTimer forMode:NSRunLoopCommonModes];
            hues = huesAry;
            colorfulNum = 0;
            colorSaturation = [colorSat floatValue];
            colorfulSceneId = rgbSceneId;
        }
    }
}

- (void)colorfulTimerMethod:(NSTimer *)infoTimer {
    @synchronized (self) {
       
        NSNumber *deviceId = infoTimer.userInfo;
        UIColor *color = [UIColor colorWithHue:[[hues objectAtIndex:colorfulNum] floatValue] saturation:colorSaturation brightness:1.0 alpha:1.0];
        [[LightModelApi sharedInstance] setColor:deviceId color:color duration:@0 success:nil failure:nil];
        colorfulNum ++;
        if (colorfulNum==6) {
            colorfulNum = 0;
        }
    }
}

- (void)invalidateColofulTimer {
    if (colorfulTimer) {
        [colorfulTimer invalidate];
        colorfulTimer = nil;
    }
}

- (void)regetHues:(NSArray *)huesAry {
    hues = huesAry;
}

- (void)regetColorSaturation:(float)sat {
    colorSaturation = sat;
}

- (void)regetColofulTimerInterval:(NSTimeInterval)interval deviceId:(NSNumber *)deviceId {
    if (colorfulTimer) {
        [colorfulTimer invalidate];
        colorfulTimer = nil;
        colorfulTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(colorfulTimerMethod:) userInfo:deviceId repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:colorfulTimer forMode:NSRunLoopCommonModes];
    }
}


@end
