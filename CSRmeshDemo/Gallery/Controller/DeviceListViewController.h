//
//  DeviceListViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/31.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,DeviceListSelectMode)
{
    DeviceListSelectMode_Single = 0,
    DeviceListSelectMode_Multiple,
    DeviceListSelectMode_ForDrop,
    DeviceListSelectMode_ForGroup,
    DeviceListSelectMode_SelectGroup,
    DeviceListSelectMode_SelectScene,
    DeviceListSelectMode_ForLightSensor,
    DeviceListSelectMode_SelectRGBDeviceOrGroup,
    DeviceListSelectMode_SelectCWDeviceOrGroup
};

typedef void(^DeviceListSelectedHandle)(NSArray *devices);

@interface DeviceListViewController : UIViewController

@property (nonatomic,assign)DeviceListSelectMode selectMode;
@property (nonatomic,strong)NSArray *originalMembers;
@property (nonatomic,strong)NSNumber *buttonNum;
@property (nonatomic,strong)NSString *remoteBranch;

- (void)getSelectedDevices:(DeviceListSelectedHandle)handle;

@end
