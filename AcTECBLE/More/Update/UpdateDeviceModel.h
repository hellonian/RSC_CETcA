//
//  UpdateDeviceModel.h
//  AcTECBLE
//
//  Created by AcTEC on 2017/12/19.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UpdateDeviceModel : NSObject

@property (nonatomic,strong) CBPeripheral *peripheral;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *kind;
@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,assign) BOOL connected;
@property (nonatomic,strong) NSNumber *bleHwVersion;
@property (nonatomic,strong) NSNumber *fVersion;
@property (nonatomic,strong) NSNumber *hVersion;
@property (nonatomic,strong) NSNumber *bleFVersion;
@property (nonatomic,strong) NSNumber *fmcuVersion;
@property (nonatomic,strong) NSNumber *hmcuVersion;
@property (nonatomic,assign) NSInteger updateNumber;//1、OTAU方式升级蓝牙固件；2、GAIA方式升级蓝牙固件；3、升级MCU固件；4、OTAU方式升级蓝牙固件 + 升级MCU固件；5、GAIA方式升级蓝牙固件 + 升级MCU固件；

@end
