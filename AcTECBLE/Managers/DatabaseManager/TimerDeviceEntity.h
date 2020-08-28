//
//  TimerDeviceEntity.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/3/5.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface TimerDeviceEntity : NSManagedObject

@property (nonatomic,retain) NSNumber *timerID;
@property (nonatomic,retain) NSNumber *deviceID;
@property (nonatomic,retain) NSNumber *timerIndex;
@property (nonatomic,retain) NSNumber *alive;
@property (nonatomic,retain) NSNumber *channel;

@end
