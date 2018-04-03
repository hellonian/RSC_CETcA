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
- (void) CBPowerIsOff;
- (void) CBPoweredOn;
- (void) discoveredBridge;
- (void) didConnectBridge :(CBPeripheral *) bridge;
- (void) didDiscoverBridgeService :(CBPeripheral *) bridge;
- (void) updateItemClusterDeviceId:(NSNumber *)deviceId level:(NSNumber *)level powerState:(NSNumber *)powerState;
- (void) statusMessage:(NSString *)message;

/////////////////////////////////////////////////////////////////////////
- (void) didDiscoverPeripheral:(CBPeripheral *) peripheral;
- (void) didConnectPeripheral:(CBPeripheral *) peripheral;
- (void) didDisconnect:(CBPeripheral *)peripheral error:(NSError *)error;
- (void) didChangeMode;
- (void) discoveryDidRefresh;
- (void) discoveryStatePoweredOff;
- (void) otauPeripheralTest:(CBPeripheral *) peripheral :(BOOL) isOtau;
- (void) didDiscoverServices:(CBPeripheral *) peripheral;

@end



/****************************************************************************/
/*						Public Interface                                    */
/****************************************************************************/
@interface CSRBluetoothLE : NSObject

    
+ (id) sharedInstance;
-(void) connectPeripheral:(CBPeripheral *) peripheral;
-(void) disconnectPeripheral:(CBPeripheral *) peripheral;
-(void) connectPeripheralNoCheck:(CBPeripheral *) peripheral;
-(void) removeDiscoveredPeripheralsExceptConnected;
-(void) startScan;
-(void) stopScan;
- (void)powerOnCentralManager;
- (void)powerOffCentralManager;

-(void) setScanner :(BOOL) stateRequired source:(id) source;



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

@end
