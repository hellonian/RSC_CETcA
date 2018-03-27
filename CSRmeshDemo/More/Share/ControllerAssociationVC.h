//
//  ControllerAssociationVC.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/16.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSRControllerEntity.h"
#import "CSRmeshDevice.h"

@protocol CSRControllerAssociated <NSObject>

- (void) dismissAndPush:(CSRControllerEntity *)ctrlEnt;

@end

@interface ControllerAssociationVC : UIViewController

@property (weak, nonatomic) IBOutlet UIView *pinView;
@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UIView *successView;
@property (weak, nonatomic) IBOutlet UIView *failureView;
@property (weak, nonatomic) IBOutlet UITextField *pinTextField;
@property (weak, nonatomic) IBOutlet UIProgressView *associationProgressView;
@property (weak, nonatomic) IBOutlet UILabel *associationStepsInfoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *failureImageView;
@property (weak, nonatomic) IBOutlet UIImageView *successImageView;
@property (assign, nonatomic) id<CSRControllerAssociated> controllerDelegate;
@property (nonatomic) CSRmeshDevice *meshDevice;
@property (nonatomic) UIViewController *parent;

@end
