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

@property (nonatomic,strong)CSRPlaceEntity *sharePlace;

@end

@implementation CSRParseAndLoad

- (id) init {
    self = [super init];
    if (self) {
        managedObjectContext = [CSRDatabaseManager sharedInstance].managedObjectContext;
        
    }
    return self;
}

- (void) deleteEntitiesInSelectedPlace:(CSRPlaceEntity *)placeEntity
{
    //Delete already devices, areas, gateway and (cloudTenancyID,cloudMeshID,cloudSiteID)
    [placeEntity removeAreas:placeEntity.areas];
    for (CSRAreaEntity *area in placeEntity.areas) {
        [managedObjectContext deleteObject:area];
    }
    
    NSSet *gallerys = placeEntity.gallerys;
    [placeEntity removeGallerys:gallerys];
    for (GalleryEntity *gallery in gallerys) {
        [gallery removeDrops:gallery.drops];
        for (DropEntity *drop in gallery.drops) {
            [managedObjectContext deleteObject:drop];
        }
        [managedObjectContext deleteObject:gallery];
    }
    
    NSSet *scenes = placeEntity.scenes;
    [placeEntity removeScenes:scenes];
    for (SceneEntity *scene in scenes) {
        [scene removeMembers:scene.members];
        for (SceneMemberEntity *member in scene.members) {
            [managedObjectContext deleteObject:member];
        }
        [managedObjectContext deleteObject:scene];
    }
    
    NSSet *timers = placeEntity.timers;
    [placeEntity removeScenes:timers];
    for (TimerEntity *timer in timers) {
        [timer removeTimerDevices:timer.timerDevices];
        for (TimerDeviceEntity *timerDevice in timer.timerDevices) {
            [managedObjectContext deleteObject:timerDevice];
        }
        [managedObjectContext deleteObject:timer];
    }
    
    [placeEntity removeDevices:placeEntity.devices];
    [placeEntity removeGateways:placeEntity.gateways];
    placeEntity.settings.cloudTenancyID = nil;
    placeEntity.settings.cloudMeshID = nil;
    placeEntity.cloudSiteID = nil;
    
    [[CSRDatabaseManager sharedInstance] saveContext];
    
}

- (void)checkForSettings
{
    if (self.sharePlace.settings) {
        
        self.sharePlace.settings.retryInterval = @500;
        self.sharePlace.settings.retryCount = @10;
        self.sharePlace.settings.concurrentConnections = @1;
        self.sharePlace.settings.listeningMode = @1;
        
    } else {
        
        CSRSettingsEntity *settings = [NSEntityDescription insertNewObjectForEntityForName:@"CSRSettingsEntity"
                                                                    inManagedObjectContext:managedObjectContext];
        settings.retryInterval = @500;
        settings.retryCount = @10;
        settings.concurrentConnections = @1;
        settings.listeningMode = @1;
        
        self.sharePlace.settings = settings;
        
    }
}

- (CSRPlaceEntity *) parseIncomingDictionary:(NSDictionary *)parsingDictionary
{
    if (parsingDictionary[@"place"]) {
        NSDictionary *placeDict = parsingDictionary[@"place"];
        NSArray *placesArray = [[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"CSRPlaceEntity" withPredicate:@"name == %@",placeDict[@"placeName"],@"passPhrase == %@",placeDict[@"placePassword"]];
        if (placesArray && placesArray.count>0) {
            
            self.sharePlace = [placesArray firstObject];
            [self deleteEntitiesInSelectedPlace:[placesArray firstObject]];
            
            
        }else {
            self.sharePlace = [NSEntityDescription insertNewObjectForEntityForName:@"CSRPlaceEntity"
                                                            inManagedObjectContext:managedObjectContext];
            
            self.sharePlace.name = placeDict[@"placeName"];
            self.sharePlace.passPhrase = placeDict[@"placePassword"];
            self.sharePlace.color = @([CSRUtilities rgbFromColor:[CSRUtilities colorFromHex:@"#2196f3"]]);
            self.sharePlace.iconID = @(8);
            self.sharePlace.owner = @"My place";
            self.sharePlace.networkKey = nil;
            [self checkForSettings];
            [[CSRDatabaseManager sharedInstance] saveContext];
            [[CSRAppStateManager sharedInstance] setupPlace];
        }
        
        
    }
    
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
            
            if (self.sharePlace) {
                [self.sharePlace addAreasObject:groupObj];
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
                
                __block CSRAreaEntity *foundAreaEntity = nil;
                [self.sharePlace.areas enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
                    CSRAreaEntity *areaEntity = (CSRAreaEntity *)obj;
                    if ([areaEntity.areaID isEqualToNumber:@(desiredValue)]) {
                        foundAreaEntity = areaEntity;
                        *stop = YES;
                    }
                }];
                
                if (foundAreaEntity) {
                    [deviceEntity addAreasObject:foundAreaEntity];
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
            deviceEntity.remoteBranch = deviceDict[@"remoteBranch"];
            
            if (self.sharePlace) {
                [self.sharePlace addDevicesObject:deviceEntity];
            }
        }
        
        [[CSRDatabaseManager sharedInstance] loadDatabase];
    }
    
    if (parsingDictionary[@"gallerys_list"]) {
        for (NSDictionary *galleryDict in parsingDictionary[@"gallerys_list"]) {
            GalleryEntity *galleryObj = [NSEntityDescription insertNewObjectForEntityForName:@"GalleryEntity" inManagedObjectContext:managedObjectContext];
            NSData *galleryImageData = [CSRUtilities dataForHexString:galleryDict[@"galleryImage"]];
            
            galleryObj.galleryID = galleryDict[@"galleryID"];
            galleryObj.galleryImage = galleryImageData;
            galleryObj.boundWidth = galleryDict[@"boundWidth"];
            galleryObj.boundHeight = galleryDict[@"boundHeight"];
            galleryObj.sortId = galleryDict[@"sortId"];
            
            NSMutableArray *drops = [NSMutableArray new];
            if (parsingDictionary[@"drops_list"]) {
                for (NSDictionary *dropDict in parsingDictionary[@"drops_list"]) {
                    if ([dropDict[@"galleryID"] isEqualToNumber:galleryDict[@"galleryID"]]) {
                        DropEntity *dropObj = [NSEntityDescription insertNewObjectForEntityForName:@"DropEntity" inManagedObjectContext:managedObjectContext];
                        dropObj.galleryID = dropDict[@"galleryID"];
                        dropObj.dropID = dropDict[@"dropID"];
                        dropObj.boundRatio = dropDict[@"boundRatio"];
                        dropObj.centerYRatio = dropDict[@"centerYRatio"];
                        dropObj.centerXRatio = dropDict[@"centerXRatio"];
                        dropObj.deviceID = dropDict[@"deviceID"];
                        dropObj.kindName = dropDict[@"kindName"];
                        [drops addObject:dropObj];
                    }
                }
            }
            [galleryObj addDrops:[NSSet setWithArray:drops]];
            
            if (self.sharePlace) {
                [self.sharePlace addGallerysObject:galleryObj];
            }
        }
    }
    
    if (parsingDictionary[@"scenes_list"]) {
        for (NSDictionary * sceneDict in parsingDictionary[@"scenes_list"]) {
            SceneEntity *sceneObj = [NSEntityDescription insertNewObjectForEntityForName:@"SceneEntity" inManagedObjectContext:managedObjectContext];
            sceneObj.sceneID = sceneDict[@"sceneID"];
            sceneObj.iconID = sceneDict[@"iconID"];
            sceneObj.sceneName = sceneDict[@"sceneName"];

            NSMutableArray *members = [NSMutableArray new];
            if (parsingDictionary[@"sceneMembers_list"]) {
                for (NSDictionary *sceneMemberDict in parsingDictionary[@"sceneMembers_list"]) {
                    if ([sceneMemberDict[@"sceneID"] isEqualToNumber:sceneDict[@"sceneID"]]) {
                        SceneMemberEntity *sceneMemberObj = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:managedObjectContext];
                        sceneMemberObj.sceneID = sceneMemberDict[@"sceneID"];
                        sceneMemberObj.deviceID = sceneMemberDict[@"deviceID"];
                        sceneMemberObj.powerState = sceneMemberDict[@"powerState"];
                        sceneMemberObj.level = sceneMemberDict[@"level"];
                        sceneMemberObj.kindString = sceneMemberDict[@"kindString"];
                        [members addObject:sceneMemberObj];
                    }
                }
            }
            [sceneObj addMembers:[NSSet setWithArray:members]];
            if (self.sharePlace) {
                [self.sharePlace addScenesObject:sceneObj];
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
            if (self.sharePlace) {
                [self.sharePlace addTimersObject:timerObj];
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
            
            if (self.sharePlace) {
                [self.sharePlace addGatewaysObject:gatewayObj];
            }
        }
    }
    
    if (parsingDictionary[@"rest_list"])
    {
        for (NSDictionary *restDict in parsingDictionary[@"rest_list"]) {
            
            CSRSettingsEntity *settingsEntity = [[CSRDatabaseManager sharedInstance] settingsForCurrentlySelectedPlace];
            settingsEntity.cloudMeshID = restDict[@"cloudMeshID"];
            settingsEntity.cloudTenancyID = restDict[@"cloudTenantID"];
            
//            CSRPlaceEntity *placeEntity = [[CSRAppStateManager sharedInstance] selectedPlace];
            self.sharePlace.cloudSiteID = restDict[@"cloudSiteID"];
        }
    }
    [[CSRDatabaseManager sharedInstance] saveContext];
    return self.sharePlace;
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
    
    ///////////////////PlaceNamePassword//////////////////////////////////////
    CSRPlaceEntity *place = [CSRAppStateManager sharedInstance].selectedPlace;
    if (place) {
        [jsonDictionary setObject:@{@"placeName":place.name,@"placePassword":place.passPhrase} forKey:@"place"];
    }

    
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
                                          @"sortId": (device.sortId) ? (device.sortId):@0,
                                          @"remoteBranch":(device.remoteBranch)? (device.remoteBranch):@""
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
                                    @"sortId":(area.sortId) ? (area.sortId) : @0
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
                                   @"boundHeight":(gallery.boundHeight)?(gallery.boundHeight):@0,
                                   @"sortId":(gallery.sortId)?(gallery.sortId):@88
                                }];
        
        for (DropEntity *drop in gallery.drops) {
            [dropsArray addObject:@{@"galleryID":(gallery.galleryID)?(gallery.galleryID):@0,
                                    @"dropID":(drop.dropID)?(drop.dropID):@0,
                                    @"boundRatio":(drop.boundRatio)?(drop.boundRatio):@0,
                                    @"centerXRatio":(drop.centerXRatio)?(drop.centerXRatio):@0,
                                    @"centerYRatio":(drop.centerYRatio)?(drop.centerYRatio):@0,
                                    @"deviceID":(drop.deviceID)?(drop.deviceID):@0,
                                    @"kindName":(drop.kindName)?(drop.kindName):@""
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
