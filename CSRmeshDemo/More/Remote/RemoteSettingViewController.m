//
//  RemoteSettingViewController.m
//  CSRmeshDemo
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
#import "MCUUpdateTool.h"

@interface RemoteSettingViewController ()<UITextFieldDelegate,MBProgressHUDDelegate,MCUUpdateToolDelegate>
{
    dispatch_semaphore_t semaphore;
    NSInteger timerSeconde;
    NSTimer *timer;
    
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
    UIButton *updateMCUBtn;
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
@property (weak, nonatomic) IBOutlet UITextField *passwordTF;
@property (weak, nonatomic) IBOutlet UISwitch *passwordEnableSwitch;
@property (nonatomic, strong) NSString *resendCmd;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (nonatomic,strong) UIView *translucentBgView;

@property (strong, nonatomic) IBOutlet UIView *RB08View;
@property (weak, nonatomic) IBOutlet UILabel *RB08ControlOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *RB08SelectOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *RB08ControlTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *RB08SelectTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *RB08ControlThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *RB08SelectThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *RB08ControlFourLabel;
@property (weak, nonatomic) IBOutlet UILabel *RB08SelectFourLabel;
@property (weak, nonatomic) IBOutlet UILabel *RB08ControlFiveLabel;
@property (weak, nonatomic) IBOutlet UILabel *RB08SelectFiveLabel;
@property (weak, nonatomic) IBOutlet UILabel *RB08ControlSixLabel;
@property (weak, nonatomic) IBOutlet UILabel *RB08SelectSixLabel;

@property (strong, nonatomic) IBOutlet UIView *GR15BView;
@property (weak, nonatomic) IBOutlet UILabel *GR15BControlOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *GR15BSelectOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *GR15BControlTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *GR15BSelectTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *GR15BControlThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *GR15BSelectThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *GR15BControlFourLabel;
@property (weak, nonatomic) IBOutlet UILabel *GR15BSelectFourLabel;


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
        
        if ([[CSRAppStateManager sharedInstance].selectedPlace.color boolValue]) {
            if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length >0) {
                NSArray *remoteArray = [self.remoteEntity.remoteBranch componentsSeparatedByString:@"|"];
                for (NSString *brach in remoteArray) {
                    NSString *swIndex = [brach substringToIndex:2];
                    NSString *rcIndex = [brach substringWithRange:NSMakeRange(2, 4)];
                    
                    if ([swIndex isEqualToString:@"01"]) {
                        if ([rcIndex isEqualToString:@"0000"]) {
                            _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                            _fSelectOneLabel.text = @"";
                        }else if ([rcIndex isEqualToString:@"0100"]) {
                            _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                            NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                            if (deviceEntity) {
                                _fSelectOneLabel.text = deviceEntity.name;
                                _fSelectOneLabel.tag = deviceId;
                            }else {
                                _fSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                        }else if ([rcIndex isEqualToString:@"2000"]) {
                            _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                            NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                            if (areaEntity) {
                                _fSelectOneLabel.text = areaEntity.areaName;
                                _fSelectOneLabel.tag = areaId;
                            }else {
                                _fSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else {
                            _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                            NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                            if (sceneEntity) {
                                _fSelectOneLabel.text = sceneEntity.sceneName;
                                _fSelectOneLabel.tag = rcIndexInt;
                            }else {
                                _fSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }
                    }
                    if ([swIndex isEqualToString:@"02"]) {
                        if ([rcIndex isEqualToString:@"0000"]) {
                            _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                            _fSelectTwoLabel.text = @"";
                        }else if ([rcIndex isEqualToString:@"0100"]) {
                            _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                            NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                            if (deviceEntity) {
                                _fSelectTwoLabel.text = deviceEntity.name;
                                _fSelectTwoLabel.tag = deviceId;
                            }else {
                                _fSelectTwoLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else if ([rcIndex isEqualToString:@"2000"]) {
                            _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                            NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                            if (areaEntity) {
                                _fSelectTwoLabel.text = areaEntity.areaName;
                                _fSelectTwoLabel.tag = areaId;
                            }else {
                                _fSelectTwoLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else {
                            _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                            NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                            if (sceneEntity) {
                                _fSelectTwoLabel.text = sceneEntity.sceneName;
                                _fSelectTwoLabel.tag = rcIndexInt;
                            }else {
                                _fSelectTwoLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }
                    }
                    if ([swIndex isEqualToString:@"03"]) {
                        if ([rcIndex isEqualToString:@"0000"]) {
                            _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                            _fSelectThreeLabel.text = @"";
                        }else if ([rcIndex isEqualToString:@"0100"]) {
                            _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                            NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                            if (deviceEntity) {
                                _fSelectThreeLabel.text = deviceEntity.name;
                                _fSelectThreeLabel.tag = deviceId;
                            }else{
                                _fSelectThreeLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else if ([rcIndex isEqualToString:@"2000"]) {
                            _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                            NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                            if (areaEntity) {
                                _fSelectThreeLabel.text = areaEntity.areaName;
                                _fSelectThreeLabel.tag = areaId;
                            }else {
                                _fSelectThreeLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else {
                            _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                            NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                            if (sceneEntity) {
                                _fSelectThreeLabel.text = sceneEntity.sceneName;
                                _fSelectThreeLabel.tag = rcIndexInt;
                            }else {
                                _fSelectThreeLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }
                    }
                    if ([swIndex isEqualToString:@"04"]) {
                        if ([rcIndex isEqualToString:@"0000"]) {
                            _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                            _fSelectFourLabel.text = @"";
                        }else if ([rcIndex isEqualToString:@"0100"]) {
                            _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                            NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                            if (deviceEntity) {
                                _fSelectFourLabel.text = deviceEntity.name;
                                _fSelectFourLabel.tag = deviceId;
                            }else{
                                _fSelectFourLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else if ([rcIndex isEqualToString:@"2000"]) {
                            _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                            NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                            if (areaEntity) {
                                _fSelectFourLabel.text = areaEntity.areaName;
                                _fSelectFourLabel.tag = areaId;
                            }else {
                                _fSelectFourLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else {
                            _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                            NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                            if (sceneEntity) {
                                _fSelectFourLabel.text = sceneEntity.sceneName;
                                _fSelectFourLabel.tag = rcIndexInt;
                            }else {
                                _fSelectFourLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }
                    }
                    
                }
            }else {
                _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            }
        }else {
            if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length >= 46) {
                [self fillControlLabel:_fConrolOneLabel selectedLabel:_fSelectOneLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 8)]];
                [self fillControlLabel:_fConrolTwoLabel selectedLabel:_fSelectTwoLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(18, 8)]];
                [self fillControlLabel:_fConrolThreeLabel selectedLabel:_fSelectThreeLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(28, 8)]];
                [self fillControlLabel:_fConrolFourLabel selectedLabel:_fSelectFourLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(38, 8)]];
            }else {
                _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            }
        }
        
    }else if ([self.remoteEntity.shortName isEqualToString:@"RB02"]||[_remoteEntity.shortName isEqualToString:@"RB06"]||[_remoteEntity.shortName isEqualToString:@"RSBH"]||[_remoteEntity.shortName isEqualToString:@"1BMBH"]) {
        _practicalityImageView.image = [UIImage imageNamed:@"rb02"];
        [self.customContentView addSubview:self.singleRemoteView];
        [self.singleRemoteView autoSetDimension:ALDimensionHeight toSize:44.0f];
        [self.singleRemoteView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.singleRemoteView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.singleRemoteView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
        if ([[CSRAppStateManager sharedInstance].selectedPlace.color boolValue]) {
            if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length >= 18) {
                
                NSString *rcIndex = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(2, 4)];
                if ([rcIndex isEqualToString:@"0000"]) {
                    _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                    _sSelectOneLabel.text = @"";
                }else if ([rcIndex isEqualToString:@"0100"]) {
                    _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    NSInteger deviceId = [self exchangePositionOfDeviceIdString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(12, 4)]];
                    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                    if (deviceEntity) {
                        _sSelectOneLabel.text = deviceEntity.name;
                        _sSelectOneLabel.tag = deviceId;
                    }else {
                        _sSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                    }
                }else if ([rcIndex isEqualToString:@"2000"]) {
                    _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    NSInteger areaId = [self exchangePositionOfDeviceIdString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(12, 4)]];
                    CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                    if (areaEntity) {
                        _sSelectOneLabel.text = areaEntity.areaName;
                        _sSelectOneLabel.tag = areaId;
                    }else {
                        _sSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                    }
                    
                }else {
                    _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex];
                    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                    if (sceneEntity) {
                        _sSelectOneLabel.text = sceneEntity.sceneName;
                        _sSelectOneLabel.tag = rcIndexInt;
                    }else {
                        _sSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                    }
                }
            }else {
                _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            }
        }else {
            if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length >= 16) {
                [self fillControlLabel:_sConrolOneLabel selectedLabel:_sSelectOneLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 8)]];
            }else {
                _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            }
        }
        
    }else if ([self.remoteEntity.shortName isEqualToString:@"RB04"] || [self.remoteEntity.shortName isEqualToString:@"RSIBH"] || [self.remoteEntity.shortName isEqualToString:@"S10IB-H2"]) {
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
        
        if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length >= 26) {
            [self fillControlLabel:_tConrolOneLabel selectedLabel:_tSelectOneLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 8)]];
            [self fillControlLabel:_tConrolTwoLabel selectedLabel:_tSelectTwoLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(18, 8)]];
        }else {
            _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        }
        
    }else if ([self.remoteEntity.shortName isEqualToString:@"R5BSBH"] || [self.remoteEntity.shortName isEqualToString:@"RB09"] || [self.remoteEntity.shortName isEqualToString:@"5RSIBH"]) {
        if ([self.remoteEntity.shortName isEqualToString:@"R5BSBH"]) {
            _practicalityImageView.image = [UIImage imageNamed:@"rb01"];
        }else {
            _practicalityImageView.image = [UIImage imageNamed:@"bajiao"];
        }
        
        [self.customContentView addSubview:self.R5BSHBView];
        [self.R5BSHBView autoSetDimension:ALDimensionHeight toSize:224.0f];
        [self.R5BSHBView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.R5BSHBView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.R5BSHBView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
        
        if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length >= 56) {
            [self fillControlLabel:_R5BSHBControlOneLabel selectedLabel:_R5BSHBSelectOneLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 8)]];
            [self fillControlLabel:_R5BSHBControlTwoLabel selectedLabel:_R5BSHBSelectTwoLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(18, 8)]];
            [self fillControlLabel:_R5BSHBControlThreeLabel selectedLabel:_R5BSHBSelectThreeLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(28, 8)]];
            [self fillControlLabel:_R5BSHBControlFourLabel selectedLabel:_R5BSHBSelectFourLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(38, 8)]];
            [self fillControlLabel:_R5BSHBControlFiveLabel selectedLabel:_R5BSHBSelectFiveLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(48, 8)]];
        }else {
            _R5BSHBControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R5BSHBControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R5BSHBControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R5BSHBControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R5BSHBControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
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
        
        if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length >= 96) {
            [self fillControlLabel:_R9BSBHControlOneLabel selectedLabel:_R9BSBHSelectOneLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 8)]];
            [self fillControlLabel:_R9BSBHControlTwoLabel selectedLabel:_R9BSBHSelectTwoLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(18, 8)]];
            [self fillControlLabel:_R9BSBHControlThreeLabel selectedLabel:_R9BSBHSelectThreeLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(28, 8)]];
            [self fillControlLabel:_R9BSBHControlFourLabel selectedLabel:_R9BSBHSelectFourLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(38, 8)]];
            [self fillControlLabel:_R9BSBHControlFiveLabel selectedLabel:_R9BSBHSelectFiveLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(48, 8)]];
            [self fillControlLabel:_R9BSBHControlSixLabel selectedLabel:_R9BSBHSelectSixLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(58, 8)]];
            [self fillControlLabel:_R9BSBHControlSevenLabel selectedLabel:_R9BSBHSelectSevenLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(68, 8)]];
            [self fillControlLabel:_R9BSBHControlEightLabel selectedLabel:_R9BSBHSelectEightLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(78, 8)]];
            [self fillControlLabel:_R9BSBHControlNineLabel selectedLabel:_R9BSBHSelectNineLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(88, 8)]];
        }else {
            _R9BSBHControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlSixLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlSevenLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlEightLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R9BSBHControlNineLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        }
    }else if ([self.remoteEntity.shortName isEqualToString:@"RB07"]) {
        _practicalityImageView.image = [UIImage imageNamed:@"bajiao"];
        [self.customContentView addSubview:self.twoRemoteView];
        [self.twoRemoteView autoSetDimension:ALDimensionHeight toSize:89.0f];
        [self.twoRemoteView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.twoRemoteView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.twoRemoteView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
        if ([[CSRAppStateManager sharedInstance].selectedPlace.color boolValue]) {
            if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length >37) {
                NSArray *remoteArray = [self.remoteEntity.remoteBranch componentsSeparatedByString:@"|"];
                for (NSString *brach in remoteArray) {
                    NSString *swIndex = [brach substringToIndex:2];
                    NSString *rcIndex = [brach substringWithRange:NSMakeRange(2, 4)];
                    
                    if ([swIndex isEqualToString:@"01"]) {
                        if ([rcIndex isEqualToString:@"0000"]) {
                            _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                            _tSelectOneLabel.text = @"";
                        }else if ([rcIndex isEqualToString:@"0100"]) {
                            _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                            NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                            if (deviceEntity) {
                                _tSelectOneLabel.text = deviceEntity.name;
                                _tSelectOneLabel.tag = deviceId;
                            }else {
                                _tSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                        }else if ([rcIndex isEqualToString:@"2000"]) {
                            _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                            NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                            if (areaEntity) {
                                _tSelectOneLabel.text = areaEntity.areaName;
                                _tSelectOneLabel.tag = areaId;
                            }else {
                                _tSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else {
                            _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                            NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                            if (sceneEntity) {
                                _tSelectOneLabel.text = sceneEntity.sceneName;
                                _tSelectOneLabel.tag = rcIndexInt;
                            }else {
                                _tSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }
                    }
                    if ([swIndex isEqualToString:@"02"]) {
                        if ([rcIndex isEqualToString:@"0000"]) {
                            _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                            _tSelectTwoLabel.text = @"";
                        }else if ([rcIndex isEqualToString:@"0100"]) {
                            _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                            NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                            if (deviceEntity) {
                                _tSelectTwoLabel.text = deviceEntity.name;
                                _tSelectTwoLabel.tag = deviceId;
                            }else {
                                _tSelectTwoLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else if ([rcIndex isEqualToString:@"2000"]) {
                            _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                            NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                            if (areaEntity) {
                                _tSelectTwoLabel.text = areaEntity.areaName;
                                _tSelectTwoLabel.tag = areaId;
                            }else {
                                _tSelectTwoLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else {
                            _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                            NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                            if (sceneEntity) {
                                _tSelectTwoLabel.text = sceneEntity.sceneName;
                                _tSelectTwoLabel.tag = rcIndexInt;
                            }else {
                                _tSelectTwoLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                        }
                    }
                }
            }else {
                _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            }
        }else {
            if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length >= 26) {
                [self fillControlLabel:_tConrolOneLabel selectedLabel:_tSelectOneLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 8)]];
                [self fillControlLabel:_tConrolTwoLabel selectedLabel:_tSelectTwoLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(18, 8)]];
            }else {
                _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            }
        }
    }else if ([self.remoteEntity.shortName isEqualToString:@"RB08"] || [self.remoteEntity.shortName isEqualToString:@"GR10B"]) {
        _practicalityImageView.image = [UIImage imageNamed:@"rb08"];
        [self.customContentView addSubview:self.RB08View];
        [self.RB08View autoSetDimension:ALDimensionHeight toSize:269.0];
        [self.RB08View autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.RB08View autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.RB08View autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30.0];
        
        if ([[CSRAppStateManager sharedInstance].selectedPlace.color boolValue]) {
            if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length >0) {
                NSArray *remoteArray = [self.remoteEntity.remoteBranch componentsSeparatedByString:@"|"];
                for (NSString *brach in remoteArray) {
                    NSString *swIndex = [brach substringToIndex:2];
                    NSString *rcIndex = [brach substringWithRange:NSMakeRange(2, 4)];
                    if ([swIndex isEqualToString:@"01"]) {
                        if ([rcIndex isEqualToString:@"0000"]) {
                            _RB08ControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                            _RB08SelectOneLabel.text = @"";
                        }else if ([rcIndex isEqualToString:@"0100"]) {
                            _RB08ControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                            NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                            if (deviceEntity) {
                                _RB08SelectOneLabel.text = deviceEntity.name;
                                _RB08SelectOneLabel.tag = deviceId;
                            }else {
                                _RB08SelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                        }else if ([rcIndex isEqualToString:@"2000"]) {
                            _RB08ControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                            NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                            if (areaEntity) {
                                _RB08SelectOneLabel.text = areaEntity.areaName;
                                _RB08SelectOneLabel.tag = areaId;
                            }else {
                                _RB08SelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else {
                            _RB08ControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                            NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                            if (sceneEntity) {
                                _RB08SelectOneLabel.text = sceneEntity.sceneName;
                                _RB08SelectOneLabel.tag = rcIndexInt;
                            }else {
                                _RB08SelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                        }
                    }
                    if ([swIndex isEqualToString:@"02"]) {
                        if ([rcIndex isEqualToString:@"0000"]) {
                            _RB08ControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                            _RB08SelectTwoLabel.text = @"";
                        }else if ([rcIndex isEqualToString:@"0100"]) {
                            _RB08ControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                            NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                            if (deviceEntity) {
                                _RB08SelectTwoLabel.text = deviceEntity.name;
                                _RB08SelectTwoLabel.tag = deviceId;
                            }else {
                                _RB08SelectTwoLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else if ([rcIndex isEqualToString:@"2000"]) {
                            _RB08ControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                            NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                            if (areaEntity) {
                                _RB08SelectTwoLabel.text = areaEntity.areaName;
                                _RB08SelectTwoLabel.tag = areaId;
                            }else {
                                _RB08SelectTwoLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else {
                            _RB08ControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                            NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                            if (sceneEntity) {
                                _RB08SelectTwoLabel.text = sceneEntity.sceneName;
                                _RB08SelectTwoLabel.tag = rcIndexInt;
                            }else {
                                _RB08SelectTwoLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                        }
                    }
                    if ([swIndex isEqualToString:@"03"]) {
                        if ([rcIndex isEqualToString:@"0000"]) {
                            _RB08ControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                            _RB08SelectThreeLabel.text = @"";
                        }else if ([rcIndex isEqualToString:@"0100"]) {
                            _RB08ControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                            NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                            if (deviceEntity) {
                                _RB08SelectThreeLabel.text = deviceEntity.name;
                                _RB08SelectThreeLabel.tag = deviceId;
                            }else{
                                _RB08SelectThreeLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else if ([rcIndex isEqualToString:@"2000"]) {
                            _RB08ControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                            NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                            if (areaEntity) {
                                _RB08SelectThreeLabel.text = areaEntity.areaName;
                                _RB08SelectThreeLabel.tag = areaId;
                            }else {
                                _RB08SelectThreeLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else {
                            _RB08ControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                            NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                            if (sceneEntity) {
                                _RB08SelectThreeLabel.text = sceneEntity.sceneName;
                                _RB08SelectThreeLabel.tag = rcIndexInt;
                            }else {
                                _RB08SelectThreeLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                        }
                    }
                    if ([swIndex isEqualToString:@"04"]) {
                        if ([rcIndex isEqualToString:@"0000"]) {
                            _RB08ControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                            _RB08SelectFourLabel.text = @"";
                        }else if ([rcIndex isEqualToString:@"0100"]) {
                            _RB08ControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                            NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                            if (deviceEntity) {
                                _RB08SelectFourLabel.text = deviceEntity.name;
                                _RB08SelectFourLabel.tag = deviceId;
                            }else{
                                _RB08SelectFourLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else if ([rcIndex isEqualToString:@"2000"]) {
                            _RB08ControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                            NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                            if (areaEntity) {
                                _RB08SelectFourLabel.text = areaEntity.areaName;
                                _RB08SelectFourLabel.tag = areaId;
                            }else {
                                _RB08SelectFourLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else {
                            _RB08ControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                            NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                            if (sceneEntity) {
                                _RB08SelectFourLabel.text = sceneEntity.sceneName;
                                _RB08SelectFourLabel.tag = rcIndexInt;
                            }else {
                                _RB08SelectFourLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                        }
                    }
                    if ([swIndex isEqualToString:@"05"]) {
                        if ([rcIndex isEqualToString:@"0000"]) {
                            _RB08ControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                            _RB08SelectFiveLabel.text = @"";
                        }else if ([rcIndex isEqualToString:@"0100"]) {
                            _RB08ControlFiveLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                            NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                            if (deviceEntity) {
                                _RB08SelectFiveLabel.text = deviceEntity.name;
                                _RB08SelectFiveLabel.tag = deviceId;
                            }else{
                                _RB08SelectFiveLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else if ([rcIndex isEqualToString:@"2000"]) {
                            _RB08ControlFiveLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                            NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                            if (areaEntity) {
                                _RB08SelectFiveLabel.text = areaEntity.areaName;
                                _RB08SelectFiveLabel.tag = areaId;
                            }else {
                                _RB08SelectFiveLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else {
                            _RB08ControlFiveLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                            NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                            if (sceneEntity) {
                                _RB08SelectFiveLabel.text = sceneEntity.sceneName;
                                _RB08SelectFiveLabel.tag = rcIndexInt;
                            }else {
                                _RB08SelectFiveLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                        }
                    }
                    if ([swIndex isEqualToString:@"06"]) {
                        if ([rcIndex isEqualToString:@"0000"]) {
                            _RB08ControlSixLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                            _RB08SelectSixLabel.text = @"";
                        }else if ([rcIndex isEqualToString:@"0100"]) {
                            _RB08ControlSixLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                            NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                            if (deviceEntity) {
                                _RB08SelectSixLabel.text = deviceEntity.name;
                                _RB08SelectSixLabel.tag = deviceId;
                            }else{
                                _RB08SelectSixLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else if ([rcIndex isEqualToString:@"2000"]) {
                            _RB08ControlSixLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                            NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(12, 4)]];
                            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                            if (areaEntity) {
                                _RB08SelectSixLabel.text = areaEntity.areaName;
                                _RB08SelectSixLabel.tag = areaId;
                            }else {
                                _RB08SelectSixLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                            
                        }else {
                            _RB08ControlSixLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                            NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                            if (sceneEntity) {
                                _RB08SelectSixLabel.text = sceneEntity.sceneName;
                                _RB08SelectSixLabel.tag = rcIndexInt;
                            }else {
                                _RB08SelectSixLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                            }
                        }
                    }
                }
            }else {
                _RB08ControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _RB08ControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _RB08ControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _RB08ControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _RB08ControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _RB08ControlSixLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            }
        }else {
            if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length >= 46) {
                [self fillControlLabel:_RB08ControlOneLabel selectedLabel:_RB08SelectOneLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 8)]];
                [self fillControlLabel:_RB08ControlTwoLabel selectedLabel:_RB08SelectTwoLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(18, 8)]];
                [self fillControlLabel:_RB08ControlThreeLabel selectedLabel:_RB08SelectThreeLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(28, 8)]];
                [self fillControlLabel:_RB08ControlFourLabel selectedLabel:_RB08SelectFourLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(38, 8)]];
                [self fillControlLabel:_RB08ControlFiveLabel selectedLabel:_RB08SelectFiveLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(48, 8)]];
                [self fillControlLabel:_RB08ControlSixLabel selectedLabel:_RB08SelectSixLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(58, 8)]];
            }else {
                _RB08ControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _RB08ControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _RB08ControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _RB08ControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _RB08ControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _RB08ControlSixLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            }
        }
    }else if ([self.remoteEntity.shortName isEqualToString:@"GR15B"]) {
        _practicalityImageView.image = [UIImage imageNamed:@"gr15b"];
        [_customContentView addSubview:self.GR15BView];
        [self.GR15BView autoSetDimension:ALDimensionHeight toSize:179.0f];
        [self.GR15BView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.GR15BView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.GR15BView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
        
        if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length >= 46) {
            [self fillControlLabel:_GR15BControlOneLabel selectedLabel:_GR15BSelectOneLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 8)]];
            [self fillControlLabel:_GR15BControlTwoLabel selectedLabel:_GR15BSelectTwoLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(18, 8)]];
            [self fillControlLabel:_GR15BControlThreeLabel selectedLabel:_GR15BSelectThreeLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(28, 8)]];
            [self fillControlLabel:_GR15BControlFourLabel selectedLabel:_GR15BSelectFourLabel brachString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(38, 8)]];
        }else {
            _R5BSHBControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R5BSHBControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R5BSHBControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _R5BSHBControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
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
            if ([_remoteEntity.mcuSVersion integerValue]<latestMCUSVersion) {
                updateMCUBtn = [UIButton buttonWithType:UIButtonTypeSystem];
                [updateMCUBtn setBackgroundColor:[UIColor whiteColor]];
                [updateMCUBtn setTitle:@"UPDATE MCU" forState:UIControlStateNormal];
                [updateMCUBtn setTitleColor:DARKORAGE forState:UIControlStateNormal];
                [updateMCUBtn addTarget:self action:@selector(askUpdateMCU) forControlEvents:UIControlEventTouchUpInside];
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
- (void)askUpdateMCU {
    [MCUUpdateTool sharedInstace].toolDelegate = self;
    [[MCUUpdateTool sharedInstace] askUpdateMCU:_remoteEntity.deviceId downloadAddress:downloadAddress latestMCUSVersion:latestMCUSVersion];
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

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deleteStatus:)
                                                 name:kCSRDeviceManagerDeviceFoundForReset
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
        CGFloat safeHeight = HEIGHT - self.view.safeAreaInsets.bottom - self.view.safeAreaInsets.top;
        if ([self.remoteEntity.shortName isEqualToString:@"RB01"]||[self.remoteEntity.shortName isEqualToString:@"RB05"]) {
            if (safeHeight <= 506.5) {
                _contentViewHeight.constant = 506.5;
            }else {
                _contentViewHeight.constant = safeHeight;
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"RB02"]||[self.remoteEntity.shortName isEqualToString:@"RB06"]||[self.remoteEntity.shortName isEqualToString:@"RSBH"]||[self.remoteEntity.shortName isEqualToString:@"1BMBH"]) {
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
        }else if ([self.remoteEntity.shortName isEqualToString:@"R5BSBH"]||[self.remoteEntity.shortName isEqualToString:@"RB09"]||[self.remoteEntity.shortName isEqualToString:@"5RSIBH"]) {
            if (safeHeight <= 551.5) {
                _contentViewHeight.constant = 551.5;
            }else {
                _contentViewHeight.constant = safeHeight;
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"R9BSBH"]) {
            if (safeHeight <= 850.5) {
                _contentViewHeight.constant = 850.5;
            }else {
                _contentViewHeight.constant = safeHeight;
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"RB08"] || [self.remoteEntity.shortName isEqualToString:@"GR10B"]) {
            if (safeHeight <= 596.5) {
                _contentViewHeight.constant = 596.5;
            }else {
                _contentViewHeight.constant = safeHeight;
            }
        }else if ([self.remoteEntity.shortName isEqualToString:@"GR15B"]) {
            if (safeHeight <= 506.5) {
                _contentViewHeight.constant = 506.5;
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
    list.buttonNum = [NSNumber numberWithInteger:(button.tag % 10 + 1)];
    if (_remoteEntity.remoteBranch && [_remoteEntity.remoteBranch length]>=button.tag % 10 * 10 + 16) {
        list.remoteBranch = [_remoteEntity.remoteBranch substringWithRange:NSMakeRange(button.tag % 10 * 10 + 8, 8)];
    }
    
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count] > 0) {
            if (selectMode == DeviceListSelectMode_Single) {
                
                NSNumber *deviceId = devices[0];
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
                if (button.tag == 100) {
                    _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _fSelectOneLabel.text = deviceEntity.name;
                    _fSelectOneLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 101) {
                    _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _fSelectTwoLabel.text = deviceEntity.name;
                    _fSelectTwoLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 102) {
                    _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _fSelectThreeLabel.text = deviceEntity.name;
                    _fSelectThreeLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 103) {
                    _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _fSelectFourLabel.text = deviceEntity.name;
                    _fSelectFourLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 200) {
                    _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _sSelectOneLabel.text = deviceEntity.name;
                    _sSelectOneLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 400) {
                    _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _tSelectOneLabel.text = deviceEntity.name;
                    _tSelectOneLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 401) {
                    _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _tSelectTwoLabel.text = deviceEntity.name;
                    _tSelectTwoLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 500) {
                    _R5BSHBControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R5BSHBSelectOneLabel.text = deviceEntity.name;
                    _R5BSHBSelectOneLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 501) {
                    _R5BSHBControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R5BSHBSelectTwoLabel.text = deviceEntity.name;
                    _R5BSHBSelectTwoLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 502) {
                    _R5BSHBControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R5BSHBSelectThreeLabel.text = deviceEntity.name;
                    _R5BSHBSelectThreeLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 503) {
                    _R5BSHBControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R5BSHBSelectFourLabel.text = deviceEntity.name;
                    _R5BSHBSelectFourLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 504) {
                    _R5BSHBControlFiveLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R5BSHBSelectFiveLabel.text = deviceEntity.name;
                    _R5BSHBSelectFiveLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 600) {
                    _R9BSBHControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R9BSBHSelectOneLabel.text = deviceEntity.name;
                    _R9BSBHSelectOneLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 601) {
                    _R9BSBHControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R9BSBHSelectTwoLabel.text = deviceEntity.name;
                    _R9BSBHSelectTwoLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 602) {
                    _R9BSBHControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R9BSBHSelectThreeLabel.text = deviceEntity.name;
                    _R9BSBHSelectThreeLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 603) {
                    _R9BSBHControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R9BSBHSelectFourLabel.text = deviceEntity.name;
                    _R9BSBHSelectFourLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 604) {
                    _R9BSBHControlFiveLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R9BSBHSelectFiveLabel.text = deviceEntity.name;
                    _R9BSBHSelectFiveLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 605) {
                    _R9BSBHControlSixLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R9BSBHSelectSixLabel.text = deviceEntity.name;
                    _R9BSBHSelectSixLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 606) {
                    _R9BSBHControlSevenLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R9BSBHSelectSevenLabel.text = deviceEntity.name;
                    _R9BSBHSelectSevenLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 607) {
                    _R9BSBHControlEightLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R9BSBHSelectEightLabel.text = deviceEntity.name;
                    _R9BSBHSelectEightLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 608) {
                    _R9BSBHControlNineLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _R9BSBHSelectNineLabel.text = deviceEntity.name;
                    _R9BSBHSelectNineLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 700) {
                    _RB08ControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _RB08SelectOneLabel.text = deviceEntity.name;
                    _RB08SelectOneLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 701) {
                    _RB08ControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _RB08SelectTwoLabel.text = deviceEntity.name;
                    _RB08SelectTwoLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 702) {
                    _RB08ControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _RB08SelectThreeLabel.text = deviceEntity.name;
                    _RB08SelectThreeLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 703) {
                    _RB08ControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _RB08SelectFourLabel.text = deviceEntity.name;
                    _RB08SelectFourLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 704) {
                    _RB08ControlFiveLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _RB08SelectFiveLabel.text = deviceEntity.name;
                    _RB08SelectFiveLabel.tag = [deviceId integerValue];
                    return;
                }
                if (button.tag == 705) {
                    _RB08ControlSixLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                    _RB08SelectSixLabel.text = deviceEntity.name;
                    _RB08SelectSixLabel.tag = [deviceId integerValue];
                    return;
                }
            }
            if (selectMode == DeviceListSelectMode_SelectGroup) {
                NSNumber *areaId = devices[0];
                CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:areaId];
                if (button.tag == 100) {
                    _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _fSelectOneLabel.text = areaEntity.areaName;
                    _fSelectOneLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 101) {
                    _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _fSelectTwoLabel.text = areaEntity.areaName;
                    _fSelectTwoLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 102) {
                    _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _fSelectThreeLabel.text = areaEntity.areaName;
                    _fSelectThreeLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 103) {
                    _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _fSelectFourLabel.text = areaEntity.areaName;
                    _fSelectFourLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 200) {
                    _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _sSelectOneLabel.text = areaEntity.areaName;
                    _sSelectOneLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 400) {
                    _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _tSelectOneLabel.text = areaEntity.areaName;
                    _tSelectOneLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 401) {
                    _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _tSelectTwoLabel.text = areaEntity.areaName;
                    _tSelectTwoLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 500) {
                    _R5BSHBControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R5BSHBSelectOneLabel.text = areaEntity.areaName;
                    _R5BSHBSelectOneLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 501) {
                    _R5BSHBControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R5BSHBSelectTwoLabel.text = areaEntity.areaName;
                    _R5BSHBSelectTwoLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 502) {
                    _R5BSHBControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R5BSHBSelectThreeLabel.text = areaEntity.areaName;
                    _R5BSHBSelectThreeLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 503) {
                    _R5BSHBControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R5BSHBSelectFourLabel.text = areaEntity.areaName;
                    _R5BSHBSelectFourLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 504) {
                    _R5BSHBControlFiveLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R5BSHBSelectFiveLabel.text = areaEntity.areaName;
                    _R5BSHBSelectFiveLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 600) {
                    _R9BSBHControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R9BSBHSelectOneLabel.text = areaEntity.areaName;
                    _R9BSBHSelectOneLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 601) {
                    _R9BSBHControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R9BSBHSelectTwoLabel.text = areaEntity.areaName;
                    _R9BSBHSelectTwoLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 602) {
                    _R9BSBHControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R9BSBHSelectThreeLabel.text = areaEntity.areaName;
                    _R9BSBHSelectThreeLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 603) {
                    _R9BSBHControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R9BSBHSelectFourLabel.text = areaEntity.areaName;
                    _R9BSBHSelectFourLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 604) {
                    _R9BSBHControlFiveLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R9BSBHSelectFiveLabel.text = areaEntity.areaName;
                    _R9BSBHSelectFiveLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 605) {
                    _R9BSBHControlSixLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R9BSBHSelectSixLabel.text = areaEntity.areaName;
                    _R9BSBHSelectSixLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 606) {
                    _R9BSBHControlSevenLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R9BSBHSelectSevenLabel.text = areaEntity.areaName;
                    _R9BSBHSelectSevenLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 607) {
                    _R9BSBHControlEightLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R9BSBHSelectEightLabel.text = areaEntity.areaName;
                    _R9BSBHSelectEightLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 608) {
                    _R9BSBHControlNineLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _R9BSBHSelectNineLabel.text = areaEntity.areaName;
                    _R9BSBHSelectNineLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 700) {
                    _RB08ControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _RB08SelectOneLabel.text = areaEntity.areaName;
                    _RB08SelectOneLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 701) {
                    _RB08ControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _RB08SelectTwoLabel.text = areaEntity.areaName;
                    _RB08SelectTwoLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 702) {
                    _RB08ControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _RB08SelectThreeLabel.text = areaEntity.areaName;
                    _RB08SelectThreeLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 703) {
                    _RB08ControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _RB08SelectFourLabel.text = areaEntity.areaName;
                    _RB08SelectFourLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 704) {
                    _RB08ControlFiveLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _RB08SelectFiveLabel.text = areaEntity.areaName;
                    _RB08SelectFiveLabel.tag = [areaId integerValue];
                    return;
                }
                if (button.tag == 705) {
                    _RB08ControlSixLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                    _RB08SelectSixLabel.text = areaEntity.areaName;
                    _RB08SelectSixLabel.tag = [areaId integerValue];
                    return;
                }
            }
            if (selectMode == DeviceListSelectMode_SelectScene) {
                NSNumber *rcIndex = devices[0];
                SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:rcIndex];
                if (button.tag == 100) {
                    _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _fSelectOneLabel.text = sceneEntity.sceneName;
                    _fSelectOneLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 101) {
                    _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _fSelectTwoLabel.text = sceneEntity.sceneName;
                    _fSelectTwoLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 102) {
                    _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _fSelectThreeLabel.text = sceneEntity.sceneName;
                    _fSelectThreeLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 103) {
                    _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _fSelectFourLabel.text = sceneEntity.sceneName;
                    _fSelectFourLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 200) {
                    _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _sSelectOneLabel.text = sceneEntity.sceneName;
                    _sSelectOneLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 400) {
                    _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _tSelectOneLabel.text = sceneEntity.sceneName;
                    _tSelectOneLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 401) {
                    _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _tSelectTwoLabel.text = sceneEntity.sceneName;
                    _tSelectTwoLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 500) {
                    _R5BSHBControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R5BSHBSelectOneLabel.text = sceneEntity.sceneName;
                    _R5BSHBSelectOneLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 501) {
                    _R5BSHBControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R5BSHBSelectTwoLabel.text = sceneEntity.sceneName;
                    _R5BSHBSelectTwoLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 502) {
                    _R5BSHBControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R5BSHBSelectThreeLabel.text = sceneEntity.sceneName;
                    _R5BSHBSelectThreeLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 503) {
                    _R5BSHBControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R5BSHBSelectFourLabel.text = sceneEntity.sceneName;
                    _R5BSHBSelectFourLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 504) {
                    _R5BSHBControlFiveLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R5BSHBSelectFiveLabel.text = sceneEntity.sceneName;
                    _R5BSHBSelectFiveLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 600) {
                    _R9BSBHControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R9BSBHSelectOneLabel.text = sceneEntity.sceneName;
                    _R9BSBHSelectOneLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 601) {
                    _R9BSBHControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R9BSBHSelectTwoLabel.text = sceneEntity.sceneName;
                    _R9BSBHSelectTwoLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 602) {
                    _R9BSBHControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R9BSBHSelectThreeLabel.text = sceneEntity.sceneName;
                    _R9BSBHSelectThreeLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 603) {
                    _R9BSBHControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R9BSBHSelectFourLabel.text = sceneEntity.sceneName;
                    _R9BSBHSelectFourLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 604) {
                    _R9BSBHControlFiveLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R9BSBHSelectFiveLabel.text = sceneEntity.sceneName;
                    _R9BSBHSelectFiveLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 605) {
                    _R9BSBHControlSixLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R9BSBHSelectSixLabel.text = sceneEntity.sceneName;
                    _R9BSBHSelectSixLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 606) {
                    _R9BSBHControlSevenLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R9BSBHSelectSevenLabel.text = sceneEntity.sceneName;
                    _R9BSBHSelectSevenLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 607) {
                    _R9BSBHControlEightLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R9BSBHSelectEightLabel.text = sceneEntity.sceneName;
                    _R9BSBHSelectEightLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 608) {
                    _R9BSBHControlNineLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _R9BSBHSelectNineLabel.text = sceneEntity.sceneName;
                    _R9BSBHSelectNineLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 700) {
                    _RB08ControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _RB08SelectOneLabel.text = sceneEntity.sceneName;
                    _RB08SelectOneLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 701) {
                    _RB08ControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _RB08SelectTwoLabel.text = sceneEntity.sceneName;
                    _RB08SelectTwoLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 702) {
                    _RB08ControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _RB08SelectThreeLabel.text = sceneEntity.sceneName;
                    _RB08SelectThreeLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 703) {
                    _RB08ControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _RB08SelectFourLabel.text = sceneEntity.sceneName;
                    _RB08SelectFourLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 704) {
                    _RB08ControlFiveLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _RB08SelectFiveLabel.text = sceneEntity.sceneName;
                    _RB08SelectFiveLabel.tag = [rcIndex integerValue];
                    return;
                }
                if (button.tag == 705) {
                    _RB08ControlSixLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                    _RB08SelectSixLabel.text = sceneEntity.sceneName;
                    _RB08SelectSixLabel.tag = [rcIndex integerValue];
                    return;
                }
            }
            
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)cleanRemoteButton:(UIButton *)button {
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
        _RB08ControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _RB08SelectOneLabel.text = @"";
        return;
    }
    if (button.tag == 701) {
        _RB08ControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _RB08SelectTwoLabel.text = @"";
        return;
    }
    if (button.tag == 702) {
        _RB08ControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _RB08SelectThreeLabel.text = @"";
        return;
    }
    if (button.tag == 703) {
        _RB08ControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _RB08SelectFourLabel.text = @"";
        return;
    }
    if (button.tag == 704) {
        _RB08ControlFiveLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _RB08SelectFiveLabel.text = @"";
        return;
    }
    if (button.tag == 705) {
        _RB08ControlSixLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        _RB08SelectSixLabel.text = @"";
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
            NSString *eveType = [NSString stringWithFormat:@"%@",sceneMember.eveType];
            NSString *level = [CSRUtilities stringWithHexNumber:[sceneMember.level integerValue]];
            NSString *red;
            NSString *green;
            NSString *blue;
            if ([sceneMember.eveType integerValue] == 18 || [sceneMember.eveType integerValue] == 19) {
                NSString *temperature = [self exchangePositionOfDeviceId:[sceneMember.colorTemperature integerValue]];
                red = [temperature substringToIndex:2];
                green = [temperature substringFromIndex:2];
                blue = @"00";
            }else {
                red = [CSRUtilities stringWithHexNumber:[sceneMember.colorRed integerValue]];
                green = [CSRUtilities stringWithHexNumber:[sceneMember.colorGreen integerValue]];
                blue = [CSRUtilities stringWithHexNumber:[sceneMember.colorBlue integerValue]];
            }
            
            dstAddrLevel = [NSString stringWithFormat:@"%@%@%@%@%@%@%@",dstAddrLevel,[self exchangePositionOfDeviceId:[sceneMember.deviceID integerValue]],eveType,level,red,green,blue];
        }
    }
    
    NSString *nLength = [CSRUtilities stringWithHexNumber:dstAddrLevel.length/2+7];
    if ((dstAddrLevel.length/2+7)<250) {
        NSString *cmdStr = [NSString stringWithFormat:@"73%@010%ld%@%@%@%@%@",nLength,(long)swIndex,rcIndexStr,ligCnt,startLigIdx,endLigIdx,dstAddrLevel];
        return cmdStr;
    }
    return nil;
}

- (IBAction)selectRGBDeviceAction:(UIButton *)sender {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_SelectRGBDeviceOrGroup;
    switch (sender.tag) {
        case 800:
            if (_GR15BSelectOneLabel.tag!=0) {
                list.originalMembers = [NSArray arrayWithObject:[NSNumber numberWithInteger:_GR15BSelectOneLabel.tag]];
            }
            break;
        case 801:
            if (_GR15BSelectTwoLabel.tag!=0) {
                list.originalMembers = [NSArray arrayWithObject:[NSNumber numberWithInteger:_GR15BSelectTwoLabel.tag]];
            }
            break;
        case 802:
            if (_GR15BSelectThreeLabel.tag!=0) {
                list.originalMembers = [NSArray arrayWithObject:[NSNumber numberWithInteger:_GR15BSelectThreeLabel.tag]];
            }
            break;
        case 803:
            if (_GR15BSelectFourLabel.tag!=0) {
                list.originalMembers = [NSArray arrayWithObject:[NSNumber numberWithInteger:_GR15BSelectFourLabel.tag]];
            }
            break;
        default:
            break;
    }
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count]>0) {
            NSNumber *num = devices[0];
            if ([num integerValue] > 32768) {
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:num];
                switch (sender.tag) {
                    case 800:
                        _GR15BControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                        _GR15BSelectOneLabel.text = deviceEntity.name;
                        _GR15BSelectOneLabel.tag = [num integerValue];
                        break;
                    case 801:
                        _GR15BControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                        _GR15BSelectTwoLabel.text = deviceEntity.name;
                        _GR15BSelectTwoLabel.tag = [num integerValue];
                        break;
                    case 802:
                        _GR15BControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                        _GR15BSelectThreeLabel.text = deviceEntity.name;
                        _GR15BSelectThreeLabel.tag = [num integerValue];
                        break;
                    case 803:
                        _GR15BControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                        _GR15BSelectFourLabel.text = deviceEntity.name;
                        _GR15BSelectFourLabel.tag = [num integerValue];
                        break;
                    default:
                        break;
                }
            }else {
                CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:num];
                switch (sender.tag) {
                    case 800:
                        _GR15BControlOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                        _GR15BSelectOneLabel.text = areaEntity.areaName;
                        _GR15BSelectOneLabel.tag = [num integerValue];
                        break;
                    case 801:
                        _GR15BControlTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                        _GR15BSelectTwoLabel.text = areaEntity.areaName;
                        _GR15BSelectTwoLabel.tag = [num integerValue];
                        break;
                    case 802:
                        _GR15BControlThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                        _GR15BSelectThreeLabel.text = areaEntity.areaName;
                        _GR15BSelectThreeLabel.tag = [num integerValue];
                        break;
                    case 803:
                        _GR15BControlFourLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                        _GR15BSelectFourLabel.text = areaEntity.areaName;
                        _GR15BSelectFourLabel.tag = [num integerValue];
                        break;
                    default:
                        break;
                }
            }
        }else {
            switch (sender.tag) {
                case 800:
                    _GR15BControlOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                    _GR15BSelectOneLabel.text = @"";
                    _GR15BSelectOneLabel.tag = 0;
                    break;
                case 801:
                    _GR15BControlTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                    _GR15BSelectTwoLabel.text = @"";
                    _GR15BSelectTwoLabel.tag = 0;
                    break;
                case 802:
                    _GR15BControlThreeLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                    _GR15BSelectThreeLabel.text = @"";
                    _GR15BSelectThreeLabel.tag = 0;
                    break;
                case 803:
                    _GR15BControlFourLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                    _GR15BSelectFourLabel.text = @"";
                    _GR15BSelectFourLabel.tag = 0;
                    break;
                default:
                    break;
            }
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)doneAction {
    _setSuccess = NO;
    timerSeconde = 20;
    [self showHudTogether];
    
    if ([_remoteEntity.shortName isEqualToString:@"RB04"] || [_remoteEntity.shortName isEqualToString:@"RSIBH"]) {
        
        NSString *cmdStr1 = [self cmdStringFromControlLabel:_tConrolOneLabel selectedLabel:_tSelectOneLabel buttonNum:@1];
        
        NSString *cmdStr2 = [self cmdStringFromControlLabel:_tConrolTwoLabel selectedLabel:_tSelectTwoLabel buttonNum:@2];
        
        NSString *cmdString = [NSString stringWithFormat:@"9b0b0201%@02%@",cmdStr1,cmdStr2];
        [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdString] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
            
            _remoteEntity.remoteBranch = cmdString;
            [[CSRDatabaseManager sharedInstance] saveContext];
            _setSuccess = YES;
            [_hub hideAnimated:YES];
            [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
            [timer invalidate];
            timer = nil;
        } failure:^(NSError * _Nonnull error) {
            
        }];
    }else if ([_remoteEntity.shortName isEqualToString:@"R5BSBH"] || [_remoteEntity.shortName isEqualToString:@"RB09"] || [_remoteEntity.shortName isEqualToString:@"5RSIBH"]) {
        NSString *cmdStr1 = [self cmdStringFromControlLabel:_R5BSHBControlOneLabel selectedLabel:_R5BSHBSelectOneLabel buttonNum:@1];
        
        NSString *cmdStr2 = [self cmdStringFromControlLabel:_R5BSHBControlTwoLabel selectedLabel:_R5BSHBSelectTwoLabel buttonNum:@2];
        
        NSString *cmdStr3 = [self cmdStringFromControlLabel:_R5BSHBControlThreeLabel selectedLabel:_R5BSHBSelectThreeLabel buttonNum:@3];
        
        NSString *cmdStr4 = [self cmdStringFromControlLabel:_R5BSHBControlFourLabel selectedLabel:_R5BSHBSelectFourLabel buttonNum:@4];
        
        NSString *cmdStr5 = [self cmdStringFromControlLabel:_R5BSHBControlFiveLabel selectedLabel:_R5BSHBSelectFiveLabel buttonNum:@5];
        
        NSString *cmdString;
        if ([_remoteEntity.shortName isEqualToString:@"R5BSBH"]) {
            cmdString = [NSString stringWithFormat:@"9b1a0501%@02%@03%@04%@00%@",cmdStr1,cmdStr2,cmdStr3,cmdStr4,cmdStr5];
        }else if ([_remoteEntity.shortName isEqualToString:@"RB09"]||[_remoteEntity.shortName isEqualToString:@"5RSIBH"]) {
            cmdString = [NSString stringWithFormat:@"9b1a0501%@02%@03%@04%@05%@",cmdStr1,cmdStr2,cmdStr3,cmdStr4,cmdStr5];
        }
        
        [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdString] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
            
            _remoteEntity.remoteBranch = cmdString;
            [[CSRDatabaseManager sharedInstance] saveContext];
            _setSuccess = YES;
            [_hub hideAnimated:YES];
            [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
            [timer invalidate];
            timer = nil;
        } failure:^(NSError * _Nonnull error) {
            
        }];
    }else if ([_remoteEntity.shortName isEqualToString:@"R9BSBH"]) {
        NSString *cmdStr1 = [self cmdStringFromControlLabel:_R9BSBHControlOneLabel selectedLabel:_R9BSBHSelectOneLabel buttonNum:@1];
        
        NSString *cmdStr2 = [self cmdStringFromControlLabel:_R9BSBHControlTwoLabel selectedLabel:_R9BSBHSelectTwoLabel buttonNum:@2];
        
        NSString *cmdStr3 = [self cmdStringFromControlLabel:_R9BSBHControlThreeLabel selectedLabel:_R9BSBHSelectThreeLabel buttonNum:@3];
        
        NSString *cmdStr4 = [self cmdStringFromControlLabel:_R9BSBHControlFourLabel selectedLabel:_R9BSBHSelectFourLabel buttonNum:@4];
        
        NSString *cmdStr5 = [self cmdStringFromControlLabel:_R9BSBHControlFiveLabel selectedLabel:_R9BSBHSelectFiveLabel buttonNum:@5];
        
        NSString *cmdStr6 = [self cmdStringFromControlLabel:_R9BSBHControlSixLabel selectedLabel:_R9BSBHSelectSixLabel buttonNum:@6];
        
        NSString *cmdStr7 = [self cmdStringFromControlLabel:_R9BSBHControlSevenLabel selectedLabel:_R9BSBHSelectSevenLabel buttonNum:@7];
        
        NSString *cmdStr8 = [self cmdStringFromControlLabel:_R9BSBHControlEightLabel selectedLabel:_R9BSBHSelectEightLabel buttonNum:@8];
        
        NSString *cmdStr9 = [self cmdStringFromControlLabel:_R9BSBHControlNineLabel selectedLabel:_R9BSBHSelectNineLabel buttonNum:@9];
        
        NSString *cmdString = [NSString stringWithFormat:@"9b2e0901%@02%@03%@04%@05%@06%@07%@08%@09%@",cmdStr1,cmdStr2,cmdStr3,cmdStr4,cmdStr5,cmdStr6,cmdStr7,cmdStr8,cmdStr9];
        
        [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdString] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
            
            _remoteEntity.remoteBranch = cmdString;
            [[CSRDatabaseManager sharedInstance] saveContext];
            _setSuccess = YES;
            [_hub hideAnimated:YES];
            [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
            [timer invalidate];
            timer = nil;
        } failure:^(NSError * _Nonnull error) {
            
        }];
        
    }else if ([_remoteEntity.shortName isEqualToString:@"GR15B"]) {
        NSString *cmdStr1 = [self cmdStringFromControlLabel:_GR15BControlOneLabel selectedLabel:_GR15BSelectOneLabel buttonNum:@1];
        
        NSString *cmdStr2 = [self cmdStringFromControlLabel:_GR15BControlTwoLabel selectedLabel:_GR15BSelectTwoLabel buttonNum:@2];
        
        NSString *cmdStr3 = [self cmdStringFromControlLabel:_GR15BControlThreeLabel selectedLabel:_GR15BSelectThreeLabel buttonNum:@3];
        
        NSString *cmdStr4 = [self cmdStringFromControlLabel:_GR15BControlFourLabel selectedLabel:_GR15BSelectFourLabel buttonNum:@4];
        
        NSString *cmdString = [NSString stringWithFormat:@"9b150407%@08%@09%@0a%@",cmdStr1,cmdStr2,cmdStr3,cmdStr4];
        
        [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdString] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
            
            _remoteEntity.remoteBranch = cmdString;
            [[CSRDatabaseManager sharedInstance] saveContext];
            _setSuccess = YES;
            [_hub hideAnimated:YES];
            [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
            [timer invalidate];
            timer = nil;
        } failure:^(NSError * _Nonnull error) {
            
        }];
    }else {
        if (![[CSRAppStateManager sharedInstance].selectedPlace.color boolValue]) {
            if ([_remoteEntity.shortName isEqualToString:@"RB01"]||[_remoteEntity.shortName isEqualToString:@"RB05"]) {
                
                NSString *cmdStr1 = [self cmdStringFromControlLabel:_fConrolOneLabel selectedLabel:_fSelectOneLabel buttonNum:@1];
                
                NSString *cmdStr2 = [self cmdStringFromControlLabel:_fConrolTwoLabel selectedLabel:_fSelectTwoLabel buttonNum:@2];
                
                NSString *cmdStr3 = [self cmdStringFromControlLabel:_fConrolThreeLabel selectedLabel:_fSelectThreeLabel buttonNum:@3];
                
                NSString *cmdStr4 = [self cmdStringFromControlLabel:_fConrolFourLabel selectedLabel:_fSelectFourLabel buttonNum:@4];
                
                NSString *cmdString = [NSString stringWithFormat:@"9b150401%@02%@03%@04%@",cmdStr1,cmdStr2,cmdStr3,cmdStr4];
                
                [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdString] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                    
                    _remoteEntity.remoteBranch = cmdString;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    _setSuccess = YES;
                    [_hub hideAnimated:YES];
                    [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                    [timer invalidate];
                    timer = nil;
                } failure:^(NSError * _Nonnull error) {
                    
                }];
                
                
            }else if ([_remoteEntity.shortName isEqualToString:@"RB02"]||[_remoteEntity.shortName isEqualToString:@"S10IB-H2"]||[_remoteEntity.shortName isEqualToString:@"RB06"]||[_remoteEntity.shortName isEqualToString:@"RSBH"]||[_remoteEntity.shortName isEqualToString:@"1BMBH"]) {
                
                NSString *cmdStr1 = [self cmdStringFromControlLabel:_sConrolOneLabel selectedLabel:_sSelectOneLabel buttonNum:@1];
                
                NSString *cmdString = [NSString stringWithFormat:@"9b060101%@",cmdStr1];
                
                [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdString] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                    
                    _remoteEntity.remoteBranch = cmdString;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    _setSuccess = YES;
                    [_hub hideAnimated:YES];
                    [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                    [timer invalidate];
                    timer = nil;
                } failure:^(NSError * _Nonnull error) {
                    
                }];
            }else if ([_remoteEntity.shortName isEqualToString:@"RB07"]) {
                NSString *cmdStr1 = [self cmdStringFromControlLabel:_tConrolOneLabel selectedLabel:_tSelectOneLabel buttonNum:@1];
                
                NSString *cmdStr2 = [self cmdStringFromControlLabel:_tConrolTwoLabel selectedLabel:_tSelectTwoLabel buttonNum:@2];
                
                NSString *cmdString = [NSString stringWithFormat:@"9b0b0201%@02%@",cmdStr1,cmdStr2];
                [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdString] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                    
                    _remoteEntity.remoteBranch = cmdString;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    _setSuccess = YES;
                    [_hub hideAnimated:YES];
                    [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                    [timer invalidate];
                    timer = nil;
                } failure:^(NSError * _Nonnull error) {
                    
                }];
            }else if ([_remoteEntity.shortName isEqualToString:@"RB08"] || [_remoteEntity.shortName isEqualToString:@"GR10B"]) {
                NSString *cmdStr1 = [self cmdStringFromControlLabel:_RB08ControlOneLabel selectedLabel:_RB08SelectOneLabel buttonNum:@1];
                
                NSString *cmdStr2 = [self cmdStringFromControlLabel:_RB08ControlTwoLabel selectedLabel:_RB08SelectTwoLabel buttonNum:@2];
                
                NSString *cmdStr3 = [self cmdStringFromControlLabel:_RB08ControlThreeLabel selectedLabel:_RB08SelectThreeLabel buttonNum:@3];
                
                NSString *cmdStr4 = [self cmdStringFromControlLabel:_RB08ControlFourLabel selectedLabel:_RB08SelectFourLabel buttonNum:@4];
                
                NSString *cmdStr5 = [self cmdStringFromControlLabel:_RB08ControlFiveLabel selectedLabel:_RB08SelectFiveLabel buttonNum:@5];
                
                NSString *cmdStr6 = [self cmdStringFromControlLabel:_RB08ControlSixLabel selectedLabel:_RB08SelectSixLabel buttonNum:@6];
                
                NSString *cmdString = [NSString stringWithFormat:@"9b1f0601%@02%@03%@04%@05%@06%@",cmdStr1,cmdStr2,cmdStr3,cmdStr4,cmdStr5,cmdStr6];
                
                [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdString] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                    
                    _remoteEntity.remoteBranch = cmdString;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    _setSuccess = YES;
                    [_hub hideAnimated:YES];
                    [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
                    [timer invalidate];
                    timer = nil;
                } failure:^(NSError * _Nonnull error) {
                    
                }];
                
            }
            
        }else {
            if ([_remoteEntity.shortName isEqualToString:@"RB01"]||[_remoteEntity.shortName isEqualToString:@"RB05"]) {
                NSString *cmdStr1;
                if ([_fConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_fSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectOneLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_fSelectOneLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr1 = [NSString stringWithFormat:@"730e01010%@00010000%@0000000000",chanelSelect,deviceIdString];
                    }else {
                        cmdStr1 = [NSString stringWithFormat:@"730e01010100010000%@0000000000",deviceIdString];
                    }
                }else if ([_fConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_fSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectOneLabel.tag];
                    cmdStr1 = [NSString stringWithFormat:@"730e01012000010000%@0000000000",deviceIdString];
                }else if ([_fConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_fSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    cmdStr1 = [self cmdStringWithSceneRcIndex:_fSelectOneLabel.tag swIndex:1];
                }else{
                    cmdStr1 = @"730701010000000000";
                }
                
                NSString *cmdStr2;
                if ([_fConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_fSelectTwoLabel.text isEqualToString:@"Not found"]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectTwoLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_fSelectTwoLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr2 = [NSString stringWithFormat:@"730e01020%@00010000%@0000000000",chanelSelect,deviceIdString];
                    }else {
                        cmdStr2 = [NSString stringWithFormat:@"730e01020100010000%@0000000000",deviceIdString];
                    }
                }else if ([_fConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_fSelectTwoLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectTwoLabel.tag];
                    cmdStr2 = [NSString stringWithFormat:@"730e01022000010000%@0000000000",deviceIdString];
                }else if ([_fConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_fSelectTwoLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    cmdStr2 = [self cmdStringWithSceneRcIndex:_fSelectTwoLabel.tag swIndex:2];
                }else{
                    cmdStr2 = @"730701020000000000";
                }
                
                NSString *cmdStr3;
                if ([_fConrolThreeLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_fSelectThreeLabel.text isEqualToString:@"Not found"]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectThreeLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_fSelectThreeLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr3 = [NSString stringWithFormat:@"730e01030%@00010000%@0000000000",chanelSelect,deviceIdString];
                    }else {
                        cmdStr3 = [NSString stringWithFormat:@"730e01030100010000%@0000000000",deviceIdString];
                    }
                }else if ([_fConrolThreeLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_fSelectThreeLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectThreeLabel.tag];
                    cmdStr3 = [NSString stringWithFormat:@"730e01032000010000%@0000000000",deviceIdString];
                }else if ([_fConrolThreeLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_fSelectThreeLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    cmdStr3 = [self cmdStringWithSceneRcIndex:_fSelectThreeLabel.tag swIndex:3];
                }else{
                    cmdStr3 = @"730701030000000000";
                }
                
                NSString *cmdStr4;
                if ([_fConrolFourLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_fSelectFourLabel.text isEqualToString:@"Not found"]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectFourLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_fSelectFourLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr4 = [NSString stringWithFormat:@"730e01040%@00010000%@0000000000",chanelSelect,deviceIdString];
                    }else {
                        cmdStr4 = [NSString stringWithFormat:@"730e01040100010000%@0000000000",deviceIdString];
                    }
                }else if ([_fConrolFourLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_fSelectFourLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectFourLabel.tag];
                    cmdStr4 = [NSString stringWithFormat:@"730e01042000010000%@0000000000",deviceIdString];
                }else if ([_fConrolFourLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_fSelectFourLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    cmdStr4 = [self cmdStringWithSceneRcIndex:_fSelectFourLabel.tag swIndex:4];
                }else {
                    cmdStr4 = @"730701040000000000";
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
            }else if ([_remoteEntity.shortName isEqualToString:@"RB02"]||[_remoteEntity.shortName isEqualToString:@"RB06"]||[_remoteEntity.shortName isEqualToString:@"RSBH"]||[_remoteEntity.shortName isEqualToString:@"1BMBH"]) {
                NSString *cmdStr1;
                if ([_sConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_sSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_sSelectOneLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_sSelectOneLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr1 = [NSString stringWithFormat:@"730e01010%@00010000%@0000000000",chanelSelect,deviceIdString];
                    }else {
                        cmdStr1 = [NSString stringWithFormat:@"730e01010100010000%@0000000000",deviceIdString];
                    }
                }else if ([_sConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_sSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_sSelectOneLabel.tag];
                    cmdStr1 = [NSString stringWithFormat:@"730e01012000010000%@0000000000",deviceIdString];
                }else if ([_sConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_sSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    cmdStr1 = [self cmdStringWithSceneRcIndex:_sSelectOneLabel.tag swIndex:1];
                }else{
                    cmdStr1 = @"730701010000000000";
                }
                
                if (cmdStr1.length>0) {
                    [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdStr1] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                        
                        NSString *remoteBranch = [NSString stringWithFormat:@"%@",[cmdStr1 substringFromIndex:6]];
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
                if ([_tConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_tSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_tSelectOneLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_tSelectOneLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr1 = [NSString stringWithFormat:@"730e01010%@00010000%@0000000000",chanelSelect,deviceIdString];
                    }else {
                        cmdStr1 = [NSString stringWithFormat:@"730e01010100010000%@0000000000",deviceIdString];
                    }
                }else if ([_tConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_tSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_tSelectOneLabel.tag];
                    cmdStr1 = [NSString stringWithFormat:@"730e01012000010000%@0000000000",deviceIdString];
                }else if ([_tConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_tSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    cmdStr1 = [self cmdStringWithSceneRcIndex:_tSelectOneLabel.tag swIndex:1];
                }else{
                    cmdStr1 = @"730701010000000000";
                }
                
                NSString *cmdStr2;
                if ([_tConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_tSelectTwoLabel.text isEqualToString:@"Not found"]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_tSelectTwoLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_tSelectTwoLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr2 = [NSString stringWithFormat:@"730e01020%@00010000%@0000000000",chanelSelect,deviceIdString];
                    }else {
                        cmdStr2 = [NSString stringWithFormat:@"730e01020100010000%@0000000000",deviceIdString];
                    }
                }else if ([_tConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_tSelectTwoLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_tSelectTwoLabel.tag];
                    cmdStr2 = [NSString stringWithFormat:@"730e01022000010000%@0000000000",deviceIdString];
                }else if ([_tConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_tSelectTwoLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    cmdStr2 = [self cmdStringWithSceneRcIndex:_tSelectTwoLabel.tag swIndex:2];
                }else{
                    cmdStr2 = @"730701020000000000";
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
            }else if ([_remoteEntity.shortName isEqualToString:@"RB08"] || [_remoteEntity.shortName isEqualToString:@"GR10B"]) {
                NSString *cmdStr1;
                if ([_RB08ControlOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_RB08SelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_RB08SelectOneLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_RB08SelectOneLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr1 = [NSString stringWithFormat:@"730e01010%@00010000%@0000000000",chanelSelect,deviceIdString];
                    }else {
                        cmdStr1 = [NSString stringWithFormat:@"730e01010100010000%@0000000000",deviceIdString];
                    }
                }else if ([_RB08ControlOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_RB08SelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_RB08SelectOneLabel.tag];
                    cmdStr1 = [NSString stringWithFormat:@"730e01012000010000%@0000000000",deviceIdString];
                }else if ([_RB08ControlOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_RB08SelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    cmdStr1 = [self cmdStringWithSceneRcIndex:_RB08SelectOneLabel.tag swIndex:1];
                }else{
                    cmdStr1 = @"730701010000000000";
                }
                
                NSString *cmdStr2;
                if ([_RB08ControlTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_RB08SelectTwoLabel.text isEqualToString:@"Not found"]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_RB08SelectTwoLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_RB08SelectTwoLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr2 = [NSString stringWithFormat:@"730e01020%@00010000%@0000000000",chanelSelect,deviceIdString];
                    }else {
                        cmdStr2 = [NSString stringWithFormat:@"730e01020100010000%@0000000000",deviceIdString];
                    }
                }else if ([_RB08ControlTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_RB08SelectTwoLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_RB08SelectTwoLabel.tag];
                    cmdStr2 = [NSString stringWithFormat:@"730e01022000010000%@0000000000",deviceIdString];
                }else if ([_RB08ControlTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_RB08SelectTwoLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    cmdStr2 = [self cmdStringWithSceneRcIndex:_RB08SelectTwoLabel.tag swIndex:2];
                }else{
                    cmdStr2 = @"730701020000000000";
                }
                
                NSString *cmdStr3;
                if ([_RB08ControlThreeLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_RB08SelectThreeLabel.text isEqualToString:@"Not found"]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_RB08SelectThreeLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_RB08SelectThreeLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr3 = [NSString stringWithFormat:@"730e01030%@00010000%@0000000000",chanelSelect,deviceIdString];
                    }else {
                        cmdStr3 = [NSString stringWithFormat:@"730e01030100010000%@0000000000",deviceIdString];
                    }
                }else if ([_RB08ControlThreeLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_RB08SelectThreeLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_RB08SelectThreeLabel.tag];
                    cmdStr3 = [NSString stringWithFormat:@"730e01032000010000%@0000000000",deviceIdString];
                }else if ([_RB08ControlThreeLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_RB08SelectThreeLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    cmdStr3 = [self cmdStringWithSceneRcIndex:_RB08SelectThreeLabel.tag swIndex:3];
                }else{
                    cmdStr3 = @"730701030000000000";
                }
                
                NSString *cmdStr4;
                if ([_RB08ControlFourLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_RB08SelectFourLabel.text isEqualToString:@"Not found"]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_RB08SelectFourLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_RB08SelectFourLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr4 = [NSString stringWithFormat:@"730e01040%@00010000%@0000000000",chanelSelect,deviceIdString];
                    }else {
                        cmdStr4 = [NSString stringWithFormat:@"730e01040100010000%@0000000000",deviceIdString];
                    }
                }else if ([_RB08ControlFourLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_RB08SelectFourLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_RB08SelectFourLabel.tag];
                    cmdStr4 = [NSString stringWithFormat:@"730e01042000010000%@0000000000",deviceIdString];
                }else if ([_RB08ControlFourLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_RB08SelectFourLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    cmdStr4 = [self cmdStringWithSceneRcIndex:_RB08SelectFourLabel.tag swIndex:4];
                }else {
                    cmdStr4 = @"730701040000000000";
                }
                
                NSString *cmdStr5;
                if ([_RB08ControlFiveLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_RB08SelectFiveLabel.text isEqualToString:@"Not found"]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_RB08SelectFiveLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_RB08SelectFiveLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr4 = [NSString stringWithFormat:@"730e01050%@00010000%@0000000000",chanelSelect,deviceIdString];
                    }else {
                        cmdStr4 = [NSString stringWithFormat:@"730e01050100010000%@0000000000",deviceIdString];
                    }
                }else if ([_RB08ControlFiveLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_RB08SelectFiveLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_RB08SelectFiveLabel.tag];
                    cmdStr4 = [NSString stringWithFormat:@"730e01052000010000%@0000000000",deviceIdString];
                }else if ([_RB08ControlFiveLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_RB08SelectFiveLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    cmdStr4 = [self cmdStringWithSceneRcIndex:_RB08SelectFiveLabel.tag swIndex:4];
                }else {
                    cmdStr4 = @"730701050000000000";
                }
                
                NSString *cmdStr6;
                if ([_RB08ControlSixLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_RB08SelectSixLabel.text isEqualToString:@"Not found"]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_RB08SelectSixLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_RB08SelectSixLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr4 = [NSString stringWithFormat:@"730e01060%@00010000%@0000000000",chanelSelect,deviceIdString];
                    }else {
                        cmdStr4 = [NSString stringWithFormat:@"730e01060100010000%@0000000000",deviceIdString];
                    }
                }else if ([_RB08ControlSixLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_RB08SelectSixLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_RB08SelectSixLabel.tag];
                    cmdStr4 = [NSString stringWithFormat:@"730e01062000010000%@0000000000",deviceIdString];
                }else if ([_RB08ControlSixLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_RB08SelectSixLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    cmdStr4 = [self cmdStringWithSceneRcIndex:_RB08SelectSixLabel.tag swIndex:4];
                }else {
                    cmdStr4 = @"730701060000000000";
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
                                dispatch_semaphore_signal(semaphore);
                                timerSeconde = 20;
                            } failure:^(NSError * _Nonnull error) {
                                
                            }];
                        });
                        
                        NSLog(@"信号量-1 第四个按键  %@",cmdStr4);
                        
                    }else {
                        [self showTextHud:[NSString stringWithFormat:@"%@",AcTECLocalizedStringFromTable(@"outLargeScene", @"Localizable")]];
                    }
                    
                });
                
                dispatch_async(queue, ^{
                    
                    if (cmdStr5.length>0) {
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdStr5] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                                dispatch_semaphore_signal(semaphore);
                                timerSeconde = 20;
                            } failure:^(NSError * _Nonnull error) {
                                
                            }];
                        });
                        
                        NSLog(@"信号量-1 第5个按键  %@",cmdStr5);
                        
                    }else {
                        [self showTextHud:[NSString stringWithFormat:@"%@",AcTECLocalizedStringFromTable(@"outLargeScene", @"Localizable")]];
                    }
                    
                });
                
                
                
                dispatch_async(queue, ^{
                    
                    if (cmdStr6.length>0) {
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdStr6] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                                NSLog(@"+++++++++++ 完成");
                                
                                dispatch_semaphore_signal(semaphore);
                                NSString *remoteBranch = [NSString stringWithFormat:@"%@|%@|%@|%@|%@|%@",[cmdStr1 substringFromIndex:6],[cmdStr2 substringFromIndex:6],[cmdStr3 substringFromIndex:6],[cmdStr4 substringFromIndex:6],[cmdStr5 substringFromIndex:6],[cmdStr6 substringFromIndex:6]];
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
                        
                        NSLog(@"信号量-1 第6个按键  %@",cmdStr6);
                        
                    }else {
                        [self showTextHud:[NSString stringWithFormat:@"%@",AcTECLocalizedStringFromTable(@"outLargeScene", @"Localizable")]];
                    }
                    
                });
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
    _hub.label.text = AcTECLocalizedStringFromTable(@"RemoteOpenAlert", @"Localizable");
    _hub.label.font = [UIFont systemFontOfSize:13];
    _hub.label.numberOfLines = 0;
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
        
        NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
        
        [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
        
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
                                                         NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
                                                         
                                                         [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
                                                         
                                                         if (self.reloadDataHandle) {
                                                             self.reloadDataHandle();
                                                         }
                                                         [self.navigationController popViewControllerAnimated:YES];
                                                     }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (NSString *)cmdStringFromControlLabel:(UILabel *)controlLabel selectedLabel:(UILabel *)selectedLabel buttonNum:(NSNumber *)num {
    NSString *cmdString;
    if ([controlLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![selectedLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
        NSString *deviceIdString = [self exchangePositionOfDeviceId:selectedLabel.tag];
        DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:selectedLabel.tag]];
        if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName] || [CSRUtilities belongToCurtainController:deviceModel.shortName] || [CSRUtilities belongToFanController:deviceModel.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceModel.shortName]) {
            NSNumber *obj = [deviceModel.buttonnumAndChannel objectForKey:[NSString stringWithFormat:@"%@",num]];
            if (obj) {
                cmdString = [NSString stringWithFormat:@"0%@00%@",obj,deviceIdString];
            }else {
                cmdString = @"00000000";
            }
        }else {
            cmdString = [NSString stringWithFormat:@"0100%@",deviceIdString];
        }
    }else if ([controlLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![selectedLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
        
        NSString *rcIndexStr;
        NSInteger dimmerNum = 0;
        NSInteger switchNum = 0;
        NSInteger RGBNum = 0;
        CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:selectedLabel.tag]];
        for (CSRDeviceEntity *deviceEntity in areaEntity.devices) {
            if ([CSRUtilities belongToDimmer:deviceEntity.shortName]) {
                dimmerNum ++;
            }else if ([CSRUtilities belongToSwitch:deviceEntity.shortName]) {
                switchNum ++;
            }else if ([CSRUtilities belongToRGBDevice:deviceEntity.shortName] || [CSRUtilities belongToCWDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBCWDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBNoLevelDevice:deviceEntity.shortName] || [CSRUtilities belongToCWNoLevelDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBCWNoLevelDevice:deviceEntity.shortName]){
                RGBNum ++;
            }
        }
        if (RGBNum && dimmerNum && !switchNum) {
            rcIndexStr = @"33";
        }else if ((RGBNum && !dimmerNum && switchNum) || (!RGBNum && dimmerNum && switchNum) || (RGBNum && dimmerNum && switchNum)) {
            rcIndexStr = @"34";
        }else {
            rcIndexStr = @"32";
        }
        NSString *deviceIdString = [self exchangePositionOfDeviceId:selectedLabel.tag];
        cmdString = [NSString stringWithFormat:@"%@00%@",[CSRUtilities stringWithHexNumber:[rcIndexStr integerValue]],deviceIdString];
    }else if ([controlLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![selectedLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
        NSString *deviceIdString = [self exchangePositionOfDeviceId:selectedLabel.tag];
        cmdString = [NSString stringWithFormat:@"%@0000",deviceIdString];
    }else{
        cmdString = @"00000000";
    }
    return cmdString;
}

- (void)fillControlLabel:(UILabel *)controlLabel selectedLabel:(UILabel *)selectedLabel brachString:(NSString *)branchString {
    NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:[branchString substringToIndex:4]];
    if (rcIndexInt == 0) {
        controlLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        selectedLabel.text = @"";
    }else if (rcIndexInt > 0 && rcIndexInt <= 9) {
        controlLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
        NSInteger deviceId = [self exchangePositionOfDeviceIdString:[branchString substringFromIndex:4]];
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
        if (deviceEntity) {
            selectedLabel.text = deviceEntity.name;
            selectedLabel.tag = deviceId;
        }else {
            selectedLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
        }
     }else if (rcIndexInt >= 32 && rcIndexInt <= 35) {
         controlLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
         NSInteger areaId = [self exchangePositionOfDeviceIdString:[branchString substringFromIndex:4]];
         CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
         if (areaEntity) {
             selectedLabel.text = areaEntity.areaName;
             selectedLabel.tag = areaId;
         }else {
             selectedLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
         }
     }else {
         controlLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
         SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
         if (sceneEntity) {
             selectedLabel.text = sceneEntity.sceneName;
             selectedLabel.tag = rcIndexInt;
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

@end
