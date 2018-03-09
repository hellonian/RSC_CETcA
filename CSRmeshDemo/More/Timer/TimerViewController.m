//
//  TimerViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/30.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "TimerViewController.h"
#import "TimerDetailViewController.h"
#import "PureLayout.h"
#import "CSRAppStateManager.h"
#import "TimerTableViewCell.h"
#import "CSRDeviceEntity.h"
#import "DataModelManager.h"

@interface TimerViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UIView *noneDataView;
@property (nonatomic,strong) NSMutableArray *dataArray;


@end

@implementation TimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1];
    self.navigationItem.title = @"Timers";
    self.automaticallyAdjustsScrollViewInsets = NO;
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Setting_back"] style:UIBarButtonItemStylePlain target:self action:@selector(backSetting)];
        self.navigationItem.leftBarButtonItem = left;
    }
    
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editClick)];
    self.navigationItem.rightBarButtonItem = edit;
    
    [self getData];
    [self layoutView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTimerProfile:) name:kTimerProfile object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTimerProfile object:nil];
}

- (void)backSetting{
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)editClick {
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneClick)];
    self.navigationItem.rightBarButtonItem = done;
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addClick)];
    self.navigationItem.leftBarButtonItem = add;
    
}

- (void)doneClick {
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editClick)];
    self.navigationItem.rightBarButtonItem = edit;
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Setting_back"] style:UIBarButtonItemStylePlain target:self action:@selector(backSetting)];
        self.navigationItem.leftBarButtonItem = left;
    }else {
        self.navigationItem.leftBarButtonItem = nil;
    }
    
}

- (void)addClick {
    TimerDetailViewController *tdvc = [[TimerDetailViewController alloc] init];
    __weak TimerViewController *weakSelf = self;
    tdvc.handle = ^{
        [weakSelf getData];
        [weakSelf layoutView];
    };
    
    [self.navigationController pushViewController:tdvc animated:YES];
}

- (void)layoutView {
    if ([self.dataArray count] == 0) {
        [self.view addSubview:self.noneDataView];
        [_noneDataView autoSetDimension:ALDimensionWidth toSize:190.0];
        [_noneDataView autoSetDimension:ALDimensionHeight toSize:262.0];
        [_noneDataView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_noneDataView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:119.0];
        [self.tableView removeFromSuperview];
    }else {
        [self.view addSubview:self.tableView];
        [_tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(64, 0, 50, 0)];
        [self.noneDataView removeFromSuperview];
    }
    [self.tableView reloadData];
}


- (void)getData {
    
    NSMutableArray *timerMutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.timers allObjects] mutableCopy];
    
    if (timerMutableArray != nil || [timerMutableArray count] != 0 ) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"timerID" ascending:YES];
        [timerMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        
        self.dataArray = timerMutableArray;
        
    }
    
    [self getDeviceTimer];
    
    
    
}

- (void)getDeviceTimer {
    NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
    if (mutableArray != nil || [mutableArray count] != 0) {
        [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([deviceEntity.shortName isEqualToString:@"D350BT"] || [deviceEntity.shortName isEqualToString:@"S350BT"]) {
                
                [[DataModelManager shareInstance] readAlarmMessageByDeviceId:deviceEntity.deviceId];
                
            }
        }];
    }
}

- (void)receiveTimerProfile:(NSNotification *)result {
    NSDictionary *timerInfo = result.userInfo;
    NSArray *timersArray = [timerInfo objectForKey:kTimerProfile];
    NSNumber *deviceId = [timerInfo objectForKey:@"deviceId"];
    
    
    
    
}

#pragma mark - UITableViewDelegate,UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataArray count];
}

- (TimerTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TimerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimerTableViewCell" forIndexPath:indexPath];
    TimerEntity *timerEntity = [_dataArray objectAtIndex:indexPath.row];
    [cell configureCellWithInfo:timerEntity];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    TimerDetailViewController *tdvc = [[TimerDetailViewController alloc] init];
    TimerEntity *timerEntity = [_dataArray objectAtIndex:indexPath.row];
    tdvc.timerEntity = timerEntity;
    __weak TimerViewController *weakSelf = self;
    tdvc.handle = ^{
        [weakSelf getData];
        [weakSelf layoutView];
    };
    [self.navigationController pushViewController:tdvc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

#pragma mark - Lazy

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [NSMutableArray new];
    }
    return _dataArray;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 88.0f;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.backgroundView = [[UIView alloc] init];
        _tableView.backgroundColor = [UIColor clearColor];
        [_tableView registerNib:[UINib nibWithNibName:@"TimerTableViewCell" bundle:nil] forCellReuseIdentifier:@"TimerTableViewCell"];
    }
    return _tableView;
}

- (UIView *)noneDataView {
    if (!_noneDataView) {
        _noneDataView = [[UIView alloc] init];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImage imageNamed:@"Timer_bg"];
        [_noneDataView addSubview:imageView];
        
        UILabel *label = [[UILabel alloc] init];
        label.text = @"Timers allow you to turn ON and OFF based in time.";
        label.font = [UIFont systemFontOfSize:11];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        label.numberOfLines = 0;
        [_noneDataView addSubview:label];
        
        UIButton *btn = [[UIButton alloc] init];
        [btn setTitle:@"Add a timer" forState:UIControlStateNormal];
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
        [btn autoSetDimension:ALDimensionHeight toSize:30];
        
    }
    return _noneDataView;
}

@end

/*
#import "TimerViewController.h"
#import "TimerCell.h"
#import "PureLayout.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceEntity.h"
#import "DataModelManager.h"
#import "TimeSchedule.h"
#import "TimerTool.h"
#import "AddTimerViewController.h"
#import <MBProgressHUD.h>

#import "TimerDetailViewController.h"

@interface TimerViewController ()<UITableViewDelegate,UITableViewDataSource,MBProgressHUDDelegate,DataModelManagerDelegate>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UIView *noneDataView;
@property (nonatomic,copy) NSArray *dataKeyArray;
@property (nonatomic,copy) NSMutableDictionary *dataDic;

@end

@implementation TimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1];
    self.navigationItem.title = @"Timers";
    self.automaticallyAdjustsScrollViewInsets = NO;
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Setting_back"] style:UIBarButtonItemStylePlain target:self action:@selector(backSetting)];
        self.navigationItem.leftBarButtonItem = left;
    }
    
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editClick)];
    self.navigationItem.rightBarButtonItem = edit;
    
    [self updateTableView];
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTimerProfile:) name:kTimerProfile object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideHudAndShowText:) name:@"deleteAlarmCall" object:nil];
}

- (void)addAlarmSuccessCall:(TimeSchedule *)schedule {
    [TimerTool saveNewTimerIndex:schedule.timerIndex forDevice:schedule.deviceId];
    NSMutableArray *mutary = [[self.dataDic objectForKey:schedule.deviceId] mutableCopy];
    if (mutary) {
        [mutary addObject:schedule];
        [self.dataDic setObject:mutary forKey:schedule.deviceId];
    }else {
        [self.dataDic setObject:@[schedule] forKey:schedule.deviceId];
    }
    
    self.dataKeyArray = [self.dataDic allKeys];
    
    [self updateTableView];
}

- (void)backSetting{
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)editClick {
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneClick)];
    self.navigationItem.rightBarButtonItem = done;
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addClick)];
    self.navigationItem.leftBarButtonItem = add;
    
    self.tableView.editing = YES;
//    [self.tableView reloadData];
    
}

- (void)doneClick {
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editClick)];
    self.navigationItem.rightBarButtonItem = edit;
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Setting_back"] style:UIBarButtonItemStylePlain target:self action:@selector(backSetting)];
        self.navigationItem.leftBarButtonItem = left;
    }else {
        self.navigationItem.leftBarButtonItem = nil;
    }
    
    self.tableView.editing = NO;
//    [self.tableView reloadData];
}

- (void)addClick {
//    AddTimerViewController *avc = [[AddTimerViewController alloc] init];
//    [DataModelManager shareInstance].delegate = self;
//    [self.navigationController pushViewController:avc animated:YES];
    
    TimerDetailViewController *tdvc = [[TimerDetailViewController alloc] init];
    
    
    [self.navigationController pushViewController:tdvc animated:YES];
}

- (void)loadData {
    [self.dataDic removeAllObjects];
    
    NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
    if (mutableArray != nil || [mutableArray count] !=0) {
        for (CSRDeviceEntity *deviceEntity in mutableArray) {
            if (![deviceEntity.shortName isEqualToString:@"RC350"]) {
                [[DataModelManager shareInstance] ReadAlarmMessageByDeviceId:deviceEntity.deviceId];
            }
        }
    }
    
}

- (void)receiveTimerProfile:(NSNotification *)result {
    NSDictionary *timerInfo = result.userInfo;
    NSArray *timersArray = [timerInfo objectForKey:kTimerProfile];
    for (TimeSchedule *profile in timersArray) {
        [TimerTool saveNewTimerIndex:profile.timerIndex forDevice:profile.deviceId];
    }
    
    NSNumber *deviceId = [timerInfo objectForKey:@"deviceId"];
    [self.dataDic setObject:timersArray forKey:deviceId];
    self.dataKeyArray = [self.dataDic allKeys];
    
    [self updateTableView];
}

- (void)updateTableView {
    if ([self.dataDic count] == 0) {
        [self.view addSubview:self.noneDataView];
        [_noneDataView autoSetDimension:ALDimensionWidth toSize:190.0];
        [_noneDataView autoSetDimension:ALDimensionHeight toSize:262.0];
        [_noneDataView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_noneDataView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:119.0];
        [self.tableView removeFromSuperview];
    }else {
        [self.view addSubview:self.tableView];
        [_tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(64, 0, 50, 0)];
        [self.noneDataView removeFromSuperview];
    }
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate,UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataDic.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSNumber *deviceId = self.dataKeyArray[section];
    NSArray *array = [self.dataDic objectForKey:deviceId];
    return array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TimerCell *timerCell = [tableView dequeueReusableCellWithIdentifier:@"TimerCell" forIndexPath:indexPath];
    TimeSchedule *schedule = [_dataDic objectForKey:_dataKeyArray[indexPath.section]][indexPath.row];
    [timerCell configureCellWithInfo:schedule];
//    if (self.tableView.editing) {
//        timerCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//        timerCell.enSwitch.hidden = YES;
//    }else{
//        timerCell.accessoryType = UITableViewCellAccessoryNone;
//        timerCell.enSwitch.hidden = NO;
//    }
    
    return timerCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"head"];
    if (!header) {
        header = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"head"];
        header.contentView.backgroundColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1];
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(10, 5, 150, 34);
        label.tag = 201709111736;
        label.textColor = [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1];
        [header.contentView addSubview:label];
    }
    UILabel *lab = (UILabel *)[header.contentView viewWithTag:201709111736];
    NSArray *ary = [self.dataDic objectForKey:self.dataKeyArray[section]];
    TimeSchedule *profile = [ary firstObject];
    lab.text = profile.lightNickname;
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

//-(void)updateViewConstraints {
//    [super updateViewConstraints];
//    [self.tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(64, 0, 0, 0)];
//}

#pragma mark - 编辑表

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *array = [[_dataDic objectForKey:_dataKeyArray[indexPath.section]] mutableCopy];
        TimeSchedule *schedule = [array objectAtIndex:indexPath.row];
            
        [[DataModelManager shareInstance] deleteAlarmForDevice:schedule.deviceId index:schedule.timerIndex];
        
        [TimerTool removeTimerIndex:schedule.timerIndex forDevice:schedule.deviceId];
        
        [array removeObjectAtIndex:indexPath.row];
        [_dataDic setObject:array forKey:_dataKeyArray[indexPath.section]];
        if (array.count == 0) {
            [_dataDic removeObjectForKey:_dataKeyArray[indexPath.section]];
        }
        
        [self updateTableView];
        
    }
}

- (void)hideHudAndShowText:(NSNotification *)result {
    NSDictionary *resultDic = result.userInfo;
    NSString *resultStr = [resultDic objectForKey:@"deleteAlarmCall"];
    if ([resultStr boolValue]) {
        [self showTextHud:@"SUCCESS"];
    }else {
        [self showTextHud:@"ERROR"];
    }
}

- (void)showTextHud:(NSString *)text {
    MBProgressHUD *successHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    successHud.mode = MBProgressHUDModeText;
    successHud.label.text = text;
    successHud.delegate = self;
    [successHud hideAnimated:YES afterDelay:1.5f];
}

#pragma mark - Lazy

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_tableView registerNib:[UINib nibWithNibName:@"TimerCell" bundle:nil] forCellReuseIdentifier:@"TimerCell"];
    }
    return _tableView;
}

- (UIView *)noneDataView {
    if (!_noneDataView) {
        _noneDataView = [[UIView alloc] init];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImage imageNamed:@"Timer_bg"];
        [_noneDataView addSubview:imageView];
        
        UILabel *label = [[UILabel alloc] init];
        label.text = @"Timers allow you to turn ON and OFF based in time.";
        label.font = [UIFont systemFontOfSize:11];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        label.numberOfLines = 0;
        [_noneDataView addSubview:label];
        
        UIButton *btn = [[UIButton alloc] init];
        [btn setTitle:@"Add a timer" forState:UIControlStateNormal];
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
        [btn autoSetDimension:ALDimensionHeight toSize:30];
        
    }
    return _noneDataView;
}

- (NSMutableDictionary *)dataDic {
    if (!_dataDic) {
        _dataDic = [[NSMutableDictionary alloc] init];
    }
    return _dataDic;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    
    [hud removeFromSuperview];
    
    hud = nil;
    
}

@end
 */
