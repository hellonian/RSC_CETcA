//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CSRDeviceEntity;

@interface CSRAreaEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * areaIconNum;
@property (nonatomic, retain) NSNumber * areaID;
@property (nonatomic, retain) NSString * areaName;
@property (nonatomic, retain) NSData *areaImage;
@property (nonatomic, retain) NSNumber * favourite;
@property (nonatomic, retain) NSNumber * sortId;
@property (nonatomic, retain) NSSet *devices;
@property (nonatomic, retain) NSNumber *isEditting;

@end

@interface CSRAreaEntity (CoreDataGeneratedAccessors)

- (void)addDevicesObject:(CSRDeviceEntity *)value;
- (void)removeDevicesObject:(CSRDeviceEntity *)value;
- (void)addDevices:(NSSet *)values;
- (void)removeDevices:(NSSet *)values;

@end
