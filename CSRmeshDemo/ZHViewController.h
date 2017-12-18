//
//  ZHViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/10/23.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShareViewController.h"

@interface ZHViewController : UIViewController

@property (nonatomic,assign)ShareDirection shareDirection;
@property (nonatomic,copy) void(^handle)(NSString *name,NSString *password);

@end
