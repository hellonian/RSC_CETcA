//
//  TimerEntity.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/3/5.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TimerDeviceEntity;

@interface TimerEntity : NSManagedObject

@property (nonatomic,retain) NSNumber *timerID;
@property (nonatomic,retain) NSString *name;
@property (nonatomic,retain) NSNumber *enabled;
@property (nonatomic,retain) NSSet *timerDevices;
@property (nonatomic,retain) NSDate *fireTime;
@property (nonatomic,retain) NSDate *fireDate;
@property (nonatomic,retain) NSString *repeat;
@property (nonatomic,retain) NSNumber *sceneID;

@end

@interface TimerEntity (CoreDataGeneratedAccessors)

- (void)addTimerDevicesObject:(TimerDeviceEntity *)value;
- (void)removeTimerDevicesObject:(TimerDeviceEntity *)value;
- (void)addTimerDevices:(NSSet *)values;
- (void)removeTimerDevices:(NSSet *)values;

@end

