//
//  JoinPlaceViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/15.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JoinPlaceViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *pinLabel;
@property (weak, nonatomic) IBOutlet UILabel *placefoundLabel;
@property (weak, nonatomic) IBOutlet UIButton *okButton;
@property (weak, nonatomic) IBOutlet UIImageView *okImageView;
@property (weak, nonatomic) IBOutlet UILabel *successLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@end
