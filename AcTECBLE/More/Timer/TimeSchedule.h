//
//  TimeSchedule.h
//  BluetoothTest
//
//  Created by hua on 6/12/16.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimeSchedule : NSObject<NSCopying,NSCoding>
@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,strong) NSDate *fireDate;
@property (nonatomic,copy) NSString *lightNickname;
@property (nonatomic,assign) NSInteger timerIndex;
@property (nonatomic,copy) NSString *repeat;
@property (nonatomic,copy) NSString *eveType;
@property (nonatomic,assign) NSInteger level;
@property (nonatomic,assign) BOOL state;


-(NSData *)archive;
+(TimeSchedule *)unArchiveData:(NSData *)data;

@end
