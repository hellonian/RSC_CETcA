//
//  PIRDeviceVC.h
//  AcTECBLE
//
//  Created by AcTEC on 2021/1/6.
//  Copyright © 2021 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PIRDeviceVC : UIViewController

@property (nonatomic,strong)NSNumber *deviceId;
@property (nonatomic,copy) void (^reloadDataHandle)(void);

@end

NS_ASSUME_NONNULL_END
