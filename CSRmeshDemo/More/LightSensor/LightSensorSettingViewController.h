//
//  LightSensorSettingViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/6/14.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSRDeviceEntity.h"

@interface LightSensorSettingViewController : UIViewController

@property (nonatomic,strong)CSRDeviceEntity *lightSensor;
@property (nonatomic,copy) void (^reloadDataHandle)(void);

@end
