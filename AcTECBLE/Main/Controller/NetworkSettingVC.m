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
#import "GCDAsyncSocket.h"

@interface NetworkSettingVC ()<CLLocationManagerDelegate,GCDAsyncSocketDelegate>

@property (weak, nonatomic) IBOutlet UILabel *connectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *ipLabel;
@property (weak, nonatomic) IBOutlet UILabel *subnetLabel;
@property (weak, nonatomic) IBOutlet UILabel *gatewayLabel;
@property (weak, nonatomic) IBOutlet UILabel *dnsLabel;
@property (nonatomic, strong) NSString *wifiPassword;
@property (nonatomic, strong) NSData *applyData;
@property (nonatomic, assign) NSInteger applyIndex;
@property (nonatomic, strong) GCDAsyncSocket *tcpSocketManager;

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
    NSData *data_0 = [_applyData subdataWithRange:NSMakeRange(0, l)];
    Byte byte[4] = {0xea, 0x78, packet, 0x01};
    NSData *head = [[NSData alloc] initWithBytes:byte length:4];
    NSMutableData *cmd = [[NSMutableData alloc] init];
    [cmd appendData:head];
    [cmd appendData:data_0];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (void)LCDRemoteSSIDCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSInteger index = [CSRUtilities numberWithHexString:userInfo[@"index"]];
    NSInteger sort = [CSRUtilities numberWithHexString:userInfo[@"sort"]];
    
    if ([deviceId isEqualToNumber:_deviceId] && index == _applyIndex) {
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
                NSData *data_0 = [_applyData subdataWithRange:NSMakeRange(0, l)];
                Byte byte[4] = {0xea, 0x79, packet, 0x01};
                NSData *head = [[NSData alloc] initWithBytes:byte length:4];
                NSMutableData *cmd = [[NSMutableData alloc] init];
                [cmd appendData:head];
                [cmd appendData:data_0];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }
            
        }else if (index == (packet - 1)) {
            _applyIndex = index + 1;
            NSData *data_0 = [_applyData subdataWithRange:NSMakeRange(6*index, _applyData.length - 6*index)];
            Byte byte[4] = {0xea, sort, packet, _applyIndex};
            NSData *head = [[NSData alloc] initWithBytes:byte length:4];
            NSMutableData *cmd = [[NSMutableData alloc] init];
            [cmd appendData:head];
            [cmd appendData:data_0];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }else {
            _applyIndex = index + 1;
            NSData *data_0 = [_applyData subdataWithRange:NSMakeRange(6*index, 6)];
            Byte byte[4] = {0xea, sort, packet, _applyIndex};
            NSData *head = [[NSData alloc] initWithBytes:byte length:4];
            NSMutableData *cmd = [[NSMutableData alloc] init];
            [cmd appendData:head];
            [cmd appendData:data_0];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }
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
        }else if (type == 1) {
            NSString *status = userInfo[@"staus"];
            _ipLabel.text = status;
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

- (IBAction)socketConnectAction:(id)sender {
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if (device.ipAddress) {
        [self connentHost:device.ipAddress prot:8888];
    }
}

- (void)connentHost:(NSString *)host prot:(uint16_t)port{
    if (host==nil || host.length <= 0) {
        NSAssert(host != nil, @"host must be not nil");
    }
    
    [self.tcpSocketManager disconnect];
    if (self.tcpSocketManager == nil) {
        self.tcpSocketManager = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    NSError *connectError = nil;
    BOOL isConnected = [self.tcpSocketManager isConnected];
    NSLog(@"isConnected: %d",isConnected);
    if (!isConnected) {
        if (![self.tcpSocketManager connectToHost:host onPort:port error:&connectError]) {
            NSLog(@"Connect Error: %@", connectError);
        }else {
            NSLog(@"Connect success!");
            [self.tcpSocketManager readDataWithTimeout:-1 tag:0];
        }
    }
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@">><><> %@", data);
    
    [sock readDataWithTimeout:-1 tag:0];
}

- (IBAction)getDeviceInfosAction:(id)sender {
    Byte b[] = {0xa5, 0x00, 0x0e, 0x00, 0x00, 0x00, 0x10, 0x00, 0x01, 0x00, 0x01, 0x10};
    NSData *d = [[NSData alloc] initWithBytes:b length:12];
    int sum = [self sumCFromData:d];
    Byte byte[] = {0xa5, 0x00, 0x0e, 0x00, 0x00, 0x00, 0x10, 0x00, 0x01, 0x00, 0x01, 0x10, sum, 0xfe};
    NSData *data = [[NSData alloc] initWithBytes:byte length:14];
    NSLog(@"getDeviceInfosAction: %@",data);
    [self.tcpSocketManager writeData:data withTimeout:-1 tag:0];
}

- (IBAction)getFavoritesAction:(id)sender {
    Byte b[] = {0xa5, 0x00, 0x0e, 0x00, 0x00, 0x00, 0x10, 0x00, 0x01, 0x00, 0x01, 0x10};
    NSData *d = [[NSData alloc] initWithBytes:b length:12];
    int sum = [self sumCFromData:d];
    Byte byte[] = {0xa5, 0x00, 0x0e, 0x00, 0x00, 0x00, 0x10, 0x00, 0x01, 0x00, 0x02, 0x10, sum, 0xfe};
    NSData *data = [[NSData alloc] initWithBytes:byte length:14];
    NSLog(@"getFavoritesAction: %@",data);
    [self.tcpSocketManager writeData:data withTimeout:-1 tag:0];
}

- (int)sumCFromData:(NSData *)data {
    int lm = (int)data.length;
    Byte *bytes = (unsigned char *)[data bytes];
    int sumC = 0;
    for (int i = 0; i < lm; i++) {
        sumC ^= bytes[i];
    }
    return sumC;
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
