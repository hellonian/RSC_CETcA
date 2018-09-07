//
//  LightSensorViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/6/14.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "LightSensorViewController.h"
#import "AddDevcieViewController.h"
#import "CSRDeviceEntity.h"
#import "CSRAppStateManager.h"
#import "CSRUtilities.h"

#import "LightSensorSettingViewController.h"
#import "PureLayout.h"
#import <CSRmesh/PowerModelApi.h>
#import "DeviceModelManager.h"

@interface LightSensorViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) NSMutableArray *dataArray;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UIView *noneDataView;

@end

@implementation LightSensorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange) name:ZZAppLanguageDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reGetDataForPlaceChanged) name:@"reGetDataForPlaceChanged" object:nil];
    if (@available(iOS 11.0, *)) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(-35, 0, 0, 0);
    }
    self.view.backgroundColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1];
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"LightSensor", @"Localizable");
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Setting", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(backSetting) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
    }
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addClick)];
    self.navigationItem.rightBarButtonItem = add;
    
    [self getLightSensorData];
    [self layoutViews];
}

- (void)addClick {
    AddDevcieViewController *addVC = [[AddDevcieViewController alloc] init];
    __weak LightSensorViewController *weakSelf = self;
    addVC.handle = ^{
        [weakSelf getLightSensorData];
        [weakSelf layoutViews];
    };
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromRight];
    [self.view.window.layer addAnimation:animation forKey:nil];
    UINavigationController *nav= [[UINavigationController alloc] initWithRootViewController:addVC];
    [self presentViewController:nav animated:NO completion:nil];
}

- (void)backSetting{
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)getLightSensorData {
    [self.dataArray removeAllObjects];
    NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
    if (mutableArray != nil || [mutableArray count] != 0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
        [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        for (CSRDeviceEntity *deviceEntity in mutableArray) {
            if ([CSRUtilities belongToLightSensor:deviceEntity.shortName]) {
                [self.dataArray addObject:deviceEntity];
            }
        }
    }
}

- (void)layoutViews {
    if ([self.dataArray count] == 0) {
        [self.view addSubview:self.noneDataView];
        [_noneDataView autoSetDimension:ALDimensionWidth toSize:190.0];
        [_noneDataView autoSetDimension:ALDimensionHeight toSize:300.0];
        [_noneDataView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_noneDataView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:119.0];
        if (self.tableView) {
            [self.tableView removeFromSuperview];
        }
        
    }else {
        [self.view addSubview:self.tableView];
        [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSLayoutConstraint *top;
        if (@available(iOS 11.0, *)) {
            top = [NSLayoutConstraint constraintWithItem:self.tableView
                                               attribute:NSLayoutAttributeTop
                                               relatedBy:NSLayoutRelationEqual
                                                  toItem:self.view.safeAreaLayoutGuide
                                               attribute:NSLayoutAttributeTop
                                              multiplier:1.0
                                                constant:0];
        } else {
            top = [NSLayoutConstraint constraintWithItem:self.tableView
                                               attribute:NSLayoutAttributeTop
                                               relatedBy:NSLayoutRelationEqual
                                                  toItem:self.view
                                               attribute:NSLayoutAttributeTop
                                              multiplier:1.0
                                                constant:0];
        }
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self.tableView
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1.0
                                                                 constant:0];
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self.tableView
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.view
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1.0
                                                                  constant:0];
        NSLayoutConstraint *bottom;
        if (@available(iOS 11.0, *)) {
            bottom = [NSLayoutConstraint constraintWithItem:self.tableView
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view.safeAreaLayoutGuide
                                                  attribute:NSLayoutAttributeBottom
                                                 multiplier:1.0
                                                   constant:0];
        } else {
            bottom = [NSLayoutConstraint constraintWithItem:self.tableView
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.view
                                                  attribute:NSLayoutAttributeBottom
                                                 multiplier:1.0
                                                   constant:0];
        }
        [NSLayoutConstraint  activateConstraints:@[top,left,right,bottom]];
        if (self.noneDataView) {
            [self.noneDataView removeFromSuperview];
        }
        
        [self.tableView reloadData];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        cell.imageView.image = [UIImage imageNamed:@"Setting_sensorDevice"];
        UISwitch *powerSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        powerSwitch.tag = 621;
        powerSwitch.onTintColor = DARKORAGE;
        [powerSwitch addTarget:self action:@selector(powerAction:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:powerSwitch];
        [powerSwitch autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [powerSwitch autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16];
    }
    CSRDeviceEntity *deviceEntity = self.dataArray[indexPath.row];
    cell.textLabel.text = deviceEntity.name;
    cell.contentView.tag = [deviceEntity.deviceId integerValue];
    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceEntity.deviceId];
    UISwitch *powerSwitch = (UISwitch *)[cell.contentView viewWithTag:621];
    [powerSwitch setOn:[deviceModel.powerState boolValue]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LightSensorSettingViewController *lssvc = [[LightSensorSettingViewController alloc] init];
    lssvc.lightSensor = self.dataArray[indexPath.row];
    __weak LightSensorViewController *weakSelf = self;
    lssvc.reloadDataHandle = ^{
        [weakSelf getLightSensorData];
        [weakSelf layoutViews];
    };
    
    [self.navigationController pushViewController:lssvc animated:YES];
}

#pragma mark - lazy

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc] init];
    }
    return _dataArray;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundView = [[UIView alloc] init];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.rowHeight = 60.0f;
    }
    return _tableView;
}

- (void)reGetDataForPlaceChanged {
    [self getLightSensorData];
    [self layoutViews];
}

- (void)languageChange {
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"LightSensor", @"Localizable");
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Setting", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(backSetting) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
    }
    if (_noneDataView) {
        [_noneDataView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)obj;
                label.text = AcTECLocalizedStringFromTable(@"LightSensorIntroduce", @"Localizable");
            }else if ([obj isKindOfClass:[UIButton class]]) {
                UIButton *btn = (UIButton *)obj;
                [btn setTitle:AcTECLocalizedStringFromTable(@"AddLightSensor", @"Localizable") forState:UIControlStateNormal];
            }
        }];
    }
}

- (void)powerAction:(UISwitch *)sender {
    
    [[PowerModelApi sharedInstance] setPowerState:@(sender.superview.tag) state:[NSNumber numberWithBool:sender.on] success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable state) {

    } failure:^(NSError * _Nullable error) {

    }];
}

- (UIView *)noneDataView {
    if (!_noneDataView) {
        _noneDataView = [[UIView alloc] init];
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImage imageNamed:@"LightSensor_bg"];
        [_noneDataView addSubview:imageView];
        
        UILabel *label = [[UILabel alloc] init];
        label.text = AcTECLocalizedStringFromTable(@"LightSensorIntroduce", @"Localizable");
        label.font = [UIFont systemFontOfSize:11];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        label.numberOfLines = 0;
        [_noneDataView addSubview:label];
        
        UIButton *btn = [[UIButton alloc] init];
        [btn setTitle:AcTECLocalizedStringFromTable(@"AddLightSensor", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(addClick) forControlEvents:UIControlEventTouchUpInside];
        [_noneDataView addSubview:btn];
        
        [imageView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:_noneDataView];
        [imageView autoSetDimension:ALDimensionHeight toSize:168.0];
        [imageView autoSetDimension:ALDimensionWidth toSize:200.0];
        [imageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [label autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:imageView withOffset:20.0];
        [label autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [label autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [label autoSetDimension:ALDimensionHeight toSize:80];
        [btn autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [btn autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [btn autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [btn autoSetDimension:ALDimensionHeight toSize:15];
    }
    return _noneDataView;
}

@end
