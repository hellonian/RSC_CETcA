//
//  DeviceModelManager.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/16.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceModel.h"
#import "SuperCollectionViewCell.h"

@interface DeviceModelManager : NSObject

@property (nonatomic, strong) NSMutableArray *allDevices;

+ (DeviceModelManager *)sharedInstance;

- (DeviceModel *)getDeviceModelByDeviceId:(NSNumber *)deviceId;
- (void)setPowerStateWithDeviceId:(NSNumber *)deviceId withPowerState:(NSNumber *)powerState;
- (void)setLevelWithDeviceId:(NSNumber *)deviceId withLevel:(NSNumber *)level withState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction;

@end
