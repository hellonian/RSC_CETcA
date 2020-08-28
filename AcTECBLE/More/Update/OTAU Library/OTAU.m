//
//  OTAU.m
//  OTAUTest
//
//  Created by AcTEC on 2019/2/28.
//  Copyright © 2019 BAO. All rights reserved.
//

#import "OTAU.h"
#import "PCM.h"
#import "CBPeripheral+Info.h"
#import <CommonCrypto/CommonCrypto.h>
#import "ApplicationImage.h"
#import "DataModelManager.h"
#import "CSRAppStateManager.h"
#import "CSRDatabaseManager.h"

#define kDidUpdateNotificationStateForCharacteristic @"didUpdateNotificationStateForCharacteristic"
#define kDidWriteValueForCharacteristic @"didWriteValueForCharacteristic"
#define kDidUpdateValueForCharacteristic @"didUpdateValueForCharacteristic"
#define kDidDiscoverCharacteristicsForService   @"didDiscoverCharacteristicsForService"
#define kBleDidConnectPeripheral @"BleDidConnectPeripheral"


@interface OTAU ()<CBPeripheralDelegate,CSRBluetoothLEDelegate>
{
    BOOL otauRunning;
    uint8_t otauVersion;
    NSInteger applicationNumber;
    BOOL waitForDisconnect;
    BOOL targetHasChallengeResponse;
    BOOL transferInProgress;
    NSInteger transferCount;
    NSInteger transferTotal;
    uint8_t transferPercent;
}

@property (nonatomic, strong) CBPeripheral *targetPeripheral;
@property (nonatomic, strong) NSString *peripheralBuildId;
@property (nonatomic, strong) NSDictionary *csKeyDb;
@property (nonatomic, strong) NSData *btMacAddress, *crystalTrim, *iRoot, *eRoot;

@end

@implementation OTAU

+ (id)shareInstance {
    static OTAU *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[OTAU alloc] init];
    });
    return shared;
}

- (id) init {
    self = [super init];
    if (self) {
        otauRunning = NO;
        otauVersion = 0;
    }
    return self;
}

- (void) initOTAU:(CBPeripheral *)peripheral {
    _targetPeripheral = [[CSRBluetoothLE sharedInstance] targetPeripheral];
    _targetPeripheral.delegate = self;
    _peripheralBuildId = nil;
    
    CBUUID *uuid = [CBUUID UUIDWithString:serviceApplicationOtauUuid];
    CBUUID *bl_uuid = [CBUUID UUIDWithString:serviceBootOtauUuid];
    
    for (CBService *service in _targetPeripheral.services) {
        if ([service.UUID isEqual:uuid] || [service.UUID isEqual:bl_uuid]) {
            [[CSRBluetoothLE sharedInstance] setTargetService:service];
        }
    }
    
    [_targetPeripheral deleteQueue];
    if (!otauRunning) {
        [self performSelectorInBackground:@selector(initMain) withObject:nil];
    }
}

- (BOOL) initMain {
    BOOL success = NO;
    do {
        if (![self discoverOtauVersion]) {
            break;
        }
        NSLog(@"otauVersion:%d",otauVersion);
        
        [self clearOtauKeys];
        
        if (![self getOtauKeys]) {
            break;
        }
        
        [self startOTAU];
        
    } while (0);
    
    return success;
}


- (void)clearOtauKeys {
    _btMacAddress = nil;
    _crystalTrim = nil;
    _iRoot = nil;
    _eRoot = nil;
}

-(BOOL) discoverOtauVersion {
    BOOL otauRunningOld = otauRunning;
    otauRunning = YES;
    BOOL returnValue = NO;
    
    do {
        if ([self checkForCharacteristic:characteristicVersionUuid]) {
            NSData *otauVer = [self readCharacteristic:characteristicVersionUuid fromService:[[CSRBluetoothLE sharedInstance] targetService]];
            if (!otauVer) {
                NSLog(@"Failed: Read Bootloader Version Characteristics");
                break;
            }
            [otauVer getBytes:&otauVersion length:sizeof(otauVersion)];
            if (otauVersion<4) {
                NSLog(@"Failed: Invalid bootloader version specified: %hhu",otauVersion);
                break;
            }
            NSLog(@"Success: Read Bootloader Version Characteristics");
            returnValue = YES;
        }
    } while (0);
    
    otauRunning = otauRunningOld;
    
    return returnValue;
}

-(BOOL) getOtauKeys {
    if (!_targetPeripheral || _targetPeripheral.state != CBPeripheralStateConnected || otauVersion == 0) {
        return NO;
    }
    
    [self getBtMacAddress];
    if (_btMacAddress == nil) {
        return (NO);
    }
    NSLog(@"Mac address: %@", _btMacAddress);
    
    [self getCrystalTrim];
    if (_crystalTrim == nil) {
        return NO;
    }
    NSLog(@"Trim: %@", _crystalTrim);
    
    [self getIdentityRoot];
    if (_iRoot == nil) {
        return NO;
    }
    NSLog(@"Identity root: %@", _iRoot);
    
    [self getEncryptionRoot];
    if (_eRoot == nil) {
        return NO;
    }
    NSLog(@"Encryption root:%@:", _eRoot);
    
    return YES;
}

-(NSData *) readCharacteristic:(NSString *)characteristicName fromService:(CBService*) service {
    CBUUID *uuid = [CBUUID UUIDWithString:characteristicName];
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:uuid]) {
            NSLog(@"Request Characteristic %@ Value", characteristicName);
            [_targetPeripheral readValueForCharacteristic:characteristic];
            PCM *pcm= [self waitForDelegate:kDidUpdateValueForCharacteristic];
            if (pcm && (pcm.PCMError == NULL)) {
                NSLog(@"Success: Request Characteristic %@ Value", characteristicName);
                return (pcm.PCMCharacteristic.value);
            }
            else {
                if (pcm.PCMError) {
                    NSLog(@"Failed: Request Characteristic %@ Value, status:%@",
                          characteristicName, pcm.PCMError.localizedDescription);
                }
            }
        }
    }
    return nil;
}

- (BOOL) getBtMacAddress {
    NSData *result = [self getCsKeyMain: csKeyIndexBluetoothAddress];
    if (result) {
        if (otauVersion < 5) {
            _btMacAddress = [result subdataWithRange:NSMakeRange(0, 6)];
        }else {
            Byte b[] = {0, 0, 0, 0, 0, 0};
            NSUInteger length = 6;
            if ( length > result.length ) {
                length = result.length;
            }
            for ( NSUInteger i = 0; ( i < length ); ++i ) {
                NSRange range = {length - i - 1, 1};
                [result getBytes:&b[i] range:range];
            }
            _btMacAddress = [NSData dataWithBytes:b length:length];
        }
        return YES;
    }else {
        NSLog(@"Failed: Get BT Mac address");
    }
    return NO;
}

- (BOOL)getCrystalTrim {
    NSData *result = [self getCsKeyMain: csKeyIndexCrystalTrim];
    if (result) {
        _crystalTrim = [result subdataWithRange:NSMakeRange(0, result.length)];
        return YES;
    }
    else {
        NSLog(@"Failed: Get Crystal Trim");
    }
    
    return NO;
}

- (BOOL)getIdentityRoot {
    NSData *result = [self getCsKeyMain:csKeyIndexIdentityRoot];
    if (result) {
        _iRoot = [result subdataWithRange:NSMakeRange(0, result.length)];
        return YES;
    }else {
        NSLog(@"Failed: Get Identity Root");
        return NO;
    }
}

- (BOOL)getEncryptionRoot {
    NSData *result = [self getCsKeyMain:csKeyIndexEncryptionRoot];
    if (result != nil) {
        _eRoot = [result subdataWithRange:NSMakeRange(0, result.length)];
        return YES;
    }
    else {
        NSLog(@"Failed: Get Encryption Root");
        return NO;
    }
}

-(NSData*) getCsKeyMain : (uint8_t) csKeyIndex {
    NSData *result = nil;
    BOOL otauRunningOld = otauRunning;
    if (_targetPeripheral && otauVersion >= 4) {
        otauRunning = YES;
        do {
            _targetPeripheral.delegate = self;
            
            BOOL useLegacy = NO;
            if ([[[CSRBluetoothLE sharedInstance] peripheralInBoot] boolValue]) {
                if (otauVersion >= 5) {
                    useLegacy = YES;
                }else {
                    break;
                }
            }
            
            if (useLegacy) {
                PCM *pcm = [self getCsKeyLegacy:(otauVersion >= 5) : [[[CSRBluetoothLE sharedInstance] peripheralInBoot] boolValue] : csKeyIndex];
                if (pcm && (pcm.PCMError == NULL)) {
                    result = pcm.PCMCharacteristic.value;
                }
                
            }else {
                if ([self createNotifyForCSKey]) {
                    result  = [self getCsKeyFromBlock:csKeyIndex];
                }else {
                    NSLog(@"Failed to register for cs key notification");
                }
            }
            break;
        } while (0);
    }
    otauRunning = otauRunningOld;
    return result;
}

-(PCM *) getCsKeyLegacy :(BOOL) isOTAUv5 :(BOOL) isBootMode :(uint8_t) csKeyIndex {
    PCM *retVal = NULL;
    CBUUID *getCsKeyCharUuid = [CBUUID UUIDWithString:characteristicGetKeysUuid];
    CBUUID *dataTransferCharUuid = [CBUUID UUIDWithString:characteristicDataTransferUuid];
    CBCharacteristic *dataTransferCharacteristic = NULL;
    CBCharacteristic *getCsKeyCharacteristic = NULL;
    for (CBCharacteristic *characteristic in [[CSRBluetoothLE sharedInstance] targetService].characteristics) {
        if ([characteristic.UUID isEqual:dataTransferCharUuid]) {
            dataTransferCharacteristic = characteristic;
        }
        else if ([characteristic.UUID isEqual:getCsKeyCharUuid]) {
            getCsKeyCharacteristic = characteristic;
        }
        if (getCsKeyCharacteristic && dataTransferCharacteristic) {
            NSData *csCommand = [NSData dataWithBytes:(void *)&csKeyIndex
                                               length:sizeof(csKeyIndex)];
            [_targetPeripheral writeValue:csCommand
                       forCharacteristic:getCsKeyCharacteristic
                                    type:CBCharacteristicWriteWithResponse];
            if ( isOTAUv5 && isBootMode ) {
                PCM *pcm = [self waitForDelegate:kDidWriteValueForCharacteristic];
                if (pcm == nil) {
                    NSLog(@"Failed: No write response requesting cs key from boot loader");
                    break;
                }
                [_targetPeripheral readValueForCharacteristic:dataTransferCharacteristic];
            }
            if (otauRunning) {
                NSLog(@"OTAU is running");
            }
            else {
                NSLog(@"OTAU is not running");
            }
            retVal = [self waitForDelegate:kDidUpdateValueForCharacteristic];
            break;
        }
    }
    return retVal;
}

-(BOOL) createNotifyForCSKey {
    CBUUID *uuid;
    if ([[[CSRBluetoothLE sharedInstance] peripheralInBoot] boolValue]) {
        uuid = [CBUUID UUIDWithString:characteristicTransferControlUuid];
    }else {
        uuid = [CBUUID UUIDWithString:characteristicDataTransferUuid];
    }
    
    for (CBCharacteristic *characteristic in [[CSRBluetoothLE sharedInstance] targetService].characteristics) {
        if ([characteristic.UUID isEqual:uuid]) {
            if (!characteristic.isNotifying) {
                [_targetPeripheral setNotifyValue:YES forCharacteristic:characteristic];
                PCM *pcm = [self waitForDelegate:kDidUpdateNotificationStateForCharacteristic];
                if (pcm && pcm.PCMError == NULL) {
                    return YES;
                }else {
                    return NO;
                }
            }else {
                NSLog(@"Notify already set");
                return YES;
            }
        }
    }
    return NO;
}

-(BOOL) checkForCharacteristic:(NSString *)characteristicName {
    BOOL ret = false;
    CBUUID *uuid = [CBUUID UUIDWithString:characteristicName];
    for (CBCharacteristic *characteristic in [[CSRBluetoothLE sharedInstance] targetService].characteristics) {
        // Is this the characteristic we have discovered
        if ([characteristic.UUID isEqual:uuid]) {
            ret = true;
            break;
        }
    }
    return ret;
}

-(PCM *) waitForDelegate:(NSString *) delegate {
    // Test every Second, timeout afer 30 seconds
    for (int i=0; i<30; i++) {
        [NSThread sleepForTimeInterval:1];
        if (_targetPeripheral) {
            // This removes a delegate from the queue of received delegates.
            PCM *pcm = [_targetPeripheral getCallBack];
            if (pcm) {
                if ([pcm.PCMName isEqualToString:delegate]) {
                    return (pcm);
                }
            }
        }
        if (otauRunning==NO)
            return(nil);
    }
    return (nil);
}

-(NSData *) getCsKeyFromBlock : (uint8_t) csKeyId {
    PCM *pcm = NULL;
    CBUUID *getCsBlockUuid = [CBUUID UUIDWithString:characteristicGetKeyBlockUuid];
    CBUUID *dataTransferCharUuid = [CBUUID UUIDWithString:characteristicDataTransferUuid];
    CBCharacteristic *dataTransferCharacteristic = NULL;
    CBCharacteristic *csBlockCharacteristic = NULL;
    for (CBCharacteristic *characteristic in [[CSRBluetoothLE sharedInstance] targetService].characteristics) {
        if ([characteristic.UUID isEqual:dataTransferCharUuid]) {
            dataTransferCharacteristic = characteristic;
        }else if ([characteristic.UUID isEqual:getCsBlockUuid]) {
            csBlockCharacteristic = characteristic;
        }
        
        if (csBlockCharacteristic && dataTransferCharacteristic ) {
            if (_peripheralBuildId == nil) {
                Byte bytes[] = {0x00,0x00,0x02,0x00};
                NSMutableData *buildIdCommand = [NSMutableData dataWithBytes:bytes length:4];
                [_targetPeripheral writeValue:buildIdCommand
                            forCharacteristic:csBlockCharacteristic type:CBCharacteristicWriteWithResponse];
                
                pcm = [self waitForDelegate:kDidWriteValueForCharacteristic];
                if (pcm == nil) {
                    NSLog(@"Failed: no write response when trying to read build id");
                    break;
                }else {
                    NSLog(@"Requested build id ok");
                }
                
                pcm = [self waitForDelegate:kDidUpdateValueForCharacteristic];
                if (pcm && pcm.PCMError == NULL) {
                    NSData *data = [NSData dataWithData:pcm.PCMCharacteristic.value];
                    uint16_t *build = (uint16_t *)[data bytes];
                    if (build!=nil) {
                        _peripheralBuildId = [NSString stringWithFormat:@"%d",*build];
                        NSLog(@"Build id is %@", _peripheralBuildId);
                    }
                    pcm = nil;
                }
            }else {
                NSDictionary *csKeyEntry = [self getCsKeyDbEntry:_peripheralBuildId :csKeyId];
                NSLog(@"Cs key entry is %@", csKeyEntry);
                if (csKeyEntry != nil) {
                    
                    uint16_t offset = [csKeyEntry[@"OFFSET"] intValue];
                    uint16_t lenBytes = [csKeyEntry[@"LENGTH"] intValue] * 2;
                    
                    NSMutableData *csCommand = [[NSMutableData alloc] init];
                    [csCommand appendBytes:(void *)&offset length:sizeof(offset)];
                    [csCommand appendBytes:(void *)&lenBytes length:sizeof(lenBytes)];
                    
                    
                    [_targetPeripheral writeValue:csCommand
                               forCharacteristic:csBlockCharacteristic
                                            type:CBCharacteristicWriteWithResponse];
                    
                    pcm = [self waitForDelegate:kDidUpdateValueForCharacteristic];
                }
                else {
                    NSLog(@"Failed: Build id or cs key id not found in cs key db");
                }
            }
        }
    }
    NSData *result = NULL;
    if (pcm && (pcm.PCMError == NULL)) {
        result = [NSData dataWithData: pcm.PCMCharacteristic.value];
    }
    else if (pcm) {
        NSLog(@"Error is %@", pcm.PCMError.localizedDescription);
    }
    return result;
}

- (BOOL)parseCsKeyJson:(NSString*)csKeyJsonFile {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:csKeyJsonFile ofType:@"json"];
    NSError *error = nil;
    NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    if (error) {
        return NO;
    }
    _csKeyDb = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        return NO;
    }
    return YES;
}

- (NSDictionary *)getCsKeyDbEntry:(NSString *)buildId :(uint8_t)keyId {
    if (!_csKeyDb) {
        return nil;
    }
    NSString *keyIdAsString = [NSString stringWithFormat:@"%d",keyId];
    NSArray *allBuilds = [[_csKeyDb objectForKey:@"PSKEY_DATABASE"] objectForKey:@"PSKEYS"];
    for (NSDictionary *build in allBuilds) {
        if ([build[@"BUILD_ID"] isEqualToString:buildId]) {
            NSArray *keysForThisBuild = build[@"PSKEY"];
            for (NSDictionary *csKey in keysForThisBuild) {
                if ([csKey[@"ID"] isEqualToString:keyIdAsString]) {
                    return csKey;
                }
            }
        }
    }
    return nil;
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateNotificationStateForCharacteristic for peripheral %@ & Characteristic %@",peripheral.name, characteristic.UUID);
    PCM *pcm = [[PCM alloc] init:peripheral :nil :characteristic :error :kDidUpdateNotificationStateForCharacteristic];
    [peripheral saveCallBack:pcm];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (transferInProgress) {
        transferCount++;
        uint8_t percent = 50 + (50*transferCount)/transferTotal;
        if (percent > transferPercent) {
            NSLog(@"进度 %hhu %%",percent);
            [self updateProgressDelegteMethod:percent/100.0];
        }
        if (transferCount == transferTotal) {
            transferInProgress = NO;
        }
    }
    NSLog(@"didWriteValueForCharacteristic for peripheral %@ & Characteristic %@",peripheral.name, characteristic.UUID);
    PCM *pcm = [[PCM alloc] init:peripheral :nil :characteristic :error :kDidWriteValueForCharacteristic];
    [peripheral saveCallBack:pcm];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"111didUpdateValueForCharacteristic for peripheral %@ & Characteristic %@ value=%@",peripheral.name, characteristic.UUID, characteristic.value);
    PCM *pcm = [[PCM alloc] init:peripheral :nil :characteristic :error :kDidUpdateValueForCharacteristic];
    [peripheral saveCallBack:pcm];
}

- (void)startOTAU {
    applicationNumber = 1;
    if (!otauRunning) {
//        [self performSelectorInBackground:@selector(otauMain) withObject:nil];
        [self otauMain];
    }
}

- (void)otauMain {
    otauRunning = YES;
    BOOL completedSuccessfuly = NO;
    do {
        if (![[[CSRBluetoothLE sharedInstance] peripheralInBoot] boolValue]) {
            NSLog(@"Start: Enter Boot");
            if ([self enterBoot] == NO || otauRunning == NO) {
                NSLog(@"Failed: Enter Boot");
                break;
            }
            NSLog(@"Success: Enter Boot");
            [self updateProgressDelegteMethod:0.3];
            
            if (![self discoverOtauVersion]) {
                break;
            }
            NSLog(@"otauVersion:%d",otauVersion);
            [self updateProgressDelegteMethod:0.5];
            
            if (![self detectChallengeResponse]) {
                break;
            }
            
            if ([self hostValidation]==NO) {
                break;
            }
            
            if (otauVersion >= 5) {
                [self clearOtauKeys];
                if (![self getOtauKeys]) {
                    break;
                }
            }
        }else if (_btMacAddress == nil || _crystalTrim == nil || _iRoot == nil || _eRoot == nil) {
            if (![self getOtauKeys]) {
                break;
            }
        }
        NSLog(@"Start: Prepare Application image");
        NSData *newApplication = [[ApplicationImage sharedInstance] prepareFirmwareWith:_crystalTrim
                                                                                    and:_btMacAddress
                                                                                    and:_iRoot
                                                                                    and:_eRoot
                                                                                forFile:_sourceFilePath];
        NSLog(@"Success: Prepare Application image");
        
        if (![self transferNewApplication:newApplication]) {
            break;
        }
        
        completedSuccessfuly = YES;
        waitForDisconnect = YES;
        NSLog (@"Start waitforDisconnect");
        while (waitForDisconnect) {
            NSLog(@"End waitforDisconnect");
            [NSThread sleepForTimeInterval: 2];
        }
        NSLog(@"Success: Image transferred");
    } while (0);
    
    if (!completedSuccessfuly) {
        [self terminateOTAU:@"Failed: Application Update" :OTAUErrorFailedUpdate];
        transferInProgress = NO;
    }else {
        if (![self connectPeripheral]) {
            [self terminateOTAU:@"Failed: Could not reconnect" :OTAUErrorFailedUpdate];
        }else {
            if (![self initMain]) {
                [self terminateOTAU:@"Failed: Could not query device" :OTAUErrorFailedUpdate];
            }
            NSLog(@"Success: Application Update");
            [self terminateOTAU:@"Success: Application Update" :0];
            
            [[CSRBluetoothLE sharedInstance] setTargetPeripheral:nil];
            [[CSRBluetoothLE sharedInstance] setTargetService:nil];
            NSArray *devices = [[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects];
            for (CSRDeviceEntity *deviceEntity in devices) {
                NSString *adUuidString = [_targetPeripheral.uuidString substringToIndex:12];
                NSString *deviceUuidString = [deviceEntity.uuid substringFromIndex:24];
                if ([adUuidString isEqualToString:deviceUuidString]) {
                    deviceEntity.firVersion = nil;
                    deviceEntity.cvVersion = nil;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    [self getVersion:deviceEntity.deviceId];
                    break;
                }
            }
        }
    }
    otauRunning = NO;
}

- (void)getVersion: (NSNumber *)deviceId {
    [[DataModelManager shareInstance] sendCmdData:@"880100" toDeviceId:deviceId];
    __weak OTAU *weakself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        if (!deviceEntity.firVersion && !deviceEntity.cvVersion) {
            [weakself getVersion:deviceId];
        }else {
            if (self.otauDelegate && [self.otauDelegate respondsToSelector:@selector(regetVersion)]) {
                [self.otauDelegate regetVersion];
            }
        }
    });
}

- (BOOL)enterBoot {
    CBUUID *uuid = [CBUUID UUIDWithString:characteristicCurrentAppUuid];
    BOOL success = NO;
    NSUUID  *targetPeripheralID = _targetPeripheral.identifier;
    
    waitForDisconnect = YES;
    
    for (CBCharacteristic *characteristic in [[CSRBluetoothLE sharedInstance] targetService].characteristics) {
        if ([characteristic.UUID isEqual:uuid]) {
            uint8_t appCommandValue = 0;
            NSData *appCommand = [NSData dataWithBytes:(void *)&appCommandValue length:sizeof(appCommandValue)];
            [_targetPeripheral writeValue:appCommand forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            PCM *pcm = [self waitForDelegate:kDidWriteValueForCharacteristic];
            if ( (!pcm) || (pcm.PCMError != NULL) ) {
                if ( pcm ) {
                    NSLog(@"Enter bootmode, write characteristic status: %@", pcm.PCMError.localizedDescription);
                }
                break;
            }
            
            [NSThread sleepForTimeInterval:2];
            
            [[CSRBluetoothLE sharedInstance] disconnectPeripheral:_targetPeripheral];
            [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
            
            NSArray *peripherals = [[CSRBluetoothLE sharedInstance] retrievePeripheralsWithIdentifier:targetPeripheralID];
            if (peripherals && [peripherals count] == 1) {
                _targetPeripheral = (CBPeripheral *)[peripherals objectAtIndex:0];
                _targetPeripheral.delegate = self;
                success = [self connectPeripheral];
                break;
            }
            [[CSRBluetoothLE sharedInstance] setBleDelegate:nil];
            break;
        }
    }
    waitForDisconnect = NO;
    return success;
}

- (BOOL)connectPeripheral {
    BOOL success = NO;
    [[CSRBluetoothLE sharedInstance] setSecondConnectBool:YES];
    [[CSRBluetoothLE sharedInstance] connectPeripheralNoCheck:_targetPeripheral];
    PCM *pcm = [self waitForDelegate:kBleDidConnectPeripheral];
    if (pcm) {
        NSLog(@"Success: Connect");
        int timeout = 300;
        while (![[[CSRBluetoothLE sharedInstance] discoveredChars] boolValue] && timeout--) {
            [NSThread sleepForTimeInterval:0.1];
        }
        if (timeout > 0) {
            success = YES;
            _targetPeripheral.delegate = self;
        }
    }else {
        NSLog(@"Failed: Connect");
    }
    return success;
}

- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral withError:(NSError *)error {
    if (peripheral == _targetPeripheral) {
        if (waitForDisconnect == NO) {
            if (error) {
                [[CSRBluetoothLE sharedInstance] disconnectPeripheral:_targetPeripheral];
                _targetPeripheral.delegate = nil;
                [[CSRBluetoothLE sharedInstance] setBleDelegate:nil];
                NSLog(@"Failed: Peripheral Disconnected.error:%@",error);
            }
        }else {
            waitForDisconnect = NO;
        }
    }else {
        NSLog(@"%@ peripheral Disconnected with error %@",peripheral.name, error);
    }
}

- (void)didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"didConnectPeripheral peripheral %@",peripheral.name);
    PCM *pcm = [[PCM alloc] init:peripheral :nil :nil :nil :kBleDidConnectPeripheral];
    [peripheral saveCallBack:pcm];
}

-(BOOL) detectChallengeResponse {
    NSLog(@"Start: Detect if target challenge response enabled.");
    bool returnVal = NO;
    do {
        if ([self checkForCharacteristic: characteristicTransferControlUuid]) {
            NSData* value = [self readCharacteristic:characteristicTransferControlUuid fromService: [[CSRBluetoothLE sharedInstance] targetService]];
            if (!value) {
                NSLog(@"Failed: Detect challenge response setting.");
                break;
            }
            uint8_t intVal = 0;
            [value getBytes:&intVal length:1];
            targetHasChallengeResponse = (intVal == 0 ? YES : NO);
            
            NSLog(@"targetHasChallengeResponse: %d",targetHasChallengeResponse);
            
            returnVal = (YES);
        }
    } while (0);
    
    return returnVal;
}

const uint8_t sharedSecretKey[] = {
    0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff};

-(BOOL) hostValidation {
    
    if (targetHasChallengeResponse) {
        NSLog(@"Start: Obtain Challenge Value");
        NSData *challenge = [self readCharacteristic:characteristicDataTransferUuid fromService:[[CSRBluetoothLE sharedInstance] targetService]];
        if (challenge) {
            NSLog(@"Success: Obtain Challenge Value");
            NSData *key = [[NSData alloc] initWithBytes:sharedSecretKey length:sizeof(sharedSecretKey)];
            size_t outLength;
            NSMutableData *cipherData = [NSMutableData dataWithLength:challenge.length +
                                         kCCBlockSizeAES128];
            
            CCCryptorStatus result = CCCrypt(kCCEncrypt, // operation
                                             kCCAlgorithmAES128, // Algorithm
                                             kCCOptionPKCS7Padding, // options
                                             key.bytes, // key
                                             key.length, // keylength
                                             nil, // (*iv).bytes,// iv
                                             challenge.bytes, // dataIn
                                             challenge.length, // dataInLength,
                                             cipherData.mutableBytes, // dataOut
                                             cipherData.length, // dataOutAvailable
                                             &outLength); // dataOutMoved
            
            if (result == kCCSuccess) {
                cipherData.length = outLength;
                NSData *destination = [NSData dataWithBytes:((char *)cipherData.bytes) length:16];
                NSLog(@"Start: Return Encrypted Challenge Value");
                [self writeCharacteristic:characteristicDataTransferUuid withValue:destination];
                [NSThread sleepForTimeInterval:5];
                NSLog(@"Success: Return Encrypted Challenge Value");
                return (YES);
            }
        }
        NSLog(@"Failed: Obtain Challenge Value");
        return (NO);
    }
    
    // return YES because challenge response is not expected
    return (YES);
}

-(void) writeCharacteristic:(NSString *)characteristicName withValue:(NSData *) data {
    CBUUID *uuid = [CBUUID UUIDWithString:characteristicName];
    
    for (CBCharacteristic *characteristic in [[CSRBluetoothLE sharedInstance] targetService].characteristics) {
        // Is this the characteristic we have discovered
        if ([characteristic.UUID isEqual:uuid]) {
            
            [_targetPeripheral writeValue:data forCharacteristic:characteristic
                                    type:CBCharacteristicWriteWithResponse];
        }
    }
}

-(BOOL) transferNewApplication:(NSData *) application {
    BOOL returnVal = YES;
    NSLog(@"Start: Subscribe for Notification");
    if (![self createNotifyForAppTransfer]) {
        NSLog(@"Failed: Subscribe for Notification");
        return (NO);
    }
    NSLog(@"Success: Subscribe for Notification");
    
    do {
        uint8_t charValue8 = (uint8_t) applicationNumber;
        
        NSData *charValue = [NSData dataWithBytes:(void *)&charValue8
                                           length:sizeof(charValue8)];
        [self writeCharacteristic:characteristicCurrentAppUuid withValue:charValue];
        PCM *appIdPcm = [self waitForDelegate:kDidWriteValueForCharacteristic];
        if ((!appIdPcm) || (appIdPcm.PCMError != NULL)) {
            if (appIdPcm && (appIdPcm.PCMError != NULL)) {
                NSLog(@"Setting the update application ID failed: %@, proceeding anyway!", appIdPcm.PCMError.localizedDescription);
            }
        }
        
        uint16_t charValue16 = transferControlInProgress;
        charValue = [NSData dataWithBytes:(void *)&charValue16
                                   length:sizeof(charValue16)];
        [self writeCharacteristic:characteristicTransferControlUuid withValue:charValue];
        PCM *transControlPcm = [self waitForDelegate:kDidWriteValueForCharacteristic];
        if ((!transControlPcm) || (transControlPcm.PCMError != NULL)) {
            if (transControlPcm) {
                NSLog(@"Setting app image transfer in progress failed: %@", transControlPcm.PCMError.localizedDescription);
            }
            NSLog(@"Failed: Set app image transfer in progress");
            returnVal = NO;
            break;
        }
        NSLog(@"Start: Transferring image");
        
        const uint8_t PacketLength = 20;
        transferInProgress = YES;
        transferPercent = 0;
        transferCount = 0;
        int total = (int) [application length];
        
        transferTotal = (total + (PacketLength-1)) / PacketLength;
        int index=0, length=PacketLength;
        while (returnVal && index<total) {
            if ((total-index) < 20) {
                length = total-index;
            }
            NSData *chunkOfAppData = [application subdataWithRange:NSMakeRange(index, length)];
            [self writeCharacteristic:characteristicDataTransferUuid withValue:chunkOfAppData];
            
            PCM *writePcm = nil;
            do {
                for (int i=0; i<1000; i++) {
                    usleep(100);
                    if (_targetPeripheral) {
                        writePcm = [_targetPeripheral getCallBack];
                        if (writePcm) {
                            if ([writePcm.PCMName isEqualToString:kDidWriteValueForCharacteristic]) {
                                break;
                            }
                        }
                    }
                }
                
                if ((!writePcm) || (writePcm.PCMError != NULL)) {
                    NSLog(@"Failed: while completing OTAU transfer");
                    if (writePcm) {
                        NSLog(@"Write data failed: %@", writePcm.PCMError.localizedDescription);
                    }
                    returnVal = NO;
                    break;
                }
            } while (![writePcm.PCMCharacteristic.UUID isEqual:[CBUUID UUIDWithString: characteristicDataTransferUuid]]);
            index += PacketLength;
        }
        
    } while (0);
    
    if (returnVal) {
        uint16_t charValue16 = transferControlComplete;
        NSData *charValue = [NSData dataWithBytes:(void *)&charValue16
                                           length:sizeof(charValue16)];
        [self writeCharacteristic:characteristicTransferControlUuid withValue:charValue];
    }
    
    return (returnVal);
}

-(BOOL) createNotifyForAppTransfer {
    NSLog(@"otauCreateNotifyForAppTx");
    CBUUID *uuid = [CBUUID UUIDWithString:characteristicTransferControlUuid];
    
    for (CBCharacteristic *characteristic in [[CSRBluetoothLE sharedInstance] targetService].characteristics) {
        
        if ([characteristic.UUID isEqual:uuid])
        {
            NSLog(@" -SetNotify for %@",characteristic.UUID);
            [_targetPeripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            PCM *pcm = [self waitForDelegate:kDidUpdateNotificationStateForCharacteristic];
            if (pcm && ( pcm.PCMError == NULL ) ) {
                return (YES);
            }
            else
                break;
        }
    }
    return (NO);
    
}

- (void)terminateOTAU:(NSString *)message :(int) errorCode {
    if (errorCode) {
        [[CSRBluetoothLE sharedInstance] disconnectPeripheral:_targetPeripheral];
        _targetPeripheral.delegate = nil;
        [[CSRBluetoothLE sharedInstance] setBleDelegate:nil];
    }else {
        NSLog(@"%@",[message capitalizedString]);
    }
    otauRunning = NO;
    [[CSRBluetoothLE sharedInstance] setIsUpdateFW:NO];
}

- (void)updateProgressDelegteMethod:(CGFloat)percentage {
    if (self.otauDelegate && [self.otauDelegate respondsToSelector:@selector(updateProgressDelegteMethod:)]) {
        [self.otauDelegate updateProgressDelegteMethod:percentage];
    }
}

@end
