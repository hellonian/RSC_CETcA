//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

//  Connect to a Mesh bridge, discover its services and characteristics then
// subcribe for notifcations on that characteristics
//
#import "CSRBluetoothLE.h"
#import <CSRmesh/MeshServiceApi.h>
#import "AppDelegate.h"
#import "CSRDatabaseManager.h"
#import "CSRBridgeRoaming.h"
#import "CSRmeshSettings.h"
#import "CSRConstants.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceEntity.h"

#import "OTAU.h"
#import "CSRUtilities.h"
#import "DeviceModelManager.h"
#import "DataModelManager.h"

#import "CSRGaia.h"
#import "CSRCallbacks.h"
#import "CSRBLEUtil.h"

// Uncomment to enable brige roaming
#define   BRIDGE_ROAMING_ENABLE
//#define BRIDGE_DISCONNECT_ALERT

    /****************************************************************************/
    /*			Private variables and methods									*/
    /****************************************************************************/
#define CSR_STORED_PERIPHERALS  @"StoredDevices"


@interface CSRBluetoothLE () <CBCentralManagerDelegate, CBPeripheralDelegate> {
	CBCentralManager    *centralManager;
    NSInteger beforeRssi;
    NSInteger lastRssi;
}

    // Set of objects that request the scanner to be turned On
    // Scanner will be turned off if there are no memebers in the Set
@property (atomic)  NSMutableSet  *scannerEnablers;

@property (nonatomic, strong) NSMutableDictionary *characteristicQueue;

@property (nonatomic, strong) NSMutableArray *collectionPeripherals;
@property (nonatomic, assign) BOOL startCollect;
@property (nonatomic, strong) NSString *macformcuupdateConnection;

@end


@implementation CSRBluetoothLE


    /****************************************************************************/
    /*			Instantiate properties using @synthesise                        */
    /****************************************************************************/
@synthesize discoveredBridges;
@synthesize bleDelegate;
@synthesize scannerEnablers;

    /****************************************************************************/
    /*								Interface Methods                           */
    /****************************************************************************/
    // First call will instantiate the one object & initialise it.
    // Subsequent calls will simply return a pointer to the object.

+ (id) sharedInstance {
	static CSRBluetoothLE	*this	= nil;
    
	if (!this)
    this = [[CSRBluetoothLE alloc] init];
    
	return this;
}
    
    
    //============================================================================
    // One time initialisation, called after instantiation of this singleton class
    //

- (id) init
{
    self = [super init];
    
    if (self) {
        
        _connectedPeripherals = [NSMutableArray array];
        [self powerOnCentralManager];
        discoveredBridges = [NSMutableArray array];
        scannerEnablers = [NSMutableSet set];
        
        //////////////////////////////////////////////////////////////////
        _foundPeripherals = [[NSMutableArray alloc] init];
        
        [[MeshServiceApi sharedInstance] setCentralManager:centralManager];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setScannerEnabledNotification:)
                                                     name:kCSRSetScannerEnabled
                                                   object:nil];

	}
    return self;
}

    
    //============================================================================
    // Connect peripheral, if already connected then disconnect first.
    // This should be called when the user selects a bridge
//-(void) connectPeripheral:(CBPeripheral *) peripheral {
//
////    if ([[CSRmeshSettings sharedInstance] getBleListenMode] == CSRBleListenMode_ScanNotificationListen) {
//
////    } else {
//     if ([[CSRmeshSettings sharedInstance] getBleConnectMode]==CSR_BLE_CONNECTIONS_MANUAL) {
//        for (CBPeripheral *connectedPeripheral in _connectedPeripherals) {
//            if (connectedPeripheral && connectedPeripheral.state != CBPeripheralStateConnected)
//                [centralManager cancelPeripheralConnection:peripheral];
//        }
//
//        [_connectedPeripherals removeAllObjects];
//
//        if ([peripheral state]!=CBPeripheralStateConnected) {
//            [centralManager connectPeripheral:peripheral options:nil];
//        }
//    }
//
//}

    //============================================================================
    // Connect peripheral without checking how many are connected
-(void) connectPeripheralNoCheck:(CBPeripheral *) peripheral {
    if ([peripheral state]!=CBPeripheralStateConnected) {
        [centralManager connectPeripheral:peripheral options:nil];
    }
    if (_isForGAIA) {
        [self.characteristicQueue removeAllObjects];
        [self.listening removeAllObjects];
    }
}



    //============================================================================
    // Disconnect the given peripheral.
-(void) disconnectPeripheral:(CBPeripheral *) peripheral {
    NSLog(@"主动断开");
    if (_isForGAIA) {
        [self clearListeners];
    }
    [centralManager cancelPeripheralConnection:peripheral];
    if (_isForGAIA) {
        self.targetPeripheral = nil;
    }
}

- (void)disconnectPeripheralForMCUUpdate:(NSString *)mac {
    _startCollect = NO;
    _macformcuupdateConnection = mac;
    if ([_connectedPeripherals count]>0) {
        for (CBPeripheral *peripheral in _connectedPeripherals) {
            [centralManager cancelPeripheralConnection:peripheral];
        }
    }
}

- (void)cancelMCUUpdate {
    _startCollect = YES;
    _macformcuupdateConnection = nil;
}

- (void)successMCUUpdate {
    _macformcuupdateConnection = nil;
}

    //============================================================================
    // With exception of connected peripheral, remove all discovered peripherals
-(void) removeDiscoveredPeripheralsExceptConnected {
    
    [discoveredBridges removeAllObjects];
    
    for (CBPeripheral *connectedPeripheral in _connectedPeripherals) {
        if (connectedPeripheral && connectedPeripheral.state == CBPeripheralStateConnected)
            [discoveredBridges addObject:connectedPeripheral];
    }
}

    //============================================================================
    // Start Scan
-(void) startScan {
    NSLog (@"Start Scan");
    @synchronized(self) {
        if ([centralManager state] == CBCentralManagerStatePoweredOn) {
            //////////////////////////////////////////////////////////////////
            if (!_macformcuupdateConnection) {
                [self.collectionPeripherals removeAllObjects];
                _startCollect = YES;
            }
            
            if (_isUpdateFW) {
                [_foundPeripherals removeAllObjects];
            }
            
            CBUUID *uuid = [CBUUID UUIDWithString:@"FEF1"];
            CBUUID *uuid1 = [CBUUID UUIDWithString:@"00001016-D102-11E1-9B23-00025B00A5A5"];
            NSDictionary *options = [self createDiscoveryOptions];
            [centralManager scanForPeripheralsWithServices:@[uuid,uuid1] options:options];
        }
    }
}


    //============================================================================
    // Stop Scan
-(void) stopScan {
    @synchronized(self) {
        _startCollect = NO;
        _macformcuupdateConnection = nil;
        [centralManager stopScan];
    }
    NSLog (@"Stop Scan");
}

- (void)powerOnCentralManager
{
    if (centralManager) {
        
        [self powerOffCentralManager];
        
    }
    
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
}

- (void)powerOffCentralManager
{
    if (centralManager) {
        
        centralManager = nil;
        
    }
    
}


//============================================================================
// Create an NSDictionary of options that we wish to apply when scanning for advertising peripherals
-(NSDictionary *) createDiscoveryOptions {
    
    NSNumber *yesOption = @YES;
    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey : yesOption};
    return (options);
}



    /****************************************************************************/
    /*								Callbacks                                   */
    /****************************************************************************/

    //============================================================================
    // This callback when the Bluetooth Module changes State (normally power state)
    // Bluetooth Module change of state
    // Mainly used to check the Bluetooth is powered up and to alert the user if it is not.

- (void) centralManagerDidUpdateState:(CBCentralManager *)central {
    static CBCentralManagerState previousState = -1;
    
    switch ([centralManager state]) {
        case CBCentralManagerStatePoweredOff: {
            NSLog(@"Central Powered OFF");
            if (_isUpdateFW) {
                [_foundPeripherals removeAllObjects];
                if (_isForGAIA && self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(didPowerOff)]) {
                    [self.bleDelegate didPowerOff];
                }
            }else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CBCentralManagerStatePoweredOff" object:nil];
            }
            
            break;
        }
        
        case CBCentralManagerStateUnauthorized: {
            /* Tell user the app is not allowed. */
            break;
        }
        
        case CBCentralManagerStateUnknown: {
            /* Bad news, let's wait for another event. */
            break;
        }
        
        case CBCentralManagerStatePoweredOn: {
            NSLog(@"Central powered ON");
            if (_isUpdateFW) {
                [_foundPeripherals removeAllObjects];
                if (_isForGAIA && self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(didPowerOn)]) {
                    [self.bleDelegate didPowerOn];
                }
            }
            _startCollect = YES;
            CBUUID *uuid = [CBUUID UUIDWithString:@"FEF1"];
            CBUUID *uuid1 = [CBUUID UUIDWithString:@"00001016-D102-11E1-9B23-00025B00A5A5"];
            NSDictionary *options = [self createDiscoveryOptions];
            [centralManager scanForPeripheralsWithServices:@[uuid,uuid1] options:options];
            
            break;
        }
        
        case CBCentralManagerStateResetting: {
            NSLog(@"Central Resetting");
//            [self discoveryDidRefresh];
            break;
        }
        
        case CBCentralManagerStateUnsupported:
        break;
        
    }
    
    previousState = (CBCentralManagerState)[centralManager state];
    self.cbCentralManagerState = previousState;
}
    

    //============================================================================
    // This callback occurs on discovery of a Peripheral.
    // If the Peripheral is a Mesh Bridge then
    //  - save it
    //  - go on to discover Services and then Characteristics
    //  - Inform delegate of new discovery (for UI refresh)

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
//    NSLog(@"%@",advertisementData);
    [peripheral setRssi:RSSI];
    NSString *adString;
    if (advertisementData[@"kCBAdvDataManufacturerData"]) {
        NSData *adData = advertisementData[@"kCBAdvDataManufacturerData"];
        if ([adData length]>6) {
            adString = [[CSRUtilities hexStringForData:adData] uppercaseString];
            [peripheral setUuidString:adString];
        }
    }
    if (self.isUpdateFW && peripheral.name != nil) {
        if (![_foundPeripherals containsObject:peripheral]) {
            [_foundPeripherals addObject:peripheral];
            [self discoveryDidRefresh:peripheral];
        }
    }else if (self.isNearbyFunction && peripheral.name != nil && [CSRUtilities belongToNearbyFunctionDevice:peripheral.name]) {
        [self discoveryDidRefresh:peripheral];
    }else if ([RSSI integerValue]>-80 && peripheral.name != nil && [RSSI integerValue] != 127) {
        
        NSMutableDictionary *enhancedAdvertismentData = [NSMutableDictionary dictionaryWithDictionary:advertisementData];
        enhancedAdvertismentData [CSR_PERIPHERAL] = peripheral;
        
        NSNumber *messageStatus = [[MeshServiceApi sharedInstance] processMeshAdvert:enhancedAdvertismentData RSSI:RSSI];
        if ([messageStatus integerValue] == IS_BRIDGE_DISCOVERED_SERVICE) {
            [peripheral setIsBridgeService:@(YES)];
        } else {
            [peripheral setIsBridgeService:@(NO)];
        }
        
        if ([messageStatus integerValue] == IS_BRIDGE || [messageStatus integerValue] == IS_BRIDGE_DISCOVERED_SERVICE) {
#ifdef BRIDGE_ROAMING_ENABLE
            
//            if ([peripheral.uuidString length]>11 && [[peripheral.uuidString substringToIndex:12] isEqualToString:@"002006060223"]) {
//                [[CSRBridgeRoaming sharedInstance] didDiscoverBridgeDevice:central peripheral:peripheral advertisment:advertisementData RSSI:RSSI];
//            }
//            [[CSRBridgeRoaming sharedInstance] didDiscoverBridgeDevice:central peripheral:peripheral advertisment:advertisementData RSSI:RSSI];
            
            if (_startCollect) {
                if ([self.collectionPeripherals count] == 0) {
                    [self performSelector:@selector(connectBridgeAction) withObject:nil afterDelay:1];
                }
                NSDictionary *dic = @{@"RSSI":RSSI,@"peripheral":peripheral,@"advertisementData":advertisementData};
                if (![self.collectionPeripherals containsObject:dic]) {
                    [self.collectionPeripherals addObject:dic];
                }
                
            }else if (_macformcuupdateConnection) {
                if ([peripheral.uuidString length]>11 && [[peripheral.uuidString substringToIndex:12] isEqualToString:_macformcuupdateConnection]) {
                    [[CSRBridgeRoaming sharedInstance] didDiscoverBridgeDevice:central peripheral:peripheral advertisment:advertisementData RSSI:RSSI];
                }
            }
            
            
#endif
            
            if (![discoveredBridges containsObject:peripheral]) {
                [discoveredBridges addObject:peripheral];
            }
            [peripheral setLocalName:advertisementData[CBAdvertisementDataLocalNameKey]];
//            if(bleDelegate && [bleDelegate respondsToSelector:@selector(discoveredBridge)]) {
//                [bleDelegate discoveredBridge];
//            }
            
        }
    }
    
}

    //============================================================================
    // This callback occurs if the RSSI has changed
//- (void) peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
//
//    if(bleDelegate && [bleDelegate respondsToSelector:@selector(discoveredBridge)]) {
//        [bleDelegate discoveredBridge];
//    }
//}

- (void)readRssi:(CBPeripheral *)peripheral {
    if (!_isUpdateFW && !_isNearbyFunction) {
        [peripheral readRSSI];
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    
    [peripheral setRssi:RSSI];
//    NSLog(@"RSSI returned %@", [RSSI stringValue]);
    
    if (beforeRssi < -90 && lastRssi < -90 && [RSSI integerValue] < -90) {
        [self disconnectPeripheral:peripheral];
    }else {
        beforeRssi = lastRssi;
        lastRssi = [RSSI integerValue];
    }
}

    //============================================================================
    // This callback occurs on a Successful connection to a Mesh bridge device
    // - remove connection to other Mesh Bridges, if these exist.
    // - go on to Discover the Mesh Service
    // - and inform delegate of new connection (for UI refresh)

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"did connect peripheral %@",peripheral.name);
    [central stopScan];
    // if also connected to another Bridge then disconnect from that.
    
    if (_isUpdateFW) {
        if (_isForGAIA) {
            peripheral.delegate = self;
            [peripheral discoverServices:nil];
            if (self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(didConnectToPeripheral:)]) {
                [self.bleDelegate didConnectToPeripheral:peripheral];
            }
        }else {
            self.discoveredChars = [NSNumber numberWithBool:NO];
            peripheral.delegate=self;
            
            if (peripheral.services.count==0) {
                [peripheral discoverServices:nil];
            }
            else {
                for (CBService *service in peripheral.services) {
                    NSLog(@"didConnectPeripheral_service: %@",service.UUID);
                }
            }
            
            [self didConnectPeripheral:peripheral];
        }
        
    }else if (_isNearbyFunction) {
        peripheral.delegate = self;
        [peripheral discoverServices:nil];
//        [peripheral discoverServices:@[[CBUUID UUIDWithString:@"00001100-d102-11e1-9b23-00025b00a5a5"]]];
    }else {

    [_connectedPeripherals addObject:peripheral];
    
    peripheral.delegate=self;
    
    [peripheral discoverServices:nil];
    
#ifdef BRIDGE_ROAMING_ENABLE
        [[CSRBridgeRoaming sharedInstance] connectedPeripheral:peripheral];
        NSLog (@"BRIDGE CONNECTED %@  %@",peripheral.name,peripheral.uuidString);
        [self.collectionPeripherals removeAllObjects];
//        [[DeviceModelManager sharedInstance] getAllDevicesState];
        
#endif
    
//    if(bleDelegate && [bleDelegate respondsToSelector:@selector(discoveredBridge)])
//        [bleDelegate discoveredBridge];

    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Attempted connection to peripheral %@ failed: %@", [peripheral name], [error localizedDescription]);
}

    //============================================================================
    // This callback occurs on a Successful disconnection to a Peripheral
- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"did disconnect Peripheral %@\n",peripheral.name);
    if(_isUpdateFW) {
        if (_isForGAIA) {
            [self clearListeners];
            if (self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(didDisconnectFromPeripheral:)]) {
                [self.bleDelegate didDisconnectFromPeripheral:peripheral];
            }
        }else {
            [self didDisconnectPeripheral:peripheral withError:error];
        }
        
    }else {
        if ([_connectedPeripherals containsObject:peripheral]) {
            [_connectedPeripherals removeObject:peripheral];
            [[MeshServiceApi sharedInstance] disconnectBridge:peripheral];
            
            //#ifdef  BRIDGE_DISCONNECT_ALERT
            NSLog (@"BRIDGE DISCONNECTED : %@",peripheral.name);
            if (!_macformcuupdateConnection) {
                _startCollect = YES;
            }
            
            //#endif
            
            // Call up Bridge Select View
            //#ifdef BRIDGE_ROAMING_ENABLE
            [[CSRBridgeRoaming sharedInstance] disconnectedPeripheral:peripheral];
            //#endif
            
            // Call up Bridge Select View
            if (_connectedPeripherals.count==0)
                [[NSNotificationCenter defaultCenter] postNotificationName:@"BridgeDisconnectedNotification" object:nil];
        }
    }
}

    //============================================================================
    // peripheral:discoverServices initiated this callback

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (_isUpdateFW) {
        if (error == nil) {
            if (_isForGAIA) {
                if (peripheral.state == CBPeripheralStateConnected) {
                    for (CBService *service in peripheral.services) {
                        NSLog(@"Service %@", service.UUID);
                        [peripheral discoverCharacteristics:nil forService:service];
                    }
                }
            }else {
                CBUUID *uuid = [CBUUID UUIDWithString:serviceApplicationOtauUuid];
                CBUUID *bl_uuid = [CBUUID UUIDWithString:serviceBootOtauUuid];
                for (CBService *service in peripheral.services) {
                    NSLog(@"didDiscoverServices_service: %@",service.UUID);
                    if ([service.UUID isEqual:uuid]) {
                        self.peripheralInBoot = [NSNumber numberWithBool:NO];
                        [peripheral discoverCharacteristics:nil forService:service];
                        self.targetService = service;
                    }else if ([service.UUID isEqual:bl_uuid]) {
                        self.peripheralInBoot = [NSNumber numberWithBool:YES];
                        [peripheral discoverCharacteristics:nil forService:service];
                        self.targetService = service;
                    }
                }
            }
        }else {
            NSLog(@"%@ Error = %@", peripheral.name, [error userInfo]);
        }
    }else if (_isNearbyFunction) {
        for (CBService *service in peripheral.services) {
            if ([[service UUID] isEqual:[CBUUID UUIDWithString:@"00001100-d102-11e1-9b23-00025b00a5a5"]]) {
                [peripheral discoverCharacteristics:nil forService:service];
                break;
            }
        }
    }else {
        if (error == nil) {
            if (peripheral.state==CBPeripheralStateConnected) {
                for (CBService *service in peripheral.services) {
                    [peripheral discoverCharacteristics:nil forService:service];

                }
            }
        }
    }
}
    

    //============================================================================
    // discoverCharacteristics initiated this callback

#define MESH_MTL_CHAR_ADVERT        @"C4EDC000-9DAF-11E3-800A-00025B000B00"

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (_isUpdateFW) {
        if (error == nil) {
            if (_isForGAIA) {
                for (CBCharacteristic *charateristic in service.characteristics) {
                    NSLog(@"charateristic: %@",charateristic.UUID);
                    [peripheral discoverDescriptorsForCharacteristic:charateristic];
                }
                self.targetPeripheral = peripheral;
                
                if (self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(discoveredPripheralDetails)]) {
                    [self.bleDelegate discoveredPripheralDetails];
                }
                
            }else {
                for (CBCharacteristic *charateristic in service.characteristics) {
                    NSLog(@"charateristic: %@",charateristic.UUID);
                }
                CBUUID *uuid = [CBUUID UUIDWithString:serviceApplicationOtauUuid];
                CBUUID *bl_uuid = [CBUUID UUIDWithString:serviceBootOtauUuid];
                
                if ([service.UUID isEqual:uuid] || [service.UUID isEqual:bl_uuid]) {
                    [centralManager stopScan];
                    self.targetPeripheral = peripheral;
                    self.discoveredChars = [NSNumber numberWithBool:YES];
                    if (!_secondConnectBool) {
                        [[OTAU shareInstance] initOTAU:peripheral];
                    }
                }
            }
        }
    }else if (_isNearbyFunction) {
        for (CBCharacteristic *charateristic in service.characteristics) {
            if ([charateristic.UUID isEqual:[CBUUID UUIDWithString:@"00001101-d102-11e1-9b23-00025b00a5a5"]]) {
                NSLog(@"发现特征");
                [peripheral readValueForCharacteristic:charateristic];
                Byte byte[] = {0xee, 0xaa, 0x01, 0x01};
                NSData *data = [[NSData alloc] initWithBytes:byte length:4];
                [peripheral writeValue:data forCharacteristic:charateristic type:CBCharacteristicWriteWithResponse];
                break;
            }
            [peripheral discoverDescriptorsForCharacteristic:charateristic];
        }
    }else {
        if (error == nil && [service.UUID.UUIDString isEqualToString:@"FEF1"]) {
                    [[MeshServiceApi sharedInstance] connectBridge:peripheral enableBridgeNotification:@([[CSRmeshSettings sharedInstance] getBleListenMode])];
                    // Inform BridgeRoaming that a peripheral has disconnected
                    
                    for (CBCharacteristic *characteristic in service.characteristics) {
                        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:MESH_MTL_CHAR_ADVERT]]) {
                            [self subscribeToMeshSimNotifyChar:peripheral :characteristic];
                        }
                    }
                    
                    [peripheral setIsBridgeService:@(YES)];
                    
        #ifdef BRIDGE_ROAMING_ENABLE
                    [[CSRBridgeRoaming sharedInstance] connectedPeripheral:peripheral];
        #endif
                    if (_connectedPeripherals.count>0) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"BridgeConnectedNotification" object:nil userInfo:@{@"peripheral":peripheral}];
                    }
                    
        //            if ([service.UUID.UUIDString isEqualToString:@"FEF1"]) {
                        [[DataModelManager shareInstance] setDeviceTime];
                        [[DeviceModelManager sharedInstance] getAllDevicesState];
        //            }
                    
                }
    }
}
    

    //============================================================================
    // set scan enabled notification from Library
-(void) setScannerEnabledNotification :(NSNotification *)notification
{
    NSNumber *enabledNumber = notification.userInfo [kCSRSetScannerEnabled];
    BOOL    enabled = [enabledNumber boolValue];
    [self setScanner:enabled source:[MeshServiceApi sharedInstance]];
}


    //============================================================================
    // Manage Scanner Enable/Disable control
-(void) setScanner:(BOOL)stateRequired source:(id) source {
    
    BOOL    scannerCurrentState, scannerNewState;
    scannerCurrentState = (scannerEnablers.count > 0);
    
    if (stateRequired==YES)
        [scannerEnablers addObject:source];
    else
        [scannerEnablers removeObject:source];
    
    scannerNewState = (scannerEnablers.count > 0);
    
    if (scannerCurrentState != scannerNewState){
        if (scannerNewState == YES) {
            [self startScan];
            NSLog (@"Scan ON");
        }
        else {
            [self stopScan];
            NSLog (@"Scan OFF");
        }
    }
}


    //============================================================================
    // MeshSimulator Notification Charactersitic
-(void) subscribeToMeshSimNotifyChar :(CBPeripheral *) peripheral :(CBCharacteristic *) characteristic {
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (_isForGAIA) {
        if (!error) {
            NSLog(@"didUpdateNotificationStateForCharacteristic %@ %@", characteristic, characteristic.UUID);
            if (characteristic.isNotifying) {
                if (!characteristic.value) {
                    [peripheral
                     readValueForCharacteristic:characteristic];
                } else {
                    if ([self.listening objectForKey:characteristic.UUID.UUIDString]) {
                        if (self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(chracteristicChanged:)]) {
                            [self.bleDelegate chracteristicChanged:characteristic];
                        }
                    }
                }
            }
            if (self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(chracteristicSetNotifySuccess:)]) {
                [self.bleDelegate chracteristicSetNotifySuccess:characteristic];
            }
        }
    }
    
}

    //============================================================================
    // Incoming Mesh packets can also be received as bridge notifications.
    // If so, then an advertimentData dictionary should be built with
    //     Key = CBAdvertisementDataServiceDataKey object = (dictionary with key=0xfef1 object=value)
    //     Key = CBAdvertisementDataIsConnectable object = NSNumber of the BOOL NO
    //     Key = @"didUpdateValueForCharacteristic" object = handle to the characeterisic
-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
//    NSLog(@"didUpdateValueForCharacteristic for peripheral %@ & Characteristic %@ value=%@",peripheral.name, characteristic.UUID, characteristic.value);

    if (_isForGAIA) {
        CSRCallbacks *cbs = [self.characteristicQueue objectForKey:characteristic.UUID.UUIDString];
        if (!error) {
            if ([self.listening objectForKey:characteristic.UUID.UUIDString]) {
                if (self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(chracteristicChanged:)]) {
                    [self.bleDelegate chracteristicChanged:characteristic];
                }
            }
            if (cbs) {
                if (cbs.successCallback) {
                    switch (cbs.callbackType) {
                        case CSRCallbackType_Bool: {
                            CSRGetBoolCompletion cb = cbs.successCallback;
                            
                            cb([CSRBLEUtil boolValue:characteristic.value]);
                            break;
                        }
                        case CSRCallbackType_Int: {
                            CSRGetIntCompletion cb = cbs.successCallback;
                            
                            cb([CSRBLEUtil intValue:characteristic.value]);
                            break;
                        }
                        case CSRCallbackType_Double: {
                            CSRGetIntCompletion cb = cbs.successCallback;
                            
                            cb([CSRBLEUtil doubleValue:characteristic.value offset:0]);
                            break;
                        }
                        case CSRCallbackType_String: {
                            CSRGetStringCompletion cb = cbs.successCallback;
                            
                            cb([CSRBLEUtil stringValue:characteristic.value]);
                            break;
                        }
                            
                        case CSRCallbackType_Data: {
                            
                            CSRGetDataCompletion cb = cbs.successCallback;
                            
                            cb(characteristic.value);
                            break;
                            
                        }
                            
                        case CSRCallbackType_SetInt:
                        case CSRCallbackType_SetBool:
                        case CSRCallbackType_SetData:
                        case CSRCallbackType_SetString: {
                            CSRSetValueCompletion cb = cbs.successCallback;
                            
                            cb();
                            break;
                        }
                    }
                }
                
                [self.characteristicQueue removeObjectForKey:characteristic.UUID.UUIDString];
            }
        }else {
            NSLog(@"didUpdateValueForCharacteristic error: %@", error.localizedDescription);
            
            if (cbs) {
                if (cbs.failureCallback) {
                    CSRErrorCompletion cc = cbs.failureCallback;
                    
                    cc(error);
                }
                
                [self.characteristicQueue removeObjectForKey:characteristic.UUID.UUIDString];
            }
        }
    }else if(!_isNearbyFunction) {
        NSMutableDictionary *advertisementData = [NSMutableDictionary dictionary];
        
        [advertisementData setObject:@(NO) forKey:CBAdvertisementDataIsConnectable];
        
        advertisementData [CBAdvertisementDataIsConnectable] = @(NO);
        [advertisementData setObject:characteristic.value forKey:CSR_NotifiedValueForCharacteristic];
        [advertisementData setObject:characteristic forKey:CSR_didUpdateValueForCharacteristic];
        [advertisementData setObject:peripheral forKey:CSR_PERIPHERAL];
        [[MeshServiceApi sharedInstance] processMeshAdvert:advertisementData RSSI:nil];
    }
}






///////////////////////////////////////////////////////////////////
-(void) retrieveCachedPeripherals {
    NSArray *services = [[NSArray alloc] initWithObjects:
                         [CBUUID UUIDWithString:serviceApplicationOtauUuid], nil];

    [self retrieveConnectedPeripheral:services];
}

///////////////////////////////////////////////////////////////////

-(NSArray *) retrievePeripheralsWithIdentifier:(NSUUID *) uuid {
    NSLog(@"Retrieve peripherals with UUID=%@",[uuid UUIDString]);
    NSArray *peripheralIdentifiers = [[NSArray alloc]initWithObjects:uuid, nil];

    return([centralManager retrievePeripheralsWithIdentifiers:peripheralIdentifiers]);

}

-(void) retrieveConnectedPeripheral:(NSArray *) services {
    NSLog(@"Retrieve Connected Peripherals %@", services);
    NSArray *peripherals = [centralManager retrieveConnectedPeripheralsWithServices:services];
    if (peripherals) {
        for (CBPeripheral *peripheral in peripherals) {
            [_foundPeripherals addObject:peripheral];
        }
//        [self discoveryDidRefresh];
    }
}

- (void)startOTAUTest: (CBPeripheral *) peripheral {
    if (peripheral.state != CBPeripheralStateConnected) {
        [self connectPeripheralNoCheck:peripheral];
    }
    else {
        if (peripheral.services.count<1) {
            [peripheral discoverServices:nil];
        }
    }
}



///////////////////////////////////////////////////////////////////

-(void) didConnectPeripheral:(CBPeripheral *) peripheral {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        if(self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(didConnectPeripheral:)])
            [self.bleDelegate didConnectPeripheral:peripheral];
    }];
}

-(void) didDisconnectPeripheral:(CBPeripheral *)peripheral withError:(NSError *)error {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        if(self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(didDisconnectPeripheral:withError:)])
            [self.bleDelegate didDisconnectPeripheral:peripheral withError:error];
    }];
}

-(void) discoveryDidRefresh:(CBPeripheral *) peripheral {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        if(self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(discoveryDidRefresh:)]) {
            [self.bleDelegate discoveryDidRefresh:peripheral];
        }
    }];
}

- (CBService *)findService:(CBPeripheral *)peripheral
                      uuid:(NSString *)service_uuid {
    @try {
        CBUUID *serviceUUID = [CBUUID UUIDWithString:service_uuid];
        
        for (CBService *service in peripheral.services) {
            if ([service.UUID isEqual:serviceUUID]) {
                return service;
            }
        }
    } @catch(NSException *ex) {
        for (CBService *service in peripheral.services) {
            if ([service.UUID.UUIDString isEqualToString:service_uuid]) {
                return service;
            }
        }
    }
    
    return nil;
}

- (CBService *)findService:(NSString *)service_uuid {
    return [self findService:self.targetPeripheral
                        uuid:service_uuid];
}

- (CBCharacteristic *)findCharacteristic:(CBService *)service
                          characteristic:(NSString *)characteristic_uuid {
    @try {
        CBUUID *characteristicUUID = [CBUUID UUIDWithString:characteristic_uuid];
        
        for (CBCharacteristic *character in service.characteristics) {
            if ([character.UUID isEqual:characteristicUUID]) {
                return character;
            }
        }
    } @catch(NSException *ex) {
        for (CBCharacteristic *character in service.characteristics) {
            if ([character.UUID.UUIDString isEqualToString:characteristic_uuid]) {
                return character;
            }
        }
    }
    
    return nil;
}

- (BOOL)listenFor:(NSString *)service_uuid
   characteristic:(NSString *)charactaristic_uuid {
    CBService *service = [self findService:service_uuid];
    
    if (service) {
        CBCharacteristic *characteristic = [self findCharacteristic:service characteristic:charactaristic_uuid];
        
        if (characteristic) {
            CBCharacteristic *listener = [self.listening objectForKey:characteristic.UUID.UUIDString];
            
            if (!listener || !listener.isNotifying) {
                [self.listening setObject:characteristic forKey:characteristic.UUID.UUIDString];
                [self.targetPeripheral
                 setNotifyValue:YES
                 forCharacteristic:characteristic];
            }
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (NSMutableDictionary *)listening {
    if (!_listening) {
        _listening = [[NSMutableDictionary alloc] init];
    }
    return _listening;
}

- (NSMutableDictionary *)characteristicQueue {
    if (!_characteristicQueue) {
        _characteristicQueue = [[NSMutableDictionary alloc] init];
    }
    return _characteristicQueue;
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (_isForGAIA) {
        if (self.characteristicQueue.count > 0) {
            CSRCallbacks *cbs = [self.characteristicQueue objectForKey:characteristic.UUID.UUIDString];
            
            if (error) {
                NSLog(@"didWriteValueForCharacteristic error: %@", error.localizedDescription);
                
                if (cbs) {
                    if (cbs.failureCallback) {
                        CSRErrorCompletion cc = cbs.failureCallback;
                        
                        cc(error);
                    }
                    
                    [self.characteristicQueue removeObjectForKey:characteristic.UUID.UUIDString];
                }
            } else {
                if (cbs) {
                    if (cbs.successCallback) {
                        CSRSetValueCompletion sv = cbs.successCallback;
                        
                        sv();
                    }
                    
                    [self.characteristicQueue removeObjectForKey:characteristic.UUID.UUIDString];
                }
            }
        }
        if (self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(delegatePeripheral:didWriteValueForCharacteristic:error:)]) {
            [self.bleDelegate delegatePeripheral:peripheral didWriteValueForCharacteristic:characteristic error:error];
        }
    }else if (_isNearbyFunction) {
        [self disconnectPeripheral:peripheral];
        [self startScan];
        if (self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(delegatePeripheral:didWriteValueForCharacteristic:error:)]) {
            [self.bleDelegate delegatePeripheral:peripheral didWriteValueForCharacteristic:characteristic error:error];
        }
    }
}

- (void)clearListeners {
    if (self.targetPeripheral.state == CBPeripheralStateConnected) {
        for (NSString *uuid in self.listening) {
            CBCharacteristic *characteristic = [self findCharacteristic:uuid];
            
            if (characteristic && characteristic.isNotifying) {
                [self.targetPeripheral
                 setNotifyValue:NO
                 forCharacteristic:characteristic];
            }
        }
    }
    
    [self.listening removeAllObjects];
}

- (CBCharacteristic *)findCharacteristic:(NSString *)characteristic_uuid {
    @try {
        CBUUID *characteristicUUID = [CBUUID UUIDWithString:characteristic_uuid];
        
        for (CBService *service in self.targetPeripheral.services) {
            for (CBCharacteristic *character in service.characteristics) {
                if ([character.UUID isEqual:characteristicUUID]) {
                    return character;
                }
            }
        }
    } @catch(NSException *ex) {
        for (CBService *service in self.targetPeripheral.services) {
            for (CBCharacteristic *character in service.characteristics) {
                if ([character.UUID.UUIDString isEqualToString:characteristic_uuid]) {
                    return character;
                }
            }
        }
    }
    
    return nil;
}

- (NSMutableArray *)collectionPeripherals {
    if (!_collectionPeripherals) {
        _collectionPeripherals = [[NSMutableArray alloc] init];
    }
    return _collectionPeripherals;
}

- (void)connectBridgeAction {
    _startCollect = NO;
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"RSSI" ascending:YES];
    [self.collectionPeripherals sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    NSDictionary *dic = [self.collectionPeripherals lastObject];
    [[CSRBridgeRoaming sharedInstance] didDiscoverBridgeDevice:centralManager peripheral:dic[@"peripheral"] advertisment:dic[@"advertisementData"] RSSI:dic[@"RSSI"]];
}

@end
