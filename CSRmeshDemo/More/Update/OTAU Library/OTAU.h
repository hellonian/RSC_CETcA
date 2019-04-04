//
//  OTAU.h
//  OTAUTest
//
//  Created by AcTEC on 2019/2/28.
//  Copyright © 2019 BAO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSRBluetoothLE.h"

#define serviceBootOtauUuid @"00001010-d102-11e1-9b23-00025b00a5a5"
#define characteristicVersionUuid @"00001011-d102-11e1-9b23-00025b00a5a5"
#define serviceDeviceInfoUuid @"0000180a-0000-1000-8000-00805f9b34fb"
#define characteristicAppVersionUuid @"00002a28-0000-1000-8000-00805f9b34fb"
#define characteristicCurrentAppUuid @"00001013-d102-11e1-9b23-00025b00a5a5"
#define characteristicDataTransferUuid @"00001014-d102-11e1-9b23-00025b00a5a5"
#define characteristicTransferControlUuid @"00001015-d102-11e1-9b23-00025b00a5a5"
#define serviceApplicationOtauUuid @"00001016-d102-11e1-9b23-00025b00a5a5"
#define characteristicGetKeysUuid @"00001017-d102-11e1-9b23-00025b00a5a5"
#define characteristicGetKeyBlockUuid @"00001018-d102-11e1-9b23-00025b00a5a5"

#define csKeyIndexBluetoothAddress 1
#define csKeyIndexCrystalTrim 2
#define csKeyIndexIdentityRoot 17
#define csKeyIndexEncryptionRoot 18

#define transferControlInProgress 2
#define transferControlComplete 4

typedef enum OtauErrorTypes {
    OTAUErrorFailedQueryDevice = 1000,
    OTAUErrorFailedUpdate,
    OTAUErrorFailedDisconnected,
    OTAUErrorDeviceNotSelected
} OtauErrors;

@protocol OTAUDelegate <NSObject>

- (void)regetVersion;
- (void)updateProgressDelegteMethod:(CGFloat)percentage;

@end

NS_ASSUME_NONNULL_BEGIN

@interface OTAU : NSObject

@property (nonatomic, strong) NSString *sourceFilePath;
@property (nonatomic, weak) id<OTAUDelegate> otauDelegate;

+ (id)shareInstance;
- (void)initOTAU:(CBPeripheral *)peripheral;
- (BOOL)parseCsKeyJson:(NSString*)csKeyJsonFile;
- (void)startOTAU;

@end

NS_ASSUME_NONNULL_END
