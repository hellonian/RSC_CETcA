//
//  AboutViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2017/8/30.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "AboutViewController.h"

#import "PureLayout.h"
#import "ShowExceptionLogVC.h"

@interface AboutViewController ()
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;
@property (weak, nonatomic) IBOutlet UILabel *wwwLabel;
@property (weak, nonatomic) IBOutlet UIImageView *logo;

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
    
    UITapGestureRecognizer *showExceptionTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showExceptionLog)];
    showExceptionTap.numberOfTapsRequired = 5;
    [_logo addGestureRecognizer:showExceptionTap];
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

- (void)showExceptionLog {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dataPath = [path stringByAppendingPathComponent:@"Exception.txt"];
    NSData *data = [NSData dataWithContentsOfFile:dataPath];
    ShowExceptionLogVC *svc = [[ShowExceptionLogVC alloc] init];
    svc.path = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self.navigationController pushViewController:svc animated:YES];
}

@end
