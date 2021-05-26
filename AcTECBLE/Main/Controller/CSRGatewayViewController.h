//
//  CSRGatewayViewController.h
//  AcTECBLE
//
//  Created by AcTEC on 2021/5/25.
//  Copyright © 2021 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CSRGatewayViewController : UIViewController

@property (nonatomic,strong) NSNumber *deviceId;
typedef void (^RenameBlock)(void);
@property (nonatomic, strong) RenameBlock renameBlock;

@end

NS_ASSUME_NONNULL_END
