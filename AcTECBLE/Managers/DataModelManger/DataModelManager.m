//
//  DataModelManager.m
//  AcTECBLE
//
//  Created by AcTEC on 2017/9/6.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "DataModelManager.h"
#import <CSRmesh/DataModelApi.h>
#import "TimeSchedule.h"
#import "CSRmeshDevice.h"
#import "CSRDevicesManager.h"
#import "CSRUtilities.h"
#import "CSRDatabaseManager.h"
#import "CSRDeviceEntity.h"
#import "DeviceModelManager.h"

@interface DataModelManager ()<DataModelApiDelegate>

@property (nonatomic,strong) DataModelApi *manager;
@property (nonatomic,strong) NSMutableDictionary *deviceKeyDic;


@end

@implementation DataModelManager

NSString * const kTimerProfile = @"com.actec.bluetooth.timerProfile";

static DataModelManager *manager = nil;
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DataModelManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _manager = [DataModelApi sharedInstance];
        [_manager addDelegate:self];
    }
    return self;
}

- (void)sendCmdData:(NSString *)hexStrCmd  toDeviceId:(NSNumber *)deviceId {
    if (deviceId) {
        [_manager sendData:deviceId data:[CSRUtilities dataForHexString:hexStrCmd] success:nil failure:nil];
    }
    
}

- (void)sendDataByBlockDataTransfer:(NSNumber *)deviceId data:(NSData *)data {
    if (deviceId) {
        [_manager sendData:deviceId data:data success:nil failure:nil];
    }
}

- (void)sendDataByStreamDataTransfer:(NSNumber *)deviceId data:(NSData *)data {
    if (deviceId) {
        [_manager sendData:deviceId data:data success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
            
        } failure:^(NSError * _Nonnull error) {
            
        }];
    }
}

//读取单灯闹钟列表
- (void)readAlarmMessageByDeviceId:(NSNumber *)deviceId {
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
    if (deviceId) {
        if ([deviceEntity.cvVersion integerValue]>18) {
            [_manager sendData:deviceId data:[CSRUtilities dataForHexString:@"820100"] success:nil failure:nil];
        }else {
            [_manager sendData:deviceId data:[CSRUtilities dataForHexString:@"820100"] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                
            } failure:^(NSError * _Nonnull error) {
                
            }];
        }
    }
//    [self sendCmdData:@"820100" toDeviceId:deviceId];
}

//同步设备时间
- (void) setDeviceTime {
    NSDate *current = [NSDate date];
    NSString *dateString = [self hexStringForDate:current];
    
    NSString *cmd = [NSString stringWithFormat:@"8006%@",dateString];

    [_manager sendData:@0 data:[CSRUtilities dataForHexString:cmd] success:nil failure:nil];

}

//读取设备时间
- (void)readDeviceTime:(NSNumber *)deviceId {
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
    if (deviceId) {
        if ([deviceEntity.cvVersion integerValue]>18) {
            [_manager sendData:deviceId data:[CSRUtilities dataForHexString:@"810100"] success:nil failure:nil];
        }else {
            [_manager sendData:deviceId data:[CSRUtilities dataForHexString:@"810100"] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                
            } failure:^(NSError * _Nonnull error) {
                
            }];
        }
    }
//    [self sendCmdData:@"810100" toDeviceId:deviceId];
}

- (void)changeColorTemperature:(NSNumber *)deviceId {
    [self sendCmdData:@"8C0101" toDeviceId:deviceId];
}

- (void)resetColorTemperature:(NSNumber *)deviceId {
    [self sendCmdData:@"8C0100" toDeviceId:deviceId];
}


#pragma mark - DataModelApiDelegate

- (void)didSendData:(NSNumber *)deviceId data:(NSData *)data meshRequestId:(NSNumber *)meshRequestId {
    NSLog(@"didSendData : %@",data);
    NSString *dataStr = [CSRUtilities hexStringForData:data];
    if ([dataStr hasPrefix:@"8316"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didSendStreamData" object:nil userInfo:@{@"deviceId":deviceId, @"channel":@1}];
    }else if ([dataStr hasPrefix:@"501801"]) {
        NSNumber *channel = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(6, 2)]]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didSendStreamData" object:nil userInfo:@{@"deviceId":deviceId, @"channel":channel}];
    }
    
}

- (void)didReceiveBlockData:(NSNumber *)destinationDeviceId sourceDeviceId:(NSNumber *)sourceDeviceId data:(NSData *)data {
    NSLog(@"didReceiveBlockData: %@ ----- %@ +++++ %@",data,destinationDeviceId,sourceDeviceId);
    
    NSString *dataStr = [CSRUtilities hexStringForData:data];
    
    //获取到设备时间
    if ([dataStr hasPrefix:@"a1"]) {
        
//        NSString *dateStrInData = [dataStr substringWithRange:NSMakeRange(4, 12)];
//
//        NSDate *deviceTime = [self dateForString:dateStrInData];///////////
    }
    
    //添加闹钟回调
    else if ([dataStr hasPrefix:@"a3"]) {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:sourceDeviceId];
        NSString *suffixStr;
        if ([deviceEntity.cvVersion integerValue]>18) {
            suffixStr = [dataStr substringWithRange:NSMakeRange(8, 2)];
        }else {
            suffixStr = [dataStr substringWithRange:NSMakeRange(6, 2)];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addAlarmCall" object:nil userInfo:@{@"state":suffixStr, @"deviceId":sourceDeviceId, @"channel":
        @1}];
    }
    
    else if ([dataStr hasPrefix:@"500502"]) {
        if ([dataStr length]>=14) {
            NSNumber *channel = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(6, 2)]]];
//            NSString *indexStr = [NSString stringWithFormat:@"%@%@",[dataStr substringWithRange:NSMakeRange(10, 2)],[dataStr substringWithRange:NSMakeRange(8, 2)]];
//            NSNumber *index = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:indexStr]];
            NSNumber *state = [NSNumber numberWithBool:[[dataStr substringWithRange:NSMakeRange(12, 2)] boolValue]];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"multichannelAddAlarmCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"channel":channel,@"index":index,@"state":state}];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"addAlarmCall" object:nil userInfo:@{@"state":state, @"deviceId":sourceDeviceId, @"channel":channel}];
        }
    }
    
    else if ([dataStr hasPrefix:@"500508"]) {
        if ([dataStr length]>=14) {
            NSNumber *channel = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(6, 2)]]];
            NSString *state = [dataStr substringWithRange:NSMakeRange(12, 2)];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteAlarmCall" object:nil userInfo:@{@"deviceId":sourceDeviceId, @"state":state, @"channel":channel}];
        }
    }
    
    else if ([dataStr hasPrefix:@"500506"]) {
        if ([dataStr length]>=14) {
            NSNumber *channel = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(6, 2)]]];
            NSString *state = [dataStr substringWithRange:NSMakeRange(12, 2)];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"enabledAlarmCall" object:nil userInfo:@{@"deviceId":sourceDeviceId, @"state":state, @"channel":channel}];
        }
    }
    
    //删除闹钟回调
    else if ([dataStr hasPrefix:@"a5"]) {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:sourceDeviceId];
        NSString *state;
        if ([deviceEntity.cvVersion integerValue]>18) {
            state = [dataStr substringWithRange:NSMakeRange(8, 2)];
        }else {
            state = [dataStr substringWithRange:NSMakeRange(6, 2)];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteAlarmCall" object:nil userInfo:@{@"deviceId":sourceDeviceId, @"state":state, @"channel":@1}];
    }
    
    //关闭或开启闹钟回调
    else if ([dataStr hasPrefix:@"a4"]) {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:sourceDeviceId];
        NSString *state;
        if ([deviceEntity.cvVersion integerValue]>18) {
            state = [dataStr substringWithRange:NSMakeRange(8, 2)];
        }else {
            state = [dataStr substringWithRange:NSMakeRange(6, 2)];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"enabledAlarmCall" object:nil userInfo:@{@"deviceId":sourceDeviceId, @"state":state, @"channel":@1}];
    }
    
    //实物按钮动作反馈
    else if ([dataStr hasPrefix:@"87"]) {
        
        NSInteger seq = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(4, 2)]];
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:sourceDeviceId];
        if (seq && (seq - model.primordial) < 0 && (seq - model.primordial) >-10) {
            return;
        }
        model.primordial = seq;
        
        NSNumber *state = @([[dataStr substringWithRange:NSMakeRange(6, 2)] boolValue]);
        NSNumber *level = @([CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(8, 2)]]);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"physicalButtonActionCall" object:self userInfo:@{@"powerState":state,@"level":level,@"deviceId":sourceDeviceId}];
    }
    
    else if ([dataStr hasPrefix:@"8e"]) {
        NSInteger seq = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(4, 2)]];
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:sourceDeviceId];
        if (seq && (seq - model.primordial) < 0 && (seq - model.primordial) >-10) {
            return;
        }
        model.primordial = seq;
        
        NSString *stateStr = [CSRUtilities getBinaryByhex:[dataStr substringWithRange:NSMakeRange(6, 2)]];
        NSNumber *state = @([[stateStr substringWithRange:NSMakeRange(7, 1)] boolValue]);
        NSNumber *supports = @([[stateStr substringWithRange:NSMakeRange(6, 1)] boolValue]);
        
        NSNumber *level = @([CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(8, 2)]]);
        NSNumber *red = @([CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(10, 2)]]);
        NSNumber *green = @([CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(12, 2)]]);
        NSNumber *blue = @([CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(14, 2)]]);
        
        NSNumber *temperature = @([CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(16, 4)]]);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RGBCWDeviceActionCall" object:self userInfo:@{@"powerState":state,@"supports":supports,@"level":level,@"temperature":temperature,@"red":red,@"green":green,@"blue":blue,@"deviceId":sourceDeviceId}];
        
    }
    
    //遥控器设置反馈
    else if ([dataStr hasPrefix:@"b0"]) {
        NSString *suffixStr = [dataStr substringWithRange:NSMakeRange(6, 2)];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"settingRemoteCall" object:nil userInfo:@{@"settingRemoteCall":suffixStr}];
    }
    
    //获取固件版本
    else if ([dataStr hasPrefix:@"a8"]) {
        NSString *hardwareVersion = [dataStr substringWithRange:NSMakeRange(14, 2)];
        NSString *firmwareVersion = [dataStr substringWithRange:NSMakeRange(16, 2)];
        NSString *bleHardwareVersion = [dataStr substringWithRange:NSMakeRange(8, 2)];
        NSString *blefirwareVersion = [dataStr substringWithRange:NSMakeRange(10, 4)];
        NSString *CVVersionStr;
        if ([dataStr length] == 20) {
            CVVersionStr = [dataStr substringWithRange:NSMakeRange(18, 2)];
        }else {
            CVVersionStr = @"11";
        }
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:sourceDeviceId];
        deviceEntity.firVersion = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:firmwareVersion]];
        deviceEntity.cvVersion = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:CVVersionStr]];
        deviceEntity.hwVersion = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:hardwareVersion]];
        deviceEntity.bleHwVersion = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:bleHardwareVersion]];
        deviceEntity.bleFirVersion = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:blefirwareVersion]];
        [[CSRDatabaseManager sharedInstance] saveContext];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reGetDataForPlaceChanged" object:nil];
    }
    
    //获取遥控器电量
//    if ([dataStr hasPrefix:@"b2"]) {
//        NSString *batterylow = [dataStr substringWithRange:NSMakeRange(6, 2)];
//        NSString *batteryhight = [dataStr substringWithRange:NSMakeRange(8, 2)];
//        NSInteger battery = [self numberWithHexString:[NSString stringWithFormat:@"%@%@",batteryhight,batterylow]];
//        NSInteger batteryPercent = (battery-2100)*99/900+1;
//
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"getRemoteBattery" object:nil userInfo:@{@"batteryPercent":[NSNumber numberWithInteger:batteryPercent],@"deviceId":sourceDeviceId}];
//    }
    
    else if ([dataStr hasPrefix:@"aa"]) {
        [self setDeviceTime];
    }
    
    else if ([dataStr hasPrefix:@"b4"]) {
        NSString *cntStr = [dataStr substringFromIndex:4];
        if ([cntStr integerValue]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"settedLightSensorCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"cntStr":cntStr}];
        }
    }
    
    else if ([dataStr hasPrefix:@"760603"]) {
        if ([dataStr length]>=16) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"settedLightSensorCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"dataStr":[dataStr substringFromIndex:6]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"760305"]) {
        if ([dataStr length]>=10) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"getCurrenIllumination" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"dataStr":[dataStr substringFromIndex:6]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"790305"] || [dataStr hasPrefix:@"790205"]) {
        if ([dataStr length] == 8) {
            NSInteger step = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(6, 2)]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"calibrateCall" object:nil userInfo:@{@"deviceId":sourceDeviceId, @"step":@(step), @"channel":@1}];
        }else if ([dataStr length] == 10) {
            NSInteger step = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(6, 2)]];
            NSInteger channel = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(8, 2)]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"calibrateCall" object:nil userInfo:@{@"deviceId":sourceDeviceId, @"step":@(step), @"channel":@(channel)}];
        }
    }
    
    else if ([dataStr hasPrefix:@"7a"] && dataStr.length >= 14) {
        NSInteger seq = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(12, 2)]];
        NSNumber *channel = @([CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(10, 2)]] + 1);
        if (seq) {
            seq = [channel integerValue]*100+seq;
        }
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:sourceDeviceId];
        if (seq && (seq - model.primordial) < 0 && (seq - model.primordial) >-10) {
            return;
        }
        model.primordial = seq;
        
        NSNumber *state = @([[dataStr substringWithRange:NSMakeRange(6, 2)] boolValue]);
        NSNumber *level = @([CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(8, 2)]]);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"multichannelActionCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"channel":channel,@"level":level,@"state":state}];
    }
    
    else if ([dataStr hasPrefix:@"9d"] ) {
        NSInteger seq = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(10, 2)]];
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:sourceDeviceId];
        if (seq && (seq - model.primordial) < 0 && (seq - model.primordial) >-10) {
            return;
        }
        model.primordial = seq;
        
        NSNumber *fanState = @([[dataStr substringWithRange:NSMakeRange(4, 2)] boolValue]);
        NSNumber *fanSpeed = @([[dataStr substringWithRange:NSMakeRange(6, 2)] integerValue]);
        NSNumber *lampState = @([[dataStr substringWithRange:NSMakeRange(8, 2)] boolValue]);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fanControllerCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"fanState":fanState,@"fanSpeed":fanSpeed,@"lampState":lampState}];
    }
    
    else if ([dataStr hasPrefix:@"52"] ) {
        NSInteger seq = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(6, 2)]];
        NSNumber *channel = @([CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(4, 2)]] + 1);
        if (seq) {
            seq = [channel integerValue]*100+seq;
        }
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:sourceDeviceId];
        if (seq && (seq - model.primordial) < 0 && (seq - model.primordial) >-10) {
            return;
        }
        model.primordial = seq;
        
        NSNumber *state = @([[dataStr substringWithRange:NSMakeRange(8, 2)] boolValue]);
        NSNumber *level = @([CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(10, 2)]]);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"multichannelActionCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"channel":channel,@"level":level,@"state":state}];
    }
    
    else if ([dataStr hasPrefix:@"5a"]) {
        if ([dataStr length]>=12) {
            NSNumber *state = [NSNumber numberWithBool:[[dataStr substringWithRange:NSMakeRange(10, 2)] boolValue]];
            NSString *str1 = [dataStr substringWithRange:NSMakeRange(6, 2)];
            NSString *str2 = [dataStr substringWithRange:NSMakeRange(8, 2)];
            NSNumber *index = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[NSString stringWithFormat:@"%@%@",str2,str1]]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SceneAddedSuccessCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"state":state,@"index":index}];
        }
    }
    
    else if ([dataStr hasPrefix:@"94"]) {
        if ([dataStr length]>=10) {
            NSNumber *state = [NSNumber numberWithBool:[[dataStr substringWithRange:NSMakeRange(8, 2)] boolValue]];
            NSString *str1 = [dataStr substringWithRange:NSMakeRange(4, 2)];
            NSString *str2 = [dataStr substringWithRange:NSMakeRange(6, 2)];
            NSNumber *index = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[NSString stringWithFormat:@"%@%@",str2,str1]]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SceneAddedSuccessCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"state":state,@"index":index}];
        }
    }
    
    else if ([dataStr hasPrefix:@"5e"]) {
        if ([dataStr length]>=12) {
            NSNumber *state = [NSNumber numberWithBool:[[dataStr substringWithRange:NSMakeRange(10, 2)] boolValue]];
            NSString *str1 = [dataStr substringWithRange:NSMakeRange(6, 2)];
            NSString *str2 = [dataStr substringWithRange:NSMakeRange(8, 2)];
            NSNumber *index = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[NSString stringWithFormat:@"%@%@",str2,str1]]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveSceneCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"state":state,@"index":index}];
        }
    }
    
    else if ([dataStr hasPrefix:@"99"]) {
        if ([dataStr length]>=10) {
            NSNumber *state = [NSNumber numberWithBool:[[dataStr substringWithRange:NSMakeRange(8, 2)] boolValue]];
            NSString *str1 = [dataStr substringWithRange:NSMakeRange(4, 2)];
            NSString *str2 = [dataStr substringWithRange:NSMakeRange(6, 2)];
            NSNumber *index = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[NSString stringWithFormat:@"%@%@",str2,str1]]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveSceneCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"state":state,@"index":index}];
        }
    }
    
    else if ([dataStr hasPrefix:@"b60513"]) {
        if ([dataStr length]>=14) {
            NSString *swidx = [dataStr substringWithRange:NSMakeRange(6, 2)];
            NSString *swtype = [dataStr substringWithRange:NSMakeRange(8, 2)];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"controlRemoteButtonCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"swidx":swidx,@"swtype":swtype}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb42"]) {
        if ([dataStr length]>=8) {
            NSNumber *state1 = [NSNumber numberWithBool:[[dataStr substringWithRange:NSMakeRange(4, 2)] boolValue]];
            NSNumber *state2 = [NSNumber numberWithBool:[[dataStr substringWithRange:NSMakeRange(6, 2)] boolValue]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"childrenModelState" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"state1":state1,@"state2":state2}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb44"]) {
        if ([dataStr length]>=12) {
            NSNumber *channel = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(4, 2)]]];
            NSInteger power1 = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(6, 4)]];
            NSInteger power2 = 0;
            if ([channel integerValue] == 3 && [dataStr length]>=14) {
                power2 = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(10, 4)]];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"socketPowerCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"power1":[NSNumber numberWithFloat:power1/10.0],@"power2":[NSNumber numberWithFloat:power2/10.0],@"channel":channel}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb43"]) {
        if ([dataStr length]>=20) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"socketPowerStatisticsCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"socketPowerStatisticsCall":[dataStr substringFromIndex:4]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb35"]) {
        NSInteger mcuBootVersion = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(4, 2)]];
        NSInteger mcuHVersion = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(6, 2)]];
        NSInteger mcuSVersion = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(8, 2)]];
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:sourceDeviceId];
        if (device) {
            BOOL higher = NO;
            if (device.mcuSVersion && [device.mcuSVersion integerValue]<mcuSVersion) {
                higher = YES;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedMCUVersionData" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"higher":@(higher)}];
            device.mcuBootVersion = [NSNumber numberWithInteger:mcuBootVersion];
            device.mcuHVersion = [NSNumber numberWithInteger:mcuHVersion];
            device.mcuSVersion = [NSNumber numberWithInteger:mcuSVersion];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb34"]) {
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:sourceDeviceId];
        if (device) {
            device.mcuSVersion = @0;
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb30"]||[dataStr hasPrefix:@"eb32"]||[dataStr hasPrefix:@"eb33"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MCUUpdateDataCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"MCUUpdateDataCall":[dataStr substringFromIndex:2]}];
    }
    
    else if ([dataStr hasPrefix:@"eb5002"]) {
        if ([dataStr length] >= 10) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"getRemoteEnableState" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"getRemoteEnableState":[dataStr substringFromIndex:8]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb52"]) {
        if ([dataStr length]>=10) {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:sourceDeviceId];
            device.remoteBranch = [dataStr substringWithRange:NSMakeRange(8, 2)];
            [[CSRDatabaseManager sharedInstance] saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"getDaliAdress" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"addressStr":[dataStr substringWithRange:NSMakeRange(8, 2)]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb61"]) {
        if ([dataStr length]>=8) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setRemotePasswordCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"state":[dataStr substringWithRange:NSMakeRange(6, 2)]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb62"]) {
        if ([dataStr length]>=6) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"enableRemotePasswordCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"state":[dataStr substringWithRange:NSMakeRange(4, 2)]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb63"]) {
        if ([dataStr length]>=12) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"getRemotePassword" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"enable":[dataStr substringWithRange:NSMakeRange(4, 1)],@"passwordCnt":[dataStr substringWithRange:NSMakeRange(5, 1)],@"password":[dataStr substringFromIndex:6]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb71"]) {
        if ([dataStr length]>=6) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"getGanjiedianModel" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"state":[dataStr substringWithRange:NSMakeRange(4, 2)]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb46"]) {
        if ([dataStr length]>=8) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearSocketPower" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"channel":[dataStr substringWithRange:NSMakeRange(4, 2)],@"state":[dataStr substringWithRange:NSMakeRange(6, 2)]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb49"]) {
        if ([dataStr length]>=8) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"socketPowerAbnormalReport" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"channel":[dataStr substringWithRange:NSMakeRange(4, 2)],@"state":[dataStr substringWithRange:NSMakeRange(6, 2)]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb48"] || [dataStr hasPrefix:@"eb47"]) {
        if ([dataStr length]>=10) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"socketPowerThreshold" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"channel":[dataStr substringWithRange:NSMakeRange(4, 2)],@"socketPowerThreshold":[dataStr substringFromIndex:6]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb53"] || [dataStr hasPrefix:@"eb54"]) {
        if ([dataStr length]>=20) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"remoteKeyTypeCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"remoteKeyTypeCall":[dataStr substringFromIndex:3]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"b6030d"]) {
        if ([dataStr length]>=10) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LCDRemoteAddCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"sourceID":[dataStr substringWithRange:NSMakeRange(6, 2)],@"state":[dataStr substringWithRange:NSMakeRange(8, 2)]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb7d"]) {
        if ([dataStr length]>=10) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LCDRemoteNameCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"sourceID":[dataStr substringWithRange:NSMakeRange(4, 2)],@"packet":[dataStr substringWithRange:NSMakeRange(6, 2)],@"index":[dataStr substringWithRange:NSMakeRange(8, 2)]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb7f"]) {
        if ([dataStr length]>6) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LCDRemoteKeyIndexCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"keyIndex":[data subdataWithRange:NSMakeRange(2, [data length]-2)]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb78"] || [dataStr hasPrefix:@"eb79"]) {
        if ([dataStr length]>8) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LCDRemoteSSIDCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"packet":[dataStr substringWithRange:NSMakeRange(4, 2)],@"index":[dataStr substringWithRange:NSMakeRange(6, 2)],@"sort":[dataStr substringWithRange:NSMakeRange(2, 2)]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb7701"]) {
        if ([dataStr length]>=14) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LCDRemoteIPAdressCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"IPAdress":[dataStr substringFromIndex:6]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb7b"]) {
        if ([dataStr length]>=8) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LCDRemotePortCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"port":[dataStr substringFromIndex:4]}];
        }
    }
    
    else if ([dataStr hasPrefix:@"600411"]) {
        if ([dataStr length] >= 12) {
            NSString *ff = [dataStr substringWithRange:NSMakeRange(10, 2)];
            if ([ff isEqualToString:@"ff"]) {
                NSString *s1 = [dataStr substringWithRange:NSMakeRange(6, 2)];
                NSString *s2 = [dataStr substringWithRange:NSMakeRange(8, 2)];
                NSInteger sceneIndex = [CSRUtilities numberWithHexString:[NSString stringWithFormat:@"%@%@",s2,s1]];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"remoteControlScene" object:nil userInfo:@{@"sceneIndex":@(sceneIndex)}];
            }
        }
    }
    
    else if ([dataStr hasPrefix:@"600480"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"remoteControlGroup" object:nil userInfo:@{@"groupId":destinationDeviceId, @"powerState":@(0)}];
    }
    
    else if ([dataStr hasPrefix:@"600481"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"remoteControlGroup" object:nil userInfo:@{@"groupId":destinationDeviceId, @"powerState":@(1)}];
    }
    
    else if ([dataStr hasPrefix:@"eb83"]) {
        if ([dataStr length] == 8) {
            NSString *str = [dataStr substringWithRange:NSMakeRange(4, 4)];
            [[DeviceModelManager sharedInstance] refreshMCChannel:sourceDeviceId mcChannel:[CSRUtilities numberWithHexString:str]];
        }
    }
    
    else if ([dataStr hasPrefix:@"b6061f"]) {
        if ([dataStr length] == 16) {
            NSInteger mcChannelValid = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(6, 4)]];
            NSInteger mcStatus = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(10, 2)]];
            NSInteger mcVoice = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(12, 2)]];
            [[DeviceModelManager sharedInstance] refreshDeviceID:sourceDeviceId mcChannelValid:mcChannelValid mcStatus:mcStatus mcVoice:mcVoice];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb84"]) {
        if ([dataStr length] == 6) {
            NSInteger channel = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(4, 2)]];
            [[DeviceModelManager sharedInstance] findDevice:sourceDeviceId getSongName:channel];
        }
    }
    
    else if ([dataStr hasPrefix:@"eb81"]) {
        if ([dataStr length] > 12) {
            NSInteger channel = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(4, 2)]];
            NSInteger count = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(6, 2)]];
            NSInteger index = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(8, 2)]];
            NSInteger encoding = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(10, 2)]];
            NSData *nameData = [data subdataWithRange:NSMakeRange(6, [data length]-6)];
            [[DeviceModelManager sharedInstance] postSongNameDeviceID:sourceDeviceId channel:channel count:count index:index encoding:encoding data:nameData];
        }
    }
    
    else if ([dataStr hasPrefix:@"b6021d"]) {
        if ([dataStr length] == 8) {
            BOOL state = [[dataStr substringWithRange:NSMakeRange(6, 2)] boolValue];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"configureMusicRemoteCall" object:nil userInfo:@{@"deviceId":sourceDeviceId,@"state":@(state)}];
        }
    }
}

- (void)didReceiveStreamData:(NSNumber *)deviceId streamNumber:(NSNumber *)streamNumber data:(NSData *)data {
    NSLog(@"didReceiveStreamData: %@ +++++ %@ ----- %@",data,deviceId,streamNumber);
    
    NSMutableDictionary *deviceDic;
    if ([self.deviceKeyDic objectForKey:deviceId]) {
        deviceDic = [self.deviceKeyDic objectForKey:deviceId];
        if (![deviceDic objectForKey:streamNumber]) {
            [deviceDic setObject:data forKey:streamNumber];
        }
    }else{
        deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:data forKey:streamNumber];
    }
    [self.deviceKeyDic setObject:deviceDic forKey:deviceId];
}

- (void)didReceiveStreamDataEnd:(NSNumber *)deviceId streamNumber:(NSNumber *)streamNumber {
    NSLog(@"didReceiveStreamDataEnd: %@ ~~~~~ %@",deviceId,streamNumber);
    
    NSMutableDictionary *dic = [self.deviceKeyDic objectForKey:deviceId];
    NSArray *ary = [dic.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    NSData *data = [dic objectForKey:ary[0]];
    NSString *firstStr = [CSRUtilities hexStringForData:data];
    
    if ([firstStr hasPrefix:@"b3"]) {
        NSMutableData *data = [[NSMutableData alloc] init];
        for (NSNumber *key in ary) {
            NSData *d = [dic objectForKey:key];
            [data appendData:d];
        }
        CSRDeviceEntity *remote = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        remote.remoteBranch = [CSRUtilities hexStringForData:data];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"getRemoteConfiguration" object:nil userInfo:@{@"deviceId":deviceId}];
    }
    
    [self.deviceKeyDic removeObjectForKey:deviceId];
}

- (NSDate *)dateForString:(NSString *)dateStrInData {
    NSInteger year = [CSRUtilities numberWithHexString:[dateStrInData substringWithRange:NSMakeRange(0, 2)]] + 2000;
    NSInteger month = [CSRUtilities numberWithHexString:[dateStrInData substringWithRange:NSMakeRange(2, 2)]];
    NSInteger day = [CSRUtilities numberWithHexString:[dateStrInData substringWithRange:NSMakeRange(4, 2)]];
    NSInteger hour = [CSRUtilities numberWithHexString:[dateStrInData substringWithRange:NSMakeRange(6, 2)]];
    NSInteger minute = [CSRUtilities numberWithHexString:[dateStrInData substringWithRange:NSMakeRange(8, 2)]];
    NSInteger second = [CSRUtilities numberWithHexString:[dateStrInData substringWithRange:NSMakeRange(10, 2)]];
    NSString *dateStr = [NSString stringWithFormat:@"%ld-%ld-%ld %ld:%ld:%ld",(long)year,(long)month,(long)day,(long)hour,(long)minute,(long)second];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [format dateFromString:dateStr];
    return date;
}

- (NSString *)YMdStringForDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"YYYY:MM:dd";
    NSString *dateStr = [formatter stringFromDate:date];
    NSArray *YMdAry = [dateStr componentsSeparatedByString:@":"];
    
    NSString *year = [CSRUtilities stringWithHexNumber:[[YMdAry[0] substringWithRange:NSMakeRange(2, 2)] integerValue]];
    NSString *month = [CSRUtilities stringWithHexNumber:[YMdAry[1] integerValue]];
    NSString *day = [CSRUtilities stringWithHexNumber:[YMdAry[2] integerValue]];
    NSString *YMdString = [NSString stringWithFormat:@"%@%@%@",year,month,day];
    return YMdString;
}

- (NSString *)hmsStringForDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"HH:mm:ss";
    NSString *dateStr = [formatter stringFromDate:date];
    NSArray *hmsAry = [dateStr componentsSeparatedByString:@":"];
    
    NSString *hour = [CSRUtilities stringWithHexNumber:[hmsAry[0] integerValue]];
    NSString *minute = [CSRUtilities stringWithHexNumber:[hmsAry[1] integerValue]];
    NSString *second = [CSRUtilities stringWithHexNumber:[hmsAry[2] integerValue]];
    NSString *hmsString = [NSString stringWithFormat:@"%@%@%@",hour,minute,second];
    return hmsString;
}

- (NSString *)hexStringForDate:(NSDate *)date {
    NSString *YMdString = [self YMdStringForDate:date];
    
    NSString *hmsString = [self hmsStringForDate:date];
    
    NSString *string = [NSString stringWithFormat:@"%@%@",YMdString,hmsString];
    return string;
}

#pragma mark - 数据类型转化

//二进制字符串 转 十进制字符串
- (NSString *)toDecimalSystemWithBinarySystem:(NSString *)binary
{
    int ll = 0 ;
    int  temp = 0 ;
    for (int i = 0; i < binary.length; i ++)
    {
        temp = [[binary substringWithRange:NSMakeRange(i, 1)] intValue];
        temp = temp * powf(2, binary.length - i - 1);
        ll += temp;
    }
    
    NSString * result = [NSString stringWithFormat:@"%d",ll];
    
    return result;
}

- (NSMutableDictionary *)deviceKeyDic {
    if (!_deviceKeyDic) {
        _deviceKeyDic = [[NSMutableDictionary alloc] init];
    }
    return _deviceKeyDic;
}



@end
