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
#import <CSRmesh/LightModelApi.h>
#import "CSRDeviceEntity.h"

#import "OTAU.h"

// Uncomment to enable brige roaming
#define   BRIDGE_ROAMING_ENABLE
//#define BRIDGE_DISCONNECT_ALERT

    /****************************************************************************/
    /*			Private variables and methods									*/
    /****************************************************************************/
#define CSR_STORED_PERIPHERALS  @"StoredDevices"


@interface CSRBluetoothLE () <CBCentralManagerDelegate, CBPeripheralDelegate,LightModelApiDelegate> {
	CBCentralManager    *centralManager;
    BOOL                pendingInit;
}

    // Set of objects that request the scanner to be turned On
    // Scanner will be turned off if there are no memebers in the Set
@property (atomic)  NSMutableSet  *scannerEnablers;

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
        
        pendingInit = YES;
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
-(void) connectPeripheral:(CBPeripheral *) peripheral {
    
//    if ([[CSRmeshSettings sharedInstance] getBleListenMode] == CSRBleListenMode_ScanNotificationListen) {
    
//    } else {
     if ([[CSRmeshSettings sharedInstance] getBleConnectMode]==CSR_BLE_CONNECTIONS_MANUAL) {
        for (CBPeripheral *connectedPeripheral in _connectedPeripherals) {
            if (connectedPeripheral && connectedPeripheral.state != CBPeripheralStateConnected)
                [centralManager cancelPeripheralConnection:peripheral];
        }
        
        [_connectedPeripherals removeAllObjects];

        if ([peripheral state]!=CBPeripheralStateConnected) {
            [centralManager connectPeripheral:peripheral options:nil];
        }
    }
    
}

    //============================================================================
    // Connect peripheral without checking how many are connected
-(void) connectPeripheralNoCheck:(CBPeripheral *) peripheral {
    NSLog(@"~~~~~~~~~1111");
    if ([peripheral state]!=CBPeripheralStateConnected) {
        [centralManager connectPeripheral:peripheral options:nil];
    }
}



    //============================================================================
    // Disconnect the given peripheral.
-(void) disconnectPeripheral:(CBPeripheral *) peripheral {
    [centralManager cancelPeripheralConnection:peripheral];
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
            [_foundPeripherals removeAllObjects];
            
            NSDictionary *options = [self createDiscoveryOptions];
            [centralManager scanForPeripheralsWithServices:nil options:options];
        }
    }
}


    //============================================================================
    // Stop Scan
-(void) stopScan {
    @synchronized(self) {
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
            [self statusMessage:[NSString stringWithFormat:@"Bluetooth Powered Off\n"]];
            [_foundPeripherals removeAllObjects];
            [self discoveryDidRefresh];
            [self discoveryStatePoweredOff];
            if(bleDelegate && [bleDelegate respondsToSelector:@selector(CBPowerIsOff)])
                [bleDelegate CBPowerIsOff];
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
            [self statusMessage:[NSString stringWithFormat:@"Bluetooth Powered On\n"]];
            [_foundPeripherals removeAllObjects];
            if(bleDelegate && [bleDelegate respondsToSelector:@selector(CBPoweredOn)])
                [bleDelegate CBPoweredOn];
            
            
            NSDictionary *options = [self createDiscoveryOptions];
            [centralManager scanForPeripheralsWithServices:nil options:options];
            pendingInit = NO;
            
            [self statusMessage:[NSString stringWithFormat:@"Scanning...\n"]];
            break;
        }
        
        case CBCentralManagerStateResetting: {
            NSLog(@"Central Resetting");
            [self discoveryDidRefresh];
            pendingInit = YES;
            break;
        }
        
        case CBCentralManagerStateUnsupported:
        break;
        
    }
    
    previousState = [centralManager state];
    self.cbCentralManagerState = previousState;
}
    

    //============================================================================
    // This callback occurs on discovery of a Peripheral.
    // If the Peripheral is a Mesh Bridge then
    //  - save it
    //  - go on to discover Services and then Characteristics
    //  - Inform delegate of new discovery (for UI refresh)

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    [peripheral setRssi:RSSI];
    NSString *adString;
    if (advertisementData[@"kCBAdvDataManufacturerData"]) {
        NSData *adData = advertisementData[@"kCBAdvDataManufacturerData"];
        adString = [[self hexStringForData:adData] uppercaseString];
        [peripheral setUuidString:adString];
    }

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
        
        NSArray *array = [[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects];
        if (array.count == 0 || array == nil) {
            [[CSRBridgeRoaming sharedInstance] didDiscoverBridgeDevice:central peripheral:peripheral advertisment:advertisementData RSSI:RSSI];
        }
        else if (!_isUpdateScaning && adString != nil ) {
            
            BOOL exist = [[adString substringFromIndex:13] boolValue];
            if (exist) {
                [[CSRBridgeRoaming sharedInstance] didDiscoverBridgeDevice:central peripheral:peripheral advertisment:advertisementData RSSI:RSSI];
            }
            
        }
        
#endif
        
        if (![discoveredBridges containsObject:peripheral]) {
            [discoveredBridges addObject:peripheral];
        }
        [peripheral setLocalName:advertisementData[CBAdvertisementDataLocalNameKey]];
        if(bleDelegate && [bleDelegate respondsToSelector:@selector(discoveredBridge)]) {
            [bleDelegate discoveredBridge];
        }
        //////////////////////////////////////////////////////////////////
        
        
        
        if (self.isUpdateScaning ) {
            if (![_foundPeripherals containsObject:peripheral]) {
                [_foundPeripherals addObject:peripheral];
                [self discoveryDidRefresh];
            }
            [self didDiscoverPeripheral:peripheral];
        }
    }
}

//二进制数据转十六进制字符串
- (NSString *)hexStringForData: (NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

    //============================================================================
    // This callback occurs if the RSSI has changed
- (void) peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    
//    [peripheral setRssi:peripheral.RSSI];
    
    if(bleDelegate && [bleDelegate respondsToSelector:@selector(discoveredBridge)]) {
        [bleDelegate discoveredBridge];
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    
    [peripheral setRssi:RSSI];
    NSLog(@"RSSI returned %@", [RSSI stringValue]);
}

    //============================================================================
    // This callback occurs on a Successful connection to a Mesh bridge device
    // - remove connection to other Mesh Bridges, if these exist.
    // - go on to Discover the Mesh Service
    // - and inform delegate of new connection (for UI refresh)

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"did connect peripheral %@",peripheral.name);
    
    // if also connected to another Bridge then disconnect from that.
    
    if (_isUpdateScaning||_isUpdatePage) {
        [_connectedPeripherals addObject:peripheral];
        [self statusMessage:[NSString stringWithFormat:@"1010>>Established Connection To Peripheral %@\n",peripheral.name]];
        peripheral.delegate=self;
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.discoveredChars = [NSNumber numberWithBool: NO];
        if (peripheral.services.count==0) {
            NSLog(@" -Discovering Services");
            [peripheral discoverServices:nil];
        }
        else {
            NSLog(@" -skipped discover services");
            for (CBService *service in peripheral.services) {
                NSLog (@" - Service=%@",service.UUID);
                [self statusMessage:[NSString stringWithFormat:@" - Service=%@",service.UUID]];
            }
        }
        
        [self didConnectPeripheral:peripheral];
        
    }else {
        
    
    
    [_connectedPeripherals addObject:peripheral];
    
    peripheral.delegate=self;
    
    [peripheral discoverServices:nil];
    
    if (bleDelegate && [bleDelegate respondsToSelector:@selector(didConnectBridge:)]) {
        
        [bleDelegate didConnectBridge:peripheral];
        
    }
    
#ifdef BRIDGE_ROAMING_ENABLE
        [[CSRBridgeRoaming sharedInstance] connectedPeripheral:peripheral];
        NSLog (@"BRIDGE CONNECTED %@",peripheral.name);
        [self stopScan];
        
#endif
    
    if(bleDelegate && [bleDelegate respondsToSelector:@selector(discoveredBridge)])
        [bleDelegate discoveredBridge];

    }
}

    //============================================================================
    // This callback occurs on a Successful disconnection to a Peripheral
- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if ([_connectedPeripherals containsObject:peripheral]) {
        [_connectedPeripherals removeObject:peripheral];
        [[MeshServiceApi sharedInstance] disconnectBridge:peripheral];

//#ifdef  BRIDGE_DISCONNECT_ALERT
        NSLog (@"BRIDGE DISCONNECTED : %@",peripheral.name);

//#endif
        
        // Call up Bridge Select View
//#ifdef BRIDGE_ROAMING_ENABLE
        [[CSRBridgeRoaming sharedInstance] disconnectedPeripheral:peripheral];
//#endif

        // Call up Bridge Select View
        if (_connectedPeripherals.count==0)
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BridgeDisconnectedNotification" object:nil];
    }
    
    NSLog(@"}}}}}}}%d{{{}}}%d",_isUpdatePage,_isUpdateScaning);
    [self statusMessage:[NSString stringWithFormat:@"88>>Removed Connection To Peripheral %@\n",peripheral.name]];
    [self didDisconnect:peripheral error:error];
    if (_isUpdateScaning && _outUpdate) {
        
        [self connectPeripheralNoCheck:_updatePeripheral];
    }
}

    //============================================================================
    // peripheral:discoverServices initiated this callback

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (_isUpdateScaning||_isUpdatePage) {
        bool isOtau=NO;
        NSLog(@"did discover services for peripheral %@",peripheral.name);
        if (error == nil) {
            if (peripheral.state==CBPeripheralStateConnected) {
                [self didDiscoverServices:peripheral];
                [self statusMessage:[NSString stringWithFormat:@"1212>>Found Services\n"]];
                CBUUID *uuid = [CBUUID UUIDWithString:serviceApplicationOtauUuid];
                CBUUID *bl_uuid = [CBUUID UUIDWithString:serviceBootOtauUuid];
                CBUUID *devInfoUuid = [CBUUID UUIDWithString:serviceDeviceInfoUuid];
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                appDelegate.devInfoService = nil;
                for (CBService *service in peripheral.services) {
                    NSLog(@" -Found service %@",service.UUID);
                    [self statusMessage:[NSString stringWithFormat:@"1313>>%@\n",service.UUID]];
                    if ([service.UUID isEqual:uuid]) {
                        isOtau=YES;
                        appDelegate.peripheralInBoot = [NSNumber numberWithBool: NO];
                        [self didChangeMode];
                        [peripheral discoverCharacteristics:nil forService:service];
                        appDelegate.targetService = service;
                        if (appDelegate.devInfoService != nil) {
                            break;
                        }
                    }
                    else if ([service.UUID isEqual:bl_uuid]) {
                        isOtau = YES;
                        appDelegate.peripheralInBoot = [NSNumber numberWithBool: YES];
                        [self didChangeMode];
                        [peripheral discoverCharacteristics:nil forService:service];
                        appDelegate.targetService = service;
                        if (appDelegate.devInfoService != nil) {
                            break;
                        }
                    }
                    else if ([service.UUID isEqual:devInfoUuid]) {
                        [peripheral discoverCharacteristics:nil forService:service];
                        appDelegate.devInfoService = service;
                        if (isOtau) {
                            // Already found the OTAU service so we are done now.
                            break;
                        }
                    }
                }
                [self discoveryDidRefresh];
                
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
    if (error == nil) {
        [[MeshServiceApi sharedInstance] connectBridge:peripheral enableBridgeNotification:@([[CSRmeshSettings sharedInstance] getBleListenMode])];
        // Inform BridgeRoaming that a peripheral has disconnected
        
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:MESH_MTL_CHAR_ADVERT]]) {
                [self subscribeToMeshSimNotifyChar:peripheral :characteristic];
            }
        }
        
        [peripheral setIsBridgeService:@(YES)];
        if(bleDelegate && [bleDelegate respondsToSelector:@selector(didConnectBridge:)])
            [bleDelegate didConnectBridge:peripheral];
        
#ifdef BRIDGE_ROAMING_ENABLE
        [[CSRBridgeRoaming sharedInstance] connectedPeripheral:peripheral];
#endif
        
        if (_isUpdateScaning||_isUpdatePage) {
            CBUUID *uuid = [CBUUID UUIDWithString:serviceApplicationOtauUuid];
            CBUUID *bl_uuid = [CBUUID UUIDWithString:serviceBootOtauUuid];

            if ([service.UUID isEqual:uuid] || [service.UUID isEqual:bl_uuid]) {
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                appDelegate.discoveredChars = [NSNumber numberWithBool: YES];
                NSLog(@"44444444");
                [self otauPeripheralTest:peripheral :YES];
            }
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
    
    if (error)
        NSLog (@"Can't subscribe for notification to %@ of %@", characteristic.UUID, peripheral.name);
    else
        NSLog (@"Did subscribe for notification to %@ of %@", characteristic.UUID, peripheral.name);
//        static dispatch_once_t onceToken;
//        dispatch_once(&onceToken, ^{
//            [[LightModelApi sharedInstance] addDelegate:self];
//            NSSet *devices = [CSRAppStateManager sharedInstance].selectedPlace.devices;
//            for (CSRDeviceEntity *deviceEntity in devices) {
//                
//                [[LightModelApi sharedInstance] getState:deviceEntity.deviceId success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
//                    NSLog(@"获取所有设备状态");
//                } failure:^(NSError * _Nullable error) {
//                    
//                }];
//            }
//            
//        });
    
}

- (void)didGetLightState:(NSNumber *)deviceId red:(NSNumber *)red green:(NSNumber *)green blue:(NSNumber *)blue level:(NSNumber *)level powerState:(NSNumber *)powerState colorTemperature:(NSNumber *)colorTemperature supports:(NSNumber *)supports meshRequestId:(NSNumber *)meshRequestId {
    
    [self.bleDelegate updateItemClusterDeviceId:deviceId level:level powerState:powerState];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"getAllDeviceState" object:nil userInfo:@{@"deviceId":deviceId,@"level":level,@"powerState":powerState}];
}

    //============================================================================
    // Incoming Mesh packets can also be received as bridge notifications.
    // If so, then an advertimentData dictionary should be built with
    //     Key = CBAdvertisementDataServiceDataKey object = (dictionary with key=0xfef1 object=value)
    //     Key = CBAdvertisementDataIsConnectable object = NSNumber of the BOOL NO
    //     Key = @"didUpdateValueForCharacteristic" object = handle to the characeterisic
-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    
    NSMutableDictionary *advertisementData = [NSMutableDictionary dictionary];
    
    [advertisementData setObject:@(NO) forKey:CBAdvertisementDataIsConnectable];
    
    advertisementData [CBAdvertisementDataIsConnectable] = @(NO);
    [advertisementData setObject:characteristic.value forKey:CSR_NotifiedValueForCharacteristic];
    [advertisementData setObject:characteristic forKey:CSR_didUpdateValueForCharacteristic];
    [advertisementData setObject:peripheral forKey:CSR_PERIPHERAL];
    
    [[MeshServiceApi sharedInstance] processMeshAdvert:advertisementData RSSI:nil];
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
        [self discoveryDidRefresh];
    }
}

- (void)startOTAUTest: (CBPeripheral *) peripheral {
    [self statusMessage:[NSString stringWithFormat:@"\nStart: OTAU Test\n"]];
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
-(void) didDiscoverPeripheral:(CBPeripheral *) peripheral {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        if(self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(didDiscoverPeripheral:)])
            [self.bleDelegate didDiscoverPeripheral:peripheral];
    }];
}

-(void) didConnectPeripheral:(CBPeripheral *) peripheral {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        if(self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(didConnectPeripheral:)])
            [self.bleDelegate didConnectPeripheral:peripheral];
    }];
}

-(void) didDisconnect:(CBPeripheral *)peripheral error:(NSError *)error {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        if(self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(didDisconnect: error:)])
            [self.bleDelegate didDisconnect:peripheral error:error];
    }];
}

-(void) didChangeMode {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        if(self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(didChangeMode)])
            [self.bleDelegate didChangeMode];
    }];
}

-(void) discoveryDidRefresh {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        if(self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(discoveryDidRefresh)])
            [self.bleDelegate discoveryDidRefresh];
    }];
}

-(void) discoveryStatePoweredOff {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        if(self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(discoveryStatePoweredOff)])
            [self.bleDelegate discoveryStatePoweredOff];
    }];
}

-(void) statusMessage:(NSString *)message {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        if(self.bleDelegate  && [self.bleDelegate  respondsToSelector:@selector(statusMessage:)])
            [self.bleDelegate  statusMessage:message];
    }];
}

-(void) otauPeripheralTest:(CBPeripheral *) peripheral :(BOOL) isOtau {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        if(self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(otauPeripheralTest::)])
            [self.bleDelegate otauPeripheralTest:peripheral:isOtau];
    }];
}

-(void) didDiscoverServices:(CBPeripheral *) peripheral {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        if(self.bleDelegate && [self.bleDelegate respondsToSelector:@selector(didDiscoverServices:)])
            [self.bleDelegate didDiscoverServices:peripheral];
    }];
}

@end
