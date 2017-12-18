//
//  TimerTool.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/11.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimerTool : NSObject

+ (NSInteger)newTimerIndexForDevice:(NSNumber *)deviceId;
+ (void)removeTimerIndex:(NSInteger)index forDevice:(NSNumber *)deviceId;
+ (void)saveNewTimerIndex:(NSInteger)index forDevice:(NSNumber *)deviceId;

@end
