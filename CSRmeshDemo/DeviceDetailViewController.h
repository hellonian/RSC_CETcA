//
//  DeviceDetailViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/21.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSRmeshDevice.h"
#import "CSRDeviceEntity.h"

@interface DeviceDetailViewController : UIViewController

@property (nonatomic,strong) CSRmeshDevice *lightDevice;
@property (nonatomic,strong) CSRDeviceEntity *deviceEntity;
@property (nonatomic,strong) NSNumber *level;
@property (nonatomic,strong) NSNumber *powerState;
@property (nonatomic,copy) void (^handle) (void);

@end
