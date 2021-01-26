//
//  PIRDeviceVC.m
//  AcTECBLE
//
//  Created by AcTEC on 2021/1/6.
//  Copyright © 2021 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "PIRDeviceVC.h"
#import "CSRDatabaseManager.h"
#import "DeviceListViewController.h"
#import "SelectModel.h"
#import "DataModelManager.h"
#import "AFHTTPSessionManager.h"
#import "UpdataMCUTool.h"
#import "CSRBluetoothLE.h"
#import "PureLayout.h"
#import <MBProgressHUD.h>

@interface PIRDeviceVC ()<UITextFieldDelegate,MBProgressHUDDelegate,UpdataMCUToolDelegate>
{
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
    UIButton *updateMCUBtn;
}

@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (nonatomic,copy) NSString *originalName;
@property (weak, nonatomic) IBOutlet UILabel *sDeviceIDLabel;
@property (weak, nonatomic) IBOutlet UISlider *controlLuxSlider;
@property (weak, nonatomic) IBOutlet UILabel *controlLuxLabel;
@property (weak, nonatomic) IBOutlet UISlider *delayTimeSlider;
@property (weak, nonatomic) IBOutlet UILabel *delayTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *strengthChangeTimeSlider;
@property (weak, nonatomic) IBOutlet UILabel *strengthChangeTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *detectionLuxSlider;
@property (weak, nonatomic) IBOutlet UILabel *detectionLuxLabel;
@property (weak, nonatomic) IBOutlet UISlider *sensitivitySlider;
@property (weak, nonatomic) IBOutlet UILabel *sensitivityLabel;
@property (weak, nonatomic) IBOutlet UISlider *toleranceSlider;
@property (weak, nonatomic) IBOutlet UILabel *toleranceLabel;
@property (weak, nonatomic) IBOutlet UISlider *calibrationLuxSlider;
@property (weak, nonatomic) IBOutlet UILabel *calibrationLuxLabel;
@property (weak, nonatomic) IBOutlet UISlider *thresholdLuxSlider;
@property (weak, nonatomic) IBOutlet UILabel *thresholdLuxLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UISlider *nightLightBrightnessSlider;
@property (weak, nonatomic) IBOutlet UILabel *nightLightBrightness;
@property (weak, nonatomic) IBOutlet UILabel *nightLightState;
@property (weak, nonatomic) IBOutlet UIView *pirModelView;
@property (weak, nonatomic) IBOutlet UIView *detectionModelView;
@property (nonatomic,strong) UIView *translucentBgView;
@property (nonatomic, strong) UIAlertController *mcuAlert;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic,strong) MBProgressHUD *updatingHud;

@end

@implementation PIRDeviceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIButton *btn = [[UIButton alloc] init];
    [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
    [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
    [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = back;
    
    if (_deviceId) {
        CSRDeviceEntity *deviceE = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        self.navigationItem.title = deviceE.name;
        self.nameTf.delegate = self;
        self.nameTf.text = deviceE.name;
        self.originalName = deviceE.name;
        NSString *macAddr = [deviceE.uuid substringFromIndex:24];
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
        self.macAddressLabel.text = doneTitle;
        
        if ([deviceE.remoteBranch length] > 0) {
            NSInteger number = [deviceE.remoteBranch integerValue];
            if (number > 32768) {
                CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:@(number)];
                _sDeviceIDLabel.text = d.name;
            }else {
                CSRAreaEntity *a = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:@(number)];
                _sDeviceIDLabel.text = a.areaName;
            }
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(pircall:)
                                                     name:@"PIRCALL"
                                                   object:nil];
        
        Byte byte[] = {0xea, 0x8a};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        
        if ([deviceE.hwVersion integerValue]==2) {
            NSMutableString *mutStr = [NSMutableString stringWithString:deviceE.shortName];
            NSRange range = {0,deviceE.shortName.length};
            [mutStr replaceOccurrencesOfString:@"/" withString:@"" options:NSLiteralSearch range:range];
            NSString *urlString = [NSString stringWithFormat:@"http://39.108.152.134/MCU/%@/%@.php",mutStr,mutStr];
            AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
            sessionManager.responseSerializer.acceptableContentTypes = nil;
            sessionManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
            [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                NSDictionary *dic = (NSDictionary *)responseObject;
                latestMCUSVersion = [dic[@"mcu_software_version"] integerValue];
                downloadAddress = dic[@"Download_address"];
                if ([deviceE.mcuSVersion integerValue]<latestMCUSVersion && [deviceE.mcuSVersion integerValue] != 0) {
                    updateMCUBtn = [UIButton buttonWithType:UIButtonTypeSystem];
                    [updateMCUBtn setBackgroundColor:[UIColor whiteColor]];
                    [updateMCUBtn setTitle:@"UPDATE MCU" forState:UIControlStateNormal];
                    [updateMCUBtn setTitleColor:DARKORAGE forState:UIControlStateNormal];
                    [updateMCUBtn addTarget:self action:@selector(disconnectForMCUUpdate) forControlEvents:UIControlEventTouchUpInside];
                    [self.view addSubview:updateMCUBtn];
                    [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeLeft];
                    [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeRight];
                    [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:45.0];
                    [updateMCUBtn autoSetDimension:ALDimensionHeight toSize:44.0];
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                NSLog(@"%@",error);
            }];
        }
    }
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    textField.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    textField.backgroundColor = [UIColor whiteColor];
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self saveNickName];
}

- (void)saveNickName {
    if (![_nameTf.text isEqualToString:_originalName] && _nameTf.text.length > 0) {
        self.navigationItem.title = _nameTf.text;
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:self.deviceId];
        deviceEntity.name = _nameTf.text;
        [[CSRDatabaseManager sharedInstance] saveContext];
        _originalName = _nameTf.text;
        if (self.reloadDataHandle) {
            self.reloadDataHandle();
        }
    }
}
- (IBAction)selectDevice:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *lamp = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self selectMember:DeviceListSelectMode_Single];
        
    }];
    UIAlertAction *group = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self selectMember:DeviceListSelectMode_SelectGroup];
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:lamp];
    [alert addAction:group];
    [alert addAction:cancel];
    
    UIPopoverPresentationController *popover = alert.popoverPresentationController;
    if (popover) {
        UIButton *button = (UIButton *)sender;
        popover.sourceView = button;
        popover.sourceRect = button.bounds;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)selectMember:(DeviceListSelectMode)selectMode {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = selectMode;
    list.source = 2;
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count] > 0) {
            SelectModel *mod = devices[0];
            if ([mod.deviceID integerValue] > 32768) {
                CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:mod.deviceID];
                _sDeviceIDLabel.text = d.name;
            }else {
                CSRAreaEntity *a = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:mod.deviceID];
                _sDeviceIDLabel.text = a.areaName;
            }
            NSInteger d = [mod.deviceID integerValue];
            NSInteger h = (d & 0xFF00) >> 8;
            NSInteger l = d & 0x00FF;
            Byte byte[] = {0x67, 0x03, 0x00, l, h};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
            deviceEntity.remoteBranch = [NSString stringWithFormat:@"%@",mod.deviceID];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
    }];
    [self.navigationController pushViewController:list animated:YES];
}

- (IBAction)touchUp:(UISlider *)sender {
    NSInteger lux = sender.value;
    _controlLuxLabel.text = [NSString stringWithFormat:@"%ld",(long)lux];
    NSInteger h = (lux & 0xFF00) >> 8;
    NSInteger l = lux & 0x00FF;
    Byte byte[] = {0x67, 0x03, 0x01, l, h};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}
- (IBAction)controlValueChange:(UISlider *)sender {
    NSInteger lux = sender.value;
    _controlLuxLabel.text = [NSString stringWithFormat:@"%ld",(long)lux];
}

- (IBAction)sceneSet:(UIButton *)sender {
    sender.selected = YES;
    for (UIView *subview in sender.superview.subviews) {
        if (subview.tag != sender.tag) {
            UIButton *s = (UIButton *)subview;
            if (s.selected) {
                s.selected = NO;
            }
        }
    }
    Byte byte[] = {0xea, 0x88, 0x06, 0x02, sender.tag-1, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (IBAction)delaySet:(UISlider *)sender {
    NSInteger delay = sender.value;
    _delayTimeLabel.text = [NSString stringWithFormat:@"%ld", (long)delay];
    Byte byte[] = {0xea, 0x88, 0x00, 0x02, delay, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}
- (IBAction)delayValueChanged:(UISlider *)sender {
    NSInteger delay = sender.value;
    _delayTimeLabel.text = [NSString stringWithFormat:@"%ld", (long)delay];
}

- (IBAction)strengthChangeTimeSet:(UISlider *)sender {
    NSInteger time = sender.value;
    _strengthChangeTimeLabel.text = [NSString stringWithFormat:@"%ld",(long)time];
    Byte byte[] = {0xea, 0x88, 0x01, 0x02, time, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}
- (IBAction)strengthChangeTimeValueChanged:(UISlider *)sender {
    NSInteger time = sender.value;
    _strengthChangeTimeLabel.text = [NSString stringWithFormat:@"%ld",(long)time];
}

- (IBAction)detectionLuxSet:(UISlider *)sender {
    NSInteger lux = sender.value;
    _detectionLuxLabel.text = [NSString stringWithFormat:@"%ld",(long)lux];
    NSInteger h = (lux & 0xFF00) >> 8;
    NSInteger l = lux & 0x00FF;
    Byte byte[] = {0xea, 0x88, 0x02, 0x02, l, h};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}
- (IBAction)detectionLuxValueChanged:(UISlider *)sender {
    NSInteger lux = sender.value;
    _detectionLuxLabel.text = [NSString stringWithFormat:@"%ld",(long)lux];
}

- (IBAction)sensitivitySet:(UISlider *)sender {
    NSInteger sen = sender.value;
    _sensitivityLabel.text = [NSString stringWithFormat:@"%ld", (long)sen];
    Byte byte[] = {0xea, 0x88, 0x03, 0x02, sen, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}
- (IBAction)sensitivityValueChanged:(UISlider *)sender {
    NSInteger sen = sender.value;
    _sensitivityLabel.text = [NSString stringWithFormat:@"%ld", (long)sen];
}

- (IBAction)toleranceSet:(UISlider *)sender {
    NSInteger sen = sender.value;
    _toleranceLabel.text = [NSString stringWithFormat:@"%ld", (long)sen];
    Byte byte[] = {0xea, 0x88, 0x04, 0x02, sen, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}
- (IBAction)toleranceValueChanged:(UISlider *)sender {
    NSInteger sen = sender.value;
    _toleranceLabel.text = [NSString stringWithFormat:@"%ld", (long)sen];
}

- (IBAction)thresholdLuxSet:(UISlider *)sender {
    NSInteger lux = sender.value;
    _thresholdLuxLabel.text = [NSString stringWithFormat:@"%ld",(long)lux];
    NSInteger h = (lux & 0xFF00) >> 8;
    NSInteger l = lux & 0x00FF;
    Byte byte[] = {0xea, 0x88, 0x07, 0x02, l, h};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}
- (IBAction)thresholdLuxValueChanged:(UISlider *)sender {
    NSInteger lux = sender.value;
    _thresholdLuxLabel.text = [NSString stringWithFormat:@"%ld",(long)lux];
}

- (IBAction)calibrationLuxSet:(UISlider *)sender {
    NSInteger lux = sender.value;
    _calibrationLuxLabel.text = [NSString stringWithFormat:@"%ld",(long)lux];
    NSInteger h = (lux & 0xFF00) >> 8;
    NSInteger l = lux & 0x00FF;
    Byte byte[] = {0xea, 0x88, 0x08, 0x02, l, h};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}
- (IBAction)calibrationLuxValueChanged:(UISlider *)sender {
    NSInteger lux = sender.value;
    _calibrationLuxLabel.text = [NSString stringWithFormat:@"%ld",(long)lux];
}

- (IBAction)detect:(UIButton *)sender {
    sender.selected = YES;
    for (UIView *subview in sender.superview.subviews) {
        if (subview.tag != sender.tag) {
            UIButton *s = (UIButton *)subview;
            if (s.selected) {
                s.selected = NO;
            }
        }
    }
    Byte byte[] = {0xea, 0x88, 0x09, 0x02, sender.tag-1, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (IBAction)readTemperature:(id)sender {
    Byte byte[] = {0xea, 0x8a};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (void)pircall:(NSNotification *)notification {
    NSDictionary *useInfo = notification.userInfo;
    NSNumber *sourceDeviceId = useInfo[@"DEVICEID"];
    if ([sourceDeviceId isEqualToNumber:_deviceId]) {
        NSData *data = useInfo[@"DATA"];
        Byte *bytes = (Byte *)[data bytes];
        if (bytes[1] == 0x8a) {
            NSInteger lux = bytes[3] + bytes[4] * 256;
            [_controlLuxSlider setValue:lux];
            _controlLuxLabel.text = [NSString stringWithFormat:@"%ld",(long)lux];
            NSInteger l = bytes[5];
            NSInteger h = bytes[6] & 0x7F;
            NSInteger w = (bytes[6] & 0x80)>>7;
            _temperatureLabel.text = w==0 ? [NSString stringWithFormat:@"%ld.%ld",(long)h,(long)l] : [NSString stringWithFormat:@"-%ld.%ld",(long)h,(long)l];
            _nightLightState.text = bytes[7] == 0x01? @"开":@"关";
            
            Byte byte[] = {0xea, 0x89, 0x00};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }else if (bytes[1] == 0x89) {
            if (bytes[2] == 0x00) {
                NSInteger delay = bytes[4] + bytes[5] * 256;
                [_delayTimeSlider setValue:delay];
                _delayTimeLabel.text = [NSString stringWithFormat:@"%ld",(long)delay];
                NSInteger strength = bytes[6] + bytes[7] * 256;
                [_strengthChangeTimeSlider setValue:strength];
                _strengthChangeTimeLabel.text = [NSString stringWithFormat:@"%ld", (long)strength];
                NSInteger detection = bytes[8] + bytes[9] * 256;
                [_detectionLuxSlider setValue:detection];
                _detectionLuxLabel.text = [NSString stringWithFormat:@"%ld", (long)detection];
                
                Byte byte[] = {0xea, 0x89, 0x01};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }else if (bytes[2] == 0x01) {
                NSInteger sensitivity = bytes[4] + bytes[5] * 256;
                [_sensitivitySlider setValue:sensitivity];
                _sensitivityLabel.text = [NSString stringWithFormat:@"%ld", (long)sensitivity];
                NSInteger tolerance = bytes[6] + bytes[7] * 256;
                [_toleranceSlider setValue:tolerance];
                _toleranceLabel.text = [NSString stringWithFormat:@"%ld", (long)tolerance];
                NSInteger brightness = bytes[8] + bytes[9] * 256;
                [_nightLightBrightnessSlider setValue:brightness];
                _nightLightBrightness.text = [NSString stringWithFormat:@"%ld", (long)brightness];
                
                Byte byte[] = {0xea, 0x89, 0x02};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }else if (bytes[2] == 0x02) {
                NSInteger pirmodel = bytes[4] + bytes[5] * 256;
                UIButton *btn =(UIButton *)[_pirModelView viewWithTag:pirmodel+1];
                btn.selected = YES;
                NSInteger threshold = bytes[6] + bytes[7] * 256;
                [_thresholdLuxSlider setValue:threshold];
                _thresholdLuxLabel.text = [NSString stringWithFormat:@"%ld", (long)threshold];
                NSInteger calibration = bytes[8] + bytes[9] * 256;
                [_calibrationLuxSlider setValue:calibration];
                _calibrationLuxLabel.text = [NSString stringWithFormat:@"%ld", (long)calibration];
                
                Byte byte[] = {0xea, 0x89, 0x03};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }else if (bytes[2] == 0x03) {
                NSInteger detection = bytes[4] + bytes[5] * 256;
                UIButton *btn =(UIButton *)[_detectionModelView viewWithTag:detection+1];
                btn.selected = YES;
            }
        }
    }
}

- (IBAction)nightLightBrightnessSet:(UISlider *)sender {
    NSInteger lux = sender.value;
    _nightLightBrightness.text = [NSString stringWithFormat:@"%ld",(long)lux];
    Byte byte[] = {0xea, 0x88, 0x05, 0x02, lux, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}
- (IBAction)nightLightBrightnessValueChanged:(UISlider *)sender {
    NSInteger lux = sender.value;
    _nightLightBrightness.text = [NSString stringWithFormat:@"%ld",(long)lux];
}

- (void)disconnectForMCUUpdate {
    CSRDeviceEntity *deviceEn = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if ([deviceEn.uuid length] == 36) {
        [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
        [[UIApplication sharedApplication].keyWindow addSubview:self.indicatorView];
        [self.indicatorView autoCenterInSuperview];
        [self.indicatorView startAnimating];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(BridgeConnectedNotification:)
                                                     name:@"BridgeConnectedNotification"
                                                   object:nil];
        [[CSRBluetoothLE sharedInstance] disconnectPeripheralForMCUUpdate:[deviceEn.uuid substringFromIndex:24]];
        [self performSelector:@selector(connectForMCUUpdateDelayMethod) withObject:nil afterDelay:10.0];
    }
}

- (void)connectForMCUUpdateDelayMethod {
    _mcuAlert = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"mcu_connetion_alert", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
    [_mcuAlert.view setTintColor:DARKORAGE];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [[CSRBluetoothLE sharedInstance] cancelMCUUpdate];
        [self.indicatorView stopAnimating];
        [self.indicatorView removeFromSuperview];
        [self.translucentBgView removeFromSuperview];
        _indicatorView = nil;
        _translucentBgView = nil;
    }];
    UIAlertAction *conti = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"continue", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSelector:@selector(connectForMCUUpdateDelayMethod) withObject:nil afterDelay:10.0];
    }];
    [_mcuAlert addAction:cancel];
    [_mcuAlert addAction:conti];
    [self presentViewController:_mcuAlert animated:YES completion:nil];
}

- (void)BridgeConnectedNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CBPeripheral *peripheral = userInfo[@"peripheral"];
    NSString *adUuidString = [peripheral.uuidString substringToIndex:12];
    CSRDeviceEntity *deviceEn = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    NSString *deviceUuidString = [deviceEn.uuid substringFromIndex:24];
    if ([adUuidString isEqualToString:deviceUuidString]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectForMCUUpdateDelayMethod) object:nil];
        if (_mcuAlert) {
            [_mcuAlert dismissViewControllerAnimated:YES completion:nil];
            _mcuAlert = nil;
        }
        [self askUpdateMCU];
    }
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

- (void)askUpdateMCU {
    [UpdataMCUTool sharedInstace].toolDelegate = self;
    [[UpdataMCUTool sharedInstace] askUpdateMCU:_deviceId downloadAddress:downloadAddress latestMCUSVersion:latestMCUSVersion];
}

- (void)starteUpdateHud {
    if (!_updatingHud) {
        [self.indicatorView stopAnimating];
        [self.indicatorView removeFromSuperview];
        _indicatorView = nil;
        _updatingHud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        _updatingHud.mode = MBProgressHUDModeAnnularDeterminate;
        _updatingHud.delegate = self;
    }
}

- (void)updateHudProgress:(CGFloat)progress {
    if (_updatingHud) {
        _updatingHud.progress = progress;
    }
}

- (void)updateSuccess:(NSString *)value {
    if (_indicatorView) {
        [_indicatorView removeFromSuperview];
        _indicatorView = nil;
    }
    if (_translucentBgView) {
        [self.translucentBgView removeFromSuperview];
        self.translucentBgView = nil;
    }
    if (_updatingHud) {
        [_updatingHud hideAnimated:YES];
        [updateMCUBtn removeFromSuperview];
        updateMCUBtn = nil;
    }
    if (!_mcuAlert) {
        _mcuAlert = [UIAlertController alertControllerWithTitle:nil message:value preferredStyle:UIAlertControllerStyleAlert];
        [_mcuAlert.view setTintColor:DARKORAGE];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
        [_mcuAlert addAction:cancel];
        [self presentViewController:_mcuAlert animated:YES completion:nil];
    }else {
        [_mcuAlert setMessage:value];
    }
    [[CSRBluetoothLE sharedInstance] successMCUUpdate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BridgeConnectedNotification" object:nil];
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
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
