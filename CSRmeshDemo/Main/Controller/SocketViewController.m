//
//  SocketViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/12/29.
//  Copyright © 2018 Cambridge Silicon Radio Ltd. All rights reserved.
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
#import "MCUUpdateTool.h"

@interface SocketViewController ()<UITextFieldDelegate,MBProgressHUDDelegate,MCUUpdateToolDelegate>
{
    NSTimer *timer;
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
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

@end

@implementation SocketViewController

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
                NSLog(@"%@",dic);
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

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ((522 - self.scrollView.bounds.size.height + 44)/2>0) {
        self.constantH.constant = (522 - self.scrollView.bounds.size.height + 44)/2;
    }
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(socketPowerCall:)
                                                 name:@"socketPowerCall"
                                               object:nil];
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
    NSString *cmdString;
    switch (sender.tag) {
        case 1:
            cmdString = [NSString stringWithFormat:@"51050100010%d%@",sender.on,[CSRUtilities stringWithHexNumber:sender.on*255]];
            break;
        case 2:
            cmdString = [NSString stringWithFormat:@"51050200010%d%@",sender.on,[CSRUtilities stringWithHexNumber:sender.on*255]];
            break;
        default:
            break;
    }
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
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
        if (deviceModel.channel1PowerState && !deviceModel.childrenState1) {
            [_childSwitch1 setEnabled:NO];
            _child1Btn.hidden = NO;
        }else {
            [_childSwitch1 setEnabled:YES];
            _child1Btn.hidden = YES;
        }
        
        [_channel2Switch setOn:deviceModel.channel2PowerState];
        if (deviceModel.channel2PowerState && !deviceModel.childrenState2) {
            [_childSwitch2 setEnabled:NO];
            _child2Btn.hidden = NO;
        }else {
            [_childSwitch2 setEnabled:YES];
            _child2Btn.hidden = YES;
        }
        
        [_childSwitch1 setOn:deviceModel.childrenState1];
        if (deviceModel.childrenState1) {
            [_channel1Switch setEnabled:NO];
            _socket1Btn.hidden = NO;
        }else {
            [_channel1Switch setEnabled:YES];
            _socket1Btn.hidden = YES;
        }
        
        [_childSwitch2 setOn:deviceModel.childrenState2];
        if (deviceModel.childrenState2) {
            [_channel2Switch setEnabled:NO];
            _socket2Btn.hidden = NO;
        }else {
            [_channel2Switch setEnabled:YES];
            _socket2Btn.hidden = YES;
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
    __block SocketViewController *weakself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakself changeUI:_deviceId];
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
    [self presentViewController:nav animated:NO completion:nil];
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

@end
