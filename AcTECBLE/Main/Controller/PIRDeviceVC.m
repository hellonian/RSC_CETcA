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

@interface PIRDeviceVC ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (nonatomic,copy) NSString *originalName;
@property (weak, nonatomic) IBOutlet UILabel *sDeviceIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *controlLuxLabel;
@property (weak, nonatomic) IBOutlet UILabel *delayTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *strengthChangeTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *detectionLuxLabel;
@property (weak, nonatomic) IBOutlet UILabel *sensitivityLabel;
@property (weak, nonatomic) IBOutlet UILabel *toleranceLabel;
@property (weak, nonatomic) IBOutlet UILabel *calibrationLuxLabel;
@property (weak, nonatomic) IBOutlet UILabel *thresholdLuxLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *nightLightBrightness;

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
        CSRDeviceEntity *curtainEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        self.navigationItem.title = curtainEntity.name;
        self.nameTf.delegate = self;
        self.nameTf.text = curtainEntity.name;
        self.originalName = curtainEntity.name;
        NSString *macAddr = [curtainEntity.uuid substringFromIndex:24];
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
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pircall:)
                                                 name:@"PIRCALL"
                                               object:nil];
    
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
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)selectMember:(DeviceListSelectMode)selectMode {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = selectMode;
    list.source = 2;
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count] > 0) {
            SelectModel *mod = devices[0];
            NSLog(@"%@",mod.deviceID);
            _sDeviceIDLabel.text = [NSString stringWithFormat:@"%@",mod.deviceID];
            NSInteger d = [mod.deviceID integerValue];
            NSInteger h = (d & 0xFF00) >> 8;
            NSInteger l = d & 0x00FF;
            Byte byte[] = {0x67, 0x03, 0x00, l, h};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
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

- (IBAction)detect:(id)sender {
    Byte byte[] = {0xea, 0x88, 0x09, 0x02, 0x00, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (IBAction)readTemperature:(id)sender {
    Byte byte[] = {0xea, 0x8a, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (void)pircall:(NSNotification *)notification {
    NSDictionary *useInfo = notification.userInfo;
    NSNumber *sourceDeviceId = useInfo[@"DEVICEID"];
    if ([sourceDeviceId isEqualToNumber:_deviceId]) {
        NSInteger configID = [useInfo[@"CONFIGID"] integerValue];
        if (configID == 0) {
            _temperatureLabel.text = [NSString stringWithFormat:@"%@.%@",useInfo[@"VALUEHIGH"],useInfo[@"VALUELOW"]];
        }
    }
}

- (IBAction)nightLightSwitch:(UIButton *)sender {
    sender.selected = YES;
    for (UIView *subview in sender.superview.subviews) {
        if (subview.tag != sender.tag) {
            UIButton *s = (UIButton *)subview;
            if (s.selected) {
                s.selected = NO;
            }
        }
    }
    Byte byte[] = {0xea, 0x88, 0x04, 0x02, sender.tag-1, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
