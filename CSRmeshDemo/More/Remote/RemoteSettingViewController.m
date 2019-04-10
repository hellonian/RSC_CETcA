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

@interface RemoteSettingViewController ()<UITextFieldDelegate,MBProgressHUDDelegate>
{
    dispatch_semaphore_t semaphore;
    NSInteger timerSeconde;
    NSTimer *timer;
    
    NSInteger nowBinPage;
    dispatch_semaphore_t mcuSemaphore;
    NSMutableDictionary *updateEveDataDic;
    NSMutableDictionary *updateSuccessDic;
    BOOL isLastPage;
    NSInteger resendQueryNumber;
    NSInteger pageNum;
    
    NSString *downloadAddress;
    NSInteger latestMCUSVersion;
}

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
@property (weak, nonatomic) IBOutlet UILabel *batteryLabel;
@property (weak, nonatomic) IBOutlet UIImageView *practicalityImageView;

@property (weak, nonatomic) IBOutlet UIView *twoRemoteView;
@property (weak, nonatomic) IBOutlet UILabel *tSelectOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *tSelectTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *tConrolOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *tConrolTwoLabel;
@property (weak, nonatomic) IBOutlet UISwitch *enableSwitch;

@property (nonatomic,strong) MBProgressHUD *updatingHud;

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
    
    if ([self.remoteEntity.shortName isEqualToString:@"RB01"]) {
        _practicalityImageView.image = [UIImage imageNamed:@"rb01"];
        [self.view addSubview:self.fiveRemoteView];
        [self.fiveRemoteView autoSetDimension:ALDimensionHeight toSize:179.0f];
        [self.fiveRemoteView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.fiveRemoteView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.fiveRemoteView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
        
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
        
    }else if ([self.remoteEntity.shortName isEqualToString:@"RB02"]) {
        _practicalityImageView.image = [UIImage imageNamed:@"rb02"];
        [self.view addSubview:self.singleRemoteView];
        [self.singleRemoteView autoSetDimension:ALDimensionHeight toSize:44.0f];
        [self.singleRemoteView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.singleRemoteView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.singleRemoteView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
        
        if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length > 0) {
            
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
        }
        
        else {
            _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        }
        
        /*
        if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length == 4) {
            CSRDeviceEntity *deviceEntity1 = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:@([CSRUtilities numberWithHexString:self.remoteEntity.remoteBranch])];
            self.sSelectOneLabel.text = deviceEntity1.name;
            self.sSelectOneLabel.tag = [self.remoteEntity.remoteBranch integerValue];
        }*/
    }else if ([self.remoteEntity.shortName isEqualToString:@"RB04"] || [self.remoteEntity.shortName isEqualToString:@"RSIBH"]) {
        _practicalityImageView.image = [UIImage imageNamed:@"rb04"];
        
        [self.view addSubview:self.twoRemoteView];
        [self.twoRemoteView autoSetDimension:ALDimensionHeight toSize:134.0f];
        [self.twoRemoteView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.twoRemoteView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.twoRemoteView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
        if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length >0) {
            
            NSString *rcIndex1Str = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 4)];
            if ([rcIndex1Str isEqualToString:@"0000"]) {
                _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _tSelectOneLabel.text = @"";
            }else if ([rcIndex1Str isEqualToString:@"0100"] || [rcIndex1Str isEqualToString:@"0200"]) {
                _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                NSInteger deviceId = [self exchangePositionOfDeviceIdString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(12, 4)]];
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                if (deviceEntity) {
                    _tSelectOneLabel.text = deviceEntity.name;
                    _tSelectOneLabel.tag = deviceId;
                }else {
                    _tSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                }
            }else if ([rcIndex1Str isEqualToString:@"2000"] || [rcIndex1Str isEqualToString:@"2100"] || [rcIndex1Str isEqualToString:@"2200"] || [rcIndex1Str isEqualToString:@"2300"]) {
                _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                NSInteger areaId = [self exchangePositionOfDeviceIdString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(12, 4)]];
                CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                if (areaEntity) {
                    _tSelectOneLabel.text = areaEntity.areaName;
                    _tSelectOneLabel.tag = areaId;
                }else {
                    _tSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                }
            }else {
                _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex1Str];
                SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                if (sceneEntity) {
                    _tSelectOneLabel.text = sceneEntity.sceneName;
                    _tSelectOneLabel.tag = rcIndexInt;
                }else {
                    _tSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                }
            }
            
            NSString *rcIndex2Str = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(18, 4)];
            if ([rcIndex2Str isEqualToString:@"0000"]) {
                _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
                _tSelectTwoLabel.text = @"";
            }else if ([rcIndex2Str isEqualToString:@"0100"] || [rcIndex2Str isEqualToString:@"0200"]) {
                _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable");
                NSInteger deviceId = [self exchangePositionOfDeviceIdString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(22, 4)]];
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                if (deviceEntity) {
                    _tSelectTwoLabel.text = deviceEntity.name;
                    _tSelectTwoLabel.tag = deviceId;
                }else {
                    _tSelectTwoLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                }
            }else if ([rcIndex2Str isEqualToString:@"2000"] || [rcIndex2Str isEqualToString:@"2100"] || [rcIndex2Str isEqualToString:@"2200"] || [rcIndex2Str isEqualToString:@"2300"]) {
                _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                NSInteger areaId = [self exchangePositionOfDeviceIdString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(22, 4)]];
                CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:areaId]];
                if (areaEntity) {
                    _tSelectTwoLabel.text = areaEntity.areaName;
                    _tSelectTwoLabel.tag = areaId;
                }else {
                    _tSelectTwoLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                }
            }else {
                _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable");
                NSInteger rcIndexInt = [self exchangePositionOfDeviceIdString:rcIndex2Str];
                SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:[NSNumber numberWithInteger:rcIndexInt]];
                if (sceneEntity) {
                    _tSelectTwoLabel.text = sceneEntity.sceneName;
                    _tSelectTwoLabel.tag = rcIndexInt;
                }else {
                    _tSelectTwoLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                }
            }
        }else {
            _tConrolOneLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
            _tConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"TapToSelect", @"Localizable");
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MCUUpdateDataCall:) name:@"MCUUpdateDataCall" object:nil];
        NSMutableString *mutStr = [NSMutableString stringWithString:_remoteEntity.shortName];
        NSRange range = {0,_remoteEntity.shortName.length};
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
            NSLog(@">> %@  %ld  %ld",downloadAddress,(long)[_remoteEntity.mcuSVersion integerValue],latestMCUSVersion);
            if ([_remoteEntity.mcuSVersion integerValue]<latestMCUSVersion) {
                UIButton *updateMCUBtn = [UIButton buttonWithType:UIButtonTypeSystem];
                [updateMCUBtn setBackgroundColor:[UIColor whiteColor]];
                [updateMCUBtn setTitle:@"UPDATE MCU" forState:UIControlStateNormal];
                [updateMCUBtn setTitleColor:DARKORAGE forState:UIControlStateNormal];
                [updateMCUBtn addTarget:self action:@selector(askUpdateMCU) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:updateMCUBtn];
                [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeLeft];
                [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeRight];
                [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:45.0];
                [updateMCUBtn autoSetDimension:ALDimensionHeight toSize:44.0];
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"%@",error);
        }];
    }
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = done;
//    self.navigationItem.rightBarButtonItem.enabled = NO;
    semaphore = dispatch_semaphore_create(1);
    
}
- (void)askUpdateMCU {
    [[DataModelManager shareInstance] sendCmdData:@"ea30" toDeviceId:_remoteEntity.deviceId];
}

- (void)MCUUpdateDataCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *mucDeviceId = dic[@"deviceId"];
    NSString *mcuString = dic[@"MCUUpdateDataCall"];
    if ([mucDeviceId isEqualToNumber:_remoteEntity.deviceId]) {
        if ([mcuString hasPrefix:@"30"]) {
            if ([[mcuString substringWithRange:NSMakeRange(2, 2)] boolValue]) {
                if (!_updatingHud) {
                    _updatingHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    _updatingHud.mode = MBProgressHUDModeAnnularDeterminate;
                    _updatingHud.delegate = self;
                    [self downloadPin];
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
                    dispatch_semaphore_signal(mcuSemaphore);
                    [updateSuccessDic setObject:@(![[updateSuccessDic objectForKey:@(backBinPage)] boolValue]) forKey:@(backBinPage)];
                    if (isLastPage) {
                        NSLog(@"最后一页成功");
                        [[DataModelManager shareInstance] sendCmdData:@"ea32" toDeviceId:_remoteEntity.deviceId];
                    }
                    _updatingHud.progress = (backBinPage+1)/(CGFloat)pageNum;
                }else {
                    
                    for (NSInteger i=0; i<[resultBinStr length]; i++) {
                        NSString *resultStr = [resultBinStr substringWithRange:NSMakeRange([resultBinStr length]-1-i, 1)];
                        NSLog(@"%@",resultStr);
                        if (![resultStr boolValue]) {
                            NSString *binResendString = [[updateEveDataDic objectForKey:@(backBinPage)] objectAtIndex:i];
                            [[DataModelManager shareInstance] sendCmdData:binResendString toDeviceId:_remoteEntity.deviceId];
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
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_remoteEntity.deviceId];
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
    __block RemoteSettingViewController *weakSelf = self;
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:&progress destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@",fileName]];
        
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        [weakSelf startMCUUpdate:filePath];
        
    }];
    [task resume];
}

- (void)startMCUUpdate:(NSURL *)path {
    
    NSData *data = [[NSData alloc] initWithContentsOfURL:path];
    mcuSemaphore = dispatch_semaphore_create(1);
    updateEveDataDic = [[NSMutableDictionary alloc] init];
    updateSuccessDic = [[NSMutableDictionary alloc] init];
    isLastPage = NO;
    if (data) {
        pageNum = [data length]/128+1;
        dispatch_queue_t queue = dispatch_queue_create("串行", NULL);
        for (NSInteger binPage=0; binPage<([data length]/128+1); binPage++) {
            dispatch_async(queue, ^{
                dispatch_semaphore_wait(mcuSemaphore, DISPATCH_TIME_FOREVER);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [updateSuccessDic setObject:@(0) forKey:@(binPage)];
                    NSLog(@"xunfan %ld",(long)binPage);
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
                        [[DataModelManager shareInstance] sendCmdData:binSendString toDeviceId:_remoteEntity.deviceId];
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
        NSLog(@"首次延时~~ %ld | %d",(long)binPage,[[updateSuccessDic objectForKey:@(binPage)] boolValue]);
        if (![[updateSuccessDic objectForKey:@(binPage)] boolValue] && resendQueryNumber<6) {
            resendQueryNumber++;
            [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"ea33%@",[CSRUtilities stringWithHexNumber:binPage]] toDeviceId:_remoteEntity.deviceId];
            [self resendData:binPage];
        }
    });
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
    }
}

-(void)getRemoteEnableState:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    NSString *stateStr = dic[@"getRemoteEnableState"];
    if ([deviceId isEqualToNumber:_remoteEntity.deviceId]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_enableSwitch setOn:[stateStr boolValue]];
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

- (void)doneAction {
    _setSuccess = NO;
    timerSeconde = 20;
    [self showHudTogether];
    
    if ([_remoteEntity.shortName isEqualToString:@"RB04"] || [_remoteEntity.shortName isEqualToString:@"RSIBH"]) {
        NSString *cmdStr1;
        if ([_tConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_tSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
            NSString *deviceIdString = [self exchangePositionOfDeviceId:_tSelectOneLabel.tag];
            DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_fSelectOneLabel.tag]];
            if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
                NSString *chanelSelect;
                if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                    chanelSelect = @"2";
                }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                    chanelSelect = @"3";
                }else {
                    chanelSelect = @"1";
                }
                cmdStr1 = [NSString stringWithFormat:@"010%@00%@",chanelSelect,deviceIdString];
            }else {
                cmdStr1 = [NSString stringWithFormat:@"010100%@",deviceIdString];
            }
        }else if ([_tConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_tSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
            
            NSString *rcIndexStr;
            NSInteger dimmerNum = 0;
            NSInteger switchNum = 0;
            NSInteger RGBNum = 0;
            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:_sSelectOneLabel.tag]];
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
            NSString *deviceIdString = [self exchangePositionOfDeviceId:_tSelectOneLabel.tag];
            cmdStr1 = [NSString stringWithFormat:@"01%@00%@",[CSRUtilities stringWithHexNumber:[rcIndexStr integerValue]],deviceIdString];
        }else if ([_tConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_tSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
            NSString *deviceIdString = [self exchangePositionOfDeviceId:_tSelectOneLabel.tag];
            cmdStr1 = [NSString stringWithFormat:@"01%@0000",deviceIdString];
        }else{
            cmdStr1 = @"0100000000";
        }
        
        NSString *cmdStr2;
        if ([_tConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_tSelectTwoLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
            NSString *deviceIdString = [self exchangePositionOfDeviceId:_tSelectTwoLabel.tag];
            DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_fSelectOneLabel.tag]];
            if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
                NSString *chanelSelect;
                if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                    chanelSelect = @"2";
                }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                    chanelSelect = @"3";
                }else {
                    chanelSelect = @"1";
                }
                cmdStr2 = [NSString stringWithFormat:@"020%@00%@",chanelSelect,deviceIdString];
            }else {
                cmdStr2 = [NSString stringWithFormat:@"020100%@",deviceIdString];
            }
        }else if ([_tConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_tSelectTwoLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
            
            NSString *rcIndexStr;
            NSInteger dimmerNum = 0;
            NSInteger switchNum = 0;
            NSInteger RGBNum = 0;
            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:_tSelectTwoLabel.tag]];
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
            NSString *deviceIdString = [self exchangePositionOfDeviceId:_tSelectTwoLabel.tag];
            cmdStr2 = [NSString stringWithFormat:@"02%@00%@",[CSRUtilities stringWithHexNumber:[rcIndexStr integerValue]],deviceIdString];
        }else if ([_tConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_tSelectTwoLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
            NSString *deviceIdString = [self exchangePositionOfDeviceId:_tSelectTwoLabel.tag];
            cmdStr2 = [NSString stringWithFormat:@"02%@0000",deviceIdString];
        }else{
            cmdStr2 = @"0200000000";
        }
        NSString *cmdString = [NSString stringWithFormat:@"9b1102%@%@",cmdStr1,cmdStr2];
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
            if ([_remoteEntity.shortName isEqualToString:@"RB01"]) {
                NSString *cmdStr1;
                if ([_fConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_fSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectOneLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_fSelectOneLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr1 = [NSString stringWithFormat:@"010%@00%@",chanelSelect,deviceIdString];
                    }else {
                        cmdStr1 = [NSString stringWithFormat:@"010100%@",deviceIdString];
                    }
                    
                }else if ([_fConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_fSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectOneLabel.tag];
                    if ([self isContainInGroupByGroupIdInt:_fSelectOneLabel.tag]) {
                        cmdStr1 = [NSString stringWithFormat:@"012100%@",deviceIdString];
                    }else {
                        cmdStr1 = [NSString stringWithFormat:@"012000%@",deviceIdString];
                    }
                }else if ([_fConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_fSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectOneLabel.tag];
                    cmdStr1 = [NSString stringWithFormat:@"01%@0000",deviceIdString];
                }else{
                    cmdStr1 = @"0100000000";
                }
                
                NSString *cmdStr2;
                if ([_fConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_fSelectTwoLabel.text isEqualToString:@"Not found"]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectTwoLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_fSelectOneLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr2 = [NSString stringWithFormat:@"020%@00%@",chanelSelect,deviceIdString];
                    }else {
                        cmdStr2 = [NSString stringWithFormat:@"020100%@",deviceIdString];
                    }
                }else if ([_fConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_fSelectTwoLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectTwoLabel.tag];
                    if ([self isContainInGroupByGroupIdInt:_fSelectTwoLabel.tag]) {
                        cmdStr2 = [NSString stringWithFormat:@"022100%@",deviceIdString];
                    }else {
                        cmdStr2 = [NSString stringWithFormat:@"022000%@",deviceIdString];
                    }
                }else if ([_fConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_fSelectTwoLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectTwoLabel.tag];
                    cmdStr2 = [NSString stringWithFormat:@"02%@0000",deviceIdString];
                }else{
                    cmdStr2 = @"0200000000";
                }
                
                NSString *cmdStr3;
                if ([_fConrolThreeLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_fSelectThreeLabel.text isEqualToString:@"Not found"]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectThreeLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_fSelectOneLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr3 = [NSString stringWithFormat:@"030%@00%@",chanelSelect,deviceIdString];
                    }else {
                        cmdStr3 = [NSString stringWithFormat:@"030100%@",deviceIdString];
                    }
                }else if ([_fConrolThreeLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_fSelectThreeLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectThreeLabel.tag];
                    if ([self isContainInGroupByGroupIdInt:_fSelectThreeLabel.tag]) {
                        cmdStr3 = [NSString stringWithFormat:@"032100%@",deviceIdString];
                    }else {
                        cmdStr3 = [NSString stringWithFormat:@"032000%@",deviceIdString];
                    }
                }else if ([_fConrolThreeLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_fSelectThreeLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectThreeLabel.tag];
                    cmdStr3 = [NSString stringWithFormat:@"03%@0000",deviceIdString];
                }else{
                    cmdStr3 = @"0300000000";
                }
                
                NSString *cmdStr4;
                if ([_fConrolFourLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_fSelectFourLabel.text isEqualToString:@"Not found"]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectFourLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_fSelectOneLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr4 = [NSString stringWithFormat:@"040%@00%@",chanelSelect,deviceIdString];
                    }else {
                        cmdStr4 = [NSString stringWithFormat:@"040100%@",deviceIdString];
                    }
                }else if ([_fConrolFourLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_fSelectFourLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectFourLabel.tag];
                    if ([self isContainInGroupByGroupIdInt:_fSelectFourLabel.tag]) {
                        cmdStr4 = [NSString stringWithFormat:@"042100%@",deviceIdString];
                    }else {
                        cmdStr4 = [NSString stringWithFormat:@"042000%@",deviceIdString];
                    }
                }else if ([_fConrolFourLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_fSelectFourLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectFourLabel.tag];
                    cmdStr4 = [NSString stringWithFormat:@"04%@0000",deviceIdString];
                }else {
                    cmdStr4 = @"0400000000";
                }
                
                NSString *cmdString = [NSString stringWithFormat:@"9b2104%@%@%@%@",cmdStr1,cmdStr2,cmdStr3,cmdStr4];
                
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
                
                
            }else if ([_remoteEntity.shortName isEqualToString:@"RB02"]||[_remoteEntity.shortName isEqualToString:@"S10IB-H2"]) {
                NSString *cmdStr1;
                if ([_sConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_sSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_sSelectOneLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_sSelectOneLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
                        NSString *chanelSelect;
                        if (deviceModel.channel1Selected && !deviceModel.channel2Selected) {
                            chanelSelect = @"2";
                        }else if (!deviceModel.channel1Selected && deviceModel.channel2Selected) {
                            chanelSelect = @"3";
                        }else {
                            chanelSelect = @"1";
                        }
                        cmdStr1 = [NSString stringWithFormat:@"9b0601010%@00%@",chanelSelect,deviceIdString];
                    }else {
                        cmdStr1 = [NSString stringWithFormat:@"9b0601010100%@",deviceIdString];
                    }
                }else if ([_sConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_sSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    
                    NSString *rcIndexStr;
                    NSInteger dimmerNum = 0;
                    NSInteger switchNum = 0;
                    NSInteger RGBNum = 0;
                    CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:_sSelectOneLabel.tag]];
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
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_sSelectOneLabel.tag];
                    cmdStr1 = [NSString stringWithFormat:@"9b060101%@00%@",[CSRUtilities stringWithHexNumber:[rcIndexStr integerValue]],deviceIdString];
                }else if ([_sConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_sSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_sSelectOneLabel.tag];
                    cmdStr1 = [NSString stringWithFormat:@"9b060101%@0000",deviceIdString];
                }else{
                    cmdStr1 = @"9b06010100000000";
                }
                [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdStr1] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                    
                    _remoteEntity.remoteBranch = cmdStr1;
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
            if ([_remoteEntity.shortName isEqualToString:@"RB01"]) {
                NSString *cmdStr1;
                if ([_fConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_fSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectOneLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_fSelectOneLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
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
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
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
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
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
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
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
            }else if ([_remoteEntity.shortName isEqualToString:@"RB02"]) {
                NSString *cmdStr1;
                if ([_sConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_sSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
                    NSString *deviceIdString = [self exchangePositionOfDeviceId:_sSelectOneLabel.tag];
                    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:[NSNumber numberWithInteger:_sSelectOneLabel.tag]];
                    if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
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
            }
        }
    }
}

- (IBAction)enableRemote:(UISwitch *)sender {
    [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea500101%d",sender.on]] success:nil failure:nil];
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

@end
