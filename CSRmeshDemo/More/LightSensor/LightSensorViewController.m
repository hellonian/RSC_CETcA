//
//  LightSensorViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/6/14.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
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
        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:AcTECLocalizedStringFromTable(@"Setting_back", @"Localizable")] style:UIBarButtonItemStylePlain target:self action:@selector(backSetting)];
        self.navigationItem.leftBarButtonItem = left;
    }
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addClick)];
    self.navigationItem.rightBarButtonItem = add;
    
    [self getLightSensorData];
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
}

- (void)addClick {
    AddDevcieViewController *addVC = [[AddDevcieViewController alloc] init];
    __weak LightSensorViewController *weakSelf = self;
    addVC.handle = ^{
        [weakSelf getLightSensorData];
        [self.tableView reloadData];
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
        [weakSelf.tableView reloadData];
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
    [self.tableView reloadData];
}

- (void)languageChange {
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"LightSensor", @"Localizable");
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:AcTECLocalizedStringFromTable(@"Setting_back", @"Localizable")] style:UIBarButtonItemStylePlain target:self action:@selector(backSetting)];
        self.navigationItem.leftBarButtonItem = left;
    }
}

- (void)powerAction:(UISwitch *)sender {
    
    [[PowerModelApi sharedInstance] setPowerState:@(sender.superview.tag) state:[NSNumber numberWithBool:sender.on] success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable state) {

    } failure:^(NSError * _Nullable error) {

    }];
}

@end
