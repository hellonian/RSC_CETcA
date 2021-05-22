//
//  DeviceModel.h
//  AcTECBLE
//
//  Created by AcTEC on 2017/9/20.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceModel : NSObject

@property (nonatomic, strong) NSNumber *deviceId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *shortName;
@property (nonatomic, strong) NSNumber *level;
@property (nonatomic, strong) NSNumber *powerState;
@property (nonatomic, strong) NSNumber *colorTemperature;
@property (nonatomic, strong) NSNumber *supports;
@property (nonatomic, assign) BOOL isForGroup;
@property (nonatomic, assign) BOOL isShowDeleteBtn;
@property (nonatomic, assign) BOOL isleave;
@property (nonatomic, strong) NSNumber *red;
@property (nonatomic, strong) NSNumber *green;
@property (nonatomic, strong) NSNumber *blue;
@property (nonatomic, assign) NSInteger primordial;
@property (nonatomic, assign) BOOL fanState;
@property (nonatomic, assign) int fansSpeed;
@property (nonatomic, assign) BOOL lampState;
@property (nonatomic, assign) BOOL channel1PowerState;
@property (nonatomic, assign) BOOL channel2PowerState;
@property (nonatomic, assign) BOOL childrenState1;
@property (nonatomic, assign) BOOL childrenState2;
@property (nonatomic, assign) NSInteger channel1Level;
@property (nonatomic, assign) NSInteger channel2Level;
@property (nonatomic, assign) BOOL channel3PowerState;
@property (nonatomic, assign) NSInteger channel3Level;
@property (nonatomic, assign) NSInteger cDirection1;//1——正转（关） 2——正转停 3——反转（开） 0——反转（停）
@property (nonatomic, assign) NSInteger cDirection2;
@property (nonatomic, assign) NSInteger mcLiveChannels;
@property (nonatomic, assign) NSInteger mcExistChannels;
@property (nonatomic, assign) NSInteger mcCurrentChannel;
@property (nonatomic, assign) NSInteger mcStatus;
@property (nonatomic, assign) NSInteger mcVoice;
@property (nonatomic, assign) NSInteger mcSong;
@property (nonatomic, strong) NSString *songName;
@property (nonatomic, assign) NSInteger curtainRange;
@property (nonatomic, assign) NSInteger curtainDirection;
@property (nonatomic, strong) NSMutableDictionary *stateDic;

@end

