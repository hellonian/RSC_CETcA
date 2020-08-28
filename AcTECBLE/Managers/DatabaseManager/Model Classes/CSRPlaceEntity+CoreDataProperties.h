//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//


#import "CSRPlaceEntity.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSRPlaceEntity (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *cloudSiteID;
@property (nullable, nonatomic, retain) NSNumber *color;
@property (nullable, nonatomic, retain) NSNumber *hostControllerID;
@property (nullable, nonatomic, retain) NSNumber *iconID;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSData *networkKey;
@property (nullable, nonatomic, retain) NSString *owner;
@property (nullable, nonatomic, retain) NSString *passPhrase;
@property (nullable, nonatomic, retain) NSSet<CSRAreaEntity *> *areas;
@property (nullable, nonatomic, retain) NSSet<CSRControllerEntity *> *controllers;
@property (nullable, nonatomic, retain) NSSet<CSRDeviceEntity *> *devices;
@property (nullable, nonatomic, retain) NSSet<CSREventEntity *> *events;
@property (nullable, nonatomic, retain) NSSet<CSRGatewayEntity *> *gateways;
@property (nullable, nonatomic, retain) CSRSettingsEntity *settings;
@property (nullable, nonatomic, retain) CSRUserEntity *user;
@property (nullable, nonatomic, retain) NSSet<GalleryEntity *> *gallerys;
@property (nullable, nonatomic, retain) NSSet<SceneEntity *> *scenes;
@property (nullable, nonatomic, retain) NSSet<TimerEntity *> *timers;

@end

@interface CSRPlaceEntity (CoreDataGeneratedAccessors)

- (void)addAreasObject:(CSRAreaEntity *)value;
- (void)removeAreasObject:(CSRAreaEntity *)value;
- (void)addAreas:(NSSet<CSRAreaEntity *> *)values;
- (void)removeAreas:(NSSet<CSRAreaEntity *> *)values;

- (void)addControllersObject:(CSRControllerEntity *)value;
- (void)removeControllersObject:(CSRControllerEntity *)value;
- (void)addControllers:(NSSet<CSRControllerEntity *> *)values;
- (void)removeControllers:(NSSet<CSRControllerEntity *> *)values;

- (void)addDevicesObject:(CSRDeviceEntity *)value;
- (void)removeDevicesObject:(CSRDeviceEntity *)value;
- (void)addDevices:(NSSet<CSRDeviceEntity *> *)values;
- (void)removeDevices:(NSSet<CSRDeviceEntity *> *)values;

- (void)addEventsObject:(CSREventEntity *)value;
- (void)removeEventsObject:(CSREventEntity *)value;
- (void)addEvents:(NSSet<CSREventEntity *> *)values;
- (void)removeEvents:(NSSet<CSREventEntity *> *)values;

- (void)addGatewaysObject:(CSRGatewayEntity *)value;
- (void)removeGatewaysObject:(CSRGatewayEntity *)value;
- (void)addGateways:(NSSet<CSRGatewayEntity *> *)values;
- (void)removeGateways:(NSSet<CSRGatewayEntity *> *)values;

- (void)addGallerysObject:(GalleryEntity *)value;
- (void)removeGallerysObject:(GalleryEntity *)value;
- (void)addGallerys:(NSSet<GalleryEntity *> *)values;
- (void)removeGallerys:(NSSet<GalleryEntity *> *)values;

- (void)addScenesObject:(SceneEntity *)value;
- (void)removeScenesObject:(SceneEntity *)value;
- (void)addScenes:(NSSet<SceneEntity *> *)values;
- (void)removeScenes:(NSSet<SceneEntity *> *)values;

- (void)addTimersObject:(TimerEntity *)value;
- (void)removeTimersObject:(TimerEntity *)value;
- (void)addTimers:(NSSet<TimerEntity *> *)values;
- (void)removeTimers:(NSSet<TimerEntity *> *)values;

@end

NS_ASSUME_NONNULL_END
