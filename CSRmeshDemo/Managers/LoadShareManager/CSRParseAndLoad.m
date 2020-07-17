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
#import "RGBSceneEntity.h"

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
        for (DropEntity *drop in gallery.drops) {
            [managedObjectContext deleteObject:drop];
        }
        [managedObjectContext deleteObject:gallery];
    }
    
    NSSet *scenes = placeEntity.scenes;
    [placeEntity removeScenes:scenes];
    for (SceneEntity *scene in scenes) {
        for (SceneMemberEntity *member in scene.members) {
            [managedObjectContext deleteObject:member];
        }
        [managedObjectContext deleteObject:scene];
    }
    
    NSSet *timers = placeEntity.timers;
    [placeEntity removeTimers:timers];
    for (TimerEntity *timer in timers) {
        for (TimerDeviceEntity *timerDevice in timer.timerDevices) {
            [managedObjectContext deleteObject:timerDevice];
        }
        [managedObjectContext deleteObject:timer];
    }
    
    NSSet *devices = placeEntity.devices;
    [placeEntity removeDevices:placeEntity.devices];
    for (CSRDeviceEntity *device in devices) {
        for (RGBSceneEntity *rgbScene in device.rgbScenes) {
            [managedObjectContext deleteObject:rgbScene];
        }
        [managedObjectContext deleteObject:device];
    }
    [placeEntity removeGateways:placeEntity.gateways];
//    placeEntity.settings.cloudTenancyID = nil;
//    placeEntity.settings.cloudMeshID = nil;
//    placeEntity.cloudSiteID = nil;
    
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
        NSArray *placesArray = [[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"CSRPlaceEntity" withPredicate:@"passPhrase == %@ and name == %@",placeDict[@"placePassword"],placeDict[@"placeName"]];
        if (placesArray && placesArray.count>0) {

            self.sharePlace = [placesArray firstObject];
            self.sharePlace.name = placeDict[@"placeName"];
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
                [groups appendBytes:&desiredValue length:2];
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
            deviceEntity.uuid = deviceDict[@"uuid"];
            deviceEntity.dhmKey = [CSRUtilities dataForHexString:deviceDict[@"dhmKey"]];
            deviceEntity.cvVersion = deviceDict[@"cvVersion"];
            deviceEntity.firVersion = deviceDict[@"firVersion"];
            deviceEntity.mcuBootVersion = deviceDict[@"mcuBootVersion"];
            deviceEntity.mcuHVersion = deviceDict[@"mcuHVersion"];
            deviceEntity.mcuSVersion = deviceDict[@"mcuSVersion"];
            deviceEntity.bleFirVersion = deviceDict[@"bleFirVersion"];
            deviceEntity.bleHwVersion = deviceDict[@"bleHwVersion"];
            deviceEntity.hwVersion = deviceDict[@"hwVersion"];
            
            NSMutableArray *rgbScenes = [NSMutableArray new];
            if (parsingDictionary[@"rgbScene_list"]) {
                for (NSDictionary *rgbSceneDict in parsingDictionary[@"rgbScene_list"]) {
                    if ([rgbSceneDict[@"deviceId"] isEqualToNumber:deviceDict[@"deviceID"]]) {
                        RGBSceneEntity *rgbSceneObj = [NSEntityDescription insertNewObjectForEntityForName:@"RGBSceneEntity" inManagedObjectContext:managedObjectContext];
                        rgbSceneObj.deviceID = rgbSceneDict[@"deviceId"];
                        rgbSceneObj.name = rgbSceneDict[@"name"];
                        rgbSceneObj.isDefaultImg = rgbSceneDict[@"deviceId"];
                        NSData *rgbSceneImage = [CSRUtilities dataForHexString:rgbSceneDict[@"rgbSceneImage"]];
                        rgbSceneObj.rgbSceneImage = rgbSceneImage;
                        rgbSceneObj.rgbSceneID = rgbSceneDict[@"rgbSceneID"];
                        rgbSceneObj.level = rgbSceneDict[@"level"];
                        rgbSceneObj.colorSat = rgbSceneDict[@"colorSat"];
                        rgbSceneObj.eventType = rgbSceneDict[@"eventType"];
                        rgbSceneObj.hueA = rgbSceneDict[@"hueA"];
                        rgbSceneObj.hueB = rgbSceneDict[@"hueB"];
                        rgbSceneObj.hueC = rgbSceneDict[@"hueC"];
                        rgbSceneObj.hueD = rgbSceneDict[@"hueD"];
                        rgbSceneObj.hueE = rgbSceneDict[@"hueE"];
                        rgbSceneObj.hueF = rgbSceneDict[@"hueF"];
                        rgbSceneObj.changeSpeed = rgbSceneDict[@"changeSpeed"];
                        rgbSceneObj.sortID = rgbSceneDict[@"sortID"];
                        [rgbScenes addObject:rgbSceneObj];
                    }
                }
            }
            [deviceEntity addRgbScenes:[NSSet setWithArray:rgbScenes]];
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
            sceneObj.rcIndex = sceneDict[@"rcIndex"];
            sceneObj.enumMethod = sceneDict[@"enumMethod"];

            NSMutableArray *members = [NSMutableArray new];
            if (parsingDictionary[@"sceneMembers_list"]) {
                for (NSDictionary *sceneMemberDict in parsingDictionary[@"sceneMembers_list"]) {
                    if ([sceneMemberDict[@"sceneID"] isEqualToNumber:sceneDict[@"sceneID"]]) {
                        SceneMemberEntity *sceneMemberObj = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:managedObjectContext];
                        sceneMemberObj.sceneID = sceneMemberDict[@"sceneID"];
                        sceneMemberObj.deviceID = sceneMemberDict[@"deviceID"];
                        sceneMemberObj.kindString = sceneMemberDict[@"kindString"];
                        sceneMemberObj.sortID = sceneMemberDict[@"sortID"];
                        sceneMemberObj.eveType = sceneMemberDict[@"eveType"];
                        sceneMemberObj.channel = sceneMemberDict[@"channel"];
                        sceneMemberObj.eveD0 = sceneMemberDict[@"eveD0"];
                        sceneMemberObj.eveD1 = sceneMemberDict[@"eveD1"];
                        sceneMemberObj.eveD2 = sceneMemberDict[@"eveD2"];
                        sceneMemberObj.eveD3 = sceneMemberDict[@"eveD3"];
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
            timerObj.sceneID = timerDict[@"sceneID"];
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
    NSMutableArray *rgbSceneArray = [NSMutableArray new];
    
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
                NSString *dhmKey = [CSRUtilities hexStringForData:device.dhmKey];
                
//                NSData *groups = [CSRUtilities dataForHexString:device.groups];
//                NSLog(@"<-- %@",groups);
//                uint16_t *choppedValue = (uint16_t*)groups.bytes;
//                NSMutableArray *groupsInArray = [NSMutableArray array];
//                for (int i = 0; i < device.groups.length/2; i++) {
//                    NSNumber *group = @(*choppedValue++);
//                    NSLog(@"%@ --> %@",device.deviceId,group);
//                    [groupsInArray addObject:group];
//                }
                NSMutableArray *groupsInArray = [[NSMutableArray alloc] init];
                NSString *groupsString = device.groups;
                if ([groupsString length]<32) {
                    for (; ; ) {
                        groupsString = [NSString stringWithFormat:@"%@%@",groupsString,@"0"];
                        if ([groupsString length]>=32) {
                            break;
                        }
                    }
                }
                for (int i = 0; i<8; i++) {
                    int j = i*4;
                    NSString *str = [groupsString substringWithRange:NSMakeRange(j, 4)];
                    NSString *str1 = [str substringWithRange:NSMakeRange(0, 2)];
                    NSString *str2 = [str substringWithRange:NSMakeRange(2, 2)];
                    NSNumber *num = @([CSRUtilities numberWithHexString:[NSString stringWithFormat:@"%@%@",str2,str1]]);
                    [groupsInArray addObject:num];
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
                                          @"remoteBranch":(device.remoteBranch)? (device.remoteBranch):@"",
                                          @"uuid":(device.uuid)?(device.uuid):@"",
                                          @"cvVersion":(device.cvVersion)?(device.cvVersion):@0,
                                          @"firVersion":(device.firVersion)?(device.firVersion):@0,
                                          @"mcuBootVersion":(device.mcuBootVersion)?(device.mcuBootVersion):@0,
                                          @"mcuHVersion":(device.mcuHVersion)?(device.mcuHVersion):@0,
                                          @"mcuSVersion":(device.mcuSVersion)?(device.mcuSVersion):@0,
                                          @"bleFirVersion":(device.bleFirVersion)?(device.bleFirVersion):@0,
                                          @"bleHwVersion":(device.bleHwVersion)?(device.bleHwVersion):@0,
                                          @"hwVersion":(device.hwVersion)?(device.hwVersion):@0
                                          }];
                
                if (device.rgbScenes && [device.rgbScenes count]>0) {
                    for (RGBSceneEntity *rgbScene in device.rgbScenes) {
                        NSString *rgbsceneImage = [CSRUtilities hexStringFromData:rgbScene.rgbSceneImage];
                        [rgbSceneArray addObject:@{@"deviceId":(device.deviceId)? (device.deviceId):@0,
                                                   @"name":(rgbScene.name)? (rgbScene.name):@"",
                                                   @"isDefaultImg":(rgbScene.isDefaultImg)? (rgbScene.isDefaultImg):@0,
                                                   @"rgbSceneImage":(rgbsceneImage)? rgbsceneImage:@"",
                                                   @"rgbSceneID":(rgbScene.rgbSceneID)? (rgbScene.rgbSceneID):@0,
                                                   @"level":(rgbScene.level)? (rgbScene.level):@0,
                                                   @"colorSat":(rgbScene.colorSat)? (rgbScene.colorSat):@0,
                                                   @"eventType":(rgbScene.eventType)? (rgbScene.eventType):@0,
                                                   @"hueA":(rgbScene.hueA)? (rgbScene.hueA):@0,
                                                   @"hueB":(rgbScene.hueB)? (rgbScene.hueB):@0,
                                                   @"hueC":(rgbScene.hueC)? (rgbScene.hueC):@0,
                                                   @"hueD":(rgbScene.hueD)? (rgbScene.hueD):@0,
                                                   @"hueE":(rgbScene.hueE)? (rgbScene.hueE):@0,
                                                   @"hueF":(rgbScene.hueF)? (rgbScene.hueF):@0,
                                                   @"changeSpeed":(rgbScene.changeSpeed)? (rgbScene.changeSpeed):@0,
                                                   @"sortID":(rgbScene.sortID)? (rgbScene.sortID):@0
                                                   }];
                    }
                }
                
            }
        }
        if (rgbSceneArray) {
            [jsonDictionary setObject:rgbSceneArray forKey:@"rgbScene_list"];
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
                                 @"sceneName":scene.sceneName?scene.sceneName:@"",
                                 @"rcIndex":(scene.rcIndex)?(scene.rcIndex):@0,
                                 @"enumMethod":(scene.enumMethod)?(scene.enumMethod):@0
                                 }];
        
        for (SceneMemberEntity *sceneMember in scene.members) {
            [sceneMembersArray addObject:@{@"sceneID":(scene.sceneID)?(scene.sceneID):@0,
                                           @"deviceID":(sceneMember.deviceID)?(sceneMember.deviceID):@0,
                                           @"kindString":sceneMember.kindString?sceneMember.kindString:@"",
                                           @"sortID":sceneMember.sortID?(sceneMember.sortID):@0,
                                           @"eveType":sceneMember.eveType?(sceneMember.eveType):@0,
                                           @"channel":sceneMember.channel?(sceneMember.channel):@0,
                                           @"eveD0":sceneMember.eveD0?(sceneMember.eveD0):@0,
                                           @"eveD1":sceneMember.eveD1?(sceneMember.eveD1):@0,
                                           @"eveD2":sceneMember.eveD2?(sceneMember.eveD2):@0,
                                           @"eveD3":sceneMember.eveD3?(sceneMember.eveD3):@0
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
                                 @"repeat":timer.repeat?timer.repeat:@"",
                                 @"sceneID":timer.sceneID?timer.sceneID:@0}];
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
//    NSError *error;
//    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary
//                                                       options:0
//                                                         error:&error];
    NSString *jsonString = [CSRUtilities convertToJsonData:jsonDictionary];
    NSLog(@"%@",jsonString);
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    return jsonData;
    
}

- (CSRPlaceEntity *) parseIncomingDictionaryFromAndroid:(NSMutableArray *)files {
    
    if ([files count]>0) {
        NSDictionary *parsingDictionary = [files objectAtIndex:0];
        if (parsingDictionary[@"KEY_CUR_PLACE"]) {
            NSDictionary *placeDict = parsingDictionary[@"KEY_CUR_PLACE"];
            NSArray *placesArray = [[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"CSRPlaceEntity" withPredicate:@"passPhrase == %@ and name == %@",placeDict[@"`c_passphrase`"],placeDict[@"`c_name`"]];
            if (placesArray && placesArray.count>0) {

                self.sharePlace = [placesArray firstObject];
                self.sharePlace.name = placeDict[@"`c_name`"];
                [self deleteEntitiesInSelectedPlace:[placesArray firstObject]];


            }else {
                self.sharePlace = [NSEntityDescription insertNewObjectForEntityForName:@"CSRPlaceEntity"
                                                                inManagedObjectContext:managedObjectContext];
                
                self.sharePlace.name = placeDict[@"`c_name`"];
                self.sharePlace.passPhrase = placeDict[@"`c_passphrase`"];
                self.sharePlace.color = @([CSRUtilities rgbFromColor:[CSRUtilities colorFromHex:@"#2196f3"]]);
                self.sharePlace.iconID = @(8);
                self.sharePlace.owner = @"My place";
                self.sharePlace.networkKey = nil;
                [self checkForSettings];
                [[CSRDatabaseManager sharedInstance] saveContext];
                [[CSRAppStateManager sharedInstance] setupPlace];
            }
        }
        
        if (parsingDictionary[@"KEY_DEVICES_LIST"]) {
            for (NSDictionary * deviceDict in parsingDictionary[@"KEY_DEVICES_LIST"]) {
                NSNumber *type = (NSNumber *)deviceDict[@"`c_type`"];
                if ([type isEqualToNumber:@(0)]) {
                    CSRAreaEntity *groupObj = [NSEntityDescription insertNewObjectForEntityForName:@"CSRAreaEntity" inManagedObjectContext:managedObjectContext];
                    groupObj.areaName = deviceDict[@"`c_subName`"];
                    groupObj.areaID = deviceDict[@"`c_csr_deviceId`"];
                    groupObj.sortId = deviceDict[@"`c_orderIndex`"];
                    groupObj.androidId = deviceDict[@"`_id`"];
                    NSString *imageStr = deviceDict[@"`c_bgImage`"];
                    if ([imageStr length]>0) {
                        groupObj.areaIconNum = @(99);
                        groupObj.areaImage = [files objectAtIndex:1];
                        [files removeObjectAtIndex:1];
                    }else {
                        groupObj.areaIconNum = deviceDict[@"`c_resIndex`"];
                    }
                    
                    if (self.sharePlace) {
                        [self.sharePlace addAreasObject:groupObj];
                    }
                }
            }
        }
        
        if (parsingDictionary[@"KEY_DEVICES_LIST"]) {
            for (NSDictionary * deviceDict in parsingDictionary[@"KEY_DEVICES_LIST"]) {
                NSNumber *type = (NSNumber *)deviceDict[@"`c_type`"];
                if (![type isEqualToNumber:@(0)]) {
                    CSRDeviceEntity *deviceEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRDeviceEntity" inManagedObjectContext:managedObjectContext];
                    
                    deviceEntity.deviceId = (NSNumber *)deviceDict[@"`c_csr_deviceId`"];
                    deviceEntity.deviceHash = [CSRUtilities IntToNSData:[deviceDict[@"`c_uuidHash`"] unsignedLongLongValue]];
                    deviceEntity.shortName = deviceDict[@"`c_shortName`"];
                    deviceEntity.name = deviceDict[@"`c_name`"];
                    deviceEntity.uuid = deviceDict[@"`c_uuid`"];
                    deviceEntity.dhmKey = [CSRUtilities dataForHexString:deviceDict[@"`c_dmkey`"]];
                    deviceEntity.sortId = deviceDict[@"`c_orderIndex`"];
                    deviceEntity.androidId = deviceDict[@"`_id`"];
                    deviceEntity.cvVersion = deviceDict[@"`c_user_version`"];
                    deviceEntity.hwVersion = deviceDict[@"`c_hardware_version`"];
                    deviceEntity.mcuSVersion = deviceDict[@"`c_mcu_s_version`"];
                    
                    __block NSMutableData *groups = [NSMutableData data];
                    if (parsingDictionary[@"KEY_PARENTDEVICE_LIST"]) {
                        for (NSDictionary *parentDict in parsingDictionary[@"KEY_PARENTDEVICE_LIST"]) {
                            NSNumber *parentType = (NSNumber *)parentDict[@"`c_parent_type`"];
                            
                            NSNumber *childId = (NSNumber *)parentDict[@"`c_device_id`"];
                            if ([parentType isEqualToNumber:@(2)] && [childId isEqualToNumber:deviceDict[@"`_id`"]]) {
                                NSNumber *parentId = (NSNumber *)parentDict[@"`c_parent_id`"];
                                [self.sharePlace.areas enumerateObjectsUsingBlock:^(CSRAreaEntity * _Nonnull obj, BOOL * _Nonnull stop) {
                                    if ([obj.androidId isEqualToNumber:parentId]) {
                                        uint16_t desiredValue = [obj.areaID unsignedShortValue];
                                        [groups appendBytes:&desiredValue length:2];
                                        [deviceEntity addAreasObject:obj];
                                        *stop = YES;
                                    }
                                }];
                            }
                        }
                    }
                    
                    Byte byte[] = {0x00};
                    for (; ; ) {
                        if ([groups length]>=16) {
                            break;
                        }else {
                            [groups appendBytes:&byte length:1];
                        }
                    }
                    deviceEntity.groups = [CSRUtilities hexStringFromData:groups];
                    
                    NSMutableArray *rgbScenes = [NSMutableArray new];
                    if (parsingDictionary[@"KEY_RGB_SCENE_LIST"]) {
                        for (NSDictionary *rgbSceneDict in parsingDictionary[@"KEY_RGB_SCENE_LIST"]) {
                            if ([(NSNumber *)rgbSceneDict[@"`c_csr_deviceId`"] isEqualToNumber:(NSNumber *)deviceDict[@"`c_csr_deviceId`"]]) {
                                RGBSceneEntity *rgbSceneObj = [NSEntityDescription insertNewObjectForEntityForName:@"RGBSceneEntity" inManagedObjectContext:managedObjectContext];
                                rgbSceneObj.deviceID = rgbSceneDict[@"`c_csr_deviceId`"];
                                rgbSceneObj.name = rgbSceneDict[@"`c_name`"];
                                rgbSceneObj.isDefaultImg = rgbSceneDict[@"`c_csr_deviceId`"];
//                                NSData *rgbSceneImage = [CSRUtilities dataForHexString:rgbSceneDict[@"rgbSceneImage"]];
//                                rgbSceneObj.rgbSceneImage = rgbSceneImage;
                                rgbSceneObj.rgbSceneID = rgbSceneDict[@"`c_resIndex`"];
                                rgbSceneObj.sortID = rgbSceneDict[@"`c_resIndex`"];
                                rgbSceneObj.level = @([rgbSceneDict[@"`c_bright`"] integerValue]/100.0*255);
                                rgbSceneObj.colorSat = @([rgbSceneDict[@"`c_color_sta`"] integerValue]/100.0);
                                NSInteger resIndex = [rgbSceneDict[@"`c_resIndex`"] integerValue];
                                if (resIndex>=0 && resIndex<=8) {
                                    rgbSceneObj.eventType = @0;
                                    rgbSceneObj.hueA = @([rgbSceneDict[@"`c_color`"] integerValue]/360.0);
                                }else {
                                    rgbSceneObj.eventType = @1;
                                    if (rgbSceneDict[@"`c_color_array`"]) {
                                        
                                        NSArray *ary = [rgbSceneDict[@"`c_color_array`"] componentsSeparatedByString:@","];
                                        
                                        rgbSceneObj.hueA = [self hueWithHex:(NSNumber *)ary[0]];
                                        rgbSceneObj.hueB = [self hueWithHex:(NSNumber *)ary[1]];
                                        rgbSceneObj.hueC = [self hueWithHex:(NSNumber *)ary[2]];
                                        rgbSceneObj.hueD = [self hueWithHex:(NSNumber *)ary[3]];
                                        rgbSceneObj.hueE = [self hueWithHex:(NSNumber *)ary[4]];
                                        rgbSceneObj.hueF = [self hueWithHex:(NSNumber *)ary[5]];
                                    }
                                    rgbSceneObj.changeSpeed = @([rgbSceneDict[@"`c_speed`"] integerValue]/100 * 4.5 + 0.5);
                                }
                                [rgbScenes addObject:rgbSceneObj];
                            }
                        }
                    }
                    [deviceEntity addRgbScenes:[NSSet setWithArray:rgbScenes]];
                    
                    if ([CSRUtilities belongToRemote:deviceDict[@"`c_shortName`"]]
                        || [CSRUtilities belongToCWRemote:deviceDict[@"`c_shortName`"]]
                        || [CSRUtilities belongToRGBDevice:deviceDict[@"`c_shortName`"]]
                        || [CSRUtilities belongToRGBCWDevice:deviceDict[@"`c_shortName`"]]
                        /*|| [CSRUtilities belongToSceneRemote:deviceDict[@"`c_shortName`"]]*/) {
                        NSString *shortname = deviceDict[@"`c_shortName`"];
                        if ([shortname isEqualToString:@"RB01"]
                            || [shortname isEqualToString:@"RB05"]
                            || [CSRUtilities belongToCWRemote:deviceDict[@"`c_shortName`"]]
                            || [CSRUtilities belongToRGBDevice:deviceDict[@"`c_shortName`"]]
                            || [CSRUtilities belongToRGBCWDevice:deviceDict[@"`c_shortName`"]]) {
                            
                            NSInteger t1 = [deviceDict[@"`c_deviceType1`"] integerValue];
                            NSInteger i1 = [deviceDict[@"`c_deviceid_1`"] integerValue];
                            NSString *s1 = [self type:t1 deviceID:i1];
                            NSInteger t2 = [deviceDict[@"`c_deviceType2`"] integerValue];
                            NSInteger i2 = [deviceDict[@"`c_deviceid_2`"] integerValue];
                            NSString *s2 = [self type:t2 deviceID:i2];
                            NSInteger t3 = [deviceDict[@"`c_deviceType3`"] integerValue];
                            NSInteger i3 = [deviceDict[@"`c_deviceid_3`"] integerValue];
                            NSString *s3 = [self type:t3 deviceID:i3];
                            NSInteger t4 = [deviceDict[@"`c_deviceType4`"] integerValue];
                            NSInteger i4 = [deviceDict[@"`c_deviceid_4`"] integerValue];
                            NSString *s4 = [self type:t4 deviceID:i4];
                            deviceEntity.remoteBranch = [NSString stringWithFormat:@"9b150401%@02%@03%@04%@",s1,s2,s3,s4];
                            
                        }else if ([shortname isEqualToString:@"RB02"]
                                  ||[shortname isEqualToString:@"RB06"]
                                  ||[shortname isEqualToString:@"RSBH"]
                                  ||[shortname isEqualToString:@"1BMBH"]) {
                            
                            NSInteger t1 = [deviceDict[@"`c_deviceType1`"] integerValue];
                            NSInteger i1 = [deviceDict[@"`c_deviceid_1`"] integerValue];
                            NSString *s1 = [self type:t1 deviceID:i1];
                            deviceEntity.remoteBranch = [NSString stringWithFormat:@"9b060101%@",s1];
                            
                        }else if ([shortname isEqualToString:@"RB04"]
                                  || [shortname isEqualToString:@"RSIBH"]
                                  || [shortname isEqualToString:@"S10IB-H2"]
                                  || [shortname isEqualToString:@"RB07"]) {
                            
                            NSInteger t1 = [deviceDict[@"`c_deviceType1`"] integerValue];
                            NSInteger i1 = [deviceDict[@"`c_deviceid_1`"] integerValue];
                            NSString *s1 = [self type:t1 deviceID:i1];
                            NSInteger t2 = [deviceDict[@"`c_deviceType2`"] integerValue];
                            NSInteger i2 = [deviceDict[@"`c_deviceid_2`"] integerValue];
                            NSString *s2 = [self type:t2 deviceID:i2];
                            deviceEntity.remoteBranch = [NSString stringWithFormat:@"9b0b0201%@02%@",s1,s2];
                            
                        }else if ([shortname isEqualToString:@"R5BSBH"]
                                  || [shortname isEqualToString:@"RB09"]
                                  || [shortname isEqualToString:@"5RSIBH"]
                                  || [shortname isEqualToString:@"5BCBH"]) {
                            
                            NSInteger t1 = [deviceDict[@"`c_deviceType1`"] integerValue];
                            NSInteger i1 = [deviceDict[@"`c_deviceid_1`"] integerValue];
                            NSString *s1 = [self type:t1 deviceID:i1];
                            NSInteger t2 = [deviceDict[@"`c_deviceType2`"] integerValue];
                            NSInteger i2 = [deviceDict[@"`c_deviceid_2`"] integerValue];
                            NSString *s2 = [self type:t2 deviceID:i2];
                            NSInteger t3 = [deviceDict[@"`c_deviceType3`"] integerValue];
                            NSInteger i3 = [deviceDict[@"`c_deviceid_3`"] integerValue];
                            NSString *s3 = [self type:t3 deviceID:i3];
                            NSInteger t4 = [deviceDict[@"`c_deviceType4`"] integerValue];
                            NSInteger i4 = [deviceDict[@"`c_deviceid_4`"] integerValue];
                            NSString *s4 = [self type:t4 deviceID:i4];
                            NSInteger t5 = [deviceDict[@"`c_deviceType5`"] integerValue];
                            NSInteger i5 = [deviceDict[@"`c_deviceid_5`"] integerValue];
                            NSString *s5 = [self type:t5 deviceID:i5];
                            deviceEntity.remoteBranch = [NSString stringWithFormat:@"9b1a0501%@02%@03%@04%@05%@",s1,s2,s3,s4,s5];
                            
                        }else if ([shortname isEqualToString:@"6RSIBH"]
                                  /*|| [CSRUtilities belongToSceneRemote:deviceDict[@"`c_shortName`"]]*/) {
                            
                            NSInteger t1 = [deviceDict[@"`c_deviceType1`"] integerValue];
                            NSInteger i1 = [deviceDict[@"`c_deviceid_1`"] integerValue];
                            NSString *s1 = [self type:t1 deviceID:i1];
                            NSInteger t2 = [deviceDict[@"`c_deviceType2`"] integerValue];
                            NSInteger i2 = [deviceDict[@"`c_deviceid_2`"] integerValue];
                            NSString *s2 = [self type:t2 deviceID:i2];
                            NSInteger t3 = [deviceDict[@"`c_deviceType3`"] integerValue];
                            NSInteger i3 = [deviceDict[@"`c_deviceid_3`"] integerValue];
                            NSString *s3 = [self type:t3 deviceID:i3];
                            NSInteger t4 = [deviceDict[@"`c_deviceType4`"] integerValue];
                            NSInteger i4 = [deviceDict[@"`c_deviceid_4`"] integerValue];
                            NSString *s4 = [self type:t4 deviceID:i4];
                            NSInteger t5 = [deviceDict[@"`c_deviceType5`"] integerValue];
                            NSInteger i5 = [deviceDict[@"`c_deviceid_5`"] integerValue];
                            NSString *s5 = [self type:t5 deviceID:i5];
                            NSInteger t6 = [deviceDict[@"`c_deviceType6`"] integerValue];
                            NSInteger i6 = [deviceDict[@"`c_deviceid_6`"] integerValue];
                            NSString *s6 = [self type:t6 deviceID:i6];
                            deviceEntity.remoteBranch = [NSString stringWithFormat:@"9b1a0501%@02%@03%@04%@05%@06%@",s1,s2,s3,s4,s5,s6];
                            
                        }
                    }
                    
                    if (self.sharePlace) {
                        [self.sharePlace addDevicesObject:deviceEntity];
                    }
                }
            }
            [[CSRDatabaseManager sharedInstance] loadDatabase];
        }
        if (parsingDictionary[@"KEY_SCENE_LIST"]) {
            for (NSDictionary * sceneDict in parsingDictionary[@"KEY_SCENE_LIST"]) {
                SceneEntity *sceneObj = [NSEntityDescription insertNewObjectForEntityForName:@"SceneEntity" inManagedObjectContext:managedObjectContext];
                if (![sceneDict[@"`c_isCustom`"] boolValue]) {
                    if ([sceneDict[@"`c_resIndex`"] intValue] == 0) {
                        sceneObj.sceneID = @0;
                    }else if ([sceneDict[@"`c_resIndex`"] intValue] == 1) {
                        sceneObj.sceneID = @1;
                    }else {
                        sceneObj.sceneID = sceneDict[@"`_id`"];
                    }
                }else {
                    sceneObj.sceneID = sceneDict[@"`_id`"];
                }
                sceneObj.iconID = sceneDict[@"`c_resIndex`"];
                sceneObj.sceneName = sceneDict[@"`c_name`"];
                sceneObj.rcIndex = sceneDict[@"`c_csrsceneid`"];
                sceneObj.enumMethod = @(NO);
                
                NSMutableArray *members = [NSMutableArray new];
                if (parsingDictionary[@"KEY_PARENTDEVICE_LIST"]) {
                    for (NSDictionary *parentDict in parsingDictionary[@"KEY_PARENTDEVICE_LIST"]) {
                        NSNumber *parentType = (NSNumber *)parentDict[@"`c_parent_type`"];
                        NSNumber *parentId = (NSNumber *)parentDict[@"`c_parent_id`"];
                        if ([parentType isEqualToNumber:@(1)] && [parentId isEqualToNumber:(NSNumber *)sceneDict[@"`_id`"]]) {
                            if (parsingDictionary[@"KEY_DEVICES_LIST"]) {
                                for (NSDictionary * deviceDict in parsingDictionary[@"KEY_DEVICES_LIST"]) {
                                    if ([(NSNumber *)deviceDict[@"`_id`"] isEqualToNumber:(NSNumber *)parentDict[@"`c_device_id`"]]) {
                                        if ([CSRUtilities belongToSwitch:deviceDict[@"`c_shortName`"]]) {
                                            SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                            if (![parentDict[@"`c_bOnOff`"] boolValue]) {
                                                sceneMemberObj.eveType = @(17);
                                            }else {
                                                sceneMemberObj.eveType = @(16);
                                            }
                                            [members addObject:sceneMemberObj];
                                        }else if ([CSRUtilities belongToTwoChannelSwitch:deviceDict[@"`c_shortName`"]]) {
                                            if ([parentDict[@"`c_channel`"] integerValue] == 3) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                                if (![parentDict[@"`c_chanel1_onoff`"] boolValue]) {
                                                    sceneMemberObj.eveType = @(17);
                                                }else {
                                                    sceneMemberObj.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj];
                                                
                                                SceneMemberEntity *sceneMemberObj1 = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@2];
                                                if (![parentDict[@"`c_chanel2_onoff`"] boolValue]) {
                                                    sceneMemberObj.eveType = @(17);
                                                }else {
                                                    sceneMemberObj.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj1];
                                            }else if ([parentDict[@"`c_channel`"] integerValue] == 1) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                                if (![parentDict[@"`c_chanel1_onoff`"] boolValue]) {
                                                    sceneMemberObj.eveType = @(17);
                                                }else {
                                                    sceneMemberObj.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj];
                                            }else if ([parentDict[@"`c_channel`"] integerValue] == 2) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@2];
                                                if (![parentDict[@"`c_chanel2_onoff`"] boolValue]) {
                                                    sceneMemberObj.eveType = @(17);
                                                }else {
                                                    sceneMemberObj.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj];
                                            }
                                        }else if ([CSRUtilities belongToThreeChannelSwitch:deviceDict[@"`c_shortName`"]]) {
                                            if ([parentDict[@"`c_channel`"] integerValue] == 1) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                                if (![parentDict[@"`c_chanel1_onoff`"] boolValue]) {
                                                    sceneMemberObj.eveType = @(17);
                                                }else {
                                                    sceneMemberObj.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj];
                                            }else if ([parentDict[@"`c_channel`"] integerValue] == 2) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@2];
                                                if (![parentDict[@"`c_chanel2_onoff`"] boolValue]) {
                                                    sceneMemberObj.eveType = @(17);
                                                }else {
                                                    sceneMemberObj.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj];
                                            }else if ([parentDict[@"`c_channel`"] integerValue] == 4) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@4];
                                                if (![parentDict[@"`c_chanel3_onoff`"] boolValue]) {
                                                    sceneMemberObj.eveType = @(17);
                                                }else {
                                                    sceneMemberObj.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj];
                                            }else if ([parentDict[@"`c_channel`"] integerValue] == 3) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                                if (![parentDict[@"`c_chanel1_onoff`"] boolValue]) {
                                                    sceneMemberObj.eveType = @(17);
                                                }else {
                                                    sceneMemberObj.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj];
                                                
                                                SceneMemberEntity *sceneMemberObj2 = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@2];
                                                if (![parentDict[@"`c_chanel2_onoff`"] boolValue]) {
                                                    sceneMemberObj2.eveType = @(17);
                                                }else {
                                                    sceneMemberObj2.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj2];
                                            }else if ([parentDict[@"`c_channel`"] integerValue] == 5) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                                if (![parentDict[@"`c_chanel1_onoff`"] boolValue]) {
                                                    sceneMemberObj.eveType = @(17);
                                                }else {
                                                    sceneMemberObj.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj];
                                                
                                                SceneMemberEntity *sceneMemberObj3 = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@4];
                                                if (![parentDict[@"`c_chanel3_onoff`"] boolValue]) {
                                                    sceneMemberObj3.eveType = @(17);
                                                }else {
                                                    sceneMemberObj3.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj3];
                                            }else if ([parentDict[@"`c_channel`"] integerValue] == 6) {
                                                SceneMemberEntity *sceneMemberObj2 = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@2];
                                                if (![parentDict[@"`c_chanel2_onoff`"] boolValue]) {
                                                    sceneMemberObj2.eveType = @(17);
                                                }else {
                                                    sceneMemberObj2.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj2];
                                                
                                                SceneMemberEntity *sceneMemberObj3 = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@4];
                                                if (![parentDict[@"`c_chanel3_onoff`"] boolValue]) {
                                                    sceneMemberObj3.eveType = @(17);
                                                }else {
                                                    sceneMemberObj3.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj3];
                                            }else if ([parentDict[@"`c_channel`"] integerValue] == 7) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                                if (![parentDict[@"`c_chanel1_onoff`"] boolValue]) {
                                                    sceneMemberObj.eveType = @(17);
                                                }else {
                                                    sceneMemberObj.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj];
                                                
                                                SceneMemberEntity *sceneMemberObj2 = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@2];
                                                if (![parentDict[@"`c_chanel2_onoff`"] boolValue]) {
                                                    sceneMemberObj2.eveType = @(17);
                                                }else {
                                                    sceneMemberObj2.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj2];
                                                
                                                SceneMemberEntity *sceneMemberObj3 = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@4];
                                                if (![parentDict[@"`c_chanel3_onoff`"] boolValue]) {
                                                    sceneMemberObj3.eveType = @(17);
                                                }else {
                                                    sceneMemberObj3.eveType = @(16);
                                                }
                                                [members addObject:sceneMemberObj3];
                                            }
                                        }else if ([CSRUtilities belongToDimmer:deviceDict[@"`c_shortName`"]]) {
                                            SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                            if (![parentDict[@"`c_bOnOff`"] boolValue]) {
                                                sceneMemberObj.eveType = @(17);
                                            }else {
                                                sceneMemberObj.eveType = @(18);
                                                sceneMemberObj.eveD0 = @([parentDict[@"`c_bright`"] integerValue] * 2.55);
                                            }
                                            [members addObject:sceneMemberObj];
                                        }else if ([CSRUtilities belongToTwoChannelDimmer:deviceDict[@"`c_shortName`"]]) {
                                            if ([parentDict[@"`c_channel`"] integerValue] == 1) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                                if (![parentDict[@"`c_chanel1_onoff`"] boolValue]) {
                                                    sceneMemberObj.eveType = @(17);
                                                }else {
                                                    sceneMemberObj.eveType = @(18);
                                                    sceneMemberObj.eveD0 = @([parentDict[@"`c_bright`"] integerValue] * 2.55);
                                                }
                                                [members addObject:sceneMemberObj];
                                            }else if ([parentDict[@"`c_channel`"] integerValue] == 2) {
                                                SceneMemberEntity *sceneMemberObj2 = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                                if (![parentDict[@"`c_chanel2_onoff`"] boolValue]) {
                                                    sceneMemberObj2.eveType = @(17);
                                                }else {
                                                    sceneMemberObj2.eveType = @(18);
                                                    sceneMemberObj2.eveD0 = @([parentDict[@"`c_chanel2_bright`"] integerValue] * 2.55);
                                                }
                                                [members addObject:sceneMemberObj2];
                                            }else if ([parentDict[@"`c_channel`"] integerValue] == 4) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                                if (![parentDict[@"`c_chanel1_onoff`"] boolValue]) {
                                                    sceneMemberObj.eveType = @(17);
                                                }else {
                                                    sceneMemberObj.eveType = @(18);
                                                    sceneMemberObj.eveD0 = @([parentDict[@"`c_bright`"] integerValue] * 2.55);
                                                }
                                                [members addObject:sceneMemberObj];
                                                
                                                SceneMemberEntity *sceneMemberObj2 = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                                if (![parentDict[@"`c_chanel2_onoff`"] boolValue]) {
                                                    sceneMemberObj2.eveType = @(17);
                                                }else {
                                                    sceneMemberObj2.eveType = @(18);
                                                    sceneMemberObj2.eveD0 = @([parentDict[@"`c_chanel2_bright`"] integerValue] * 2.55);
                                                }
                                                [members addObject:sceneMemberObj2];
                                            }
                                        }else if ([CSRUtilities belongToCWDevice:deviceDict[@"`c_shortName`"]]) {
                                            SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                            if (![parentDict[@"`c_bOnOff`"] boolValue]) {
                                                sceneMemberObj.eveType = @(17);
                                            }else {
                                                sceneMemberObj.eveType = @(25);
                                                sceneMemberObj.eveD0 = @([parentDict[@"`c_bright`"] integerValue] * 2.55);
                                                NSString *t = [CSRUtilities stringWithHexNumber:[parentDict[@"`c_cw_color_temp`"] integerValue]];
                                                NSString *t1 = [t substringToIndex:2];
                                                NSString *t2 = [t substringFromIndex:2];
                                                sceneMemberObj.eveD1 = @([CSRUtilities numberWithHexString:t1]);
                                                sceneMemberObj.eveD2 = @([CSRUtilities numberWithHexString:t2]);
                                            }
                                            [members addObject:sceneMemberObj];
                                        }else if ([CSRUtilities belongToRGBDevice:deviceDict[@"`c_shortName`"]]) {
                                            SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                            if (![parentDict[@"`c_bOnOff`"] boolValue]) {
                                                sceneMemberObj.eveType = @(17);
                                            }else {
                                                sceneMemberObj.eveType = @(20);
                                                sceneMemberObj.eveD0 = @([parentDict[@"`c_bright`"] integerValue] * 2.55);
                                                NSInteger rgbValue = [parentDict[@"`c_rgb_color`"] integerValue];
                                                sceneMemberObj.eveD1 = @((rgbValue & 0xFF0000) >> 16);
                                                sceneMemberObj.eveD2 = @((rgbValue & 0x00FF00) >> 8);
                                                sceneMemberObj.eveD3 = @(rgbValue & 0x0000FF);
                                            }
                                            [members addObject:sceneMemberObj];
                                        }else if ([CSRUtilities belongToRGBCWDevice:deviceDict[@"`c_shortName`"]]) {
                                            SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                            if (![parentDict[@"`c_bOnOff`"] boolValue]) {
                                                sceneMemberObj.eveType = @(17);
                                            }else {
                                                if (![parentDict[@"`c_support`"] boolValue]) {
                                                    sceneMemberObj.eveType = @(20);
                                                    sceneMemberObj.eveD0 = @([parentDict[@"`c_bright`"] integerValue] * 2.55);
                                                    NSInteger rgbValue = [parentDict[@"`c_rgb_color`"] integerValue];
                                                    sceneMemberObj.eveD1 = @((rgbValue & 0xFF0000) >> 16);
                                                    sceneMemberObj.eveD2 = @((rgbValue & 0x00FF00) >> 8);
                                                    sceneMemberObj.eveD3 = @(rgbValue & 0x0000FF);
                                                }else {
                                                    sceneMemberObj.eveType = @(25);
                                                    sceneMemberObj.eveD0 = @([parentDict[@"`c_bright`"] integerValue] * 2.55);
                                                    NSString *t = [CSRUtilities stringWithHexNumber:[parentDict[@"`c_cw_color_temp`"] integerValue]];
                                                    NSString *t1 = [t substringToIndex:2];
                                                    NSString *t2 = [t substringFromIndex:2];
                                                    sceneMemberObj.eveD1 = @([CSRUtilities numberWithHexString:t1]);
                                                    sceneMemberObj.eveD2 = @([CSRUtilities numberWithHexString:t2]);
                                                }
                                            }
                                            [members addObject:sceneMemberObj];
                                        }else if ([CSRUtilities belongToSocketOneChannel:deviceDict[@"`c_shortName`"]]) {
                                            SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                            sceneMemberObj.eveType = @(29);
                                            sceneMemberObj.eveD0 = @([parentDict[@"`c_bOnOff`"] boolValue]);
                                            sceneMemberObj.eveD1 = @([parentDict[@"`c_children_mode1`"] boolValue]);
                                            [members addObject:sceneMemberObj];
                                        }else if ([CSRUtilities belongToSocketTwoChannel:deviceDict[@"`c_shortName`"]]) {
                                            if ([parentDict[@"`c_channel`"] integerValue] == 3) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                                sceneMemberObj.eveType = @(29);
                                                sceneMemberObj.eveD0 = @([parentDict[@"`c_chanel1_onoff`"] boolValue]);
                                                sceneMemberObj.eveD1 = @([parentDict[@"`c_children_mode1`"] boolValue]);
                                                [members addObject:sceneMemberObj];
                                                
                                                SceneMemberEntity *sceneMemberObj2 = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@2];
                                                sceneMemberObj2.eveType = @(29);
                                                sceneMemberObj2.eveD0 = @([parentDict[@"`c_chanel12onoff`"] boolValue]);
                                                sceneMemberObj2.eveD1 = @([parentDict[@"`c_children_mode2`"] boolValue]);
                                                [members addObject:sceneMemberObj2];
                                            }else if ([parentDict[@"`c_channel`"] integerValue] == 1) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                                sceneMemberObj.eveType = @(29);
                                                sceneMemberObj.eveD0 = @([parentDict[@"`c_chanel1_onoff`"] boolValue]);
                                                sceneMemberObj.eveD1 = @([parentDict[@"`c_children_mode1`"] boolValue]);
                                                [members addObject:sceneMemberObj];
                                            }else if ([parentDict[@"`c_channel`"] integerValue] == 2) {
                                                SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@2];
                                                sceneMemberObj.eveType = @(29);
                                                sceneMemberObj.eveD0 = @([parentDict[@"`c_chanel2_onoff`"] boolValue]);
                                                sceneMemberObj.eveD1 = @([parentDict[@"`c_children_mode2`"] boolValue]);
                                                [members addObject:sceneMemberObj];
                                            }
                                        }else if ([CSRUtilities belongToOneChannelCurtainController:deviceDict[@"`c_shortName`"]]) {
                                            SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                            if (![parentDict[@"`c_bOnOff`"] boolValue]) {
                                                sceneMemberObj.eveType = @(17);
                                            }else {
                                                sceneMemberObj.eveType = @(18);
                                                sceneMemberObj.eveD0 = @([parentDict[@"`c_bright`"] integerValue] * 2.55);
                                            }
                                            [members addObject:sceneMemberObj];
                                        }else if ([CSRUtilities belongToTwoChannelCurtainController:deviceDict[@"`c_shortName`"]]) {
                                            SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                            if (![parentDict[@"`c_chanel1_onoff`"] boolValue]) {
                                                sceneMemberObj.eveType = @(17);
                                            }else {
                                                sceneMemberObj.eveType = @(18);
                                                sceneMemberObj.eveD0 = @([parentDict[@"`c_bright`"] integerValue] * 2.55);
                                            }
                                            [members addObject:sceneMemberObj];
                                            
                                            SceneMemberEntity *sceneMemberObj2 = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@2];
                                            if (![parentDict[@"`c_chanel2_onoff`"] boolValue]) {
                                                sceneMemberObj2.eveType = @(17);
                                            }else {
                                                sceneMemberObj2.eveType = @(18);
                                                sceneMemberObj2.eveD0 = @([parentDict[@"`c_chanel2_onoff`"] integerValue] * 2.55);
                                            }
                                            [members addObject:sceneMemberObj];
                                        }else if ([CSRUtilities belongToFanController:deviceDict[@"`c_shortName`"]]) {
                                            SceneMemberEntity *sceneMemberObj = [self creatSceneMemberObj:sceneDict[@"`_id`"] parentDict:parentDict deviceDic:deviceDict channel:@1];
                                            sceneMemberObj.eveType = @32;
                                            sceneMemberObj.eveD0 = @([parentDict[@"`c_fanbOnOff`"] boolValue]);
                                            sceneMemberObj.eveD1 = @([parentDict[@"`c_fan_speed`"] integerValue]);
                                            sceneMemberObj.eveD2 = @([parentDict[@"`c_bOnOff`"] boolValue]);
                                            [members addObject:sceneMemberObj];
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                [sceneObj addMembers:[NSSet setWithArray:members]];
                if (self.sharePlace) {
                    [self.sharePlace addScenesObject:sceneObj];
                }
            }
        }
        
        if (parsingDictionary[@"KEY_GALLERY_LIST"]) {
            for (NSDictionary *galleryDict in parsingDictionary[@"KEY_GALLERY_LIST"]) {
                GalleryEntity *galleryObj = [NSEntityDescription insertNewObjectForEntityForName:@"GalleryEntity" inManagedObjectContext:managedObjectContext];
                
                galleryObj.galleryID = galleryDict[@"`_id`"];
                galleryObj.boundWidth = galleryDict[@"`c_widthrate`"];
                galleryObj.boundHeight = galleryDict[@"`c_heightrate`"];
                galleryObj.sortId = galleryDict[@"`c_orderIndex`"];
                NSString *imageStr = galleryDict[@"`c_imagePath`"];
                if ([imageStr length]>0) {
                    galleryObj.galleryImage = [files objectAtIndex:1];;
                    [files removeObjectAtIndex:1];
                }
                
                NSMutableArray *drops = [NSMutableArray new];
                if (parsingDictionary[@"KEY_PARENTDEVICE_LIST"]) {
                    for (NSDictionary *parentDict in parsingDictionary[@"KEY_PARENTDEVICE_LIST"]) {
                        NSNumber *parentType = (NSNumber *)parentDict[@"`c_parent_type`"];
                        NSNumber *parentId = (NSNumber *)parentDict[@"`c_parent_id`"];
                        if ([parentType isEqualToNumber:@(3)] && [parentId isEqualToNumber:(NSNumber *)galleryDict[@"`_id`"]]) {
                            if (parsingDictionary[@"KEY_DEVICES_LIST"]) {
                                for (NSDictionary * deviceDict in parsingDictionary[@"KEY_DEVICES_LIST"]) {
                                    if ([(NSNumber *)deviceDict[@"`_id`"] isEqualToNumber:(NSNumber *)parentDict[@"`c_device_id`"]]) {
                                        DropEntity *dropObj = [NSEntityDescription insertNewObjectForEntityForName:@"DropEntity" inManagedObjectContext:managedObjectContext];
                                        dropObj.galleryID = galleryDict[@"`_id`"];;
                                        dropObj.dropID = deviceDict[@"`_id`"];
                                        dropObj.boundRatio = parentDict[@"`c_sizerate`"];
                                        CGFloat y = [parentDict[@"`c_toprate`"] floatValue] + [parentDict[@"`c_sizerate`"] floatValue]*0.5;
                                        dropObj.centerYRatio = @(y);
                                        CGFloat x = [parentDict[@"`c_leftrate`"] floatValue] + [parentDict[@"`c_sizerate`"] floatValue]*0.5;
                                        dropObj.centerXRatio = @(x);
                                        dropObj.deviceID = deviceDict[@"`c_csr_deviceId`"];
                                        dropObj.kindName = deviceDict[@"`c_shortName`"];
                                        [drops addObject:dropObj];
                                    }
                                }
                            }
                        }
                    }
                }
                [galleryObj addDrops:[NSSet setWithArray:drops]];
                if (self.sharePlace) {
                    [self.sharePlace addGallerysObject:galleryObj];
                }
            }
        }
        
        if (parsingDictionary[@"KEY_TIMER_LIST"]) {
            for (NSDictionary *timerDict in parsingDictionary[@"KEY_TIMER_LIST"]) {
                TimerEntity *timerObj = [NSEntityDescription insertNewObjectForEntityForName:@"TimerEntity" inManagedObjectContext:managedObjectContext];
                timerObj.timerID = timerDict[@"`_id`"];
                timerObj.name = timerDict[@"`c_name`"];
                timerObj.enabled = timerDict[@"`c_enabled`"];
                if (timerDict[@"`c_repeat`"]) {
                    NSString *s = [timerDict[@"`c_repeat`"] lowercaseString];
                    timerObj.repeat = [NSString stringWithFormat:@"%@%@",[CSRUtilities getBinaryByhex:[s substringToIndex:1]], [CSRUtilities getBinaryByhex:[s substringFromIndex:1]]];
                }
                NSDateFormatter *matter = [[NSDateFormatter alloc] init];
                matter.dateFormat = @"YYYYMMddHHmmss";
                NSString *M = [NSString stringWithFormat:@"%@",timerDict[@"`c_month`"]];
                if ([M length]<2) {
                    M = [NSString stringWithFormat:@"0%@",M];
                }
                NSString *d = [NSString stringWithFormat:@"%@",timerDict[@"`c_day`"]];
                if ([d length]<2) {
                    d = [NSString stringWithFormat:@"0%@",d];
                }
                NSString *h = [NSString stringWithFormat:@"%@",timerDict[@"`c_hour`"]];
                if ([h length]<2) {
                    h = [NSString stringWithFormat:@"0%@",h];
                }
                NSString *m = [NSString stringWithFormat:@"%@",timerDict[@"`c_minute`"]];
                if ([m length]<2) {
                    m = [NSString stringWithFormat:@"0%@",m];
                }
                NSString *t = [NSString stringWithFormat:@"%@%@%@%@%@00", timerDict[@"`c_year`"], M, d, h, m];
                timerObj.fireTime = [matter dateFromString:t];
                timerObj.fireDate = [matter dateFromString:t];
                timerObj.sceneID = timerDict[@"`c_sceneid`"];
                if (parsingDictionary[@"KEY_SCENE_LIST"]) {
                    for (NSDictionary * sceneDict in parsingDictionary[@"KEY_SCENE_LIST"]) {
                        if (![sceneDict[@"`c_isCustom`"] boolValue]) {
                            if ([sceneDict[@"`c_resIndex`"] intValue] == 0) {
                                if ([timerDict[@"`c_sceneid`"] intValue] == [sceneDict[@"`_id`"] intValue]) {
                                    timerObj.sceneID = @0;
                                }
                            }else if ([sceneDict[@"`c_resIndex`"] intValue] == 1) {
                                if ([timerDict[@"`c_sceneid`"] intValue] == [sceneDict[@"`_id`"] intValue]) {
                                    timerObj.sceneID = @1;
                                }
                            }
                        }
                    }
                }
                NSMutableArray *tds = [NSMutableArray new];
                if (timerDict[@"KEY_DEVICETIMER_LIST"]) {
                    for (NSDictionary *timerDeviceDict in timerDict[@"KEY_DEVICETIMER_LIST"]) {
                        TimerDeviceEntity *timerDeviceObj = [NSEntityDescription insertNewObjectForEntityForName:@"TimerDeviceEntity" inManagedObjectContext:managedObjectContext];
                        timerDeviceObj.timerID = timerDeviceDict[@"`c_timer_id`"];
                        timerDeviceObj.deviceID = timerDeviceDict[@"`c_csrdevice_id`"];
                        timerDeviceObj.channel = [timerDeviceDict[@"`c_channel`"] length]>0 ? @([timerDeviceDict[@"`c_channel`"] integerValue]):@(1);
                        timerDeviceObj.timerIndex = @([timerDeviceDict[@"`c_device_timer_id`"] integerValue]);
                        [tds addObject:timerDeviceObj];
                    }
                }
                [timerObj addTimerDevices:[NSSet setWithArray:tds]];
                if (self.sharePlace) {
                    [self.sharePlace addTimersObject:timerObj];
                }
                
            }
        }
        
        [[CSRDatabaseManager sharedInstance] saveContext];
    }
    
    return self.sharePlace;
}

- (NSNumber *)hueWithHex:(NSNumber *)hex {
    UIColor *color = [CSRUtilities colorFromRGB:[hex integerValue]];
    CGFloat hue,saturation,brightness,alpha;
    if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        return [NSNumber numberWithFloat:hue];
    }
    return nil;
}

- (NSString *)type:(NSInteger)t deviceID:(NSInteger)deviceId {
    NSString *s = @"";
    if (t == 0) {
        s = [NSString stringWithFormat:@"0100%@",[CSRUtilities exchangePositionOfDeviceId:deviceId]];
    }else if (t == 1) {
        s = [NSString stringWithFormat:@"2000%@",[CSRUtilities exchangePositionOfDeviceId:deviceId]];
    }else if (t == 2) {
        s = [NSString stringWithFormat:@"%@0000",[CSRUtilities exchangePositionOfDeviceId:deviceId]];
    }
    return s;
}

- (SceneMemberEntity *)creatSceneMemberObj:(NSNumber *)sceneID parentDict:(NSDictionary *)parentDict deviceDic:(NSDictionary *)deviceDict channel:(NSNumber *)channel {
    SceneMemberEntity *sceneMemberObj = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:managedObjectContext];
    sceneMemberObj.sceneID = sceneID;
    sceneMemberObj.deviceID = deviceDict[@"`c_csr_deviceId`"];
    sceneMemberObj.kindString = deviceDict[@"`c_shortName`"];
    sceneMemberObj.channel = channel;
    sceneMemberObj.eveD0 = @0;
    sceneMemberObj.eveD1 = @0;
    sceneMemberObj.eveD2 = @0;
    sceneMemberObj.eveD3 = @0;
    return sceneMemberObj;
}

@end
