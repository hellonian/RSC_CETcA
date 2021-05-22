//
//  DeviceModel.m
//  AcTECBLE
//
//  Created by AcTEC on 2017/9/20.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "DeviceModel.h"

@implementation DeviceModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.mcLiveChannels = 0;
        self.mcExistChannels = 0;
        self.mcCurrentChannel = -1;
        self.mcStatus = -1;
        self.mcVoice = -1;
        self.mcSong = -1;
        self.stateDic = [NSMutableDictionary new];
    }
    return self;
}

@end

