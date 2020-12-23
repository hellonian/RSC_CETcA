//
//  RemoteSettingViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/3/1.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "RemoteSettingViewController.h"
#import "CSRDatabaseManager.h"
#import "CSRAppStateManager.h"
#import "CSRUtilities.h"
#import "CSRDevicesManager.h"
#import "PureLayout.h"
#import "DeviceListViewController.h"
#import "DataModelManager.h"
#import <MBProgressHUD.h>
#import "SingleDeviceModel.h"
#import "SceneMemberEntity.h"
#import <CSRmesh/DataModelApi.h>
#import "DeviceModelManager.h"
#import "AFHTTPSessionManager.h"
#import "UpdataMCUTool.h"
#import "CSRBluetoothLE.h"

#import "SelectModel.h"

@interface RemoteSettingViewController ()<UITextFieldDelegate,MBProgressHUDDelegate,UpdataMCUToolDelegate>
{
    dispatch_semaphore_t semaphore;
    NSInteger timerSeconde;
    NSTimer *timer;
    
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
    UIButton *updateMCUBtn;
    
    NSInteger keyCount;
}

@property (weak, nonatomic) IBOutlet UIView *customContentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (weak, nonatomic) IBOutlet UITextField *nameTF;
@property (nonatomic,copy) NSString *originalName;
@property (nonatomic,strong) CSRmeshDevice *deleteDevice;
@property (nonatomic,strong) UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIView *fiveRemoteView;
@property (weak, nonatomic) IBOutlet UIView *singleRemoteView;
@property (weak, nonatomic) IBOutlet UIView *nameBgView;
@property (weak, nonatomic) IBOutlet UILabel *fSelectOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *fSelectTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *fSelectThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *fSelectFourLabel;
@property (weak, nonatomic) IBOutlet UILabel *sSelectOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *fConrolOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *fConrolTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *fConrolThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *fConrolFourLabel;
@property (weak, nonatomic) IBOutlet UILabel *sConrolOneLabel;
@property (nonatomic,strong) MBProgressHUD *hub;
@property (nonatomic,assign) BOOL setSuccess;
@property (weak, nonatomic) IBOutlet UIImageView *practicalityImageView;

@property (weak, nonatomic) IBOutlet UIView *twoRemoteView;
@property (weak, nonatomic) IBOutlet UILabel *tSelectOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *tSelectTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *tConrolOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *tConrolTwoLabel;
@property (strong, nonatomic) IBOutlet UIView *twoRemoteEnableView;
@property (weak, nonatomic) IBOutlet UISwitch *enableSwitch;

@property (nonatomic,strong) MBProgressHUD *updatingHud;

@property (strong, nonatomic) IBOutlet UIView *R5BSHBView;
@property (weak, nonatomic) IBOutlet UILabel *R5BSHBControlOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *R5BSHBSelectOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *R5BSHBControlTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *R5BSHBSelectTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *R5BSHBControlThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *R5BSHBSelectThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *R5BSHBControlFourLabel;
@property (weak, nonatomic) IBOutlet UILabel *R5BSHBSelectFourLabel;
@property (weak, nonatomic) IBOutlet UILabel *R5BSHBControlFiveLabel;
@property (weak, nonatomic) IBOutlet UILabel *R5BSHBSelectFiveLabel;

@property (strong, nonatomic) IBOutlet UIView *R9BSBHPsswordView;
@property (strong, nonatomic) IBOutlet UIView *R9BSBHView;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHControlOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHSelectOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHControlTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHSelectTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHControlThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHSelectThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHControlFourLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHSelectFourLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHControlFiveLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHSelectFiveLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHControlSixLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHSelectSixLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHControlSevenLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHSelectSevenLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHControlEightLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHSelectEightLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHControlNineLabel;
@property (weak, nonatomic) IBOutlet UILabel *R9BSBHSelectNineLabel;

@property (strong, nonatomic) IBOutlet UIView *sixKeyView;
@property (weak, nonatomic) IBOutlet UILabel *sixKeyControlOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixKeySelectOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixKeyControlTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixKeySelectTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixKeyControlThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixKeySelectThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixKeyControlFourLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixKeySelectFourLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixKeyControlFiveLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixKeySelectFiveLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixKeyControlSixLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixKeySelectSixLabel;

@property (weak, nonatomic) IBOutlet UITextField *passwordTF;
@property (weak, nonatomic) IBOutlet UISwitch *passwordEnableSwitch;
@property (nonatomic, strong) NSString *resendCmd;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (nonatomic,strong) UIView *translucentBgView;

@property (nonatomic,strong) UIView *keyTypeSettingView;

@property (nonatomic,strong) NSMutableArray *settingSelectMutArray;
@property (nonatomic, strong) UIAlertController *mcuAlert;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation RemoteSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (@available(iOS 11.0,*)) {
    }else {
        [_practicalityImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:94.0f];
    }
    self.navigationItem.title = self.remoteEntity.name;
    self.nameTF.delegate = self;
    self.nameTF.text = self.remoteEntity.name;
    self.originalName = self.remoteEntity.name;
    
    if ([self.remoteEntity.shortName isEqualToString:@"RB01"]||[self.remoteEntity.shortName isEqualToString:@"RB05"]) {
        if ([self.remoteEntity.shortName isEqualToString:@"RB01"]) {
            _practicalityImageView.image = [UIImage imageNamed:@"rb01"];
        }else if ([self.remoteEntity.shortName isEqualToString:@"RB05"]) {
            _practicalityImageView.image = [UIImage imageNamed:@"rb05"];
        }
        
        [_customContentView addSubview:self.fiveRemoteView];
        [self.fiveRemoteView autoSetDimension:ALDimensionHeight toSize:179.0f];
        [self.fiveRemoteView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.fiveRemoteView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.fiveRemoteView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
        
        _settingSelectMutArray = [[NSMutableArray alloc] initWithCapacity:4];
        
        if (/*[[CSRAppStateManager sharedInstance].selectedPlace.color boolValue]*/
            [_remoteEntity.cvVersion integerValue] < 18) {
            if (_remoteEntity.remoteBranch.length > 72) {
                NSArray *remoteArray = [self.remoteEntity.remoteBranch componentsSeparatedByString:@"|"];
                [remoteArray enumerateObjectsUsingBlock:^(NSString *brach, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString *swIndex = [brach substringToIndex:2];
                    NSString *rcIndex = [brach substringWithRange:NSMakeRange(2, 4)];
                    SelectModel *mod = [[SelectModel alloc] init];
                    mod.sourceID = @([CSRUtilities numberWithHexString:swIndex]);
                    if ([brach length]>15) {
                        mod.channel = @([self exchangePositionOfDeviceIdString:rcIndex]);
                        mod.deviceID = @([self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]]);
                    }else {
                        mod.channel = @(0);
                        mod.deviceID = @(0);
                    }
                    [_settingSelectMutArray insertObject:mod atIndex:idx];
                    
                    switch (idx) {
                        case 0:
                            [self fillControlLabel:_fConrolOneLabel selectedLabel:_fSelectOneLabel selectModel:mod];
                            break;
                        case 1:
                            [self fillControlLabel:_fConrolTwoLabel selectedLabel:_fSelectTwoLabel selectModel:mod];
                            break;
                        case 2:
                            [self fillControlLabel:_fConrolThreeLabel selectedLabel:_fSelectThreeLabel selectModel:mod];
                            break;
                        case 3:
                            [self fillControlLabel:_fConrolFourLabel selectedLabel:_fSelectFourLabel selectModel:mod];
                            break;
                        default:
                            break;
                    }
                }];
            }else {
                for (int i=0; i<4; i++) {
                    SelectModel *mod = [[SelectModel alloc] init];
                    mod.sourceID = @(i+1);
                    mod.channel = @(0);
                    mod.deviceID = @(0);
                    [_settingSelectMutArray insertObject:mod atIndex:i];
                }
                _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            }
        }else {
            for (int i=0; i<5; i++) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @(i+1);
                mod.channel = @(0);
                mod.deviceID = @(0);
                [_settingSelectMutArray insertObject:mod atIndex:i];
            }
            _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            
            if (self.remoteEntity.remoteBranch.length >= 16) {
                NSInteger c = (self.remoteEntity.remoteBranch.length-6) / 10;
                for (int i=0; i<c; i++) {
                    NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
                    SelectModel *mod = [[SelectModel alloc] init];
                    NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                    NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                    mod.channel = @(channelInt);
                    NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                    mod.deviceID = @(deviceIDInt);
                    mod.sourceID = @(s);
                    [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                    switch (s-1) {
                        case 0:
                            [self fillControlLabel:_fConrolOneLabel selectedLabel:_fSelectOneLabel selectModel:mod];
                            break;
                        case 1:
                            [self fillControlLabel:_fConrolTwoLabel selectedLabel:_fSelectTwoLabel selectModel:mod];
                            break;
                        case 2:
                            [self fillControlLabel:_fConrolThreeLabel selectedLabel:_fSelectThreeLabel selectModel:mod];
                            break;
                        case 3:
                            [self fillControlLabel:_fConrolFourLabel selectedLabel:_fSelectFourLabel selectModel:mod];
                            break;
                        default:
                            break;
                    }
                }
            }
        }
        
    }else if ([self.remoteEntity.shortName isEqualToString:@"RB02"]
              ||[_remoteEntity.shortName isEqualToString:@"RB06"]
              ||[_remoteEntity.shortName isEqualToString:@"RSBH"]
              ||[_remoteEntity.shortName isEqualToString:@"1BMBH"]
              ||[_remoteEntity.shortName isEqualToString:@"RB08"]) {
        if ([self.remoteEntity.shortName isEqualToString:@"RB02"]) {
            _practicalityImageView.image = [UIImage imageNamed:@"rb02"];
        }else {
            _practicalityImageView.image = [UIImage imageNamed:@"rb06"];
        }
        
        [self.customContentView addSubview:self.singleRemoteView];
        [self.singleRemoteView autoSetDimension:ALDimensionHeight toSize:44.0f];
        [self.singleRemoteView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.singleRemoteView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.singleRemoteView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
        _settingSelectMutArray = [[NSMutableArray alloc] initWithCapacity:1];
        if (/*[[CSRAppStateManager sharedInstance].selectedPlace.color boolValue]*/
            [_remoteEntity.cvVersion integerValue] < 18) {
            if (_remoteEntity.remoteBranch.length >= 18) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @(1);
                mod.channel = @([self exchangePositionOfDeviceIdString:[_remoteEntity.remoteBranch substringWithRange:NSMakeRange(2, 4)]]);
                mod.deviceID = @([self exchangePositionOfDeviceIdString:[_remoteEntity.remoteBranch substringWithRange:NSMakeRange(12, 4)]]);
                [_settingSelectMutArray insertObject:mod atIndex:0];
                [self fillControlLabel:_sConrolOneLabel selectedLabel:_sSelectOneLabel selectModel:mod];
            }else {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @(1);
                mod.channel = @(0);
                mod.deviceID = @(0);
                [_settingSelectMutArray insertObject:mod atIndex:0];
                _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            }
        }else {
            SelectModel *mod = [[SelectModel alloc] init];
            mod.sourceID = @(1);
            mod.channel = @(0);
            mod.deviceID = @(0);
            [_settingSelectMutArray insertObject:mod atIndex:0];
            _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            if (self.remoteEntity.remoteBranch.length >= 16) {
                NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(6, 10)];
                SelectModel *mod = [[SelectModel alloc] init];
                NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                mod.channel = @(channelInt);
                NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                mod.deviceID = @(deviceIDInt);
                mod.sourceID = @(s);
                [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                [self fillControlLabel:_sConrolOneLabel selectedLabel:_sSelectOneLabel selectModel:mod];
            }
        }
        
    }else if ([self.remoteEntity.shortName isEqualToString:@"RB04"]
              || [self.remoteEntity.shortName isEqualToString:@"RSIBH"]
              || [self.remoteEntity.shortName isEqualToString:@"S10IB-H2"]) {
        _practicalityImageView.image = [UIImage imageNamed:@"bajiao"];
        [self.customContentView addSubview:self.twoRemoteView];
        [self.twoRemoteView autoSetDimension:ALDimensionHeight toSize:89.0f];
        [self.twoRemoteView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.twoRemoteView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.twoRemoteView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
        [self.customContentView addSubview:self.twoRemoteEnableView];
        [self.twoRemoteEnableView autoSetDimension:ALDimensionHeight toSize:45.0f];
        [self.twoRemoteEnableView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.twoRemoteEnableView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.twoRemoteEnableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.twoRemoteView];
        
        _settingSelectMutArray = [[NSMutableArray alloc] initWithCapacity:4];
        
        for (int i=0; i<2; i++) {
            SelectModel *mod = [[SelectModel alloc] init];
            mod.sourceID = @(i+1);
            mod.channel = @(0);
            mod.deviceID = @(0);
            [_settingSelectMutArray insertObject:mod atIndex:i];
        }
        _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        if (self.remoteEntity.remoteBranch.length >= 16) {
            NSInteger c = (self.remoteEntity.remoteBranch.length-6) / 10;
            for (int i=0; i<c; i++) {
                NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
                SelectModel *mod = [[SelectModel alloc] init];
                NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                mod.channel = @(channelInt);
                NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                mod.deviceID = @(deviceIDInt);
                mod.sourceID = @(s);
                [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                switch (s-1) {
                    case 0:
                        [self fillControlLabel:_tConrolOneLabel selectedLabel:_tSelectOneLabel selectModel:mod];
                        break;
                    case 1:
                        [self fillControlLabel:_tConrolTwoLabel selectedLabel:_tSelectTwoLabel selectModel:mod];
                        break;
                    default:
                        break;
                }
            }
        }
        
    }else if ([self.remoteEntity.shortName isEqualToString:@"R5BSBH"]
              || [self.remoteEntity.shortName isEqualToString:@"RB09"]
              || [self.remoteEntity.shortName isEqualToString:@"5RSIBH"]
              || [self.remoteEntity.shortName isEqualToString:@"5BCBH"]) {
        if ([self.remoteEntity.shortName isEqualToString:@"R5BSBH"] || [self.remoteEntity.shortName isEqualToString:@"5BCBH"]) {
            _practicalityImageView.image = [UIImage imageNamed:@"rb01"];
        }else {
            _practicalityImageView.image = [UIImage imageNamed:@"bajiao"];
            if ([self.remoteEntity.shortName isEqualToString:@"5RSIBH"]) {
                keyCount = 5;
                UIButton *btn = [[UIButton alloc] initWithFrame:CGRectZero];
                [btn setTitle:@"Set Key Type" forState:UIControlStateNormal];
                [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
                [btn.titleLabel setFont:[UIFont systemFontOfSize:12.0]];
                btn.backgroundColor = [UIColor whiteColor];
                btn.layer.cornerRadius = 5.0;
                btn.clipsToBounds = YES;
                [btn addTarget:self action:@selector(keyTypeSettingAction) forControlEvents:UIControlEventTouchUpInside];
                [self.customContentView addSubview:btn];
                [btn autoSetDimensionsToSize:CGSizeMake(100, 30)];
                [btn autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20.0];
                [btn autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.nameBgView withOffset:-10.0];
            }
        }
        
        [self.customContentView addSubview:self.R5BSHBView];
        [self.R5BSHBView autoSetDimension:ALDimensionHeight toSize:224.0f];
        [self.R5BSHBView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.R5BSHBView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.R5BSHBView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
        
        _settingSelectMutArray = [[NSMutableArray alloc] initWithCapacity:5];
        
        for (int i=0; i<5; i++) {
            SelectModel *mod = [[SelectModel alloc] init];
            mod.sourceID = @(i+1);
            mod.channel = @(0);
            mod.deviceID = @(0);
            [_settingSelectMutArray insertObject:mod atIndex:i];
        }
        _R5BSHBControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R5BSHBControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R5BSHBControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R5BSHBControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R5BSHBControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        if (self.remoteEntity.remoteBranch.length >= 16) {
            NSInteger c = (self.remoteEntity.remoteBranch.length-6) / 10;
            for (int i=0; i<c; i++) {
               NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
                SelectModel *mod = [[SelectModel alloc] init];
                NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                mod.channel = @(channelInt);
                NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                mod.deviceID = @(deviceIDInt);
                if (s == 0) {
                    mod.sourceID = @(5);
                    [_settingSelectMutArray replaceObjectAtIndex:4 withObject:mod];
                }else {
                    mod.sourceID = @(s);
                    [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                }
                switch (s-1) {
                    case 0:
                        [self fillControlLabel:_R5BSHBControlOneLabel selectedLabel:_R5BSHBSelectOneLabel selectModel:mod];
                        break;
                    case 1:
                        [self fillControlLabel:_R5BSHBControlTwoLabel selectedLabel:_R5BSHBSelectTwoLabel selectModel:mod];
                        break;
                    case 2:
                        [self fillControlLabel:_R5BSHBControlThreeLabel selectedLabel:_R5BSHBSelectThreeLabel selectModel:mod];
                        break;
                    case 3:
                        [self fillControlLabel:_R5BSHBControlFourLabel selectedLabel:_R5BSHBSelectFourLabel selectModel:mod];
                        break;
                    case 4:
                    case -1:
                        [self fillControlLabel:_R5BSHBControlFiveLabel selectedLabel:_R5BSHBSelectFiveLabel selectModel:mod];
                        break;
                    default:
                        break;
                }
            }
        }
    }else if ([self.remoteEntity.shortName isEqualToString:@"R9BSBH"]) {
        _practicalityImageView.image = [UIImage imageNamed:@"rb01"];
        [self.customContentView addSubview:self.R9BSBHPsswordView];
        [self.R9BSBHPsswordView autoSetDimension:ALDimensionHeight toSize:89.0f];
        [self.R9BSBHPsswordView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.R9BSBHPsswordView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.R9BSBHPsswordView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
        
        [self.customContentView addSubview:self.R9BSBHView];
        [self.R9BSBHView autoSetDimension:ALDimensionHeight toSize:404.0f];
        [self.R9BSBHView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.R9BSBHView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.R9BSBHView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.R9BSBHPsswordView withOffset:30];
        
        _passwordTF.delegate = self;
        
        _settingSelectMutArray = [[NSMutableArray alloc] initWithCapacity:9];
        
        for (int i=0; i<9; i++) {
            SelectModel *mod = [[SelectModel alloc] init];
            mod.sourceID = @(i+1);
            mod.channel = @(0);
            mod.deviceID = @(0);
            [_settingSelectMutArray insertObject:mod atIndex:i];
        }
        _R9BSBHControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHControlSixLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHControlSevenLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHControlEightLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHControlNineLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        if (self.remoteEntity.remoteBranch.length >= 16) {
            NSInteger c = (self.remoteEntity.remoteBranch.length-6) / 10;
            for (int i=0; i<c; i++) {
                NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
                SelectModel *mod = [[SelectModel alloc] init];
                NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                mod.channel = @(channelInt);
                NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                mod.deviceID = @(deviceIDInt);
                mod.sourceID = @(s);
                [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                switch (s-1) {
                    case 0:
                        [self fillControlLabel:_R9BSBHControlOneLabel selectedLabel:_R9BSBHSelectOneLabel selectModel:mod];
                        break;
                    case 1:
                        [self fillControlLabel:_R9BSBHControlTwoLabel selectedLabel:_R9BSBHSelectTwoLabel selectModel:mod];
                        break;
                    case 2:
                        [self fillControlLabel:_R9BSBHControlThreeLabel selectedLabel:_R9BSBHSelectThreeLabel selectModel:mod];
                        break;
                    case 3:
                        [self fillControlLabel:_R9BSBHControlFourLabel selectedLabel:_R9BSBHSelectFourLabel selectModel:mod];
                        break;
                    case 4:
                        [self fillControlLabel:_R9BSBHControlFiveLabel selectedLabel:_R9BSBHSelectFiveLabel selectModel:mod];
                        break;
                    case 5:
                        [self fillControlLabel:_R9BSBHControlSixLabel selectedLabel:_R9BSBHSelectSixLabel selectModel:mod];
                        break;
                    case 6:
                        [self fillControlLabel:_R9BSBHControlSevenLabel selectedLabel:_R9BSBHSelectSevenLabel selectModel:mod];
                        break;
                    case 7:
                        [self fillControlLabel:_R9BSBHControlEightLabel selectedLabel:_R9BSBHSelectEightLabel selectModel:mod];
                        break;
                    case 8:
                        [self fillControlLabel:_R9BSBHControlNineLabel selectedLabel:_R9BSBHSelectNineLabel selectModel:mod];
                        break;
                    default:
                        break;
                }
            }
        }
    }else if ([self.remoteEntity.shortName isEqualToString:@"RB07"]) {
        _practicalityImageView.image = [UIImage imageNamed:@"bajiao"];
        [self.customContentView addSubview:self.twoRemoteView];
        [self.twoRemoteView autoSetDimension:ALDimensionHeight toSize:89.0f];
        [self.twoRemoteView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.twoRemoteView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.twoRemoteView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
        
        _settingSelectMutArray = [[NSMutableArray alloc] initWithCapacity:2];
        
        if (/*[[CSRAppStateManager sharedInstance].selectedPlace.color boolValue]*/
            [_remoteEntity.cvVersion integerValue] < 18) {
            if (_remoteEntity.remoteBranch.length >37) {
                NSArray *remoteArray = [self.remoteEntity.remoteBranch componentsSeparatedByString:@"|"];
                [remoteArray enumerateObjectsUsingBlock:^(NSString *brach, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString *swIndex = [brach substringToIndex:2];
                    NSString *rcIndex = [brach substringWithRange:NSMakeRange(2, 4)];
                    SelectModel *mod = [[SelectModel alloc] init];
                    mod.sourceID = @([CSRUtilities numberWithHexString:swIndex]);
                    mod.channel = @([self exchangePositionOfDeviceIdString:rcIndex]);
                    mod.deviceID = @([self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]]);
                    [_settingSelectMutArray insertObject:mod atIndex:idx];
                    
                    switch (idx) {
                        case 0:
                            [self fillControlLabel:_tConrolOneLabel selectedLabel:_tSelectOneLabel selectModel:mod];
                            break;
                        case 1:
                            [self fillControlLabel:_tConrolTwoLabel selectedLabel:_tSelectTwoLabel selectModel:mod];
                            break;
                        default:
                            break;
                    }
                }];
            }else {
                for (int i=0; i<2; i++) {
                    SelectModel *mod = [[SelectModel alloc] init];
                    mod.sourceID = @(i+1);
                    mod.channel = @(0);
                    mod.deviceID = @(0);
                    [_settingSelectMutArray insertObject:mod atIndex:i];
                }
                _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            }
        }else {
            for (int i=0; i<2; i++) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @(i+1);
                mod.channel = @(0);
                mod.deviceID = @(0);
                [_settingSelectMutArray insertObject:mod atIndex:i];
            }
            _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            if (self.remoteEntity.remoteBranch.length >= 16) {
                NSInteger c = (self.remoteEntity.remoteBranch.length-6) / 10;
                for (int i=0; i<c; i++) {
                    NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
                    SelectModel *mod = [[SelectModel alloc] init];
                    NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                    NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                    mod.channel = @(channelInt);
                    NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                    mod.deviceID = @(deviceIDInt);
                    mod.sourceID = @(s);
                    [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                    switch (s-1) {
                        case 0:
                            [self fillControlLabel:_tConrolOneLabel selectedLabel:_tSelectOneLabel selectModel:mod];
                            break;
                        case 1:
                            [self fillControlLabel:_tConrolTwoLabel selectedLabel:_tSelectTwoLabel selectModel:mod];
                            break;
                        default:
                            break;
                    }
                }
            }
        }
    }else if ([self.remoteEntity.shortName isEqualToString:@"6RSIBH"]
              || [self.remoteEntity.shortName isEqualToString:@"H1CSWB"]
              || [self.remoteEntity.shortName isEqualToString:@"H2CSWB"]
              || [self.remoteEntity.shortName isEqualToString:@"H3CSWB"]
              || [self.remoteEntity.shortName isEqualToString:@"H4CSWB"]
              || [self.remoteEntity.shortName isEqualToString:@"H6CSWB"]
              || [self.remoteEntity.shortName isEqualToString:@"H1CSB"]
              || [self.remoteEntity.shortName isEqualToString:@"H2CSB"]
              || [self.remoteEntity.shortName isEqualToString:@"H3CSB"]
              || [self.remoteEntity.shortName isEqualToString:@"H4CSB"]
              || [self.remoteEntity.shortName isEqualToString:@"H6CSB"]
              || [self.remoteEntity.shortName isEqualToString:@"KT6RS"]
              || [self.remoteEntity.shortName isEqualToString:@"H1RSMB"]
              || [self.remoteEntity.shortName isEqualToString:@"H2RSMB"]
              || [self.remoteEntity.shortName isEqualToString:@"H3RSMB"]
              || [self.remoteEntity.shortName isEqualToString:@"H4RSMB"]
              || [self.remoteEntity.shortName isEqualToString:@"H5RSMB"]
              || [self.remoteEntity.shortName isEqualToString:@"H6RSMB"]) {
        _practicalityImageView.image = [UIImage imageNamed:@"bajiao"];
        keyCount = 6;
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectZero];
        [btn setTitle:@"Set Key Type" forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:12.0]];
        btn.backgroundColor = [UIColor whiteColor];
        btn.layer.cornerRadius = 5.0;
        btn.clipsToBounds = YES;
        [btn addTarget:self action:@selector(keyTypeSettingAction) forControlEvents:UIControlEventTouchUpInside];
        [self.customContentView addSubview:btn];
        [btn autoSetDimensionsToSize:CGSizeMake(100, 30)];
        [btn autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20.0];
        [btn autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.nameBgView withOffset:-10.0];
        
        [self.customContentView addSubview:_sixKeyView];
        [_sixKeyView autoSetDimension:ALDimensionHeight toSize:269.0f];
        [_sixKeyView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_sixKeyView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [_sixKeyView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_nameBgView withOffset:30.0f];
        
        _settingSelectMutArray = [[NSMutableArray alloc] initWithCapacity:6];
        
        for (int i=0; i<6; i++) {
            SelectModel *mod = [[SelectModel alloc] init];
            mod.sourceID = @(i+1);
            mod.channel = @(0);
            mod.deviceID = @(0);
            [_settingSelectMutArray insertObject:mod atIndex:i];
        }
        _sixKeyControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _sixKeyControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _sixKeyControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _sixKeyControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _sixKeyControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _sixKeyControlSixLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        if (self.remoteEntity.remoteBranch.length >= 16) {
            NSInteger c = (self.remoteEntity.remoteBranch.length-6) / 10;
            for (int i=0; i<c; i++) {
                NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
                SelectModel *mod = [[SelectModel alloc] init];
                NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                mod.channel = @(channelInt);
                NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                mod.deviceID = @(deviceIDInt);
                mod.sourceID = @(s);
                [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                switch (s-1) {
                    case 0:
                        [self fillControlLabel:_sixKeyControlOneLabel selectedLabel:_sixKeySelectOneLabel selectModel:mod];
                        break;
                    case 1:
                        [self fillControlLabel:_sixKeyControlTwoLabel selectedLabel:_sixKeySelectTwoLabel selectModel:mod];
                        break;
                    case 2:
                        [self fillControlLabel:_sixKeyControlThreeLabel selectedLabel:_sixKeySelectThreeLabel selectModel:mod];
                        break;
                    case 3:
                        [self fillControlLabel:_sixKeyControlFourLabel selectedLabel:_sixKeySelectFourLabel selectModel:mod];
                        break;
                    case 4:
                        [self fillControlLabel:_sixKeyControlFiveLabel selectedLabel:_sixKeySelectFiveLabel selectModel:mod];
                        break;
                    case 5:
                        [self fillControlLabel:_sixKeyControlSixLabel selectedLabel:_sixKeySelectSixLabel selectModel:mod];
                        break;
                    default:
                        break;
                }
            }
        }
    }
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = done;
//    self.navigationItem.rightBarButtonItem.enabled = NO;
    semaphore = dispatch_semaphore_create(1);
    
    if ([_remoteEntity.hwVersion integerValue]==2) {
        NSMutableString *mutStr = [NSMutableString stringWithString:_remoteEntity.shortName];
        NSRange range = {0,_remoteEntity.shortName.length};
        [mutStr replaceOccurrencesOfString:@"/" withString:@"" options:NSLiteralSearch range:range];
        NSString *urlString = [NSString stringWithFormat:@"http://39.108.152.134/MCU/%@/%@.php",mutStr,mutStr];
        AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
        sessionManager.responseSerializer.acceptableContentTypes = nil;
        sessionManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
        [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSDictionary *dic = (NSDictionary *)responseObject;
            latestMCUSVersion = [dic[@"mcu_software_version"] integerValue];
            downloadAddress = dic[@"Download_address"];
            if ([_remoteEntity.mcuSVersion integerValue]<latestMCUSVersion && [_remoteEntity.mcuSVersion integerValue] != 0) {
                updateMCUBtn = [UIButton buttonWithType:UIButtonTypeSystem];
                [updateMCUBtn setBackgroundColor:[UIColor whiteColor]];
                [updateMCUBtn setTitle:@"UPDATE MCU" forState:UIControlStateNormal];
                [updateMCUBtn setTitleColor:DARKORAGE forState:UIControlStateNormal];
                [updateMCUBtn addTarget:self action:@selector(disconnectForMCUUpdate) forControlEvents:UIControlEventTouchUpInside];
                [_customContentView addSubview:updateMCUBtn];
                [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeLeft];
                [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeRight];
                [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:45.0];
                [updateMCUBtn autoSetDimension:ALDimensionHeight toSize:44.0];
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"%@",error);
        }];
    }
    
}

- (void)disconnectForMCUUpdate {
    if ([_remoteEntity.uuid length] == 36) {
        [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
        [[UIApplication sharedApplication].keyWindow addSubview:self.indicatorView];
        [self.indicatorView autoCenterInSuperview];
        [self.indicatorView startAnimating];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(BridgeConnectedNotification:)
                                                     name:@"BridgeConnectedNotification"
                                                   object:nil];
        [[CSRBluetoothLE sharedInstance] disconnectPeripheralForMCUUpdate:[_remoteEntity.uuid substringFromIndex:24]];
        [self performSelector:@selector(connectForMCUUpdateDelayMethod) withObject:nil afterDelay:10.0];
    }
}

- (void)connectForMCUUpdateDelayMethod {
    _mcuAlert = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"mcu_connetion_alert", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
    [_mcuAlert.view setTintColor:DARKORAGE];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [[CSRBluetoothLE sharedInstance] cancelMCUUpdate];
        [self.indicatorView stopAnimating];
        [self.indicatorView removeFromSuperview];
        [self.translucentBgView removeFromSuperview];
        _indicatorView = nil;
        _translucentBgView = nil;
    }];
    UIAlertAction *conti = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"continue", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSelector:@selector(connectForMCUUpdateDelayMethod) withObject:nil afterDelay:10.0];
    }];
    [_mcuAlert addAction:cancel];
    [_mcuAlert addAction:conti];
    [self presentViewController:_mcuAlert animated:YES completion:nil];
}

- (void)BridgeConnectedNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CBPeripheral *peripheral = userInfo[@"peripheral"];
    NSString *adUuidString = [peripheral.uuidString substringToIndex:12];
    NSString *deviceUuidString = [_remoteEntity.uuid substringFromIndex:24];
    if ([adUuidString isEqualToString:deviceUuidString]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectForMCUUpdateDelayMethod) object:nil];
        if (_mcuAlert) {
            [_mcuAlert dismissViewControllerAnimated:YES completion:nil];
            _mcuAlert = nil;
        }
        [self askUpdateMCU];
    }
}

- (void)askUpdateMCU {
    [UpdataMCUTool sharedInstace].toolDelegate = self;
    [[UpdataMCUTool sharedInstace] askUpdateMCU:_remoteEntity.deviceId downloadAddress:downloadAddress latestMCUSVersion:latestMCUSVersion];
}

- (void)starteUpdateHud {
    if (!_updatingHud) {
        [self.indicatorView stopAnimating];
        [self.indicatorView removeFromSuperview];
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
        [[CSRBluetoothLE sharedInstance] successMCUUpdate];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BridgeConnectedNotification" object:nil];
    }
}

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] init];
        _indicatorView.hidesWhenStopped = YES;
        _indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    }
    return _indicatorView;
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deleteStatus:)
                                                 name:kCSRDeviceManagerDeviceFoundForReset
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getRemoteConfiguration:)
                                                 name:@"getRemoteConfiguration"
                                               object:nil];
    
    if ([self.remoteEntity.shortName isEqualToString:@"RB04"] || [self.remoteEntity.shortName isEqualToString:@"RSIBH"]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(getRemoteEnableState:)
                                                     name:@"getRemoteEnableState"
                                                   object:nil];
        [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:@"ea50030100"] success:nil failure:nil];
    }else if ([self.remoteEntity.shortName isEqualToString:@"R9BSBH"]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setRemotePasswordCall:)
                                                     name:@"setRemotePasswordCall"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enableRemotePasswordCall:)
                                                     name:@"enableRemotePasswordCall"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(getRemotePassword:)
                                                     name:@"getRemotePassword"
                                                   object:nil];
        [[DataModelManager shareInstance] sendCmdData:@"ea63" toDeviceId:_remoteEntity.deviceId];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRDeviceManagerDeviceFoundForReset
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"getRemoteConfiguration"
                                                  object:nil];
    
    if ([self.remoteEntity.shortName isEqualToString:@"RB04"] || [self.remoteEntity.shortName isEqualToString:@"RSIBH"]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:@"getRemoteEnableState"
                                                      object:nil];
    }else if ([self.remoteEntity.shortName isEqualToString:@"R9BSBH"]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:@"setRemotePasswordCall"
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:@"enableRemotePasswordCall"
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:@"getRemotePassword"
                                                      object:nil];
    }
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (@available(iOS 11.0, *)) {
        CGFloat safeHeight = self.view.bounds.size.height - self.view.safeAreaInsets.bottom - self.view.safeAreaInsets.top;
        if ([self.remoteEntity.shortName isEqualToString:@"RB01"]||[self.remoteEntity.shortName isEqualToString:@"RB05"]) {
            if (safeHeight <= 506.5) {
                _contentViewHeight.constant = 506.5;
            }else {
                _contentViewHeight.constant = safeHeight;
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"RB02"]
                  ||[self.remoteEntity.shortName isEqualToString:@"RB06"]
                  ||[self.remoteEntity.shortName isEqualToString:@"RSBH"]
                  ||[self.remoteEntity.shortName isEqualToString:@"1BMBH"]
                  ||[self.remoteEntity.shortName isEqualToString:@"RB08"]) {
            if (safeHeight <= 371.5) {
                _contentViewHeight.constant = 371.5;
            }else {
                _contentViewHeight.constant = safeHeight;
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"RB04"] || [self.remoteEntity.shortName isEqualToString:@"RSIBH"] || [self.remoteEntity.shortName isEqualToString:@"S10IB-H2"]||[self.remoteEntity.shortName isEqualToString:@"RB07"]) {
            if (safeHeight <= 461.5) {
                _contentViewHeight.constant = 461.5;
            }else {
                _contentViewHeight.constant = safeHeight;
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"R5BSBH"]
                  ||[self.remoteEntity.shortName isEqualToString:@"RB09"]
                  ||[self.remoteEntity.shortName isEqualToString:@"5RSIBH"]
                  ||[self.remoteEntity.shortName isEqualToString:@"5BCBH"]) {
            if (safeHeight <= 535) {
                _contentViewHeight.constant = 535;
            }else {
                _contentViewHeight.constant = safeHeight;
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"R9BSBH"]) {
            if (safeHeight <= 850.5) {
                _contentViewHeight.constant = 850.5;
            }else {
                _contentViewHeight.constant = safeHeight;
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"6RSIBH"]
                  || [self.remoteEntity.shortName isEqualToString:@"H1CSWB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H2CSWB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H3CSWB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H4CSWB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H6CSWB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H1CSB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H2CSB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H3CSB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H4CSB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H6CSB"]
                  || [self.remoteEntity.shortName isEqualToString:@"KT6RS"]
                  || [self.remoteEntity.shortName isEqualToString:@"H1RSMB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H2RSMB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H3RSMB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H4RSMB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H5RSMB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H6RSMB"]) {
            if (safeHeight <= 580) {
                _contentViewHeight.constant = 580;
            }else {
                _contentViewHeight.constant = safeHeight;
            }
        }
    }
}

-(void)getRemoteEnableState:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    NSString *stateStr = dic[@"getRemoteEnableState"];
    if (_remoteEntity.deviceId && [deviceId isEqualToNumber:_remoteEntity.deviceId]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_enableSwitch setOn:[stateStr boolValue]];
        });
    }
}

-(void)setRemotePasswordCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    NSString *state = dic[@"state"];
    if ([deviceId isEqualToNumber:_remoteEntity.deviceId]) {
        _setSuccess = YES;
        [_hub hideAnimated:YES];
        [self showTextHud:[state boolValue]? AcTECLocalizedStringFromTable(@"Success", @"Localizable"):AcTECLocalizedStringFromTable(@"fail", @"Localizable")];
        [timer invalidate];
        timer = nil;
        _resendCmd = nil;
    }
}

-(void)enableRemotePasswordCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    NSString *state = dic[@"state"];
    if ([deviceId isEqualToNumber:_remoteEntity.deviceId]) {
        _setSuccess = YES;
        [_hub hideAnimated:YES];
        [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
        [timer invalidate];
        timer = nil;
        _resendCmd = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_passwordEnableSwitch setOn:[state boolValue]];
        });
    }
}

-(void)getRemotePassword:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    if ([deviceId isEqualToNumber:_remoteEntity.deviceId]) {
        NSString *enable = dic[@"enable"];
        NSString *passwordCnt = dic[@"passwordCnt"];
        NSString *password = dic[@"password"];
        NSString *passwordHex = [[NSString alloc] init];
        int total = (int)[CSRUtilities numberWithHexString:passwordCnt],index = 0,length = 2;
        for (int i=0; i<(total+1)/2; i++) {
            if (total-index < 2) {
                length = total - index;
            }
            NSString *exStr = [password substringWithRange:NSMakeRange(index, length)];
            index += length;
            
            if ([exStr length] == 2) {
                NSString *str1 = [exStr substringToIndex:1];
                NSString *str2 = [exStr substringFromIndex:1];
                passwordHex = [NSString stringWithFormat:@"%@%@%@",passwordHex,str2,str1];
            }else {
                passwordHex = [NSString stringWithFormat:@"%@%@",passwordHex,exStr];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [_passwordEnableSwitch setOn:[enable boolValue]];
            _passwordTF.text = passwordHex;
        });
    }
}

- (IBAction)fSelectDevice:(UIButton *)sender {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *lamp = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self selectMember:DeviceListSelectMode_Single withButton:sender];
        
    }];
    UIAlertAction *group = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self selectMember:DeviceListSelectMode_SelectGroup withButton:sender];
        
    }];
    UIAlertAction *scene = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self selectMember:DeviceListSelectMode_SelectScene withButton:sender];
        
    }];
    UIAlertAction *clear = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Clear", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self cleanRemoteButton:sender];
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:lamp];
    [alert addAction:group];
    [alert addAction:scene];
    [alert addAction:clear];
    [alert addAction:cancel];
    
    alert.popoverPresentationController.sourceRect = sender.bounds;
    alert.popoverPresentationController.sourceView = sender;
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)selectMember:(DeviceListSelectMode)selectMode withButton:(UIButton *)button{
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = selectMode;
    list.sourceID = [NSNumber numberWithInteger:(button.tag % 10 + 1)];
    list.originalMembers = [NSArray arrayWithObject:[_settingSelectMutArray objectAtIndex:(button.tag%10)]];
    
    if (_remoteEntity.remoteBranch && [_remoteEntity.remoteBranch length]>=button.tag % 10 * 10 + 16) {
        list.remoteBranch = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(button.tag % 10 * 10 + 8, 8)];
    }
    
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count] > 0) {
            SelectModel *mod = devices[0];
            [_settingSelectMutArray replaceObjectAtIndex:([mod.sourceID integerValue]-1) withObject:mod];
            switch (button.tag) {
                case 100:
                    [self fillControlLabel:_fConrolOneLabel selectedLabel:_fSelectOneLabel selectModel:mod];
                    break;
                case 101:
                    [self fillControlLabel:_fConrolTwoLabel selectedLabel:_fSelectTwoLabel selectModel:mod];
                    break;
                case 102:
                    [self fillControlLabel:_fConrolThreeLabel selectedLabel:_fSelectThreeLabel selectModel:mod];
                    break;
                case 103:
                    [self fillControlLabel:_fConrolFourLabel selectedLabel:_fSelectFourLabel selectModel:mod];
                    break;
                case 200:
                    [self fillControlLabel:_sConrolOneLabel selectedLabel:_sSelectOneLabel selectModel:mod];
                    break;
                case 400:
                    [self fillControlLabel:_tConrolOneLabel selectedLabel:_tSelectOneLabel selectModel:mod];
                    break;
                case 401:
                    [self fillControlLabel:_tConrolTwoLabel selectedLabel:_tSelectTwoLabel selectModel:mod];
                    break;
                case 500:
                    [self fillControlLabel:_R5BSHBControlOneLabel selectedLabel:_R5BSHBSelectOneLabel selectModel:mod];
                    break;
                case 501:
                    [self fillControlLabel:_R5BSHBControlTwoLabel selectedLabel:_R5BSHBSelectTwoLabel selectModel:mod];
                    break;
                case 502:
                    [self fillControlLabel:_R5BSHBControlThreeLabel selectedLabel:_R5BSHBSelectThreeLabel selectModel:mod];
                    break;
                case 503:
                    [self fillControlLabel:_R5BSHBControlFourLabel selectedLabel:_R5BSHBSelectFourLabel selectModel:mod];
                    break;
                case 504:
                    [self fillControlLabel:_R5BSHBControlFiveLabel selectedLabel:_R5BSHBSelectFiveLabel selectModel:mod];
                    break;
                case 600:
                    [self fillControlLabel:_R9BSBHControlOneLabel selectedLabel:_R9BSBHSelectOneLabel selectModel:mod];
                case 601:
                    [self fillControlLabel:_R9BSBHControlTwoLabel selectedLabel:_R9BSBHSelectTwoLabel selectModel:mod];
                    break;
                case 602:
                    [self fillControlLabel:_R9BSBHControlThreeLabel selectedLabel:_R9BSBHSelectThreeLabel selectModel:mod];
                    break;
                case 603:
                    [self fillControlLabel:_R9BSBHControlFourLabel selectedLabel:_R9BSBHSelectFourLabel selectModel:mod];
                    break;
                case 604:
                    [self fillControlLabel:_R9BSBHControlFiveLabel selectedLabel:_R9BSBHSelectFiveLabel selectModel:mod];
                    break;
                case 605:
                    [self fillControlLabel:_R9BSBHControlSixLabel selectedLabel:_R9BSBHSelectSixLabel selectModel:mod];
                    break;
                case 606:
                    [self fillControlLabel:_R9BSBHControlSevenLabel selectedLabel:_R9BSBHSelectSevenLabel selectModel:mod];
                    break;
                case 607:
                    [self fillControlLabel:_R9BSBHControlEightLabel selectedLabel:_R9BSBHSelectEightLabel selectModel:mod];
                    break;
                case 608:
                    [self fillControlLabel:_R9BSBHControlNineLabel selectedLabel:_R9BSBHSelectNineLabel selectModel:mod];
                    break;
                case 700:
                    [self fillControlLabel:_sixKeyControlOneLabel selectedLabel:_sixKeySelectOneLabel selectModel:mod];
                    break;
                case 701:
                    [self fillControlLabel:_sixKeyControlTwoLabel selectedLabel:_sixKeySelectTwoLabel selectModel:mod];
                    break;
                case 702:
                    [self fillControlLabel:_sixKeyControlThreeLabel selectedLabel:_sixKeySelectThreeLabel selectModel:mod];
                    break;
                case 703:
                    [self fillControlLabel:_sixKeyControlFourLabel selectedLabel:_sixKeySelectFourLabel selectModel:mod];
                    break;
                case 704:
                    [self fillControlLabel:_sixKeyControlFiveLabel selectedLabel:_sixKeySelectFiveLabel selectModel:mod];
                    break;
                case 705:
                    [self fillControlLabel:_sixKeyControlSixLabel selectedLabel:_sixKeySelectSixLabel selectModel:mod];
                    break;
                default:
                    break;
            }
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)cleanRemoteButton:(UIButton *)button {
    
    SelectModel *mod = [_settingSelectMutArray objectAtIndex:button.tag%10];
    mod.deviceID = @(0);
    mod.channel = @(0);
    
    if (button.tag == 100) {
        _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _fSelectOneLabel.text = @"";
        return;
    }
    if (button.tag == 101) {
        _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _fSelectTwoLabel.text = @"";
        return;
    }
    if (button.tag == 102) {
        _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _fSelectThreeLabel.text = @"";
        return;
    }
    if (button.tag == 103) {
        _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _fSelectFourLabel.text = @"";
        return;
    }
    if (button.tag == 200) {
        _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _sSelectOneLabel.text = @"";
        return;
    }
    if (button.tag == 400) {
        _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _tSelectOneLabel.text = @"";
        return;
    }
    if (button.tag == 401) {
        _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _tSelectTwoLabel.text = @"";
        return;
    }
    if (button.tag == 500) {
        _R5BSHBControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R5BSHBSelectOneLabel.text = @"";
        return;
    }
    if (button.tag == 501) {
        _R5BSHBControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R5BSHBSelectTwoLabel.text = @"";
        return;
    }
    if (button.tag == 502) {
        _R5BSHBControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R5BSHBSelectThreeLabel.text = @"";
        return;
    }
    if (button.tag == 503) {
        _R5BSHBControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R5BSHBSelectFourLabel.text = @"";
        return;
    }
    if (button.tag == 504) {
        _R5BSHBControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R5BSHBSelectFiveLabel.text = @"";
        return;
    }
    if (button.tag == 600) {
        _R9BSBHControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHSelectOneLabel.text = @"";
        return;
    }
    if (button.tag == 601) {
        _R9BSBHControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHSelectTwoLabel.text = @"";
        return;
    }
    if (button.tag == 602) {
        _R9BSBHControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHSelectThreeLabel.text = @"";
        return;
    }
    if (button.tag == 603) {
        _R9BSBHControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHSelectFourLabel.text = @"";
        return;
    }
    if (button.tag == 604) {
        _R9BSBHControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHSelectFiveLabel.text = @"";
        return;
    }
    if (button.tag == 605) {
        _R9BSBHControlSixLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHSelectSixLabel.text = @"";
        return;
    }
    if (button.tag == 606) {
        _R9BSBHControlSevenLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHSelectSevenLabel.text = @"";
        return;
    }
    if (button.tag == 607) {
        _R9BSBHControlEightLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHSelectEightLabel.text = @"";
        return;
    }
    if (button.tag == 608) {
        _R9BSBHControlNineLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _R9BSBHSelectNineLabel.text = @"";
        return;
    }
    if (button.tag == 700) {
        _sixKeyControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _sixKeySelectOneLabel.text = @"";
        return;
    }
    if (button.tag == 701) {
        _sixKeyControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _sixKeySelectTwoLabel.text = @"";
        return;
    }
    if (button.tag == 702) {
        _sixKeyControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _sixKeySelectThreeLabel.text = @"";
        return;
    }
    if (button.tag == 703) {
        _sixKeyControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _sixKeySelectFourLabel.text = @"";
        return;
    }
    if (button.tag == 704) {
        _sixKeyControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _sixKeySelectFiveLabel.text = @"";
        return;
    }
    if (button.tag == 705) {
        _sixKeyControlSixLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _sixKeySelectSixLabel.text = @"";
        return;
    }
}

- (NSString *)cmdStringWithSceneRcIndex:(NSInteger)rcIndex swIndex:(NSInteger)swIndex {
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:@(rcIndex)];
    NSString *rcIndexStr = [self exchangePositionOfDeviceId:rcIndex];
    NSString *ligCnt = [CSRUtilities stringWithHexNumber:[sceneEntity.members count]];
    NSString *startLigIdx = @"00";
    NSString *endLigIdx = [CSRUtilities stringWithHexNumber:[sceneEntity.members count]-1];
    NSString *dstAddrLevel = @"";
    NSMutableArray *mutableMemebers = [[sceneEntity.members allObjects] mutableCopy];
    if ([mutableMemebers count] != 0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortID" ascending:YES];
        [mutableMemebers sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        for (SceneMemberEntity *sceneMember in mutableMemebers) {
            dstAddrLevel = [NSString stringWithFormat:@"%@%@%@%@%@%@%@",dstAddrLevel,[self exchangePositionOfDeviceId:[sceneMember.deviceID integerValue]],[CSRUtilities stringWithHexNumber:[sceneMember.eveType integerValue]], [CSRUtilities stringWithHexNumber:[sceneMember.eveD0 integerValue]], [CSRUtilities stringWithHexNumber:[sceneMember.eveD1 integerValue]], [CSRUtilities stringWithHexNumber:[sceneMember.eveD2 integerValue]], [CSRUtilities stringWithHexNumber:[sceneMember.eveD3 integerValue]]];
        }
    }
    NSString *nLength = [CSRUtilities stringWithHexNumber:dstAddrLevel.length/2+7];
    if ((dstAddrLevel.length/2+7)<250) {
        NSString *cmdStr = [NSString stringWithFormat:@"73%@010%ld%@%@%@%@%@",nLength,(long)swIndex,rcIndexStr,ligCnt,startLigIdx,endLigIdx,dstAddrLevel];
        return cmdStr;
    }
    return nil;
}

- (void)doneAction {
    _setSuccess = NO;
    timerSeconde = 20;
    [self showHudTogether];
    
    if ([_remoteEntity.shortName isEqualToString:@"RB04"] || [_remoteEntity.shortName isEqualToString:@"RSIBH"]) {
        NSString *cmd = @"9b0b02";
        for (SelectModel *mod in _settingSelectMutArray) {
            NSString *sw = [CSRUtilities stringWithHexNumber:[mod.sourceID integerValue]];
            NSString *rc = [CSRUtilities exchangePositionOfDeviceId:[mod.channel integerValue]];
            NSString *dst = [CSRUtilities exchangePositionOfDeviceId:[mod.deviceID integerValue]];
            cmd = [NSString stringWithFormat:@"%@%@%@%@",cmd,sw,rc,dst];
        }
        [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
            _remoteEntity.remoteBranch = cmd;
            [[CSRDatabaseManager sharedInstance] saveContext];
            _setSuccess = YES;
            [_hub hideAnimated:YES];
            [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
            [timer invalidate];
            timer = nil;
        } failure:^(NSError * _Nonnull error) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                    _remoteEntity.remoteBranch = cmd;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    _setSuccess = YES;
                    [_hub hideAnimated:YES];
                    [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                    [timer invalidate];
                    timer = nil;
                } failure:^(NSError * _Nonnull error) {
                    
                }];
            });
        }];
    }else if ([_remoteEntity.shortName isEqualToString:@"R5BSBH"] || [_remoteEntity.shortName isEqualToString:@"RB09"] || [_remoteEntity.shortName isEqualToString:@"5RSIBH"] || [_remoteEntity.shortName isEqualToString:@"5BCBH"]) {
        NSString *cmd = @"9b1a05";
        if ([_remoteEntity.shortName isEqualToString:@"R5BSBH"] || [_remoteEntity.shortName isEqualToString:@"5BCBH"]) {
            for (SelectModel *mod in _settingSelectMutArray) {
                NSString *sw = [CSRUtilities stringWithHexNumber:[mod.sourceID integerValue]];
                NSString *rc = [CSRUtilities exchangePositionOfDeviceId:[mod.channel integerValue]];
                NSString *dst = [CSRUtilities exchangePositionOfDeviceId:[mod.deviceID integerValue]];
                if ([mod.sourceID integerValue] == 5) {
                    sw = @"00";
                }
                cmd = [NSString stringWithFormat:@"%@%@%@%@",cmd,sw,rc,dst];
            }
        }else if ([_remoteEntity.shortName isEqualToString:@"RB09"]||[_remoteEntity.shortName isEqualToString:@"5RSIBH"]) {
            for (SelectModel *mod in _settingSelectMutArray) {
                NSString *sw = [CSRUtilities stringWithHexNumber:[mod.sourceID integerValue]];
                NSString *rc = [CSRUtilities exchangePositionOfDeviceId:[mod.channel integerValue]];
                NSString *dst = [CSRUtilities exchangePositionOfDeviceId:[mod.deviceID integerValue]];
                cmd = [NSString stringWithFormat:@"%@%@%@%@",cmd,sw,rc,dst];
            }
        }
        
        [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
            _remoteEntity.remoteBranch = cmd;
            [[CSRDatabaseManager sharedInstance] saveContext];
            _setSuccess = YES;
            [_hub hideAnimated:YES];
            [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
            [timer invalidate];
            timer = nil;
        } failure:^(NSError * _Nonnull error) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                    _remoteEntity.remoteBranch = cmd;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    _setSuccess = YES;
                    [_hub hideAnimated:YES];
                    [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                    [timer invalidate];
                    timer = nil;
                } failure:^(NSError * _Nonnull error) {
                    
                }];
            });
        }];
    }else if ([_remoteEntity.shortName isEqualToString:@"R9BSBH"]) {
        NSString *cmd = @"9b2e09";
        for (SelectModel *mod in _settingSelectMutArray) {
            NSString *sw = [CSRUtilities stringWithHexNumber:[mod.sourceID integerValue]];
            NSString *rc = [CSRUtilities exchangePositionOfDeviceId:[mod.channel integerValue]];
            NSString *dst = [CSRUtilities exchangePositionOfDeviceId:[mod.deviceID integerValue]];
            cmd = [NSString stringWithFormat:@"%@%@%@%@",cmd,sw,rc,dst];
        }
        
        [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
            _remoteEntity.remoteBranch = cmd;
            [[CSRDatabaseManager sharedInstance] saveContext];
            _setSuccess = YES;
            [_hub hideAnimated:YES];
            [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
            [timer invalidate];
            timer = nil;
        } failure:^(NSError * _Nonnull error) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                    _remoteEntity.remoteBranch = cmd;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    _setSuccess = YES;
                    [_hub hideAnimated:YES];
                    [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                    [timer invalidate];
                    timer = nil;
                } failure:^(NSError * _Nonnull error) {
                    
                }];
            });
        }];
    }else if ([_remoteEntity.shortName isEqualToString:@"6RSIBH"]
              || [self.remoteEntity.shortName isEqualToString:@"H1CSWB"]
              || [self.remoteEntity.shortName isEqualToString:@"H2CSWB"]
              || [self.remoteEntity.shortName isEqualToString:@"H3CSWB"]
              || [self.remoteEntity.shortName isEqualToString:@"H4CSWB"]
              || [self.remoteEntity.shortName isEqualToString:@"H6CSWB"]
              || [self.remoteEntity.shortName isEqualToString:@"H1CSB"]
              || [self.remoteEntity.shortName isEqualToString:@"H2CSB"]
              || [self.remoteEntity.shortName isEqualToString:@"H3CSB"]
              || [self.remoteEntity.shortName isEqualToString:@"H4CSB"]
              || [self.remoteEntity.shortName isEqualToString:@"H6CSB"]
              || [self.remoteEntity.shortName isEqualToString:@"KT6RS"]
              || [self.remoteEntity.shortName isEqualToString:@"H1RSMB"]
              || [self.remoteEntity.shortName isEqualToString:@"H2RSMB"]
              || [self.remoteEntity.shortName isEqualToString:@"H3RSMB"]
              || [self.remoteEntity.shortName isEqualToString:@"H4RSMB"]
              || [self.remoteEntity.shortName isEqualToString:@"H5RSMB"]
              || [self.remoteEntity.shortName isEqualToString:@"H6RSMB"]) {
        NSString *cmd = @"9b1f06";
        for (SelectModel *mod in _settingSelectMutArray) {
            NSString *sw = [CSRUtilities stringWithHexNumber:[mod.sourceID integerValue]];
            NSString *rc = [CSRUtilities exchangePositionOfDeviceId:[mod.channel integerValue]];
            NSString *dst = [CSRUtilities exchangePositionOfDeviceId:[mod.deviceID integerValue]];
            cmd = [NSString stringWithFormat:@"%@%@%@%@",cmd,sw,rc,dst];
        }
        
        [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
            _remoteEntity.remoteBranch = cmd;
            [[CSRDatabaseManager sharedInstance] saveContext];
            _setSuccess = YES;
            [_hub hideAnimated:YES];
            [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
            [timer invalidate];
            timer = nil;
        } failure:^(NSError * _Nonnull error) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                    _remoteEntity.remoteBranch = cmd;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    _setSuccess = YES;
                    [_hub hideAnimated:YES];
                    [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                    [timer invalidate];
                    timer = nil;
                } failure:^(NSError * _Nonnull error) {
                    
                }];
            });
        }];
    }else {
        if (/*[[CSRAppStateManager sharedInstance].selectedPlace.color boolValue]*/
            [_remoteEntity.cvVersion integerValue] < 18) {
            if ([_remoteEntity.shortName isEqualToString:@"RB01"]||[_remoteEntity.shortName isEqualToString:@"RB05"]) {
                
                NSString *cmdStr1;
                NSString *cmdStr2;
                NSString *cmdStr3;
                NSString *cmdStr4;
                
                for (int i=0; i<4; i++) {
                    SelectModel *mod = [_settingSelectMutArray objectAtIndex:i];
                    NSString *rc = [CSRUtilities exchangePositionOfDeviceId:[mod.channel integerValue]];
                    NSString *dst = [CSRUtilities exchangePositionOfDeviceId:[mod.deviceID integerValue]];
                    NSInteger channelInt = [mod.channel integerValue];
                    if (channelInt == 0) {
                        switch (i) {
                            case 0:
                                cmdStr1 = @"730701010000000000";
                                break;
                            case 1:
                                cmdStr2 = @"730701020000000000";
                                break;
                            case 2:
                                cmdStr3 = @"730701030000000000";
                                break;
                            case 3:
                                cmdStr4 = @"730701040000000000";
                                break;
                            default:
                                break;
                        }
                    }else if (channelInt >= 64 && channelInt <= 65535) {
                        switch (i) {
                            case 0:
                                cmdStr1 = [self cmdStringWithSceneRcIndex:[mod.channel integerValue] swIndex:1];
                                break;
                            case 1:
                                cmdStr2 = [self cmdStringWithSceneRcIndex:[mod.channel integerValue] swIndex:2];
                                break;
                            case 2:
                                cmdStr3 = [self cmdStringWithSceneRcIndex:[mod.channel integerValue] swIndex:3];
                                break;
                            case 3:
                                cmdStr4 = [self cmdStringWithSceneRcIndex:[mod.channel integerValue] swIndex:4];
                                break;
                            default:
                                break;
                        }
                    }else {
                        switch (i) {
                            case 0:
                                cmdStr1 = [NSString stringWithFormat:@"730e0101%@010000%@0000000000",rc,dst];
                                break;
                            case 1:
                                cmdStr2 = [NSString stringWithFormat:@"730e0102%@010000%@0000000000",rc,dst];
                                break;
                            case 2:
                                cmdStr3 = [NSString stringWithFormat:@"730e0103%@010000%@0000000000",rc,dst];
                                break;
                            case 3:
                                cmdStr4 = [NSString stringWithFormat:@"730e0104%@010000%@0000000000",rc,dst];
                                break;
                            default:
                                break;
                        }
                    }
                }
                
                dispatch_queue_t queue = dispatch_queue_create("串行", NULL);
                dispatch_async(queue, ^{
                    
                    if (cmdStr1.length>0) {
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdStr1] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                                dispatch_semaphore_signal(semaphore);
                                timerSeconde = 20;
                            } failure:^(NSError * _Nonnull error) {
                                
                            }];
                        });
                        
                        NSLog(@"信号量-1 第一个按键  %@",cmdStr1);
                        
                    }else {
                        [self showTextHud:[NSString stringWithFormat:@"%@",AcTECLocalizedStringFromTable(@"outLargeScene", @"Localizable")]];
                    }
                    
                });
                
                dispatch_async(queue, ^{
                    
                    if (cmdStr2.length>0) {
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdStr2] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                                dispatch_semaphore_signal(semaphore);
                                timerSeconde = 20;
                            } failure:^(NSError * _Nonnull error) {
                                
                            }];
                        });
                        
                        NSLog(@"信号量-1 第二个按键  %@",cmdStr2);
                        
                    }else {
                        [self showTextHud:[NSString stringWithFormat:@"%@",AcTECLocalizedStringFromTable(@"outLargeScene", @"Localizable")]];
                    }
                    
                });
                
                dispatch_async(queue, ^{
                    
                    if (cmdStr3.length>0) {
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdStr3] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                                dispatch_semaphore_signal(semaphore);
                                timerSeconde = 20;
                            } failure:^(NSError * _Nonnull error) {
                                
                            }];
                        });
                        
                        NSLog(@"信号量-1 第三个按键  %@",cmdStr3);
                        
                    }else {
                        [self showTextHud:[NSString stringWithFormat:@"%@",AcTECLocalizedStringFromTable(@"outLargeScene", @"Localizable")]];
                    }
                    
                });
                
                
                
                dispatch_async(queue, ^{
                    
                    if (cmdStr4.length>0) {
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdStr4] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                                NSLog(@"+++++++++++ 完成");
                                
                                dispatch_semaphore_signal(semaphore);
                                NSString *remoteBranch = [NSString stringWithFormat:@"%@|%@|%@|%@",[cmdStr1 substringFromIndex:6],[cmdStr2 substringFromIndex:6],[cmdStr3 substringFromIndex:6],[cmdStr4 substringFromIndex:6]];
                                _remoteEntity.remoteBranch = remoteBranch;
                                [[CSRDatabaseManager sharedInstance] saveContext];
                                _setSuccess = YES;
                                [_hub hideAnimated:YES];
                                [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                                [timer invalidate];
                                timer = nil;
                            } failure:^(NSError * _Nonnull error) {
                                
                            }];
                        });
                        
                        NSLog(@"信号量-1 第四个按键  %@",cmdStr4);
                        
                    }else {
                        [self showTextHud:[NSString stringWithFormat:@"%@",AcTECLocalizedStringFromTable(@"outLargeScene", @"Localizable")]];
                    }
                    
                });
            }else if ([_remoteEntity.shortName isEqualToString:@"RB02"]
                      ||[_remoteEntity.shortName isEqualToString:@"RB06"]
                      ||[_remoteEntity.shortName isEqualToString:@"RSBH"]
                      ||[_remoteEntity.shortName isEqualToString:@"1BMBH"]) {
                NSString *cmdStr;
                SelectModel *mod = [_settingSelectMutArray objectAtIndex:0];
                NSString *rc = [CSRUtilities exchangePositionOfDeviceId:[mod.channel integerValue]];
                NSString *dst = [CSRUtilities exchangePositionOfDeviceId:[mod.deviceID integerValue]];
                NSInteger channelInt = [mod.channel integerValue];
                if (channelInt == 0) {
                    cmdStr = @"730701010000000000";
                }else if (channelInt >= 64 && channelInt <= 65535) {
                    cmdStr = [self cmdStringWithSceneRcIndex:[mod.channel integerValue] swIndex:1];
                }else {
                    cmdStr = [NSString stringWithFormat:@"730e0101%@010000%@0000000000",rc,dst];
                }
                
                if (cmdStr.length>0) {
                    [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdStr] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                        
                        NSString *remoteBranch = [NSString stringWithFormat:@"%@",[cmdStr substringFromIndex:6]];
                        _remoteEntity.remoteBranch = remoteBranch;
                        [[CSRDatabaseManager sharedInstance] saveContext];
                        _setSuccess = YES;
                        [_hub hideAnimated:YES];
                        [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                        [timer invalidate];
                        timer = nil;
                    } failure:^(NSError * _Nonnull error) {
                        
                    }];
                }else {
                    [self showTextHud:[NSString stringWithFormat:@"%@",AcTECLocalizedStringFromTable(@"outLargeScene", @"Localizable")]];
                }
            } else if ([_remoteEntity.shortName isEqualToString:@"RB07"]) {
                
                NSString *cmdStr1;
                NSString *cmdStr2;
                
                for (int i=0; i<4; i++) {
                    SelectModel *mod = [_settingSelectMutArray objectAtIndex:i];
                    NSString *rc = [CSRUtilities exchangePositionOfDeviceId:[mod.channel integerValue]];
                    NSString *dst = [CSRUtilities exchangePositionOfDeviceId:[mod.deviceID integerValue]];
                    NSInteger channelInt = [mod.channel integerValue];
                    if (channelInt == 0) {
                        switch (i) {
                            case 0:
                                cmdStr1 = @"730701010000000000";
                                break;
                            case 1:
                                cmdStr2 = @"730701020000000000";
                                break;
                            default:
                                break;
                        }
                    }else if (channelInt >= 64 && channelInt <= 65535) {
                        switch (i) {
                            case 0:
                                cmdStr1 = [self cmdStringWithSceneRcIndex:[mod.channel integerValue] swIndex:1];
                                break;
                            case 1:
                                cmdStr2 = [self cmdStringWithSceneRcIndex:[mod.channel integerValue] swIndex:2];
                                break;
                            default:
                                break;
                        }
                    }else {
                        switch (i) {
                            case 0:
                                cmdStr1 = [NSString stringWithFormat:@"730e0101%@010000%@0000000000",rc,dst];
                                break;
                            case 1:
                                cmdStr2 = [NSString stringWithFormat:@"730e0102%@010000%@0000000000",rc,dst];
                                break;
                            default:
                                break;
                        }
                    }
                }
                
                dispatch_queue_t queue = dispatch_queue_create("串行", NULL);
                dispatch_async(queue, ^{
                    
                    if (cmdStr1.length>0) {
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdStr1] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                                dispatch_semaphore_signal(semaphore);
                                timerSeconde = 20;
                            } failure:^(NSError * _Nonnull error) {
                                
                            }];
                        });
                        
                        NSLog(@"信号量-1 第一个按键  %@",cmdStr1);
                        
                    }else {
                        [self showTextHud:[NSString stringWithFormat:@"%@",AcTECLocalizedStringFromTable(@"outLargeScene", @"Localizable")]];
                    }
                    
                });
                
                dispatch_async(queue, ^{
                    
                    if (cmdStr2.length>0) {
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdStr2] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                                dispatch_semaphore_signal(semaphore);
                                NSString *remoteBranch = [NSString stringWithFormat:@"%@|%@",[cmdStr1 substringFromIndex:6],[cmdStr2 substringFromIndex:6]];
                                _remoteEntity.remoteBranch = remoteBranch;
                                [[CSRDatabaseManager sharedInstance] saveContext];
                                _setSuccess = YES;
                                [_hub hideAnimated:YES];
                                [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                                [timer invalidate];
                                timer = nil;
                            } failure:^(NSError * _Nonnull error) {
                                
                            }];
                        });
                        
                        NSLog(@"信号量-1 第二个按键  %@",cmdStr2);
                        
                    }else {
                        [self showTextHud:[NSString stringWithFormat:@"%@",AcTECLocalizedStringFromTable(@"outLargeScene", @"Localizable")]];
                    }
                    
                });
            }
            
        }else {
            if ([_remoteEntity.shortName isEqualToString:@"RB01"]||[_remoteEntity.shortName isEqualToString:@"RB05"]) {
                NSString *cmd = @"9b1504";
                for (SelectModel *mod in _settingSelectMutArray) {
                    NSString *sw = [CSRUtilities stringWithHexNumber:[mod.sourceID integerValue]];
                    NSString *rc = [CSRUtilities exchangePositionOfDeviceId:[mod.channel integerValue]];
                    NSString *dst = [CSRUtilities exchangePositionOfDeviceId:[mod.deviceID integerValue]];
                    cmd = [NSString stringWithFormat:@"%@%@%@%@",cmd,sw,rc,dst];
                }
                
                [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                    _remoteEntity.remoteBranch = cmd;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    _setSuccess = YES;
                    [_hub hideAnimated:YES];
                    [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                    [timer invalidate];
                    timer = nil;
                } failure:^(NSError * _Nonnull error) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                            _remoteEntity.remoteBranch = cmd;
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            _setSuccess = YES;
                            [_hub hideAnimated:YES];
                            [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                            [timer invalidate];
                            timer = nil;
                        } failure:^(NSError * _Nonnull error) {
                            
                        }];
                    });
                }];
            }else if ([_remoteEntity.shortName isEqualToString:@"RB02"]
                      ||[_remoteEntity.shortName isEqualToString:@"S10IB-H2"]
                      ||[_remoteEntity.shortName isEqualToString:@"RB06"]
                      ||[_remoteEntity.shortName isEqualToString:@"RSBH"]
                      ||[_remoteEntity.shortName isEqualToString:@"1BMBH"]
                      ||[_remoteEntity.shortName isEqualToString:@"RB08"]) {
                
                NSString *cmd = @"9b0601";
                for (SelectModel *mod in _settingSelectMutArray) {
                    NSString *sw = [CSRUtilities stringWithHexNumber:[mod.sourceID integerValue]];
                    NSString *rc = [CSRUtilities exchangePositionOfDeviceId:[mod.channel integerValue]];
                    NSString *dst = [CSRUtilities exchangePositionOfDeviceId:[mod.deviceID integerValue]];
                    cmd = [NSString stringWithFormat:@"%@%@%@%@",cmd,sw,rc,dst];
                }
                
                [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                    _remoteEntity.remoteBranch = cmd;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    _setSuccess = YES;
                    [_hub hideAnimated:YES];
                    [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                    [timer invalidate];
                    timer = nil;
                } failure:^(NSError * _Nonnull error) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                            _remoteEntity.remoteBranch = cmd;
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            _setSuccess = YES;
                            [_hub hideAnimated:YES];
                            [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                            [timer invalidate];
                            timer = nil;
                        } failure:^(NSError * _Nonnull error) {
                            
                        }];
                    });
                }];
            }else if ([_remoteEntity.shortName isEqualToString:@"RB07"]) {
                NSString *cmd = @"9b0602";
                for (SelectModel *mod in _settingSelectMutArray) {
                    NSString *sw = [CSRUtilities stringWithHexNumber:[mod.sourceID integerValue]];
                    NSString *rc = [CSRUtilities exchangePositionOfDeviceId:[mod.channel integerValue]];
                    NSString *dst = [CSRUtilities exchangePositionOfDeviceId:[mod.deviceID integerValue]];
                    cmd = [NSString stringWithFormat:@"%@%@%@%@",cmd,sw,rc,dst];
                }
                
                [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                    _remoteEntity.remoteBranch = cmd;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    _setSuccess = YES;
                    [_hub hideAnimated:YES];
                    [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                    [timer invalidate];
                    timer = nil;
                } failure:^(NSError * _Nonnull error) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                            _remoteEntity.remoteBranch = cmd;
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            _setSuccess = YES;
                            [_hub hideAnimated:YES];
                            [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                            [timer invalidate];
                            timer = nil;
                        } failure:^(NSError * _Nonnull error) {
                            
                        }];
                    });
                }];
            }
        }
    }
}

- (IBAction)enableRemote:(UISwitch *)sender {
    [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea5001010%d",sender.on]] success:nil failure:nil];
}

- (IBAction)enablePassword:(UISwitch *)sender {
    _setSuccess = NO;
    timerSeconde = 20;
    [self showHudTogether];
    _resendCmd = [NSString stringWithFormat:@"ea620%d",sender.on];
}

- (BOOL)isSwitchByDevcieIdInt:(NSInteger)deviceIdInt {
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceIdInt]];
    if ([CSRUtilities belongToSwitch:device.shortName]) {
        return YES;
    }
    return NO;
}

- (BOOL)isContainInGroupByGroupIdInt:(NSInteger)groupIdInt {
    CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:groupIdInt]];
    __block BOOL exist;
    [area.devices enumerateObjectsUsingBlock:^(CSRDeviceEntity *device, BOOL * _Nonnull stop) {
        if ([CSRUtilities belongToSwitch:device.shortName]) {
            exist = YES;
            *stop = YES;
        }
    }];
    
    return exist;
}

- (NSString *)exchangePositionOfDeviceId:(NSInteger)deviceId {
    NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1lx",(long)deviceId]];
    if (hexString.length == 1) {
        hexString = [NSString stringWithFormat:@"000%@",hexString];
    }
    if (hexString.length == 2) {
        hexString = [NSString stringWithFormat:@"00%@",hexString];
    }
    if (hexString.length == 3) {
        hexString = [NSString stringWithFormat:@"0%@",hexString];
    }
    NSString *str11 = [hexString substringToIndex:2];
    NSString *str22 = [hexString substringFromIndex:2];
    NSString *deviceIdStr = [NSString stringWithFormat:@"%@%@",str22,str11];
    return deviceIdStr;
}

- (NSInteger)exchangePositionOfDeviceIdString:(NSString *)deviceIdString {
    NSString *str11 = [deviceIdString substringToIndex:2];
    NSString *str22 = [deviceIdString substringFromIndex:2];
    NSString *deviceIdStr = [NSString stringWithFormat:@"%@%@",str22,str11];
    NSInteger deviceIdInt = [CSRUtilities numberWithHexString:deviceIdStr];
    return deviceIdInt;
}

- (void)showHudTogether {
    _hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hub.mode = MBProgressHUDModeIndeterminate;
    _hub.delegate = self;
    _hub.label.font = [UIFont systemFontOfSize:13];
    _hub.label.numberOfLines = 0;
    if ([_remoteEntity.shortName isEqualToString:@"RB01"]
        || [_remoteEntity.shortName isEqualToString:@"RB02"]
        || [_remoteEntity.shortName isEqualToString:@"RB03"]
        || [_remoteEntity.shortName isEqualToString:@"R9BSBH"]
        || [_remoteEntity.shortName isEqualToString:@"R5BSBH"]
        || [_remoteEntity.shortName isEqualToString:@"5BCBH"]
        || [_remoteEntity.shortName isEqualToString:@"RB05"]
        ||[_remoteEntity.shortName isEqualToString:@"RB08"]) {
        _hub.label.text = AcTECLocalizedStringFromTable(@"RemoteOpenAlert", @"Localizable");
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerOutWaiting) userInfo:nil repeats:YES];
}

- (void)timerOutWaiting {
    
    if (!_setSuccess) {
        timerSeconde--;
        if (timerSeconde == 0) {
            [_hub hideAnimated:YES];
            [self showTextHud:AcTECLocalizedStringFromTable(@"TimeOut", @"Localizable")];
            [timer invalidate];
            timer = nil;
            _resendCmd = nil;
        }
        if (_resendCmd && [_resendCmd length]>0) {
            [[DataModelManager shareInstance] sendCmdData:_resendCmd toDeviceId:_remoteEntity.deviceId];
        }
    }
}

- (void)showTextHud:(NSString *)text {
    MBProgressHUD *successHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    successHud.mode = MBProgressHUDModeText;
    successHud.label.text = text;
    successHud.delegate = self;
    [successHud hideAnimated:YES afterDelay:1.5f];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    switch (textField.tag) {
        case 1:
            textField.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
            break;
            
        default:
            break;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    switch (textField.tag) {
        case 1:
            textField.backgroundColor = [UIColor whiteColor];
            break;
        case 2:
            if ([textField.text length]<6) {
                return NO;
            }
            break;
            
        default:
            break;
    }
    
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    switch (textField.tag) {
        case 1:
            [self saveNickName];
            break;
        case 2:
            if ([textField.text length] >=6 && [textField.text length] <= 9) {
                _setSuccess = NO;
                timerSeconde = 20;
                [self showHudTogether];
                NSString *passwordHex = [[NSString alloc] init];
                int total = (int)[textField.text length],index = 0,length = 2;
                for (int i=0; i<(total+1)/2; i++) {
                    if (total-index < 2) {
                        length = total - index;
                    }
                    NSString *exStr = [textField.text substringWithRange:NSMakeRange(index, length)];
                    index += length;
                    
                    if ([exStr length] == 2) {
                        NSString *str1 = [exStr substringToIndex:1];
                        NSString *str2 = [exStr substringFromIndex:1];
                        passwordHex = [NSString stringWithFormat:@"%@%@%@",passwordHex,str2,str1];
                    }else {
                        passwordHex = [NSString stringWithFormat:@"%@%@",passwordHex,exStr];
                    }
                }
                _resendCmd = [NSString stringWithFormat:@"ea61%@%@",[CSRUtilities stringWithHexNumber:total],passwordHex];
            }
            break;
            
        default:
            break;
    }
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    CGPoint pointx = [_customContentView convertPoint:textField.frame.origin fromView:textField.superview];
    CGPoint point = [self.view convertPoint:pointx fromView:_customContentView];
    int offset = point.y + textField.frame.size.height - (self.view.frame.size.height - 256.0);
    NSTimeInterval animaTime = 0.30f;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animaTime];
    if (offset>0) {
        self.view.frame = CGRectMake(0.0f, -offset, self.view.frame.size.width, self.view.frame.size.height);
    }
    [UIView commitAnimations];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == _passwordTF) {
        if (range.length == 1 && string.length == 0) {
            return YES;
        }else {
            NSString *aString = [textField.text stringByReplacingCharactersInRange:range withString:string];
            if ([self validateNumber:aString] && [textField.text length] < 9) {
                return YES;
            }
            return NO;
        }
    }else{
        return YES;
    }
}

- (BOOL)validateNumber:(NSString*)number {
    BOOL res = YES;
    NSCharacterSet* tmpSet = [NSCharacterSet characterSetWithCharactersInString:@"123456789"];
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

#pragma mark -

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

#pragma mark - 保存修改后的灯名

- (void)saveNickName {
    if (![_nameTF.text isEqualToString:_originalName] && _nameTF.text.length > 0) {
        self.navigationItem.title = _nameTF.text;
        self.remoteEntity.name = _nameTF.text;
        [[CSRDatabaseManager sharedInstance] saveContext];
        if (self.reloadDataHandle) {
            self.reloadDataHandle();
        }
    }
}

#pragma mark - deleteRemote

- (IBAction)deleteRemote:(UIButton *)sender {
    _deleteDevice = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:self.remoteEntity.deviceId];
    CSRPlaceEntity *placeEntity = [CSRAppStateManager sharedInstance].selectedPlace;
    if (![CSRUtilities isStringEmpty:placeEntity.passPhrase]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AcTECLocalizedStringFromTable(@"DeleteDevice", @"Localizable") message:[NSString stringWithFormat:@"%@ : %@?",AcTECLocalizedStringFromTable(@"DeleteDeviceAlert", @"Localizable"),self.remoteEntity.name] preferredStyle:UIAlertControllerStyleAlert];
        [alertController.view setTintColor:DARKORAGE];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[CSRDevicesManager sharedInstance] initiateRemoveDevice:_deleteDevice];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [_spinner stopAnimating];
            [_spinner setHidden:YES];
        }];
        [alertController addAction:okAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.view addSubview:_spinner];
        _spinner.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        [_spinner startAnimating];
    }
    else
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert!!"
                                                                                 message:@"You should be place owner to associate a device"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             
                                                         }];
        
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

-(void)deleteStatus:(NSNotification *)notification
{
    [_spinner stopAnimating];
    
    NSNumber *num = notification.userInfo[@"boolFlag"];
    if ([num boolValue] == NO) {
        [self showForceAlert];
    } else {
        [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:self.remoteEntity];
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:self.remoteEntity];
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        if (self.reloadDataHandle) {
            self.reloadDataHandle();
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void) showForceAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AcTECLocalizedStringFromTable(@"DeleteDevice", @"Localizable")
                                                                             message:[NSString stringWithFormat:@"%@ %@ ？",AcTECLocalizedStringFromTable(@"DeleteDeviceOffLine", @"Localizable"), _deleteDevice.name]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController.view setTintColor:DARKORAGE];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [_spinner stopAnimating];
                                                             [_spinner setHidden:YES];
                                                         }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         
                                                         [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:self.remoteEntity];
                                                         [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:self.remoteEntity];
                                                         [[CSRDatabaseManager sharedInstance] saveContext];
                                                         
                                                         if (self.reloadDataHandle) {
                                                             self.reloadDataHandle();
                                                         }
                                                         [self.navigationController popViewControllerAnimated:YES];
                                                     }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)fillControlLabel:(UILabel *)controlLabel selectedLabel:(UILabel *)selectedLabel selectModel:(SelectModel *)sMod {
    NSInteger channelInt = [sMod.channel integerValue];
    if (channelInt == 0) {
        controlLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        selectedLabel.text = @"";
    }else if (channelInt >= 1 && channelInt <= 9) {
        controlLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:sMod.deviceID];
        if (device) {
            selectedLabel.text = device.name;
        }else {
            selectedLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
        }
    }else if (channelInt >= 32 && channelInt <= 35) {
        controlLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
        CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:sMod.deviceID];
        if (area) {
            selectedLabel.text = area.areaName;
        }else {
            selectedLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
        }
    }else if (channelInt >= 64 && channelInt <= 65535) {
        controlLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
        SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:sMod.channel];
        if (scene) {
            selectedLabel.text = scene.sceneName;
        }else {
            selectedLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
        }
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

- (UIView *)keyTypeSettingView {
    if (!_keyTypeSettingView) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteKeyTypeCall:) name:@"remoteKeyTypeCall" object:nil];
        _keyTypeSettingView = [[UIView alloc] initWithFrame:CGRectZero];
        _keyTypeSettingView.backgroundColor = [UIColor whiteColor];
        _keyTypeSettingView.alpha = 0.9;
        _keyTypeSettingView.layer.borderColor = DARKORAGE.CGColor;
        _keyTypeSettingView.layer.borderWidth = 1.0;
        _keyTypeSettingView.layer.cornerRadius = 14.0;
        _keyTypeSettingView.layer.masksToBounds = YES;
        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
        lab.text = @"       TOGGLE  MOMENTARY";
        lab.font = [UIFont systemFontOfSize:12.0];
        lab.textAlignment = NSTextAlignmentCenter;
        lab.textColor = DARKORAGE;
        [_keyTypeSettingView addSubview:lab];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 40, 200, 1)];
        line.backgroundColor = DARKORAGE;
        [_keyTypeSettingView addSubview:line];
        
        NSArray *array = [NSArray arrayWithObjects:@"TOG",@"MOM", nil];
        for (int i=0; i<keyCount; i++) {
            UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:array];
            segment.frame = CGRectMake(50, 51+i*45, 100, 30);
            segment.tag = i+100;
            segment.tintColor = DARKORAGE;
            [_keyTypeSettingView addSubview:segment];
        }
        
        UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(0, 91+45*(keyCount-1), 200, 1)];
        line1.backgroundColor = DARKORAGE;
        [_keyTypeSettingView addSubview:line1];
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 92+45*(keyCount-1), 200, 40)];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(keyTypeSettingCommandSendingAction:) forControlEvents:UIControlEventTouchUpInside];
        [_keyTypeSettingView addSubview:btn];
    }
    return _keyTypeSettingView;
}

- (void)keyTypeSettingAction {
    [self.view addSubview:self.keyTypeSettingView];
    [self.keyTypeSettingView autoCenterInSuperview];
    [self.keyTypeSettingView autoSetDimensionsToSize:CGSizeMake(200, 132+45*(keyCount-1))];
    
    [[DataModelManager shareInstance] sendCmdData:@"ea54" toDeviceId:_remoteEntity.deviceId];
    
}

- (void)keyTypeSettingCommandSendingAction:(UIButton *)button {
    NSString *cmd=@"";
    UIView *supView = button.superview;
    for (int i=0; i<keyCount; i++) {
        UISegmentedControl *segment = (UISegmentedControl *)[supView viewWithTag:100+i];
        if (segment.selectedSegmentIndex == 1) {
            cmd = [NSString stringWithFormat:@"%@%@",cmd,@"01"];
        }else {
            cmd = [NSString stringWithFormat:@"%@%@",cmd,@"00"];
        }
    }
    [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"ea53%@",cmd] toDeviceId:_remoteEntity.deviceId];
}

- (void)remoteKeyTypeCall:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    NSNumber *deviceId = info[@"deviceId"];
    if ([deviceId isEqualToNumber:_remoteEntity.deviceId]) {
        NSString *dataStr = info[@"remoteKeyTypeCall"];
        for (int i=0; i<keyCount; i++) {
            NSString *type = [dataStr substringWithRange:NSMakeRange(1+i*2, 2)];
            UISegmentedControl *segment = (UISegmentedControl *)[self.keyTypeSettingView viewWithTag:100+i];
            [type isEqualToString:@"00"]? [segment setSelectedSegmentIndex:0]:[segment setSelectedSegmentIndex:1];
        }
        if ([[dataStr substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"3"]) {
            [self.keyTypeSettingView removeFromSuperview];
            self.keyTypeSettingView = nil;
        }
    }
}

- (IBAction)readRemoteConfig:(UIButton *)sender {
    if ([_remoteEntity.shortName isEqualToString:@"RB01"]
        || [_remoteEntity.shortName isEqualToString:@"RB02"]
        || [_remoteEntity.shortName isEqualToString:@"RB03"]
        || [_remoteEntity.shortName isEqualToString:@"R9BSBH"]
        || [_remoteEntity.shortName isEqualToString:@"R5BSBH"]
        || [_remoteEntity.shortName isEqualToString:@"5BCBH"]
        || [_remoteEntity.shortName isEqualToString:@"RB05"]
        ||[_remoteEntity.shortName isEqualToString:@"RB08"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"remotereadalert", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            Byte byte[] = {0x71, 0x01, 0x00};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_remoteEntity.deviceId data:cmd];
        }];
        [alert addAction:yes];
        [self presentViewController:alert animated:YES completion:nil];
    }else {
        Byte byte[] = {0x71, 0x01, 0x00};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_remoteEntity.deviceId data:cmd];
    }
}

- (void)getRemoteConfiguration:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    NSNumber *deviceId = info[@"deviceId"];
    if ([deviceId isEqualToNumber:_remoteEntity.deviceId]) {
        [_settingSelectMutArray removeAllObjects];
        if ([self.remoteEntity.shortName isEqualToString:@"RB01"]||[self.remoteEntity.shortName isEqualToString:@"RB05"]) {
            for (int i=0; i<4; i++) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @(i+1);
                mod.channel = @(0);
                mod.deviceID = @(0);
                [_settingSelectMutArray insertObject:mod atIndex:i];
            }
            _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _fSelectOneLabel.text = @"";
            _fSelectTwoLabel.text = @"";
            _fSelectThreeLabel.text = @"";
            _fSelectFourLabel.text = @"";
            if (self.remoteEntity.remoteBranch.length >= 16) {
                NSInteger c = (self.remoteEntity.remoteBranch.length-6) / 10;
                for (int i=0; i<c; i++) {
                   NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
                    SelectModel *mod = [[SelectModel alloc] init];
                    NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                    NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                    mod.channel = @(channelInt);
                    NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                    mod.deviceID = @(deviceIDInt);
                    mod.sourceID = @(s);
                    [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                    switch (s-1) {
                        case 0:
                            [self fillControlLabel:_fConrolOneLabel selectedLabel:_fSelectOneLabel selectModel:mod];
                            break;
                        case 1:
                            [self fillControlLabel:_fConrolTwoLabel selectedLabel:_fSelectTwoLabel selectModel:mod];
                            break;
                        case 2:
                            [self fillControlLabel:_fConrolThreeLabel selectedLabel:_fSelectThreeLabel selectModel:mod];
                            break;
                        case 3:
                            [self fillControlLabel:_fConrolFourLabel selectedLabel:_fSelectFourLabel selectModel:mod];
                            break;
                        default:
                            break;
                    }
                }
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"RB02"]
                  ||[_remoteEntity.shortName isEqualToString:@"RB06"]
                  ||[_remoteEntity.shortName isEqualToString:@"RSBH"]
                  ||[_remoteEntity.shortName isEqualToString:@"1BMBH"]
                  ||[_remoteEntity.shortName isEqualToString:@"RB08"]) {
            SelectModel *mod = [[SelectModel alloc] init];
            mod.sourceID = @(1);
            mod.channel = @(0);
            mod.deviceID = @(0);
            [_settingSelectMutArray insertObject:mod atIndex:0];
            _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _sSelectOneLabel.text = @"";
            if (self.remoteEntity.remoteBranch.length >= 16) {
                NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(6, 10)];
                 SelectModel *mod = [[SelectModel alloc] init];
                 NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                 NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                 mod.channel = @(channelInt);
                 NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                 mod.deviceID = @(deviceIDInt);
                 mod.sourceID = @(s);
                 [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                [self fillControlLabel:_sConrolOneLabel selectedLabel:_sSelectOneLabel selectModel:mod];
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"RB04"]
                  || [self.remoteEntity.shortName isEqualToString:@"RSIBH"]
                  || [self.remoteEntity.shortName isEqualToString:@"S10IB-H2"]) {
            for (int i=0; i<2; i++) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @(i+1);
                mod.channel = @(0);
                mod.deviceID = @(0);
                [_settingSelectMutArray insertObject:mod atIndex:i];
            }
            _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _tSelectOneLabel.text = @"";
            _tSelectTwoLabel.text = @"";
            if (self.remoteEntity.remoteBranch.length >= 16) {
                NSInteger c = (self.remoteEntity.remoteBranch.length-6) / 10;
                for (int i=0; i<c; i++) {
                   NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
                    SelectModel *mod = [[SelectModel alloc] init];
                    NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                    NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                    mod.channel = @(channelInt);
                    NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                    mod.deviceID = @(deviceIDInt);
                    mod.sourceID = @(s);
                    [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                    switch (s-1) {
                        case 0:
                            [self fillControlLabel:_tConrolOneLabel selectedLabel:_tSelectOneLabel selectModel:mod];
                            break;
                        case 1:
                            [self fillControlLabel:_tConrolTwoLabel selectedLabel:_tSelectTwoLabel selectModel:mod];
                            break;
                        default:
                            break;
                    }
                }
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"R5BSBH"]
                  || [self.remoteEntity.shortName isEqualToString:@"RB09"]
                  || [self.remoteEntity.shortName isEqualToString:@"5RSIBH"]
                  || [self.remoteEntity.shortName isEqualToString:@"5BCBH"]) {
            [_settingSelectMutArray removeAllObjects];
            for (int i=0; i<5; i++) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @(i+1);
                mod.channel = @(0);
                mod.deviceID = @(0);
                [_settingSelectMutArray insertObject:mod atIndex:i];
            }
            _R5BSHBControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R5BSHBControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R5BSHBControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R5BSHBControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R5BSHBControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R5BSHBSelectOneLabel.text = @"";
            _R5BSHBSelectTwoLabel.text = @"";
            _R5BSHBSelectThreeLabel.text = @"";
            _R5BSHBSelectFourLabel.text = @"";
            _R5BSHBSelectFiveLabel.text = @"";
            if (self.remoteEntity.remoteBranch.length >= 16) {
                NSInteger c = (self.remoteEntity.remoteBranch.length-6) / 10;
                for (int i=0; i<c; i++) {
                   NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
                    SelectModel *mod = [[SelectModel alloc] init];
                    NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                    NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                    mod.channel = @(channelInt);
                    NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                    mod.deviceID = @(deviceIDInt);
                    if (s == 0) {
                        mod.sourceID = @(5);
                        [_settingSelectMutArray replaceObjectAtIndex:4 withObject:mod];
                    }else {
                        mod.sourceID = @(s);
                        [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                    }
                    switch (s-1) {
                        case 0:
                            [self fillControlLabel:_R5BSHBControlOneLabel selectedLabel:_R5BSHBSelectOneLabel selectModel:mod];
                            break;
                        case 1:
                            [self fillControlLabel:_R5BSHBControlTwoLabel selectedLabel:_R5BSHBSelectTwoLabel selectModel:mod];
                            break;
                        case 2:
                            [self fillControlLabel:_R5BSHBControlThreeLabel selectedLabel:_R5BSHBSelectThreeLabel selectModel:mod];
                            break;
                        case 3:
                            [self fillControlLabel:_R5BSHBControlFourLabel selectedLabel:_R5BSHBSelectFourLabel selectModel:mod];
                            break;
                        case -1:
                        case 4:
                            [self fillControlLabel:_R5BSHBControlFiveLabel selectedLabel:_R5BSHBSelectFiveLabel selectModel:mod];
                            break;
                        default:
                            break;
                    }
                }
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"R9BSBH"]) {
            for (int i=0; i<9; i++) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @(i+1);
                mod.channel = @(0);
                mod.deviceID = @(0);
                [_settingSelectMutArray insertObject:mod atIndex:i];
            }
            _R9BSBHControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlSixLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlSevenLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlEightLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlNineLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHSelectOneLabel.text = @"";
            _R9BSBHSelectTwoLabel.text = @"";
            _R9BSBHSelectThreeLabel.text = @"";
            _R9BSBHSelectFourLabel.text = @"";
            _R9BSBHSelectFiveLabel.text = @"";
            _R9BSBHSelectSixLabel.text = @"";
            _R9BSBHSelectSevenLabel.text = @"";
            _R9BSBHSelectEightLabel.text = @"";
            _R9BSBHSelectNineLabel.text = @"";
            if (self.remoteEntity.remoteBranch.length >= 16) {
                NSInteger c = (self.remoteEntity.remoteBranch.length-6) / 10;
                for (int i=0; i<c; i++) {
                   NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
                    SelectModel *mod = [[SelectModel alloc] init];
                    NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                    NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                    mod.channel = @(channelInt);
                    NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                    mod.deviceID = @(deviceIDInt);
                    mod.sourceID = @(s);
                    [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                    switch (s-1) {
                        case 0:
                            [self fillControlLabel:_R9BSBHControlOneLabel selectedLabel:_R9BSBHSelectOneLabel selectModel:mod];
                            break;
                        case 1:
                            [self fillControlLabel:_R9BSBHControlTwoLabel selectedLabel:_R9BSBHSelectTwoLabel selectModel:mod];
                            break;
                        case 2:
                            [self fillControlLabel:_R9BSBHControlThreeLabel selectedLabel:_R9BSBHSelectThreeLabel selectModel:mod];
                            break;
                        case 3:
                            [self fillControlLabel:_R9BSBHControlFourLabel selectedLabel:_R9BSBHSelectFourLabel selectModel:mod];
                            break;
                        case 4:
                            [self fillControlLabel:_R9BSBHControlFiveLabel selectedLabel:_R9BSBHSelectFiveLabel selectModel:mod];
                            break;
                        case 5:
                            [self fillControlLabel:_R9BSBHControlSixLabel selectedLabel:_R9BSBHSelectSixLabel selectModel:mod];
                            break;
                        case 6:
                            [self fillControlLabel:_R9BSBHControlSevenLabel selectedLabel:_R9BSBHSelectSevenLabel selectModel:mod];
                            break;
                        case 7:
                            [self fillControlLabel:_R9BSBHControlEightLabel selectedLabel:_R9BSBHSelectEightLabel selectModel:mod];
                            break;
                        case 8:
                            [self fillControlLabel:_R9BSBHControlNineLabel selectedLabel:_R9BSBHSelectNineLabel selectModel:mod];
                            break;
                        default:
                            break;
                    }
                }
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"RB07"]) {
            for (int i=0; i<2; i++) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @(i+1);
                mod.channel = @(0);
                mod.deviceID = @(0);
                [_settingSelectMutArray insertObject:mod atIndex:i];
            }
            _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _tSelectOneLabel.text = @"";
            _tSelectTwoLabel.text = @"";
            if (self.remoteEntity.remoteBranch.length >= 16) {
                NSInteger c = (self.remoteEntity.remoteBranch.length-6) / 10;
                for (int i=0; i<c; i++) {
                   NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
                    SelectModel *mod = [[SelectModel alloc] init];
                    NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                    NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                    mod.channel = @(channelInt);
                    NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                    mod.deviceID = @(deviceIDInt);
                    mod.sourceID = @(s);
                    [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                    switch (s-1) {
                        case 0:
                            [self fillControlLabel:_tConrolOneLabel selectedLabel:_tSelectOneLabel selectModel:mod];
                            break;
                        case 1:
                            [self fillControlLabel:_tConrolTwoLabel selectedLabel:_tSelectTwoLabel selectModel:mod];
                            break;
                        default:
                            break;
                    }
                }
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"6RSIBH"]
                  || [self.remoteEntity.shortName isEqualToString:@"H1CSWB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H2CSWB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H3CSWB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H4CSWB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H6CSWB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H1CSB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H2CSB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H3CSB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H4CSB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H6CSB"]
                  || [self.remoteEntity.shortName isEqualToString:@"KT6RS"]
                  || [self.remoteEntity.shortName isEqualToString:@"H1RSMB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H2RSMB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H3RSMB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H4RSMB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H5RSMB"]
                  || [self.remoteEntity.shortName isEqualToString:@"H6RSMB"]) {
            for (int i=0; i<6; i++) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @(i+1);
                mod.channel = @(0);
                mod.deviceID = @(0);
                [_settingSelectMutArray insertObject:mod atIndex:i];
            }
            _sixKeyControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _sixKeyControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _sixKeyControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _sixKeyControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _sixKeyControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _sixKeyControlSixLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            if (self.remoteEntity.remoteBranch.length >= 16) {
                NSInteger c = (self.remoteEntity.remoteBranch.length-6) / 10;
                for (int i=0; i<c; i++) {
                   NSString *str = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
                    SelectModel *mod = [[SelectModel alloc] init];
                    NSInteger s = [CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]];
                    NSInteger channelInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]];
                    mod.channel = @(channelInt);
                    NSInteger deviceIDInt = [self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]];
                    mod.deviceID = @(deviceIDInt);
                    mod.sourceID = @(s);
                    [_settingSelectMutArray replaceObjectAtIndex:s-1 withObject:mod];
                    switch (s-1) {
                        case 0:
                            [self fillControlLabel:_sixKeyControlOneLabel selectedLabel:_sixKeySelectOneLabel selectModel:mod];
                            break;
                        case 1:
                            [self fillControlLabel:_sixKeyControlTwoLabel selectedLabel:_sixKeySelectTwoLabel selectModel:mod];
                            break;
                        case 2:
                            [self fillControlLabel:_sixKeyControlThreeLabel selectedLabel:_sixKeySelectThreeLabel selectModel:mod];
                            break;
                        case 3:
                            [self fillControlLabel:_sixKeyControlFourLabel selectedLabel:_sixKeySelectFourLabel selectModel:mod];
                            break;
                        case 4:
                            [self fillControlLabel:_sixKeyControlFiveLabel selectedLabel:_sixKeySelectFiveLabel selectModel:mod];
                            break;
                        case 5:
                            [self fillControlLabel:_sixKeyControlSixLabel selectedLabel:_sixKeySelectSixLabel selectModel:mod];
                            break;
                        default:
                            break;
                    }
                }
            }

        }
    }
}

@end
