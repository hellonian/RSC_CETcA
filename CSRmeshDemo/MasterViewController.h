//
//  MasterViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/31.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol masterDelegate <NSObject>

- (void) didSelectRowAtMaster:(NSInteger)row;

@end

@interface MasterViewController : UIViewController

@property (nonatomic,weak) id<masterDelegate> delegate;

@end
