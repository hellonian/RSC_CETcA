//
//  MasterViewController.h
//  AcTECBLE
//
//  Created by AcTEC on 2017/8/31.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol masterDelegate <NSObject>

- (void) didSelectRowAtMaster:(NSIndexPath *)indexPath;

@end

@interface MasterViewController : UIViewController

@property (nonatomic,weak) id<masterDelegate> delegate;

@end
