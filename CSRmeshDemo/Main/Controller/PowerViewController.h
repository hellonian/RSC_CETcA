//
//  PowerViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/1/4.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PowerViewController : UIViewController

@property (nonatomic,assign) NSInteger channel;
@property (nonatomic,strong)NSNumber *deviceId;

@end

NS_ASSUME_NONNULL_END
