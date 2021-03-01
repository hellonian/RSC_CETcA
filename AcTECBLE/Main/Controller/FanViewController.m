//
//  FanViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/11/12.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "FanViewController.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import <CSRmesh/DataModelApi.h>
#import "DeviceModelManager.h"
#import "PureLayout.h"
#import "DataModelManager.h"

@interface FanViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (nonatomic,copy) NSString *originalName;
@property (nonatomic,assign)BOOL fanPowerState;
@property (nonatomic,assign)int fanSpeed;
@property (nonatomic,assign)BOOL lampPowerState;
@property (weak, nonatomic) IBOutlet UISwitch *lampStateSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *fanStateSwitch;
@property (weak, nonatomic) IBOutlet UISlider *fanSpeedSlider;

@end

@implementation FanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (_source == 1) {
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
        self.navigationItem.rightBarButtonItem = done;
        self.nameTf.enabled = NO;
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
                                             selector:@selector(setFanSuccess:)
                                                 name:@"setPowerStateSuccess"
                                               object:nil];
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
        
        [self changeUI:_deviceId];
    }
    
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

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

#pragma mark - 保存修改后的灯名

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

- (IBAction)lampPowerStateSwitch:(UISwitch *)sender {
    _lampPowerState = sender.on;
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"9c04010%d0%d0%d",_fanPowerState,_fanSpeed,sender.on]] success:nil failure:nil];
}

- (IBAction)fanPowerStateSwitch:(UISwitch *)sender {
    _fanPowerState = sender.on;
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"9c04010%d0%d0%d",sender.on,_fanSpeed,_lampPowerState]] success:nil failure:nil];
}
- (IBAction)fanSpeedChange:(UISlider *)sender {
    int speed = 0;
    if (fabsf(sender.value)<=0.5) {
        speed = 0;
    }else if (fabsf(sender.value - 1)<=0.5) {
        speed = 1;
    }else {
        speed = 2;
    }
    [sender setValue:speed];
    _fanSpeed = speed;
    if (_fanPowerState) {
        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"9c0401010%d0%d",speed,_lampPowerState]] success:nil failure:nil];
    }
}

- (void)setFanSuccess: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        [self changeUI:deviceId];
    }
    
}

- (void)changeUI:(NSNumber *)deviceId {
    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance]getDeviceModelByDeviceId:deviceId];
    if (deviceModel) {
        if (_lampStateSwitch.on != deviceModel.lampState) {
            [_lampStateSwitch setOn:deviceModel.lampState];
        }
        if (_fanStateSwitch.on != deviceModel.fanState) {
            [_fanStateSwitch setOn:deviceModel.fanState];
        }
        if (_fanSpeedSlider.value != deviceModel.fansSpeed) {
            [_fanSpeedSlider setValue:(CGFloat)deviceModel.fansSpeed];
        }
        _lampPowerState = deviceModel.lampState;
        _fanPowerState = deviceModel.fanState;
        _fanSpeed = deviceModel.fansSpeed;
        if (_fanPowerState) {
            _fanSpeedSlider.enabled = YES;
        }else {
            _fanSpeedSlider.enabled = NO;
        }
    }
}

- (void)doneAction {
    if (self.reloadDataHandle) {
        self.reloadDataHandle();
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
