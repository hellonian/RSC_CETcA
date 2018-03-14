//
//  TimerDeviceEntity.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/5.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface TimerDeviceEntity : NSManagedObject

@property (nonatomic,retain) NSNumber *deviceID;
@property (nonatomic,retain) NSNumber *timerIndex;
@property (nonatomic,retain) NSNumber *alive;

@end
