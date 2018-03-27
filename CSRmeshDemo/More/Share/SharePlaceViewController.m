//
//  SharePlaceViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/15.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SharePlaceViewController.h"
#import "JoinPlaceViewController.h"
#import "ControllersViewController.h"

@interface SharePlaceViewController ()

@end

@implementation SharePlaceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationItem.title = @"Share";
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Setting_back"] style:UIBarButtonItemStylePlain target:self action:@selector(backSetting)];
        self.navigationItem.leftBarButtonItem = left;
    }
    
}

- (void)backSetting{
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)joinPlace:(UIButton *)sender {
    JoinPlaceViewController *jpvc = [[JoinPlaceViewController alloc] init];
    [self.navigationController pushViewController:jpvc animated:YES];
}

- (IBAction)controllers:(UIButton *)sender {
    ControllersViewController *cvc = [[ControllersViewController alloc] init];
    
    [self.navigationController pushViewController:cvc animated:YES];
}

@end
