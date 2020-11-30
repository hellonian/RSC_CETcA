//
//  SocketViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/12/29.
//  Copyright © 2018 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "SocketViewController.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import <CSRmesh/DataModelApi.h>
#import "DeviceModelManager.h"
#import "PowerViewController.h"
#import <MBProgressHUD.h>
#import "AFHTTPSessionManager.h"
#import "PureLayout.h"
#import "DataModelManager.h"
#import "UpdataMCUTool.h"

@interface SocketViewController ()<UITextFieldDelegate,MBProgressHUDDelegate,UpdataMCUToolDelegate>
{
    NSTimer *timer;
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
    UIButton *updateMCUBtn;
}

@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (nonatomic,copy) NSString *originalName;
@property (weak, nonatomic) IBOutlet UISwitch *channel1Switch;
@property (weak, nonatomic) IBOutlet UISwitch *channel2Switch;
@property (weak, nonatomic) IBOutlet UISwitch *childSwitch1;
@property (weak, nonatomic) IBOutlet UISwitch *childSwitch2;
@property (weak, nonatomic) IBOutlet UILabel *currentPower1Label;
@property (weak, nonatomic) IBOutlet UILabel *currentPower2Label;
@property (nonatomic,strong) MBProgressHUD *updatingHud;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constantH;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *socket1Btn;
@property (weak, nonatomic) IBOutlet UIButton *child1Btn;
@property (weak, nonatomic) IBOutlet UIButton *socket2Btn;
@property (weak, nonatomic) IBOutlet UIButton *child2Btn;
@property (nonatomic,strong) UIView *translucentBgView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *firstChannelView;
@property (strong, nonatomic) IBOutlet UIView *secondChannelView;
@property (strong, nonatomic) IBOutlet UIButton *clearPowerDataBtn;
@property (weak, nonatomic) IBOutlet UILabel *thresholdLab1;
@property (weak, nonatomic) IBOutlet UILabel *thresholdLab2;
@property (weak, nonatomic) IBOutlet UISwitch *thresholdSwitch1;
@property (weak, nonatomic) IBOutlet UISwitch *thresholdSwitch2;
@property (weak, nonatomic) IBOutlet UIImageView *abnormalImageView1;
@property (weak, nonatomic) IBOutlet UIImageView *abnormalImageView2;
@property (nonatomic, strong) UIAlertController *mcuAlert;

@end

@implementation SocketViewController

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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setPowerStateSuccess:)
                                                 name:@"setPowerStateSuccess"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearSocketPower:)
                                                 name:@"clearSocketPower"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(socketPowerAbnormalReport:)
                                                 name:@"socketPowerAbnormalReport"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(socketPowerThreshold:)
                                                 name:@"socketPowerThreshold"
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
        
        if ([CSRUtilities belongToSocketTwoChannel:curtainEntity.shortName]) {
            [_contentView addSubview:_secondChannelView];
            [_secondChannelView autoSetDimension:ALDimensionHeight toSize:339.0];
            [_secondChannelView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_firstChannelView withOffset:10.0];
            [_secondChannelView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
            [_secondChannelView autoPinEdgeToSuperviewEdge:ALEdgeRight];
            
            [_contentView addSubview:_clearPowerDataBtn];
            [_clearPowerDataBtn autoSetDimension:ALDimensionHeight toSize:44.0];
            [_clearPowerDataBtn autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_secondChannelView withOffset:20.0];
            [_clearPowerDataBtn autoPinEdgeToSuperviewEdge:ALEdgeLeft];
            [_clearPowerDataBtn autoPinEdgeToSuperviewEdge:ALEdgeRight];
            
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"ea4803"] success:nil failure:nil];
            
        }else if ([CSRUtilities belongToSocketOneChannel:curtainEntity.shortName]) {
            [_contentView addSubview:_clearPowerDataBtn];
            [_clearPowerDataBtn autoSetDimension:ALDimensionHeight toSize:44.0];
            [_clearPowerDataBtn autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_firstChannelView withOffset:20.0];
            [_clearPowerDataBtn autoPinEdgeToSuperviewEdge:ALEdgeLeft];
            [_clearPowerDataBtn autoPinEdgeToSuperviewEdge:ALEdgeRight];
            
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"ea4801"] success:nil failure:nil];
        }
        
        [self changeUI:_deviceId channel:1];
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
                if ([curtainEntity.mcuSVersion integerValue] != 0 && [curtainEntity.mcuSVersion integerValue]<latestMCUSVersion) {
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
    [UpdataMCUTool sharedInstace].toolDelegate = self;
    [[UpdataMCUTool sharedInstace] askUpdateMCU:_deviceId downloadAddress:downloadAddress latestMCUSVersion:latestMCUSVersion];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if ([CSRUtilities belongToSocketOneChannel:deviceEntity.shortName]) {
        if ((548 - self.scrollView.bounds.size.height)/2>0) {
            self.constantH.constant = (548 - self.scrollView.bounds.size.height)/2;
        }
    }else if ([CSRUtilities belongToSocketTwoChannel:deviceEntity.shortName]) {
        if ((897 - self.scrollView.bounds.size.height)/2>0) {
            self.constantH.constant = (897 - self.scrollView.bounds.size.height)/2;
        }
    }
}

- (void)starteUpdateHud {
    if (!_updatingHud) {
        [timer invalidate];
        timer = nil;
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

- (void)updateSuccess:(NSString *)value {
    if (_updatingHud) {
        [_updatingHud hideAnimated:YES];
        [self.translucentBgView removeFromSuperview];
        self.translucentBgView = nil;
        [updateMCUBtn removeFromSuperview];
        updateMCUBtn = nil;
        if (!_mcuAlert) {
            _mcuAlert = [UIAlertController alertControllerWithTitle:nil message:value preferredStyle:UIAlertControllerStyleAlert];
            [_mcuAlert.view setTintColor:DARKORAGE];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
            [_mcuAlert addAction:cancel];
            [self presentViewController:_mcuAlert animated:YES completion:nil];
        }else {
            [_mcuAlert setMessage:value];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(socketPowerCall:)
                                                 name:@"socketPowerCall"
                                               object:nil];
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"ea42"] success:nil failure:nil];
    timer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(timerMethod:) userInfo:nil repeats:YES];
    [timer fire];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"socketPowerCall" object:nil];
    [timer invalidate];
    timer = nil;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)timerMethod:(NSTimer *)timer {
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"ea4403"] success:nil failure:nil];
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

- (IBAction)turnOnOFF:(UISwitch *)sender {
    if (sender.tag == 1) {
        [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId channel:@2 withPowerState:sender.on];
    }else if (sender.tag == 2) {
        [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId channel:@3 withPowerState:sender.on];
    }
}

- (void)setPowerStateSuccess:(NSNotification *)notification {
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
        
        if (channel == 2) {
            
            [_channel1Switch setOn:deviceModel.channel1PowerState];
            [_childSwitch1 setOn:deviceModel.childrenState1];
            if (deviceModel.channel1PowerState && !deviceModel.childrenState1) {
                [_channel1Switch setEnabled:YES];
                [_socket1Btn setHidden:YES];
                [_childSwitch1 setEnabled:NO];
                [_child1Btn setHidden:NO];
            }else if (!deviceModel.channel1PowerState && deviceModel.childrenState1) {
                [_channel1Switch setEnabled:NO];
                [_socket1Btn setHidden:NO];
                [_childSwitch1 setEnabled:YES];
                [_child1Btn setHidden:YES];
            }else {
                [_channel1Switch setEnabled:YES];
                [_socket1Btn setHidden:YES];
                [_childSwitch1 setEnabled:YES];
                [_child1Btn setHidden:YES];
            }
            
        }else if (channel == 3) {
            
            [_channel2Switch setOn:deviceModel.channel2PowerState];
            [_childSwitch2 setOn:deviceModel.childrenState2];
            if (deviceModel.channel2PowerState && !deviceModel.childrenState2) {
                [_channel2Switch setEnabled:YES];
                [_socket2Btn setHidden:YES];
                [_childSwitch2 setEnabled:NO];
                [_child2Btn setHidden:NO];
            }else if (!deviceModel.channel2PowerState && deviceModel.childrenState2) {
                [_channel2Switch setEnabled:NO];
                [_socket2Btn setHidden:NO];
                [_childSwitch2 setEnabled:YES];
                [_child2Btn setHidden:YES];
            }else {
                [_channel2Switch setEnabled:YES];
                [_socket2Btn setHidden:YES];
                [_childSwitch2 setEnabled:YES];
                [_child2Btn setHidden:YES];
            }
            
        }else if (channel == 1 || channel == 4) {
            [_channel1Switch setOn:deviceModel.channel1PowerState];
            [_childSwitch1 setOn:deviceModel.childrenState1];
            if (deviceModel.channel1PowerState && !deviceModel.childrenState1) {
                [_channel1Switch setEnabled:YES];
                [_socket1Btn setHidden:YES];
                [_childSwitch1 setEnabled:NO];
                [_child1Btn setHidden:NO];
            }else if (!deviceModel.channel1PowerState && deviceModel.childrenState1) {
                [_channel1Switch setEnabled:NO];
                [_socket1Btn setHidden:NO];
                [_childSwitch1 setEnabled:YES];
                [_child1Btn setHidden:YES];
            }else {
                [_channel1Switch setEnabled:YES];
                [_socket1Btn setHidden:YES];
                [_childSwitch1 setEnabled:YES];
                [_child1Btn setHidden:YES];
            }
            [_channel2Switch setOn:deviceModel.channel2PowerState];
            [_childSwitch2 setOn:deviceModel.childrenState2];
            if (deviceModel.channel2PowerState && !deviceModel.childrenState2) {
                [_channel2Switch setEnabled:YES];
                [_socket2Btn setHidden:YES];
                [_childSwitch2 setEnabled:NO];
                [_child2Btn setHidden:NO];
            }else if (!deviceModel.channel2PowerState && deviceModel.childrenState2) {
                [_channel2Switch setEnabled:NO];
                [_socket2Btn setHidden:NO];
                [_childSwitch2 setEnabled:YES];
                [_child2Btn setHidden:YES];
            }else {
                [_channel2Switch setEnabled:YES];
                [_socket2Btn setHidden:YES];
                [_childSwitch2 setEnabled:YES];
                [_child2Btn setHidden:YES];
            }
        }
    }
}

- (IBAction)closeChildrenModeAlert:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:AcTECLocalizedStringFromTable(@"closeChildrenModeAlert", @"Localizable") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}
- (IBAction)closeSocketStateAlert:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:AcTECLocalizedStringFromTable(@"closeSocketStateAlert", @"Localizable") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)childrenMode:(UISwitch *)sender {
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea410%ld0%d",(long)sender.tag,sender.on]] success:nil failure:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self changeUI:_deviceId channel:sender.tag];
    });
}

- (void)socketPowerCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        NSNumber *channel = dic[@"channel"];
        NSNumber *power1 = dic[@"power1"];
        NSNumber *power2 = dic[@"power2"];
        if ([channel integerValue]==3) {
            _currentPower1Label.text = [NSString stringWithFormat:@"%.1fW",[power1 floatValue]];
            _currentPower2Label.text = [NSString stringWithFormat:@"%.1fW",[power2 floatValue]];
        }
    }
}

- (IBAction)getPowerBtn:(UIButton *)sender {
    PowerViewController *pvc = [[PowerViewController alloc] init];
    pvc.channel = sender.tag/10;
    pvc.deviceId = _deviceId;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:pvc];
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromRight];
    [self.view.window.layer addAnimation:animation forKey:nil];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:NO completion:nil];
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

- (IBAction)clearAction:(UIButton *)sender {
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if ([CSRUtilities belongToSocketOneChannel:deviceEntity.shortName]) {
        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"ea4601"] success:nil failure:nil];
    }else if ([CSRUtilities belongToSocketTwoChannel:deviceEntity.shortName]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"清除第1路电量数据" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"ea4601"] success:nil failure:nil];
        }];
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"清除第2路电量数据" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"ea4602"] success:nil failure:nil];
        }];
        UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"清除两路电量数据" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"ea4603"] success:nil failure:nil];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:action1];
        [alert addAction:action2];
        [alert addAction:action3];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)clearSocketPower:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        NSString *channel = dic[@"channel"];
        BOOL state = [dic[@"state"] boolValue];
        NSString *stateStr = state? @"成功":@"失败";
        NSString *channelStr = [channel isEqualToString:@"01"]? @"第1路":([channel isEqualToString:@"02"]? @"第2路":@"两路");
        [self showTextHud:[NSString stringWithFormat:@"%@电量数据清除%@",channelStr,stateStr]];
    }
}

- (void)showTextHud:(NSString *)text {
    MBProgressHUD *successHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    successHud.mode = MBProgressHUDModeText;
    successHud.label.text = text;
    successHud.label.numberOfLines = 0;
    successHud.delegate = self;
    [successHud hideAnimated:YES afterDelay:4.0f];
}

- (void)socketPowerAbnormalReport:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        NSString *channel = dic[@"channel"];
//        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//        formatter.dateFormat = @"MM-dd HH:mm:ss";
//        NSString *dateStr = [formatter stringFromDate:[NSDate date]];
        if ([channel isEqualToString:@"01"]) {
//            _abnormalLab1.text = [NSString stringWithFormat:@"%@\nError_code:%@",dateStr,dic[@"state"]];
            _abnormalImageView1.image = [UIImage imageNamed:@"abnormal"];
        }else if ([channel isEqualToString:@"02"]) {
//            _abnormalLab2.text = [NSString stringWithFormat:@"%@\nError_code:%@",dateStr,dic[@"state"]];
            _abnormalImageView2.image = [UIImage imageNamed:@"abnormal"];
        }
    }
}

- (void)socketPowerThreshold:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        NSString *channel = dic[@"channel"];
        NSString *dataStr = dic[@"socketPowerThreshold"];
        if ([channel isEqualToString:@"01"] && [dataStr length]>=4) {
            BOOL enable = [[dataStr substringWithRange:NSMakeRange(0, 2)] boolValue];
            NSInteger pvalue = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(2, 2)]];
            [_thresholdSwitch1 setOn:enable];
            _thresholdLab1.text = [NSString stringWithFormat:@"%ld",(long)pvalue];
        }else if ([channel isEqualToString:@"02"] && [dataStr length]>=4) {
            BOOL enable = [[dataStr substringWithRange:NSMakeRange(0, 2)] boolValue];
            NSInteger pvalue = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(2, 2)]];
            [_thresholdSwitch2 setOn:enable];
            _thresholdLab2.text = [NSString stringWithFormat:@"%ld",(long)pvalue];
        }else if ([channel isEqualToString:@"03"] && [dataStr length]>=8) {
            BOOL enable1 = [[dataStr substringWithRange:NSMakeRange(0, 2)] boolValue];
            NSInteger pvalue1 = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(2, 2)]];
            BOOL enable2 = [[dataStr substringWithRange:NSMakeRange(4, 2)] boolValue];
            NSInteger pvalue2 = [CSRUtilities numberWithHexString:[dataStr substringWithRange:NSMakeRange(6, 2)]];
            [_thresholdSwitch1 setOn:enable1];
            _thresholdLab1.text = [NSString stringWithFormat:@"%ld",(long)pvalue1];
            [_thresholdSwitch2 setOn:enable2];
            _thresholdLab2.text = [NSString stringWithFormat:@"%ld",(long)pvalue2];
        }
    }
}

- (IBAction)thresholdEnableSwitch:(UISwitch *)sender {
    switch (sender.tag) {
        case 1:
        if ([_thresholdLab1.text length]>0 && [_thresholdLab1.text integerValue]>=2 && [_thresholdLab1.text integerValue]<=20) {
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea47010%d%@",sender.on,[CSRUtilities stringWithHexNumber:[_thresholdLab1.text integerValue]]]] success:nil failure:nil];
        }else {
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea47010%d02",sender.on]] success:nil failure:nil];
        }
        break;
        case 2:
        if ([_thresholdLab2.text length]>0 && [_thresholdLab2.text integerValue]>=2 && [_thresholdLab2.text integerValue]<=20) {
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea47020%d%@",sender.on,[CSRUtilities stringWithHexNumber:[_thresholdLab2.text integerValue]]]] success:nil failure:nil];
        }else {
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea47020%d02",sender.on]] success:nil failure:nil];
        }
        break;
        default:
        break;
    }
}

- (IBAction)thresholdValueChangeBtn:(UIButton *)sender {
    NSString *channel = nil;
    BOOL enable = YES;
    NSString *Pvalue = @"2";
    switch (sender.tag) {
        case 11:
        channel = @"01";
        enable = _thresholdSwitch1.on;
        if ([_thresholdLab1.text length]>0) {
            if ([_thresholdLab1.text integerValue]>20){
                Pvalue = @"20";
            }else if ([_thresholdLab1.text integerValue]>2 && [_thresholdLab1.text integerValue]<=20) {
                Pvalue = [NSString stringWithFormat:@"%ld",[_thresholdLab1.text integerValue]-1];
            }
        }
        break;
        case 12:
        channel = @"01";
        enable = _thresholdSwitch1.on;
        if ([_thresholdLab1.text length]>0) {
            if ([_thresholdLab1.text integerValue]>=20) {
                Pvalue = @"20";
            }else if ([_thresholdLab1.text integerValue]>=2 && [_thresholdLab1.text integerValue]<20) {
                Pvalue = [NSString stringWithFormat:@"%ld",[_thresholdLab1.text integerValue]+1];
            }
        }
        break;
        case 21:
        channel = @"02";
        enable = _thresholdSwitch2.on;
        if ([_thresholdLab2.text length]>0) {
            if ([_thresholdLab2.text integerValue]>20) {
                Pvalue = @"20";
            }else if ([_thresholdLab2.text integerValue]>2 && [_thresholdLab2.text integerValue]<=20) {
                Pvalue = [NSString stringWithFormat:@"%ld",[_thresholdLab2.text integerValue]-1];
            }
        }
        break;
        case 22:
        channel = @"02";
        enable = _thresholdSwitch2.on;
        if ([_thresholdLab2.text length]>0) {
            if ([_thresholdLab2.text integerValue]>=20) {
                Pvalue = @"20";
            }else if ([_thresholdLab2.text integerValue]>=2 && [_thresholdLab2.text integerValue]<20) {
                Pvalue = [NSString stringWithFormat:@"%ld",[_thresholdLab2.text integerValue]+1];
            }
        }
        break;
        default:
        break;
    }
    if (channel) {
        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea47%@0%d%@",channel,enable,[CSRUtilities stringWithHexNumber:[Pvalue integerValue]]]] success:nil failure:nil];
    }
}

@end
