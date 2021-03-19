//
//  PIRAutomaticDetailViewController.h
//  AcTECBLE
//
//  Created by AcTEC on 2021/3/5.
//  Copyright © 2021 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PIRAutomaticDetailViewController : UIViewController

@property (nonatomic, assign) int sourseNumber;//1、人体检测；2、温度感应。
@property (nonatomic, strong) NSNumber *deviceId;

@end

NS_ASSUME_NONNULL_END
