//
//  GroupViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/30.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainCollectionView.h"

@interface GroupViewController : UIViewController

@property (nonatomic,assign) BOOL isEditing;
@property (nonatomic,strong) MainCollectionView *devicesCollectionView;

@end
