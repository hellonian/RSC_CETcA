//
//  SocketViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/12/29.
//  Copyright © 2018 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SocketViewController : UIViewController

@property (nonatomic,strong)NSNumber *deviceId;
@property (nonatomic,copy) void (^reloadDataHandle)(void);

@end

NS_ASSUME_NONNULL_END
