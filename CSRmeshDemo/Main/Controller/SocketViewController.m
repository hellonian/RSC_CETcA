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
#import "DataModelManager.h"

@interface SocketViewController ()<UITextFieldDelegate,MBProgressHUDDelegate>
{
    NSTimer *timer;
    
    NSInteger nowBinPage;
    dispatch_semaphore_t semaphore;
    NSMutableDictionary *updateEveDataDic;
    NSMutableDictionary *updateSuccessDic;
    BOOL isLastPage;
    NSInteger resendQueryNumber;
    NSInteger pageNum;
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
}

@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (nonatomic,copy) NSString *originalName;
@property (weak, nonatomic) IBOutlet UISwitch *channel1Switch;
@property (weak, nonatomic) IBOutlet UISwitch *channel2Switch;
@property (weak, nonatomic) IBOutlet UISwitch *childSwitch;
@property (weak, nonatomic) IBOutlet UILabel *currentPower1Label;
@property (weak, nonatomic) IBOutlet UILabel *currentPower2Label;
@property (nonatomic,strong) MBProgressHUD *updatingHud;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constantH;

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
        
        if ([CSRUtilities belongToMCUDevice:curtainEntity.shortName]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MCUUpdateDataCall:) name:@"MCUUpdateDataCall" object:nil];
            NSMutableString *mutStr = [NSMutableString stringWithString:curtainEntity.shortName];
            NSRange range = {0,curtainEntity.shortName.length};
            [mutStr replaceOccurrencesOfString:@"/" withString:@"" options:NSLiteralSearch range:range];
            NSString *urlString = [NSString stringWithFormat:@"http://39.108.152.134/MCU/%@/%@.php",mutStr,mutStr];
            NSLog(@"urlString>> %@",urlString);
            AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
            sessionManager.responseSerializer.acceptableContentTypes = nil;
            [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                NSDictionary *dic = (NSDictionary *)responseObject;
                NSLog(@"%@",dic);
                latestMCUSVersion = [dic[@"mcu_software_version"] integerValue];
                downloadAddress = dic[@"Download_address"];
                NSLog(@">> %@  %ld  %ld",downloadAddress,[curtainEntity.mcuSVersion integerValue],latestMCUSVersion);
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
    [[DataModelManager shareInstance] sendCmdData:@"ea30" toDeviceId:_deviceId];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[DataModelManager shareInstance] sendCmdData:@"ea30" toDeviceId:_deviceId];
//    });
}
-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ((477 - self.view.bounds.size.height + 44)>0) {
        self.constantH.constant = (477 - self.view.bounds.size.height + 44);
    }
}

- (void)MCUUpdateDataCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *mucDeviceId = dic[@"deviceId"];
    NSString *mcuString = dic[@"MCUUpdateDataCall"];
    if ([mucDeviceId isEqualToNumber:_deviceId]) {
        if ([mcuString hasPrefix:@"30"]) {
            if ([[mcuString substringWithRange:NSMakeRange(2, 2)] boolValue]) {
                if (!_updatingHud) {
                    _updatingHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    _updatingHud.mode = MBProgressHUDModeAnnularDeterminate;
                    _updatingHud.delegate = self;
                    [self downloadPin];
                    [self startMCUUpdate:nil];
                }
            }
        }else if ([mcuString hasPrefix:@"33"]) {
            NSInteger backBinPage = [CSRUtilities numberWithHexString:[mcuString substringWithRange:NSMakeRange(2, 2)]];
            if (backBinPage == nowBinPage) {
                NSInteger count = [[updateEveDataDic objectForKey:@(backBinPage)] count];
                NSString *countBinString = @"";
                for (int i=0; i<count; i++) {
                    countBinString = [NSString stringWithFormat:@"%@1",countBinString];
                }
                
                NSString *str0 = [mcuString substringWithRange:NSMakeRange(4, 2)];
                NSString *str1 = [mcuString substringWithRange:NSMakeRange(6, 2)];
                NSString *str2 = [mcuString substringWithRange:NSMakeRange(8, 2)];
                NSString *resultHexStr = [NSString stringWithFormat:@"%@%@%@",str2,str1,str0];
                NSString *resultBinStr = [[CSRUtilities getBinaryByhex:resultHexStr] substringWithRange:NSMakeRange(24-count, count)];
                
                NSLog(@"%@  %@  %@",mcuString,resultHexStr,resultBinStr);
                if ([countBinString isEqualToString:resultBinStr]) {
                    dispatch_semaphore_signal(semaphore);
                    [updateSuccessDic setObject:@(![[updateSuccessDic objectForKey:@(backBinPage)] boolValue]) forKey:@(backBinPage)];
                    if (isLastPage) {
                        NSLog(@"最后一页成功");
                        [[DataModelManager shareInstance] sendCmdData:@"ea32" toDeviceId:_deviceId];
                    }
                    _updatingHud.progress = (backBinPage+1)/(CGFloat)pageNum;
                }else {
                    
                    for (NSInteger i=0; i<[resultBinStr length]; i++) {
                        NSString *resultStr = [resultBinStr substringWithRange:NSMakeRange([resultBinStr length]-1-i, 1)];
                        NSLog(@"%@",resultStr);
                        if (![resultStr boolValue]) {
                            NSString *binResendString = [[updateEveDataDic objectForKey:@(backBinPage)] objectAtIndex:i];
                            [[DataModelManager shareInstance] sendCmdData:binResendString toDeviceId:_deviceId];
                            [NSThread sleepForTimeInterval:0.1];
                        }
                    }
                    
                    resendQueryNumber = 0;
                    [self resendData:backBinPage];
                    
                }
            }
        }else if ([mcuString hasPrefix:@"32"]) {
            if (_updatingHud) {
                [_updatingHud hideAnimated:YES];
            }
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
            deviceEntity.mcuSVersion = [NSNumber numberWithInteger:latestMCUSVersion];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
    }
}

- (void)downloadPin {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadAddress]];
    NSString *fileName = [downloadAddress lastPathComponent];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSProgress *progress = nil;
    __block SocketViewController *weakSelf = self;
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:&progress destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {

        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@",fileName]];
        NSLog(@"downloadTaskWithRequest>> %@",path);
        return [NSURL fileURLWithPath:path];

    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
    
        [weakSelf startMCUUpdate:filePath];
    
    }];
    [task resume];
}

- (void)startMCUUpdate:(NSURL *)path {
//        NSString *path1 = [[NSBundle mainBundle] pathForResource:@"P2400B-H_MCU_V10.10" ofType:@"bin"];
//        NSData *data = [[NSData alloc] initWithContentsOfFile:path1];
    
    NSData *data = [[NSData alloc] initWithContentsOfURL:path];
//    NSLog(@"data length>> %ld",[data length]);
    semaphore = dispatch_semaphore_create(1);
    updateEveDataDic = [[NSMutableDictionary alloc] init];
    updateSuccessDic = [[NSMutableDictionary alloc] init];
    isLastPage = NO;
    if (data) {
        pageNum = [data length]/128+1;
        dispatch_queue_t queue = dispatch_queue_create("串行", NULL);
        for (NSInteger binPage=0; binPage<([data length]/128+1); binPage++) {
            dispatch_async(queue, ^{
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [updateSuccessDic setObject:@(0) forKey:@(binPage)];
                    NSLog(@"xunfan %ld",binPage);
                    nowBinPage = binPage;
                    NSInteger binPageLength = 128;
                    if (binPage == [data length]/128) {
                        binPageLength = [data length]%128;
                        isLastPage = YES;
                    }
                    NSData *binPageData = [data subdataWithRange:NSMakeRange(binPage*128, binPageLength)];
                    NSMutableArray *eveDataArray = [[NSMutableArray alloc] init];
                    for (NSInteger binRow=0; binRow<([binPageData length]/6+1); binRow++) {
                        NSInteger binRowLenth = 6;
                        if (binRow == [binPageData length]/6) {
                            binRowLenth = [binPageData length]%6;
                        }
                        NSData *binRowData = [binPageData subdataWithRange:NSMakeRange(binRow*6, binRowLenth)];
                        NSString *binSendString = [NSString stringWithFormat:@"ea31%@%@%@",[CSRUtilities stringWithHexNumber:binPage],[CSRUtilities stringWithHexNumber:binRow],[CSRUtilities hexStringForData:binRowData]];
                        [eveDataArray insertObject:binSendString atIndex:binRow];
                        [[DataModelManager shareInstance] sendCmdData:binSendString toDeviceId:_deviceId];
                        [NSThread sleepForTimeInterval:0.1];
                    }
                    [updateEveDataDic setObject:eveDataArray forKey:@(binPage)];
                    
                    resendQueryNumber = 0;
                    [self resendData:binPage];
                });
            });
        }
        NSLog(@"循环结束");
    }
}

- (void)resendData:(NSInteger)binPage {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"首次延时~~ %ld | %d",binPage,[[updateSuccessDic objectForKey:@(binPage)] boolValue]);
        if (![[updateSuccessDic objectForKey:@(binPage)] boolValue] && resendQueryNumber<6) {
            resendQueryNumber++;
            [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"ea33%@",[CSRUtilities stringWithHexNumber:binPage]] toDeviceId:_deviceId];
            [self resendData:binPage];
        }
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(socketPowerCall:)
                                                 name:@"socketPowerCall"
                                               object:nil];
    timer = [NSTimer scheduledTimerWithTimeInterval:30.0f target:self selector:@selector(timerMethod:) userInfo:nil repeats:YES];
    [timer fire];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"socketPowerCall" object:nil];
    [timer invalidate];
    timer = nil;
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
        [_channel2Switch setOn:deviceModel.channel2PowerState];
        [_childSwitch setOn:deviceModel.childrenState];
    }
}

- (IBAction)childrenMode:(UISwitch *)sender {
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea410%d",sender.on]] success:nil failure:nil];
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
        NSNumber *power = dic[@"power"];
        switch ([channel integerValue]) {
            case 1:
                _currentPower1Label.text = [NSString stringWithFormat:@"%.1fW",[power floatValue]];
                break;
            case 2:
                _currentPower2Label.text = [NSString stringWithFormat:@"%.1fW",[power floatValue]];
                break;
            default:
                break;
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
