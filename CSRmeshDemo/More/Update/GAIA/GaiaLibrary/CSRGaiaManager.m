//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSRGaiaManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "CSRBluetoothLE.h"
#import "QTIRWCP.h"

#define GAIA_MAX_LENGTH     12
#define RWCP_MAX_LENGTH     10

@interface CSRGaiaManager () <QTIRWCPDelegate>

@property (nonatomic) NSData *fileData;
@property (nonatomic) NSUInteger fileIndex;
@property (nonatomic) BOOL waitingForReconnect;
@property (nonatomic) BOOL disconnected;
@property (nonatomic) CBPeripheral *connectedPeripheral;
@property (nonatomic) NSTimeInterval startTime;
@property (nonatomic) GaiaUpdateResumePoint resumePoint;
@property (nonatomic) uint16_t lastError;
@property (nonatomic) BOOL restart;
@property (nonatomic) BOOL aborted;
@property (nonatomic) NSMutableArray *dataBuffer;
@property (nonatomic) BOOL syncRequested;
@property (nonatomic) BOOL registeredForNotifications;
@property (nonatomic) BOOL dataEndpointAvailable;
@property (nonatomic) uint16_t progress;


@end

@implementation CSRGaiaManager

@synthesize aborted;
@synthesize connectedPeripheral;
@synthesize dataBuffer;
@synthesize dataEndpointAvailable;
@synthesize delegate;
@synthesize disconnected;
@synthesize fileData;
@synthesize fileIndex;
@synthesize lastError;
@synthesize progress;
@synthesize registeredForNotifications;
@synthesize resumePoint;
@synthesize restart;
@synthesize startTime;
@synthesize syncRequested;
@synthesize updateFileName;
@synthesize updateInProgress;
@synthesize updateProgress;
@synthesize waitingForReconnect;

+ (CSRGaiaManager *)sharedInstance {
    static dispatch_once_t pred;
    static CSRGaiaManager *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[CSRGaiaManager alloc] init];
    });
    
    return shared;
}

- (id)init {
    if (self = [super init]) {
        self.syncRequested = NO;
        self.aborted = NO;
        self.fileData = nil;
        self.updateFileName = nil;
        self.updateInProgress = NO;
        self.waitingForReconnect = NO;
        self.disconnected = NO;
        self.updateProgress = 0.0;
        self.fileIndex = 0;
        self.restart = NO;
        self.connectedPeripheral = nil;
        self.resumePoint = GaiaUpdateResumePoint_Start;
        self.dataBuffer = [NSMutableArray array];
    }
    
    return self;
}

- (void)start:(NSString *)fileName useDataEndpoint:(BOOL)useDataEndpoint {
    self.aborted = NO;
    self.dataEndpointAvailable = useDataEndpoint;
    
    if (!self.updateInProgress) {
        self.updateFileName = fileName;
        self.fileData = [[NSData alloc] initWithContentsOfFile:fileName];
        
        NSLog(@"self.fileData.length: %lu %@",(unsigned long)self.fileData.length,self.updateFileName);
        self.fileIndex = 0;
        self.restart = NO;
        self.syncRequested = NO;
        [self.dataBuffer removeAllObjects];
        
        if (!self.fileData) {
            NSString *msg = [NSString stringWithFormat:@"Unable to open: %@", fileName];
            
            [delegate didAbortWithError:[NSError
                                         errorWithDomain:CSRGaiaError
                                         code:0
                                         userInfo:@{CSRGaiaErrorParam: msg}]];
            
            return;
        } else {
            [CSRGaia sharedInstance].fileMD5 = [self MD5:self.fileData];
        }
        
        self.connectedPeripheral = [[CSRBluetoothLE sharedInstance] targetPeripheral];
        
        if (self.dataEndpointAvailable) {
            [[QTIRWCP sharedInstance]
             connectPeripheral:self.connectedPeripheral
             dataCharacteristic:[CSRGaia sharedInstance].dataCharacteristic];
            [QTIRWCP sharedInstance].delegate = self;
            [QTIRWCP sharedInstance].fileSize = fileData.length;
        }
        
        [CSRGaia sharedInstance].delegate = self;
        [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
        self.updateInProgress = YES;
    }
    
    NSLog(@"GaiaEvent_VMUpgradeProtocolPacket > registerNotifications - start");
    self.registeredForNotifications = NO;
    [[CSRGaia sharedInstance] registerNotifications:GaiaEvent_VMUpgradeProtocolPacket];
}

- (void)connect {
    [CSRGaia sharedInstance].delegate = self;
    [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
    self.connectedPeripheral = [[CSRBluetoothLE sharedInstance] targetPeripheral];
}

- (void)disconnect {
    [[CSRBluetoothLE sharedInstance] disconnectPeripheral:[[CSRBluetoothLE sharedInstance] targetPeripheral]];
    [[CSRGaia sharedInstance] disconnectPeripheral];
    
    self.connectedPeripheral = nil;
}

- (void)abort {
    self.aborted = YES;
    
    [self stop];
    
    if (self.dataEndpointAvailable) {
        // Re-establish RWCP Connection
        [[QTIRWCP sharedInstance] abort];
    }
}

- (void)abortAndRestart {
    self.restart = YES;
    
    [self stop];
}

- (void)stop {
    if (self.updateInProgress) {
        NSLog(@"GaiaUpdate_AbortRequest > vmUpgradeControl");
        [self.dataBuffer removeAllObjects];
        [[CSRGaia sharedInstance] abort];
    }
}

- (void)commitConfirm:(BOOL)value {
    [self commitConfirmRequest:value];
}

- (void)eraseSqifConfirm {
    [self eraseSquifConf];
}

- (void)confirmError {
    NSMutableData *payload = [[NSMutableData alloc] init];
    uint16_t last_error = CFSwapInt16(self.lastError);
    
    [payload appendBytes:&last_error length:sizeof(uint16_t)];
    
    NSLog(@"GaiaUpdate_ErrorWarnResponse");
    
    [[CSRGaia sharedInstance]
     vmUpgradeControl:GaiaUpdate_ErrorWarnResponse
     length:sizeof(uint16_t)
     data:payload];
}

- (void)syncRequest {
    if (!self.syncRequested) {
        self.syncRequested = YES;
        self.fileIndex = 0;
        self.restart = NO;
        self.updateInProgress = YES;
        self.resumePoint = GaiaUpdateResumePoint_Start;
        NSLog(@"GaiaCommand_VMUpgradeConnect > GaiaUpdate_SyncRequest");
        [[CSRGaia sharedInstance] vmUpgradeControl:GaiaUpdate_SyncRequest];
    }
}

- (void)getLED {
    [[CSRGaia sharedInstance] getLEDState];
}

- (void)setLED:(BOOL)value {
    [[CSRGaia sharedInstance] setLED:value];
}

- (void)setVolume:(NSInteger)value {
    [[CSRGaia sharedInstance] setVolume:value];
}

- (void)getPower {
    [[CSRGaia sharedInstance] getPower];
}

- (void)setPowerOn:(BOOL)value {
    [[CSRGaia sharedInstance] setPowerOn:value];
}

- (void)getBattery {
    [[CSRGaia sharedInstance] getBattery];
}

- (void)getApiVersion {
    [[CSRGaia sharedInstance] getApiVersion];
}

- (void)avControl:(GaiaAVControlOperation)operation {
    [[CSRGaia sharedInstance] avControl:operation];
}

- (void)trimTWSVolume:(NSInteger)device volume:(NSInteger)value {
    [[CSRGaia sharedInstance] trimTWSVolume:device volume:value];
}

- (void)getTWSVolume:(NSInteger)device {
    [[CSRGaia sharedInstance] getTWSVolume:device];
}

- (void)setTWSVolume:(NSInteger)device volume:(NSInteger)value {
    [[CSRGaia sharedInstance] setTWSVolume:device volume:value];
}

- (void)getTWSRouting:(NSInteger)device {
    [[CSRGaia sharedInstance] getTWSRouting:device];
}

- (void)setTWSRouting:(NSInteger)device routing:(NSInteger)value {
    [[CSRGaia sharedInstance] setTWSRouting:device routing:value];
}

- (void)getBassBoost {
    [[CSRGaia sharedInstance] getBassBoost];
}

- (void)setBassBoost:(BOOL)value {
    [[CSRGaia sharedInstance] setBassBoost:value];
}

- (void)get3DEnhancement {
    [[CSRGaia sharedInstance] get3DEnhancement];
}

- (void)set3DEnhancement:(BOOL)value {
    [[CSRGaia sharedInstance] set3DEnhancement:value];
}

- (void)getAudioSource {
    [[CSRGaia sharedInstance] getAudioSource];
}

- (void)setAudioSource:(GaiaAudioSource)value {
    [[CSRGaia sharedInstance] setAudioSource:value];
}

- (void)findMe:(NSUInteger)value {
    [[CSRGaia sharedInstance] findMe:value];
}

- (void)getEQControl {
    [[CSRGaia sharedInstance] getEQControl];
}

- (void)setEQControl:(NSInteger)value {
    [[CSRGaia sharedInstance] setEQControl:value];
}

- (void)getEQParam:(NSData *)data {
    [[CSRGaia sharedInstance] getEQParam:data];
}

- (void)setEQParam:(NSData *)data {
    [[CSRGaia sharedInstance] setEQParam:data];
}

- (void)getGroupEQParam:(NSData *)data {
    [[CSRGaia sharedInstance] getGroupEQParam:data];
}

- (void)setGroupEQParam:(NSData *)data {
    [[CSRGaia sharedInstance] setGroupEQParam:data];
}

- (void)getUserEQ {
    [[CSRGaia sharedInstance] getUserEQ];
}

- (void)setUserEQ:(BOOL)value {
    [[CSRGaia sharedInstance] setUserEQ:value];
}

- (void)getDataEndPointMode {
    [[CSRGaia sharedInstance] getDataEndPointMode];
}

- (void)setDataEndPointMode:(BOOL)value {
    [[CSRGaia sharedInstance] setDataEndPointMode:value];
}

#pragma mark CSRConnectionManagerDelegate

- (void)discoveredPripheralDetails {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateStatus:)]) {
        [self.delegate didUpdateStatus:CSRStatusPairingString];
    }
    
    [CSRGaia sharedInstance].delegate = self;
    [[CSRGaia sharedInstance] connectPeripheral:[[CSRBluetoothLE sharedInstance] targetPeripheral]];
    
    if (self.disconnected) {
        if (self.dataEndpointAvailable) {
            // Re-establish RWCP Connection
            [[QTIRWCP sharedInstance]
             connectPeripheral:self.connectedPeripheral
             dataCharacteristic:[CSRGaia sharedInstance].dataCharacteristic];
            [QTIRWCP sharedInstance].delegate = self;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateStatus:)]) {
                [self.delegate didUpdateStatus:CSRStatusReStartingString];
            }
        }

        NSLog(@"GaiaEvent_VMUpgradeProtocolPacket > registerNotifications - discoveredPripheralDetails");
        self.registeredForNotifications = NO;
        [[CSRGaia sharedInstance] registerNotifications:GaiaEvent_VMUpgradeProtocolPacket];
    }
}

- (void)chracteristicChanged:(CBCharacteristic *)characteristic {
    if (self.waitingForReconnect) {
        self.waitingForReconnect = NO;
        
        if (!self.dataEndpointAvailable) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateStatus:)]) {
                [self.delegate didUpdateStatus:CSRStatusFinalisingString];
            }
        }
        
        NSLog(@"GaiaEvent_VMUpgradeProtocolPacket > registerNotifications - chracteristicChanged");
        self.registeredForNotifications = NO;
        [[CSRGaia sharedInstance] registerNotifications:GaiaEvent_VMUpgradeProtocolPacket];
    } else {
        [[CSRGaia sharedInstance] handleResponse:characteristic];
    }
}

- (void)delegatePeripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"didWriteValueForCharacteristic Error:%@\n\nThe Phone will now disconnect.", error.localizedDescription);
        [[CSRBluetoothLE sharedInstance] disconnectPeripheral];
        
        return;
    }
    
    if (   [characteristic isEqual:[CSRGaia sharedInstance].commandCharacteristic]
        && [self.dataBuffer count] > 0
        && self.disconnected == NO) {
        NSData *data = [self.dataBuffer firstObject];
        
        [self.dataBuffer removeObjectAtIndex:0];
        
        self.progress += GAIA_MAX_LENGTH;
        
        [[CSRGaia sharedInstance] sendData:data];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(didMakeProgress:eta:)]) {
            double fs = self.fileData.length;
            double fi = self.progress;
            double prog = (fi / fs) * 100.0;
            NSString *eta = [self calculateEta:fs fileIndex:fi];
            
            [self.delegate didMakeProgress:prog eta:eta];
        }
    }
}

- (void)didConnectToPeripheral:(CSRPeripheral *)peripheral {
    if (self.updateInProgress) {
        if (!self.disconnected) {
            NSLog(@"GaiaEvent_VMUpgradeProtocolPacket > registerNotifications - didConnectToPeripheral");
            self.registeredForNotifications = NO;
            [[CSRGaia sharedInstance] registerNotifications:GaiaEvent_VMUpgradeProtocolPacket];
        }
        
        // Discover services and characteristics.
        if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateStatus:)]) {
            [self.delegate didUpdateStatus:CSRStatusReconnectedString];
        }
    }
}

- (void)didPowerOff {
    [self didDisconnectFromPeripheral];
}

- (void)didPowerOn {
    [[CSRBluetoothLE sharedInstance] connectPeripheralNoCheck:self.connectedPeripheral];
}

- (void)didDisconnectFromPeripheral:(CBPeripheral *)peripheral {
    [self didDisconnectFromPeripheral];
}

- (void)didDisconnectFromPeripheral {
    if (self.updateInProgress) {
        self.waitingForReconnect = YES;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateStatus:)]) {
            [self.delegate didUpdateStatus:CSRStatusReconnectingString];
        }
        
        self.syncRequested = NO;
        self.disconnected = YES;
        self.fileIndex = 0;
        [[CSRBluetoothLE sharedInstance] connectPeripheralNoCheck:self.connectedPeripheral];
    } else {
        [self complete]; 
    }
}

- (void)chracteristicSetNotifySuccess:(CBCharacteristic *)characteristic {
    if ([characteristic isEqual:[CSRGaia sharedInstance].responseCharacteristic]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(gaiaReady)]) {
            [self.delegate gaiaReady];
        }
    }
}

#pragma mark CSRGaiaDelegate

- (void)didReceiveResponse:(CSRGaiaGattCommand *)command {
    GaiaCommandType cmdType = [command getCommandId];
    
    if ([command isControl]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didReceiveGaiaGattResponse:)]) {
            [self.delegate didReceiveGaiaGattResponse:command];
        }
    } else {
        if (   self.updateInProgress
            || self.restart
            || cmdType == GaiaCommand_VMUpgradeDisconnect
            || cmdType == GaiaCommand_CancelNotification) {
            if (self.disconnected) {
                if (cmdType == GaiaCommand_RegisterNotification) {
                    self.disconnected = NO;
                    self.startTime = [NSDate timeIntervalSinceReferenceDate];
                    NSLog(@"No longer skipping buffered commands");
                } else {
                    NSLog(@"Skipping command");
                    return;
                }
            }
            
            switch (cmdType) {
                case GaiaCommand_VMUpgradeConnect:
                    if ([self abortWithError:command] == 0) {
                        if (!self.syncRequested) {
                            NSLog(@"GaiaCommand_VMUpgradeConnect > GaiaUpdate_SyncRequest");
                            self.syncRequested = YES;
                            [[CSRGaia sharedInstance] vmUpgradeControl:GaiaUpdate_SyncRequest];
                        }
                    }
                    break;
                case GaiaCommand_VMUpgradeControl:
                    [self abortWithError:command];
                    break;
                case GaiaCommand_EventNotification:
                    if ([command event] == GaiaEvent_VMUpgradeProtocolPacket) { // Read off the update status from the beginning of the payload
                        switch ([command updateStatus]) {
                            case GaiaUpdate_SyncConfirm: // Battery level is also included in the response
                                NSLog(@"GaiaUpdate_StartRequest");
                                [self handleSyncConfirm:command];
                                break;
                            case GaiaUpdate_StartConfirm:
                                [self handleStartConfirm:command];
                                break;
                            case GaiaUpdate_DataBytesRequest:
                                if (self.dataEndpointAvailable) {
                                    [self dataBytesReguestRWCP:command];
                                } else {
                                    [self dataBytesReguest:command];
                                }
                                break;
                            case GaiaUpdate_AbortConfirm:
                                if (self.restart) {
                                    self.restart = NO;
                                    
                                    if (!self.registeredForNotifications) {
                                        NSLog(@"GaiaEvent_VMUpgradeProtocolPacket > registerNotifications - didReceiveResponse");
                                        [[CSRGaia sharedInstance] registerNotifications:GaiaEvent_VMUpgradeProtocolPacket];
                                    } else {
                                        self.syncRequested = NO;
                                        [self syncRequest];
                                    }
                                } else {
                                    [[CSRGaia sharedInstance] vmUpgradeDisconnect];
                                }
                                break;
                            case GaiaUpdate_ErrorWarnIndicator: // Any error will abort the upgrade.
                                [self abortWithError:command];
                                break;
                            case GaiaUpdate_ProgressConfirm:
                                [self readProgress:command];
                                break;
                            case GaiaUpdate_IsValidationDoneConfirm:
                                [self validationConfirm:command];
                                break;
                            case GaiaUpdate_TransferCompleteIndicator:
                                if (self.delegate && [self.delegate respondsToSelector:@selector(confirmTransferRequired)]) {
                                    [self.delegate confirmTransferRequired];
                                } else {
                                    [self updateTransferComplete];
                                }
                                break;
                            case GaiaUpdate_InProgressIndicator: // The device says it has rebooted.
                                [self updateComplete];
                                break;
                            case GaiaUpdate_CommitRequest:
                                if (self.delegate && [self.delegate respondsToSelector:@selector(confirmRequired)]) {
                                    [self.delegate confirmRequired];
                                } else {
                                    [self commitConfirmRequest:YES];
                                }
                                break;
                            case GaiaUpdate_HostEraseSquifRequest:
                                // Need to ask a question
                                if (self.delegate && [self.delegate respondsToSelector:@selector(okayRequired)]) {
                                    [self.delegate okayRequired];
                                } else {
                                    [self eraseSquifConf];
                                }
                                break;
                            case GaiaUpdate_CompleteIndicator:
                                NSLog(@"GaiaUpdate_CompleteIndicator > vmUpgradeDisconnect");
                                self.updateInProgress = NO;
                                [[CSRGaia sharedInstance] vmUpgradeDisconnect];
                                break;
                            default:
                                break;
                        }
                    }
                    break;
                case GaiaCommand_VMUpgradeDisconnect:
                    NSLog(@"GaiaCommand_VMUpgradeDisconnect > cancelNotification");
                    [[CSRGaia sharedInstance] cancelNotifications:GaiaEvent_VMUpgradeProtocolPacket];
                    break;
                case GaiaCommand_RegisterNotification:
                    self.registeredForNotifications = YES;
                    NSLog(@"GaiaCommand_RegisterNotification > vmUpgradeConnect");
                    [[CSRGaia sharedInstance] vmUpgradeConnect];
                    break;
                case GaiaCommand_CancelNotification:
                    NSLog(@"GaiaCommand_CancelNotification > upgrade complete...");
                    if (self.aborted) {
                        [self abortUpdate];
                        self.aborted = NO;
                    } else {
                        [self complete];
                    }
                    break;
                default:
                    break;
            }
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(didReceiveGaiaGattResponse:)]) {
                [self.delegate didReceiveGaiaGattResponse:command];
            }
        }
    }
}

- (void)resetUpdate {
    self.updateFileName = nil;
    self.updateInProgress = NO;
    self.updateProgress = 0.0;
    self.fileIndex = 0;
}

- (void)dataBytesReguest:(CSRGaiaGattCommand *)command {
    NSData *requestPayload = [command getPayload];
    uint32_t numberOfBytes = 0;
    uint32_t fileOffset = 0;
    
    [requestPayload getBytes:&numberOfBytes range:NSMakeRange(4, 4)];
    [requestPayload getBytes:&fileOffset range:NSMakeRange(8, 4)];
    
    numberOfBytes = CFSwapInt32BigToHost(numberOfBytes);
    fileOffset = CFSwapInt32BigToHost(fileOffset);
    
    NSRange dataRange = {fileOffset > 0 ? fileOffset + self.fileIndex : self.fileIndex, numberOfBytes};
    uint8_t dataBytes[numberOfBytes];
    
    NSLog(@"1Start: %lu length: %d filesize: %lu", (unsigned long)self.fileIndex, numberOfBytes, (unsigned long)self.fileData.length);
    
    if (fileOffset > 0) {
        self.fileIndex = self.fileIndex + fileOffset + numberOfBytes;
    } else {
        self.fileIndex += numberOfBytes;
    }
    
    if (dataRange.location + dataRange.length > self.fileData.length) {
        [self stop];
        [self.delegate didAbortWithError:[NSError
                                          errorWithDomain:CSRGaiaError
                                          code:2
                                          userInfo:@{CSRGaiaErrorParam: CSRGaiaError_2}]];
        return;
    }
    
    // Put the file data into the temporary buffer
    [self.fileData getBytes:&dataBytes range:dataRange];
    
    NSData *data = [NSData dataWithBytes:dataBytes length:numberOfBytes];
    uint8_t more_data = (uint8_t)GaiaCommandAction_Continue;
    NSInteger start = 0;
    
    while (start < numberOfBytes) {
        NSMutableData *payload = [[NSMutableData alloc] init];
        NSRange range = {start, start + GAIA_MAX_LENGTH > numberOfBytes ? numberOfBytes - start : GAIA_MAX_LENGTH};
        
        if (dataRange.location + start + GAIA_MAX_LENGTH >= self.fileData.length) {
            more_data = (uint8_t)GaiaCommandAction_Abort; // Sent all the data now
        }
        
        [payload appendBytes:&more_data length:1];
        [payload appendData:[data subdataWithRange:range]];
        
        [self.dataBuffer addObject:
         [[CSRGaia sharedInstance]
          vmUpgradeControlData:GaiaUpdate_Data
          length:range.length + 1
          data:payload]];
        
        start += GAIA_MAX_LENGTH;
    }

    if ([self.dataBuffer count] > 0) {
        NSData *data = [self.dataBuffer firstObject];
        
        [self.dataBuffer removeObjectAtIndex:0];
        
        self.progress += GAIA_MAX_LENGTH;
        [[CSRGaia sharedInstance] sendData:data];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didMakeProgress:eta:)]) {
        double fs = self.fileData.length;
//        double fi = (self.progress / fs) * 100.0;
//        NSString *eta = [self calculateEta:fs fileIndex:self.progress];
//        NSLog(@"~~> %f  %ld  %f  %hu",fs,self.fileData.length,fi,self.progress);
//        [self.delegate didMakeProgress:fi eta:eta];
        double fi = self.fileIndex / fs * 0.9 + 0.1; 
        [self.delegate didMakeProgress:fi eta:nil];
    }
    
    // Delay?
    if (self.fileIndex + start >= self.fileData.length) {
        if ([self.dataBuffer count] > 0) {
            NSLog(@"vmUpgradeControlData:GaiaUpdate_IsValidationDoneRequest");
            [self.dataBuffer addObject:
             [[CSRGaia sharedInstance]
              vmUpgradeControlData:GaiaUpdate_IsValidationDoneRequest
              length:0
              data:nil]];
        } else {
            NSLog(@"GaiaUpdate_IsValidationDoneRequest");
            [[CSRGaia sharedInstance] vmUpgradeControl:GaiaUpdate_IsValidationDoneRequest];
        }
    }
}

- (void)didMakeProgress:(double)value {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didMakeProgress:eta:)]) {
        double fs = self.fileData.length;
        double fi = value;
        double prog = (fi / fs) * 100.0;
        NSString *eta = [self calculateEta:fs fileIndex:fi];
        
        [self.delegate didMakeProgress:prog eta:eta];
    }
}

- (void)dataBytesReguestRWCP:(CSRGaiaGattCommand *)command {
    NSData *requestPayload = [command getPayload];
    uint32_t numberOfBytes = 0;
    uint32_t fileOffset = 0;
    
    [requestPayload getBytes:&numberOfBytes range:NSMakeRange(4, 4)];
    [requestPayload getBytes:&fileOffset range:NSMakeRange(8, 4)];
    
    numberOfBytes = CFSwapInt32BigToHost(numberOfBytes);
    fileOffset = CFSwapInt32BigToHost(fileOffset);
    
    NSRange dataRange = {fileOffset > 0 ? fileOffset + self.fileIndex : self.fileIndex, numberOfBytes};
    uint8_t dataBytes[numberOfBytes];
    
    NSLog(@"Start: %lu length: %d filesize: %lu", (unsigned long)self.fileIndex, numberOfBytes, (unsigned long)self.fileData.length);
    
    if (fileOffset > 0) {
        self.fileIndex = self.fileIndex + fileOffset + numberOfBytes;
    } else {
        self.fileIndex += numberOfBytes;
    }
    
    if (dataRange.location + dataRange.length > self.fileData.length) {
        [self stop];
        [self.delegate didAbortWithError:[NSError
                                          errorWithDomain:CSRGaiaError
                                          code:2
                                          userInfo:@{CSRGaiaErrorParam: CSRGaiaError_2}]];
        return;
    }
    
    // Put the file data into the temporary buffer
    [self.fileData getBytes:&dataBytes range:dataRange];
    
    NSData *data = [NSData dataWithBytes:dataBytes length:numberOfBytes];
    uint8_t more_data = (uint8_t)GaiaCommandAction_Continue;
    NSInteger start = 0;

    while (start <= numberOfBytes) {
        NSMutableData *payload = [[NSMutableData alloc] init];
        NSRange range = {start, start + RWCP_MAX_LENGTH > numberOfBytes ? numberOfBytes - start : RWCP_MAX_LENGTH};
        
        if (dataRange.location + start + RWCP_MAX_LENGTH >= self.fileData.length) {
            more_data = (uint8_t)GaiaCommandAction_Abort; // Sent all the data now
        }

        [payload appendBytes:&more_data length:1];
        [payload appendData:[data subdataWithRange:range]];

        if ([[QTIRWCP sharedInstance] availablePayloadBuffer]) {
            [[QTIRWCP sharedInstance]
             setPayload:[[CSRGaia sharedInstance]
                         vmUpgradeControlData:GaiaUpdate_Data
                         length:range.length + 1
                         data:payload]];
        } else {
            [[QTIRWCP sharedInstance].dataBuffer
             addObject:[[CSRGaia sharedInstance]
                        vmUpgradeControlData:GaiaUpdate_Data
                        length:range.length + 1
                        data:payload]];
        }

        start += RWCP_MAX_LENGTH;
    }
    
    if (more_data == GaiaCommandAction_Abort) {
        [QTIRWCP sharedInstance].lastByteSent = YES;
    }
}

- (NSString *)calculateEta:(double)fs fileIndex:(double)fi {
    NSString *eta = nil;
    double speed = fi / ([NSDate timeIntervalSinceReferenceDate] - self.startTime);
    double remainingInSeconds = (fs - fi) / speed;
    long long int s = [[NSString stringWithFormat:@"%f", remainingInSeconds] longLongValue];
    
    if (s < 60) {
        eta = [NSString stringWithFormat:@"%lld s", s];
    } else {
        if (s < 3600) {
            eta = [NSString stringWithFormat:@"%lld minutes remaining", s / 60];
        } else {
            long long int moduloS = s % 3600;
            eta = [NSString stringWithFormat:@"%lld h, %lld m remaining", s / 3600, moduloS / 60];
        }
    }
    
    return eta;
}

- (CSRGaiaGattCommand *)createCompleteCommand:(GaiaCommandUpdate)command
                                       length:(NSInteger)length
                                         data:(NSData *)data {
    NSMutableData *payload = [[NSMutableData alloc] init];
    uint8_t payload_event = (uint8_t)command;
    uint16_t len = CFSwapInt16(length);
    
    [payload appendBytes:&payload_event length:1];
    [payload appendBytes:&len length:2];
    
    if (data) {
        [payload appendData:data];
    }
    
    CSRGaiaGattCommand *cmd = [[CSRGaiaGattCommand alloc]
                               initWithLength:GAIA_GATT_HEADER_SIZE];
    
    if (cmd) {
        [cmd setCommandId:GaiaCommand_VMUpgradeControl];
        [cmd setVendorId:CSR_GAIA_VENDOR_ID];
        
        if (data) {
            [cmd addPayload:payload];
        }
    }
    
    return cmd;
}

- (NSInteger)abortWithError:(CSRGaiaGattCommand *)command {
    NSData *payload = [command getPayload];
    const unsigned char *data = (const unsigned char *)[payload bytes];
    NSInteger error_code = payload.length == 6 ? data[5] : data[1];
    self.lastError = error_code;
    
    if (error_code > GaiaUpdateResponse_Success) {
        NSString *errorMessage = nil;
        BOOL abortUpdate = YES;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(didAbortWithError:)]) {
            switch (error_code) {
                case GaiaUpdateResponse_Success:
                    NSLog(@"Success response decoded.");
                    break;
                case GaiaUpdateResponse_ErrorUnknownId:
                    errorMessage = CSRGaiaError_1;
                    break;
                case GaiaUpdateResponse_ErrorBadLength:
                    errorMessage = CSRGaiaError_2;
                    break;
                case GaiaUpdateResponse_ErrorWrongVariant:
                    errorMessage = CSRGaiaError_3;
                    break;
                case GaiaUpdateResponse_ErrorWrongPartitionNumber:
                    errorMessage = CSRGaiaError_4;
                    break;
                case GaiaUpdateResponse_ErrorPartitionSizeMismatch:
                    errorMessage = CSRGaiaError_5;
                    break;
                case GaiaUpdateResponse_ErrorPartitionTypeNotFound:
                    errorMessage = CSRGaiaError_6;
                    break;
                case GaiaUpdateResponse_ErrorPartitionOpenFailed:
                    errorMessage = CSRGaiaError_7;
                    break;
                case GaiaUpdateResponse_ErrorPartitionWriteFailed:
                    errorMessage = CSRGaiaError_8;
                    break;
                case GaiaUpdateResponse_ErrorPartitionCloseFailed:
                    errorMessage = CSRGaiaError_9;
                    break;
                case GaiaUpdateResponse_ErrorSFSValidationFailed:
                    errorMessage = CSRGaiaError_10;
                    break;
                case GaiaUpdateResponse_ErrorOEMValidationFailed:
                    errorMessage = CSRGaiaError_11;
                    break;
                case GaiaUpdateResponse_ErrorUpdateFailed:
                    errorMessage = CSRGaiaError_12;
                    break;
                case GaiaUpdateResponse_ErrorAppNotReady:
                    errorMessage = CSRGaiaError_13;
                    break;
                case GaiaUpdateResponse_WarnAppConfigVersionIncompatible:
                    errorMessage = CSRGaiaError_14;
                    break;
                case GaiaUpdateResponse_ErrorLoaderError:
                    errorMessage = CSRGaiaError_15;
                    break;
                case GaiaUpdateResponse_ErrorUnexpectedLoaderMessage:
                    errorMessage = CSRGaiaError_16;
                    break;
                case GaiaUpdateResponse_ErrorMissingLoaderMessage:
                    errorMessage = CSRGaiaError_17;
                    break;
                case GaiaUpdateResponse_ErrorBatteryLow:
                    errorMessage = CSRGaiaError_18;
                    abortUpdate = NO;
                    break;
                case GaiaUpdateResponse_ForceSync:
                    errorMessage = @"";
                    abortUpdate = NO;
                    break;
                default:
                    errorMessage = [NSString stringWithFormat:CSRGaiaError_Unknown, (long)error_code];
                    break;
            }
            
            if (errorMessage) {
                NSLog(@"Gaia update error: %ld %@", (long)error_code, errorMessage);
                
                if (abortUpdate) {
                    [self resetUpdate];
                }
                
                if (error_code == GaiaUpdateResponse_ForceSync) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(confirmForceUpgrade)]) {
                        [self.delegate confirmForceUpgrade];
                    }
                } else if (error_code == GaiaUpdateResponse_ErrorBatteryLow) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(confirmBatteryOkay)]) {
                        [self.delegate confirmBatteryOkay];
                    }
                } else {
                    [self.delegate didAbortWithError:[NSError
                                                      errorWithDomain:CSRGaiaError
                                                      code:error_code
                                                      userInfo:@{CSRGaiaErrorParam: errorMessage}]];
                }
            }
        }
    }
    
    return error_code;
}

- (void)readProgress:(CSRGaiaGattCommand *)command {
    NSData *payload = [command getPayload];
    const unsigned char *data = (const unsigned char *)[payload bytes];
    NSInteger prog = data[1];
    
    self.updateProgress = (double)prog / 100.0;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didMakeProgress:eta:)]) {
        [self.delegate didMakeProgress:prog eta:@""];
    }
}

- (void)updateTransferComplete {
    NSMutableData *payload = [[NSMutableData alloc] init];
    uint8_t payload_event = (uint8_t)GaiaCommandAction_Continue;
    
    [payload appendBytes:&payload_event length:1];
    
    // A warm reboot will follow
    self.connectedPeripheral = [[CSRBluetoothLE sharedInstance] targetPeripheral];
    
    NSLog(@"GaiaUpdate_TransferCompleteResult");
    
    [[CSRGaia sharedInstance]
     vmUpgradeControl:GaiaUpdate_TransferCompleteResult
     length:1
     data:payload];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didWarmBoot)]) {
        [self.delegate didWarmBoot];
    }
}

- (void)updateComplete {
    NSMutableData *payload = [[NSMutableData alloc] init];
    uint8_t payload_event = (uint8_t)GaiaCommandAction_Continue;
    
    [payload appendBytes:&payload_event length:1];
    
    NSLog(@"GaiaUpdate_InProgressResult");
    
    [[CSRGaia sharedInstance]
     vmUpgradeControl:GaiaUpdate_InProgressResult
     length:1
     data:payload];
}

- (void)complete {
    [self resetUpdate];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didCompleteUpgrade)]) {
        [self.delegate didCompleteUpgrade];
    }
    
    [[CSRBluetoothLE sharedInstance] setBleDelegate:nil];
}

- (void)abortUpdate {
    [self resetUpdate];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didAbortUpgrade)]) {
        [self.delegate didAbortUpgrade];
    }
    
    [[CSRBluetoothLE sharedInstance] setBleDelegate:nil];
}

- (void)eraseSquifConf {
    NSLog(@"GaiaUpdate_HostEraseSquifConfirm");
    
    [[CSRGaia sharedInstance]
     vmUpgradeControlNoData:GaiaUpdate_HostEraseSquifConfirm];
}

- (void)commitConfirmRequest:(BOOL)value {
    NSMutableData *payload = [[NSMutableData alloc] init];
    uint8_t payload_event = value ? (uint8_t)GaiaCommandAction_Continue : (uint8_t)GaiaCommandAction_Abort;
    
    [payload appendBytes:&payload_event length:1];
    
    NSLog(@"GaiaUpdate_CommitConfirm");
    
    [[CSRGaia sharedInstance]
     vmUpgradeControl:GaiaUpdate_CommitConfirm
     length:1
     data:payload];
}

- (void)handleStartConfirm:(CSRGaiaGattCommand *)command {
    if (self.resumePoint == GaiaUpdateResumePoint_Start) {
        NSData *requestPayload = [command getPayload];
        uint16_t length = 0;
        uint8_t status = 0;
        uint16_t batt = 0;
        
        [requestPayload getBytes:&length range:NSMakeRange(3, 2)];
        [requestPayload getBytes:&status range:NSMakeRange(4, 1)];
        [requestPayload getBytes:&batt range:NSMakeRange(5, 2)];
        
        if (status != GaiaUpdateResponse_Success) {
            [self abortWithError:command];
            [self resetUpdate];
        } else {
            NSLog(@"GaiaUpdate_StartDataRequest");
            self.startTime = [NSDate timeIntervalSinceReferenceDate];
            [[CSRGaia sharedInstance] vmUpgradeControlNoData:GaiaUpdate_StartDataRequest];
        }
    } else {
        switch (self.resumePoint) {
            case GaiaUpdateResumePoint_Start:
                [[CSRGaia sharedInstance] vmUpgradeControlNoData:GaiaUpdate_StartRequest];
                break;
            case GaiaUpdateResumePoint_Validate:
                [[CSRGaia sharedInstance] vmUpgradeControl:GaiaUpdate_IsValidationDoneRequest];
                break;
            case GaiaUpdateResumePoint_Reboot:
                if (self.delegate && [self.delegate respondsToSelector:@selector(confirmTransferRequired)]) {
                    [self.delegate confirmTransferRequired];
                } else {
                    [self updateTransferComplete];
                }
                break;
            case GaiaUpdateResumePoint_PostReboot:
                [self updateComplete];
                break;
            case GaiaUpdateResumePoint_Commit:
                [self commitConfirmRequest:YES];
                break;
            default:
                if (self.delegate && [delegate respondsToSelector:@selector(didAbortWithError:)]) {
                    NSString *msg = [NSString stringWithFormat:CSRGaiaError_UnknownResponse, (long)self.resumePoint];
                    
                    self.updateInProgress = NO;
                    [self.delegate didAbortWithError:[NSError
                                                      errorWithDomain:CSRGaiaError
                                                      code:0
                                                      userInfo:@{CSRGaiaErrorParam: msg}]];
                }
                break;
        }
    }
}

- (void)handleSyncConfirm:(CSRGaiaGattCommand *)command {
    NSData *requestPayload = [command getPayload];
    uint8_t state = 0;
    
    [requestPayload getBytes:&state range:NSMakeRange(4, 1)];
    
    // TODO: The protocol version number may be sent
    
    [[CSRGaia sharedInstance] vmUpgradeControlNoData:GaiaUpdate_StartRequest];
    
    self.resumePoint = state;
}

- (void)validationConfirm:(CSRGaiaGattCommand *)command {
    NSData *requestPayload = [command getPayload];
    uint16_t delay = 0;
    
    [requestPayload getBytes:&delay range:NSMakeRange(4, 2)];
    
    delay = CFSwapInt16HostToBig(delay);
    
    if (delay > 0) {
        [NSTimer scheduledTimerWithTimeInterval:delay / 1000
                                         target:self
                                       selector:@selector(validationDone:)
                                       userInfo:nil
                                        repeats:NO];
    }
}

- (void)validationDone:(NSTimer *)timer {
    NSLog(@"GaiaUpdate_IsValidationDoneRequest");
    [[CSRGaia sharedInstance] vmUpgradeControl:GaiaUpdate_IsValidationDoneRequest];
}

- (NSData *)MD5:(NSData *)data {
    unsigned char buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(data.bytes, (CC_LONG)data.length, buffer);
    
    NSMutableData *hv = [[NSMutableData alloc] init];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hv appendBytes:&buffer[i] length:sizeof(uint8_t)];
    }
    
    return hv;
}

- (void)didCompleteDataSend {
    NSLog(@"GaiaUpdate_IsValidationDoneRequest");
    [[CSRGaia sharedInstance] vmUpgradeControl:GaiaUpdate_IsValidationDoneRequest];
}

- (void)didAbortWithError:(NSError *)error {
    [self resetUpdate];
    [self.delegate didAbortWithError:error];
}

- (void)didUpdateStatus:(NSString *)value {
    [self.delegate didUpdateStatus:value];
}

@end
