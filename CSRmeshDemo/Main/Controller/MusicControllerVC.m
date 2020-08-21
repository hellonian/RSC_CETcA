//
//  MusicControllerVC.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/8/14.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MusicControllerVC.h"
#import "MCPickerAlertController.h"
#import "CSRDatabaseManager.h"
#import "DataModelManager.h"
#import "DeviceModelManager.h"
#import "CSRUtilities.h"
#import "PureLayout.h"

#define PLAYMODE @[AcTECLocalizedStringFromTable(@"single", @"Localizable"),AcTECLocalizedStringFromTable(@"single_cycle", @"Localizable"),AcTECLocalizedStringFromTable(@"loop_playback", @"Localizable"),AcTECLocalizedStringFromTable(@"random", @"Localizable"),AcTECLocalizedStringFromTable(@"order", @"Localizable")]
#define AUDIOSOURCES @[@"FM",@"DVD",@"MP3",@"AUX",@"NET RADIO",@"CLOUD MUSIC",@"AIRPLAY",@"DLNA"]

@interface MusicControllerVC ()
{
    NSInteger cycle;
    NSInteger channel;
    NSInteger source;
    BOOL mute;
    BOOL play;
    NSInteger voice;
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

@end

@implementation MusicControllerVC

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
    
    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"refresh", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
    self.navigationItem.rightBarButtonItem = refresh;
    
    _cycleBtn.layer.borderColor = [UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1].CGColor;
    _channelBtn.layer.borderColor = [UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1].CGColor;
    _sourceBtn.layer.borderColor = [UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1].CGColor;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMCChannel:) name:@"refreshMCChannel" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMCSongName:) name:@"refreshMCSongName" object:nil];
    
    if (_deviceId) {
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        self.navigationItem.title = device.name;
        
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        if (model) {
            if (model.mcChannel != 0 && model.mcCurrentChannel != -1 && model.mcStatus != -1 && model.mcVoice != -1) {
                
                [self refreshDisplay:model];
                _songNameLabel.text = model.songName;
                
            }else {
                //扫描在线通道
                [self showLoading];
                [self performSelector:@selector(scanOnlineChannelTimeOut) withObject:nil afterDelay:10];
                Byte byte[] = {0xea, 0x82, 0x00};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }
        }
    }
    
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)playPauseAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    _cover.highlighted = sender.selected;
    if (sender.selected) {
        [self startAnimation];
    }else {
        [self stopAnimation];
    }
    play = sender.selected;
    
    [self sendControlCommand:1];
    
}

- (IBAction)lastAction:(UIButton *)sender {
    Byte byte[] = {0xea, 0x80, channel, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (IBAction)nextAction:(UIButton *)sender {
    Byte byte[] = {0xea, 0x80, channel, 0x01};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (void)sendControlCommand:(NSInteger)dv {
    NSInteger cv = pow(2, channel);
    NSInteger s = 1 + play*2 + source*4 + cycle*32;
    NSInteger v = mute + voice*2;
    
    Byte byte[] = {0xb6, 0x06, 0x1e, cv/256, cv%256, pow(2, dv), s, v};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:8];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
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
    [self sendControlCommand:5];
}

- (IBAction)channelAction:(UIButton *)sender {
    
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
    if (model && model.mcChannel != 0) {
        NSString *hex = [CSRUtilities stringWithHexNumber:model.mcChannel];
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
        [alert.pickerView selectRow:channel inComponent:0 animated:NO];
        alert.selectedRow = channel;
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            if (channel != model.mcCurrentChannel) {
                [self showLoading];
                [self performSelector:@selector(scanOnlineChannelTimeOut) withObject:nil afterDelay:10];
                [[DeviceModelManager sharedInstance] refreshDeviceID:_deviceId mcCurrentChannel:channel];
            }
            
        }];
        alert.pickerViewBlock = ^(NSInteger row) {
            channel = row;
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
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self sendControlCommand:2];
    }];
    alert.pickerViewBlock = ^(NSInteger row) {
        source = row;
    };
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)cycleAction:(UIButton *)sender {
    
    MCPickerAlertController *alert = [MCPickerAlertController MCAlertControllerWithTitle:AcTECLocalizedStringFromTable(@"select_cycle_mode", @"Localizable") dataArray:PLAYMODE];
    [alert.pickerView selectRow:cycle inComponent:0 animated:NO];
    alert.selectedRow = cycle;
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self sendControlCommand:3];
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

- (void)refreshMCChannel:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceID = userInfo[@"deviceId"];
    if ([deviceID isEqualToNumber:_deviceId]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scanOnlineChannelTimeOut) object:nil];
        
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        if (model) {
            if (model.mcChannel == 0) {
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
            channel = i;
            break;
        }
    }
    
    NSString *hex1 = [CSRUtilities stringWithHexNumber:model.mcStatus];
    NSString *bin1 = [self fixBinStringEightLenth:[CSRUtilities getBinaryByhex:hex1]];
    
    NSString *p = [bin1 substringWithRange:NSMakeRange([bin1 length]-1-1, 1)];
    _playBtn.selected = [p boolValue];
    play = [p boolValue];
    _cover.highlighted = [p boolValue];
    if ([p boolValue]) {
        [self startAnimation];
    }else {
        [self stopAnimation];
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
        [_cycleBtn setTitle:PLAYMODE[ic] forState:UIControlStateNormal];
        cycle = ic;
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
    [_voiceSlider setValue:iv animated:YES];
    voice = iv;
}

- (void)scanOnlineChannelTimeOut {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"notRespond", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self hideLoading];
    }];
    [alert addAction:yes];
    [self presentViewController:alert animated:YES completion:nil];
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

- (void)refresh {
    [self showLoading];
    [self performSelector:@selector(scanOnlineChannelTimeOut) withObject:nil afterDelay:10];
    Byte byte[] = {0xea, 0x82, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

@end
