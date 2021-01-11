//
//  RemoteViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2017/9/30.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "RemoteViewController.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceEntity.h"
#import "CSRDevicesManager.h"
#import "PureLayout.h"
#import "AddDevcieViewController.h"
#import "RemoteSettingViewController.h"
#import "CSRUtilities.h"

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange) name:ZZAppLanguageDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reGetDataForPlaceChanged) name:@"reGetDataForPlaceChanged" object:nil];
    self.view.backgroundColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1];
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Remote", @"Localizable");
    if (@available(iOS 11.0, *)) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(-35, 0, 0, 0);
    }
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
//    __weak RemoteViewController *weakSelf = self;
//    addVC.handle = ^{
//        [weakSelf getRemotesData];
//        [weakSelf layoutViews];
//    };
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromRight];
    [self.view.window.layer addAnimation:animation forKey:nil];
    UINavigationController *nav= [[UINavigationController alloc] initWithRootViewController:addVC];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:NO completion:nil];
}

- (void)getRemotesData {
    [self.dataArray removeAllObjects];
    NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
    if (mutableArray != nil || [mutableArray count] != 0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
        [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        for (CSRDeviceEntity *deviceEntity in mutableArray) {
            if ([CSRUtilities belongToRemote:deviceEntity.shortName]) {
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
        if (self.tableView) {
            [self.tableView removeFromSuperview];
        }
        
    }else {
        [self.view addSubview:self.tableView];
        if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
            [_tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
        }else {
            [_tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 50, 0)];
        }
        if (self.noneDataView) {
            [self.noneDataView removeFromSuperview];
        }
        
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
    if ([deviceEntity.shortName isEqualToString:@"RB01"]
        || [deviceEntity.shortName isEqualToString:@"R5BSBH"]
        || [deviceEntity.shortName isEqualToString:@"5BCBH"]) {
        cell.imageView.image = [UIImage imageNamed:@"setting_round_five_key_remote"];
    }else if ([deviceEntity.shortName isEqualToString:@"RB02"]
              || [deviceEntity.shortName isEqualToString:@"RB06"]
              || [deviceEntity.shortName isEqualToString:@"RSBH"]
              || [deviceEntity.shortName isEqualToString:@"1BMBH"]) {
        cell.imageView.image = [UIImage imageNamed:@"Setting_sremote"];
    }else if ([deviceEntity.shortName isEqualToString:@"RB04"]
              || [deviceEntity.shortName isEqualToString:@"RB07"]
              || [deviceEntity.shortName isEqualToString:@"RSIBH"]) {
        cell.imageView.image = [UIImage imageNamed:@"setting_hidden_controller"];
    }else if ([deviceEntity.shortName isEqualToString:@"R9BSBH"]) {
        cell.imageView.image = [UIImage imageNamed:@"setting_round_five_key_remote"];
    }else if ([deviceEntity.shortName isEqualToString:@"RB05"]) {
        cell.imageView.image = [UIImage imageNamed:@"setting_square_five_key_remote"];
    }else if ([deviceEntity.shortName isEqualToString:@"RB09"]
              || [deviceEntity.shortName isEqualToString:@"5RSIBH"]) {
        cell.imageView.image = [UIImage imageNamed:@"setting_hidden_controller"];
    }else if ([deviceEntity.shortName isEqualToString:@"RB08"]) {
        cell.imageView.image = [UIImage imageNamed:@"setting_E_knob"];
    }else if ([deviceEntity.shortName isEqualToString:@"6RSIBH"]
              || [deviceEntity.shortName isEqualToString:@"H1RSMB"]
              || [deviceEntity.shortName isEqualToString:@"H2RSMB"]
              || [deviceEntity.shortName isEqualToString:@"H3RSMB"]
              || [deviceEntity.shortName isEqualToString:@"H4RSMB"]
              || [deviceEntity.shortName isEqualToString:@"H5RSMB"]
              || [deviceEntity.shortName isEqualToString:@"H6RSMB"]
              || [deviceEntity.shortName isEqualToString:@"H1CSWB"]
              || [deviceEntity.shortName isEqualToString:@"H2CSWB"]
              || [deviceEntity.shortName isEqualToString:@"H3CSWB"]
              || [deviceEntity.shortName isEqualToString:@"H4CSWB"]
              || [deviceEntity.shortName isEqualToString:@"H6CSWB"]
              || [deviceEntity.shortName isEqualToString:@"H1CSB"]
              || [deviceEntity.shortName isEqualToString:@"H2CSB"]
              || [deviceEntity.shortName isEqualToString:@"H3CSB"]
              || [deviceEntity.shortName isEqualToString:@"H4CSB"]
              || [deviceEntity.shortName isEqualToString:@"H6CSB"]) {
        cell.imageView.image = [UIImage imageNamed:@"setting_hidden_controller"];
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
        _tableView.rowHeight = 60.0f;
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
        label.text = AcTECLocalizedStringFromTable(@"RemoteIntroduce", @"Localizable");
        label.font = [UIFont systemFontOfSize:11];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        label.numberOfLines = 0;
        [_noneDataView addSubview:label];
        
        UIButton *btn = [[UIButton alloc] init];
        [btn setTitle:AcTECLocalizedStringFromTable(@"AddRemote", @"Localizable") forState:UIControlStateNormal];
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

- (void)reGetDataForPlaceChanged {
    [self getRemotesData];
    [self layoutViews];
}

- (void)languageChange {
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Remote", @"Localizable");
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
                label.text = AcTECLocalizedStringFromTable(@"RemoteIntroduce", @"Localizable");
            }else if ([obj isKindOfClass:[UIButton class]]) {
                UIButton *btn = (UIButton *)obj;
                [btn setTitle:AcTECLocalizedStringFromTable(@"AddRemote", @"Localizable") forState:UIControlStateNormal];
            }
        }];
    }
}

@end
