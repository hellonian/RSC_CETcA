//
//  TimerDetailViewController.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/3/2.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimerEntity.h"

typedef void(^TimerSettingDoneBlock)(void);

@interface TimerDetailViewController : UIViewController

@property (nonatomic,strong) TimerSettingDoneBlock handle;
@property (nonatomic,strong) TimerEntity *timerEntity;
@property (nonatomic,assign) BOOL newadd;

@end
