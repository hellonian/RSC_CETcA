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
@property (nonatomic,strong) UIAlertController *alertController;

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
    
    [self.tabBarView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self.tabBarView
                                                            attribute:NSLayoutAttributeLeft
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.view
                                                            attribute:NSLayoutAttributeLeft
                                                           multiplier:1.0
                                                             constant:0];
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self.tabBarView
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1.0
                                                              constant:0];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.tabBarView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationLessThanOrEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:1.0
                                                               constant:49.0];
    NSLayoutConstraint *bottom;
    if (@available(iOS 11.0, *)) {
        bottom = [NSLayoutConstraint constraintWithItem:self.tabBarView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view.safeAreaLayoutGuide
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1.0
                                               constant:0];
    }else {
        bottom = [NSLayoutConstraint constraintWithItem:self.tabBarView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1.0
                                               constant:0];
    }
    
    [NSLayoutConstraint activateConstraints:@[left,right,height,bottom]];
    
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
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:YES completion:nil];
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            _hud.mode = MBProgressHUDModeIndeterminate;
            _hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
            _hud.bezelView.backgroundColor = [UIColor clearColor];
            _hud.backgroundView.backgroundColor = [UIColor blackColor];
            _hud.backgroundView.alpha = 0.6;
            _hud.activityIndicatorColor = [UIColor whiteColor];
            _hud.delegate = self;
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (_hud) {
                _alertController = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
                NSMutableAttributedString *hogan = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"NoAvailableDevices", @"Localizable")];
                [hogan addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1] range:NSMakeRange(0, [[hogan string] length])];
                [_alertController setValue:hogan forKey:@"attributedTitle"];
                NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"AllDevicesHaveBeenOccupied", @"Localizable")];
                [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
                [attributedMessage addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:NSMakeRange(0, [[attributedMessage string] length])];
                [_alertController setValue:attributedMessage forKey:@"attributedMessage"];
                [_alertController.view setTintColor:DARKORAGE];
                UIAlertAction *rescan = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Rescan", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [_hud hideAnimated:YES];
                    [_hud removeFromSuperview];
                    _hud = nil;
                    [self creatHud];
                }];
                UIAlertAction *exit = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Exit", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self exitApplication];
                }];
                [_alertController addAction:rescan];
                [_alertController addAction:exit];
                [self presentViewController:_alertController animated:YES completion:nil];
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
