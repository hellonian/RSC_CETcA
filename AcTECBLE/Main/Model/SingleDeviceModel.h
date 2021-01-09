//
//  SingleDeviceModel.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/2/8.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SingleDeviceModel : NSObject

@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,strong) NSString *deviceName;
@property (nonatomic,strong) NSString *deviceShortName;
@property (nonatomic,assign) BOOL isForList;
@property (nonatomic,assign) BOOL isSelected;

@end
