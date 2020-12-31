//
//  DeviceViewController.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/1/25.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceViewController : UIViewController

@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,copy) void (^reloadDataHandle)(void);
@property (nonatomic, assign) NSInteger source;

@end
