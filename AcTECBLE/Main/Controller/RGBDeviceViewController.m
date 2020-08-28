//
//  RGBDeviceViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/8/30.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "RGBDeviceViewController.h"
#import "DeviceViewController.h"
#import "FavoriteViewController.h"
#import "MusicViewController.h"
#import "CSRDatabaseManager.h"
#import "PureLayout.h"
#import "MusicPlayTools.h"
#import "DeviceModelManager.h"

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
    
    if ([_deviceId integerValue]>32768/*单设备*/) {
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        self.navigationItem.title = device.name;
    }else {/*分组*/
        CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:_deviceId];
        self.navigationItem.title = area.areaName;
    }
    
    _selecteBtn = _dimmingBtn;
    
    _allViews = [[NSMutableArray alloc] init];
    
    DeviceViewController *dvc = [[DeviceViewController alloc] init];
    dvc.deviceId = _deviceId;
    dvc.reloadDataHandle = ^{
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:self.deviceId];
        self.navigationItem.title = deviceEntity.name;
        if (self.RGBDVCReloadDataHandle) {
            self.RGBDVCReloadDataHandle();
        }
    };
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
    _selecteBtn.backgroundColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1];
    _selecteBtn = sender;
    _selecteBtn.backgroundColor = DARKORAGE;
    
    [_threeView bringSubviewToFront:_allViews[sender.tag]];
    
//    if (sender.tag != 2) {
//        if ([MusicPlayTools shareMusicPlay].audioPlayer.playing) {
//            [[MusicPlayTools shareMusicPlay] musicStop];
//        }
//        if ([MusicPlayTools shareMusicPlay].audioRecorder.recording) {
//            [[MusicPlayTools shareMusicPlay] recordStop];
//        }
//    }
//    if (sender.tag != 1) {
//        [[DeviceModelManager sharedInstance] invalidateColofulTimer];
//    }
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
//    if ([MusicPlayTools shareMusicPlay].audioPlayer.playing) {
//        [[MusicPlayTools shareMusicPlay] musicStop];
//    }
//    if ([MusicPlayTools shareMusicPlay].audioRecorder.recording) {
//        [[MusicPlayTools shareMusicPlay] recordStop];
//    }
//    [[DeviceModelManager sharedInstance] invalidateColofulTimer];
}



@end
