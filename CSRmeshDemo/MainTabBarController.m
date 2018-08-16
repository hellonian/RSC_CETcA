//
//  MainTabBarController.m
//  ActecBluetoothNorDic
//
//  Created by AcTEC on 2017/4/13.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import "MainTabBarController.h"
#import "PureLayout.h"
#import <MBProgressHUD.h>
#import "AppDelegate.h"

@interface MainTabBarController ()<TabBarDelegate,MBProgressHUDDelegate>

@property (nonatomic,strong) MBProgressHUD *hud;

@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.automaticallyAdjustsScrollViewInsets = NO;
//    self.view.backgroundColor = [UIColor blackColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bridgeConnectedNotification:) name:@"BridgeConnectedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bridgeDisconnectedNotification:) name:@"BridgeDisconnectedNotification" object:nil];
    
    self.tabBarView = [[TabBarView alloc]initWithFrame:CGRectMake(0, HEIGHT-self.tabBar.frame.size.height, WIDTH, self.tabBar.frame.size.height)];
    self.tabBarView.delegate = self;
    [self.view addSubview:self.tabBarView];
    
    [self creatHud];
    
}
-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    if (self.tabBar.frame.size.height == 83) {
        [self.tabBarView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.tabBarView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.tabBarView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:34.0f];
        [self.tabBarView autoSetDimension:ALDimensionHeight toSize:49.0f];
    }else {
        [self.tabBarView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.tabBarView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.tabBarView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [self.tabBarView autoSetDimension:ALDimensionHeight toSize:49.0f];
    }
}
-(void)didSelectedAtIndex:(NSInteger)index{
    self.selectedIndex = index;
}

- (void)bridgeConnectedNotification:(NSNotification *)notification {
    if (_hud) {
        [_hud hideAnimated:YES];
        [_hud removeFromSuperview];
        _hud = nil;
    }
}

- (void)bridgeDisconnectedNotification:(NSNotification *)notification {
    [self creatHud];
}

-(void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

- (void)creatHud {
    if (!_hud) {
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.mode = MBProgressHUDModeIndeterminate;
        _hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        _hud.bezelView.backgroundColor = [UIColor clearColor];
        _hud.backgroundView.backgroundColor = [UIColor blackColor];
        _hud.backgroundView.alpha = 0.6;
        _hud.activityIndicatorColor = [UIColor whiteColor];
        _hud.delegate = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (_hud) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
                NSMutableAttributedString *hogan = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"NoAvailableDevices", @"Localizable")];
                [hogan addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1] range:NSMakeRange(0, [[hogan string] length])];
                [alertController setValue:hogan forKey:@"attributedTitle"];
                NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"AllDevicesHaveBeenOccupied", @"Localizable")];
                [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
                [attributedMessage addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:NSMakeRange(0, [[attributedMessage string] length])];
                [alertController setValue:attributedMessage forKey:@"attributedMessage"];
                [alertController.view setTintColor:DARKORAGE];
                UIAlertAction *rescan = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Rescan", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [_hud hideAnimated:YES];
                    [_hud removeFromSuperview];
                    _hud = nil;
                    [self creatHud];
                }];
                UIAlertAction *exit = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Exit", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self exitApplication];
                }];
                [alertController addAction:rescan];
                [alertController addAction:exit];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        });
    }
}

- (void)exitApplication {
    AppDelegate *app =  (AppDelegate*)[UIApplication sharedApplication].delegate;
    UIWindow *window = app.window;
    
    [UIView animateWithDuration:1.0f animations:^{
        window.alpha = 0;
        window.frame = CGRectMake(0, window.bounds.size.width, 0, 0);
    } completion:^(BOOL finished) {
        exit(0);
    }];
}

@end
