//
//  UpdateDeviceModel.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/12/19.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UpdateDeviceModel : NSObject

@property (nonatomic,strong) CBPeripheral *peripheral;
@property (nonatomic,strong) NSString *uuidStr;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *kind;
@property (nonatomic,assign) NSInteger firwareVersion;
@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,assign) BOOL isLatest;

@end
