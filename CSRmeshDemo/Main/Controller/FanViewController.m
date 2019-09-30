//
//  FanViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/11/12.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "FanViewController.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import <CSRmesh/DataModelApi.h>
#import "DeviceModelManager.h"
#import "MCUUpdateTool.h"
#import "PureLayout.h"
#import <MBProgressHUD.h>
#import "AFHTTPSessionManager.h"
#import "DataModelManager.h"

@interface FanViewController ()<UITextFieldDelegate,MBProgressHUDDelegate,MCUUpdateToolDelegate>
{
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
    UIButton *updateMCUBtn;
}
@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (nonatomic,copy) NSString *originalName;
@property (nonatomic,assign)BOOL fanPowerState;
@property (nonatomic,assign)int fanSpeed;
@property (nonatomic,assign)BOOL lampPowerState;
@property (weak, nonatomic) IBOutlet UISwitch *lampStateSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *fanStateSwitch;
@property (weak, nonatomic) IBOutlet UISlider *fanSpeedSlider;
@property (nonatomic,strong) MBProgressHUD *updatingHud;
@property (nonatomic,strong) UIView *translucentBgView;
@property (weak, nonatomic) IBOutlet UIImageView *lampSelectedImageView;
@property (weak, nonatomic) IBOutlet UIImageView *fanSelectedImageView;
@property (weak, nonatomic) IBOutlet UIButton *lampSelectedBtn;
@property (weak, nonatomic) IBOutlet UIButton *fanSelectedBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lampLeftConstaint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fanLeftConstaint;

@end

@implementation FanViewController

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
        
        if (_forSelected) {
            _lampSelectedImageView.hidden = NO;
            _fanSelectedImageView.hidden = NO;
            _lampSelectedBtn.hidden = NO;
            _fanSelectedBtn.hidden = NO;
            _lampLeftConstaint.constant = 44;
            _fanLeftConstaint.constant = 44;
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
        
        if (_buttonNum && [deviceModel.buttonnumAndChannel count]>0 && [deviceModel.buttonnumAndChannel objectForKey:[NSString stringWithFormat:@"%@",_buttonNum]]) {
            NSNumber *obj = [deviceModel.buttonnumAndChannel objectForKey:[NSString stringWithFormat:@"%@",_buttonNum]];
            if ([obj isEqualToNumber:@4]) {
                _lampSelectedImageView.image = [UIImage imageNamed:@"Be_selected"];
                _fanSelectedImageView.image = [UIImage imageNamed:@"Be_selected"];
                _lampSelectedBtn.selected = YES;
                _fanSelectedBtn.selected = YES;
            }else if ([obj isEqualToNumber:@3]){
                _lampSelectedImageView.image = [UIImage imageNamed:@"Be_selected"];
                _fanSelectedImageView.image = [UIImage imageNamed:@"To_select"];
                _lampSelectedBtn.selected = YES;
                _fanSelectedBtn.selected = NO;
            }else if ([obj isEqualToNumber:@2]) {
                _lampSelectedImageView.image = [UIImage imageNamed:@"To_select"];
                _fanSelectedImageView.image = [UIImage imageNamed:@"Be_selected"];
                _lampSelectedBtn.selected = NO;
                _fanSelectedBtn.selected = YES;
            }else {
                _lampSelectedImageView.image = [UIImage imageNamed:@"To_select"];
                _fanSelectedImageView.image = [UIImage imageNamed:@"To_select"];
                _lampSelectedBtn.selected = NO;
                _fanSelectedBtn.selected = NO;
            }
        }else {
            _lampSelectedImageView.image = [UIImage imageNamed:@"To_select"];
            _fanSelectedImageView.image = [UIImage imageNamed:@"To_select"];
            _lampSelectedBtn.selected = NO;
            _fanSelectedBtn.selected = NO;
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

- (IBAction)channelSelectBtn:(UIButton *)sender {
    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance]getDeviceModelByDeviceId:_deviceId];
    if ((deviceModel.channel1Selected && !deviceModel.channel2Selected && sender.tag == 1) || (!deviceModel.channel1Selected && deviceModel.channel2Selected && sender.tag == 2)) {
        return;
    }
    sender.selected = !sender.selected;
    UIImage *image = sender.selected? [UIImage imageNamed:@"Be_selected"]:[UIImage imageNamed:@"To_select"];
    switch (sender.tag) {
        case 1:
            _lampSelectedImageView.image = image;
            deviceModel.channel1Selected = sender.selected;
            if (_buttonNum) {
                NSNumber *obj = [deviceModel.buttonnumAndChannel objectForKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                
                if (sender.selected) {
                    if (obj && [obj isEqualToNumber:@2]) {
                        [deviceModel addValue:@4 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }else {
                        [deviceModel addValue:@3 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }
                }else {
                    if (obj && [obj isEqualToNumber:@4]) {
                        [deviceModel addValue:@2 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }
                }
            }
            break;
        case 2:
            _fanSelectedImageView.image = image;
            deviceModel.channel2Selected = sender.selected;
            if (_buttonNum) {
                NSNumber *obj = [deviceModel.buttonnumAndChannel objectForKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                
                if (sender.selected) {
                    if (obj && [obj isEqualToNumber:@3]) {
                        [deviceModel addValue:@4 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }else {
                        [deviceModel addValue:@2 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }
                }else {
                    if (obj && [obj isEqualToNumber:@4]) {
                        [deviceModel addValue:@3 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }
                }
            }
            break;
        default:
            break;
    }
}


@end
