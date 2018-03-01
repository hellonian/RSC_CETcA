//
//  RemoteSettingViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/1.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSRDeviceEntity.h"

@interface RemoteSettingViewController : UIViewController

@property (nonatomic,strong)CSRDeviceEntity *remoteEntity;
@property (nonatomic,copy) void (^reloadDataHandle)(void);

@end
