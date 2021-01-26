//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import "CSRmeshManager.h"
#import "CSRConstants.h"
#import "CSRDevicesManager.h"
#import "CSRDeviceEntity.h"
#import "CSRGatewayEntity.h"
#import "CSRDatabaseManager.h"
#import "CSRAppStateManager.h"
#import "CSRmeshDevice.h"
#import "CSRUtilities.h"
#import "DataModelManager.h"
#import "RGBSceneEntity.h"

@implementation CSRmeshManager


+ (id) sharedInstance
{
    
    static dispatch_once_t token;
    static CSRmeshManager *shared = nil;
    
    dispatch_once(&token, ^{
        shared = [[CSRmeshManager alloc] init];
    });
    
    return shared;
}

- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)setUpDelegates
{
    [[MeshServiceApi sharedInstance] addDelegate:self];
    [[AttentionModelApi sharedInstance] addDelegate:self];
    [[BearerModelApi sharedInstance] addDelegate:self];
    [[ConfigModelApi sharedInstance] addDelegate:self];
    [[FirmwareModelApi sharedInstance] addDelegate:self];
    [[GroupModelApi sharedInstance] addDelegate:self];
    [[LightModelApi sharedInstance] addDelegate:self];
    [[PowerModelApi sharedInstance] addDelegate:self];
    [[DataModelApi sharedInstance] addDelegate:self];
    [[PingModelApi sharedInstance] addDelegate:self];
    [[BatteryModelApi sharedInstance] addDelegate:self];
    [[SensorModelApi sharedInstance] addDelegate:self];
    [[ActuatorModelApi sharedInstance] addDelegate:self];
}

-(void) setScannerEnabled:(NSNumber *)enabled {
    // Notify all listeners
    NSMutableDictionary *objects = [NSMutableDictionary dictionary];
    if (enabled)
        [objects setObject:enabled forKey:kScannerEnabledString];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRmeshManagerWillSetScannerEnabledNotification object:self userInfo:objects];
}


-(void) didDiscoverDevice:(CBUUID *)uuid rssi:(NSNumber *)rssi
{
    // Notify all listeners
    NSMutableDictionary *objects = [NSMutableDictionary dictionary];
    if (uuid)
        [objects setObject:uuid forKey:kDeviceUuidString];
    if (rssi)
        [objects setObject:rssi forKey:kDeviceRssiString];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRmeshManagerDidDiscoverDeviceNotification object:self userInfo:objects];
}


-(void) didUpdateAppearance:(NSData *)deviceHash appearanceValue:(NSNumber *)appearanceValue shortName:(NSData *)shortName
{
    // Notify all listeners
    NSMutableDictionary *objects = [NSMutableDictionary dictionary];
    if (deviceHash)
        [objects setObject:deviceHash forKey:kDeviceHashString];
    if (appearanceValue)
        [objects setObject:appearanceValue forKey:kAppearanceValueString];
    if (shortName)
        [objects setObject:shortName forKey:kShortNameString];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRmeshManagerDidUpdateAppearanceNotification object:self userInfo:objects];
}


-(void) isAssociatingDevice:(NSData *)deviceHash stepsCompleted:(NSNumber *)stepsCompleted totalSteps:(NSNumber *)totalSteps meshRequestId:(NSNumber *)meshRequestId {
    [[CSRDevicesManager sharedInstance] updateDeviceAssociationInfo:deviceHash withStepsCompleted:stepsCompleted ofTotalSteps:totalSteps];
    
    // Notify all listeners
    NSMutableDictionary *objects = [NSMutableDictionary dictionary];
    if (deviceHash)
        [objects setObject:deviceHash forKey:kDeviceHashString];
    if (stepsCompleted)
        [objects setObject:stepsCompleted forKey:kStepsCompletedString];
    if (totalSteps)
        [objects setObject:totalSteps forKey:kTotalStepsString];
    if (meshRequestId)
        [objects setObject:meshRequestId forKey:kMeshRequestIdString];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRmeshManagerIsAssociatingDeviceNotification object:self userInfo:objects];
    
}

-(void) didAssociateDevice:(NSNumber *)deviceId deviceHash:(NSData *)deviceHash dhmKey:(NSData*)dhmKey meshRequestId:(NSNumber *)meshRequestId
{
    
    CSRmeshDevice *meshDevice = [[CSRDevicesManager sharedInstance] didAssociateDevice:deviceId deviceHash:deviceHash];
    // Create hash from exisitng gateway
    __block BOOL isDeviceGateway = [CSRDevicesManager sharedInstance].isDeviceTypeGateway;
    
    if (!isDeviceGateway) {
        
        // Check if device already exists
        __block CSRDeviceEntity *deviceEntity = nil;
        
        [[CSRAppStateManager sharedInstance].selectedPlace.devices enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            CSRDeviceEntity *device = (CSRDeviceEntity *)obj;
            if ([device.deviceId isEqualToNumber:deviceId]) {
                
                deviceEntity = device;
                *stop = YES;
                
            }
            
        }];
        
        if (!deviceEntity && ![meshDevice.appearanceValue  isEqual:@(CSRApperanceNameController)]) {
            
            deviceEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRDeviceEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
            
        }else {
            
            if (deviceEntity.rgbScenes && [deviceEntity.rgbScenes count] > 0) {
                for (RGBSceneEntity *deleteRgbSceneEntity in deviceEntity.rgbScenes) {
                    [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:deleteRgbSceneEntity];
                }
            }
            if ([CSRUtilities belongToSonosMusicController:deviceEntity.shortName]) {
                [[CSRDatabaseManager sharedInstance] cleanSonos:deviceEntity.deviceId];
            }
            [[CSRDatabaseManager sharedInstance] dropEntityDeleteWhenDeleteDeviceEntity:deviceEntity.deviceId];
            [[CSRDatabaseManager sharedInstance] sceneMemberEntityDeleteWhenDeleteDeviceEntity:deviceEntity.deviceId];
            [[CSRDatabaseManager sharedInstance] timerDeviceEntityDeleteWhenDeleteDeviceEntity:deviceEntity.deviceId];
            NSData *groups = [CSRUtilities dataForHexString:deviceEntity.groups];
            uint16_t *dataToModify = (uint16_t*)groups.bytes;
            NSMutableArray *desiredGroups = [NSMutableArray new];
            for (int count=0; count < deviceEntity.groups.length/2; count++, dataToModify++) {
                NSNumber *groupValue = @(*dataToModify);
                [desiredGroups addObject:groupValue];
            }
            for (int i=0; i<[desiredGroups count]; i++) {
                NSNumber *areaValue = [desiredGroups objectAtIndex:i];
                CSRAreaEntity *areaEntity = [[[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"CSRAreaEntity" withPredicate:@"areaID == %@", areaValue] firstObject];
                if (areaEntity) {
                    [areaEntity removeDevicesObject:deviceEntity];
                }
                
                NSMutableData *myData = (NSMutableData*)[CSRUtilities dataForHexString:deviceEntity.groups];
                uint16_t *groups = (uint16_t *) myData.mutableBytes;
                *(groups + i) = 0;
                deviceEntity.groups = [CSRUtilities hexStringFromData:(NSData*)myData];
            }
        }
        
        if (deviceEntity) {
            
            deviceEntity.deviceId = deviceId;
            deviceEntity.isAssociated = @(YES);
            deviceEntity.deviceHash = deviceHash;
            deviceEntity.dhmKey = dhmKey;
            deviceEntity.remoteBranch = @"";
            deviceEntity.mcuSVersion = nil;
            if (meshDevice.appearanceValue) {
                deviceEntity.appearance = meshDevice.appearanceValue;
            }
            if (meshDevice.appearanceShortname) {
                NSString *shortName = [CSRUtilities stringFromData:meshDevice.appearanceShortname];
                deviceEntity.shortName = shortName;
                meshDevice.name = [NSString stringWithFormat:@"%@ %@", shortName, [CSRUtilities stringWithHexNumber:[deviceId integerValue]]];
                deviceEntity.name = shortName;
            }
            if (meshDevice.uuid) {
                deviceEntity.uuid = meshDevice.uuid.UUIDString;
            }
            NSNumber *sortId = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"SortId"];
            deviceEntity.sortId = sortId;
            
            if ([CSRUtilities belongToRGBDevice:deviceEntity.shortName]||[CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
                NSArray *names = kRGBSceneDefaultName;
                NSArray *levels = kRGBSceneDefaultLevel;
                NSArray *hues = kRGBSceneDefaultHue;
                NSArray *sats = kRGBSceneDefaultColorSat;
                for (int i = 0; i<12; i++) {
                    RGBSceneEntity *rgbScenetity = [NSEntityDescription insertNewObjectForEntityForName:@"RGBSceneEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                    rgbScenetity.deviceID = deviceId;
                    rgbScenetity.name = names[i];
                    rgbScenetity.isDefaultImg = @1;
                    rgbScenetity.rgbSceneID = @(i);
                    rgbScenetity.sortID = @(i);
                    
                    if (i<9) {
                        rgbScenetity.eventType = @(0);
                        rgbScenetity.hueA = hues[i];
                        rgbScenetity.level = levels[i];
                        rgbScenetity.colorSat = sats[i];
                    }else {
                        rgbScenetity.eventType = @(1);
                        rgbScenetity.changeSpeed = @(5);
                        NSArray *colorfulHues = hues[i];
                        rgbScenetity.hueA = colorfulHues[0];
                        rgbScenetity.hueB = colorfulHues[1];
                        rgbScenetity.hueC = colorfulHues[2];
                        rgbScenetity.hueD = colorfulHues[3];
                        rgbScenetity.hueE = colorfulHues[4];
                        rgbScenetity.hueF = colorfulHues[5];
                        rgbScenetity.level = @(255);
                        rgbScenetity.colorSat = @(1);
                    }
                    [deviceEntity addRgbScenesObject:rgbScenetity];
                }
            }else if ([CSRUtilities belongToSceneRemoteSixKeys:deviceEntity.shortName]
                      || [CSRUtilities belongToSceneRemoteFourKeys:deviceEntity.shortName]
                      || [CSRUtilities belongToSceneRemoteThreeKeys:deviceEntity.shortName]
                      || [CSRUtilities belongToSceneRemoteTwoKeys:deviceEntity.shortName]
                      || [CSRUtilities belongToSceneRemoteOneKey:deviceEntity.shortName]
                      || [CSRUtilities belongToSceneRemoteSixKeysV:deviceEntity.shortName]
                      || [CSRUtilities belongToSceneRemoteFourKeysV:deviceEntity.shortName]
                      || [CSRUtilities belongToSceneRemoteThreeKeysV:deviceEntity.shortName]
                      || [CSRUtilities belongToSceneRemoteTwoKeysV:deviceEntity.shortName]
                      || [CSRUtilities belongToSceneRemoteOneKeyV:deviceEntity.shortName]) {
                deviceEntity.keyNameOne = AcTECLocalizedStringFromTable(@"Scene1", @"Localizable");
                deviceEntity.keyNameTwo = AcTECLocalizedStringFromTable(@"Scene2", @"Localizable");
                deviceEntity.keyNameThree = AcTECLocalizedStringFromTable(@"Scene3", @"Localizable");
                deviceEntity.keyNameFour = AcTECLocalizedStringFromTable(@"Scene4", @"Localizable");
                deviceEntity.keyNameFive = AcTECLocalizedStringFromTable(@"Scene5", @"Localizable");
                deviceEntity.keyNameSix = AcTECLocalizedStringFromTable(@"Scene6", @"Localizable");
            }
 
            [[CSRAppStateManager sharedInstance].selectedPlace addDevicesObject:deviceEntity];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
        
        // request model info for this device.
        if (![meshDevice.appearanceValue  isEqual:@(CSRApperanceNameController)]) {
            [[CSRDevicesManager sharedInstance] getModelsAndGroupsCall:deviceId infoType:@(CSR_Model_low)];
            [NSThread sleepForTimeInterval:0.3];
            [[CSRDevicesManager sharedInstance] getModelsAndGroupsCall:deviceId infoType:@(CSR_Model_high)];
            [NSThread sleepForTimeInterval:0.3];
            if (meshDevice.appearanceValue == nil) {
                [[CSRDevicesManager sharedInstance] getModelsAndGroupsCall:deviceId infoType:@(CSR_Appearance)];
            }
        }
        
        // Notify all listeners
        NSMutableDictionary *objects = [NSMutableDictionary dictionary];
        if (deviceId)
            [objects setObject:deviceId forKey:kDeviceIdString];
        if (deviceHash)
            [objects setObject:deviceHash forKey:kDeviceHashString];
        if (meshRequestId)
            [objects setObject:meshRequestId forKey:kMeshRequestIdString];
        [[NSNotificationCenter defaultCenter] postNotificationName:kCSRmeshManagerDidAssociateDeviceNotification object:self userInfo:objects];
        
        NSMutableDictionary *deviceDictionary = [NSMutableDictionary new];
        
        if (deviceEntity.deviceId) {
            [deviceDictionary setValue:deviceEntity.deviceId forKey:kDEVICE_NUMBER];
        }
        
        if (deviceEntity.deviceHash) {
            [deviceDictionary setValue:deviceEntity.deviceHash forKey:kDEVICE_HASH];
        }
        
        if (deviceEntity.authCode) {
            [deviceDictionary setValue:deviceEntity.authCode forKey:kDEVICE_AUTH_CODE];
        }
        
        if (deviceEntity.name) {
            [deviceDictionary setValue:[NSString stringWithFormat:@"%@ (%04x)",[[NSString alloc] initWithData:meshDevice.appearanceShortname encoding:NSUTF8StringEncoding], [deviceId unsignedShortValue]] forKey:kDEVICE_NAME];
        }
        
        if (deviceEntity.isAssociated) {
            [deviceDictionary setValue:deviceEntity.isAssociated forKey:kDEVICE_ISASSOCIATED];
        }
        
        if (deviceEntity.dhmKey) {
            [deviceDictionary setValue:deviceEntity.dhmKey forKey:kDEVICE_DHM];
        }
        
        [[CSRDevicesManager sharedInstance] createDeviceFromProperties:deviceDictionary];
        
        [[DataModelManager shareInstance] setDeviceTime];
        
        if ([CSRUtilities belongToFadeDevice:deviceEntity.shortName]) {
            NSInteger s = 10;
            NSNumber *fadeTimeSwitch = [[NSUserDefaults standardUserDefaults] objectForKey:FadeTimeSwitch];
            if (fadeTimeSwitch) {
                s = [fadeTimeSwitch integerValue];
            }
            [NSThread sleepForTimeInterval:0.3];
            Byte sbyte[] = {0xea, 0x55, 0xff, s};
            NSData *scmd = [[NSData alloc] initWithBytes:sbyte length:4];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:deviceId data:scmd];
            
            NSInteger d = 30;
            NSNumber *fadeTimeDimming = [[NSUserDefaults standardUserDefaults] objectForKey:FadeTimeDimming];
            if (fadeTimeDimming) {
                d = [fadeTimeDimming integerValue];
            }
            [NSThread sleepForTimeInterval:0.3];
            Byte dbyte[] = {0xea, 0x57, 0xff, d};
            NSData *dcmd = [[NSData alloc] initWithBytes:dbyte length:4];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:deviceId data:dcmd];
        }
        
    } else {
        
        NSMutableDictionary *objects = [NSMutableDictionary dictionary];
        if (deviceId)
            [objects setObject:deviceId forKey:kDeviceIdString];
        if (deviceHash)
            [objects setObject:deviceHash forKey:kDeviceHashString];
        if (dhmKey)
            [objects setObject:dhmKey forKey:kDeviceDHMString];
        if (meshRequestId)
            [objects setObject:meshRequestId forKey:kMeshRequestIdString];
        [[NSNotificationCenter defaultCenter] postNotificationName:kCSRmeshManagerDidAssociateDeviceNotification object:self userInfo:objects];
        
    }
    
    [NSThread sleepForTimeInterval:1.0];
    [self getVersion:deviceId];
    
    
}

- (void)getVersion: (NSNumber *)deviceId {
    [[DataModelManager shareInstance] sendCmdData:@"880100" toDeviceId:deviceId];
    __weak CSRmeshManager *weakself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        static int i = 0;
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        if ([deviceEntity.cvVersion integerValue]==0) {
            if (i < 5) {
                i++;
                [weakself getVersion:deviceId];
            }
        }else if ([deviceEntity.hwVersion integerValue]== 2) {
            [weakself getMcuSVersion:deviceId];
        }
    });
}

- (void)getMcuSVersion: (NSNumber *)deviceId {
    [[DataModelManager shareInstance] sendCmdData:@"ea35" toDeviceId:deviceId];
    __weak CSRmeshManager *weakself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        static int i = 0;
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        if ([deviceEntity.mcuSVersion integerValue]==0) {
            if (i < 5) {
                i++;
                [weakself getMcuSVersion:deviceId];
            }else {
                [self sceneRemoteConfigureSceneIndex:deviceId];
            }
        }else {
            [self sceneRemoteConfigureSceneIndex:deviceId];
        }
    });
}

- (void)sceneRemoteConfigureSceneIndex:(NSNumber *)deviceID {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callbackOfRemoteConfigruation:)
                                                 name:@"CALLBACKOFREMOTECONFIGURATION"
                                               object:nil];
    applyDeviceID = deviceID;
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID];
    if ([CSRUtilities belongToSceneRemoteSixKeys:deviceEntity.shortName]
        || [CSRUtilities belongToSceneRemoteSixKeysV:deviceEntity.shortName]) {
        NSMutableArray *allIndexs = [[NSMutableArray alloc] initWithObjects:@(0), nil];
        for (SceneEntity *scene in [CSRAppStateManager sharedInstance].selectedPlace.scenes) {
            [allIndexs addObject:scene.rcIndex];
        }
        
        NSInteger index1 = 0;
        while ([allIndexs containsObject:@(index1)]) {
            index1 = arc4random()%65470+64;
        }
        [allIndexs addObject:@(index1)];
        NSInteger index2 = 0;
        while ([allIndexs containsObject:@(index2)]) {
            index2 = arc4random()%65470+64;
        }
        [allIndexs addObject:@(index2)];
        NSInteger index3 = 0;
        while ([allIndexs containsObject:@(index3)]) {
            index3 = arc4random()%65470+64;
        }
        [allIndexs addObject:@(index3)];
        NSInteger index4 = 0;
        while ([allIndexs containsObject:@(index4)]) {
            index4 = arc4random()%65470+64;
        }
        [allIndexs addObject:@(index4)];
        NSInteger index5 = 0;
        while ([allIndexs containsObject:@(index5)]) {
            index5 = arc4random()%65470+64;
        }
        [allIndexs addObject:@(index5)];
        NSInteger index6 = 0;
        while ([allIndexs containsObject:@(index6)]) {
            index6 = arc4random()%65470+64;
        }
        [self performSelector:@selector(configureSceneRemoteTimeOut) withObject:nil afterDelay:15.0f];
        retryCount = 0;
        Byte byte[] = {0x9b, 0x1f, 0x06, 0x01, (index1 & 0x00FF), (index1 & 0xFF00)>>8, 0x00, 0x00, 0x02, (index2 & 0x00FF), (index2 & 0xFF00)>>8, 0x00, 0x00, 0x03, (index3 & 0x00FF), (index3 & 0xFF00)>>8, 0x00, 0x00, 0x04, (index4 & 0x00FF), (index4 & 0xFF00)>>8, 0x00, 0x00, 0x05, (index5 & 0x00FF), (index5 & 0xFF00)>>8, 0x00, 0x00, 0x06, (index6 & 0x00FF), (index6 & 0xFF00)>>8, 0x00, 0x00};
        applyCmd = [[NSData alloc] initWithBytes:byte length:33];
        [[DataModelManager shareInstance] sendDataByStreamDataTransfer:deviceID data:applyCmd];
    }else if ([CSRUtilities belongToSceneRemoteFourKeys:deviceEntity.shortName]
              || [CSRUtilities belongToSceneRemoteFourKeysV:deviceEntity.shortName]) {
        NSMutableArray *allIndexs = [[NSMutableArray alloc] initWithObjects:@(0), nil];
        for (SceneEntity *scene in [CSRAppStateManager sharedInstance].selectedPlace.scenes) {
            [allIndexs addObject:scene.rcIndex];
        }
        
        NSInteger index1 = 0;
        while ([allIndexs containsObject:@(index1)]) {
            index1 = arc4random()%65470+64;
        }
        [allIndexs addObject:@(index1)];
        NSInteger index2 = 0;
        while ([allIndexs containsObject:@(index2)]) {
            index2 = arc4random()%65470+64;
        }
        [allIndexs addObject:@(index2)];
        NSInteger index3 = 0;
        while ([allIndexs containsObject:@(index3)]) {
            index3 = arc4random()%65470+64;
        }
        [allIndexs addObject:@(index3)];
        NSInteger index4 = 0;
        while ([allIndexs containsObject:@(index4)]) {
            index4 = arc4random()%65470+64;
        }
        [self performSelector:@selector(configureSceneRemoteTimeOut) withObject:nil afterDelay:15.0f];
        retryCount = 0;
        Byte byte[] = {0x9b, 0x15, 0x04, 0x01, (index1 & 0x00FF), (index1 & 0xFF00)>>8, 0x00, 0x00, 0x02, (index2 & 0x00FF), (index2 & 0xFF00)>>8, 0x00, 0x00, 0x03, (index3 & 0x00FF), (index3 & 0xFF00)>>8, 0x00, 0x00, 0x04, (index4 & 0x00FF), (index4 & 0xFF00)>>8, 0x00, 0x00};
        applyCmd = [[NSData alloc] initWithBytes:byte length:23];
        [[DataModelManager shareInstance] sendDataByStreamDataTransfer:deviceID data:applyCmd];
    }else if ([CSRUtilities belongToSceneRemoteThreeKeys:deviceEntity.shortName]
              || [CSRUtilities belongToSceneRemoteThreeKeysV:deviceEntity.shortName]) {
        NSMutableArray *allIndexs = [[NSMutableArray alloc] initWithObjects:@(0), nil];
        for (SceneEntity *scene in [CSRAppStateManager sharedInstance].selectedPlace.scenes) {
            [allIndexs addObject:scene.rcIndex];
        }
        
        NSInteger index1 = 0;
        while ([allIndexs containsObject:@(index1)]) {
            index1 = arc4random()%65470+64;
        }
        [allIndexs addObject:@(index1)];
        NSInteger index2 = 0;
        while ([allIndexs containsObject:@(index2)]) {
            index2 = arc4random()%65470+64;
        }
        [allIndexs addObject:@(index2)];
        NSInteger index3 = 0;
        while ([allIndexs containsObject:@(index3)]) {
            index3 = arc4random()%65470+64;
        }
        [self performSelector:@selector(configureSceneRemoteTimeOut) withObject:nil afterDelay:15.0f];
        retryCount = 0;
        Byte byte[] = {0x9b, 0x10, 0x03, 0x01, (index1 & 0x00FF), (index1 & 0xFF00)>>8, 0x00, 0x00, 0x02, (index2 & 0x00FF), (index2 & 0xFF00)>>8, 0x00, 0x00, 0x03, (index3 & 0x00FF), (index3 & 0xFF00)>>8, 0x00, 0x00};
        applyCmd = [[NSData alloc] initWithBytes:byte length:18];
        [[DataModelManager shareInstance] sendDataByStreamDataTransfer:deviceID data:applyCmd];
    }else if ([CSRUtilities belongToSceneRemoteTwoKeys:deviceEntity.shortName]
              || [CSRUtilities belongToSceneRemoteTwoKeysV:deviceEntity.shortName]) {
        NSMutableArray *allIndexs = [[NSMutableArray alloc] initWithObjects:@(0), nil];
        for (SceneEntity *scene in [CSRAppStateManager sharedInstance].selectedPlace.scenes) {
            [allIndexs addObject:scene.rcIndex];
        }
        
        NSInteger index1 = 0;
        while ([allIndexs containsObject:@(index1)]) {
            index1 = arc4random()%65470+64;
        }
        [allIndexs addObject:@(index1)];
        NSInteger index2 = 0;
        while ([allIndexs containsObject:@(index2)]) {
            index2 = arc4random()%65470+64;
        }
        [self performSelector:@selector(configureSceneRemoteTimeOut) withObject:nil afterDelay:15.0f];
        retryCount = 0;
        Byte byte[] = {0x9b, 0x0b, 0x02, 0x01, (index1 & 0x00FF), (index1 & 0xFF00)>>8, 0x00, 0x00, 0x02, (index2 & 0x00FF), (index2 & 0xFF00)>>8, 0x00, 0x00};
        applyCmd = [[NSData alloc] initWithBytes:byte length:13];
        [[DataModelManager shareInstance] sendDataByStreamDataTransfer:deviceID data:applyCmd];
    }else if ([CSRUtilities belongToSceneRemoteOneKey:deviceEntity.shortName]
              || [CSRUtilities belongToSceneRemoteOneKeyV:deviceEntity.shortName]) {
        NSMutableArray *allIndexs = [[NSMutableArray alloc] initWithObjects:@(0), nil];
        for (SceneEntity *scene in [CSRAppStateManager sharedInstance].selectedPlace.scenes) {
            [allIndexs addObject:scene.rcIndex];
        }
        
        NSInteger index1 = 0;
        while ([allIndexs containsObject:@(index1)]) {
            index1 = arc4random()%65470+64;
        }
        [self performSelector:@selector(configureSceneRemoteTimeOut) withObject:nil afterDelay:15.0f];
        retryCount = 0;
        Byte byte[] = {0x9b, 0x06, 0x01, 0x01, (index1 & 0x00FF), (index1 & 0xFF00)>>8, 0x00, 0x00};
        applyCmd = [[NSData alloc] initWithBytes:byte length:8];
        [[DataModelManager shareInstance] sendDataByStreamDataTransfer:deviceID data:applyCmd];
    }
    
}

- (void)callbackOfRemoteConfigruation:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *sourceDeviceId = userInfo[@"DEVICEID"];
    if ([sourceDeviceId isEqualToNumber:applyDeviceID]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(configureSceneRemoteTimeOut) object:nil];
        NSNumber *state = userInfo[@"STATE"];
        if ([state boolValue]) {
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:applyDeviceID];
            deviceEntity.remoteBranch = [NSString stringWithFormat:@"%@%@%@%@%@%@",[CSRUtilities hexStringFromData:[applyCmd subdataWithRange:NSMakeRange(3, 3)]],[CSRUtilities hexStringFromData:[applyCmd subdataWithRange:NSMakeRange(8, 3)]],[CSRUtilities hexStringFromData:[applyCmd subdataWithRange:NSMakeRange(13, 3)]],[CSRUtilities hexStringFromData:[applyCmd subdataWithRange:NSMakeRange(18, 3)]],[CSRUtilities hexStringFromData:[applyCmd subdataWithRange:NSMakeRange(23, 3)]],[CSRUtilities hexStringFromData:[applyCmd subdataWithRange:NSMakeRange(28, 3)]]];
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            Byte *byte = (Byte *)[applyCmd bytes];
            if ([applyCmd length] == 33) {
                NSInteger index1 = byte[4] + byte[5] * 256;
                [self createSceneEntity:index1];
                NSInteger index2 = byte[9] + byte[10] * 256;
                [self createSceneEntity:index2];
                NSInteger index3 = byte[14] + byte[15] * 256;
                [self createSceneEntity:index3];
                NSInteger index4 = byte[19] + byte[20] * 256;
                [self createSceneEntity:index4];
                NSInteger index5 = byte[24] + byte[25] * 256;
                [self createSceneEntity:index5];
                NSInteger index6 = byte[29] + byte[30] * 256;
                [self createSceneEntity:index6];
            }else if ([applyCmd length] == 28) {
                NSInteger index1 = byte[4] + byte[5] * 256;
                [self createSceneEntity:index1];
                NSInteger index2 = byte[9] + byte[10] * 256;
                [self createSceneEntity:index2];
                NSInteger index3 = byte[14] + byte[15] * 256;
                [self createSceneEntity:index3];
                NSInteger index4 = byte[19] + byte[20] * 256;
                [self createSceneEntity:index4];
                NSInteger index5 = byte[24] + byte[25] * 256;
                [self createSceneEntity:index5];
            }else if ([applyCmd length] == 23) {
                NSInteger index1 = byte[4] + byte[5] * 256;
                [self createSceneEntity:index1];
                NSInteger index2 = byte[9] + byte[10] * 256;
                [self createSceneEntity:index2];
                NSInteger index3 = byte[14] + byte[15] * 256;
                [self createSceneEntity:index3];
                NSInteger index4 = byte[19] + byte[20] * 256;
                [self createSceneEntity:index4];
            }else if ([applyCmd length] == 18) {
                NSInteger index1 = byte[4] + byte[5] * 256;
                [self createSceneEntity:index1];
                NSInteger index2 = byte[9] + byte[10] * 256;
                [self createSceneEntity:index2];
                NSInteger index3 = byte[14] + byte[15] * 256;
                [self createSceneEntity:index3];
            }else if ([applyCmd length] == 13) {
                NSInteger index1 = byte[4] + byte[5] * 256;
                [self createSceneEntity:index1];
                NSInteger index2 = byte[9] + byte[10] * 256;
                [self createSceneEntity:index2];
            }else if ([applyCmd length] == 8) {
                NSInteger index1 = byte[4] + byte[5] * 256;
                [self createSceneEntity:index1];
            }
            
        }
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:@"CALLBACKOFREMOTECONFIGURATION"
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SCENEREMOTEDIDCONFIGURED" object:self userInfo:nil];
        applyDeviceID = nil;
        applyCmd = nil;
    }
}

- (void)configureSceneRemoteTimeOut {
    if (retryCount < 5) {
        retryCount ++;
        [self performSelector:@selector(configureSceneRemoteTimeOut) withObject:nil afterDelay:15.0f];
        [[DataModelManager shareInstance] sendDataByStreamDataTransfer:applyDeviceID data:applyCmd];
    }
}

- (void)createSceneEntity:(NSInteger)index {
    BOOL exit = NO;
    for (SceneEntity *scene in [CSRAppStateManager sharedInstance].selectedPlace.scenes) {
        if ([scene.rcIndex integerValue] == index) {
            exit = YES;
            break;
        }
    }
    if (!exit) {
        SceneEntity *scene = [NSEntityDescription insertNewObjectForEntityForName:@"SceneEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
        scene.rcIndex = @(index);
        scene.sceneID = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"SceneEntity_sceneID"];
        scene.srDeviceId = applyDeviceID;
        [[CSRAppStateManager sharedInstance].selectedPlace addScenesObject:scene];
        [[CSRDatabaseManager sharedInstance] saveContext];
    }
}

- (void)didGetDeviceInfo:(NSNumber * _Nonnull)deviceId  infoType:(NSNumber * _Nonnull)infoType information:(NSData * _Nonnull)information meshRequestId:(NSNumber * _Nonnull)meshRequestId
{
    CSRmeshDevice *meshDevice = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:deviceId];
    
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
    
    if (!deviceEntity) {
        
        deviceEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRDeviceEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    }
    
    NSDictionary *info = [self infoDictionary:information type:[infoType intValue]];
    
//    if ([infoType intValue] == CSR_UUID_low) {
//        NSLog(@"Dict0 :%@", info);
//    }
//    if ([infoType intValue] == CSR_UUID_high) {
//        NSLog(@"Dict1 :%@", info);
//    }
    
    NSData *data;
    
    if ([infoType intValue] == CSR_Model_low) {
        
        data = info[kDEVICE_MODELS_LOW];
        deviceEntity.modelLow = data;
    }
    if ([infoType intValue] == CSR_Model_high){
        
        data = info[kDEVICE_MODELS_HIGH];
        deviceEntity.modelHigh = data;
    }
    
    if (meshDevice) {
        
        [meshDevice createModelsWithModelNumber:data withInfoType:infoType];
    }
    
    if ([infoType intValue] == CSR_Appearance) {
        
        NSData *appearanceData = info[kDEVICE_APPEARANCE];
        NSData *revData = [CSRUtilities reverseData:appearanceData];
        NSUInteger appValue = 0;
        [revData getBytes:&appValue length:sizeof(appValue)];
        
        if (appValue) {
            NSString *name;
            switch (appValue) {
                case CSRApperanceNameLight:
                    name = [NSString stringWithFormat:@"Light %d",(int)([deviceId intValue]&0x7fff)];
                    break;
                case CSRApperanceNameSensor:
                    name = [NSString stringWithFormat:@"Sensor %d",(int)([deviceId intValue]&0x7fff)];
                    break;
                case CSRApperanceNameHeater:
                    name = [NSString stringWithFormat:@"Heater %d",(int)([deviceId intValue]&0x7fff)];
                    break;
                case CSRApperanceNameSwitch:
                    name = [NSString stringWithFormat:@"Switch %d",(int)([deviceId intValue]&0x7fff)];
                    break;
                case CSRApperanceNameController:
                    name = [NSString stringWithFormat:@"Controller %d", (int)([deviceId intValue]&0x7fff)];
                    break;
                default:
                    break;
            }
            
            meshDevice.name = name;
            
            if (deviceEntity) {
                deviceEntity.name = name;
                deviceEntity.appearance = @(appValue);
            }
        }
    }
    
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    if (info) {
        NSMutableDictionary *objects = [NSMutableDictionary dictionaryWithDictionary:info];
        if (meshRequestId)
            [objects setObject:meshRequestId forKey:kMeshRequestIdString];
        if (deviceId)
            [objects setObject:deviceId forKey:kDeviceIdString];
        if (infoType)
            [objects setObject:infoType forKey:kInfoTypeString];
        [[NSNotificationCenter defaultCenter] postNotificationName:kCSRmeshManagerDidGetDeviceInfoNotification object:self userInfo:objects];
    }
}

- (NSDictionary *)infoDictionary:(NSData *)data type:(NSInteger)infoType {
    
    switch (infoType) {
        case CSR_UUID_low:
            return @{kCSR_UUID_LOW: data};
        case CSR_UUID_high:
            return @{kCSR_UUID_HIGH: data};
        case CSR_Model_low:
            return @{kCSR_MODEL_LOW: data};
        case CSR_Model_high:
            return @{kCSR_MODEL_HIGH: data};
        case CSR_VID_PID_Version:
            return @{kCSR_PRODUCT_IDENTIFIER: data};
        case CSR_Appearance:
            return @{kCSR_APPEARANCE: data};
        case CSR_LastETag:
            return @{kCSR_LAST_ETAG: data};
        default:
            return nil;
    }
}

//-(void) didTimeoutMessage:(NSNumber *)meshRequestId
//{
//    // Notify all listeners
//    NSMutableDictionary *objects = [NSMutableDictionary dictionary];
//    
//    if (meshRequestId) {
//        
//        [objects setObject:meshRequestId forKey:kMeshRequestIdString];
//        
//    }
//    
//    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRmeshManagerDidTimeoutMessageNotification object:self userInfo:objects];
//}

#pragma mark models and groups notifications

-(void) didGetNumModelGroupIds:(NSNumber *)deviceId modelNo:(NSNumber *)modelNo numberOfModelGroupIds:(NSNumber *)numberOfModelGroupIds meshRequestId:(NSNumber *)meshRequestId{
    
    NSMutableDictionary *objects = [NSMutableDictionary dictionary];
    if (deviceId)
        [objects setObject:deviceId forKey:kDEVICE_NUMBER];
    if (modelNo)
        [objects setObject:modelNo forKey:kDEVICE_MODEL_NUMBER_STRING];
    if (numberOfModelGroupIds)
        [objects setObject:numberOfModelGroupIds forKey:kDEVICE_NUMBER_OF_MODEL_GROUP_ID_STRING];
    if (meshRequestId)
        [objects setObject:meshRequestId forKey:kDEVICE_MESH_REQUEST_ID_STRING];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRmeshManagerDidGetNumberOfModelGroupIdsNotification object:self userInfo:objects];
}


@end
