//
//  DataModelManager.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/6.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimeSchedule.h"

typedef enum : NSInteger {
    Week=0,
    Day
}AlarmRepeatType;

@protocol DataModelManagerDelegate <NSObject>

- (void)addAlarmSuccessCall:(TimeSchedule *)schedule;

@end

@interface DataModelManager : NSObject

extern NSString * const kTimerProfile;

@property (nonatomic,weak) id<DataModelManagerDelegate> delegate;

+ (instancetype)shareInstance;
- (void)sendCmdData:(NSString *)hexStrCmd  toDeviceId:(NSNumber *)deviceId;
- (void)sendDataByBlockDataTransfer:(NSNumber *)deviceId data:(NSData *)data;
- (void)sendDataByStreamDataTransfer:(NSNumber *)deviceId data:(NSData *)data;
- (void)readAlarmMessageByDeviceId:(NSNumber *)deviceId;
- (void)setDeviceTime;
- (void)readDeviceTime:(NSNumber *)deviceId;

- (void)changeColorTemperature:(NSNumber *)deviceId;
- (void)resetColorTemperature:(NSNumber *)deviceId;

@end
