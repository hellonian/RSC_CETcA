//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRParseAndLoad.h"
#import "CSRSettingsEntity.h"
#import "CSRDeviceEntity.h"
#import "CSRAreaEntity.h"
#import "CSRUtilities.h"
#import "CSRDatabaseManager.h"
#import "CSRPlaceEntity.h"
#import "CSRAppStateManager.h"
#import <CSRmesh/MeshServiceApi.h>
#import "GalleryEntity.h"
#import "SceneEntity.h"
#import "SceneMemberEntity.h"

@interface CSRParseAndLoad()
{
    
    NSManagedObjectContext *managedObjectContext;
}
@end

@implementation CSRParseAndLoad

- (id) init {
    self = [super init];
    if (self) {
        managedObjectContext = [CSRDatabaseManager sharedInstance].managedObjectContext;
        
    }
    return self;
}

- (void) deleteEntitiesInSelectedPlace
{
    //Delete already devices, areas, gateway and (cloudTenancyID,cloudMeshID,cloudSiteID)
    [[CSRAppStateManager sharedInstance].selectedPlace removeAreas:[CSRAppStateManager sharedInstance].selectedPlace.areas];
    for (CSRAreaEntity *area in [CSRAppStateManager sharedInstance].selectedPlace.areas) {
        [managedObjectContext deleteObject:area];
    }
    
    NSSet *gallerys = [CSRAppStateManager sharedInstance].selectedPlace.gallerys;
    [[CSRAppStateManager sharedInstance].selectedPlace removeGallerys:gallerys];
    for (GalleryEntity *gallery in gallerys) {
        for (DropEntity *drop in gallery.drops) {
            [managedObjectContext deleteObject:drop];
        }
        [managedObjectContext deleteObject:gallery];
    }
    
    NSSet *scenes = [CSRAppStateManager sharedInstance].selectedPlace.scenes;
    [[CSRAppStateManager sharedInstance].selectedPlace removeScenes:scenes];
    for (SceneEntity *scene in scenes) {
        for (SceneMemberEntity *member in scene.members) {
            [managedObjectContext deleteObject:member];
        }
        [managedObjectContext deleteObject:scene];
    }
    
    NSSet *timers = [CSRAppStateManager sharedInstance].selectedPlace.timers;
    [[CSRAppStateManager sharedInstance].selectedPlace removeScenes:timers];
    for (TimerEntity *timer in timers) {
        for (TimerDeviceEntity *timerDevice in timer.timerDevices) {
            [managedObjectContext deleteObject:timerDevice];
        }
        [managedObjectContext deleteObject:timer];
    }
    
    [[CSRAppStateManager sharedInstance].selectedPlace removeDevices:[CSRAppStateManager sharedInstance].selectedPlace.devices];
    [[CSRAppStateManager sharedInstance].selectedPlace removeGateways:[CSRAppStateManager sharedInstance].selectedPlace.gateways];
    [CSRAppStateManager sharedInstance].selectedPlace.settings.cloudTenancyID = nil;
    [CSRAppStateManager sharedInstance].selectedPlace.settings.cloudMeshID = nil;
    [CSRAppStateManager sharedInstance].selectedPlace.cloudSiteID = nil;
    
    [[CSRDatabaseManager sharedInstance] saveContext];
    
}

- (void) parseIncomingDictionary:(NSDictionary *)parsingDictionary
{
    if (parsingDictionary[@"areas_list"])
    {
        for (NSDictionary *areaDict in parsingDictionary[@"areas_list"]) {
            
            CSRAreaEntity *groupObj = [NSEntityDescription insertNewObjectForEntityForName:@"CSRAreaEntity" inManagedObjectContext:managedObjectContext];
            
            NSData *areaImageData = [CSRUtilities dataForHexString:areaDict[@"areaImage"]];
            
            groupObj.areaName = areaDict[@"name"];
            groupObj.areaID = areaDict[@"areaID"];
            groupObj.favourite = areaDict[@"isFavourite"];
            groupObj.areaIconNum = areaDict[@"areaIconNum"];
            groupObj.sortId = areaDict[@"sortId"];
            groupObj.areaImage = areaImageData;
            
            if ([CSRAppStateManager sharedInstance].selectedPlace) {
                [[CSRAppStateManager sharedInstance].selectedPlace addAreasObject:groupObj];
            }
        }
    }
    
    if (parsingDictionary[@"devices_list"])
    {
        for (NSDictionary * deviceDict in parsingDictionary[@"devices_list"]) {
            
            CSRDeviceEntity *deviceEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRDeviceEntity" inManagedObjectContext:managedObjectContext];
            
            NSData *devHash = [CSRUtilities IntToNSData:[deviceDict[@"hash"] unsignedLongLongValue]];
            NSData *modelHigh = [CSRUtilities IntToNSData:[deviceDict[@"modelHigh"] unsignedLongLongValue]];
            NSData *modelLow = [CSRUtilities IntToNSData:[deviceDict[@"modelLow"] unsignedLongLongValue]];
            
            __block NSMutableData *groups = [NSMutableData data];
            NSArray *groupsArray = deviceDict[@"groups"];
            
            
            [groupsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                uint16_t desiredValue = [obj unsignedShortValue];
                [groups appendBytes:&desiredValue length:sizeof(desiredValue)];
                CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:@(desiredValue)];
                
                if (areaEntity) {
                    [deviceEntity addAreasObject:areaEntity];
                }
            }];
            NSData *authCode = [CSRUtilities IntToNSData:[deviceDict[@"authCode"] unsignedLongLongValue]];
            
            deviceEntity.deviceId = deviceDict[@"deviceID"];
            deviceEntity.deviceHash = devHash;
            deviceEntity.shortName = deviceDict[@"shortName"];
            deviceEntity.name = deviceDict[@"name"];
            deviceEntity.appearance = deviceDict[@"appearance"];
            deviceEntity.modelLow = modelLow;
            deviceEntity.modelHigh = modelHigh;
            deviceEntity.groups = [CSRUtilities hexStringFromData:groups];
            deviceEntity.authCode = authCode;
            deviceEntity.nGroups = deviceDict[@"numgroups"];
            deviceEntity.isAssociated = deviceDict[@"isAssociated"];
            deviceEntity.favourite = deviceDict[@"isFavourite"];
            deviceEntity.sortId = deviceDict[@"sortId"];
            
            if ([CSRAppStateManager sharedInstance].selectedPlace) {
                [[CSRAppStateManager sharedInstance].selectedPlace addDevicesObject:deviceEntity];
            }
        }
        
        [[CSRDatabaseManager sharedInstance] loadDatabase];
    }
    
    if (parsingDictionary[@"drops_list"]) {
        for (NSDictionary *dropDict in parsingDictionary[@"drops_list"]) {
            DropEntity *dropObj = [NSEntityDescription insertNewObjectForEntityForName:@"DropEntity" inManagedObjectContext:managedObjectContext];
            dropObj.galleryID = dropDict[@"galleryID"];
            dropObj.dropID = dropDict[@"dropID"];
            dropObj.boundRatio = dropDict[@"boundRatio"];
            dropObj.centerYRatio = dropDict[@"centerYRatio"];
            dropObj.centerXRatio = dropDict[@"centerXRatio"];
            
            CSRDeviceEntity *deviceEntyity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:dropDict[@"deviceID"]];
            dropObj.device = deviceEntyity;
        }
    }
    
    if (parsingDictionary[@"gallerys_list"]) {
        for (NSDictionary *galleryDict in parsingDictionary[@"gallerys_list"]) {
            GalleryEntity *galleryObj = [NSEntityDescription insertNewObjectForEntityForName:@"GalleryEntity" inManagedObjectContext:managedObjectContext];
            NSData *galleryImageData = [CSRUtilities dataForHexString:galleryDict[@"galleryImage"]];
            
            NSArray *drops = [[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"DropEntity" withPredicate:@"galleryID == %@",galleryDict[@"galleryID"]];
            [galleryObj addDrops:[NSSet setWithArray:drops]];
            
            galleryObj.galleryID = galleryDict[@"galleryID"];
            galleryObj.galleryImage = galleryImageData;
            galleryObj.boundWidth = galleryDict[@"boundWidth"];
            galleryObj.boundHeight = galleryDict[@"boundHeight"];
            
            if ([CSRAppStateManager sharedInstance].selectedPlace) {
                [[CSRAppStateManager sharedInstance].selectedPlace addGallerysObject:galleryObj];
            }
        }
    }
    
    if (parsingDictionary[@"sceneMembers_list"]) {
        for (NSDictionary *sceneMemberDict in parsingDictionary[@"sceneMembers_list"]) {
            SceneMemberEntity *sceneMemberObj = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:managedObjectContext];
            sceneMemberObj.sceneID = sceneMemberDict[@"sceneID"];
            sceneMemberObj.deviceID = sceneMemberDict[@"deviceID"];
            sceneMemberObj.powerState = sceneMemberDict[@"powerState"];
            sceneMemberObj.level = sceneMemberDict[@"level"];
            sceneMemberObj.kindString = sceneMemberDict[@"kindString"];
        }
    }
    if (parsingDictionary[@"scenes_list"]) {
        for (NSDictionary * sceneDict in parsingDictionary[@"scenes_list"]) {
            SceneEntity *sceneObj = [NSEntityDescription insertNewObjectForEntityForName:@"SceneEntity" inManagedObjectContext:managedObjectContext];
            sceneObj.sceneID = sceneDict[@"sceneID"];
            sceneObj.iconID = sceneDict[@"iconID"];
            sceneObj.sceneName = sceneDict[@"sceneName"];
            NSArray *members = [[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"SceneMemberEntity" withPredicate:@"sceneID == %@",sceneDict[@"sceneID"]];
            [sceneObj addMembers:[NSSet setWithArray:members]];
            if ([CSRAppStateManager sharedInstance].selectedPlace) {
                [[CSRAppStateManager sharedInstance].selectedPlace addScenesObject:sceneObj];
            }
        }
    }
    
    if (parsingDictionary[@"timerDevices_list"]) {
        for (NSDictionary *timerDeviceDict in parsingDictionary[@"timerDevices_list"]) {
            TimerDeviceEntity *timerDeviceObj = [NSEntityDescription insertNewObjectForEntityForName:@"TimerDeviceEntity" inManagedObjectContext:managedObjectContext];
            timerDeviceObj.timerID = timerDeviceDict[@"timerID"];
            timerDeviceObj.deviceID = timerDeviceDict[@"deviceID"];
            timerDeviceObj.timerIndex = timerDeviceDict[@"timerIndex"];
        }
    }
    if (parsingDictionary[@"timers_list"]) {
        for (NSDictionary *timerDict in parsingDictionary[@"timers_list"]) {
            NSDateFormatter *matter = [[NSDateFormatter alloc] init];
            matter.dateFormat = @"YYYYMMddHHmmss";
            TimerEntity *timerObj = [NSEntityDescription insertNewObjectForEntityForName:@"TimerEntity" inManagedObjectContext:managedObjectContext];
            timerObj.timerID = timerDict[@"timerID"];
            timerObj.name = timerDict[@"name"];
            timerObj.enabled = timerDict[@"enabled"];
            timerObj.fireTime = [matter dateFromString:timerDict[@"fireTime"]];
            timerObj.fireDate = [matter dateFromString:timerDict[@"fireDate"]];
            timerObj.repeat = timerDict[@"repeat"];
            NSArray *timerDevices = [[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"TimerDeviceEntity" withPredicate:@"timerID == %@",timerDict[@"timerID"]];
            [timerObj addTimerDevices:[NSSet setWithArray:timerDevices]];
            if ([CSRAppStateManager sharedInstance].selectedPlace) {
                [[CSRAppStateManager sharedInstance].selectedPlace addTimersObject:timerObj];
            }
        }
    }
    
    
    if (parsingDictionary[@"gateways_list"])
    {
        for (NSDictionary *gatewayDict in parsingDictionary[@"gateways_list"]) {
            
            CSRGatewayEntity *gatewayObj = [NSEntityDescription insertNewObjectForEntityForName:@"CSRGatewayEntity" inManagedObjectContext:managedObjectContext];
            
            NSData *devHash = [CSRUtilities IntToNSData:[gatewayDict[@"deviceHash"] unsignedLongLongValue]];
            
            gatewayObj.basePath = gatewayDict[@"basePath"];
            gatewayObj.host = gatewayDict[@"host"];
            gatewayObj.name = gatewayDict[@"name"];
            
            if ([gatewayDict[@"port"] isKindOfClass:[NSString class]]) {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.numberStyle = NSNumberFormatterDecimalStyle;
                NSNumber *portNumber = [formatter numberFromString:gatewayDict[@"port"]];
                gatewayObj.port = portNumber;
            } else {
                gatewayObj.port = gatewayDict[@"port"];
            }
            
            
            gatewayObj.uuid = gatewayDict[@"uuid"];
            gatewayObj.deviceId = gatewayDict[@"deviceID"];
            gatewayObj.state = gatewayDict[@"state"];
            gatewayObj.deviceHash = devHash;
            
            if ([CSRAppStateManager sharedInstance].selectedPlace) {
                [[CSRAppStateManager sharedInstance].selectedPlace addGatewaysObject:gatewayObj];
            }
        }
    }
    
    if (parsingDictionary[@"rest_list"])
    {
        for (NSDictionary *restDict in parsingDictionary[@"rest_list"]) {
            
            CSRSettingsEntity *settingsEntity = [[CSRDatabaseManager sharedInstance] settingsForCurrentlySelectedPlace];
            settingsEntity.cloudMeshID = restDict[@"cloudMeshID"];
            settingsEntity.cloudTenancyID = restDict[@"cloudTenantID"];
            
            CSRPlaceEntity *placeEntity = [[CSRAppStateManager sharedInstance] selectedPlace];
            placeEntity.cloudSiteID = restDict[@"cloudSiteID"];
        }
    }
    [[CSRDatabaseManager sharedInstance] saveContext];
}

#pragma mark -
#pragma mark Compose Database

- (NSData *) composeDatabase
{
    NSMutableDictionary *jsonDictionary = [NSMutableDictionary new];
    NSMutableArray *devicesArray = [NSMutableArray new];
    NSMutableArray *areasArray = [NSMutableArray new];
    NSMutableArray *gallerysArray = [NSMutableArray new];
    NSMutableArray *dropsArray = [NSMutableArray new];
    NSMutableArray *scenesArray = [NSMutableArray new];
    NSMutableArray *sceneMembersArray = [NSMutableArray new];
    NSMutableArray *timersArray = [NSMutableArray new];
    NSMutableArray *timerDevicesArray = [NSMutableArray new];
    NSMutableArray *gatewayArray = [NSMutableArray new];
    NSMutableArray *restArray = [NSMutableArray new];
    
    ///////////////////Devices//////////////////////////////////////
        
        NSSet *devices = [CSRAppStateManager sharedInstance].selectedPlace.devices;
        if (devices) {
            for (CSRDeviceEntity *device in devices) {
                
                uint64_t hash = [CSRUtilities NSDataToInt:device.deviceHash];
                uint64_t modelLow = [CSRUtilities NSDataToInt:device.modelLow];
                uint64_t modelHigh = [CSRUtilities NSDataToInt:device.modelHigh];
                NSString *dhmKey = [[NSString alloc] initWithData:device.dhmKey encoding:NSUTF8StringEncoding];
                
                NSData *groups = [CSRUtilities dataForHexString:device.groups];
                uint16_t *choppedValue = (uint16_t*)groups.bytes;
                NSMutableArray *groupsInArray = [NSMutableArray array];
                for (int i = 0; i < device.groups.length/2; i++) {
                    NSNumber *group = @(*choppedValue++);
                    [groupsInArray addObject:group];
                }
                
                uint16_t authCode = [CSRUtilities NSDataToInt:device.authCode];
                
                [devicesArray addObject:@{@"deviceID":(device.deviceId) ? (device.deviceId) : @0,
                                          @"name":(device.name) ? (device.name) : @"",
                                          @"shortName":(device.shortName)?(device.shortName):@"",
                                          @"appearance":(device.appearance) ? (device.appearance) : @0,
                                          @"hash":[NSNumber numberWithUnsignedLongLong:hash] ? [NSNumber numberWithUnsignedLongLong:hash] : @0,
                                          @"modelLow":[NSNumber numberWithUnsignedLongLong:modelLow] ? [NSNumber numberWithUnsignedLongLong:modelLow] : @0,
                                          @"modelHigh":[NSNumber numberWithUnsignedLongLong:modelHigh] ? [NSNumber numberWithUnsignedLongLong:modelHigh] : @0,
                                          @"numgroups":(device.nGroups) ? (device.nGroups) : @0,
                                          @"groups":groupsInArray,
                                          @"authCode":([NSNumber numberWithUnsignedLongLong:authCode]) ? [NSNumber numberWithUnsignedLongLong:authCode] : @0,
                                          @"isAssociated":(device.isAssociated) ? (device.isAssociated) : @0,
                                          @"isFavourite":(device.favourite) ? (device.favourite) : @0,
                                          @"dhmKey" : dhmKey ? dhmKey : @"",
                                          @"sortId": (device.sortId) ? (device.sortId):@0
                                          }];
            }
        }
        if (devicesArray) {
            [jsonDictionary setObject:devicesArray forKey:@"devices_list"];
        }
        
        ///////////////////Areas//////////////////////////////////////
        
        NSSet *areas = [CSRAppStateManager sharedInstance].selectedPlace.areas;
        
        for (CSRAreaEntity *area in areas) {

            NSString *areaImage = [CSRUtilities hexStringFromData:area.areaImage];
            
            [areasArray addObject:@{@"areaID":(area.areaID) ? (area.areaID) : @0,
                                    @"name":(area.areaName) ? (area.areaName) : @"",
                                    @"isFavourite":(area.favourite) ? (area.favourite) : @0,
                                    @"areaIconNum":(area.areaIconNum) ? (area.areaIconNum):@0,
                                    @"areaImage":areaImage ? areaImage : @"",
                                    @"sortId":(area.sortId) ? (area.sortId) : @0,
                                    }];
            
        }
        
        [jsonDictionary setObject:areasArray forKey:@"areas_list"];
    
    ///////////////////gallery  drop//////////////////////////////////////
    NSSet *gallerys = [CSRAppStateManager sharedInstance].selectedPlace.gallerys;
    
    for (GalleryEntity *gallery in gallerys) {
        
        NSString *galleryImage = [CSRUtilities hexStringFromData:gallery.galleryImage];
        
        [gallerysArray addObject:@{@"galleryID":(gallery.galleryID)?(gallery.galleryID):@0,
                                   @"galleryImage":galleryImage?galleryImage:@"",
                                   @"boundWidth":(gallery.boundWidth)?(gallery.boundWidth):@0,
                                   @"boundHeight":(gallery.boundHeight)?(gallery.boundHeight):@0
                                }];
        
        for (DropEntity *drop in gallery.drops) {
            [dropsArray addObject:@{@"galleryID":(gallery.galleryID)?(gallery.galleryID):@0,
                                    @"dropID":(drop.dropID)?(drop.dropID):@0,
                                    @"boundRatio":(drop.boundRatio)?(drop.boundRatio):@0,
                                    @"centerXRatio":(drop.centerXRatio)?(drop.centerXRatio):@0,
                                    @"centerYRatio":(drop.centerYRatio)?(drop.centerYRatio):@0,
                                    @"deviceID":(drop.device.deviceId)?(drop.device.deviceId):@0
                                    }];
        }
        
    }
    
    [jsonDictionary setObject:gallerysArray forKey:@"gallerys_list"];
    [jsonDictionary setObject:dropsArray forKey:@"drops_list"];
    
    ///////////////////scene//////////////////////////////////////
    NSSet *scenes = [CSRAppStateManager sharedInstance].selectedPlace.scenes;
    for (SceneEntity *scene in scenes) {
        [scenesArray addObject:@{@"sceneID":(scene.sceneID)?(scene.sceneID):@0,
                                 @"iconID":(scene.iconID)?(scene.iconID):@0,
                                 @"sceneName":scene.sceneName?scene.sceneName:@""
                                 }];
        
        for (SceneMemberEntity *sceneMember in scene.members) {
            [sceneMembersArray addObject:@{@"sceneID":(scene.sceneID)?(scene.sceneID):@0,
                                           @"deviceID":(sceneMember.deviceID)?(sceneMember.deviceID):@0,
                                           @"powerState":(sceneMember.powerState)?(sceneMember.powerState):@0,
                                           @"level":(sceneMember.level)?(sceneMember.level):@0,
                                           @"kindString":sceneMember.kindString?sceneMember.kindString:@""
                                           }];
        }
        
    }
    [jsonDictionary setObject:scenesArray forKey:@"scenes_list"];
    [jsonDictionary setObject:sceneMembersArray forKey:@"sceneMembers_list"];
    
    ///////////////////timer//////////////////////////////////////
    NSSet *timers = [CSRAppStateManager sharedInstance].selectedPlace.timers;
    for (TimerEntity *timer in timers) {
        NSDateFormatter *matter = [[NSDateFormatter alloc] init];
        matter.dateFormat = @"YYYYMMddHHmmss";
        NSString *fireTimeStr = [matter stringFromDate:timer.fireTime];
        NSString *fireDateStr = [matter stringFromDate:timer.fireDate];
        [timersArray addObject:@{@"timerID":(timer.timerID)?(timer.timerID):@0,
                                 @"name":timer.name?timer.name:@"",
                                 @"enabled":(timer.enabled)?(timer.enabled):@0,
                                 @"fireTime":fireTimeStr?fireTimeStr:@"20180101000000",
                                 @"fireDate":fireDateStr?fireDateStr:@"20180101000000",
                                 @"repeat":timer.repeat?timer.repeat:@""
                                 }];
        for (TimerDeviceEntity *timerDevice in timer.timerDevices) {
            [timerDevicesArray addObject:@{@"timerID":(timer.timerID)?(timer.timerID):@0,
                                           @"deviceID":(timerDevice.deviceID)?(timerDevice.deviceID):@0,
                                           @"timerIndex":(timerDevice.timerIndex)?(timerDevice.timerIndex):@0
                                           }];
        }
    }
    [jsonDictionary setObject:timersArray forKey:@"timers_list"];
    [jsonDictionary setObject:timerDevicesArray forKey:@"timerDevices_list"];
        
        ///////////////////Gateway//////////////////////////////////////
        
        NSSet *gateways = [CSRAppStateManager sharedInstance].selectedPlace.gateways;
        
        for (CSRGatewayEntity *gateway in gateways) {
            uint64_t hash = [CSRUtilities NSDataToInt:gateway.deviceHash];
            [gatewayArray addObject:@{@"basePath":(gateway.basePath) ? (gateway.basePath) : @"",
                                      @"host":(gateway.host) ? (gateway.host) : @"",
                                      @"name":(gateway.name) ? (gateway.name) : @"",
                                      @"port":(gateway.port) ? (gateway.port) : @0,
                                      @"uuid":(gateway.uuid) ? (gateway.uuid) : @"",
                                      @"deviceID":(gateway.deviceId) ? (gateway.deviceId) : @0,
                                      @"state":(gateway.state) ? (gateway.state) : @0,
                                      @"deviceHash":[NSNumber numberWithUnsignedLongLong:hash] ? [NSNumber numberWithUnsignedLongLong:hash] : @0}];
        }
        
        [jsonDictionary setObject:gatewayArray forKey:@"gateways_list"];
        
        ///////////////////Rest//////////////////////////////////////
        
        CSRSettingsEntity *settingEntity = [[CSRDatabaseManager sharedInstance] settingsForCurrentlySelectedPlace];
        CSRPlaceEntity *placeEntity = [CSRAppStateManager sharedInstance].selectedPlace;
    
        //TODO: Temporary fix to get cloudMeshID
        NSString *meshId = [[MeshServiceApi sharedInstance] getMeshId];
    
        [restArray addObject:@{@"cloudMeshID": meshId,//(settingEntity.cloudMeshID) ? (settingEntity.cloudMeshID) : @"",
                               @"cloudTenantID": (settingEntity.cloudTenancyID) ? (settingEntity.cloudTenancyID) : @"",
                               @"cloudSiteID": (placeEntity.cloudSiteID) ? (placeEntity.cloudSiteID) : @""}];
        
        [jsonDictionary setObject:restArray forKey:@"rest_list"];
    
    /////////////////////////////////////////////////////////////
    NSError *error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary
                                                       options:0
                                                         error:&error];
    return jsonData;
    
}

@end
