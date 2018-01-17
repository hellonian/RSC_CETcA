//
//  DataModelManager.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/6.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
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
- (void)ReadAlarmMessageByDeviceId:(NSNumber *)deviceId;
- (void)setDeviceTime:(NSNumber *)deviceId;
- (void)readDeviceTime:(NSNumber *)deviceId;
- (void)addAlarmForDevice:(NSNumber *)deviceId alarmIndex:(NSInteger)index fireDate:(NSDate *)fireDate fireTime:(NSDate *)fireTime repeat:(NSString *)repeat eveType:(NSString *)alarnActionType level:(NSInteger)level;
- (void)enAlarmForDevice:(NSNumber *)deviceId stata:(BOOL)state index:(NSInteger)index;
- (void)deleteAlarmForDevice:(NSNumber *)deviceId index:(NSInteger)index;

- (NSString *)hexStringForData: (NSData *)data;
- (NSData*)dataForHexString:(NSString*)hexString;

@end
