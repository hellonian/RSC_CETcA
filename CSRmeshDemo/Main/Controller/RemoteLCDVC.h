//
//  RemoteLCDVC.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/1/2.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RemoteLCDVC : UIViewController

@property (nonatomic,strong)NSNumber *deviceId;
@property (nonatomic,copy) void (^reloadDataHandle)(void);

@end

NS_ASSUME_NONNULL_END
