//
//  PowerViewController.h
//  AcTECBLE
//
//  Created by AcTEC on 2019/1/4.
//  Copyright © 2019 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PowerViewController : UIViewController

@property (nonatomic,assign) NSInteger channel;
@property (nonatomic,strong)NSNumber *deviceId;

@end

NS_ASSUME_NONNULL_END
