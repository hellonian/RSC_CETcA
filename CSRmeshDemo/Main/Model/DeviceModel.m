//
//  DeviceModel.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/20.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "DeviceModel.h"

@implementation DeviceModel

- (void)addValue:(id)obj forKey:(NSString *)key {
    [self.buttonnumAndChannel setObject:obj forKey:key];
}

- (NSMutableDictionary *)buttonnumAndChannel {
    if (!_buttonnumAndChannel) {
        _buttonnumAndChannel = [[NSMutableDictionary alloc] init];
    }
    return _buttonnumAndChannel;
}

@end

