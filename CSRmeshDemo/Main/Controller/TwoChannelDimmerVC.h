//
//  TwoChannelDimmerVC.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/1/9.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TwoChannelDimmerVC : UIViewController

@property (nonatomic,strong)NSNumber *deviceId;
@property (nonatomic,copy) void (^reloadDataHandle)(void);
@property (nonatomic,assign)BOOL forSelected;

@end

NS_ASSUME_NONNULL_END
