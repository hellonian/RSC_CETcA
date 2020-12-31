//
//  SocketViewController.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/12/29.
//  Copyright © 2018 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SocketViewController : UIViewController

@property (nonatomic,strong)NSNumber *deviceId;
@property (nonatomic,copy) void (^reloadDataHandle)(void);
@property (nonatomic, assign) NSInteger source;

@end

NS_ASSUME_NONNULL_END
