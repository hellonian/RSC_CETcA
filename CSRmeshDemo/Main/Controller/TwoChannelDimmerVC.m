//
//  TwoChannelDimmerVC.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/1/9.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "TwoChannelDimmerVC.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import <CSRmesh/DataModelApi.h>
#import "DeviceModelManager.h"
#import "AFHTTPSessionManager.h"
#import "PureLayout.h"
#import "DataModelManager.h"
#import <MBProgressHUD.h>
#import "MCUUpdateTool.h"

@interface TwoChannelDimmerVC ()<UITextFieldDelegate,MBProgressHUDDelegate,MCUUpdateToolDelegate>
{
    NSTimer *timer;
    NSInteger currentLevel;
    NSInteger currenState;
    
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
    UIButton *updateMCUBtn;
}

@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (nonatomic,copy) NSString *originalName;
@property (weak, nonatomic) IBOutlet UISwitch *channel1Switch;
@property (weak, nonatomic) IBOutlet UISwitch *channel2Switch;
@property (weak, nonatomic) IBOutlet UISlider *channel1Slider;
@property (weak, nonatomic) IBOutlet UISlider *channel2Slider;
@property (weak, nonatomic) IBOutlet UILabel *channel1LevelLabel;
@property (weak, nonatomic) IBOutlet UILabel *channel2LevelLabel;
@property (nonatomic,strong) MBProgressHUD *updatingHud;
@property (nonatomic,strong) UIView *translucentBgView;

@end

@implementation TwoChannelDimmerVC

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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setSocketSuccess:)
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
                
        if ([curtainEntity.hwVersion integerValue]==2) {
            NSMutableString *mutStr = [NSMutableString stringWithString:curtainEntity.shortName];
            NSRange range = {0,curtainEntity.shortName.length};
            [mutStr replaceOccurrencesOfString:@"/" withString:@"" options:NSLiteralSearch range:range];
            NSString *urlString = [NSString stringWithFormat:@"http://39.108.152.134/MCU/%@/%@.php",mutStr,mutStr];
            AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
            sessionManager.responseSerializer.acceptableContentTypes = nil;
            sessionManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
            [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                NSDictionary *dic = (NSDictionary *)responseObject;
                latestMCUSVersion = [dic[@"mcu_software_version"] integerValue];
                downloadAddress = dic[@"Download_address"];
                if ([curtainEntity.mcuSVersion integerValue]<latestMCUSVersion) {
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self changeUI:_deviceId channel:3];
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
        if (value) {
            timer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(timerMethod:) userInfo:nil repeats:YES];
            [timer fire];
        }
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

- (void)setSocketSuccess: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSInteger channel = [userInfo[@"channel"] integerValue];
    if ([deviceId isEqualToNumber:_deviceId]) {
        [self changeUI:deviceId channel:channel];
    }
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

- (IBAction)turnOnOff:(UISwitch *)sender {
    NSString *cmdString;
    switch (sender.tag) {
        case 1:
            cmdString = [NSString stringWithFormat:@"51050100010%d00",sender.on];
            break;
        case 2:
            cmdString = [NSString stringWithFormat:@"51050200010%d00",sender.on];
            break;
        default:
            break;
    }
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
}

- (IBAction)touchDown:(UISlider *)sender {
    currenState = 1;
    currentLevel=sender.value;
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(timerMethod:) userInfo:@(sender.tag) repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (IBAction)valueChanged:(UISlider *)sender {
    currenState = 2;
    currentLevel=sender.value;
}

- (IBAction)touchUpInSideOrTouchUpOutSide:(UISlider *)sender {
    currenState = 3;
    currentLevel=sender.value;
}

- (void)timerMethod:(NSTimer *)infotimer {
    @synchronized (self) {
        NSNumber *channel = infotimer.userInfo;
        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"5105%@000301%@",[CSRUtilities stringWithHexNumber:[channel integerValue]],[CSRUtilities stringWithHexNumber:currentLevel]]] success:nil failure:nil];
        if (currenState==3) {
            [timer invalidate];
            timer = nil;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (timer) {
        [timer invalidate];
        timer = nil;
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

- (void)changeUI:(NSNumber *)deviceId channel:(NSInteger)channel{
    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance]getDeviceModelByDeviceId:deviceId];
    if (deviceModel) {
        
        if (channel == 1) {
            [_channel1Switch setOn:deviceModel.channel1PowerState];
            if (deviceModel.channel1PowerState) {
                _channel1Slider.enabled = YES;
                [_channel1Slider setValue:deviceModel.channel1Level];
                _channel1LevelLabel.text = [NSString stringWithFormat:@"%.f%%",deviceModel.channel1Level/255.0*100];
            }else {
                _channel1Slider.enabled = NO;
                [_channel1Slider setValue:0];
                _channel1LevelLabel.text = @"0%";
            }
        }else if (channel == 2) {
            [_channel2Switch setOn:deviceModel.channel2PowerState];
            if (deviceModel.channel2PowerState) {
                _channel2Slider.enabled = YES;
                [_channel2Slider setValue:deviceModel.channel2Level];
                _channel2LevelLabel.text = [NSString stringWithFormat:@"%.f%%",deviceModel.channel2Level/255.0*100];
            }else {
                _channel2Slider.enabled = NO;
                [_channel2Slider setValue:0];
                _channel2LevelLabel.text = @"0%";
            }
        }else if (channel == 3) {
            [_channel1Switch setOn:deviceModel.channel1PowerState];
            [_channel2Switch setOn:deviceModel.channel2PowerState];
            if (deviceModel.channel1PowerState) {
                _channel1Slider.enabled = YES;
                [_channel1Slider setValue:deviceModel.channel1Level];
                _channel1LevelLabel.text = [NSString stringWithFormat:@"%.f%%",deviceModel.channel1Level/255.0*100];
            }else {
                _channel1Slider.enabled = NO;
                [_channel1Slider setValue:0];
                _channel1LevelLabel.text = @"0%";
            }
            if (deviceModel.channel2PowerState) {
                _channel2Slider.enabled = YES;
                [_channel2Slider setValue:deviceModel.channel2Level];
                _channel2LevelLabel.text = [NSString stringWithFormat:@"%.f%%",deviceModel.channel2Level/255.0*100];
            }else {
                _channel2Slider.enabled = NO;
                [_channel2Slider setValue:0];
                _channel2LevelLabel.text = @"0%";
            }
        }
    }
}

@end
