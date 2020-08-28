//
//  CurtainViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/9/19.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "CurtainViewController.h"
#import "CSRDatabaseManager.h"
#import <CSRmesh/DataModelApi.h>
#import "CSRUtilities.h"
#import <CSRmesh/LightModelApi.h>
#import "DeviceModelManager.h"
#import <MBProgressHUD.h>
#import "MCUUpdateTool.h"
#import "AFHTTPSessionManager.h"
#import "PureLayout.h"
#import "DataModelManager.h"

@interface CurtainViewController ()<UITextFieldDelegate,MBProgressHUDDelegate,MCUUpdateToolDelegate>
{
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
    UIButton *updateMCUBtn;
    
    NSInteger retryCount;
    NSData *retryCmd;
    BOOL calibrateMinUpTime;
    BOOL hasUp;
}
@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (weak, nonatomic) IBOutlet UIImageView *curtainTypeImageView;
@property (weak, nonatomic) IBOutlet UIButton *openBtn;
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;
@property (nonatomic,copy) NSString *originalName;
@property (nonatomic,assign) BOOL calibrating;
@property (weak, nonatomic) IBOutlet UIImageView *calibrateImageView;
@property (weak, nonatomic) IBOutlet UIButton *pauseBtn;
@property (weak, nonatomic) IBOutlet UISlider *curtainSlider;
@property (weak, nonatomic) IBOutlet UILabel *bubbleLabel;
@property (nonatomic,strong) MBProgressHUD *updatingHud;
@property (nonatomic,strong) UIView *translucentBgView;
@property (nonatomic,assign) NSInteger controllChannel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *channelSelectSeg;
@property (nonatomic,strong) CSRDeviceEntity *curtainEntity;

@end

@implementation CurtainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
    }
    UIBarButtonItem *calibrate = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"calibrate", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(calibrateAction)];
    self.navigationItem.rightBarButtonItem = calibrate;
    
    if (_deviceId) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setPowerStateSuccess:)
                                                     name:@"setPowerStateSuccess"
                                                   object:nil];
        _curtainEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        self.navigationItem.title = _curtainEntity.name;
        self.nameTf.delegate = self;
        self.nameTf.text = _curtainEntity.name;
        self.originalName = _curtainEntity.name;
        NSString *macAddr = [_curtainEntity.uuid substringFromIndex:24];
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
        self.controllChannel = 1;
        if ([_curtainEntity.remoteBranch isEqualToString:@"ch"]) {
            self.channelSelectSeg.hidden = YES;
            self.curtainTypeImageView.image = [UIImage imageNamed:@"curtainHImage"];
            [self.openBtn setImage:[UIImage imageNamed:@"curtainHOpen"] forState:UIControlStateNormal];
            [self.closeBtn setImage:[UIImage imageNamed:@"curtainHClose"] forState:UIControlStateNormal];
        }else if ([_curtainEntity.remoteBranch isEqualToString:@"cv"]) {
            self.curtainTypeImageView.image = [UIImage imageNamed:@"curtainVImage"];
            self.channelSelectSeg.hidden = YES;
            [self.openBtn setImage:[UIImage imageNamed:@"curtainVOpen"] forState:UIControlStateNormal];
            [self.closeBtn setImage:[UIImage imageNamed:@"curtainVClose"] forState:UIControlStateNormal];
        }else if ([_curtainEntity.remoteBranch isEqualToString:@"chh"]) {
            self.curtainTypeImageView.image = [UIImage imageNamed:@"curtainHHImage"];
            [self.openBtn setImage:[UIImage imageNamed:@"curtainHOpen"] forState:UIControlStateNormal];
            [self.closeBtn setImage:[UIImage imageNamed:@"curtainHClose"] forState:UIControlStateNormal];
        }else if ([_curtainEntity.remoteBranch isEqualToString:@"cvv"]) {
            self.curtainTypeImageView.image = [UIImage imageNamed:@"curtainVVImage"];
            [self.openBtn setImage:[UIImage imageNamed:@"curtainVOpen"] forState:UIControlStateNormal];
            [self.closeBtn setImage:[UIImage imageNamed:@"curtainVClose"] forState:UIControlStateNormal];
        }
        if ([CSRUtilities belongToOneChannelCurtainController:_curtainEntity.shortName]) {
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
            if ([_curtainEntity.shortName isEqualToString:@"C300IB"] || [_curtainEntity.shortName isEqualToString:@"C300IBH"]/*旧设备*/) {
                [_curtainSlider setValue:[model.level floatValue] animated:YES];
            }else {
                [_curtainSlider setValue:model.channel1Level animated:YES];
            }
        }else if ([CSRUtilities belongToTwoChannelCurtainController:_curtainEntity.shortName]) {
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
            [_curtainSlider setValue:model.channel1Level animated:YES];
        }
        
        
        if ([_curtainEntity.hwVersion integerValue]==2) {
            NSMutableString *mutStr = [NSMutableString stringWithString:_curtainEntity.shortName];
            NSRange range = {0,_curtainEntity.shortName.length};
            [mutStr replaceOccurrencesOfString:@"/" withString:@"" options:NSLiteralSearch range:range];
            NSString *urlString = [NSString stringWithFormat:@"http://39.108.152.134/MCU/%@/%@.php",mutStr,mutStr];
            AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
            sessionManager.responseSerializer.acceptableContentTypes = nil;
            sessionManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
            [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                NSDictionary *dic = (NSDictionary *)responseObject;
                latestMCUSVersion = [dic[@"mcu_software_version"] integerValue];
                downloadAddress = dic[@"Download_address"];
                if ([_curtainEntity.mcuSVersion integerValue]<latestMCUSVersion) {
                    updateMCUBtn = [UIButton buttonWithType:UIButtonTypeSystem];
                    [updateMCUBtn setBackgroundColor:[UIColor whiteColor]];
                    [updateMCUBtn setTitle:@"UPDATE MCU" forState:UIControlStateNormal];
                    [updateMCUBtn setTitleColor:DARKORAGE forState:UIControlStateNormal];
                    [updateMCUBtn addTarget:self action:@selector(askUpdateMCU) forControlEvents:UIControlEventTouchUpInside];
                    [self.view addSubview:updateMCUBtn];
                    [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeLeft];
                    [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeRight];
                    [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeBottom];
                    [updateMCUBtn autoSetDimension:ALDimensionHeight toSize:44.0];
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                NSLog(@"%@",error);
            }];
        }
        
    }
}

- (void)askUpdateMCU {
    [MCUUpdateTool sharedInstace].toolDelegate = self;
    [[MCUUpdateTool sharedInstace] askUpdateMCU:_deviceId downloadAddress:downloadAddress latestMCUSVersion:latestMCUSVersion];
}

- (void)starteUpdateHud {
    if (!_updatingHud) {
        [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
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

- (void)updateSuccess:(BOOL)value {
    if (_updatingHud) {
        [_updatingHud hideAnimated:YES];
        [self.translucentBgView removeFromSuperview];
        self.translucentBgView = nil;
        [updateMCUBtn removeFromSuperview];
        updateMCUBtn = nil;
        NSString *valueStr = value? AcTECLocalizedStringFromTable(@"Success", @"Localizable"):AcTECLocalizedStringFromTable(@"Error", @"Localizable");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:valueStr preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)calibrateAction {
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneCalibrateAction)];
    self.navigationItem.rightBarButtonItem = done;
    _calibrating = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calibrateCall:) name:@"calibrateCall" object:nil];
    
    _channelSelectSeg.enabled = NO;
    _pauseBtn.enabled = NO;
    _curtainSlider.hidden = YES;
    _calibrateImageView.hidden = NO;
    _bubbleLabel.hidden = NO;
    _calibrateImageView.image = [UIImage imageNamed:@"bubble_mid"];
    _bubbleLabel.text = AcTECLocalizedStringFromTable(@"bubble_mid_words", @"Localizable");
    _openBtn.enabled = NO;
    _closeBtn.enabled = NO;
    
    if ([CSRUtilities belongToOneChannelCurtainController:_curtainEntity.shortName]) {
        if ([_curtainEntity.shortName isEqualToString:@"C300IB"] || [_curtainEntity.shortName isEqualToString:@"C300IBH"]/*旧设备*/) {
            Byte byte[] = {0x79, 0x02, 0x04, 0x01};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
            retryCmd = 0;
            retryCmd = cmd;
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }else {
            Byte byte[] = {0x79, 0x03, 0x04, 0x01, 0x01};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
            retryCmd = 0;
            retryCmd = cmd;
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }
    }else if ([CSRUtilities belongToTwoChannelCurtainController:_curtainEntity.shortName]) {
        Byte byte[] = {0x79, 0x03, 0x04, 0x01, _controllChannel};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
        retryCmd = 0;
        retryCmd = cmd;
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }
    
    [self performSelector:@selector(failBeginCalibrate) withObject:nil afterDelay:3.0];
}

- (void)doneCalibrateAction {
    UIBarButtonItem *calibrate = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"calibrate", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(calibrateAction)];
    self.navigationItem.rightBarButtonItem = calibrate;
    _calibrating = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"calibrateCall" object:nil];
    
    _channelSelectSeg.enabled = YES;
    _pauseBtn.enabled = YES;
    _curtainSlider.hidden = NO;
    _calibrateImageView.hidden = YES;
    _bubbleLabel.hidden = YES;
    _openBtn.enabled = YES;
    _closeBtn.enabled = YES;
    
    if ([CSRUtilities belongToOneChannelCurtainController:_curtainEntity.shortName]) {
        if ([_curtainEntity.shortName isEqualToString:@"C300IB"] || [_curtainEntity.shortName isEqualToString:@"C300IBH"]/*旧设备*/) {
            Byte byte[] = {0x79, 0x02, 0x04, 0x00};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }else {
            Byte byte[] = {0x79, 0x03, 0x04, 0x00, 0x01};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }
    }else if ([CSRUtilities belongToTwoChannelCurtainController:_curtainEntity.shortName]) {
        Byte byte[] = {0x79, 0x03, 0x04, 0x00, _controllChannel};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }
}

- (void)failBeginCalibrate {
    if (retryCount == 0) {
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:retryCmd];
        retryCount ++;
        [self performSelector:@selector(failBeginCalibrate) withObject:nil afterDelay:3.0];
    }else if (retryCount == 1) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"Calibrationfailure", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self doneCalibrateAction];
        }];
        [alert addAction:yes];
        [self presentViewController:alert animated:YES completion:nil];
    }
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

- (void)calibrateCall:(NSNotification *)result {
    NSDictionary *resultDic = result.userInfo;
    NSNumber *sourceDeviceId = resultDic[@"deviceId"];
    NSInteger step = [resultDic[@"step"] integerValue];
    NSInteger channel = [resultDic[@"channel"] integerValue];
    if ([sourceDeviceId isEqualToNumber:_deviceId] && channel == _controllChannel) {
        if (step == 1) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(failBeginCalibrate) object:nil];
            _openBtn.enabled = YES;
            _closeBtn.enabled = NO;
            _calibrateImageView.image = [UIImage imageNamed:@"bubble_left"];
            _bubbleLabel.text = AcTECLocalizedStringFromTable(@"bubble_left_words", @"Localizable");
        }else if (step == 2) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(failCalibrateTouchUp) object:nil];
            _openBtn.enabled = NO;
            _closeBtn.enabled = YES;
            _calibrateImageView.image = [UIImage imageNamed:@"bubble_right"];
            _bubbleLabel.text = AcTECLocalizedStringFromTable(@"bubble_right_words", @"Localizable");
        }else if (step == 3) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(failCalibrateTouchUp) object:nil];
            _openBtn.enabled = YES;
            _closeBtn.enabled = NO;
            _calibrateImageView.image = [UIImage imageNamed:@"bubble_left"];
            _bubbleLabel.text = AcTECLocalizedStringFromTable(@"bubble_left_words", @"Localizable");
        }else if (step == 255) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(failCalibrateTouchUp) object:nil];
            [self doneCalibrateAction];
        }else if (step == 0) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(failCalibrateTouchUp) object:nil];
            [self failBeginCalibrate];
        }
    }
}

#pragma mark - 校准

- (IBAction)curtainOpenTouchDown:(UIButton *)sender {
    if (_calibrating) {
        if ([CSRUtilities belongToOneChannelCurtainController:_curtainEntity.shortName]) {
            if ([_curtainEntity.shortName isEqualToString:@"C300IB"] || [_curtainEntity.shortName isEqualToString:@"C300IBH"]/*旧设备*/) {
                Byte byte[] = {0x79, 0x03, 0x03, 0xff, 0x00};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }else {
                Byte byte[] = {0x79, 0x04, 0x03, 0xff, 0x00, 0x01};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }
        }else if ([CSRUtilities belongToTwoChannelCurtainController:_curtainEntity.shortName]) {
            Byte byte[] = {0x79, 0x04, 0x03, 0xff, 0x00, _controllChannel};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }
        calibrateMinUpTime = NO;
        hasUp = NO;
        [self performSelector:@selector(reachCalibrateMinUpTime) withObject:nil afterDelay:2.0];
    }
}

- (IBAction)curtainCloseTouchDown:(UIButton *)sender {
    if (_calibrating) {
        if ([CSRUtilities belongToOneChannelCurtainController:_curtainEntity.shortName]) {
            if ([_curtainEntity.shortName isEqualToString:@"C300IB"] || [_curtainEntity.shortName isEqualToString:@"C300IBH"]/*旧设备*/) {
                Byte byte[] = {0x79, 0x03, 0x03, 0xff, 0x00};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }else {
                Byte byte[] = {0x79, 0x04, 0x03, 0xff, 0x00, 0x01};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }
        }else if ([CSRUtilities belongToTwoChannelCurtainController:_curtainEntity.shortName]) {
            Byte byte[] = {0x79, 0x04, 0x03, 0xff, 0x00, _controllChannel};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }
        calibrateMinUpTime = NO;
        hasUp = NO;
        [self performSelector:@selector(reachCalibrateMinUpTime) withObject:nil afterDelay:2.0];
    }
}

- (void)reachCalibrateMinUpTime {
    calibrateMinUpTime = YES;
    if (hasUp) {
        [self calibrateTouchUpMethod];
    }
}

#pragma mark - 控制

- (IBAction)channelSelectAction:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
        {
            self.controllChannel = 1;
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
            [_curtainSlider setValue:model.channel1Level animated:YES];
        }
            break;
        case 1:
        {
            self.controllChannel = 2;
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
            [_curtainSlider setValue:model.channel2Level animated:YES];
        }
            break;
        default:
            break;
    }
}

- (IBAction)curtainOpenAction:(UIButton *)sender {
    if (_calibrating) {
        hasUp = YES;
        if (calibrateMinUpTime) {
            [self calibrateTouchUpMethod];
        }
    }else {
        Byte byte[] = {0x79, 0x02, 0x02, _controllChannel};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }
}
- (IBAction)curtainPauseAction:(UIButton *)sender {
    if (!_calibrating) {
        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"7902000%ld",(long)_controllChannel]] success:nil failure:nil];
    }
    
}
- (IBAction)crutainClose:(UIButton *)sender {
    if (_calibrating) {
        hasUp = YES;
        if (calibrateMinUpTime) {
            [self calibrateTouchUpMethod];
        }
    }else {
        Byte byte[] = {0x79, 0x02, 0x01, _controllChannel};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }
}

- (IBAction)curtainOpenAndCloseTouchUpOutside:(id)sender {
    if (_calibrating) {
        hasUp = YES;
        if (calibrateMinUpTime) {
            [self calibrateTouchUpMethod];
        }
    }
}

- (void)calibrateTouchUpMethod {
    if ([CSRUtilities belongToOneChannelCurtainController:_curtainEntity.shortName]) {
        if ([_curtainEntity.shortName isEqualToString:@"C300IB"] || [_curtainEntity.shortName isEqualToString:@"C300IBH"]/*旧设备*/) {
            Byte byte[] = {0x79, 0x03, 0x03, 0x00, 0x00};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
            retryCount = 0;
            retryCmd = cmd;
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }else {
            Byte byte[] = {0x79, 0x04, 0x03, 0x00, 0x00, 0x01};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
            retryCount = 0;
            retryCmd = cmd;
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }
    }else if ([CSRUtilities belongToTwoChannelCurtainController:_curtainEntity.shortName]) {
        Byte byte[] = {0x79, 0x04, 0x03, 0x00, 0x00, _controllChannel};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
        retryCount = 0;
        retryCmd = cmd;
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }
    [self performSelector:@selector(failCalibrateTouchUp) withObject:nil afterDelay:3.0];
}

- (void)failCalibrateTouchUp {
    if (_calibrating) {
        if (retryCount == 0) {
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:retryCmd];
            retryCount ++;
            [self performSelector:@selector(failCalibrateTouchUp) withObject:nil afterDelay:3.0];
        }else if (retryCount == 1) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"Calibrationfailure", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
            [alert.view setTintColor:DARKORAGE];
            UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self doneCalibrateAction];
            }];
            [alert addAction:yes];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (IBAction)sliderTouchUpInside:(UISlider *)sender {
    if (!_calibrating) {
        if (sender.value == 255) {
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"7902010%ld",(long)_controllChannel]] success:nil failure:nil];
        }else if (sender.value == 0) {
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"7902020%ld",(long)_controllChannel]] success:nil failure:nil];
        }else {
            if ([CSRUtilities belongToOneChannelCurtainController:_curtainEntity.shortName]) {
                [[LightModelApi sharedInstance] setLevel:_deviceId level:@(sender.value) success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                    
                } failure:^(NSError * _Nullable error) {
                    
                }];
            }else if ([CSRUtilities belongToTwoChannelCurtainController:_curtainEntity.shortName]) {
                BOOL state = sender.value == 255? NO:YES;
                NSString *cmdStr = [NSString stringWithFormat:@"7906060%ld00030%d%@",(long)_controllChannel,state,[CSRUtilities stringWithHexNumber:sender.value]];
                [[DataModelManager shareInstance] sendCmdData:cmdStr toDeviceId:_deviceId];
            }
        }
    }
}

- (IBAction)sliderTouchUpOutside:(UISlider *)sender {
    if (!_calibrating) {
        if (sender.value == 255) {
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"7902010%ld",(long)_controllChannel]] success:nil failure:nil];
        }else if (sender.value == 0) {
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"7902020%ld",(long)_controllChannel]] success:nil failure:nil];
        }else {
            if ([CSRUtilities belongToOneChannelCurtainController:_curtainEntity.shortName]) {
                if ([_curtainEntity.shortName isEqualToString:@"C300IB"] || [_curtainEntity.shortName isEqualToString:@"C300IBH"]/*旧设备*/) {
                    [[LightModelApi sharedInstance] setLevel:_deviceId level:@(sender.value) success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                        
                    } failure:^(NSError * _Nullable error) {
                        
                    }];
                }else {
                    BOOL state = sender.value == 255? NO:YES;
                    [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"7906060100030%d%@",state,[CSRUtilities stringWithHexNumber:sender.value]] toDeviceId:_deviceId];
                }
            }else if ([CSRUtilities belongToTwoChannelCurtainController:_curtainEntity.shortName]) {
                BOOL state = sender.value == 255? NO:YES;
                NSString *cmdStr = [NSString stringWithFormat:@"7906060%ld00030%d%@",(long)_controllChannel,state,[CSRUtilities stringWithHexNumber:sender.value]];
                [[DataModelManager shareInstance] sendCmdData:cmdStr toDeviceId:_deviceId];
            }
        }
    }
}

- (void)setPowerStateSuccess:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSInteger channel = [userInfo[@"channel"] integerValue];
    if ([deviceId isEqualToNumber:_deviceId]) {
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        if (channel == 1) {
            [_curtainSlider setValue:[model.level floatValue] animated:YES];
        }else if (channel == 2 && _controllChannel == 1) {
            [_curtainSlider setValue:model.channel1Level animated:YES];
        }else if (channel == 3 && _controllChannel == 2) {
            [_curtainSlider setValue:model.channel2Level animated:YES];
        }
    }
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

- (UIView *)translucentBgView {
    if (!_translucentBgView) {
        _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _translucentBgView.backgroundColor = [UIColor blackColor];
        _translucentBgView.alpha = 0.4;
    }
    return _translucentBgView;
}

@end
