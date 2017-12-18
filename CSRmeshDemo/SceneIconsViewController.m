//
//  SceneIconsViewController.m
//  BluetoothAcTEC
//
//  Created by AcTEC on 2017/6/8.
//  Copyright © 2017年 hua. All rights reserved.
//

#import "SceneIconsViewController.h"

@interface SceneIconsViewController ()

@property (nonatomic,strong) UIView *bgView;

@end

@implementation SceneIconsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneClick)];
        self.navigationItem.rightBarButtonItem = done;
    }
    
    [self.view addSubview:self.bgView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    
}

-(void)tapAction:(UITapGestureRecognizer *)sender{

    CGPoint touch = [sender locationInView:self.view];
    
    for (int i =0; i<self.view.subviews.count; i++) {
        UIImageView *imageV = self.view.subviews[i];
        CGSize reference = imageV.bounds.size;
        CGFloat offsetX = ABS(imageV.center.x - touch.x);
        CGFloat offsetY = ABS(imageV.center.y - touch.y);
        if (offsetX <= reference.width*0.5 && offsetY<=reference.height*0.5){
            if (self.click) {
                self.click(imageV.tag);
            }
            [UIView animateWithDuration:0.3 animations:^{
                self.bgView.center = CGPointMake(imageV.center.x, imageV.center.y);
            }];
            return;
        }
    }
}

-(void)doneClick{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [UIColor colorWithRed:234/255.0 green:94/255.0 blue:18/255.0 alpha:0.3];
        _bgView.bounds = CGRectMake(0, 0, 80.0, 80.0);
        _bgView.layer.masksToBounds = YES;
        _bgView.layer.cornerRadius = 40.0;
    }
    return _bgView;
}


@end
