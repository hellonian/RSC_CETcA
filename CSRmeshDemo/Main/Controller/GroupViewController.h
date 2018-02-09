//
//  GroupViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/30.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainCollectionView.h"
#import "CSRAreaEntity.h"

typedef void(^GroupViewHandle)(void);

@interface GroupViewController : UIViewController

@property (nonatomic,assign) BOOL isCreateNewArea;
@property (nonatomic,strong) MainCollectionView *devicesCollectionView;
@property (nonatomic,strong) CSRAreaEntity *areaEntity;
@property (nonatomic,copy) GroupViewHandle handle;

@end
