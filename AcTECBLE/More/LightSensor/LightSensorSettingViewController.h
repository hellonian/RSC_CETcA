//
//  LightSensorSettingViewController.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/6/14.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSRDeviceEntity.h"

@interface LightSensorSettingViewController : UIViewController

@property (nonatomic,strong)CSRDeviceEntity *lightSensor;
@property (nonatomic,copy) void (^reloadDataHandle)(void);

@end
