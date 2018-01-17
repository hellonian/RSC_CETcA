//
//  TimerTool.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/11.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "TimerTool.h"

@implementation TimerTool

static NSString *const kTimerList = @"com.actec.bluetooth.timerList";
static NSString *const kIndexMap = @"com.actec.bluetooth.indexMap";

+ (NSInteger)newTimerIndexForDevice:(NSNumber *)deviceId {
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    NSString *key = [NSString stringWithFormat:@"%@%@",kIndexMap,deviceId];
    NSArray *recordList = [center arrayForKey:key];
    
    if (recordList) {
        return [TimerTool nextIndexExcludeDomain:recordList];
    }
    return 16;
}
+ (void)removeTimerIndex:(NSInteger)index forDevice:(NSNumber *)deviceId {
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    NSString *key = [NSString stringWithFormat:@"%@%@",kIndexMap,deviceId];
    NSArray *recordList = [center arrayForKey:key];
    
    if (recordList) {
        NSNumber *numIndex = [NSNumber numberWithInteger:index];
        if ([recordList containsObject:numIndex]) {
            NSMutableArray *indexSet = [NSMutableArray arrayWithArray:recordList];
            [indexSet removeObject:numIndex];
            [center setObject:indexSet forKey:key];
        }
    }
}
+ (void)saveNewTimerIndex:(NSInteger)index forDevice:(NSNumber *)deviceId {
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    NSString *key = [NSString stringWithFormat:@"%@%@",kIndexMap,deviceId];
    NSNumber *numIndex = [NSNumber numberWithInteger:index];
    NSArray *recordList = [center arrayForKey:key];
    
    if (recordList) {
        if (![recordList containsObject:numIndex]) {
            NSMutableArray *update = [[NSMutableArray alloc] initWithArray:recordList];
            [update addObject:numIndex];
            [center setObject:update forKey:key];
        }
    }else {
        [center setObject:@[numIndex] forKey:key];
    }
    
}

+ (NSInteger)nextIndexExcludeDomain:(NSArray*)exclude {
    for (NSInteger index=16; index<20; index++) {
        if (![exclude containsObject:[NSNumber numberWithInteger:index]]) {
            return index;
        }
    }
    return 99;
}

@end
