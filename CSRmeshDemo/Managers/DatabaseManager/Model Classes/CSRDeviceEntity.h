//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CSRAreaEntity,DropEntity,RGBSceneEntity;

@interface CSRDeviceEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * appearance;
@property (nonatomic, retain) NSData * authCode;
@property (nonatomic, retain) NSData * deviceHash;
@property (nonatomic, strong) NSNumber * deviceId;
@property (nonatomic, retain) NSNumber * favourite;
@property (nonatomic, retain) NSString * groups;
@property (nonatomic, retain) NSNumber * isAssociated;
@property (nonatomic, retain) NSData * modelHigh;
@property (nonatomic, retain) NSData * modelLow;
@property (nonatomic, retain) NSString *shortName;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * nGroups;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSSet *areas;
@property (nonatomic, retain) NSData *dhmKey;
@property (nonatomic, retain) NSSet *drops;
@property (nonatomic, retain) NSNumber * sortId;
@property (nonatomic, retain) NSNumber *isEditting;
@property (nonatomic, retain) NSString * remoteBranch;
@property (nonatomic, retain) NSSet *rgbScenes;
@property (nonatomic, retain) NSNumber *cvVersion;
@property (nonatomic, retain) NSNumber *firVersion;
@property (nonatomic, retain) NSNumber *androidId;
@property (nonatomic, retain) NSNumber * mcuBootVersion;
@property (nonatomic, retain) NSNumber * mcuHVersion;
@property (nonatomic, retain) NSNumber * mcuSVersion;

@end

@interface CSRDeviceEntity (CoreDataGeneratedAccessors)

- (void)addAreasObject:(CSRAreaEntity *)value;
- (void)removeAreasObject:(CSRAreaEntity *)value;
- (void)addAreas:(NSSet *)values;
- (void)removeAreas:(NSSet *)values;

- (void)addDropsObject:(DropEntity *)value;
- (void)removeDropsObject:(DropEntity *)value;
- (void)addDrops:(NSSet *)values;
- (void)removeDrops:(NSSet *)values;

- (void)addRgbScenesObject:(RGBSceneEntity *)value;
- (void)removeRgbScenesObject:(RGBSceneEntity *)value;
- (void)addRgbScenes:(NSSet *)values;
- (void)removeRGBScenes:(NSSet *)values;

@end
