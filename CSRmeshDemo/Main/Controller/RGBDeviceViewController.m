//
//  RGBDeviceViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/8/30.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "RGBDeviceViewController.h"
#import "DeviceViewController.h"
#import "FavoriteViewController.h"
#import "MusicViewController.h"
#import "CSRDatabaseManager.h"
#import "PureLayout.h"

@interface RGBDeviceViewController ()

@property (weak, nonatomic) IBOutlet UIView *threeView;
@property (nonatomic,strong) NSMutableArray *allViews;
@property (nonatomic,strong) UIButton *selecteBtn;
@property (weak, nonatomic) IBOutlet UIButton *dimmingBtn;

@end

@implementation RGBDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
    }
    
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    self.navigationItem.title = device.name;
    
    _selecteBtn = _dimmingBtn;
    
    _allViews = [[NSMutableArray alloc] init];
    
    DeviceViewController *dvc = [[DeviceViewController alloc] init];
    dvc.deviceId = _deviceId;
    [self addChildViewController:dvc];
    [_threeView addSubview:dvc.view];
    [dvc.view autoPinEdgesToSuperviewEdges];
    [_allViews addObject:dvc.view];
    
    FavoriteViewController *fvc = [[FavoriteViewController alloc] init];
    fvc.deviceId = _deviceId;
    [self addChildViewController:fvc];
    [_threeView addSubview:fvc.view];
    [fvc.view autoPinEdgesToSuperviewEdges];
    [_allViews addObject:fvc.view];
    
    MusicViewController *mvc = [[MusicViewController alloc] init];
    mvc.deviceId = _deviceId;
    [self addChildViewController:mvc];
    [_threeView addSubview:mvc.view];
    [mvc.view autoPinEdgesToSuperviewEdges];
    [_allViews addObject:mvc.view];
    
    [_threeView bringSubviewToFront:_allViews.firstObject];
    
}

- (IBAction)switchThreeView:(UIButton *)sender {
    _selecteBtn.backgroundColor = [UIColor colorWithRed:225/255.0 green:225/255.0 blue:225/255.0 alpha:1];
    _selecteBtn = sender;
    _selecteBtn.backgroundColor = DARKORAGE;
    
    [_threeView bringSubviewToFront:_allViews[sender.tag]];
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
