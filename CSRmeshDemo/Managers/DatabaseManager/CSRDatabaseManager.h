//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CSRDatabaseManager.h"
#import "CSRAreaEntity.h"
#import "CSRSettingsEntity.h"
#import "CSREventEntity.h"
#import "GalleryEntity.h"
#import "DropEntity.h"
#import "CSRDeviceEntity.h"
#import "SceneEntity.h"
#import "SceneMemberEntity.h"
#import "TimerEntity.h"
#import "TimerDeviceEntity.h"

@interface CSRDatabaseManager : NSObject {
    BOOL newDatabase;
}

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (CSRDatabaseManager*)sharedInstance;
- (void)saveContext;

//Fetch
- (NSArray *)fetchObjectsWithEntityName:(NSString *)entityName withPredicate:(id)stringOrPredicate, ...;

//DEVICE
- (NSNumber *)getNextFreeIDOfType:(NSString *)typeString;

#pragma mark - Gateway methods
- (NSNumber*)getNextFreeGatewayDeviceId;

//Groups
- (CSRAreaEntity*) saveNewArea :(NSNumber *) areaId areaName:(NSString *) areaName areaImage:(UIImage *) image areaIconNum:(NSNumber *)iconNum sortId:(NSNumber *)sortId;

// Remove Device
-(void) removeDeviceFromDatabase :(NSNumber *) deviceId;

//Remove Area
- (void) removeAreaFromDatabaseWithAreaId:(NSNumber*)areaId;

//Gallery
- (GalleryEntity *)saveNewGallery:(NSNumber *)galleryId galleryImage:(UIImage *)image galleryBoundeWR:(NSNumber *)boundWR;
- (GalleryEntity *)getGalleryEntityWithID:(NSNumber *)galleryID;

//Drop
- (DropEntity *)saveNewDrop:(NSNumber *)dropId device:(CSRDeviceEntity *)device dropBoundRatio:(NSNumber *)boundRatio centerXRatio:(NSNumber *)centerXRatio centerYRatio:(NSNumber *)centerYRatio galleryId:(NSNumber *)gelleryId channel:(NSNumber *)channel;

//Database Local functions
- (void) loadDatabase;
//-(NSString *) fetchNetworkKey;
- (CSRAreaEntity *)getAreaEntityWithId:(NSNumber *)areaId;
- (CSRDeviceEntity *)getDeviceEntityWithId:(NSNumber *)deviceId;
- (CSRSettingsEntity *)fetchSettingsEntity;
- (CSRSettingsEntity *)settingsForCurrentlySelectedPlace;
- (SceneEntity *)getSceneEntityWithId:(NSNumber *)sceneId;
- (SceneEntity *)getSceneEntityWithRcIndexId:(NSNumber *)rcIndex;

- (void) saveDeviceModel :(NSNumber *) deviceNumber modelNumber:(NSData *) modelNumber infoType:(NSNumber *) infoType;

- (NSNumber *)getNextFreeTimerIDOfDeivice:(NSNumber *)deviceId;

- (void)timerDeviceEntityDeleteWhenDeleteDeviceEntity:(NSNumber *)deviceId;
- (void)dropEntityDeleteWhenDeleteDeviceEntity:(NSNumber *)deviceId;
- (void)sceneMemberEntityDeleteWhenDeleteDeviceEntity:(NSNumber *)deviceId;

@end
