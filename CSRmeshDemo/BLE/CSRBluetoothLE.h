//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CBPeripheral+Info.h"


/****************************************************************************/
/*							UI protocols									*/
/****************************************************************************/
@protocol CSRBluetoothLEDelegate <NSObject>
@optional

/////////////////////////////////////////////////////////////////////////
- (void) didConnectPeripheral:(CBPeripheral *) peripheral;
- (void) didDisconnectPeripheral:(CBPeripheral *)peripheral withError:(NSError *)error;
- (void) discoveryDidRefresh:(CBPeripheral *) peripheral;

- (void)didPowerOn;
- (void)didPowerOff;
- (void)discoveredPripheralDetails;
- (void)chracteristicChanged:(CBCharacteristic *)characteristic;
- (void)didConnectToPeripheral:(CBPeripheral *)peripheral;
- (void)delegatePeripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
- (void)didDisconnectFromPeripheral:(CBPeripheral *)peripheral;
- (void)chracteristicSetNotifySuccess:(CBCharacteristic *)characteristic;

@end



/****************************************************************************/
/*						Public Interface                                    */
/****************************************************************************/
@interface CSRBluetoothLE : NSObject

    
+ (id) sharedInstance;
//-(void) connectPeripheral:(CBPeripheral *) peripheral;
-(void) disconnectPeripheral:(CBPeripheral *) peripheral;
-(void) connectPeripheralNoCheck:(CBPeripheral *) peripheral;
-(void) removeDiscoveredPeripheralsExceptConnected;
-(void) startScan;
-(void) stopScan;
- (void)powerOnCentralManager;
- (void)powerOffCentralManager;

-(void) setScanner :(BOOL) stateRequired source:(id) source;

- (void)readRssi:(CBPeripheral *)peripheral;

/////////////////////////////////////////////////////////////////////////
-(NSArray *) retrievePeripheralsWithIdentifier:(NSUUID *) uuid;
-(void) retrieveCachedPeripherals;
- (void)startOTAUTest: (CBPeripheral *) peripheral;

@property (nonatomic, strong) NSMutableArray *discoveredBridges;
@property (nonatomic, weak) id<CSRBluetoothLEDelegate>  bleDelegate;
@property (nonatomic) CBCentralManagerState cbCentralManagerState;

///////////////////////////////////////////////////////////////////////
@property (nonatomic,assign) BOOL isUpdateFW;
@property (nonatomic,strong) NSMutableArray *foundPeripherals;
@property (nonatomic,strong) NSMutableArray *connectedPeripherals;
@property (nonatomic, strong) NSNumber *discoveredChars;
@property (nonatomic, strong) NSNumber *peripheralInBoot;
@property (nonatomic, strong) CBService *targetService;
@property (nonatomic, strong) CBPeripheral *targetPeripheral;
@property (nonatomic,assign) BOOL secondConnectBool;

@property (nonatomic,assign) BOOL isForGAIA;
@property (nonatomic,strong) NSMutableDictionary *listening;

- (CBService *)findService:(NSString *)service_uuid;
- (CBCharacteristic *)findCharacteristic:(CBService *)service
                          characteristic:(NSString *)characteristic_uuid;
- (BOOL)listenFor:(NSString *)service_uuid
   characteristic:(NSString *)charactaristic_uuid;

@property(nonatomic, assign) BOOL isNearbyFunction;

@end
