//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import "CSRDeviceEntity.h"
#import "CSRDevicesManager.h"
#import "CSRConstants.h"
#import "CSRmeshManager.h"
#import "CSRAppStateManager.h"
#import "CSRGatewayEntity.h"
#import "CSRControllerEntity.h"


@interface CSRDatabaseManager ()

@end

@implementation CSRDatabaseManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - Singleton methods

+ (CSRDatabaseManager*)sharedInstance
{
    static dispatch_once_t token;
    static CSRDatabaseManager *shared = nil;
    
    dispatch_once(&token, ^{
        shared = [[CSRDatabaseManager alloc] init];
    });
    
    return shared;
}


- (id) init
{
    if (self = [super init]) {
        
        [[CSRmeshManager sharedInstance] setUpDelegates];
        
    }
    
    return self;
    
}

#pragma mark - Core Data stack methods

- (NSManagedObjectModel *)managedObjectModel
{
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CSRmesh" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[CSRUtilities documentsDirectoryPathURL] URLByAppendingPathComponent:@"CSRmesh.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    NSDictionary *optionDictionnary = @{NSMigratePersistentStoresAutomaticallyOption:[NSNumber numberWithBool:YES],NSInferMappingModelAutomaticallyOption:[NSNumber numberWithBool:YES]};
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:optionDictionnary error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"csr.com.AcTECBLE.DB" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext
{
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    // observe the entity save operation with its managed object context
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mergeChanges:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
    
    return _managedObjectContext;
}

// merge changes to main context,fetchedRequestController will automatically monitor the changes and update tableview.
- (void)updateMainContext:(NSNotification *)notification {
    
    assert([NSThread isMainThread]);
    [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
}

// this is called via observing "NSManagedObjectContextDidSaveNotification" from our classes
- (void)mergeChanges:(NSNotification *)notification {
    
    if (notification.object != self.managedObjectContext) {
        [self performSelectorOnMainThread:@selector(updateMainContext:) withObject:notification waitUntilDone:NO];
    }
}


#pragma mark - Core Data Saving support

- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Fetch Method

- (NSArray *)fetchObjectsWithEntityName:(NSString *)entityName withPredicate:(id)stringOrPredicate, ...
{
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext]];
    
    if (stringOrPredicate) {
        
        NSPredicate *predicate;
        
        if ([stringOrPredicate isKindOfClass:[NSString class]] && stringOrPredicate != nil) {
            
            va_list variadicArguments;
            va_start(variadicArguments, stringOrPredicate);
            predicate = [NSPredicate predicateWithFormat:stringOrPredicate arguments:variadicArguments];
            va_end(variadicArguments);
            
        } else {
            
            NSAssert2([stringOrPredicate isKindOfClass:[NSPredicate class]],
                      @"Second parameter passed to %s is of unexpected class %@",
                      sel_getName(_cmd), NSStringFromClass([stringOrPredicate class]));
            predicate = (NSPredicate *)stringOrPredicate;
            
        }
        
        [request setPredicate:predicate];
        
    }
    
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        [NSException raise:NSGenericException format:@"%@",[error description]];
        return nil;
    }
    
    return results;
    
}

#pragma mark - Insert method

#pragma mark - Update method

#pragma mark - Delete method

#pragma mark - Database helper methods

- (id)retrieveSingleObjectWithDictionary:(NSDictionary *)dictionary
{
    if (!dictionary) {
        return nil;
    }
    
    if (dictionary && [[dictionary allKeys] count] <= 0) {
        return nil;
    }
    
    NSFetchRequest *request;
    
    for (NSString *key in [dictionary allKeys]) {
        
        if ([key isEqualToString:@"entity"]) {
            request = [[NSFetchRequest alloc] initWithEntityName:dictionary[@"entity"]];
        }
        
    }
    
    
    return nil;
}

- (NSSet *)retrieveManyObjectWithDictionary:(NSDictionary *)dictionary
{
    
    return nil;
}

- (id)retrieveOneValueWithDictionary:(NSDictionary *)dictionary
{
    return nil;
}

#pragma mark --- iPhone Simulator methods
-(void) buildSimulatorDatabase {
    if ([CSRAppStateManager sharedInstance].selectedPlace.devices.count==0) {
        // 5 favourite lights
        NSMutableSet *odd = [NSMutableSet set];
        NSMutableSet *even = [NSMutableSet set];
        NSMutableSet *temperature = [NSMutableSet set];
        
        for (uint16_t i=0; i<7; i++) {
            CSRDeviceEntity *deviceEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRDeviceEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
            
            deviceEntity.deviceId = @(0x8000+i);
            deviceEntity.isAssociated = @(YES);
            deviceEntity.appearance = @(CSRApperanceNameLight);
            deviceEntity.favourite = @(YES);
            NSString *name = [NSString stringWithFormat:@"Light %d",i+1];
            deviceEntity.name = name;
            
            if (i==5) {
                deviceEntity.appearance = @(CSRApperanceNameHeater);
                deviceEntity.favourite = @(NO);
                NSString *name = [NSString stringWithFormat:@"Heater %d",i+1];
                deviceEntity.name = name;
                [temperature addObject:deviceEntity];
            }
            else if (i==6) {
                deviceEntity.appearance = @(CSRApperanceNameSensor);
                deviceEntity.favourite = @(NO);
                NSString *name = [NSString stringWithFormat:@"Sensor %d",i+1];
                deviceEntity.name = name;
                [temperature addObject:deviceEntity];
            }
            
            [[CSRAppStateManager sharedInstance].selectedPlace addDevicesObject:deviceEntity];
            if (i<5 && i&1)
                [odd addObject:deviceEntity];
            else if (i<5 && (!i)&1)
                [even addObject:deviceEntity];
        }
        
        // 4 areas
        for (uint16_t i=0; i<4; i++) {
            CSRAreaEntity *groupObj = [NSEntityDescription insertNewObjectForEntityForName:@"CSRAreaEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
            
            groupObj.areaID = @(i+1);
            NSString *name = [NSString stringWithFormat:@"Area %d",i+1];
            groupObj.areaName = name;
            groupObj.favourite = @(YES);
            if (i==1)
                [groupObj addDevices:odd];
            else if (i==0)
                [groupObj addDevices:even];
            else if (i==2) {
                groupObj.areaName = @"Heater";
                [groupObj addDevices:temperature];
            }
            else if (i==3) {
                groupObj.areaName = @"Bedroom";
                [groupObj addDevices:odd];
                [groupObj addDevices:even];
                [groupObj addDevices:temperature];
            }
            [[CSRAppStateManager sharedInstance].selectedPlace addAreasObject:groupObj];
            
        }
        [[CSRDatabaseManager sharedInstance] saveContext];
    }
}


#pragma mark --- Local Database Methods
- (void) loadDatabase
{
    @synchronized (self) {
        
        // Wipe the storing arrays
        [[[CSRDevicesManager sharedInstance] meshDevices] removeAllObjects];
        [[[CSRDevicesManager sharedInstance] scannedMeshDevices] removeAllObjects];

        // Get next free device number and store it
        [[[CSRDevicesManager sharedInstance] meshAreas] removeAllObjects];
        
        [[CSRDevicesManager sharedInstance].deviceDictionary removeAllObjects];
        
        
        // Get devices from current place
        NSSet *devices;
        
        if ([CSRAppStateManager sharedInstance].selectedPlace) {
        
#if (__i386__  || __x86_64__)
            // build a database of devices and areas for the simulator
            // 5 lights, a temperature sensor, a heater, 2 areas
            [self buildSimulatorDatabase];
#endif
            

            devices = [CSRAppStateManager sharedInstance].selectedPlace.devices;
            
            CSRSettingsEntity *settings = [CSRAppStateManager sharedInstance].selectedPlace.settings;
            
            if (settings) {
                
                newDatabase = NO;
                
            } else {
                
                newDatabase = YES;
                settings = [NSEntityDescription insertNewObjectForEntityForName:@"CSRSettingsEntity" inManagedObjectContext:self.managedObjectContext];
                settings.userID = nil;
                settings.retryInterval = @500;
                settings.retryCount = @10;
                settings.concurrentConnections = @1;
                settings.listeningMode = @1;
                
                settings.siteID = nil;
                
                [CSRAppStateManager sharedInstance].selectedPlace.settings = settings;
                
            }
            
        }
        
        for (CSRDeviceEntity *device in devices) {
                
            NSMutableDictionary *deviceProperties = [NSMutableDictionary dictionary];
            if (device.deviceHash) {
                [deviceProperties setObject:device.deviceHash forKey:kDEVICE_HASH];
            }
            
            if (device.dhmKey) {
                [deviceProperties setObject:device.dhmKey forKey:kDEVICE_DHM];
            }
            
            if (device.authCode) {
                [deviceProperties setObject:device.authCode forKey:kDEVICE_AUTH_CODE];
            }
            if (device.deviceId) {
                [deviceProperties setObject:@([device.deviceId unsignedShortValue]) forKey:kDEVICE_NUMBER];
            }
            
            if (device.name) {
                [deviceProperties setObject:device.name forKey:kDEVICE_NAME];
            }
            
            if (device.shortName) {
                [deviceProperties setObject:device.shortName forKey:kDEVICE_SHORTNAME];
            }
            
            if (device.modelLow) {
                [deviceProperties setObject:device.modelLow forKey:kDEVICE_MODELS_LOW];
            }
            
            if (device.modelHigh) {
                [deviceProperties setObject:device.modelHigh forKey:kDEVICE_MODELS_HIGH];
            }
            
            if (device.isAssociated) {
                [deviceProperties setObject:device.isAssociated forKey:kDEVICE_ISASSOCIATED];
            }
            
            if (device.uuid) {
                [deviceProperties setObject:device.uuid forKey:kDEVICE_UUID];
            }
            
                [[CSRDevicesManager sharedInstance] createDeviceFromProperties:deviceProperties];
            
            }
        
            
            // Group Entity
        
            NSSet *areas = [CSRAppStateManager sharedInstance].selectedPlace.areas;
        
            for (CSRAreaEntity *area in areas) {
                
                NSMutableDictionary *areaProperties = [NSMutableDictionary dictionary];
                
                if (area.areaID) {
                    [areaProperties setObject:area.areaID forKey:kAREA_NUMBER];
                }
                
                if (area.areaName) {
                    [areaProperties setObject:area.areaName forKey:kAREA_NAME];
                }
                
                [[CSRDevicesManager sharedInstance] createAreaFromProperties:areaProperties];
            }
    }
    
}


- (CSRSettingsEntity *)fetchSettingsEntity
{
    
    return [CSRAppStateManager sharedInstance].selectedPlace.settings;
    
}

- (CSRSettingsEntity *)settingsForCurrentlySelectedPlace
{
    
    if ([CSRAppStateManager sharedInstance].selectedPlace) {
        
        return (CSRSettingsEntity *)[CSRAppStateManager sharedInstance].selectedPlace.settings;
    }
    
    return nil;
    
}

//============================================================================
// get group entity from database
- (CSRAreaEntity *)getAreaEntityWithId:(NSNumber *)areaId
{
    
    __block CSRAreaEntity *foundAreaEntity = nil;
    
    [[CSRAppStateManager sharedInstance].selectedPlace.areas enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        CSRAreaEntity *areaEntity = (CSRAreaEntity *)obj;
        
        if ([areaEntity.areaID isEqualToNumber:areaId]) {
            
            foundAreaEntity = areaEntity;
            *stop = YES;
            
        }
        
    }];
    
    return foundAreaEntity;
}

- (CSRDeviceEntity *)getDeviceEntityWithId:(NSNumber *)deviceId
{
    if (deviceId) {
        __block CSRDeviceEntity *foundDeviceEntity = nil;
        
        [[CSRAppStateManager sharedInstance].selectedPlace.devices enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            CSRDeviceEntity *deviceEntity = (CSRDeviceEntity *)obj;
            
            if ([deviceEntity.deviceId isEqualToNumber:deviceId]) {
                
                foundDeviceEntity = deviceEntity;
                *stop = YES;
                
            }
            
        }];
        
        return foundDeviceEntity;
    }
    return nil;
}

- (SceneEntity *)getSceneEntityWithId:(NSNumber *)sceneId{
    __block SceneEntity *foundSceneEntity = nil;
    [[CSRAppStateManager sharedInstance].selectedPlace.scenes enumerateObjectsUsingBlock:^(SceneEntity * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.sceneID isEqualToNumber:sceneId]) {
            foundSceneEntity = obj;
            *stop = YES;
        }
    }];
    return foundSceneEntity;
}

- (SceneEntity *)getSceneEntityWithRcIndexId:(NSNumber *)rcIndex{
    if (rcIndex) {
        __block SceneEntity *foundSceneEntity = nil;
        [[CSRAppStateManager sharedInstance].selectedPlace.scenes enumerateObjectsUsingBlock:^(SceneEntity * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj.rcIndex isEqualToNumber:rcIndex]) {
                foundSceneEntity = obj;
                *stop = YES;
            }
        }];
        return foundSceneEntity;
    }
    return nil;
}

- (NSNumber *)getNextFreeIDOfType:(NSString *)typeString {
    
    if ([typeString isEqualToString:@"CSRDeviceEntity"]) {
        
        NSSet *devicesSet;
        NSSet *controllersSet;
        if ([CSRAppStateManager sharedInstance].selectedPlace) {
            
            devicesSet = [CSRAppStateManager sharedInstance].selectedPlace.devices;
            controllersSet = [CSRAppStateManager sharedInstance].selectedPlace.controllers;
        }
        
        NSMutableArray *allDeviceIds = [NSMutableArray new];
        for (CSRDeviceEntity *device in devicesSet) {
            [allDeviceIds addObject:device.deviceId];
        }
        for (CSRControllerEntity *controller in controllersSet) {
            [allDeviceIds addObject:controller.deviceId];
        }
        
        NSInteger objValue;
        for (; ; ) {
            objValue = arc4random()%32752+32769;
            BOOL oldId = NO;
            if ([allDeviceIds containsObject:[NSNumber numberWithInteger:objValue]]) {
                oldId = YES;
                break;
            }
            if (!oldId) {
                return [NSNumber numberWithInteger:objValue];
            }
        }
        
        
        
        /*
         NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
         [allDeviceIds sortUsingDescriptors:[NSArray arrayWithObject:sort]];
         
        __block int previousAddress = 0x8000;
        __block BOOL found = NO;
        __block int objValue;
        if (!allDeviceIds || (allDeviceIds && [allDeviceIds count] < 1)) {
            return @(0x8001);
        } else {
            
            [allDeviceIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                objValue = [(NSNumber*)obj intValue];
                
                if ((objValue - previousAddress) > 1) {
                    
                    // found gap
                    objValue = previousAddress + 1; // 0x8000
                    
                    found=YES;
                    *stop=YES;
                    
                } else {
                    
                    previousAddress = [(NSNumber*)obj intValue];
                    
                }
                
            }];
            
            if (!found) {
                if (objValue != 0xffff) {
                    // free Device Id
                    objValue ++;
                    found = YES;
                }
            }
            
            if (!found) {
                return @(-1);
            }
            
            return @(objValue);
         
        }
         */
    } else if ([typeString isEqualToString:@"CSRAreaEntity"]) {
        NSMutableArray *allIdsArray = [NSMutableArray new];
        
        for (CSRAreaEntity *area in [CSRAppStateManager sharedInstance].selectedPlace.areas) {
            
            [allIdsArray addObject:area.areaID];
            
        }
        
        //Common Method
//        return [self getFreeIdFromArray:[allIdsArray copy]];
        NSInteger objValue;
        for (; ; ) {
            objValue = arc4random()%32758+10;
            BOOL oldId = NO;
            if ([allIdsArray containsObject:[NSNumber numberWithInteger:objValue]]) {
                oldId = YES;
                break;
            }
            if (!oldId) {
                return [NSNumber numberWithInteger:objValue];
            }
        }
        
    } else if ([typeString isEqualToString:@"GalleryEntity"]) {
        NSMutableArray *allIdsArray = [NSMutableArray new];
        
        for (GalleryEntity *gallery in [CSRAppStateManager sharedInstance].selectedPlace.gallerys) {
            [allIdsArray addObject:gallery.galleryID];
        }
        
        return [self getFreeIdFromArray:[allIdsArray copy]];
        
    }else if ([typeString isEqualToString:@"DropEntity"]) {
        NSMutableArray *allIdsArray = [NSMutableArray new];
        
        for (GalleryEntity *gallery in [CSRAppStateManager sharedInstance].selectedPlace.gallerys) {
            for (DropEntity *drop in gallery.drops) {
                [allIdsArray addObject:drop.dropID];
            }
        }
        
        return [self getFreeIdFromArray:[allIdsArray copy]];
        
    }else if ([typeString isEqualToString:@"CSREventEntity"]) {
        NSMutableArray *allIdsArray = [NSMutableArray new];
        
        NSArray *allEventsArray = [self fetchObjectsWithEntityName:@"CSREventEntity" withPredicate:nil];
        
        for (CSREventEntity *event in allEventsArray) {
            
            [allIdsArray addObject:event.eventid];
            
        }
        
        //Common Method
        return [self getFreeIdFromArray:[allIdsArray copy]];
        
    }else if ([typeString isEqualToString:@"SortId"]) {
        
        NSMutableArray *allIdsArray = [NSMutableArray new];
        
        for (CSRAreaEntity *area in [CSRAppStateManager sharedInstance].selectedPlace.areas) {
            [allIdsArray addObject:area.sortId];
        }
        for (CSRDeviceEntity *device in [CSRAppStateManager sharedInstance].selectedPlace.devices) {
            [allIdsArray addObject:device.sortId];
        }
        return [self getFreeIdFromArray:[allIdsArray copy]];
        
    }else if ([typeString isEqualToString:@"TimerEntity"]) {
        
        NSMutableArray *allIdsArray = [NSMutableArray new];
        
        for (TimerEntity *timer in [CSRAppStateManager sharedInstance].selectedPlace.timers) {
            [allIdsArray addObject:timer.timerID];
        }
        
        return [self getFreeIdFromArray:[allIdsArray copy]];
        
    }else if ([typeString isEqualToString:@"GallerySortId"]) {
        NSMutableArray *allIdsArray = [NSMutableArray new];
        
        for (GalleryEntity *gallery in [CSRAppStateManager sharedInstance].selectedPlace.gallerys) {
            [allIdsArray addObject:gallery.sortId];
        }
        
        return [self getFreeIdFromArray:[allIdsArray copy]];
    }else if ([typeString isEqualToString:@"SceneEntity_sceneID"]) {
        NSMutableArray *allIdsArray = [NSMutableArray new];
        for (SceneEntity *scene in [CSRAppStateManager sharedInstance].selectedPlace.scenes) {
            [allIdsArray addObject:scene.sceneID];
        }
        return [self getFreeIdFromArray:[allIdsArray copy]];
    }else if ([typeString isEqualToString:@"SceneEntity_sceneIndex"]) {
        NSMutableArray *allIdsArray = [NSMutableArray new];
        for (SceneEntity *scene in [CSRAppStateManager sharedInstance].selectedPlace.scenes) {
            [allIdsArray addObject:scene.rcIndex];
        }
        for (; ; ) {
            NSInteger index = arc4random()%65470+64;
            if ([allIdsArray containsObject:@(index)]) {
                break;
            }else {
                return @(index);
            }
        }
    }
    return @(-1);
}

- (NSNumber *)getNextFreeTimerIDOfDeivice:(NSNumber *)deviceId {
    CSRDeviceEntity *deviceEntity = [self getDeviceEntityWithId:deviceId];
    NSInteger CVVersion = [deviceEntity.cvVersion integerValue];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"TimerDeviceEntity"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"deviceID == %@",deviceId]];
    request.predicate = predicate;
    NSArray *resArray = [_managedObjectContext executeFetchRequest:request error:nil];
    NSMutableArray *allTimerIndexs = [NSMutableArray new];
    for (TimerDeviceEntity *timerDevice in resArray) {
        [allTimerIndexs addObject:timerDevice.timerIndex];
    }
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [allTimerIndexs sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    
    NSInteger objValue;
    if (CVVersion > 18) {
        for (; ; ) {
            objValue = arc4random()%16384+4096;
            if ([allTimerIndexs containsObject:[NSNumber numberWithInteger:objValue]]) {
                continue;
            }
            return [NSNumber numberWithInteger:objValue];
        }
    }else {
        for (; ; ) {
            objValue = arc4random()%32+16;
            if ([allTimerIndexs containsObject:[NSNumber numberWithInteger:objValue]]) {
                continue;
            }
            return [NSNumber numberWithInteger:objValue];
        }
    }
    
    /*
    int maxValue = 0x2f;
    __block int previousAddress = 0x0f;
    if (CVVersion > 18) {
        previousAddress = 0x0fff;
        maxValue = 0x4fff;
    }
    __block BOOL found = NO;
    __block int objValue;
    if (!allTimerIndexs || (allTimerIndexs && [allTimerIndexs count] < 1)) {
        if (CVVersion > 18) {
            return @(0x1000);
        }else {
            return @(0x10);
        }
    } else {
        
        [allTimerIndexs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            objValue = [(NSNumber*)obj intValue];
            
            if ((objValue - previousAddress) > 1) {
                
                // found gap
                objValue = previousAddress + 1; // 0x8000
                
                found=YES;
                *stop=YES;
                
            } else {
                
                previousAddress = [(NSNumber*)obj intValue];
                
            }
            
        }];
        
        if (!found) {
            if (objValue != maxValue) {
                // free Device Id
                objValue ++;
                found = YES;
            }
        }
        
        if (!found) {
            return @(-1);
        }
        
        return @(objValue);
    }
     */
    
}

- (NSNumber *)getFreeIdFromArray:(NSArray*)collectionArray {
    
    NSMutableArray *collectionMutableArray = [collectionArray mutableCopy];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [collectionMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    
    __block int previousAddress = 0;
    __block BOOL found = NO;
    __block int objValue;
    
    if (!collectionMutableArray || (collectionMutableArray && [collectionMutableArray count] < 1)) {
        return @(1);
    } else {
        
        [collectionMutableArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            objValue = [(NSNumber*)obj intValue];
            
            if ((objValue - previousAddress) > 1) {
                
                // found gap
                objValue = previousAddress + 1;
                
                found=YES;
                *stop=YES;
                
            } else {
                
                previousAddress = [(NSNumber*)obj intValue];
                
            }
            
        }];
        
        if (!found) {
            if (objValue != 0x7fff) {
                // free Device Id
                objValue ++;
                found = YES;
            }
        }
        
        if (!found) {
            return @(-1);
        }
        
        return @(objValue);
    }

}

#pragma mark - Gateway methods

- (NSNumber*)getNextFreeGatewayDeviceId
{
    
    NSSet *gateways;
    
    if ([CSRAppStateManager sharedInstance].selectedPlace) {
        
        gateways = [CSRAppStateManager sharedInstance].selectedPlace.gateways;
        
    }
    
    NSMutableArray *gatewaysIds = [NSMutableArray new];
    
    for (CSRGatewayEntity *gateway in gateways) {
        [gatewaysIds addObject:gateway.deviceId];
    }
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
    [gatewaysIds sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    
    __block int previousAddress = 0xFFFF;
    __block BOOL found = NO;
    __block int objValue;
    
    if (!gatewaysIds || (gatewaysIds && [gatewaysIds count] < 1)) {
        
        return @(0xFFFF);
        
    } else {
        
        [gatewaysIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            objValue = [(NSNumber*)obj intValue];
            
            if ((objValue - previousAddress) > 1) {
                
                // found gap
                objValue = previousAddress - 1; // 0x8000
                
                found = YES;
                *stop = YES;
                
            } else {
                
                previousAddress = [(NSNumber*)obj intValue];
                
            }
            
        }];
        
        if (!found) {
            
            if (objValue != 0x8001) {
                
                // free gateway deviceId
                objValue --;
                found = YES;
                
            }
            
        }
        
        if (!found) {
            
            return @(-1);
            
        }
        
        return @(objValue);
    }
    
}


#pragma mark - Device Deletion Methods

- (void)removeDeviceFromDatabase:(NSNumber *)deviceId
{
    
    __block CSRDeviceEntity *deviceToDelete;
    
    [[CSRAppStateManager sharedInstance].selectedPlace.devices enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        CSRDeviceEntity *deviceEntity = (CSRDeviceEntity *)obj;
        
        if ([deviceEntity.deviceId isEqualToNumber:deviceId]) {
            
            deviceToDelete = deviceEntity;
            *stop = YES;
            
        }
        
    }];
    
    if (deviceToDelete) {
        
        [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:deviceToDelete];
        [_managedObjectContext deleteObject:deviceToDelete];
        [self saveContext];
    }

}


#pragma mark - AREA Methods

- (CSRAreaEntity*)saveNewArea:(NSNumber *)areaId areaName:(NSString *)areaName areaImage:(UIImage *)image areaIconNum:(NSNumber *)iconNum sortId:(NSNumber *)sortId {
    
    __block CSRAreaEntity *newAreaEntity;
    
    [[CSRAppStateManager sharedInstance].selectedPlace.areas enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        CSRAreaEntity *areaEntity = (CSRAreaEntity *)obj;
        
        if ([areaEntity.areaID isEqualToNumber:areaId]) {
            
            newAreaEntity = areaEntity;
            *stop = YES;
        }
        
    }];
    
    if (!newAreaEntity) {
        
        newAreaEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRAreaEntity" inManagedObjectContext:self.managedObjectContext];
    }
    
    
    newAreaEntity.areaName = areaName;
    newAreaEntity.areaID = areaId;
    newAreaEntity.areaIconNum = iconNum;
    if ([iconNum isEqualToNumber:@99]) {
        NSData *areaImageData = UIImageJPEGRepresentation(image, 0.5);
        newAreaEntity.areaImage = areaImageData;
    }else {
        newAreaEntity.areaImage = nil;
    }
//    NSNumber *sorId = [self getNextFreeIDOfType:@"SortId"];
    newAreaEntity.sortId = sortId;
    
    [[CSRAppStateManager sharedInstance].selectedPlace addAreasObject:newAreaEntity];
    [self saveContext];
    
    return newAreaEntity;
    
}

- (void)saveDeviceModel:(NSNumber *)deviceNumber modelNumber:(NSData *)modelNumber infoType:(NSNumber *)infoType
{
    
    __block CSRDeviceEntity *foundDeviceEntity = nil;
    
    [[CSRAppStateManager sharedInstance].selectedPlace.devices enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        CSRDeviceEntity *deviceEntity = (CSRDeviceEntity *)obj;
        
        if ([deviceEntity.deviceId isEqualToNumber:deviceNumber]) {
            
            foundDeviceEntity = deviceEntity;
            *stop = YES;
        }
        
    }];
    
    if (foundDeviceEntity) {
        
        if ([infoType intValue] == CSR_Model_low) {
            
            if (modelNumber) {
                
                foundDeviceEntity.modelLow = [NSData dataWithData:modelNumber];
                
            }
            
        }
        else if ([infoType intValue] == CSR_Model_high) {
            
            if (modelNumber) {
                
                foundDeviceEntity.modelHigh = [NSData dataWithData:modelNumber];
                
            }
        }
        
        [self saveContext];
        
    }
    
}

#pragma mark ----
#pragma mark - Area Deletion Methods

- (void)removeAreaFromDatabaseWithAreaId:(NSNumber*)areaId
{
    
    __block CSRAreaEntity *areaToDelete;
    
    [[CSRAppStateManager sharedInstance].selectedPlace.areas enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        CSRAreaEntity *areaEntity = (CSRAreaEntity *)obj;
        
        if ([areaEntity.areaID isEqualToNumber:areaId]) {
            
            areaToDelete = areaEntity;
            *stop = YES;
            
        }
        
    }];
    
    if (areaToDelete) {
        
        [[CSRAppStateManager sharedInstance].selectedPlace removeAreasObject:areaToDelete];
        [_managedObjectContext deleteObject:areaToDelete];
        [self saveContext];
        
    }
    
}

#pragma mark - Gallery Methods

- (GalleryEntity *)saveNewGallery:(NSNumber *)galleryId galleryImage:(UIImage *)image galleryBoundeWR:(NSNumber *)boundWR
{
    
    __block GalleryEntity *newGalleryEntity;
    
    [[CSRAppStateManager sharedInstance].selectedPlace.gallerys enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        GalleryEntity *galleryEntity = (GalleryEntity *)obj;
        
        if ([galleryEntity.galleryID isEqualToNumber:galleryId]) {
            
            newGalleryEntity = galleryEntity;
            *stop = YES;
        }
        
    }];
    
    if (!newGalleryEntity) {
        
        newGalleryEntity = [NSEntityDescription insertNewObjectForEntityForName:@"GalleryEntity" inManagedObjectContext:self.managedObjectContext];
    }
    
    NSData *galleryImageData = UIImageJPEGRepresentation(image, 0.5);
    newGalleryEntity.galleryImage = galleryImageData;
    newGalleryEntity.galleryID = galleryId;
    newGalleryEntity.boundWidth = boundWR;
    newGalleryEntity.boundHeight = @(0.549);
    NSNumber *soriId = [self getNextFreeIDOfType:@"GallerySortId"];
    newGalleryEntity.sortId = soriId;
    [[CSRAppStateManager sharedInstance].selectedPlace addGallerysObject:newGalleryEntity];
    [self saveContext];
    
    return newGalleryEntity;
    
}

- (GalleryEntity *)getGalleryEntityWithID:(NSNumber *)galleryID {
    __block GalleryEntity *foundGalleryEntity = nil;
    [[CSRAppStateManager sharedInstance].selectedPlace.gallerys enumerateObjectsUsingBlock:^(GalleryEntity * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.galleryID isEqualToNumber:galleryID]) {
            foundGalleryEntity = obj;
            *stop = YES;
        }
    }];
    return foundGalleryEntity;
}

#pragma mark - Drop Methods

- (DropEntity *)saveNewDrop:(NSNumber *)dropId device:(CSRDeviceEntity *)device dropBoundRatio:(NSNumber *)boundRatio centerXRatio:(NSNumber *)centerXRatio centerYRatio:(NSNumber *)centerYRatio galleryId:(NSNumber *)gelleryId channel:(NSNumber *)channel {
    __block GalleryEntity *currentGalleryEntity;
    [[CSRAppStateManager sharedInstance].selectedPlace.gallerys enumerateObjectsUsingBlock:^(GalleryEntity * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.galleryID isEqualToNumber:gelleryId]) {
            currentGalleryEntity = obj;
            *stop = YES;
        }
    }];
    if (currentGalleryEntity) {
        __block DropEntity *newDropEntity;
        [currentGalleryEntity.drops enumerateObjectsUsingBlock:^(DropEntity *dropEntity, BOOL * _Nonnull stop) {
            if ([dropEntity.dropID isEqualToNumber:dropId]) {
                newDropEntity = dropEntity;
                *stop = YES;
            }
        }];
        if (!newDropEntity) {
            newDropEntity = [NSEntityDescription insertNewObjectForEntityForName:@"DropEntity" inManagedObjectContext:self.managedObjectContext];
        }

        newDropEntity.galleryID = gelleryId;
        newDropEntity.dropID = dropId;
        newDropEntity.deviceID = device.deviceId;
        newDropEntity.kindName = device.shortName;
        newDropEntity.boundRatio = boundRatio;
        newDropEntity.centerXRatio = centerXRatio;
        newDropEntity.centerYRatio = centerYRatio;
        newDropEntity.channel = channel;

        [currentGalleryEntity addDropsObject:newDropEntity];
        [self saveContext];
        return newDropEntity;
    }

    return nil;

}

#pragma mark - timer

- (void)timerDeviceEntityDeleteWhenDeleteDeviceEntity:(NSNumber *)deviceId {
    if (deviceId) {
        for (TimerEntity *timer in [CSRAppStateManager sharedInstance].selectedPlace.timers) {
            NSMutableArray *ary = [[NSMutableArray alloc] init];
            for (TimerDeviceEntity  *timerDevice in timer.timerDevices) {
                if ([timerDevice.deviceID isEqualToNumber:deviceId]) {
                    [ary addObject:timerDevice];
                }
            }
            for (TimerDeviceEntity  *timerDevice in ary) {
                [timer removeTimerDevicesObject:timerDevice];
                [self.managedObjectContext deleteObject:timerDevice];
            }
            if (timer.timerDevices.count == 0) {
                [self.managedObjectContext deleteObject:timer];
            }
        }
        [self saveContext];
    }
}

- (void)dropEntityDeleteWhenDeleteDeviceEntity:(NSNumber *)deviceId {
    if (deviceId) {
        for (GalleryEntity *gallery in [CSRAppStateManager sharedInstance].selectedPlace.gallerys) {
            NSMutableArray *ary = [[NSMutableArray alloc] init];
            for (DropEntity *drop in gallery.drops) {
                if ([drop.deviceID isEqualToNumber:deviceId]) {
                    [ary addObject:drop];
                }
            }
            for (DropEntity *drop in ary) {
                [gallery removeDropsObject:drop];
                [self.managedObjectContext deleteObject:drop];
            }
        }
        [self saveContext];
    }
}

- (void)sceneMemberEntityDeleteWhenDeleteDeviceEntity:(NSNumber *)deviceId {
    if (deviceId) {
        for (SceneEntity *scene in [CSRAppStateManager sharedInstance].selectedPlace.scenes) {
            NSMutableArray *ary = [[NSMutableArray alloc] init];
            for (SceneMemberEntity *member in scene.members) {
                if ([member.deviceID isEqualToNumber:deviceId]) {
                    [ary addObject:member];
                }
            }
            for (SceneMemberEntity *member in ary) {
                [scene removeMembersObject:member];
                [self.managedObjectContext deleteObject:member];
            }
        }
        [self saveContext];
    }
}

#pragma mark - sonos

- (void)cleanSonos:(NSNumber *)deviceID {
    if (deviceID) {
        for (CSRDeviceEntity *deviceEntity in [CSRAppStateManager sharedInstance].selectedPlace.devices) {
            if ([deviceEntity.deviceId isEqualToNumber:deviceID]) {
                if ([deviceEntity.sonoss count]>0) {
                    [deviceEntity removeSonoss:deviceEntity.sonoss];
                }
                for (SonosEntity *sonosEntity in deviceEntity.sonoss) {
                    [self.managedObjectContext deleteObject:sonosEntity];
                }
                [self saveContext];
                break;
            }
        }
    }
}

- (SonosEntity *)saveNewSonos:(NSNumber *)deviceID channel:(NSNumber *)channel infoVersion:(NSNumber *)infoVersion modelType:(NSNumber *)modelType modelNumber:(NSNumber *)modelNumber name:(NSString *)name alive:(NSNumber *)alive{
    __block CSRDeviceEntity *sDeviceEntity;
    [[CSRAppStateManager sharedInstance].selectedPlace.devices enumerateObjectsUsingBlock:^(CSRDeviceEntity * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.deviceId isEqualToNumber:deviceID]) {
            sDeviceEntity = obj;
            *stop = YES;
        }
    }];
    if (sDeviceEntity) {
        sDeviceEntity.mcSonosInfoVersion = infoVersion;
        __block SonosEntity *newSonosEntity;
        [sDeviceEntity.sonoss enumerateObjectsUsingBlock:^(SonosEntity * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj.channel isEqualToNumber:channel]) {
                newSonosEntity = obj;
                *stop = YES;
            }
        }];
        if (!newSonosEntity) {
            newSonosEntity = [NSEntityDescription insertNewObjectForEntityForName:@"SonosEntity" inManagedObjectContext:self.managedObjectContext];
        }
        newSonosEntity.deviceID = deviceID;
        newSonosEntity.channel = channel;
        newSonosEntity.infoVersion = infoVersion;
        newSonosEntity.modelType = modelType;
        newSonosEntity.modelNumber = modelNumber;
        newSonosEntity.name = name;
        newSonosEntity.alive = alive;
        
        [sDeviceEntity addSonossObject:newSonosEntity];
        [self saveContext];
        return newSonosEntity;
    }
    return nil;
}

@end
