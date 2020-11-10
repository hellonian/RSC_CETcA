//
//  MusicControllerVC.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/8/14.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "MusicControllerVC.h"
#import "MCPickerAlertController.h"
#import "CSRDatabaseManager.h"
#import "DataModelManager.h"
#import "DeviceModelManager.h"
#import "CSRUtilities.h"
#import "PureLayout.h"
#import "RippleAnimationView.h"
#import "AFHTTPSessionManager.h"
#import "MCUUpdateTool.h"
#import <MBProgressHUD.h>
#import "CSRConstants.h"

@interface MusicControllerVC ()<MCUUpdateToolDelegate, MBProgressHUDDelegate>
{
    NSInteger cycle;
    NSInteger source;
    BOOL mute;
    BOOL play;
    NSInteger voice;
    BOOL channelState;
    BOOL groupCancel;
    dispatch_semaphore_t semaphore;
    
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
    BOOL musicBehavior;
    UIButton *updateMCUBtn;
    
    BOOL voicecing;
}
@property (weak, nonatomic) IBOutlet UIButton *cycleBtn;
@property (weak, nonatomic) IBOutlet UIButton *channelBtn;
@property (weak, nonatomic) IBOutlet UIButton *sourceBtn;
@property (weak, nonatomic) IBOutlet UIImageView *cover;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *muteBtn;
@property (weak, nonatomic) IBOutlet UISlider *voiceSlider;
@property (weak, nonatomic) IBOutlet UILabel *songNameLabel;
@property (nonatomic,strong) UIView *translucentBgView;
@property (nonatomic,strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) RippleAnimationView *ripple;
@property (nonatomic,strong) MBProgressHUD *updatingHud;
@property (nonatomic,copy) NSString *originalName;
@property (nonatomic, strong) UIButton *titleBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cycleBtnAxisVerticalConstraint;

@end

@implementation MusicControllerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _cycleBtn.layer.borderColor = [UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1].CGColor;
    _channelBtn.layer.borderColor = [UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1].CGColor;
    _sourceBtn.layer.borderColor = [UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1].CGColor;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMCChannelState:) name:@"refreshMCChannelState" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMCSongName:) name:@"refreshMCSongName" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setPowerStateSuccess:) name:@"setPowerStateSuccess"
      object:nil];
    
    semaphore = dispatch_semaphore_create(0);
    
    if (_deviceId) {
        
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        if (device) {
            if ([CSRUtilities belongToMusicController:device.shortName]) {
                UIBarButtonItem *channelStateItem = [[UIBarButtonItem alloc] initWithTitle:@"OFF" style:UIBarButtonItemStylePlain target:self action:@selector(channelState:)];
                self.navigationItem.rightBarButtonItem = channelStateItem;
                UIButton *btn = [[UIButton alloc] init];
                [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
                [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
                [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
                [btn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
                UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
                self.navigationItem.leftBarButtonItem = back;
                
                UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(refresh:)];
                [_cover addGestureRecognizer:gesture];
                
                _titleBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                [_titleBtn addTarget:self action:@selector(rename) forControlEvents:UIControlEventTouchUpInside];
                [_titleBtn setTitleColor:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] forState:UIControlStateNormal];
                [_titleBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
                [_titleBtn sizeToFit];
                self.navigationItem.titleView = _titleBtn;
                
                [_titleBtn setTitle:device.name forState:UIControlStateNormal];
                
                DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
                if (model) {
                    if (model.mcLiveChannels != 0 && model.mcCurrentChannel != -1 && model.mcStatus != -1 && model.mcVoice != -1) {
                        
                        [self refreshDisplay:model];
                        _songNameLabel.text = model.songName;
                        
                    }else {
                        //扫描在线通道
                        [self showLoading];
                        [self performSelector:@selector(scanOnlineChannelTimeOut) withObject:nil afterDelay:10];
                        Byte byte[] = {0xea, 0x82, 0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
                        
                        dispatch_group_t group = dispatch_group_create();
                        dispatch_group_async(group, dispatch_queue_create("com.actec.music", DISPATCH_QUEUE_CONCURRENT), ^{
                            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (!groupCancel) {
                                    NSString *hex = [CSRUtilities stringWithHexNumber:model.mcCurrentChannel];
                                    NSString *bin = [CSRUtilities getBinaryByhex:hex];
                                    for (int i = 0; i < [bin length]; i ++) {
                                        NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
                                        if ([bit boolValue]) {
                                            Byte byte[] = {0xea, 0x81, i, 0x00, 0x00};
                                            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
                                            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                                            break;
                                        }
                                    }
                                }
                            });
                        });
                        
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        
                    }
                }
                
                if ([device.hwVersion integerValue] == 2) {
                    NSMutableString *mutStr = [NSMutableString stringWithString:device.shortName];
                    NSRange range = {0,device.shortName.length};
                    [mutStr replaceOccurrencesOfString:@"/" withString:@"" options:NSLiteralSearch range:range];
                    NSString *urlString = [NSString stringWithFormat:@"http://39.108.152.134/MCU/%@/%@.php",mutStr,mutStr];
                    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
                    sessionManager.responseSerializer.acceptableContentTypes = nil;
                    sessionManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
                    [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                        NSDictionary *dic = (NSDictionary *)responseObject;
                        latestMCUSVersion = [dic[@"mcu_software_version"] integerValue];
                        downloadAddress = dic[@"Download_address"];
                        if ([device.mcuSVersion integerValue] != 0 && [device.mcuSVersion integerValue]<latestMCUSVersion) {
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
                
            }else if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
                _channelBtn.hidden = YES;
                _sourceBtn.hidden = YES;
                for (SonosEntity *so in device.sonoss) {
                    if ([so.channel integerValue] == _channel) {
                        self.navigationItem.title = so.name;
                        break;
                    }
                }
                
                [self showLoading];
                [self performSelector:@selector(scanOnlineChannelTimeOut) withObject:nil afterDelay:10];
                dispatch_group_t group = dispatch_group_create();
                dispatch_group_async(group, dispatch_queue_create("com.actec.music", DISPATCH_QUEUE_CONCURRENT), ^{
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!groupCancel) {
                            Byte byte[] = {0xea, 0x81, _channel, 0x00, 0x00};
                            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
                            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        }
                    });
                });
                
                [[DeviceModelManager sharedInstance] refreshDeviceID:_deviceId mcCurrentChannel:pow(2, _channel)];
            }
        }
    }
    
}

- (void)viewDidLayoutSubviews {
    if (_deviceId) {
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        if (device) {
            if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
                CGFloat w = self.view.bounds.size.width/2.0;
                CGFloat cc = 1/2.0*w;
                _cycleBtnAxisVerticalConstraint.constant = cc;
            }
        }
    }
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)rename {
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if (device) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
            NSMutableAttributedString *hogan = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"Rename", @"Localizable")];
            [hogan addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1] range:NSMakeRange(0, [[hogan string] length])];
            [alert setValue:hogan forKey:@"attributedTitle"];
            [alert.view setTintColor:DARKORAGE];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
            UIAlertAction *confirm = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Save", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                UITextField *renameTextField = alert.textFields.firstObject;
                if (![CSRUtilities isStringEmpty:renameTextField.text] && ![renameTextField.text isEqualToString:_originalName]){
                    
                    [_titleBtn setTitle:renameTextField.text forState:UIControlStateNormal];
                    device.name = renameTextField.text;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    _originalName = renameTextField.text;
                    if (self.reloadDataHandle) {
                        self.reloadDataHandle();
                    }
                    
                }
            }];
            [alert addAction:cancel];
            [alert addAction:confirm];
            
            [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.text = device.name;
                self.originalName = device.name;
            }];
            
            [self presentViewController:alert animated:YES completion:nil];
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

- (IBAction)playPauseAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    _cover.highlighted = sender.selected;
    if (sender.selected) {
        [self startAnimation];
        if (!_ripple) {
            _ripple = [[RippleAnimationView alloc] initWithFrame:CGRectMake(0, 0, 137, 137) animationType:AnimationTypeWithoutBackground];
            [self.view addSubview:_ripple];
            [self.view bringSubviewToFront:_cover];
            [self.view bringSubviewToFront:_songNameLabel];
            [_ripple autoAlignAxis:ALAxisVertical toSameAxisOfView:_cover];
            [_ripple autoAlignAxis:ALAxisHorizontal toSameAxisOfView:_cover];
            [_ripple autoSetDimension:ALDimensionWidth toSize:137];
            [_ripple autoSetDimension:ALDimensionHeight toSize:137];
        }else {
            [_ripple startAnimation];
        }
    }else {
        [self stopAnimation];
        [_ripple stopAnimation];
    }
    play = sender.selected;
    
    [self sendControlCommand:1];
    
}

- (IBAction)lastAction:(UIButton *)sender {
    Byte byte[] = {0xea, 0x80, _channel, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (IBAction)nextAction:(UIButton *)sender {
    Byte byte[] = {0xea, 0x80, _channel, 0x01};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (void)sendControlCommand:(NSInteger)dv {
    NSInteger cv = pow(2, _channel);
    NSInteger cy = cycle;
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if ([CSRUtilities belongToSonosMusicController:device.shortName] && (cycle == 2 || cycle == 3)) {
        cy = cycle + 1;
    }
    NSInteger s = channelState + play*2 + source*4 + cy*32;
    NSInteger v = mute + voice*2;
    
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
    if (model) {
        model.mcStatus = s;
        model.mcVoice = v;
    }
    
    Byte byte[] = {0xb6, 0x08, 0x1e, cv/256, cv%256, pow(2, dv), s, v, 0x00, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
    [[DeviceModelManager sharedInstance] controlMC:_deviceId data:cmd];
    
}

- (void)startAnimation {
    if ([_cover.layer animationForKey:@"rotateAnimationKey"]) {
        if (_cover.layer.speed == 1) {
            return;
        }
        _cover.layer.speed = 1;
        _cover.layer.beginTime = 0;
        CFTimeInterval pauseTime = _cover.layer.timeOffset;
        _cover.layer.timeOffset = 0;
        _cover.layer.beginTime = [_cover.layer convertTime:CACurrentMediaTime() toLayer:nil] - pauseTime;
    }else {
        [self addRotateAnimation];
    }
}

- (void)addRotateAnimation {
    CABasicAnimation *rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotate.toValue = @(M_PI * 2.0);
    rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    rotate.duration = 20.0;
    rotate.autoreverses = NO;
    rotate.cumulative = NO;
    rotate.removedOnCompletion = NO;
    rotate.fillMode = kCAFillModeForwards;
    rotate.repeatCount = FLT_MAX;
    [_cover.layer addAnimation:rotate forKey:@"rotateAnimationKey"];
    [self startAnimation];
}

- (void)stopAnimation {
    if (_cover.layer.speed == 0) {
        return;
    }
    _cover.layer.timeOffset = [_cover.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    _cover.layer.speed = 0;
}

- (IBAction)muteAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    mute = sender.selected;
    [self sendControlCommand:4];
}

- (IBAction)voiceAction:(UISlider *)sender {
    voice = (NSInteger)sender.value;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(voicecingDelayMethod) object:nil];
    voicecing = YES;
    [self performSelector:@selector(voicecingDelayMethod) withObject:nil afterDelay:4];
    
    [self sendControlCommand:5];
}

- (IBAction)channelAction:(UIButton *)sender {
    
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
    if (model && model.mcLiveChannels != 0) {
        NSString *hex = [CSRUtilities stringWithHexNumber:model.mcLiveChannels];
        NSString *bin = [CSRUtilities getBinaryByhex:hex];
        NSMutableArray *mAry = [[NSMutableArray alloc] init];
        NSMutableArray *sAry = [[NSMutableArray alloc] init];
        for (int i = 0; i < [bin length]; i ++) {
            NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
            if ([bit boolValue]) {
                [mAry addObject:@(i)];
                [sAry addObject:[NSString stringWithFormat:@"%@ %d", AcTECLocalizedStringFromTable(@"channel", @"Localizable"),i]];
            }
        }
        
        MCPickerAlertController *alert = [MCPickerAlertController MCAlertControllerWithTitle:AcTECLocalizedStringFromTable(@"select_the_channel", @"Localizable") dataArray:sAry];
        [alert.pickerView selectRow:_channel inComponent:0 animated:NO];
        alert.selectedRow = _channel;
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *hex = [CSRUtilities stringWithHexNumber:model.mcCurrentChannel];
            NSString *bin = [CSRUtilities getBinaryByhex:hex];
            for (int i = 0; i < [bin length]; i ++) {
                NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
                if ([bit boolValue]) {
                    if (_channel != i) {
                        [self showLoading];
                        [self performSelector:@selector(scanOnlineChannelTimeOut) withObject:nil afterDelay:10];
                        
                        dispatch_group_t group = dispatch_group_create();
                        dispatch_group_async(group, dispatch_queue_create("com.actec.music", DISPATCH_QUEUE_CONCURRENT), ^{
                            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (!groupCancel) {
                                    NSString *hex = [CSRUtilities stringWithHexNumber:model.mcCurrentChannel];
                                    NSString *bin = [CSRUtilities getBinaryByhex:hex];
                                    for (int i = 0; i < [bin length]; i ++) {
                                        NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
                                        if ([bit boolValue]) {
                                            Byte byte[] = {0xea, 0x81, i, 0x00, 0x00};
                                            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
                                            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                                            break;
                                        }
                                    }
                                }
                            });
                        });
                        
                        [[DeviceModelManager sharedInstance] refreshDeviceID:_deviceId mcCurrentChannel:pow(2, _channel)];
                        
                    }
                }
            }
            
        }];
        alert.pickerViewBlock = ^(NSInteger row) {
            _channel = row;
        };
        [alert addAction:cancelAction];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
        
    }
}

- (IBAction)sourceAction:(UIButton *)sender {
    
    MCPickerAlertController *alert = [MCPickerAlertController MCAlertControllerWithTitle:AcTECLocalizedStringFromTable(@"select_the_audio_source", @"Localizable") dataArray:AUDIOSOURCES];
    [alert.pickerView selectRow:source inComponent:0 animated:NO];
    alert.selectedRow = source;
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sendControlCommand:2];
        [_sourceBtn setTitle:AUDIOSOURCES[source] forState:UIControlStateNormal];
    }];
    alert.pickerViewBlock = ^(NSInteger row) {
        source = row;
    };
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)cycleAction:(UIButton *)sender {
    
    NSArray *pa;
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
        pa = PLAYMODE_SONOS;
    }else {
        pa = PLAYMODE;
    }
    MCPickerAlertController *alert = [MCPickerAlertController MCAlertControllerWithTitle:AcTECLocalizedStringFromTable(@"select_cycle_mode", @"Localizable") dataArray:pa];
    [alert.pickerView selectRow:cycle inComponent:0 animated:NO];
    alert.selectedRow = cycle;
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sendControlCommand:3];
        [_cycleBtn setTitle:pa[cycle] forState:UIControlStateNormal];
    }];
    alert.pickerViewBlock = ^(NSInteger row) {
        cycle = row;
    };
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSString *)fixBinStringEightLenth:(NSString *)bin {
    switch ([bin length]) {
        case 7:
            bin = [NSString stringWithFormat:@"0%@",bin];
            break;
        case 6:
            bin = [NSString stringWithFormat:@"00%@",bin];
            break;
        case 5:
            bin = [NSString stringWithFormat:@"000%@",bin];
            break;
        case 4:
            bin = [NSString stringWithFormat:@"0000%@",bin];
            break;
        case 3:
            bin = [NSString stringWithFormat:@"00000%@",bin];
            break;
        case 2:
            bin = [NSString stringWithFormat:@"000000%@",bin];
            break;
        case 1:
            bin = [NSString stringWithFormat:@"0000000%@",bin];
            break;
        default:
            break;
    }
    return bin;
}

- (void)refreshMCChannelState:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceID = userInfo[@"deviceId"];
    if ([deviceID isEqualToNumber:_deviceId]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scanOnlineChannelTimeOut) object:nil];
        
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        if (model) {
            if ([CSRUtilities belongToMusicController:model.shortName]) {
                if (model.mcLiveChannels == 0) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"no_online_channel_scanned", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
                    [alert.view setTintColor:DARKORAGE];
                    UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self hideLoading];
                    }];
                    [alert addAction:yes];
                    [self presentViewController:alert animated:YES completion:nil];
                }else if (model.mcCurrentChannel != -1 && model.mcStatus != -1 && model.mcVoice != -1) {
                    [self refreshDisplay:model];
                    [self hideLoading];
                    groupCancel = NO;
                    dispatch_semaphore_signal(semaphore);
                }
            }else if ([CSRUtilities belongToSonosMusicController:model.shortName]) {
                if (model.mcCurrentChannel != -1 && model.mcStatus != -1 && model.mcVoice != -1) {
                    [self refreshDisplay:model];
                    [self hideLoading];
                    groupCancel = NO;
                    dispatch_semaphore_signal(semaphore);
                }
            }
            
        }
    }
}

- (void)refreshDisplay:(DeviceModel *)model {
    NSString *hex = [CSRUtilities stringWithHexNumber:model.mcCurrentChannel];
    NSString *bin = [CSRUtilities getBinaryByhex:hex];
    for (int i = 0; i < [bin length]; i ++) {
        NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
        if ([bit boolValue]) {
            [_channelBtn setTitle:[NSString stringWithFormat:@"%@ %d",AcTECLocalizedStringFromTable(@"channel", @"Localizable"),i] forState:UIControlStateNormal];
            _channel = i;
            break;
        }
    }
    NSString *hex1 = [CSRUtilities stringWithHexNumber:model.mcStatus];
    NSString *bin1 = [self fixBinStringEightLenth:[CSRUtilities getBinaryByhex:hex1]];
    
    NSString *cs = [bin1 substringWithRange:NSMakeRange([bin1 length]-1, 1)];
    [self.navigationItem.rightBarButtonItem setTitle:[cs boolValue]? @"OFF":@"ON"];
    channelState = [cs boolValue];
    
    NSString *p = [bin1 substringWithRange:NSMakeRange([bin1 length]-1-1, 1)];
    _playBtn.selected = [p boolValue];
    play = [p boolValue];
    _cover.highlighted = [p boolValue];
    if ([p boolValue]) {
        [self startAnimation];
        if (!_ripple) {
            _ripple = [[RippleAnimationView alloc] initWithFrame:CGRectMake(0, 0, 137, 137) animationType:AnimationTypeWithoutBackground];
            [self.view addSubview:_ripple];
            [self.view bringSubviewToFront:_cover];
            [self.view bringSubviewToFront:_songNameLabel];
            [_ripple autoAlignAxis:ALAxisVertical toSameAxisOfView:_cover];
            [_ripple autoAlignAxis:ALAxisHorizontal toSameAxisOfView:_cover];
            [_ripple autoSetDimension:ALDimensionWidth toSize:137];
            [_ripple autoSetDimension:ALDimensionHeight toSize:137];
        }else {
            [_ripple startAnimation];
        }
    }else {
        [self stopAnimation];
        [_ripple stopAnimation];
    }
    NSString *s = [bin1 substringWithRange:NSMakeRange([bin1 length]-1-4, 3)];
    NSInteger is = 0;
    for (int i = 0; i < [s length]; i ++) {
        NSString *bit = [s substringWithRange:NSMakeRange([s length]-1-i, 1)];
        if ([bit boolValue]) {
            is = is + pow(2, i);
        }
    }
    if (is < 8) {
        [_sourceBtn setTitle:AUDIOSOURCES[is] forState:UIControlStateNormal];
        source = is;
    }
    
    NSString *c = [bin1 substringWithRange:NSMakeRange([bin1 length]-1-7, 3)];
    NSInteger ic = 0;
    for (int i = 0; i < [c length]; i ++) {
        NSString *bit = [c substringWithRange:NSMakeRange([c length]-1-i, 1)];
        if ([bit boolValue]) {
            ic = ic + pow(2, i);
        }
    }
    if (ic < 5) {
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
            cycle = ic;
            if (ic == 3 || ic == 4) {
                cycle = ic - 1;
            }
            [_cycleBtn setTitle:PLAYMODE[cycle] forState:UIControlStateNormal];
        }else {
            [_cycleBtn setTitle:PLAYMODE[ic] forState:UIControlStateNormal];
            cycle = ic;
        }
    }
    NSString *hex2 = [CSRUtilities stringWithHexNumber:model.mcVoice];
    NSString *bin2 = [self fixBinStringEightLenth:[CSRUtilities getBinaryByhex:hex2]];
    
    NSString *m = [bin2 substringWithRange:NSMakeRange([bin2 length]-1, 1)];
    _muteBtn.selected = [m boolValue];
    mute = [m boolValue];
    
    NSString *v = [bin2 substringWithRange:NSMakeRange([bin2 length]-1-7, 7)];
    NSInteger iv = 0;
    for (int i = 0; i < [v length]; i ++) {
        NSString *bit = [v substringWithRange:NSMakeRange([v length]-1-i, 1)];
        if ([bit boolValue]) {
            iv = iv + pow(2, i);
        }
    }
    voice = iv;
    if (!voicecing) {
        [_voiceSlider setValue:iv animated:YES];
    }
}

- (void)scanOnlineChannelTimeOut {
    [self hideLoading];
    groupCancel = YES;
    dispatch_semaphore_signal(semaphore);
}

- (UIView *)translucentBgView {
    if (!_translucentBgView) {
        _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _translucentBgView.backgroundColor = [UIColor blackColor];
        _translucentBgView.alpha = 0.4;
    }
    return _translucentBgView;
}

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] init];
        _indicatorView.hidesWhenStopped = YES;
        _indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    }
    return _indicatorView;
}

- (void)showLoading {
    [self.view addSubview:self.translucentBgView];
    [self.view addSubview:self.indicatorView];
    [self.indicatorView autoCenterInSuperview];
    [self.indicatorView startAnimating];
}

- (void)hideLoading {
    [self.indicatorView stopAnimating];
    [self.indicatorView removeFromSuperview];
    [self.translucentBgView removeFromSuperview];
    self.indicatorView = nil;
    self.translucentBgView = nil;
}

- (void)refreshMCSongName:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceID = userInfo[@"deviceId"];
    NSNumber *mcChannel = userInfo[@"channel"];
    if ([deviceID isEqualToNumber:_deviceId]) {
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceID];
        if (model.mcCurrentChannel != -1) {
            NSString *hex = [CSRUtilities stringWithHexNumber:model.mcCurrentChannel];
            NSString *bin = [CSRUtilities getBinaryByhex:hex];
            for (int i = 0; i < [bin length]; i ++) {
                NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
                if ([bit boolValue]) {
                    if ([mcChannel intValue] == i) {
                        _songNameLabel.text = model.songName;
                    }
                    break;
                }
            }
        }
    }
}

- (void)refresh:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self showLoading];
        [self performSelector:@selector(scanOnlineChannelTimeOut) withObject:nil afterDelay:10];
        Byte byte[] = {0xea, 0x82, 0x00};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
        
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_async(group, dispatch_queue_create("com.actec.music", DISPATCH_QUEUE_CONCURRENT), ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!groupCancel) {
                    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
                    NSString *hex = [CSRUtilities stringWithHexNumber:model.mcCurrentChannel];
                    NSString *bin = [CSRUtilities getBinaryByhex:hex];
                    for (int i = 0; i < [bin length]; i ++) {
                        NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
                        if ([bit boolValue]) {
                            Byte byte[] = {0xea, 0x81, i, 0x00, 0x00};
                            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
                            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                            break;
                        }
                    }
                }
            });
        });
        
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }
}

- (void)channelState:(UIBarButtonItem *)item {
    channelState = !channelState;
    [item setTitle:channelState? @"OFF":@"ON"];
    [self sendControlCommand:0];
}

- (void)voicecingDelayMethod {
    voicecing = NO;
}

- (void)setPowerStateSuccess:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        [self refreshDisplay:model];
    }
}

@end
