//
//  SRGBSceneDetailViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/9/3.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RGBSceneEntity.h"

@interface SRGBSceneDetailViewController : UIViewController

@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,strong) RGBSceneEntity *rgbSceneEntity;
@property (nonatomic,copy) void (^reloadDataHandle)(void);

@end
