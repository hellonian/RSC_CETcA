//
//  CurtainViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/9/19.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "CurtainViewController.h"
#import "CSRDatabaseManager.h"
#import <CSRmesh/DataModelApi.h>
#import "CSRUtilities.h"
#import <CSRmesh/LightModelApi.h>

@interface CurtainViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (weak, nonatomic) IBOutlet UIImageView *curtainTypeImageView;
@property (weak, nonatomic) IBOutlet UIButton *openBtn;
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;
@property (nonatomic,copy) NSString *originalName;
@property (nonatomic,assign) BOOL calibrating;
@property (weak, nonatomic) IBOutlet UIImageView *calibrateImageView;
@property (nonatomic,assign) BOOL calibrateReady;
@property (weak, nonatomic) IBOutlet UIButton *PauseBtn;
@property (weak, nonatomic) IBOutlet UISlider *curtainSlider;

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
        if ([curtainEntity.remoteBranch isEqualToString:@"ch"]) {
            self.curtainTypeImageView.image = [UIImage imageNamed:@"curtainHImage"];
            [self.openBtn setImage:[UIImage imageNamed:@"curtainHOpen"] forState:UIControlStateNormal];
            [self.closeBtn setImage:[UIImage imageNamed:@"curtainHClose"] forState:UIControlStateNormal];
        }else if ([curtainEntity.remoteBranch isEqualToString:@"cv"]) {
            self.curtainTypeImageView.image = [UIImage imageNamed:@"curtainVImage"];
            [self.openBtn setImage:[UIImage imageNamed:@"curtainVOpen"] forState:UIControlStateNormal];
            [self.closeBtn setImage:[UIImage imageNamed:@"curtainVClose"] forState:UIControlStateNormal];
        }
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
    
    _curtainTypeImageView.hidden = YES;
    _PauseBtn.hidden = YES;
    _curtainSlider.hidden = YES;
    _calibrateImageView.hidden = NO;
    
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"79020401"] success:nil failure:nil]; 
}

- (void)doneCalibrateAction {
    UIBarButtonItem *calibrate = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"calibrate", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(calibrateAction)];
    self.navigationItem.rightBarButtonItem = calibrate;
    _calibrating = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"calibrateCall" object:nil];
    
    _curtainTypeImageView.hidden = NO;
    _PauseBtn.hidden = NO;
    _curtainSlider.hidden = NO;
    _calibrateImageView.hidden = YES;
    _calibrateImageView.image = [UIImage imageNamed:AcTECLocalizedStringFromTable(@"bubble_mid", @"Localizable")];
    
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"79020400"] success:nil failure:nil];
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
    NSString *correctionStep = resultDic[@"correctionStep"];
    NSNumber *sourceDeviceId = resultDic[@"deviceId"];
    if ([sourceDeviceId isEqualToNumber:_deviceId]) {
        if ([correctionStep isEqualToString:@"01"]) {
            _calibrateReady = YES;
            _calibrateImageView.image = [UIImage imageNamed:AcTECLocalizedStringFromTable(@"bubble_left", @"Localizable")];
        }else if ([correctionStep isEqualToString:@"02"]) {
            _calibrateImageView.image = [UIImage imageNamed:AcTECLocalizedStringFromTable(@"bubble_right", @"Localizable")];
        }else if ([correctionStep isEqualToString:@"03"]) {
            _calibrateImageView.image = [UIImage imageNamed:AcTECLocalizedStringFromTable(@"bubble_left", @"Localizable")];
        }else if ([correctionStep isEqualToString:@"ff"]) {
            _calibrateReady = NO;
            [self doneCalibrateAction];
        }
    }
}

#pragma mark - 校准

- (IBAction)curtainOpenTouchDown:(UIButton *)sender {
    if (_calibrating && _calibrateReady) {
        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"790303ff00"] success:nil failure:nil];
    }
}

- (IBAction)curtainCloseTouchDown:(UIButton *)sender {
    if (_calibrating && _calibrateReady) {
        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"790303ff00"] success:nil failure:nil];
    }
}

#pragma mark - 控制

- (IBAction)curtainOpenAction:(UIButton *)sender {
    if (!_calibrating) {
        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"790102"] success:nil failure:nil];
    }else if (_calibrateReady) {
        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"7903030000"] success:nil failure:nil];
    }
}
- (IBAction)curtainPauseAction:(UIButton *)sender {
    if (!_calibrating) {
        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"790100"] success:nil failure:nil];
    }
    
}
- (IBAction)crutainClose:(UIButton *)sender {
    if (!_calibrating) {
        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"790101"] success:nil failure:nil];
    }else if (_calibrateReady) {
        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"7903030000"] success:nil failure:nil];
    }
}

- (IBAction)sliderTouchUpInside:(UISlider *)sender {
    if (!_calibrating) {
        [[LightModelApi sharedInstance] setLevel:_deviceId level:@(sender.value) success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
            
        } failure:^(NSError * _Nullable error) {
            
        }];
    }
}

- (IBAction)sliderTouchUpOutside:(UISlider *)sender {
    if (!_calibrating) {
        [[LightModelApi sharedInstance] setLevel:_deviceId level:@(sender.value) success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
            
        } failure:^(NSError * _Nullable error) {
            
        }];
    }
}

@end
