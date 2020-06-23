//
//  TimerViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/30.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "TimerViewController.h"
#import "TimerDetailViewController.h"
#import "PureLayout.h"
#import "CSRAppStateManager.h"
#import "TimerTableViewCell.h"
#import "CSRDeviceEntity.h"
#import "DataModelManager.h"

#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"

@interface TimerViewController ()<UITableViewDelegate,UITableViewDataSource, TimerTableViewCellDelegate>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UIView *noneDataView;
@property (nonatomic,strong) NSMutableArray *dataArray;

@property (nonatomic, strong) NSMutableArray *mMembersToApply;
@property (nonatomic, strong) NSMutableArray *fails;
@property (nonatomic, strong) CSRDeviceEntity *mDeviceToApply;
@property (nonatomic, strong) UIView *translucentBgView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) TimerEntity *sTimerEntity;
@property (nonatomic, assign) NSInteger sRow;

@end

@implementation TimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange) name:ZZAppLanguageDidChangeNotification object:nil];
    self.view.backgroundColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1];
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Timer", @"Localizable");
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteDeviceEntity) name:@"deleteDeviceEntity" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteDeviceEntity) name:@"reGetDataForPlaceChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enabledAlarmCall:) name:@"enabledAlarmCall" object:nil];
    
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
    
    [self getData];
    [self layoutView];
}

- (void)deleteDeviceEntity {
    [self getData];
    [self layoutView];
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
    NSSet *scenes = [CSRAppStateManager sharedInstance].selectedPlace.scenes;
    __block BOOL exit = NO;
    [scenes enumerateObjectsUsingBlock:^(SceneEntity  *scene, BOOL * _Nonnull stop) {
        if ([scene.members count] != 0) {
            exit = YES;
            *stop = YES;
        }
    }];
    if (!exit) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"" preferredStyle:UIAlertControllerStyleAlert];
        NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"AllSceneEmpty", @"Localizable")];
        [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
        [alertController setValue:attributedMessage forKey:@"attributedMessage"];
        [alertController.view setTintColor:DARKORAGE];
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:yesAction];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    TimerDetailViewController *tdvc = [[TimerDetailViewController alloc] init];
    tdvc.newadd = YES;
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
        [_tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
        
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
    
}

#pragma mark - UITableViewDelegate,UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataArray count];
}

- (TimerTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TimerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimerTableViewCell" forIndexPath:indexPath];
    cell.cellDelegate = self;
    TimerEntity *timerEntity = [_dataArray objectAtIndex:indexPath.row];
    [cell configureCellWithInfo:timerEntity row:indexPath.row];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    TimerDetailViewController *tdvc = [[TimerDetailViewController alloc] init];
    TimerEntity *timerEntity = [_dataArray objectAtIndex:indexPath.row];
    tdvc.timerEntity = timerEntity;
    tdvc.newadd = NO;
    __weak TimerViewController *weakSelf = self;
    tdvc.handle = ^{
        NSLog(@"TimerViewController");
        [weakSelf getData];
        [weakSelf layoutView];
    };
    [self.navigationController pushViewController:tdvc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (void)timercellChangeEnabled:(BOOL)enabled row:(NSInteger)row{
    _sTimerEntity = [_dataArray objectAtIndex:row];
    _sRow = row;
    
    _sTimerEntity.enabled = @(enabled);
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    if ([_sTimerEntity.timerDevices count] > 0) {
        [self showLoading];
        for (TimerDeviceEntity *td in _sTimerEntity.timerDevices) {
            [self.mMembersToApply addObject:td];
        }
        [self nextChangeEnableOpteration];
    }else {
        NSIndexPath *sPath = [NSIndexPath indexPathForRow:row inSection:0];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:sPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
}

- (BOOL)nextChangeEnableOpteration {
    if ([self.mMembersToApply count]>0) {
        TimerDeviceEntity *td = [self.mMembersToApply firstObject];
        _mDeviceToApply = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:td.deviceID];
        if (_mDeviceToApply == nil) {
            [_mMembersToApply removeObject:td];
            return [self nextChangeEnableOpteration];
        }else {
            Byte bIndex[]={};
            bIndex[0] = (Byte)(([td.timerIndex integerValue] & 0xFF00)>>8);
            bIndex[1] = (Byte)([td.timerIndex integerValue] & 0x00FF);
            
            [self performSelector:@selector(changeEnableTimeOut) withObject:nil afterDelay:10.0];
            
            if ([CSRUtilities belongToTwoChannelSwitch:_mDeviceToApply.shortName]
                || [CSRUtilities belongToThreeChannelSwitch:_mDeviceToApply.shortName]
                || [CSRUtilities belongToTwoChannelDimmer:_mDeviceToApply.shortName]
                || [CSRUtilities belongToSocketTwoChannel:_mDeviceToApply.shortName]
                || [CSRUtilities belongToTwoChannelCurtainController:_mDeviceToApply.shortName]) {
                Byte byte[] = {0x50, 0x05, 0x05, [td.channel integerValue], bIndex[1], bIndex[0], [_sTimerEntity.enabled boolValue]};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:7];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:td.deviceID data:cmd];
            }else {
                if ([_mDeviceToApply.cvVersion integerValue] > 18) {
                    Byte byte[] = {0x84, 0x03, bIndex[1], bIndex[0], [_sTimerEntity.enabled boolValue]};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:td.deviceID data:cmd];
                }else {
                    Byte byte[] = {0x84, 0x02, [td.timerIndex integerValue], [_sTimerEntity.enabled boolValue]};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:td.deviceID data:cmd];
                }
            }
            return YES;
        }
    }
    return NO;
}

- (void)changeEnableTimeOut {
    TimerDeviceEntity *td = [self.mMembersToApply firstObject];
    [self.mMembersToApply removeObject:td];
    [self.fails addObject:td];
    _mDeviceToApply = nil;
    if (![self nextChangeEnableOpteration]) {
        [self hideLoading];
        [self showFailAler];
    }
}

- (void)enabledAlarmCall:(NSNotification *)result {
    NSDictionary *userInfo = result.userInfo;
    NSNumber *dDeviceID = userInfo[@"deviceId"];
    NSNumber *channel = userInfo[@"channel"];
    BOOL state = [userInfo[@"state"] boolValue];
    TimerDeviceEntity *td = [self.mMembersToApply firstObject];
    if (td && [dDeviceID isEqualToNumber:td.deviceID] && [channel isEqualToNumber:td.channel]) {
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(changeEnableTimeOut) object:nil];
        
        [_mMembersToApply removeObject:td];
        if (!state) {
            [self.fails addObject:td];
        }
        
        if (![self nextChangeEnableOpteration]) {
            if ([self.fails count] > 0) {
                [self hideLoading];
                [self showFailAler];
            }else {
                [self hideLoading];
                NSIndexPath *sPath = [NSIndexPath indexPathForRow:_sRow inSection:0];
                [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:sPath] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }
}

- (void)showFailAler {
    NSString *ns = @"";
    for (TimerDeviceEntity *td in self.fails) {
        CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:td.deviceID];
        if ([CSRUtilities belongToTwoChannelSwitch:d.shortName]
            || [CSRUtilities belongToThreeChannelSwitch:d.shortName]
            || [CSRUtilities belongToTwoChannelDimmer:d.shortName]
            || [CSRUtilities belongToSocketTwoChannel:d.shortName]
            || [CSRUtilities belongToTwoChannelCurtainController:d.shortName]) {
            NSString *channelStr = @"";
            if ([td.channel integerValue] == 1) {
                channelStr = AcTECLocalizedStringFromTable(@"Channel1", @"Localizable");
            }else if ([td.channel integerValue] == 2) {
                channelStr = AcTECLocalizedStringFromTable(@"Channel2", @"Localizable");
            }else if ([td.channel integerValue] == 4) {
                channelStr = AcTECLocalizedStringFromTable(@"Channel3", @"Localizable");
            }
            ns = [NSString stringWithFormat:@"%@ %@(%@)",ns, d.name,channelStr];
        }else {
            ns = [NSString stringWithFormat:@"%@ %@",ns, d.name];
        }
    }
    NSString *message = [NSString stringWithFormat:@"%@ %@",AcTECLocalizedStringFromTable(@"enabletimerfail", @"Localizable"),ns];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.fails removeAllObjects];
        NSIndexPath *sPath = [NSIndexPath indexPathForRow:_sRow inSection:0];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:sPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
    [alert addAction:yes];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showLoading {
    [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
    [[UIApplication sharedApplication].keyWindow addSubview:self.indicatorView];
    [self.indicatorView autoCenterInSuperview];
    [self.indicatorView startAnimating];
    
}

- (void)hideLoading {
    [self.indicatorView stopAnimating];
    [self.indicatorView removeFromSuperview];
    [self.translucentBgView removeFromSuperview];
    self.indicatorView = nil;
    self.translucentBgView = nil;
}

- (UIView *)translucentBgView {
    if (!_translucentBgView) {
        _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _translucentBgView.backgroundColor = [UIColor blackColor];
        _translucentBgView.alpha = 0.4;
    }
    return _translucentBgView;
}

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] init];
        _indicatorView.hidesWhenStopped = YES;
    }
    return _indicatorView;
}

- (NSMutableArray *)mMembersToApply {
    if (!_mMembersToApply) {
        _mMembersToApply = [[NSMutableArray alloc] init];
    }
    return _mMembersToApply;
}

- (NSMutableArray *)fails {
    if (!_fails) {
        _fails = [[NSMutableArray alloc] init];
    }
    return _fails;
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
        label.text = AcTECLocalizedStringFromTable(@"TimerIntroduce", @"Localizable");
        label.font = [UIFont systemFontOfSize:11];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        label.numberOfLines = 0;
        [_noneDataView addSubview:label];
        
        UIButton *btn = [[UIButton alloc] init];
        [btn setTitle:AcTECLocalizedStringFromTable(@"AddTimer", @"Localizable") forState:UIControlStateNormal];
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

- (void)languageChange {
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Timer", @"Localizable");
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
                label.text = AcTECLocalizedStringFromTable(@"TimerIntroduce", @"Localizable");
            }else if ([obj isKindOfClass:[UIButton class]]) {
                UIButton *btn = (UIButton *)obj;
                [btn setTitle:AcTECLocalizedStringFromTable(@"AddTimer", @"Localizable") forState:UIControlStateNormal];
            }
        }];
    }
    if (_tableView) {
        [_tableView reloadData];
    }
}

@end
