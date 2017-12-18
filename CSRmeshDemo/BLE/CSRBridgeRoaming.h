//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <Foundation/Foundation.h>
#import "CBPeripheral+Info.h"



@interface CSRBridgeRoaming : NSObject

@property (atomic) NSUInteger numberOfConnectedBridges;

+ (id)sharedInstance;
- (NSDictionary *)didDiscoverBridgeDevice:(CBCentralManager *)central peripheral:(CBPeripheral *)peripheral advertisment:(NSDictionary *)advertisment RSSI:(NSNumber *)RSSI;
- (void)disconnectedPeripheral:(CBPeripheral *)peripheral;
- (void)connectedPeripheral:(CBPeripheral *)peripheral;

@end
