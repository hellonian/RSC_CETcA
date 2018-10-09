//
//  CurtainViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/9/19.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CurtainViewController : UIViewController

@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,copy) void (^reloadDataHandle)(void);

@end
