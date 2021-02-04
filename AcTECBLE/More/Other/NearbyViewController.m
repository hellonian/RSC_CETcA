//
//  NearbyViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/8/4.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "NearbyViewController.h"
#import "PureLayout.h"
#import "CSRBluetoothLE.h"

@interface NearbyViewController ()<UITableViewDelegate, UITableViewDataSource, CSRBluetoothLEDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) UIView *translucentBgView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) UILabel *alertLabel;
@property (nonatomic, strong) UILabel *countdownLabel;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, strong) UIButton *cancel;
@property (nonatomic, strong) UILabel *noneLabel;

@end

@implementation NearbyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (@available(iOS 11.0, *)) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(-35, 0, 0, 0);
    }
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"nearbyDevices", @"Localizable");
    
    _dataArray = [[NSMutableArray alloc] init];
    
    _noneLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _noneLabel.text = AcTECLocalizedStringFromTable(@"match_reset_none_alert", @"Localizable");
    _noneLabel.font = [UIFont systemFontOfSize:14];
    _noneLabel.textColor = ColorWithAlpha(77, 77, 77, 1);
    _noneLabel.textAlignment = NSTextAlignmentCenter;
    _noneLabel.numberOfLines = 0;
    [self.view addSubview:_noneLabel];
    [_noneLabel autoCenterInSuperview];
    [_noneLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [_noneLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:50];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundView = [[UIView alloc] init];
    _tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_tableView];
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        [_tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    }else {
        [_tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 50, 0)];
    }
    
    [[CSRBluetoothLE sharedInstance] setIsNearbyFunction:YES];
    [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
    [[CSRBluetoothLE sharedInstance] startScan];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[CSRBluetoothLE sharedInstance] setIsNearbyFunction:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
    }
    CBPeripheral *p = _dataArray[indexPath.row];
    cell.textLabel.text = p.name;
    cell.detailTextLabel.text = p.uuidString;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self performSelector:@selector(connectTimeOut) withObject:nil afterDelay:15.0];
    [self showLoading];
    [[CSRBluetoothLE sharedInstance] connectPeripheralNoCheck:[_dataArray objectAtIndex:indexPath.row]];
}

- (void)discoveryDidRefresh:(CBPeripheral *)peripheral {
    if ([[peripheral.uuidString substringWithRange:NSMakeRange(13, 1)] integerValue] == 1) {
        BOOL exist = NO;
        for (CBPeripheral *p in _dataArray) {
            if ([[p.uuidString substringWithRange:NSMakeRange(0, 12)] isEqualToString:[peripheral.uuidString substringWithRange:NSMakeRange(0, 12)]]) {
                exist = YES;
                break;
            }
        }
        
        if (!exist) {
            [_dataArray addObject:peripheral];
            _noneLabel.hidden = YES;
            [self.tableView reloadData];
        }
    }else if ([[peripheral.uuidString substringWithRange:NSMakeRange(13, 1)] integerValue] == 0) {
        BOOL exist = NO;
        for (CBPeripheral *p in _dataArray) {
            if ([[p.uuidString substringWithRange:NSMakeRange(0, 12)] isEqualToString:[peripheral.uuidString substringWithRange:NSMakeRange(0, 12)]]) {
                exist = YES;
                break;
            }
        }
        if (exist) {
            [_dataArray removeObject:peripheral];
            if ([_dataArray count] == 0) {
                _noneLabel.hidden = NO;
            }
            [self.tableView reloadData];
            
            [_countdownTimer invalidate];
            _countdownTimer = nil;
            [self rHideTranslucentBgView];
        }
    }
    
}

- (void)delegatePeripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectTimeOut) object:nil];
    
    [self.indicatorView stopAnimating];
    [self.indicatorView removeFromSuperview];
    self.indicatorView = nil;
    [[UIApplication sharedApplication].keyWindow addSubview:self.countdownLabel];
    [self.countdownLabel autoCenterInSuperview];
    self.countdownLabel.text = @"60";
    [[UIApplication sharedApplication].keyWindow addSubview:self.alertLabel];
    [self.alertLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.alertLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.countdownLabel withOffset:30];
    self.alertLabel.text = AcTECLocalizedStringFromTable(@"nearbyAlert", @"Localizable");
    _countdownTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(countdownMethod) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_countdownTimer forMode:NSRunLoopCommonModes];
    
    _cancel = [[UIButton alloc] initWithFrame:CGRectZero];
    [_cancel setTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") forState:UIControlStateNormal];
    [_cancel addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    [[UIApplication sharedApplication].keyWindow addSubview:_cancel];
    [_cancel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.view];
    [_cancel autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.view];
    [_cancel autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.view];
    [_cancel autoSetDimension:ALDimensionHeight toSize:44];
}

- (void)showLoading {
    [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
    [[UIApplication sharedApplication].keyWindow addSubview:self.indicatorView];
    [self.indicatorView autoCenterInSuperview];
    [self.indicatorView startAnimating];
    
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

- (UILabel *)alertLabel {
    if (!_alertLabel) {
        _alertLabel = [[UILabel alloc] init];
        _alertLabel.textColor = [UIColor whiteColor];
        _alertLabel.numberOfLines = 0;
        _alertLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _alertLabel;
}

- (UILabel *)countdownLabel {
    if (!_countdownLabel) {
        _countdownLabel = [[UILabel alloc] init];
        _countdownLabel.textColor = DARKORAGE;
        _countdownLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _countdownLabel;
}

- (void)connectTimeOut {
    [self.indicatorView stopAnimating];
    [self.indicatorView removeFromSuperview];
    self.indicatorView = nil;
    [[UIApplication sharedApplication].keyWindow addSubview:self.alertLabel];
    [self.alertLabel autoCenterInSuperview];
    [self.alertLabel autoSetDimensionsToSize:CGSizeMake(250, 100)];
    self.alertLabel.text = AcTECLocalizedStringFromTable(@"mcu_connetion_alert", @"Localizable");
    [self performSelector:@selector(cHideTranslucentBgView) withObject:nil afterDelay:3.0];
}

- (void)cHideTranslucentBgView {
    [self.alertLabel removeFromSuperview];
    [self.translucentBgView removeFromSuperview];
    self.alertLabel = nil;
    self.translucentBgView = nil;
}

- (void)countdownMethod {
    NSInteger countdown = [self.countdownLabel.text integerValue];
    if (countdown > 0) {
        self.countdownLabel.text = [NSString stringWithFormat:@"%ld",countdown - 1];
    }else {
        [self performSelector:@selector(rHideTranslucentBgView) withObject:nil afterDelay:2.0];
        [_countdownTimer invalidate];
        _countdownTimer = nil;
    }
    
}

- (void)rHideTranslucentBgView {
    [self.alertLabel removeFromSuperview];
    [self.countdownLabel removeFromSuperview];
    [self.translucentBgView removeFromSuperview];
    [_cancel removeFromSuperview];
    self.alertLabel = nil;
    self.countdownLabel = nil;
    self.translucentBgView = nil;
    _cancel = nil;
    [[CSRBluetoothLE sharedInstance] stopScan];
}

- (void)cancelAction {
    [self rHideTranslucentBgView];
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
