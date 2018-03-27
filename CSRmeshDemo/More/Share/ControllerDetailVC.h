//
//  ControllerDetailVC.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/16.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSRControllerEntity.h"

@interface ControllerDetailVC : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *controllerDetailsTableView;
@property (weak, nonatomic) IBOutlet UITextField *controllerNameTF;
@property (weak, nonatomic) IBOutlet UIImageView *controllerImageView;


@property (nonatomic, retain) CSRControllerEntity *controllerEntity;

@end
