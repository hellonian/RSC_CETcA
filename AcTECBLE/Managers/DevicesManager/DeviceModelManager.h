//
//  DeviceModelManager.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/1/16.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceModel.h"
#import "SuperCollectionViewCell.h"

@interface DeviceModelManager : NSObject

@property (nonatomic, strong) NSMutableArray *allDevices;
@property (nonatomic, strong) NSMutableDictionary *allTimers;
@property (nonatomic, strong) NSMutableDictionary *allTimerColorfulNums;
@property (nonatomic, assign) BOOL bleDisconnected;

+ (DeviceModelManager *)sharedInstance;
- (void)getAllDevicesState;
- (DeviceModel *)getDeviceModelByDeviceId:(NSNumber *)deviceId;
- (void)setPowerStateWithDeviceId:(NSNumber *)deviceId channel:(NSNumber *)channel withPowerState:(BOOL)powerState;
- (void)setLevelWithDeviceId:(NSNumber *)deviceId channel:(NSNumber *)channel withLevel:(NSNumber *)level withState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction;
-(void)setColorTemperatureWithDeviceId:(NSNumber *)deviceId withColorTemperature:(NSNumber *)colorTemperature withState:(UIGestureRecognizerState)state;
-(void)setColorWithDeviceId:(NSNumber *)deviceId withColor:(UIColor *)color withState:(UIGestureRecognizerState)state;

- (void)colorfulAction:(NSNumber *)deviceId timeInterval:(NSTimeInterval)timeInterval hues:(NSArray *)huesAry colorSaturation:(NSNumber *)colorSat rgbSceneId:(NSNumber *)rgbSceneId;
- (void)invalidateColofulTimerWithDeviceId:(NSNumber *)deviceId;
- (void)regetHues:(NSArray *)huesAry deviceId:(NSNumber *)deviceId sceneId:(NSNumber *)sceneId;
- (void)regetColorSaturation:(float)sat deviceId:(NSNumber *)deviceId sceneId:(NSNumber *)sceneId;
- (void)regetColofulTimerInterval:(NSTimeInterval)interval deviceId:(NSNumber *)deviceId sceneId:(NSNumber *)sceneId;
- (void)setColorWithDeviceId:(NSNumber *)deviceId withColor:(UIColor *)color;
- (void)controlScene:(NSNumber *)sceneId;
- (void)refreshMCChannel:(NSNumber *)deviceID mcChannel:(NSInteger)mcChannel;
- (void)refreshDeviceID:(NSNumber *)deviceID mcChannelValid:(NSInteger)mcChannelValid mcStatus:(NSInteger)mcStatus mcVoice:(NSInteger)mcVoice;
- (void)refreshDeviceID:(NSNumber *)deviceID mcCurrentChannel:(NSInteger)mcCurrentChannel;
- (void)findDevice:(NSNumber *)deviceID getSongName:(NSInteger)channel;
- (void)postSongNameDeviceID:(NSNumber *)deviceID channel:(NSInteger)channel count:(NSInteger)count index:(NSInteger)index encoding:(NSInteger)encoding data:(NSData *)data;
- (void)controlMC:(NSNumber *)deviceID data:(NSData *)cmd;

@end
