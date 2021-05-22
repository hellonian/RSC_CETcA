//
//  ThermoregulatorViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2021/4/29.
//  Copyright © 2021 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "ThermoregulatorViewController.h"
#import "CSRDatabaseManager.h"
#import "DataModelManager.h"
#import "DeviceModelManager.h"
#import "SelectionListView.h"
#import "SelectionListModel.h"

#define sectionOneKeys @[@"名称", @"MAC"]
#define sectionOtherKeys @[@"温控开关", @"风速", @"温度", @"模式", @"风向"]
#define TFENGSU @[@"自动", @"超低速", @"中低速", @"中速", @"中高速", @"高速", @"超高速"]
#define TWENDU @[@"16 ℃", @"17 ℃", @"18 ℃", @"19 ℃", @"20 ℃", @"21 ℃", @"22 ℃", @"23 ℃", @"24 ℃", @"25 ℃", @"26 ℃", @"27 ℃", @"28 ℃", @"29 ℃", @"30 ℃"]
#define TMOSHI @[@"自动", @"制冷", @"制热", @"除湿", @"送风"]
#define TFENGXIANG @[@"自动", @"向上", @"向下", @"向左", @"向右"]
#define TROWS @[TFENGSU, TWENDU, TMOSHI, TFENGXIANG]


@interface ThermoregulatorViewController ()<UITableViewDelegate, UITableViewDataSource, SelectionListViewDelegate>

@property (nonatomic, strong) CSRDeviceEntity *device;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) NSMutableArray *channels;
@property (nonatomic, assign) NSInteger applyChannel;
@property (nonatomic, assign) NSInteger applyRetryCount;
@property (nonatomic, strong) NSData *applyCmd;
@property (nonatomic, strong) SelectionListView *selectionView;
@property (nonatomic, strong) UIView *translucentBgView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, assign) NSInteger controlChannel;

@end

@implementation ThermoregulatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (_source == 1) {
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
        self.navigationItem.rightBarButtonItem = done;
    }else {
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setPowerStateSuccess:)
                                                 name:@"setPowerStateSuccess"
                                               object:nil];
    if (_deviceId) {
        _device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        self.title = _device.name;
        _dataArray = [NSMutableArray new];
        [_dataArray addObject:@[_device.name,[self macStringConcatenate]]];
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        NSInteger channel = [_device.port integerValue];
        if (channel > 0) {
            _channels = [NSMutableArray new];
            for (int i=1; i<=channel; i++) {
                [_channels addObject:@(i)];
                NSArray *states = [model.stateDic objectForKey:@(i)];
                if (states) {
                    [_dataArray addObject:states];
                }else {
                    [_dataArray addObject:@[@(0), @(0), @(0), @(0), @(0)]];
                }
            }
        }
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.rowHeight = 44.0;
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 0.001)];
        [self.view addSubview:_tableView];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 11.0, *)) {
            NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view.safeAreaLayoutGuide attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
            NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view.safeAreaLayoutGuide attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
            NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
            NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view.safeAreaLayoutGuide attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
            [NSLayoutConstraint activateConstraints:@[top, left, bottom, right]];
        } else {
            // Fallback on earlier versions
        }
        
        if (channel > 0) {
            if ([model.stateDic count] == 0) {
                [self.view addSubview:self.translucentBgView];
                [self.view addSubview:self.indicatorView];
                [self.indicatorView startAnimating];
                _indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
                NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:_indicatorView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
                NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:_indicatorView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
                [NSLayoutConstraint activateConstraints:@[centerX, centerY]];
                [self nextThermoregulatorStateOperation];
            }
        }
    }
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)macStringConcatenate {
    NSString *macAddr = [_device.uuid substringFromIndex:24];
    NSString *doneTitle = @"";
    int count = 0;
    for (int i = 0; i<macAddr.length; i++) {
        count ++;
        doneTitle = [doneTitle stringByAppendingString:[macAddr substringWithRange:NSMakeRange(i, 1)]];
        if (count == 2 && i<macAddr.length-1) {
            doneTitle = [NSString stringWithFormat:@"%@:", doneTitle];
            count = 0;
        }
    }
    return doneTitle;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_dataArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *ary = [_dataArray objectAtIndex:section];
    return [ary count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    }else {
        return 30.0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ThermoregulatorCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ThermoregulatorCell"];
        UISwitch *powerSwitch = [[UISwitch alloc] init];
        powerSwitch.onTintColor = DARKORAGE;
        powerSwitch.tag = 1;
        [powerSwitch addTarget:self action:@selector(powerSwitchAction:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:powerSwitch];
        powerSwitch.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:powerSwitch attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:powerSwitch attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-20];
        [NSLayoutConstraint activateConstraints:@[centerY, left]];
    }
    UISwitch *powerSwitch = (UISwitch *)[cell.contentView viewWithTag:1];
    NSArray *ary = [_dataArray objectAtIndex:indexPath.section];
    if (indexPath.section == 0) {
        powerSwitch.hidden = YES;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = [sectionOneKeys objectAtIndex:indexPath.row];
        cell.detailTextLabel.text = [ary objectAtIndex:indexPath.row];
    }else {
        cell.textLabel.text = [sectionOtherKeys objectAtIndex:indexPath.row];
        if (indexPath.row == 0) {
            powerSwitch.hidden = NO;
            cell.accessoryType = UITableViewCellAccessoryNone;
            powerSwitch.on = [[ary objectAtIndex:indexPath.row] boolValue];
            cell.detailTextLabel.text = nil;
        }else {
            powerSwitch.hidden = YES;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            NSArray *detailAry = [TROWS objectAtIndex:indexPath.row-1];
            cell.detailTextLabel.text = [detailAry objectAtIndex:[[ary objectAtIndex:indexPath.row] integerValue]];
        }
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    }else {
        UIView *header = [[UIView alloc] init];
        header.backgroundColor = ColorWithAlpha(238, 238, 243, 1);
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 100, 20)];
        label.text = [NSString stringWithFormat:@"%ld",section];
        [header addSubview:label];
        return header;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UIAlertController *renameAlert = [UIAlertController alertControllerWithTitle:@"输入新名称" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [renameAlert.view setTintColor:DARKORAGE];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                UITextField *textField = renameAlert.textFields.firstObject;
                if ([textField.text length] > 0 && ![textField.text isEqualToString:_device.name]) {
                    _device.name = textField.text;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    self.title = textField.text;
                    NSArray *ary = @[textField.text, [_dataArray firstObject][1]];
                    [_dataArray replaceObjectAtIndex:0 withObject:ary];
                    [_tableView reloadData];
                    if (self.renameBlock) {
                        self.renameBlock();
                    }
                }
            }];
            [renameAlert addAction:cancel];
            [renameAlert addAction:confirm];
            [renameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.textAlignment = NSTextAlignmentCenter;
            }];
            [self presentViewController:renameAlert animated:YES completion:nil];
        }
    }else {
        _controlChannel = indexPath.section;
        if (indexPath.row == 1) {
            CGFloat w = self.view.bounds.size.width * 0.618;
            CGFloat sh = w/0.618;
            CGFloat mh = 6*44+90;
            CGFloat h = sh > mh ? mh : sh;
            NSMutableArray *ary = [[NSMutableArray alloc] init];
            for (int i = 0; i < [TFENGSU count]; i ++) {
                SelectionListModel *slm = [[SelectionListModel alloc] init];
                slm.value = i;
                slm.name = TFENGSU[i];
                [ary addObject:slm];
            }
            [self.view addSubview:self.translucentBgView];
            _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width-w)/2.0, (self.view.bounds.size.height-h)/2.0, w, h) dataArray:ary tite:AcTECLocalizedStringFromTable(@"Select", @"Localizable") mode:SelectionListViewSelectionMode_Fengsu];
            _selectionView.delegate = self;
            [self.view addSubview:_selectionView];
        }else if (indexPath.row == 2) {
            CGFloat w = self.view.bounds.size.width * 0.618;
            CGFloat sh = w/0.618;
            CGFloat mh = 15*44+90;
            CGFloat h = sh > mh ? mh : sh;
            NSMutableArray *ary = [[NSMutableArray alloc] init];
            for (int i = 0; i < [TWENDU count]; i ++) {
                SelectionListModel *slm = [[SelectionListModel alloc] init];
                slm.value = i;
                slm.name = TWENDU[i];
                [ary addObject:slm];
            }
            [self.view addSubview:self.translucentBgView];
            _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width-w)/2.0, (self.view.bounds.size.height-h)/2.0, w, h) dataArray:ary tite:AcTECLocalizedStringFromTable(@"Select", @"Localizable") mode:SelectionListViewSelectionMode_Wendu];
            _selectionView.delegate = self;
            [self.view addSubview:_selectionView];
        }else if (indexPath.row == 3) {
            CGFloat w = self.view.bounds.size.width * 0.618;
            CGFloat sh = w/0.618;
            CGFloat mh = 5*44+90;
            CGFloat h = sh > mh ? mh : sh;
            NSMutableArray *ary = [[NSMutableArray alloc] init];
            for (int i = 0; i < [TMOSHI count]; i ++) {
                SelectionListModel *slm = [[SelectionListModel alloc] init];
                slm.value = i;
                slm.name = TMOSHI[i];
                [ary addObject:slm];
            }
            [self.view addSubview:self.translucentBgView];
            _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width-w)/2.0, (self.view.bounds.size.height-h)/2.0, w, h) dataArray:ary tite:AcTECLocalizedStringFromTable(@"Select", @"Localizable") mode:SelectionListViewSelectionMode_Moshi];
            _selectionView.delegate = self;
            [self.view addSubview:_selectionView];
        }else if (indexPath.row == 4) {
            CGFloat w = self.view.bounds.size.width * 0.618;
            CGFloat sh = w/0.618;
            CGFloat mh = 4*44+90;
            CGFloat h = sh > mh ? mh : sh;
            NSMutableArray *ary = [[NSMutableArray alloc] init];
            for (int i = 0; i < [TFENGXIANG count]; i ++) {
                SelectionListModel *slm = [[SelectionListModel alloc] init];
                slm.value = i;
                slm.name = TFENGXIANG[i];
                [ary addObject:slm];
            }
            [self.view addSubview:self.translucentBgView];
            _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width-w)/2.0, (self.view.bounds.size.height-h)/2.0, w, h) dataArray:ary tite:AcTECLocalizedStringFromTable(@"Select", @"Localizable") mode:SelectionListViewSelectionMode_Fengxiang];
            _selectionView.delegate = self;
            [self.view addSubview:_selectionView];
        }
    }
}

- (void)nextThermoregulatorStateOperation {
    if ([_channels count] > 0) {
        NSInteger channel = [[_channels firstObject] integerValue];
        Byte byte[] = {0xb6, 0x02, 0x27, channel};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
        _applyChannel = channel;
        _applyCmd = cmd;
        _applyRetryCount = 0;
        [self performSelector:@selector(thermoregulatorStateOperationDelay) withObject:nil afterDelay:10.0];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }else {
        [_indicatorView stopAnimating];
        [_indicatorView removeFromSuperview];
        [_translucentBgView removeFromSuperview];
        _indicatorView = nil;
        _translucentBgView = nil;
    }
}

- (void)thermoregulatorStateOperationDelay {
    if (_applyRetryCount < 3) {
        _applyRetryCount ++;
        [self performSelector:@selector(thermoregulatorStateOperationDelay) withObject:nil afterDelay:10.0];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:_applyCmd];
    }else {
        [_channels removeObjectAtIndex:0];
        [self nextThermoregulatorStateOperation];
    }
}

- (void)setPowerStateSuccess:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        NSNumber *channel = userInfo[@"channel"];
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        NSArray *states = [model.stateDic objectForKey:channel];
        if (states) {
            [_dataArray replaceObjectAtIndex:[channel integerValue] withObject:states];
            [_tableView reloadData];
        }
        if ([channel integerValue] == _applyChannel) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(thermoregulatorStateOperationDelay) object:nil];
            if ([_channels count]>0) {
                [_channels removeObjectAtIndex:0];
                [self nextThermoregulatorStateOperation];
            }
        }
    }
}

- (void)powerSwitchAction:(UISwitch *)sender {
    UITableViewCell *cell = (UITableViewCell *)sender.superview.superview;
    if (cell) {
        NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
        if (indexPath) {
            _controlChannel = indexPath.section;
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
            NSArray *states = [model.stateDic objectForKey:@(indexPath.section)];
            NSArray *ary = @[@(sender.on), @(0), @(0), @(0), @(0)];
            if (states) {
                ary = @[@(sender.on), states[1], states[2], states[3], states[4]];
            }
            [model.stateDic setObject:ary forKey:@(indexPath.section)];
            [_dataArray replaceObjectAtIndex:indexPath.section withObject:ary];
            [self controlCommandSendWithValid:1];
        }
    }
}

- (void)selectionListViewSaveAction:(NSArray *)ary selectionMode:(SelectionListViewSelectionMode)mode {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
    NSArray *states = [model.stateDic objectForKey:@(_controlChannel)];
    SelectionListModel *slm = [ary firstObject];
    if (mode == SelectionListViewSelectionMode_Fengsu) {
        NSArray *ary = @[@(0), @(slm.value), @(0), @(0), @(0)];
        if (states) {
            ary = @[states[0], @(slm.value), states[2], states[3], states[4]];
        }
        [model.stateDic setObject:ary forKey:@(_controlChannel)];
        [_dataArray replaceObjectAtIndex:_controlChannel withObject:ary];
        [_tableView reloadData];
        [self controlCommandSendWithValid:8];
    }else if (mode == SelectionListViewSelectionMode_Wendu) {
        NSArray *ary = @[@(0), @(0), @(slm.value), @(0), @(0)];
        if (states) {
            ary = @[states[0], states[1], @(slm.value), states[3], states[4]];
        }
        [model.stateDic setObject:ary forKey:@(_controlChannel)];
        [_dataArray replaceObjectAtIndex:_controlChannel withObject:ary];
        [_tableView reloadData];
        [self controlCommandSendWithValid:128];
    }else if (mode == SelectionListViewSelectionMode_Moshi) {
        NSArray *ary = @[@(0), @(0), @(0), @(slm.value), @(0)];
        if (states) {
            ary = @[states[0], states[1], states[2], @(slm.value), states[4]];
        }
        [model.stateDic setObject:ary forKey:@(_controlChannel)];
        [_dataArray replaceObjectAtIndex:_controlChannel withObject:ary];
        [_tableView reloadData];
        [self controlCommandSendWithValid:2];
    }else if (mode == SelectionListViewSelectionMode_Fengxiang) {
        NSArray *ary = @[@(0), @(0), @(0), @(0), @(slm.value)];
        if (states) {
            ary = @[states[0], states[1], states[2], states[3], @(slm.value)];
        }
        [model.stateDic setObject:ary forKey:@(_controlChannel)];
        [_dataArray replaceObjectAtIndex:_controlChannel withObject:ary];
        [_tableView reloadData];
        [self controlCommandSendWithValid:4];
    }
    
    [_selectionView removeFromSuperview];
    _selectionView = nil;
    [_translucentBgView removeFromSuperview];
    _translucentBgView = nil;
}

- (void)controlCommandSendWithValid:(uint8_t)valid {
    NSArray *ary = [_dataArray objectAtIndex:_controlChannel];
    uint8_t d1 = [ary[0] boolValue] + ([ary[3] integerValue] << 1) + ([ary[4] integerValue] << 4);
    uint8_t d2 = [ary[1] integerValue];
    uint8_t d3 = [ary[2] intValue]+16;
    Byte byte[] = {0xb6, 0x08, 0x26, _controlChannel, valid, 0x00, d1, d2, d3, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (void)selectionListViewCancelAction {
    [_selectionView removeFromSuperview];
    _selectionView = nil;
    [_translucentBgView removeFromSuperview];
    _translucentBgView = nil;
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
        _indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    }
    return _indicatorView;
}

- (void)doneAction {
    if (self.reloadDataHandle) {
        self.reloadDataHandle();
    }
    [self.navigationController popViewControllerAnimated:YES];
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
