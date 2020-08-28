//
//  CurtainViewController.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/9/19.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CurtainViewController : UIViewController

@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,copy) void (^reloadDataHandle)(void);

@end
