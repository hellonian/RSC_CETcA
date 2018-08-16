//
//  DeviceModelManager.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/16.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceModel.h"
#import "SuperCollectionViewCell.h"

@interface DeviceModelManager : NSObject

@property (nonatomic, strong) NSMutableArray *allDevices;

+ (DeviceModelManager *)sharedInstance;
- (void)getAllDevicesState;
- (DeviceModel *)getDeviceModelByDeviceId:(NSNumber *)deviceId;
- (void)setPowerStateWithDeviceId:(NSNumber *)deviceId withPowerState:(NSNumber *)powerState;
- (void)setLevelWithDeviceId:(NSNumber *)deviceId withLevel:(NSNumber *)level withState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction;
-(void)setColorTemperatureWithDeviceId:(NSNumber *)deviceId withColorTemperature:(NSNumber *)colorTemperature withState:(UIGestureRecognizerState)state;
-(void)setColorWithDeviceId:(NSNumber *)deviceId withColor:(UIColor *)color withState:(UIGestureRecognizerState)state;

@end
