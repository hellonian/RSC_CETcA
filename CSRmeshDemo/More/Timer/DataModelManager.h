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
- (void)readAlarmMessageByDeviceId:(NSNumber *)deviceId;
- (void)setDeviceTime;
- (void)readDeviceTime:(NSNumber *)deviceId;
- (void)addAlarmForDevice:(NSNumber *)deviceId alarmIndex:(NSInteger)index enabled:(BOOL)enabled fireDate:(NSDate *)fireDate fireTime:(NSDate *)fireTime repeat:(NSString *)repeat eveType:(NSNumber *)alarnActionType level:(NSInteger)level eveD1:(NSString *)eveD1 eveD2:(NSString *)eveD2 eveD3:(NSString *)eveD3;
- (void)enAlarmForDevice:(NSNumber *)deviceId stata:(BOOL)state index:(NSInteger)index;
- (void)deleteAlarmForDevice:(NSNumber *)deviceId index:(NSInteger)index;

- (NSString *)hexStringForData: (NSData *)data;
- (void)changeColorTemperature:(NSNumber *)deviceId;
- (void)resetColorTemperature:(NSNumber *)deviceId;

- (void)addAlarmForDevice:(NSNumber *)deviceId alarmIndex:(NSInteger)index enabled:(BOOL)enabled fireDate:(NSDate *)fireDate fireTime:(NSDate *)fireTime repeat:(NSString *)repeat eveType:(NSNumber *)alarnActionType level:(NSInteger)level eveD1:(NSString *)eveD1 eveD2:(NSString *)eveD2 eveD3:(NSString *)eveD3 channel:(NSString *)chanel;

@end
