//
//  DeviceViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/25.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "DeviceViewController.h"
#import "DeviceModelManager.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import "CSRConstants.h"
#import "DataModelManager.h"
#import "PureLayout.h"
#import "ColorSlider.h"
#import "ColorSquare.h"
#import <CSRmesh/LightModelApi.h>
#import "AFHTTPSessionManager.h"
#import <MBProgressHUD.h>
#import "MCUUpdateTool.h"
#import "SoundListenTool.h"
#import "PowerViewController.h"

@interface DeviceViewController ()<UITextFieldDelegate,ColorSliderDelegate,ColorSquareDelegate,MBProgressHUDDelegate,MCUUpdateToolDelegate>
{
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
    BOOL musicBehavior;
    UIButton *updateMCUBtn;
    
    NSTimer *timer;
    
    BOOL tapLimimte;
}

@property (weak, nonatomic) IBOutlet UITextField *nameTF;
@property (weak, nonatomic) IBOutlet UISwitch *powerStateSwitch;
@property (weak, nonatomic) IBOutlet UISlider *levelSlider;
@property (weak, nonatomic) IBOutlet UILabel *levelLabel;
@property (nonatomic,assign) BOOL sliderIsMoving;
@property (nonatomic,assign) BOOL colorTemperatureSliderIsMoving;
@property (nonatomic,assign) BOOL colorSliderIsMoving;
@property (nonatomic,assign) BOOL colorSaturationSliderIsMoving;
@property (nonatomic,assign) BOOL colorSquareIsMoving;
@property (nonatomic,strong) DeviceModel *device;
@property (nonatomic,copy) NSString *originalName;
@property (weak, nonatomic) IBOutlet UILabel *colorTemperatureTitle;
@property (weak, nonatomic) IBOutlet UIView *threeSpeedcolorTemperatureView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (nonatomic,strong) ColorSlider *colorSlider;
@property (weak, nonatomic) IBOutlet UIView *colorSliderBg;
@property (weak, nonatomic) IBOutlet UISlider *colorTemperatureSlider;
@property (weak, nonatomic) IBOutlet UILabel *colorTemperatureLabel;
@property (nonatomic,strong) UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UILabel *brightnessTitle;
@property (strong, nonatomic) IBOutlet UIView *brightnessView;
@property (strong, nonatomic) IBOutlet UIView *colorTempratureView;
@property (strong, nonatomic) IBOutlet UILabel *colorTitle;
@property (strong, nonatomic) IBOutlet UILabel *colorSaturationTitle;
@property (strong, nonatomic) IBOutlet UIView *colorSaturationView;
@property (nonatomic,strong) ColorSquare *colorSquareView;

@property (weak, nonatomic) IBOutlet UISlider *colorSaturationSlider;
@property (weak, nonatomic) IBOutlet UILabel *colorLabel;
@property (weak, nonatomic) IBOutlet UILabel *colorSaturationLabel;

@property (nonatomic,strong) MBProgressHUD *updatingHud;
@property (strong, nonatomic) IBOutlet UIView *dalinView;
@property (weak, nonatomic) IBOutlet UIButton *daliAllSelectBtn;
@property (weak, nonatomic) IBOutlet UIButton *daliGroupSelectBtn;
@property (weak, nonatomic) IBOutlet UIButton *daliAddressBtn;
@property (weak, nonatomic) IBOutlet UIButton *daliSceneSelectBtn;
@property (weak, nonatomic) IBOutlet UILabel *daliDeviceLab;
@property (weak, nonatomic) IBOutlet UILabel *daliGroupLab;
@property (weak, nonatomic) IBOutlet UILabel *daliSceneLab;
@property (nonatomic,strong) UIView *translucentBgView;

@property (strong, nonatomic) IBOutlet UIView *ganjiedianView;
@property (weak, nonatomic) IBOutlet UIButton *switchModelBtn;
@property (weak, nonatomic) IBOutlet UIButton *oneSecondModelBtn;
@property (weak, nonatomic) IBOutlet UIButton *sixSecondModelBtn;
@property (weak, nonatomic) IBOutlet UIButton *nineSecondModelBtn;
@property (strong, nonatomic) IBOutlet UIView *ganjiedianCustomView;
@property (strong, nonatomic) IBOutlet UIView *ganjiedianRowView;
@property (weak, nonatomic) IBOutlet UIImageView *dropDownImageView;
@property (weak, nonatomic) IBOutlet UILabel *pulseModeLabel;

@property (strong, nonatomic) IBOutlet UIView *powerView;
@property (weak, nonatomic) IBOutlet UILabel *currentPower1Label;
@property (weak, nonatomic) IBOutlet UIImageView *abnormalImageView;
@property (weak, nonatomic) IBOutlet UISwitch *thresholdSwitch;
@property (weak, nonatomic) IBOutlet UILabel *thresholdLab;

@property (strong, nonatomic) IBOutlet UIView *RGBGroupControllSwitchView;
@property (weak, nonatomic) IBOutlet UISwitch *RGBGroupControllSwitch;

@property (strong, nonatomic) MBProgressHUD *waitingHud;
@property (strong, nonatomic) IBOutlet UIView *powerSwitchChannelTwoView;
@property (strong, nonatomic) IBOutlet UIView *powerSwitchChannelThreeView;
@property (weak, nonatomic) IBOutlet UISwitch *powerSwitchChannelTwo;
@property (weak, nonatomic) IBOutlet UISwitch *powerSwitchChannelThree;
@property (strong, nonatomic) IBOutlet UIView *levelSliderChannelTwoView;
@property (weak, nonatomic) IBOutlet UISlider *levelSliderChannelTwo;
@property (weak, nonatomic) IBOutlet UILabel *levelLabelChannelTwo;

@end

@implementation DeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange:) name:ZZAppLanguageDidChangeNotification object:nil];
    
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.userInteractionEnabled = YES;
    [self.view addSubview:_scrollView];
    [_scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *top;
    if (@available(iOS 11.0,*)) {
        top = [NSLayoutConstraint constraintWithItem:_scrollView
                                           attribute:NSLayoutAttributeTop
                                           relatedBy:NSLayoutRelationEqual
                                              toItem:self.view.safeAreaLayoutGuide
                                           attribute:NSLayoutAttributeTop
                                          multiplier:1.0
                                            constant:0];
    }else {
        self.automaticallyAdjustsScrollViewInsets = NO;
        if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
            top = [NSLayoutConstraint constraintWithItem:_scrollView
                                               attribute:NSLayoutAttributeTop
                                               relatedBy:NSLayoutRelationEqual
                                                  toItem:self.view
                                               attribute:NSLayoutAttributeTop
                                              multiplier:1.0
                                                constant:64];
        }else {
            top = [NSLayoutConstraint constraintWithItem:_scrollView
                                               attribute:NSLayoutAttributeTop
                                               relatedBy:NSLayoutRelationEqual
                                                  toItem:self.view
                                               attribute:NSLayoutAttributeTop
                                              multiplier:1.0
                                                constant:44];
        }
    }
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_scrollView
                                                            attribute:NSLayoutAttributeLeft
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.view
                                                            attribute:NSLayoutAttributeLeft
                                                           multiplier:1.0
                                                             constant:0];
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_scrollView
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1.0
                                                              constant:0];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:_scrollView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0];;
    
    [NSLayoutConstraint activateConstraints:@[top,left,bottom,right]];
    
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
    }
    
    self.nameTF.delegate = self;
    
    if ([_deviceId integerValue] > 32768/*单设备*/) {
        
        [_scrollView addSubview:_topView];
        [_topView autoSetDimension:ALDimensionHeight toSize:153];
        [_topView autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [_topView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_topView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        
        _device = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        if ([CSRUtilities belongToSwitch:_device.shortName]) {
            if ([CSRUtilities belongToThreeSpeedColorTemperatureDevice:_device.shortName]) {
                
                [_scrollView addSubview:_colorTemperatureTitle];
                [_colorTemperatureTitle autoSetDimension:ALDimensionHeight toSize:20];
                [_colorTemperatureTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_topView withOffset:5];
                [_colorTemperatureTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
                [_colorTemperatureTitle autoSetDimension:ALDimensionWidth toSize:150];
                
                [_scrollView addSubview:_threeSpeedcolorTemperatureView];
                [_threeSpeedcolorTemperatureView autoSetDimension:ALDimensionHeight toSize:89];
                [_threeSpeedcolorTemperatureView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorTemperatureTitle withOffset:5];
                [_threeSpeedcolorTemperatureView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
                [_threeSpeedcolorTemperatureView autoAlignAxisToSuperviewAxis:ALAxisVertical];
                
                _scrollView.contentSize = CGSizeMake(1, 253+20);
                
            }else if ([_device.shortName isEqualToString:@"S10IB"]||[_device.shortName isEqualToString:@"S10IBH"]) {
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(getGanjiedianModel:)
                                                             name:@"getGanjiedianModel"
                                                           object:nil];
                [[DataModelManager shareInstance] sendCmdData:@"ea70" toDeviceId:_deviceId];
//                [self addSubviewGanjiedianView];
//                _scrollView.contentSize = CGSizeMake(1, 253+20+20+128);
                [self addSubviewGanjiedianRowView];
                _scrollView.contentSize = CGSizeMake(1, 253+20+45+20);
                
            }else {
                _scrollView.contentSize = CGSizeMake(1, 134+20+20);
            }
        }
        
        else if ([CSRUtilities belongToDimmer:_device.shortName]) {
            [self addSubviewBrightnessView];
            
            if ([CSRUtilities belongToThreeSpeedColorTemperatureDevice:_device.shortName]) {
                [_scrollView addSubview:_colorTemperatureTitle];
                [_colorTemperatureTitle autoSetDimension:ALDimensionHeight toSize:20];
                [_colorTemperatureTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_brightnessView withOffset:5];
                [_colorTemperatureTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
                [_colorTemperatureTitle autoSetDimension:ALDimensionWidth toSize:150];
                
                [_scrollView addSubview:_threeSpeedcolorTemperatureView];
                [_threeSpeedcolorTemperatureView autoSetDimension:ALDimensionHeight toSize:89];
                [_threeSpeedcolorTemperatureView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorTemperatureTitle withOffset:5];
                [_threeSpeedcolorTemperatureView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
                [_threeSpeedcolorTemperatureView autoAlignAxisToSuperviewAxis:ALAxisVertical];
                
                _scrollView.contentSize = CGSizeMake(1, 327+20+20);
            }else if ([CSRUtilities belongToDALDevice:_device.shortName]) {
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(getDaliAdress:)
                                                             name:@"getDaliAdress"
                                                           object:nil];
                [[DataModelManager shareInstance] sendCmdData:@"ea520102" toDeviceId:_deviceId];
                [self addSubviewDalinView];
                _scrollView.contentSize = CGSizeMake(1, 427+20);
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                if (deviceEntity.remoteBranch && [deviceEntity.remoteBranch length]>0) {
                    [self configDaliAppearance:[CSRUtilities numberWithHexString:deviceEntity.remoteBranch]];
                }
            }else if ([_device.shortName isEqualToString:@"SD350"]||[_device.shortName isEqualToString:@"SSD150"]) {
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(socketPowerCall:)
                                                             name:@"socketPowerCall"
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
                [_scrollView addSubview:_powerView];
                [_powerView autoSetDimension:ALDimensionHeight toSize:287.0];
                [_powerView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
                [_powerView autoAlignAxisToSuperviewAxis:ALAxisVertical];
                [_powerView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_brightnessView withOffset:20.0];
                _scrollView.contentSize = CGSizeMake(1, 535+20);
                
                [[DataModelManager shareInstance] sendCmdData:@"ea4801" toDeviceId:_deviceId];
                
            }else {
                _scrollView.contentSize = CGSizeMake(1, 208+20+20);
            }
        }
        
        else if ([CSRUtilities belongToCWDevice:_device.shortName]) {
            [self addSubviewBrightnessView];
            [self addSubViewColorTemperatuteView];
            _scrollView.contentSize = CGSizeMake(1, 282+20+20);
        }
        
        else if ([CSRUtilities belongToRGBDevice:_device.shortName]) {
            musicBehavior = YES;
            [self addSubviewBrightnessView];
            [_scrollView addSubview:_colorTitle];
            [_colorTitle autoSetDimension:ALDimensionHeight toSize:20];
            [_colorTitle autoSetDimension:ALDimensionWidth toSize:80];
            [_colorTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_brightnessView withOffset:5];
            [_colorTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
            
            [self addSubViewColorView];
            
            _scrollView.contentSize = CGSizeMake(1, 616+20);
        }
        
        else if ([CSRUtilities belongToRGBCWDevice:_device.shortName]) {
            musicBehavior = YES;
            [self addSubviewBrightnessView];
            
            [self addSubViewColorTemperatuteView];
            
            [_scrollView addSubview:_colorTitle];
            [_colorTitle autoSetDimension:ALDimensionHeight toSize:20];
            [_colorTitle autoSetDimension:ALDimensionWidth toSize:80];
            [_colorTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorTempratureView withOffset:5];
            [_colorTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
            
            [self addSubViewColorView];
            _scrollView.contentSize = CGSizeMake(1, 650+20);
        }
        
        else if ([CSRUtilities belongToTwoChannelSwitch:_device.shortName]) {
            [self addSubViewPowerSwitchChannelTwoView];
            _scrollView.contentSize = CGSizeMake(1, 237);
        }
        
        else if ([CSRUtilities belongToThreeChannelSwitch:_device.shortName]) {
            [self addSubViewPowerSwitchChannelTwoView];
            [self addSubViewPowerSwitchChannelThreeView];
            _scrollView.contentSize = CGSizeMake(1, 301);
        }
        
        else if ([CSRUtilities belongToTwoChannelDimmer:_device.shortName]) {
            NSLog(@"belongToTwoChannelDimmer");
            [self addSubviewBrightnessView];
            [self addSubViewChannelTwoBrightnessView];
            _scrollView.contentSize = CGSizeMake(1, 386);
        }
        
        self.navigationItem.title = _device.name;
        self.nameTF.text = _device.name;
        self.originalName = _device.name;
        self.sliderIsMoving = NO;
        self.colorTemperatureSliderIsMoving = NO;
        self.colorSliderIsMoving = NO;
        self.colorSaturationSliderIsMoving = NO;
        self.colorSquareIsMoving = NO;
        
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        NSString *macAddr = [deviceEntity.uuid substringFromIndex:24];
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
        
        if ([deviceEntity.hwVersion integerValue]==2) {
            NSMutableString *mutStr = [NSMutableString stringWithString:_device.shortName];
            NSRange range = {0,_device.shortName.length};
            [mutStr replaceOccurrencesOfString:@"/" withString:@"" options:NSLiteralSearch range:range];
            NSString *urlString = [NSString stringWithFormat:@"http://39.108.152.134/MCU/%@/%@.php",mutStr,mutStr];
            AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
            sessionManager.responseSerializer.acceptableContentTypes = nil;
            sessionManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
            [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                NSDictionary *dic = (NSDictionary *)responseObject;
                latestMCUSVersion = [dic[@"mcu_software_version"] integerValue];
                downloadAddress = dic[@"Download_address"];
                if ([deviceEntity.mcuSVersion integerValue]<latestMCUSVersion) {
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
    }else {/*分组*/
        [self forRGBGroupControllerAddSwitchView];
        [self forRGBGroupControllerAddBrightnessView];
        CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:_deviceId];
        __block BOOL RGBCWExist = NO;
        __block BOOL RGBExist = NO;
        __block BOOL CWExist = NO;
        [area.devices enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, BOOL * _Nonnull stop) {
            if ([CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
                RGBCWExist = YES;
            }else if ([CSRUtilities belongToRGBDevice:deviceEntity.shortName]) {
                RGBExist = YES;
            }else if ([CSRUtilities belongToCWDevice:deviceEntity.shortName]) {
                CWExist = YES;
            }
        }];
        
        if (RGBCWExist && !RGBExist && !CWExist) {
            [self addSubViewColorTemperatuteView];
            [_scrollView addSubview:_colorTitle];
            [_colorTitle autoSetDimension:ALDimensionHeight toSize:20];
            [_colorTitle autoSetDimension:ALDimensionWidth toSize:80];
            [_colorTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorTempratureView withOffset:5];
            [_colorTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
            [self addSubViewColorView];
            _scrollView.contentSize = CGSizeMake(1, 560);
        }else if ((RGBCWExist || RGBExist) && !CWExist) {
            [_scrollView addSubview:_colorTitle];
            [_colorTitle autoSetDimension:ALDimensionHeight toSize:20];
            [_colorTitle autoSetDimension:ALDimensionWidth toSize:80];
            [_colorTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_brightnessView withOffset:5];
            [_colorTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
            [self addSubViewColorView];
            _scrollView.contentSize = CGSizeMake(1, 486);
        }else if ((RGBCWExist || CWExist) && !RGBExist) {
            self.navigationItem.title = area.areaName;
            [self addSubViewColorTemperatuteView];
            _scrollView.contentSize = CGSizeMake(1, 192);
        }
    }
    if ([_deviceId integerValue] > 32768/*单设备*/) {
        [self adjustInterface];
    }else {
        [self forRGBGroupControllAdustInterface];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([_deviceId integerValue] > 32768/*单设备*/) {
        [self adjustInterface];
    }else {
        [self forRGBGroupControllAdustInterface];
    }
}

- (void)askUpdateMCU {
    [MCUUpdateTool sharedInstace].toolDelegate = self;
    [[MCUUpdateTool sharedInstace] askUpdateMCU:_deviceId downloadAddress:downloadAddress latestMCUSVersion:latestMCUSVersion];
}

- (void)starteUpdateHud {
    if (!_updatingHud) {
        if ([_device.shortName isEqualToString:@"SD350"]||[_device.shortName isEqualToString:@"SSD150"]) {
            if (timer) {
                [timer invalidate];
                timer = nil;
            }
        }
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
        if (([_device.shortName isEqualToString:@"SD350"]||[_device.shortName isEqualToString:@"SSD150"]) && value) {
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

- (void)addSubviewBrightnessView {
    [_scrollView addSubview:_brightnessView];
    [_brightnessView autoSetDimension:ALDimensionHeight toSize:44];
    [_brightnessView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_topView withOffset:20.0];
    [_brightnessView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_brightnessView autoAlignAxisToSuperviewAxis:ALAxisVertical];
}

- (void)addSubviewDalinView {
    [_scrollView addSubview:_dalinView];
    [_dalinView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_brightnessView withOffset:20.0];
    [_dalinView autoSetDimension:ALDimensionHeight toSize:179.0];
    [_dalinView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_dalinView autoAlignAxisToSuperviewAxis:ALAxisVertical];
}

- (void)addSubviewGanjiedianView {
    [_scrollView addSubview:_ganjiedianView];
    [_ganjiedianView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_topView withOffset:20.0];
    [_ganjiedianView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_ganjiedianView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_ganjiedianView autoSetDimension:ALDimensionHeight toSize:128.0];
}
- (void)addSubviewGanjiedianRowView {
    [_scrollView addSubview:_ganjiedianRowView];
    [_ganjiedianRowView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_topView];
    [_ganjiedianRowView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_ganjiedianRowView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_ganjiedianRowView autoSetDimension:ALDimensionHeight toSize:45.0];
}

- (void)addSubViewColorTemperatuteView {
    [_scrollView addSubview:_colorTemperatureTitle];
    [_colorTemperatureTitle autoSetDimension:ALDimensionHeight toSize:20];
    [_colorTemperatureTitle autoSetDimension:ALDimensionWidth toSize:150];
    [_colorTemperatureTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_brightnessView withOffset:5];
    [_colorTemperatureTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    
    [_scrollView addSubview:_colorTempratureView];
    [_colorTempratureView autoSetDimension:ALDimensionHeight toSize:44];
    [_colorTempratureView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorTemperatureTitle withOffset:5];
    [_colorTempratureView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_colorTempratureView autoAlignAxisToSuperviewAxis:ALAxisVertical];
}

- (void)addSubViewColorView {
    [_scrollView addSubview:_colorSliderBg];
    [_colorSliderBg autoSetDimension:ALDimensionHeight toSize:44];
    [_colorSliderBg autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorTitle withOffset:5];
    [_colorSliderBg autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_colorSliderBg autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    
    _colorSlider = [[ColorSlider alloc] initWithFrame:CGRectZero];
    _colorSlider.delegate = self;
    [_colorSliderBg addSubview:_colorSlider];
    [_colorSlider autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [_colorSlider autoSetDimension:ALDimensionHeight toSize:31];
    [_colorSlider autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:44];
    [_colorSlider autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:68];
    
    [_scrollView addSubview:_colorSaturationTitle];
    [_colorSaturationTitle autoSetDimension:ALDimensionHeight toSize:20];
    [_colorSaturationTitle autoSetDimension:ALDimensionWidth toSize:120];
    [_colorSaturationTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorSliderBg withOffset:5];
    [_colorSaturationTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    
    [_scrollView addSubview:_colorSaturationView];
    [_colorSaturationView autoSetDimension:ALDimensionHeight toSize:44];
    [_colorSaturationView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorSaturationTitle withOffset:5];
    [_colorSaturationView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_colorSaturationView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    
    _colorSquareView = [[ColorSquare alloc] initWithFrame:CGRectZero];
    _colorSquareView.delegate = self;
    [_scrollView addSubview:_colorSquareView];
    [_colorSquareView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorSaturationView withOffset:20];
    [_colorSquareView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [_colorSquareView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_colorSquareView autoSetDimension:ALDimensionHeight toSize:180];
}

- (void)addSubViewPowerSwitchChannelTwoView {
    [_scrollView addSubview:_powerSwitchChannelTwoView];
    [_powerSwitchChannelTwoView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_topView withOffset:20.0];
    [_powerSwitchChannelTwoView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_powerSwitchChannelTwoView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_powerSwitchChannelTwoView autoSetDimension:ALDimensionHeight toSize:44.0];
}

- (void)addSubViewPowerSwitchChannelThreeView {
    [_scrollView addSubview:_powerSwitchChannelThreeView];
    [_powerSwitchChannelThreeView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_powerSwitchChannelTwoView withOffset:20.0];
    [_powerSwitchChannelThreeView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_powerSwitchChannelThreeView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_powerSwitchChannelThreeView autoSetDimension:ALDimensionHeight toSize:44.0];
}

- (void)addSubViewChannelTwoBrightnessView {
    [_scrollView addSubview:_powerSwitchChannelTwoView];
    [_powerSwitchChannelTwoView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_brightnessView withOffset:20.0];
    [_powerSwitchChannelTwoView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_powerSwitchChannelTwoView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_powerSwitchChannelTwoView autoSetDimension:ALDimensionHeight toSize:44.0];
    
    [_scrollView addSubview:_levelSliderChannelTwoView];
    [_levelSliderChannelTwoView autoSetDimension:ALDimensionHeight toSize:44];
    [_levelSliderChannelTwoView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_powerSwitchChannelTwoView withOffset:20.0];
    [_levelSliderChannelTwoView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_levelSliderChannelTwoView autoAlignAxisToSuperviewAxis:ALAxisVertical];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setPowerStateSuccess:)
                                                 name:@"setPowerStateSuccess"
                                               object:nil];
    if ([_device.shortName isEqualToString:@"SD350"]||[_device.shortName isEqualToString:@"SSD150"]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(socketPowerCall:)
                                                     name:@"socketPowerCall"
                                                   object:nil];
        if (!timer) {
            timer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(timerMethod:) userInfo:nil repeats:YES];
//            [timer fire];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"setPowerStateSuccess"
                                                  object:nil];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    if ([_device.shortName isEqualToString:@"SD350"]||[_device.shortName isEqualToString:@"SSD150"]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"socketPowerCall" object:nil];
        if (timer) {
            [timer invalidate];
            timer = nil;
        }
    }
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)adjustInterface {
    if (!_sliderIsMoving) {
        if ([CSRUtilities belongToSwitch:_device.shortName]) {
            if ([_device.powerState boolValue]) {
                [self.powerStateSwitch setOn:YES];
            }else {
                [self.powerStateSwitch setOn:NO];
            }
            return;
        }else if ([CSRUtilities belongToDimmer:_device.shortName]) {
            if ([_device.powerState boolValue]) {
                [self.powerStateSwitch setOn:YES];
                [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
                self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
            }else {
                [self.powerStateSwitch setOn:NO];
                [self.levelSlider setValue:0 animated:YES];
                self.levelLabel.text = @"0%";
            }
            return;
        }else if ([CSRUtilities belongToCWDevice:_device.shortName]) {
            if ([_device.powerState boolValue]) {
                [self.powerStateSwitch setOn:YES];
                [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
                self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
            }else {
                [self.powerStateSwitch setOn:NO];
                [self.levelSlider setValue:0 animated:YES];
                self.levelLabel.text = @"0%";
            }
            if (!_colorTemperatureSliderIsMoving) {
                [_colorTemperatureSlider setValue:(CGFloat)[_device.colorTemperature integerValue] animated:YES];
                _colorTemperatureLabel.text = [NSString stringWithFormat:@"%ldK",(long)[_device.colorTemperature integerValue]];
            }
            
            return;
        }else if ([CSRUtilities belongToRGBDevice:_device.shortName]) {
            if ([_device.powerState boolValue]) {
                [self.powerStateSwitch setOn:YES];
                [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
                self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
            }else {
                [self.powerStateSwitch setOn:NO];
                [self.levelSlider setValue:0 animated:YES];
                self.levelLabel.text = @"0%";
            }
            UIColor *color = [UIColor colorWithRed:[_device.red integerValue]/255.0 green:[_device.green integerValue]/255.0 blue:[_device.blue integerValue]/255.0 alpha:1.0];
            CGFloat hue,saturation,brightness,alpha;
            if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
                if (!_colorSliderIsMoving && !_colorSaturationSliderIsMoving && !_colorSquareIsMoving) {
                    [self.colorSlider sliderMyValue:hue];
                    self.colorLabel.text = [NSString stringWithFormat:@"%.f",hue*360];
                    [self.colorSaturationSlider setValue:saturation animated:YES];
                    self.colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",saturation*100];
                    [self.colorSquareView locationPickView:hue colorSaturation:saturation];
                }
            }
            return;
        }else if ([CSRUtilities belongToRGBCWDevice:_device.shortName]) {
            if ([_device.powerState boolValue]) {
                [self.powerStateSwitch setOn:YES];
                [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
                self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
            }else {
                [self.powerStateSwitch setOn:NO];
                [self.levelSlider setValue:0 animated:YES];
                self.levelLabel.text = @"0%";
            }

            if (!_colorTemperatureSliderIsMoving) {
                [_colorTemperatureSlider setValue:(CGFloat)[_device.colorTemperature integerValue] animated:YES];
                _colorTemperatureLabel.text = [NSString stringWithFormat:@"%ldK",(long)[_device.colorTemperature integerValue]];
            }
            UIColor *color = [UIColor colorWithRed:[_device.red integerValue]/255.0 green:[_device.green integerValue]/255.0 blue:[_device.blue integerValue]/255.0 alpha:1.0];
            CGFloat hue,saturation,brightness,alpha;
            if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
                if (!_colorSliderIsMoving && !_colorSaturationSliderIsMoving && !_colorSquareIsMoving) {
                    [self.colorSlider sliderMyValue:hue];
                    self.colorLabel.text = [NSString stringWithFormat:@"%.f",hue*360];
                    [self.colorSaturationSlider setValue:saturation animated:YES];
                    self.colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",saturation*100];
                    [self.colorSquareView locationPickView:hue colorSaturation:saturation];
                }
            }
            
            return;
        }else if ([CSRUtilities belongToTwoChannelSwitch:_device.shortName]) {
            [self.powerStateSwitch setOn:_device.channel1PowerState];
            [self.powerSwitchChannelTwo setOn:_device.channel2PowerState];
            return;
        }else if ([CSRUtilities belongToThreeChannelSwitch:_device.shortName]) {
            [self.powerStateSwitch setOn:_device.channel1PowerState];
            [self.powerSwitchChannelTwo setOn:_device.channel2PowerState];
            [self.powerSwitchChannelThree setOn:_device.channel3PowerState];
            return;
        }else if ([CSRUtilities belongToTwoChannelDimmer:_device.shortName]) {
            if (_device.channel1PowerState) {
                [self.powerStateSwitch setOn:YES];
                [self.levelSlider setValue:_device.channel1Level animated:YES];
                self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",_device.channel1Level/255.0*100];
            }else {
                [self.powerStateSwitch setOn:NO];
                [self.levelSlider setValue:0 animated:YES];
                self.levelLabel.text = @"0%";
            }
            if (_device.channel2PowerState) {
                [self.powerSwitchChannelTwo setOn:YES];
                [self.levelSliderChannelTwo setValue:_device.channel2Level animated:YES];
                self.levelLabelChannelTwo.text = [NSString stringWithFormat:@"%.f%%",_device.channel2Level/255.0*100];
            }else {
                [self.powerSwitchChannelTwo setOn:NO];
                [self.levelSliderChannelTwo setValue:0 animated:YES];
                self.levelLabelChannelTwo.text = @"0%";
            }
            return;
        }
    }
}

- (void)setPowerStateSuccess:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([_deviceId integerValue] > 32768/*单设备*/) {
        if ([deviceId isEqualToNumber:_deviceId]) {
            [self adjustInterface];
        }
    }
}
//开关
- (IBAction)powerStateSwitch:(UISwitch *)sender {
    if (!tapLimimte) {
        tapLimimte = YES;
        _powerStateSwitch.enabled = NO;
        _powerSwitchChannelTwo.enabled = NO;
        _powerSwitchChannelThree.enabled = NO;
        _RGBGroupControllSwitch.enabled = NO;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayMethodEndLevelMoving) object:nil];
        _sliderIsMoving = YES;
        
        if ([CSRUtilities belongToThreeChannelSwitch:_device.shortName]
            || [CSRUtilities belongToTwoChannelSwitch:_device.shortName]
            || [CSRUtilities belongToTwoChannelDimmer:_device.shortName]) {
            Byte byte[] = {0x51, 0x05, 0x01, 0x00, 0x01, sender.on, _device.channel1Level};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:7];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            if (sender.on) {
                [self.levelSlider setValue:_device.channel1Level animated:YES];
                self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",_device.channel1Level/255.0*100];
            }else {
                [self.levelSlider setValue:0 animated:YES];
                self.levelLabel.text = @"0%";
            }
        }else {
            if (musicBehavior) {
                if ([SoundListenTool sharedInstance].audioRecorder.recording) {
                    [[SoundListenTool sharedInstance] stopRecord:_deviceId];
                }
            }
            [[DeviceModelManager sharedInstance] invalidateColofulTimerWithDeviceId:_deviceId];
            [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId withPowerState:@(sender.on)];
            
            if ([_deviceId integerValue] < 32768/*分组*/) {
                if (sender.on) {
                    CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:_deviceId];
                    NSArray *ds = [area.devices allObjects];
                    CSRDeviceEntity *d = ds[0];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:d.deviceId];
                    NSLog(@"%@  %@",deviceModel.deviceId, deviceModel.level);
                    [self.levelSlider setValue:(CGFloat)[deviceModel.level integerValue] animated:YES];
                    self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[deviceModel.level integerValue]/255.0*100];
                }else {
                    [self.RGBGroupControllSwitch setOn:NO];
                    [self.levelSlider setValue:0 animated:YES];
                    self.levelLabel.text = @"0%";
                }
            }else {
                if (sender.on) {
                    [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
                    self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
                }else {
                    [self.levelSlider setValue:0 animated:YES];
                    self.levelLabel.text = @"0%";
                }
            }
        }
        
        [self performSelector:@selector(delayMethodEndLevelMoving) withObject:nil afterDelay:4.0];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            tapLimimte = NO;
            _powerStateSwitch.enabled = YES;
            _powerSwitchChannelTwo.enabled = YES;
            _powerSwitchChannelThree.enabled = YES;
            _RGBGroupControllSwitch.enabled = YES;
        });
    }
}

- (IBAction)powerSwitchChannelTwo:(UISwitch *)sender {
    if (!tapLimimte) {
        tapLimimte = YES;
        _powerStateSwitch.enabled = NO;
        _powerSwitchChannelTwo.enabled = NO;
        _powerSwitchChannelThree.enabled = NO;
        
        if ([CSRUtilities belongToThreeChannelSwitch:_device.shortName]
            || [CSRUtilities belongToTwoChannelSwitch:_device.shortName]
            || [CSRUtilities belongToTwoChannelDimmer:_device.shortName]) {
            Byte byte[] = {0x51, 0x05, 0x02, 0x00, 0x01, sender.on, _device.channel2Level};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:7];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            if (sender.on) {
                [self.levelSliderChannelTwo setValue:_device.channel2Level animated:YES];
                self.levelLabelChannelTwo.text = [NSString stringWithFormat:@"%.f%%",_device.channel2Level/255.0*100];
            }else {
                [self.levelSliderChannelTwo setValue:0 animated:YES];
                self.levelLabelChannelTwo.text = @"0%";
            }
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            tapLimimte = NO;
            _powerStateSwitch.enabled = YES;
            _powerSwitchChannelTwo.enabled = YES;
            _powerSwitchChannelThree.enabled = YES;
        });
    }
}

- (IBAction)powerStateSwitchChannelThree:(UISwitch *)sender {
    if (!tapLimimte) {
        tapLimimte = YES;
        _powerStateSwitch.enabled = NO;
        _powerSwitchChannelTwo.enabled = NO;
        _powerSwitchChannelThree.enabled = NO;
        
        if ([CSRUtilities belongToThreeChannelSwitch:_device.shortName]) {
            [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"51050400010%d00",sender.on] toDeviceId:_deviceId];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            tapLimimte = NO;
            _powerStateSwitch.enabled = YES;
            _powerSwitchChannelTwo.enabled = YES;
            _powerSwitchChannelThree.enabled = YES;
        });
    }
}

//调光
- (IBAction)levelSliderTouchDown:(UISlider *)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayMethodEndLevelMoving) object:nil];
    _sliderIsMoving = YES;
    
    if ([CSRUtilities belongToTwoChannelDimmer:_device.shortName]) {
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId channel:@2 withLevel:@(sender.value) withState:UIGestureRecognizerStateBegan direction:PanGestureMoveDirectionHorizontal];
    }else {
        if (musicBehavior) {
            if ([SoundListenTool sharedInstance].audioRecorder.recording) {
                [[SoundListenTool sharedInstance] stopRecord:_deviceId];
            }
        }
        [[DeviceModelManager sharedInstance] invalidateColofulTimerWithDeviceId:_deviceId];
        
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId channel:@1 withLevel:@(sender.value) withState:UIGestureRecognizerStateBegan direction:PanGestureMoveDirectionHorizontal];
    }
}

- (IBAction)leveSliderValueChanged:(UISlider *)sender {
    
    if ([CSRUtilities belongToTwoChannelDimmer:_device.shortName]) {
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId channel:@2 withLevel:@(sender.value) withState:UIGestureRecognizerStateChanged direction:PanGestureMoveDirectionHorizontal];
    }else {
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId channel:@1 withLevel:@(sender.value) withState:UIGestureRecognizerStateChanged direction:PanGestureMoveDirectionHorizontal];
    }
    
    self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value/255.0*100];
    if (sender.value == 0) {
        if ([_deviceId integerValue] < 32768/*分组*/) {
            [_RGBGroupControllSwitch setOn:NO];
        }else {
            [_powerStateSwitch setOn:NO];
        }
    }else {
        if ([_deviceId integerValue] < 32768/*分组*/) {
            [_RGBGroupControllSwitch setOn:YES];
        }else {
            [_powerStateSwitch setOn:YES];
        }
    }
}

- (IBAction)levelSliderTouchUpInSide:(UISlider *)sender {
    [self performSelector:@selector(delayMethodEndLevelMoving) withObject:nil afterDelay:4.0];
    
    if ([CSRUtilities belongToTwoChannelDimmer:_device.shortName]) {
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId channel:@2 withLevel:@(sender.value) withState:UIGestureRecognizerStateEnded direction:PanGestureMoveDirectionHorizontal];
    }else {
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId channel:@1 withLevel:@(sender.value) withState:UIGestureRecognizerStateEnded direction:PanGestureMoveDirectionHorizontal];
    }
    
    self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value/255.0*100];
    if (sender.value == 0) {
        if ([_deviceId integerValue] < 32768/*分组*/) {
            [_RGBGroupControllSwitch setOn:NO];
        }else {
            [_powerStateSwitch setOn:NO];
        }
    }else {
        if ([_deviceId integerValue] < 32768/*分组*/) {
            [_RGBGroupControllSwitch setOn:YES];
        }else {
            [_powerStateSwitch setOn:YES];
        }
    }
}

- (IBAction)levelSliderChannelTwoTouchDown:(UISlider *)sender {
    if ([CSRUtilities belongToTwoChannelDimmer:_device.shortName]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayMethodEndLevelMoving) object:nil];
        _sliderIsMoving = YES;
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId channel:@3 withLevel:@(sender.value) withState:UIGestureRecognizerStateBegan direction:PanGestureMoveDirectionHorizontal];
    }
}

- (IBAction)levelSliderChannelTwoValueChanged:(UISlider *)sender {
    if ([CSRUtilities belongToTwoChannelDimmer:_device.shortName]) {
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId channel:@3 withLevel:@(sender.value) withState:UIGestureRecognizerStateChanged direction:PanGestureMoveDirectionHorizontal];
        self.levelLabelChannelTwo.text = [NSString stringWithFormat:@"%.f%%",sender.value/255.0*100];
        if (sender.value == 0) {
            [_powerSwitchChannelTwo setOn:NO];
        }else {
            [_powerSwitchChannelTwo setOn:YES];
        }
    }
}

- (IBAction)levelSliderChannelTwoTouchUpInside:(UISlider *)sender {
    if ([CSRUtilities belongToTwoChannelDimmer:_device.shortName]) {
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId channel:@3 withLevel:@(sender.value) withState:UIGestureRecognizerStateEnded direction:PanGestureMoveDirectionHorizontal];
        self.levelLabelChannelTwo.text = [NSString stringWithFormat:@"%.f%%",sender.value/255.0*100];
        if (sender.value == 0) {
            [_powerSwitchChannelTwo setOn:NO];
        }else {
            [_powerSwitchChannelTwo setOn:YES];
        }
    }
}

- (void)delayMethodEndLevelMoving {
    _sliderIsMoving = NO;
}

//调色温
- (IBAction)colorTemperatureSliderTouchDown:(UISlider *)sender {
    if (musicBehavior) {
        if ([SoundListenTool sharedInstance].audioRecorder.recording) {
            [[SoundListenTool sharedInstance] stopRecord:_deviceId];
        }
    }
    [[DeviceModelManager sharedInstance] invalidateColofulTimerWithDeviceId:_deviceId];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayMethodEndColorTemperatureMoving) object:nil];
    _colorTemperatureSliderIsMoving = YES;
    [[DeviceModelManager sharedInstance] setColorTemperatureWithDeviceId:_deviceId withColorTemperature:@(sender.value) withState:UIGestureRecognizerStateBegan];
}

- (IBAction)colorTemperatureSliderValueChanged:(UISlider *)sender {
    [[DeviceModelManager sharedInstance] setColorTemperatureWithDeviceId:_deviceId withColorTemperature:@(sender.value) withState:UIGestureRecognizerStateChanged];
    
    _colorTemperatureLabel.text = [NSString stringWithFormat:@"%.fK",sender.value];
    
    if ([_deviceId integerValue] < 32768) {
        if (!_RGBGroupControllSwitch.on) {
            [_RGBGroupControllSwitch setOn:YES];
            CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:_deviceId];
            CSRDeviceEntity *d = [[area.devices allObjects] objectAtIndex:0];
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:d.deviceId];
            [_levelSlider setValue:[model.level integerValue] animated:YES];
            self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[model.level integerValue]/255.0*100];
        }
    }else if (!_powerStateSwitch.on) {
        [_powerStateSwitch setOn:YES];
        [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
        self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
    }
    
}

- (IBAction)colorTemperatureSliderTouchUpInSide:(UISlider *)sender {
    [self performSelector:@selector(delayMethodEndColorTemperatureMoving) withObject:nil afterDelay:4.0];
    [[DeviceModelManager sharedInstance] setColorTemperatureWithDeviceId:_deviceId withColorTemperature:@(sender.value) withState:UIGestureRecognizerStateEnded];
    
    _colorTemperatureLabel.text = [NSString stringWithFormat:@"%.fK",sender.value];
    
}

- (IBAction)colorTemperatureSliderTouchUpOutSide:(UISlider *)sender {
    [self performSelector:@selector(delayMethodEndColorTemperatureMoving) withObject:nil afterDelay:4.0];
    [[DeviceModelManager sharedInstance] setColorTemperatureWithDeviceId:_deviceId withColorTemperature:@(sender.value) withState:UIGestureRecognizerStateEnded];
    
    _colorTemperatureLabel.text = [NSString stringWithFormat:@"%.fK",sender.value];
    
}

- (void)delayMethodEndColorTemperatureMoving {
    _colorTemperatureSliderIsMoving = NO;
}

//饱和度
- (IBAction)colorSaturationSliderTouchDown:(UISlider *)sender {
    if (musicBehavior) {
        if ([SoundListenTool sharedInstance].audioRecorder.recording) {
            [[SoundListenTool sharedInstance] stopRecord:_deviceId];
        }
    }
    [[DeviceModelManager sharedInstance] invalidateColofulTimerWithDeviceId:_deviceId];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayMethodEndColorSaturationMoving) object:nil];
    _colorSaturationSliderIsMoving = YES;
    UIColor *color = [UIColor colorWithHue:_colorSlider.myValue saturation:sender.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_deviceId withColor:color withState:UIGestureRecognizerStateBegan];
}

- (IBAction)colorSaturationSliderValueChanged:(UISlider *)sender {
    UIColor *color = [UIColor colorWithHue:_colorSlider.myValue saturation:sender.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_deviceId withColor:color withState:UIGestureRecognizerStateChanged];
    
    self.colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value*100];
    [self.colorSquareView locationPickView:_colorSlider.myValue colorSaturation:sender.value];
    
    if ([_deviceId integerValue] < 32768) {
        if (!_RGBGroupControllSwitch.on) {
            [_RGBGroupControllSwitch setOn:YES];
            CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:_deviceId];
            CSRDeviceEntity *d = [[area.devices allObjects] objectAtIndex:0];
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:d.deviceId];
            [_levelSlider setValue:[model.level integerValue] animated:YES];
            self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[model.level integerValue]/255.0*100];
        }
    }else if (!_powerStateSwitch.on) {
        [_powerStateSwitch setOn:YES];
        [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
        self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
    }
}

- (IBAction)colorSaturationSliderTouchUpInSide:(UISlider *)sender {
    [self performSelector:@selector(delayMethodEndColorSaturationMoving) withObject:nil afterDelay:4.0];
    UIColor *color = [UIColor colorWithHue:_colorSlider.myValue saturation:sender.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_deviceId withColor:color withState:UIGestureRecognizerStateEnded];
    
    self.colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value*100];
    [self.colorSquareView locationPickView:_colorSlider.myValue colorSaturation:sender.value];
    
}

- (IBAction)colorSaturationSliderTouchUpOutSide:(UISlider *)sender {
    [self performSelector:@selector(delayMethodEndColorSaturationMoving) withObject:nil afterDelay:4.0];
    UIColor *color = [UIColor colorWithHue:_colorSlider.myValue saturation:sender.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_deviceId withColor:color withState:UIGestureRecognizerStateEnded];
    
    self.colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value*100];
    [self.colorSquareView locationPickView:_colorSlider.myValue colorSaturation:sender.value];
    
}

- (void)delayMethodEndColorSaturationMoving {
    _colorSaturationSliderIsMoving = NO;
}
    
#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    switch (textField.tag) {
        case 11:
            textField.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
            break;
        default:
            break;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    switch (textField.tag) {
        case 11:
            textField.backgroundColor = [UIColor whiteColor];
            break;
        default:
            break;
    }
    
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    switch (textField.tag) {
        case 11:
            [self saveNickName];
            break;
        default:
            break;
    }
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (range.length == 1 && string.length == 0) {
        return YES;
    }else {
        switch (textField.tag) {
            case 12:
                {
                    NSString *aString = [textField.text stringByReplacingCharactersInRange:range withString:string];
                    if ([self validateNumber:string]) {
                        if ([aString integerValue]>63) {
                            return NO;
                        }else {
                            return YES;
                        }
                    }else {
                        return NO;
                    }
                }
                break;
            case 13:
                {
                    NSString *aString = [textField.text stringByReplacingCharactersInRange:range withString:string];
                    if ([self validateNumber:string]) {
                        if ([aString integerValue]>15) {
                            return NO;
                        }else {
                            return YES;
                        }
                    }else {
                        return NO;
                    }
                }
                break;
            case 14:
                {
                    NSString *aString = [textField.text stringByReplacingCharactersInRange:range withString:string];
                    if ([self validateNumber:string]) {
                        if ([aString integerValue]>15) {
                            return NO;
                        }else {
                            return YES;
                        }
                    }else {
                        return NO;
                    }
                }
                break;
            default:
                break;
        }
        return YES;
    }
}

- (BOOL)validateNumber:(NSString*)number {
    BOOL res = YES;
    NSCharacterSet* tmpSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    int i = 0;
    while (i < number.length) {
        NSString * string = [number substringWithRange:NSMakeRange(i, 1)];
        NSRange range = [string rangeOfCharacterFromSet:tmpSet];
        if (range.length == 0) {
            res = NO;
            break;
        }
        i++;
    }
    return res;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    CGPoint pointx = [_scrollView convertPoint:textField.frame.origin fromView:_dalinView];
    CGPoint point = [self.view convertPoint:pointx fromView:_scrollView];
    int offset = point.y + textField.frame.size.height - (self.view.frame.size.height - 256.0);
    NSTimeInterval animaTime = 0.30f;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animaTime];
    if (offset>0) {
        self.view.frame = CGRectMake(0.0f, -offset, self.view.frame.size.width, self.view.frame.size.height);
    }
    [UIView commitAnimations];
}

#pragma mark - 保存修改后的灯名

- (void)saveNickName {
    if (![_nameTF.text isEqualToString:_originalName] && _nameTF.text.length > 0) {
        self.navigationItem.title = _nameTF.text;
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:self.deviceId];
        deviceEntity.name = _nameTF.text;
        [[CSRDatabaseManager sharedInstance] saveContext];
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:self.deviceId];
        model.name = _nameTF.text;
        _originalName = _nameTF.text;
        if (self.reloadDataHandle) {
            self.reloadDataHandle();
        }
    }
    
}

- (IBAction)colorTemperatureChange:(UIButton *)sender {
    [[DataModelManager shareInstance] changeColorTemperature:_deviceId];
    sender.backgroundColor = [UIColor clearColor];
}
- (IBAction)touchUpOutside:(UIButton *)sender {
    sender.backgroundColor = [UIColor colorWithRed:234/255.0 green:184/255.0 blue:63/255.0 alpha:1];
}


- (IBAction)colorTemperatureReset:(UIButton *)sender {
    [[DataModelManager shareInstance] resetColorTemperature:_deviceId];
    sender.backgroundColor = [UIColor clearColor];
}

//设置颜色，自定义滑动条代理方法
- (void)colorSliderValueChanged:(CGFloat)myValue withState:(UIGestureRecognizerState)state{
    if (state == UIGestureRecognizerStateBegan) {
        if (musicBehavior) {
            if ([SoundListenTool sharedInstance].audioRecorder.recording) {
                [[SoundListenTool sharedInstance] stopRecord:_deviceId];
            }
        }
        [[DeviceModelManager sharedInstance] invalidateColofulTimerWithDeviceId:_deviceId];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayMethodEndColorSliderMoving) object:nil];
        _colorSliderIsMoving = YES;
    }else if (state == UIGestureRecognizerStateEnded) {
        [self performSelector:@selector(delayMethodEndColorSliderMoving) withObject:nil afterDelay:4.0f];
    }
    UIColor *color = [UIColor colorWithHue:myValue saturation:_colorSaturationSlider.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_deviceId withColor:color withState:state];
    
    self.colorLabel.text = [NSString stringWithFormat:@"%.f",myValue*360];
    [self.colorSquareView locationPickView:myValue colorSaturation:_colorSaturationSlider.value];
    
    if ([_deviceId integerValue] < 32768) {
        if (!_RGBGroupControllSwitch.on) {
            [_RGBGroupControllSwitch setOn:YES];
            CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:_deviceId];
            CSRDeviceEntity *d = [[area.devices allObjects] objectAtIndex:0];
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:d.deviceId];
            [_levelSlider setValue:[model.level integerValue] animated:YES];
            self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[model.level integerValue]/255.0*100];
        }
    }else if (!_powerStateSwitch.on) {
        [_powerStateSwitch setOn:YES];
        [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
        self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
    }
    
}

- (void)delayMethodEndColorSliderMoving {
    _colorSliderIsMoving = NO;
}

//设置颜色，颜色图的代理方法
- (void)tapColorChangeWithHue:(CGFloat)hue colorSaturation:(CGFloat)colorSatutation {
    if (musicBehavior) {
        if ([SoundListenTool sharedInstance].audioRecorder.recording) {
            [[SoundListenTool sharedInstance] stopRecord:_deviceId];
        }
    }
    [[DeviceModelManager sharedInstance] invalidateColofulTimerWithDeviceId:_deviceId];
    UIColor *color = [UIColor colorWithHue:hue saturation:colorSatutation brightness:1.0 alpha:1.0];
    [[LightModelApi sharedInstance] setColor:_deviceId color:color duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
        
    } failure:^(NSError * _Nullable error) {
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        model.isleave = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":_deviceId}];
    }];
    
    self.colorLabel.text = [NSString stringWithFormat:@"%.f",hue*360];
    [self.colorSlider sliderMyValue:hue];
    self.colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",colorSatutation*100];
    [self.colorSaturationSlider setValue:colorSatutation animated:YES];
    
    if ([_deviceId integerValue] < 32768) {
        if (!_RGBGroupControllSwitch.on) {
            [_RGBGroupControllSwitch setOn:YES];
            CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:_deviceId];
            CSRDeviceEntity *d = [[area.devices allObjects] objectAtIndex:0];
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:d.deviceId];
            [_levelSlider setValue:[model.level integerValue] animated:YES];
            self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[model.level integerValue]/255.0*100];
        }
    }else if (!_powerStateSwitch.on) {
        [_powerStateSwitch setOn:YES];
        [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
        self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
    }
}

- (void)panColorChangeWithHue:(CGFloat)hue colorSaturation:(CGFloat)colorSatutation state:(UIGestureRecognizerState)state {
    if (state == UIGestureRecognizerStateBegan) {
        if (musicBehavior) {
            if ([SoundListenTool sharedInstance].audioRecorder.recording) {
                [[SoundListenTool sharedInstance] stopRecord:_deviceId];
            }
        }
        [[DeviceModelManager sharedInstance] invalidateColofulTimerWithDeviceId:_deviceId];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayMethodEndColorSquareMoving) object:nil];
        _colorSquareIsMoving = YES;
    }else if (state == UIGestureRecognizerStateEnded) {
        [self performSelector:@selector(delayMethodEndColorSquareMoving) withObject:nil afterDelay:4.0];
    }
    UIColor *color = [UIColor colorWithHue:hue saturation:colorSatutation brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_deviceId withColor:color withState:state];
    
    self.colorLabel.text = [NSString stringWithFormat:@"%.f",hue*360];
    [self.colorSlider sliderMyValue:hue];
    self.colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",colorSatutation*100];
    [self.colorSaturationSlider setValue:colorSatutation animated:YES];
    
    if ([_deviceId integerValue] < 32768) {
        if (!_RGBGroupControllSwitch.on) {
            [_RGBGroupControllSwitch setOn:YES];
            CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:_deviceId];
            CSRDeviceEntity *d = [[area.devices allObjects] objectAtIndex:0];
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:d.deviceId];
            [_levelSlider setValue:[model.level integerValue] animated:YES];
            self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[model.level integerValue]/255.0*100];
        }
    }else if (!_powerStateSwitch.on) {
        [_powerStateSwitch setOn:YES];
        [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
        self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
    }
}

- (void)delayMethodEndColorSquareMoving {
    _colorSquareIsMoving = NO;
}

- (void)languageChange:(id)sender {
    if (self.isViewLoaded && !self.view.window) {
        self.view = nil;
    }
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

- (IBAction)daliAdressSelectAction:(UIButton *)sender {
    sender.selected = YES;
    switch (sender.tag) {
        case 1:
            if (_daliGroupSelectBtn.selected) {
                _daliGroupSelectBtn.selected = NO;
            }else if (_daliAddressBtn.selected) {
                _daliAddressBtn.selected = NO;
            }else if (_daliSceneSelectBtn.selected) {
                _daliSceneSelectBtn.selected = NO;
            }
            [self showWaitingHud];
            [self performSelector:@selector(hideWaitingHudDelayMethod) withObject:nil afterDelay:10.0];
            [[DataModelManager shareInstance] sendCmdData:@"ea520101ff" toDeviceId:_deviceId];
            break;
        case 2:
            if (_daliAllSelectBtn.selected) {
                _daliAllSelectBtn.selected = NO;
            }else if (_daliGroupSelectBtn.selected) {
                _daliGroupSelectBtn.selected = NO;
            }else if (_daliSceneSelectBtn.selected) {
                _daliSceneSelectBtn.selected = NO;
            }
            [self showDaliAdressInputAlert:sender.tag];
            break;
        case 3:
            if (_daliAddressBtn.selected) {
                _daliAddressBtn.selected = NO;
            }else if (_daliAllSelectBtn.selected) {
                _daliAllSelectBtn.selected = NO;
            }else if (_daliSceneSelectBtn.selected) {
                _daliSceneSelectBtn.selected = NO;
            }
            [self showDaliAdressInputAlert:sender.tag];
            break;
        case 4:
            if (_daliAllSelectBtn.selected) {
                _daliAllSelectBtn.selected = NO;
            }else if (_daliAddressBtn.selected) {
                _daliAddressBtn.selected = NO;
            }else if (_daliGroupSelectBtn.selected) {
                _daliGroupSelectBtn.selected = NO;
            }
            [self showDaliAdressInputAlert:sender.tag];
            break;
        default:
            break;
    }
    
}

- (void)showDaliAdressInputAlert:(NSInteger)type {
    NSString *message = @"";
    if (type == 2) {
        message = @"Please enter the address(0~63) of the device.";
    }else if (type == 3) {
        message = @"Please enter the address(0~15) of the group.";
    }else if (type == 4) {
        message = @"Please enter the number(0~15) of the scene.";
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        if (deviceEntity.remoteBranch && [deviceEntity.remoteBranch length]>0) {
            [self configDaliAppearance:[CSRUtilities numberWithHexString:deviceEntity.remoteBranch]];
        }
    }];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Save", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *tf = alert.textFields.firstObject;
        if (tf.tag == 12) {
            if ([tf.text length]>0 && [tf.text integerValue]<=63) {
                [self showWaitingHud];
                [self performSelector:@selector(hideWaitingHudDelayMethod) withObject:nil afterDelay:10.0];
                [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"ea520101%@",[CSRUtilities stringWithHexNumber:[tf.text integerValue]]] toDeviceId:_deviceId];
            }
        }else if (tf.tag == 13) {
            if ([tf.text length]>0 && [tf.text integerValue]<=15) {
                [self showWaitingHud];
                [self performSelector:@selector(hideWaitingHudDelayMethod) withObject:nil afterDelay:10.0];
                [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"ea520101%@",[CSRUtilities stringWithHexNumber:[tf.text integerValue] + 64]] toDeviceId:_deviceId];
            }
        }else if (tf.tag == 14) {
            if ([tf.text length]>0 && [tf.text integerValue]<=15) {
                [self showWaitingHud];
                [self performSelector:@selector(hideWaitingHudDelayMethod) withObject:nil afterDelay:10.0];
                [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"ea520101%@",[CSRUtilities stringWithHexNumber:[tf.text integerValue] + 80]] toDeviceId:_deviceId];
            }
        }
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.delegate = self;
        textField.textAlignment = NSTextAlignmentCenter;
        if (type == 2) {
            textField.tag = 12;
        }else if (type == 3) {
            textField.tag = 13;
        }else if (type == 4) {
            textField.tag = 14;
        }
    }];
    [alert addAction:cancel];
    [alert addAction:confirm];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)getDaliAdress:(NSNotification *)notification {
    NSDictionary *userDic = notification.userInfo;
    NSNumber *infoDeviceId = userDic[@"deviceId"];
    if ([infoDeviceId isEqualToNumber:_deviceId]) {
        NSInteger address = [CSRUtilities numberWithHexString:userDic[@"addressStr"]];
        [self configDaliAppearance:address];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideWaitingHudDelayMethod) object:nil];
        [self hideWaitingHud];
    }
}

- (void)configDaliAppearance:(NSInteger)address {
    if (address == 255) {
        _daliAllSelectBtn.selected = YES;
        _daliGroupSelectBtn.selected = NO;
        _daliGroupLab.text = nil;
        _daliAddressBtn.selected = NO;
        _daliDeviceLab.text = nil;
        _daliSceneSelectBtn.selected = NO;
        _daliSceneLab.text = nil;
    }else if (address >= 64 && address <= 79) {
        _daliAllSelectBtn.selected = NO;
        _daliGroupSelectBtn.selected = YES;
        _daliGroupLab.text = [NSString stringWithFormat:@"%ld",address-64];
        _daliAddressBtn.selected = NO;
        _daliDeviceLab.text = nil;
        _daliSceneSelectBtn.selected = NO;
        _daliSceneLab.text = nil;
    }else if (address < 64){
        _daliAllSelectBtn.selected = NO;
        _daliGroupSelectBtn.selected = NO;
        _daliGroupLab.text = nil;
        _daliAddressBtn.selected = YES;
        _daliDeviceLab.text = [NSString stringWithFormat:@"%ld",(long)address];
        _daliSceneSelectBtn.selected = NO;
        _daliSceneLab.text = nil;
    }else if (address > 79 && address <= 95) {
        _daliAllSelectBtn.selected = NO;
        _daliGroupSelectBtn.selected = NO;
        _daliGroupLab.text = nil;
        _daliAddressBtn.selected = NO;
        _daliDeviceLab.text = nil;
        _daliSceneSelectBtn.selected = YES;
        _daliSceneLab.text = [NSString stringWithFormat:@"%ld",address-80];
    }
}

- (void)showWaitingHud {
    if (self.waitingHud) {
        self.waitingHud = nil;
    }
    self.waitingHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.waitingHud showAnimated:YES];
    self.waitingHud.delegate = self;
}

-(void)hideWaitingHudDelayMethod {
    if (self.waitingHud) {
        [self.waitingHud hideAnimated:YES];
        self.waitingHud = nil;
        [self showTextHud:@"Time out"];
    }
}

- (void)hideWaitingHud {
    if (self.waitingHud) {
        [self.waitingHud hideAnimated:YES];
        self.waitingHud = nil;
        [self showTextHud:@"SUCCESS"];
    }
}

- (void)getGanjiedianModel:(NSNotification *)notification {
    NSDictionary *userDic = notification.userInfo;
    NSString *stateStr = userDic[@"state"];
    NSNumber *sourceDeviceId = userDic[@"deviceId"];
    if ([sourceDeviceId isEqualToNumber:_deviceId]) {
        if ([stateStr isEqualToString:@"00"]) {
            _pulseModeLabel.text = AcTECLocalizedStringFromTable(@"onoffmode", @"Localizable");
//            _switchModelBtn.selected = YES;
//            [_switchModelBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
//            _oneSecondModelBtn.selected = NO;
//            [_oneSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
//            _sixSecondModelBtn.selected = NO;
//            [_sixSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
//            _nineSecondModelBtn.selected = NO;
//            [_nineSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        }else if ([stateStr isEqualToString:@"01"]) {
            _pulseModeLabel.text = AcTECLocalizedStringFromTable(@"pulsewidth1", @"Localizable");
//            _switchModelBtn.selected = NO;
//            [_switchModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
//            _oneSecondModelBtn.selected = YES;
//            [_oneSecondModelBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
//            _sixSecondModelBtn.selected = NO;
//            [_sixSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
//            _nineSecondModelBtn.selected = NO;
//            [_nineSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        }else if ([stateStr isEqualToString:@"06"]) {
            _pulseModeLabel.text = AcTECLocalizedStringFromTable(@"pulsewidth6", @"Localizable");
//            _switchModelBtn.selected = NO;
//            [_switchModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
//            _oneSecondModelBtn.selected = NO;
//            [_oneSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
//            _sixSecondModelBtn.selected = YES;
//            [_sixSecondModelBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
//            _nineSecondModelBtn.selected = NO;
//            [_nineSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        }else if ([stateStr isEqualToString:@"09"]) {
            _pulseModeLabel.text = AcTECLocalizedStringFromTable(@"pulsewidth9", @"Localizable");
//            _switchModelBtn.selected = NO;
//            [_switchModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
//            _oneSecondModelBtn.selected = NO;
//            [_oneSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
//            _sixSecondModelBtn.selected = NO;
//            [_sixSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
//            _nineSecondModelBtn.selected = YES;
//            [_nineSecondModelBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
        }
    }
}
- (IBAction)ganjiedianSelectAction:(UIButton *)sender {
    if (sender.selected) {
        return;
    }
    sender.selected = YES;
    UIImage *image = [UIImage imageNamed:@"Be_selected"];
    [sender setImage:image forState:UIControlStateNormal];
    switch (sender.tag) {
        case 1:
            if (sender.selected) {
                if (_oneSecondModelBtn.selected) {
                    _oneSecondModelBtn.selected = NO;
                    [_oneSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }else if (_sixSecondModelBtn.selected) {
                    _sixSecondModelBtn.selected = NO;
                    [_sixSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }else if (_nineSecondModelBtn.selected) {
                    _nineSecondModelBtn.selected = NO;
                    [_nineSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }
                [[DataModelManager shareInstance] sendCmdData:@"ea7200" toDeviceId:_deviceId];
            }
            break;
        case 2:
            if (sender.selected) {
                if (_switchModelBtn.selected) {
                    _switchModelBtn.selected = NO;
                    [_switchModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }else if (_sixSecondModelBtn.selected) {
                    _sixSecondModelBtn.selected = NO;
                    [_sixSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }else if (_nineSecondModelBtn.selected) {
                    _nineSecondModelBtn.selected = NO;
                    [_nineSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }
                [[DataModelManager shareInstance] sendCmdData:@"ea7201" toDeviceId:_deviceId];
            }
            break;
        case 3:
            if (sender.selected) {
                if (_oneSecondModelBtn.selected) {
                    _oneSecondModelBtn.selected = NO;
                    [_oneSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }else if (_switchModelBtn.selected) {
                    _switchModelBtn.selected = NO;
                    [_switchModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }else if (_nineSecondModelBtn.selected) {
                    _nineSecondModelBtn.selected = NO;
                    [_nineSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }
                [[DataModelManager shareInstance] sendCmdData:@"ea7206" toDeviceId:_deviceId];
            }
            break;
        case 4:
            if (sender.selected) {
                if (_oneSecondModelBtn.selected) {
                    _oneSecondModelBtn.selected = NO;
                    [_oneSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }else if (_sixSecondModelBtn.selected) {
                    _sixSecondModelBtn.selected = NO;
                    [_sixSecondModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }else if (_switchModelBtn.selected) {
                    _switchModelBtn.selected = NO;
                    [_switchModelBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }
                [[DataModelManager shareInstance] sendCmdData:@"ea7209" toDeviceId:_deviceId];
            }
            break;
        default:
            break;
    }
}

- (IBAction)ganjiedianRowTapAction:(UIButton *)sender {
    if (!_ganjiedianCustomView.superview) {
        _ganjiedianCustomView.layer.borderWidth = 2;
        _ganjiedianCustomView.layer.borderColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0].CGColor;
        _ganjiedianCustomView.frame = CGRectMake(WIDTH-200.0, _ganjiedianRowView.frame.origin.y-134.0, 200.0, 179.0);
        [_scrollView addSubview:_ganjiedianCustomView];
        [_scrollView sendSubviewToBack:_ganjiedianCustomView];
        
        [UIView beginAnimations:@"ganjiedianCustomViewAnimation" context:nil];
        [UIView setAnimationsEnabled:YES];
        [UIView setAnimationDuration:0.5];
        _dropDownImageView.transform = CGAffineTransformMakeRotation(M_PI/2);
        _ganjiedianCustomView.frame = CGRectMake(WIDTH-179.0, _ganjiedianRowView.frame.origin.y+45.0, 200.0, 179.0);
        [UIView commitAnimations];
    }else {
        [UIView beginAnimations:@"ganjiedianCustomViewBackAnimation" context:nil];
        [UIView setAnimationsEnabled:YES];
        [UIView setAnimationDuration:0.5];
        _dropDownImageView.transform = CGAffineTransformIdentity;
        _ganjiedianCustomView.frame = CGRectMake(WIDTH-179.0, _ganjiedianRowView.frame.origin.y-134.0, 200.0, 179.0);
        [UIView commitAnimations];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_ganjiedianCustomView removeFromSuperview];
        });
    }
}

- (IBAction)selectPulseWidthAction:(UIButton *)sender {
    [UIView beginAnimations:@"ganjiedianCustomViewBackAnimation" context:nil];
    [UIView setAnimationsEnabled:YES];
    [UIView setAnimationDuration:0.5];
    _dropDownImageView.transform = CGAffineTransformIdentity;
    _ganjiedianCustomView.frame = CGRectMake(WIDTH-179.0, _ganjiedianRowView.frame.origin.y-134.0, 200.0, 179.0);
    [UIView commitAnimations];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_ganjiedianCustomView removeFromSuperview];
    });
    
    switch (sender.tag) {
        case 1:
            [[DataModelManager shareInstance] sendCmdData:@"ea7200" toDeviceId:_deviceId];
            break;
        case 2:
            [[DataModelManager shareInstance] sendCmdData:@"ea7201" toDeviceId:_deviceId];
            break;
        case 3:
            [[DataModelManager shareInstance] sendCmdData:@"ea7206" toDeviceId:_deviceId];
            break;
        case 4:
            [[DataModelManager shareInstance] sendCmdData:@"ea7209" toDeviceId:_deviceId];
            break;
        default:
            break;
    }
    
}

- (UIView *)translucentBgView {
    if (!_translucentBgView) {
        _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _translucentBgView.backgroundColor = [UIColor blackColor];
        _translucentBgView.alpha = 0.4;
    }
    return _translucentBgView;
}

- (void)timerMethod:(NSTimer *)timer {
    [[DataModelManager shareInstance]sendCmdData:@"ea4401" toDeviceId:_deviceId];
}

- (void)socketPowerCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        NSNumber *channel = dic[@"channel"];
        if ([channel integerValue]==1) {
            NSNumber *power1 = dic[@"power1"];
            _currentPower1Label.text = [NSString stringWithFormat:@"%.1fW",[power1 floatValue]];
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

- (IBAction)clearAction:(UIButton *)sender {
    [[DataModelManager shareInstance]sendCmdData:@"ea4601" toDeviceId:_deviceId];
}

- (void)clearSocketPower:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        BOOL state = [dic[@"state"] boolValue];
        NSString *stateStr = state? @"成功":@"失败";
        [self showTextHud:[NSString stringWithFormat:@"电量数据清除%@",stateStr]];
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
        if ([channel isEqualToString:@"01"]) {
            _abnormalImageView.image = [UIImage imageNamed:@"abnormal"];
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
            [_thresholdSwitch setOn:enable];
            _thresholdLab.text = [NSString stringWithFormat:@"%ld",(long)pvalue];
        }
    }
}

- (IBAction)thresholdEnableSwitch:(UISwitch *)sender {
    if ([_thresholdLab.text length]>0 && [_thresholdLab.text integerValue]>=2 && [_thresholdLab.text integerValue]<=20) {
        [[DataModelManager shareInstance]sendCmdData:[NSString stringWithFormat:@"ea47010%d%@",sender.on,[CSRUtilities stringWithHexNumber:[_thresholdLab.text integerValue]]] toDeviceId:_deviceId];
    }else {
        [[DataModelManager shareInstance]sendCmdData:[NSString stringWithFormat:@"ea47010%d02",sender.on] toDeviceId:_deviceId];
    }
}

- (IBAction)thresholdValueChangeBtn:(UIButton *)sender {
    BOOL enable = YES;
    NSString *Pvalue = @"2";
    switch (sender.tag) {
        case 11:
            enable = _thresholdSwitch.on;
            if ([_thresholdLab.text length]>0) {
                if ([_thresholdLab.text integerValue]>20){
                    Pvalue = @"20";
                }else if ([_thresholdLab.text integerValue]>2 && [_thresholdLab.text integerValue]<=20) {
                    Pvalue = [NSString stringWithFormat:@"%ld",[_thresholdLab.text integerValue]-1];
                }
            }
            break;
        case 12:
            enable = _thresholdSwitch.on;
            if ([_thresholdLab.text length]>0) {
                if ([_thresholdLab.text integerValue]>=20) {
                    Pvalue = @"20";
                }else if ([_thresholdLab.text integerValue]>=2 && [_thresholdLab.text integerValue]<20) {
                    Pvalue = [NSString stringWithFormat:@"%ld",[_thresholdLab.text integerValue]+1];
                }
            }
            break;
        default:
            break;
    }
    [[DataModelManager shareInstance]sendCmdData:[NSString stringWithFormat:@"ea47010%d%@",enable,[CSRUtilities stringWithHexNumber:[Pvalue integerValue]]] toDeviceId:_deviceId];
}

- (void)forRGBGroupControllerAddSwitchView {
    [_scrollView addSubview:_RGBGroupControllSwitchView];
    [_RGBGroupControllSwitchView autoSetDimension:ALDimensionHeight toSize:44.0];
    [_RGBGroupControllSwitchView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [_RGBGroupControllSwitchView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_RGBGroupControllSwitchView autoAlignAxisToSuperviewAxis:ALAxisVertical];
}

- (void)forRGBGroupControllerAddBrightnessView {
    [_scrollView addSubview:_brightnessTitle];
    [_brightnessTitle autoSetDimension:ALDimensionHeight toSize:20];
    [_brightnessTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_RGBGroupControllSwitchView withOffset:5];
    [_brightnessTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [_brightnessTitle autoSetDimension:ALDimensionWidth toSize:120];
    
    [_scrollView addSubview:_brightnessView];
    [_brightnessView autoSetDimension:ALDimensionHeight toSize:44];
    [_brightnessView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_brightnessTitle withOffset:5];
    [_brightnessView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_brightnessView autoAlignAxisToSuperviewAxis:ALAxisVertical];
}

- (void)forRGBGroupControllAdustInterface {
    CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:_deviceId];
    __block NSInteger brightness = 0;
    [area.devices enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, BOOL * _Nonnull stop) {
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceEntity.deviceId];
        if ([model.powerState boolValue] && [model.level integerValue]>brightness && !model.isleave) {
            brightness = [model.level integerValue];
        }
    }];
    if (brightness) {
        [_RGBGroupControllSwitch setOn:YES];
        if (!_sliderIsMoving) {
            [_levelSlider setValue:brightness animated:YES];
            self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",brightness/255.0*100];
        }
        
    }else {
        [_RGBGroupControllSwitch setOn:NO];
        [_levelSlider setValue:0 animated:YES];
        self.levelLabel.text = @"0%";
    }
    CSRDeviceEntity *lastDevice = [[area.devices allObjects] lastObject];
    DeviceModel *lastModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:lastDevice.deviceId];
    if (!_colorTemperatureSliderIsMoving) {
        [_colorTemperatureSlider setValue:(CGFloat)[lastModel.colorTemperature integerValue] animated:YES];
    }
    _colorTemperatureLabel.text = [NSString stringWithFormat:@"%ldK",(long)[lastModel.colorTemperature integerValue]];
    UIColor *color = [UIColor colorWithRed:[lastModel.red integerValue]/255.0 green:[lastModel.green integerValue]/255.0 blue:[lastModel.blue integerValue]/255.0 alpha:1.0];
    CGFloat hue,saturation,level,alpha;
    if ([color getHue:&hue saturation:&saturation brightness:&level alpha:&alpha]) {
        if (!_colorSliderIsMoving) {
            [self.colorSlider sliderMyValue:hue];
        }
        self.colorLabel.text = [NSString stringWithFormat:@"%.f",hue*360];
        if (!_colorSaturationSliderIsMoving) {
            [self.colorSaturationSlider setValue:saturation animated:YES];
        }
        self.colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",saturation*100];
        if (!_colorSquareIsMoving) {
            [self.colorSquareView locationPickView:hue colorSaturation:saturation];
        }
    }
}

@end
