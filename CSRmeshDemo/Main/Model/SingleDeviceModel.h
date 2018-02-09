//
//  SingleDeviceModel.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/2/8.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SingleDeviceModel : NSObject

@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,strong) NSString *deviceName;
@property (nonatomic,strong) NSString *deviceShortName;

@end
