//
//  TimerDetailViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/2.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimerEntity.h"

typedef void(^TimerSettingDoneBlock)(void);

@interface TimerDetailViewController : UIViewController

@property (nonatomic,strong) TimerSettingDoneBlock handle;
@property (nonatomic,strong) TimerEntity *timerEntity;

@end
