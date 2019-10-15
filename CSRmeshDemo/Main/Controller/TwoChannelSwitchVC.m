//
//  TwoChannelSwitchVC.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/10/11.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "TwoChannelSwitchVC.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import "DeviceModelManager.h"
#import "AFHTTPSessionManager.h"
#import "PureLayout.h"
#import "DataModelManager.h"
#import <MBProgressHUD.h>
#import "MCUUpdateTool.h"

@interface TwoChannelSwitchVC ()<UITextFieldDelegate,MBProgressHUDDelegate,MCUUpdateToolDelegate>
{
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
    UIButton *updateMCUBtn;
}

@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (nonatomic,copy) NSString *originalName;
@property (weak, nonatomic) IBOutlet UISwitch *channel1Switch;
@property (weak, nonatomic) IBOutlet UISwitch *channel2Switch;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *left1Constaint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *left2Constaint;
@property (weak, nonatomic) IBOutlet UIImageView *channelSelected1ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *channelSelected2ImageView;
@property (weak, nonatomic) IBOutlet UIButton *channelSelected1Btn;
@property (weak, nonatomic) IBOutlet UIButton *channelSelected2Btn;
@property (nonatomic,strong) MBProgressHUD *updatingHud;
@property (nonatomic,strong) UIView *translucentBgView;

@end

@implementation TwoChannelSwitchVC

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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setMultichannelStateSuccess:)
                                                 name:@"setMultichannelStateSuccess"
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
    
    if ([_remoteBrach length]>=8) {
        NSString *str1 = [_remoteBrach substringWithRange:NSMakeRange(4, 2)];
        NSString *str2 = [_remoteBrach substringWithRange:NSMakeRange(6, 2)];
        NSString *str = [NSString stringWithFormat:@"%@%@",str2,str1];
        NSNumber *remoteDeviceId = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:str]];
        if ([remoteDeviceId isEqualToNumber:_deviceId]) {
            DeviceModel *deviceModel = [[DeviceModelManager sharedInstance]getDeviceModelByDeviceId:_deviceId];
            if (deviceModel && _buttonNum) {
                NSString *remoteChannel = [_remoteBrach substringWithRange:NSMakeRange(0, 4)];
                if ([remoteChannel isEqualToString:@"0100"]) {
                    [deviceModel addValue:@1 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                }else if ([remoteChannel isEqualToString:@"0200"]) {
                    [deviceModel addValue:@2 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                }else if ([remoteChannel isEqualToString:@"0300"]) {
                    [deviceModel addValue:@3 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                }
            }
        }
    }
    [self changeUI:_deviceId];
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
    [[DataModelManager shareInstance] sendCmdData:cmdString toDeviceId:_deviceId];
}

- (void)setMultichannelStateSuccess: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSInteger channel = [userInfo[@"channel"] integerValue];
    if ([deviceId isEqualToNumber:_deviceId]) {
        [self changeUI:deviceId channel:channel];
    }
}

- (void)changeUI:(NSNumber *)deviceId channel:(NSInteger)channel{
    
    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance]getDeviceModelByDeviceId:deviceId];
    if (deviceModel) {
        if (channel == 1) {
            [_channel1Switch setOn:deviceModel.channel1PowerState];
        }else if (channel == 2) {
            [_channel2Switch setOn:deviceModel.channel2PowerState];
        }
        if (_forSelected) {
            if (_buttonNum) {
                NSNumber *obj = [deviceModel.buttonnumAndChannel objectForKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                if (obj) {
                    if ([obj isEqualToNumber:@1]) {
                        _channelSelected1ImageView.image = [UIImage imageNamed:@"Be_selected"];
                        _channelSelected2ImageView.image = [UIImage imageNamed:@"Be_selected"];
                    }else if ([obj isEqualToNumber:@2]) {
                        _channelSelected1ImageView.image = [UIImage imageNamed:@"Be_selected"];
                        _channelSelected2ImageView.image = [UIImage imageNamed:@"To_select"];
                    }else if ([obj isEqualToNumber:@3]) {
                        _channelSelected1ImageView.image = [UIImage imageNamed:@"To_select"];
                        _channelSelected2ImageView.image = [UIImage imageNamed:@"Be_selected"];
                    }else {
                        _channelSelected1ImageView.image = [UIImage imageNamed:@"To_select"];
                        _channelSelected2ImageView.image = [UIImage imageNamed:@"To_select"];
                    }
                }
            }
        }
    }
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
        if (_forSelected) {
            if (_buttonNum) {
                NSNumber *obj = [deviceModel.buttonnumAndChannel objectForKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                if (obj) {
                    if ([obj isEqualToNumber:@1]) {
                        _channelSelected1ImageView.image = [UIImage imageNamed:@"Be_selected"];
                        _channelSelected1Btn.selected = YES;
                        _channelSelected2ImageView.image = [UIImage imageNamed:@"Be_selected"];
                        _channelSelected2Btn.selected = YES;
                    }else if ([obj isEqualToNumber:@2]) {
                        _channelSelected1ImageView.image = [UIImage imageNamed:@"Be_selected"];
                        _channelSelected1Btn.selected = YES;
                        _channelSelected2ImageView.image = [UIImage imageNamed:@"To_select"];
                        _channelSelected2Btn.selected = NO;
                    }else if ([obj isEqualToNumber:@3]) {
                        _channelSelected1ImageView.image = [UIImage imageNamed:@"To_select"];
                        _channelSelected1Btn.selected = NO;
                        _channelSelected2ImageView.image = [UIImage imageNamed:@"Be_selected"];
                        _channelSelected2Btn.selected = YES;
                    }else {
                        _channelSelected1ImageView.image = [UIImage imageNamed:@"To_select"];
                        _channelSelected1Btn.selected = NO;
                        _channelSelected2ImageView.image = [UIImage imageNamed:@"To_select"];
                        _channelSelected2Btn.selected = NO;
                    }
                }
            }
        }
    }
}

- (IBAction)channelSeleteBtn:(UIButton *)sender {
    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance]getDeviceModelByDeviceId:_deviceId];

    sender.selected = !sender.selected;
    UIImage *image = sender.selected? [UIImage imageNamed:@"Be_selected"]:[UIImage imageNamed:@"To_select"];
    
    switch (sender.tag) {
        case 1:
            _channelSelected1ImageView.image = image;
            deviceModel.channel1Selected = sender.selected;
            if (_buttonNum) {
                NSNumber *obj = [deviceModel.buttonnumAndChannel objectForKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                if (sender.selected) {
                    if (obj && [obj isEqualToNumber:@3]) {
                        [deviceModel addValue:@1 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }else {
                        [deviceModel addValue:@2 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }
                }else {
                    if (obj && [obj isEqualToNumber:@1]) {
                        [deviceModel addValue:@3 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }else {
                        [deviceModel.buttonnumAndChannel removeObjectForKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }
                }
            }
            break;
        case 2:
            _channelSelected2ImageView.image = image;
            deviceModel.channel2Selected = sender.selected;
            if (_buttonNum) {
                NSNumber *obj = [deviceModel.buttonnumAndChannel objectForKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                if (sender.selected) {
                    if (obj && [obj isEqualToNumber:@2]) {
                        [deviceModel addValue:@1 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }else {
                        [deviceModel addValue:@3 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }
                }else {
                    if (obj && [obj isEqualToNumber:@1]) {
                        [deviceModel addValue:@2 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }else {
                        [deviceModel.buttonnumAndChannel removeObjectForKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }
                }
            }
            break;
        default:
            break;
    }
}

@end
