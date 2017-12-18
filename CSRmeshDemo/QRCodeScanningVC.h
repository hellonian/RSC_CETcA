//
//  QRCodeScanningVC.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/10/12.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QRCodeScanningVC : UIViewController

@property (nonatomic,copy) void(^handle)(NSString *uuid);

@end
