//
//  NetworkSettingVC.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/9/29.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "NetworkSettingVC.h"
#import "CSRDatabaseManager.h"
#import <CoreLocation/CLLocationManager.h>
#import "CSRUtilities.h"
#import "DataModelManager.h"
#import "DeviceModelManager.h"
#import "PureLayout.h"

@interface NetworkSettingVC ()<CLLocationManagerDelegate>
{
    NSInteger retrCount;
    NSData *retryData;
}

@property (weak, nonatomic) IBOutlet UILabel *connectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *ipLabel;
@property (weak, nonatomic) IBOutlet UILabel *subnetLabel;
@property (weak, nonatomic) IBOutlet UILabel *gatewayLabel;
@property (weak, nonatomic) IBOutlet UILabel *dnsLabel;
@property (nonatomic, strong) NSString *wifiPassword;
@property (nonatomic, strong) NSData *applyData;
@property (nonatomic, assign) NSInteger applyIndex;
@property (nonatomic, assign) NSInteger applySort;
@property (nonatomic, strong) NSMutableData *receiveData;
@property (weak, nonatomic) IBOutlet UIButton *socketConnectionBtn;
@property (nonatomic,strong) UIView *translucentBgView;
@property (nonatomic,strong) UIActivityIndicatorView *indicatorView;

@end

@implementation NetworkSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(LCDRemoteSSIDCall:)
                                                 name:@"LCDRemoteSSIDCall"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshNetworkConnectionStatus:)
                                                 name:@"refreshNetworkConnectionStatus"
                                               object:nil];
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"networking_setting", @"Localizable");
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"refresh", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(refreshNetworkingAction)];
    self.navigationItem.rightBarButtonItem = item;
    if (_deviceId) {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        
        if (deviceEntity.ipAddress) {
            _connectionLabel.text = AcTECLocalizedStringFromTable(@"connected", @"Localizable");
            _ipLabel.text = deviceEntity.ipAddress;
            _subnetLabel.text = deviceEntity.subnetMask;
            _gatewayLabel.text = deviceEntity.gateway;
            _dnsLabel.text = deviceEntity.dns;
        }else {
            _connectionLabel.text = AcTECLocalizedStringFromTable(@"not_connected", @"Localizable");
            _ipLabel.text = @"";
            _subnetLabel.text = @"";
            _gatewayLabel.text = @"";
            _dnsLabel.text = @"";
        }
    }
    
    
}

- (void)refreshNetworkingAction {
    _connectionLabel.text = @"";
    _ipLabel.text = @"";
    _subnetLabel.text = @"";
    _gatewayLabel.text = @"";
    _dnsLabel.text = @"";
    Byte byte[] = {0xea, 0x77, 0x07};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (IBAction)wifiAction:(UIButton *)sender {
    if (@available(iOS 13.0, *)) {
        [self getcurrentLocation];
    }else {
        [self getWifiInfo];
    }
}

- (void)getcurrentLocation {
    if (@available(iOS 13.0, *)) {
        //用户明确拒绝，可以弹窗提示用户到设置中手动打开权限
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            //使用下面接口可以打开当前应用的设置页面
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
        
        CLLocationManager *locManager = [[CLLocationManager alloc] init];
        locManager.delegate = self;
        if(![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            //弹框提示用户是否开启位置权限
            [locManager requestWhenInUseAuthorization];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self getWifiInfo];
}

- (void)getWifiInfo {
    NSString *name = [CSRUtilities getWifiName];
    if (name) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:AcTECLocalizedStringFromTable(@"set_lcdremote_wifi", @"Localizable") message:name preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
        
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"send", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UITextField *textField = alert.textFields.firstObject;
            [self sendWifiName:name wifiPassword:textField.text];
        }];
        [alert addAction:cancel];
        [alert addAction:confirm];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = AcTECLocalizedStringFromTable(@"enter_wifi_password", @"Localizable");
        }];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)sendWifiName:(NSString *)name wifiPassword:(NSString *)password {
    [self showLoading];
    _wifiPassword = password;
    _applyData = [name dataUsingEncoding:NSUTF8StringEncoding];
    NSInteger packet = _applyData.length / 6 + 1;
    if (_applyData.length % 6 == 0) {
        packet = _applyData.length / 6;
    }
    NSInteger l = 6;
    if (_applyData.length < 6) {
        l = _applyData.length;
    }
    _applyIndex = 1;
    _applySort = 120;
    NSData *data_0 = [_applyData subdataWithRange:NSMakeRange(0, l)];
    Byte byte[4] = {0xea, 0x78, packet, 0x01};
    NSData *head = [[NSData alloc] initWithBytes:byte length:4];
    NSMutableData *cmd = [[NSMutableData alloc] init];
    [cmd appendData:head];
    [cmd appendData:data_0];
    retrCount = 0;
    retryData = cmd;
    [self performSelector:@selector(sendwifiDelay) withObject:nil afterDelay:2];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (void)LCDRemoteSSIDCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSInteger index = [CSRUtilities numberWithHexString:userInfo[@"index"]];
    NSInteger sort = [CSRUtilities numberWithHexString:userInfo[@"sort"]];
    
    if ([deviceId isEqualToNumber:_deviceId] && index == _applyIndex && sort == _applySort) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendwifiDelay) object:nil];
        NSInteger packet = _applyData.length / 6 + 1;
        if (_applyData.length % 6 == 0) {
            packet = _applyData.length / 6;
        }
        
        if (index == packet) {
            
            if (sort == 120) {
                _applyData = [_wifiPassword dataUsingEncoding:NSUTF8StringEncoding];
                NSInteger packet = _applyData.length / 6 + 1;
                if (_applyData.length % 6 == 0) {
                    packet = _applyData.length / 6;
                }
                NSInteger l = 6;
                if (_applyData.length < 6) {
                    l = _applyData.length;
                }
                _applyIndex = 1;
                _applySort = 121;
                NSData *data_0 = [_applyData subdataWithRange:NSMakeRange(0, l)];
                Byte byte[4] = {0xea, 0x79, packet, 0x01};
                NSData *head = [[NSData alloc] initWithBytes:byte length:4];
                NSMutableData *cmd = [[NSMutableData alloc] init];
                [cmd appendData:head];
                [cmd appendData:data_0];
                retrCount = 0;
                retryData = cmd;
                [self performSelector:@selector(sendwifiDelay) withObject:nil afterDelay:2];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }else if (sort == 121) {
                retrCount = 0;
                [self performSelector:@selector(connectionDelay) withObject:nil afterDelay:10];
            }
            
        }else if (index == (packet - 1)) {
            _applyIndex = index + 1;
            NSData *data_0 = [_applyData subdataWithRange:NSMakeRange(6*index, _applyData.length - 6*index)];
            Byte byte[4] = {0xea, sort, packet, _applyIndex};
            NSData *head = [[NSData alloc] initWithBytes:byte length:4];
            NSMutableData *cmd = [[NSMutableData alloc] init];
            [cmd appendData:head];
            [cmd appendData:data_0];
            retrCount = 0;
            retryData = cmd;
            [self performSelector:@selector(sendwifiDelay) withObject:nil afterDelay:2];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }else {
            _applyIndex = index + 1;
            NSData *data_0 = [_applyData subdataWithRange:NSMakeRange(6*index, 6)];
            Byte byte[4] = {0xea, sort, packet, _applyIndex};
            NSData *head = [[NSData alloc] initWithBytes:byte length:4];
            NSMutableData *cmd = [[NSMutableData alloc] init];
            [cmd appendData:head];
            [cmd appendData:data_0];
            retrCount = 0;
            retryData = cmd;
            [self performSelector:@selector(sendwifiDelay) withObject:nil afterDelay:2];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }
    }
}

- (void)sendwifiDelay {
    if (retrCount < 4) {
        retrCount ++;
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:retryData];
    }else {
        [self hideLoading];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"fail_ssid_password", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:yes];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)connectionDelay {
    if (retrCount < 4) {
        retrCount ++;
        [self performSelector:@selector(connectionDelay) withObject:nil afterDelay:3];
        Byte byte[] = {0xea, 0x77, 0x07};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }else {
        [self hideLoading];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"fail_connection", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

        }];
        [alert addAction:yes];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)refreshNetworkConnectionStatus:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSInteger type = [userInfo[@"type"] integerValue];
    if ([deviceId isEqualToNumber:_deviceId]) {
        if (type == 7) {
            BOOL status = [userInfo[@"staus"] boolValue];
            _connectionLabel.text = status ? AcTECLocalizedStringFromTable(@"connected", @"Localizable") : AcTECLocalizedStringFromTable(@"not_connected", @"Localizable");
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectionDelay) object:nil];
            [self hideLoading];
            
        }else if (type == 1) {
            NSString *status = userInfo[@"staus"];
            _ipLabel.text = status;
            
            Byte byte[] = {0xea, 0x77, 0x03};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            
        }else if (type == 3) {
            NSString *status = userInfo[@"staus"];
            _subnetLabel.text = status;
        }else if (type == 2) {
            NSString *status = userInfo[@"staus"];
            _gatewayLabel.text = status;
        }else if (type == 4) {
            NSString *status = userInfo[@"staus"];
            _dnsLabel.text = status;
        }
    }
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
        _indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    }
    return _indicatorView;
}

@end
