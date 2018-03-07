//
//  RemoteViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/30.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "RemoteViewController.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceEntity.h"
#import "CSRDevicesManager.h"
#import "PureLayout.h"
#import "AddDevcieViewController.h"
#import "RemoteSettingViewController.h"

@interface RemoteViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *dataArray;
@property (nonatomic,strong) CSRmeshDevice *deleteDevice;
@property (nonatomic,strong) UIView *noneDataView;
@property (nonatomic,assign) BOOL setSuccess;

@end

@implementation RemoteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.title = @"Remotes";
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Setting_back"] style:UIBarButtonItemStylePlain target:self action:@selector(backSetting)];
        self.navigationItem.leftBarButtonItem = left;
    }
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addClick)];
    self.navigationItem.rightBarButtonItem = add;
    
    [self getRemotesData];
    [self layoutViews];
    
}

- (void)backSetting{
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)addClick {
    AddDevcieViewController *addVC = [[AddDevcieViewController alloc] init];
    __weak RemoteViewController *weakSelf = self;
    addVC.handle = ^{
        [weakSelf getRemotesData];
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

- (void)getRemotesData {
    [self.dataArray removeAllObjects];
    NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
    if (mutableArray != nil || [mutableArray count] != 0) {
        for (CSRDeviceEntity *deviceEntity in mutableArray) {
            if ([deviceEntity.shortName isEqualToString:@"RC350"] || [deviceEntity.shortName isEqualToString:@"RC351"]) {
                [self.dataArray addObject:deviceEntity];
            }
        }
    }
}

- (void)layoutViews {
    if ([self.dataArray count] == 0) {
        [self.view addSubview:self.noneDataView];
        [_noneDataView autoSetDimension:ALDimensionWidth toSize:190.0];
        [_noneDataView autoSetDimension:ALDimensionHeight toSize:262.0];
        [_noneDataView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_noneDataView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:119.0];
        [self.tableView removeFromSuperview];
    }else {
        [self.view addSubview:self.tableView];
        if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
            [_tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(64, 0, 0, 0)];
        }else {
            [_tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(64, 0, 50, 0)];
        }
        [self.noneDataView removeFromSuperview];
        [self.tableView reloadData];
    }
}

#pragma mark - UITableViewDelegate,UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
    }
    CSRDeviceEntity *deviceEntity = self.dataArray[indexPath.row];
    if ([deviceEntity.shortName isEqualToString:@"RC350"]) {
        cell.imageView.image = [UIImage imageNamed:@"Setting_fremote"];
    }else if ([deviceEntity.shortName isEqualToString:@"RC351"]) {
        cell.imageView.image = [UIImage imageNamed:@"Setting_sremote"];
    }
    cell.textLabel.text = deviceEntity.name;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RemoteSettingViewController *rsvc = [[RemoteSettingViewController alloc] init];
    CSRDeviceEntity *deviceEntity = self.dataArray[indexPath.row];
    rsvc.remoteEntity = deviceEntity;
    __weak RemoteViewController *weakSelf = self;
    rsvc.reloadDataHandle = ^{
        [weakSelf getRemotesData];
        [weakSelf layoutViews];
    };
    [self.navigationController pushViewController:rsvc animated:YES];
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
        _tableView.rowHeight = 42.0f;
    }
    return _tableView;
}

- (UIView *)noneDataView {
    if (!_noneDataView) {
        _noneDataView = [[UIView alloc] init];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImage imageNamed:@"Remote_bg"];
        [_noneDataView addSubview:imageView];
        
        UILabel *label = [[UILabel alloc] init];
        label.text = @"You can add your bluetooth remotes and assign lights to the buttons of the remotes.";
        label.font = [UIFont systemFontOfSize:11];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        label.numberOfLines = 0;
        [_noneDataView addSubview:label];
        
        UIButton *btn = [[UIButton alloc] init];
        [btn setTitle:@"Add a remote" forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(addClick) forControlEvents:UIControlEventTouchUpInside];
        [_noneDataView addSubview:btn];
        
        [imageView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:_noneDataView];
        [imageView autoSetDimension:ALDimensionHeight toSize:172.0];
        [imageView autoSetDimension:ALDimensionWidth toSize:172.0];
        [imageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [label autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:imageView withOffset:20.0];
        [label autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [label autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [label autoSetDimension:ALDimensionHeight toSize:40];
        [btn autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [btn autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [btn autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [btn autoSetDimension:ALDimensionHeight toSize:15];
        
    }
    return _noneDataView;
}

@end
