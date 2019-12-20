//
//  RemoteMainVC.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/12/16.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RemoteMainVC : UIViewController

@property (nonatomic,strong)NSNumber *deviceId;
@property (nonatomic,copy) void (^reloadDataHandle)(void);

@end

NS_ASSUME_NONNULL_END
