//
//  DeviceModel.h
//  CSRmeshDemo
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

@end

