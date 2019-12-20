//
//  TwoChannelDimmerVC.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/1/9.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TwoChannelDimmerVC : UIViewController

@property (nonatomic,strong)NSNumber *deviceId;
@property (nonatomic,copy) void (^reloadDataHandle)(void);
@property (nonatomic,strong)NSString *remoteBrach;

@end

