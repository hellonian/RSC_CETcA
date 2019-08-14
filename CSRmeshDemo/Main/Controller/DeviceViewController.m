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

@interface DeviceViewController ()<UITextFieldDelegate,ColorSliderDelegate,ColorSquareDelegate,MBProgressHUDDelegate,MCUUpdateToolDelegate>
{
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
    BOOL musicBehavior;
    UIButton *updateMCUBtn;
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
@property (weak, nonatomic) IBOutlet UITextField *daliGroupTF;
@property (weak, nonatomic) IBOutlet UITextField *daliAddressTF;
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
    
    [_scrollView addSubview:_topView];
    [_topView autoSetDimension:ALDimensionHeight toSize:134];
    [_topView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [_topView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_topView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
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
    
    if (_deviceId) {
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
                _scrollView.contentSize = CGSizeMake(1, 253+20+45);
                
            }else {
                _scrollView.contentSize = CGSizeMake(1, 134+20);
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
                
                _scrollView.contentSize = CGSizeMake(1, 327+20);
            }else if ([_device.shortName isEqualToString:@"DDSB"]) {
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(getDaliAdress:)
                                                             name:@"getDaliAdress"
                                                           object:nil];
                [[DataModelManager shareInstance] sendCmdData:@"ea520102" toDeviceId:_deviceId];
                [self addSubviewDalinView];
                _scrollView.contentSize = CGSizeMake(1, 208+20+20+220);
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                if (deviceEntity.remoteBranch && [deviceEntity.remoteBranch length]>0) {
                    [self configDaliAppearance:[CSRUtilities numberWithHexString:deviceEntity.remoteBranch]];
                }
            }else {
                _scrollView.contentSize = CGSizeMake(1, 208+20);
            }
        }
        
        else if ([CSRUtilities belongToCWDevice:_device.shortName]) {
            [self addSubviewBrightnessView];
            [self addSubViewColorTemperatuteView];
            _scrollView.contentSize = CGSizeMake(1, 282+20);
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
            
            _scrollView.contentSize = CGSizeMake(1, 616);
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
            _scrollView.contentSize = CGSizeMake(1, 650);
        }
        
        self.navigationItem.title = _device.name;
        self.nameTF.text = _device.name;
        self.originalName = _device.name;
        self.powerStateSwitch.on = [_device.powerState boolValue];
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
                NSLog(@"%@  %ld",deviceEntity.mcuSVersion,latestMCUSVersion);
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

- (void)hideUpdateHud {
    if (_updatingHud) {
        [_updatingHud hideAnimated:YES];
        [self.translucentBgView removeFromSuperview];
        self.translucentBgView = nil;
        [updateMCUBtn removeFromSuperview];
        updateMCUBtn = nil;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.view layoutIfNeeded];
    [self adjustInterface];
}

- (void)addSubviewBrightnessView {
    [_scrollView addSubview:_brightnessTitle];
    [_brightnessTitle autoSetDimension:ALDimensionHeight toSize:20];
    [_brightnessTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_topView withOffset:5];
    [_brightnessTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [_brightnessTitle autoSetDimension:ALDimensionWidth toSize:120];
    
    [_scrollView addSubview:_brightnessView];
    [_brightnessView autoSetDimension:ALDimensionHeight toSize:44];
    [_brightnessView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_brightnessTitle withOffset:5];
    [_brightnessView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_brightnessView autoAlignAxisToSuperviewAxis:ALAxisVertical];
}

- (void)addSubviewDalinView {
    _daliGroupTF.delegate = self;
    _daliAddressTF.delegate = self;
    [_scrollView addSubview:_dalinView];
    [_dalinView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_brightnessView withOffset:20.0];
    [_dalinView autoSetDimension:ALDimensionHeight toSize:220.0];
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



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setPowerStateSuccess:)
                                                 name:@"setPowerStateSuccess"
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"setPowerStateSuccess"
                                                  object:nil];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)adjustInterface {
    if ([CSRUtilities belongToSwitch:_device.shortName]) {
        if ([_device.powerState boolValue]) {
            [self.powerStateSwitch setOn:YES];
        }else {
            [self.powerStateSwitch setOn:NO];
        }
        return;
    }
    if ([CSRUtilities belongToDimmer:_device.shortName]) {
        if ([_device.powerState boolValue]) {
            [self.powerStateSwitch setOn:YES];
            if (!_sliderIsMoving) {
                [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
            }
            self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
        }else {
            [self.powerStateSwitch setOn:NO];
            [self.levelSlider setValue:0 animated:YES];
            self.levelLabel.text = @"0%";
        }
        return;
    }
    
    if ([CSRUtilities belongToCWDevice:_device.shortName]) {
        if ([_device.powerState boolValue]) {
            [self.powerStateSwitch setOn:YES];
            if (!_sliderIsMoving) {
                [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
            }
            self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
        }else {
            [self.powerStateSwitch setOn:NO];
            [self.levelSlider setValue:0 animated:YES];
            self.levelLabel.text = @"0%";
        }
        if (!_colorTemperatureSliderIsMoving) {
            [_colorTemperatureSlider setValue:(CGFloat)[_device.colorTemperature integerValue] animated:YES];
        }
        _colorTemperatureLabel.text = [NSString stringWithFormat:@"%ldK",(long)[_device.colorTemperature integerValue]];
        return;
    }
    
    if ([CSRUtilities belongToRGBDevice:_device.shortName]) {
        if ([_device.powerState boolValue]) {
            [self.powerStateSwitch setOn:YES];
            if (!_sliderIsMoving) {
                [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
            }
            self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
        }else {
            [self.powerStateSwitch setOn:NO];
            [self.levelSlider setValue:0 animated:YES];
            self.levelLabel.text = @"0%";
        }
        UIColor *color = [UIColor colorWithRed:[_device.red integerValue]/255.0 green:[_device.green integerValue]/255.0 blue:[_device.blue integerValue]/255.0 alpha:1.0];
        CGFloat hue,saturation,brightness,alpha;
        if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
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
        return;
    }
    
    if ([CSRUtilities belongToRGBCWDevice:_device.shortName]) {
        if ([_device.powerState boolValue]) {
            [self.powerStateSwitch setOn:YES];
            if (!_sliderIsMoving) {
                [self.levelSlider setValue:(CGFloat)[_device.level integerValue] animated:YES];
            }
            self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_device.level integerValue]/255.0*100];
        }else {
            [self.powerStateSwitch setOn:NO];
            [self.levelSlider setValue:0 animated:YES];
            self.levelLabel.text = @"0%";
        }
//        if ([_device.supports integerValue]==1) {
            if (!_colorTemperatureSliderIsMoving) {
                [_colorTemperatureSlider setValue:(CGFloat)[_device.colorTemperature integerValue] animated:YES];
            }
        _colorTemperatureLabel.text = [NSString stringWithFormat:@"%ldK",(long)[_device.colorTemperature integerValue]];
//        }
//        if ([_device.supports integerValue]==0) {
            UIColor *color = [UIColor colorWithRed:[_device.red integerValue]/255.0 green:[_device.green integerValue]/255.0 blue:[_device.blue integerValue]/255.0 alpha:1.0];
            CGFloat hue,saturation,brightness,alpha;
            if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
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
//        }
        
        return;
    }
}

- (void)setPowerStateSuccess:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        [self adjustInterface];
    }
}
//开关
- (IBAction)powerStateSwitch:(UISwitch *)sender {
    if (musicBehavior) {
        if ([SoundListenTool sharedInstance].audioRecorder.recording) {
            [[SoundListenTool sharedInstance] stopRecord:_deviceId];
        }
    }
    [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId withPowerState:@(sender.on)];
}
//调光
- (IBAction)levelSliderTouchUpInSide:(UISlider *)sender {
    _sliderIsMoving = NO;
    [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId withLevel:@(sender.value) withState:UIGestureRecognizerStateEnded direction:PanGestureMoveDirectionHorizontal];
}

- (IBAction)leveSliderValueChanged:(UISlider *)sender {
    [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId withLevel:@(sender.value) withState:UIGestureRecognizerStateChanged direction:PanGestureMoveDirectionHorizontal];
}

- (IBAction)levelSliderTouchDown:(UISlider *)sender {
    if (musicBehavior) {
        if ([SoundListenTool sharedInstance].audioRecorder.recording) {
            [[SoundListenTool sharedInstance] stopRecord:_deviceId];
        }
    }
    _sliderIsMoving = YES;
    [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId withLevel:@(sender.value) withState:UIGestureRecognizerStateBegan direction:PanGestureMoveDirectionHorizontal];
}

- (IBAction)levelSliderTouchUpOutSide:(UISlider *)sender {
    _sliderIsMoving = NO;
    [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId withLevel:@(sender.value) withState:UIGestureRecognizerStateEnded direction:PanGestureMoveDirectionHorizontal];
}
//调色温
- (IBAction)colorTemperatureSliderTouchDown:(UISlider *)sender {
    if (musicBehavior) {
        if ([SoundListenTool sharedInstance].audioRecorder.recording) {
            [[SoundListenTool sharedInstance] stopRecord:_deviceId];
        }
    }
    _colorTemperatureSliderIsMoving = YES;
    [[DeviceModelManager sharedInstance] setColorTemperatureWithDeviceId:_deviceId withColorTemperature:@(sender.value) withState:UIGestureRecognizerStateBegan];
}

- (IBAction)colorTemperatureSliderValueChanged:(UISlider *)sender {
    [[DeviceModelManager sharedInstance] setColorTemperatureWithDeviceId:_deviceId withColorTemperature:@(sender.value) withState:UIGestureRecognizerStateChanged];
}

- (IBAction)colorTemperatureSliderTouchUpInSide:(UISlider *)sender {
    _colorTemperatureSliderIsMoving = NO;
    [[DeviceModelManager sharedInstance] setColorTemperatureWithDeviceId:_deviceId withColorTemperature:@(sender.value) withState:UIGestureRecognizerStateEnded];
}

- (IBAction)colorTemperatureSliderTouchUpOutSide:(UISlider *)sender {
    _colorTemperatureSliderIsMoving = NO;
    [[DeviceModelManager sharedInstance] setColorTemperatureWithDeviceId:_deviceId withColorTemperature:@(sender.value) withState:UIGestureRecognizerStateEnded];
}

//饱和度
- (IBAction)colorSaturationSliderTouchDown:(UISlider *)sender {
    if (musicBehavior) {
        if ([SoundListenTool sharedInstance].audioRecorder.recording) {
            [[SoundListenTool sharedInstance] stopRecord:_deviceId];
        }
    }
    _colorSaturationSliderIsMoving = YES;
    UIColor *color = [UIColor colorWithHue:_colorSlider.myValue saturation:sender.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_deviceId withColor:color withState:UIGestureRecognizerStateBegan];
}

- (IBAction)colorSaturationSliderValueChanged:(UISlider *)sender {
    UIColor *color = [UIColor colorWithHue:_colorSlider.myValue saturation:sender.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_deviceId withColor:color withState:UIGestureRecognizerStateChanged];
}

- (IBAction)colorSaturationSliderTouchUpInSide:(UISlider *)sender {
    _colorSaturationSliderIsMoving = NO;
    UIColor *color = [UIColor colorWithHue:_colorSlider.myValue saturation:sender.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_deviceId withColor:color withState:UIGestureRecognizerStateEnded];
}

- (IBAction)colorSaturationSliderTouchUpOutSide:(UISlider *)sender {
    _colorSaturationSliderIsMoving = NO;
    UIColor *color = [UIColor colorWithHue:_colorSlider.myValue saturation:sender.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_deviceId withColor:color withState:UIGestureRecognizerStateEnded];
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
        case 12:
            if ([textField.text length]>0 && [textField.text integerValue]<=15) {
                [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"ea520101%@",[CSRUtilities stringWithHexNumber:[textField.text integerValue] + 64]] toDeviceId:_deviceId];
            }
            break;
        case 13:
            if ([textField.text length]>0 && [textField.text integerValue]<=63) {
                [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"ea520101%@",[CSRUtilities stringWithHexNumber:[textField.text integerValue]]] toDeviceId:_deviceId];
            }
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
            case 13:
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
        _colorSliderIsMoving = YES;
    }else if (state == UIGestureRecognizerStateEnded) {
        _colorSliderIsMoving = NO;
    }
    UIColor *color = [UIColor colorWithHue:myValue saturation:_colorSaturationSlider.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_deviceId withColor:color withState:state];
}

//设置颜色，颜色图的代理方法
- (void)tapColorChangeWithHue:(CGFloat)hue colorSaturation:(CGFloat)colorSatutation {
    if (musicBehavior) {
        if ([SoundListenTool sharedInstance].audioRecorder.recording) {
            [[SoundListenTool sharedInstance] stopRecord:_deviceId];
        }
    }
    UIColor *color = [UIColor colorWithHue:hue saturation:colorSatutation brightness:1.0 alpha:1.0];
    [[LightModelApi sharedInstance] setColor:_deviceId color:color duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
        
    } failure:^(NSError * _Nullable error) {
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        model.isleave = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":_deviceId}];
    }];
}

- (void)panColorChangeWithHue:(CGFloat)hue colorSaturation:(CGFloat)colorSatutation state:(UIGestureRecognizerState)state {
    if (state == UIGestureRecognizerStateBegan) {
        if (musicBehavior) {
            if ([SoundListenTool sharedInstance].audioRecorder.recording) {
                [[SoundListenTool sharedInstance] stopRecord:_deviceId];
            }
        }
        _colorSquareIsMoving = YES;
    }else if (state == UIGestureRecognizerStateEnded) {
        _colorSquareIsMoving = NO;
    }
    UIColor *color = [UIColor colorWithHue:hue saturation:colorSatutation brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_deviceId withColor:color withState:state];
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
    sender.selected = !sender.selected;
    UIImage *image = sender.selected? [UIImage imageNamed:@"Be_selected"]:[UIImage imageNamed:@"To_select"];
    [sender setImage:image forState:UIControlStateNormal];
    switch (sender.tag) {
        case 1:
            if (sender.selected) {
                if (_daliGroupSelectBtn.selected) {
                    _daliGroupSelectBtn.selected = NO;
                    [_daliGroupSelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                    [_daliGroupTF resignFirstResponder];
                }else if (_daliAddressBtn.selected) {
                    _daliAddressBtn.selected = NO;
                    [_daliAddressBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                    [_daliAddressTF resignFirstResponder];
                }
                [[DataModelManager shareInstance] sendCmdData:@"ea520101ff" toDeviceId:_deviceId];
            }
            break;
        case 2:
            if (sender.selected) {
                if (_daliAllSelectBtn.selected) {
                    _daliAllSelectBtn.selected = NO;
                    [_daliAllSelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }else if (_daliAddressBtn.selected) {
                    _daliAddressBtn.selected = NO;
                    [_daliAddressBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                    [_daliAddressTF resignFirstResponder];
                }
                [_daliGroupTF becomeFirstResponder];
            }
            break;
        case 3:
            if (sender.selected) {
                if (_daliGroupSelectBtn.selected) {
                    _daliGroupSelectBtn.selected = NO;
                    [_daliGroupSelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                    [_daliGroupTF resignFirstResponder];
                }else if (_daliAllSelectBtn.selected) {
                    _daliAllSelectBtn.selected = NO;
                    [_daliAllSelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                }
                [_daliAddressTF becomeFirstResponder];
            }
            break;
        default:
            break;
    }
}

- (void)getDaliAdress:(NSNotification *)notification {
    NSDictionary *userDic = notification.userInfo;
    NSInteger address = [CSRUtilities numberWithHexString:userDic[@"addressStr"]];
    [self configDaliAppearance:address];
}

- (void)configDaliAppearance:(NSInteger)address {
    if (address == 255) {
        _daliAllSelectBtn.selected = YES;
        [_daliAllSelectBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
        _daliGroupSelectBtn.selected = NO;
        [_daliGroupSelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        _daliGroupTF.text = nil;
        _daliAddressBtn.selected = NO;
        [_daliAddressBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        _daliAddressTF.text = nil;
    }else if (address >= 64 && address <= 79) {
        _daliAllSelectBtn.selected = NO;
        [_daliAllSelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        _daliGroupSelectBtn.selected = YES;
        [_daliGroupSelectBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
        _daliGroupTF.text = [NSString stringWithFormat:@"%d",address-64];
        _daliAddressBtn.selected = NO;
        [_daliAddressBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        _daliAddressTF.text = nil;
    }else if (address < 64){
        _daliAllSelectBtn.selected = NO;
        [_daliAllSelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        _daliGroupSelectBtn.selected = NO;
        [_daliGroupSelectBtn setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        _daliGroupTF.text = nil;
        _daliAddressBtn.selected = YES;
        [_daliAddressBtn setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
        _daliAddressTF.text = [NSString stringWithFormat:@"%ld",(long)address];
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
        _ganjiedianCustomView.frame = CGRectMake(WIDTH-179.0, _ganjiedianRowView.frame.origin.y-134.0, 200.0, 179.0);
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


@end
