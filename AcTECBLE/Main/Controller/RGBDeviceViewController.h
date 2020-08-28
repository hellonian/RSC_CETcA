//
//  RGBDeviceViewController.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/8/30.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RGBDeviceViewController : UIViewController

@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,copy) void (^RGBDVCReloadDataHandle)(void);

@end
