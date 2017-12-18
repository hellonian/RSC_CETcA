//
//  TimerViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/30.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

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
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgImage"]];
    imageView.frame = [UIScreen mainScreen].bounds;
    [self.view addSubview:imageView];
    self.navigationItem.title = @"Timers";
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editClick)];
    self.navigationItem.rightBarButtonItem = edit;
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closeClick)];
    self.navigationItem.leftBarButtonItem = close;
    
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

- (void)closeClick {
    [self.navigationController popViewControllerAnimated:YES];
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
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closeClick)];
    self.navigationItem.leftBarButtonItem = close;
    
    self.tableView.editing = NO;
//    [self.tableView reloadData];
}

- (void)addClick {
    AddTimerViewController *avc = [[AddTimerViewController alloc] init];
    [DataModelManager shareInstance].delegate = self;
    [self.navigationController pushViewController:avc animated:YES];
    
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
        [_noneDataView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(100, 50, 100, 50)];
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
        header.contentView.backgroundColor = [UIColor colorWithRed:192/255.0 green:192/255.0 blue:192/255.0 alpha:1];
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(10, 5, 150, 34);
        label.tag = 201709111736;
        label.textColor = DARKORAGE;
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
//        [self.view addSubview:_noneDataView];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImage imageNamed:@"nonetimer"];
        [_noneDataView addSubview:imageView];
        
        UILabel *label = [[UILabel alloc] init];
        label.text = @"Timers allow you to turn ON and OFF based in time.";
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor lightGrayColor];
        label.numberOfLines = 0;
        [_noneDataView addSubview:label];
        
        UIButton *btn = [[UIButton alloc] init];
        [btn setTitle:@"Add a timer" forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(addClick) forControlEvents:UIControlEventTouchUpInside];
        [_noneDataView addSubview:btn];
        
//        [_noneDataView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(100, 50, 100, 50)];
        [imageView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:_noneDataView];
        [imageView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:_noneDataView];
        [imageView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:_noneDataView];
        [imageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:imageView];
        [label autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:imageView];
        [label autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:_noneDataView];
        [label autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [label autoSetDimension:ALDimensionHeight toSize:50];
        [btn autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:label withOffset:40];
        [btn autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [btn autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:_noneDataView withMultiplier:0.5];
        [btn autoSetDimension:ALDimensionHeight toSize:40];
        
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
