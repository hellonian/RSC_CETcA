//
//  AboutViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/30.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "AboutViewController.h"

#import "DeviceModelManager.h"
#import <CSRmesh/LightModelApi.h>
#import "PureLayout.h"

@interface AboutViewController ()
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;
@property (weak, nonatomic) IBOutlet UILabel *wwwLabel;

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"About", @"Localizable");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange:) name:ZZAppLanguageDidChangeNotification object:nil];
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Setting", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(backSetting) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
        [self.copyrightLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10.0];
    }else {
        [self.copyrightLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:60.0];
    }
    
    [self.copyrightLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.copyrightLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
    [self.copyrightLabel autoSetDimension:ALDimensionHeight toSize:21.0];
    
    [self.wwwLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.wwwLabel autoSetDimension:ALDimensionHeight toSize:21.0];
    [self.wwwLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
    [self.wwwLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.copyrightLabel];
}
- (IBAction)TEST:(id)sender {
    UIColor *color = [UIColor redColor];
    CGFloat hue,saturation,brightness,alpha;
    if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        NSLog(@" %f \\ %f \\ %f \\ %f ",hue,saturation,brightness,alpha);
    }
    UIColor *color1 = [UIColor orangeColor];
    CGFloat hue1,saturation1,brightness1,alpha1;
    if ([color1 getHue:&hue1 saturation:&saturation1 brightness:&brightness1 alpha:&alpha1]) {
        NSLog(@"1| %f \\ %f \\ %f \\ %f ",hue1,saturation1,brightness1,alpha1);
    }
    UIColor *color2 = [UIColor yellowColor];
    CGFloat hue2,saturation2,brightness2,alpha2;
    if ([color2 getHue:&hue2 saturation:&saturation2 brightness:&brightness2 alpha:&alpha2]) {
        NSLog(@"2| %f \\ %f \\ %f \\ %f ",hue2,saturation2,brightness2,alpha2);
    }
    UIColor *color3 = [UIColor greenColor];
    CGFloat hue3,saturation3,brightness3,alpha3;
    if ([color3 getHue:&hue3 saturation:&saturation3 brightness:&brightness3 alpha:&alpha3]) {
        NSLog(@"3| %f \\ %f \\ %f \\ %f ",hue3,saturation3,brightness3,alpha3);
    }
    UIColor *color4 = [UIColor blueColor];
    CGFloat hue4,saturation4,brightness4,alpha4;
    if ([color4 getHue:&hue4 saturation:&saturation4 brightness:&brightness4 alpha:&alpha4]) {
        NSLog(@"4| %f \\ %f \\ %f \\ %f ",hue4,saturation4,brightness4,alpha4);
    }
    UIColor *color5 = [UIColor purpleColor];
    CGFloat hue5,saturation5,brightness5,alpha5;
    if ([color5 getHue:&hue5 saturation:&saturation5 brightness:&brightness5 alpha:&alpha5]) {
        NSLog(@"5| %f \\ %f \\ %f \\ %f ",hue5,saturation5,brightness5,alpha5);
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

- (void)languageChange:(id)sender {
//    self.navigationItem.title = AcTECLocalizedStringFromTable(@"About", @"Localizable");
//    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
//        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:AcTECLocalizedStringFromTable(@"Setting_back", @"Localizable")] style:UIBarButtonItemStylePlain target:self action:@selector(backSetting)];
//        self.navigationItem.leftBarButtonItem = left;
//    }
    if (self.isViewLoaded && !self.view.window) {
        self.view = nil;
    }
}

@end
