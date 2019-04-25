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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *left1Constaint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *left2Constaint;
@property (weak, nonatomic) IBOutlet UIImageView *channelSelected1ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *channelSelected2ImageView;
@property (weak, nonatomic) IBOutlet UIButton *channelSelected1Btn;
@property (weak, nonatomic) IBOutlet UIButton *channelSelected2Btn;
@property (nonatomic,strong) MBProgressHUD *updatingHud;

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
        
        if (_forSelected) {
            _channelSelected1ImageView.hidden = NO;
            _channelSelected2ImageView.hidden = NO;
            _channelSelected1Btn.hidden = NO;
            _channelSelected2Btn.hidden = NO;
            _left1Constaint.constant = 44;
            _left2Constaint.constant = 44;
        }
        
        [self changeUI:_deviceId];
        
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
                    UIButton *updateMCUBtn = [UIButton buttonWithType:UIButtonTypeSystem];
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
        _updatingHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _updatingHud.mode = MBProgressHUDModeAnnularDeterminate;
        _updatingHud.delegate = self;
    }
}

- (void)updateHudProgress:(CGFloat)progress {
    if (_updatingHud) {
        _updatingHud.progress = progress;
    }
}

- (void)hideUpdateHud {
    if (_updatingHud) {
        [_updatingHud hideAnimated:YES];
    }
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setSocketSuccess: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        [self changeUI:deviceId];
    }
}

- (void)changeUI:(NSNumber *)deviceId {
    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance]getDeviceModelByDeviceId:deviceId];
    if (deviceModel) {
        [_channel1Switch setOn:deviceModel.channel1PowerState];
        [_channel2Switch setOn:deviceModel.channel2PowerState];
        _channelSelected1ImageView.image = deviceModel.channel1Selected? [UIImage imageNamed:@"Be_selected"]:[UIImage imageNamed:@"To_select"];
        _channelSelected2ImageView.image = deviceModel.channel2Selected? [UIImage imageNamed:@"Be_selected"]:[UIImage imageNamed:@"To_select"];
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

- (IBAction)channelSeleteBtn:(UIButton *)sender {
    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance]getDeviceModelByDeviceId:_deviceId];
    if ((deviceModel.channel1Selected && !deviceModel.channel2Selected && sender.tag == 1) || (!deviceModel.channel1Selected && deviceModel.channel2Selected && sender.tag == 2)) {
        return;
    }
    sender.selected = !sender.selected;
    UIImage *image = sender.selected? [UIImage imageNamed:@"Be_selected"]:[UIImage imageNamed:@"To_select"];
    
    switch (sender.tag) {
        case 1:
            _channelSelected1ImageView.image = image;
            deviceModel.channel1Selected = sender.selected;
            break;
        case 2:
            _channelSelected2ImageView.image = image;
            deviceModel.channel2Selected = sender.selected;
            break;
        default:
            break;
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

@end
