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

@interface RemoteSettingViewController ()<UITextFieldDelegate,MBProgressHUDDelegate>
{
    dispatch_semaphore_t semaphore;
    NSInteger timerSeconde;
    NSTimer *timer;
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
        
        /*
        if (self.remoteEntity.remoteBranch && self.remoteEntity.remoteBranch.length == 16) {
            NSString *myStr1 = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(0, 4)];
            CSRDeviceEntity *deviceEntity1 = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:@([CSRUtilities numberWithHexString:myStr1])];
            self.fSelectOneLabel.text = deviceEntity1.name;
            self.fSelectOneLabel.tag = [CSRUtilities numberWithHexString:myStr1];
            NSString *myStr2 = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(4, 4)];
            CSRDeviceEntity *deviceEntity2 = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:@([CSRUtilities numberWithHexString:myStr2])];
            self.fSelectTwoLabel.text = deviceEntity2.name;
            self.fSelectTwoLabel.tag = [CSRUtilities numberWithHexString:myStr2];
            NSString *myStr3 = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 4)];
            CSRDeviceEntity *deviceEntity3 = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:@([CSRUtilities numberWithHexString:myStr3])];
            self.fSelectThreeLabel.text = deviceEntity3.name;
            self.fSelectThreeLabel.tag = [CSRUtilities numberWithHexString:myStr3];
            NSString *myStr4 = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(12, 4)];
            CSRDeviceEntity *deviceEntity4 = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:@([CSRUtilities numberWithHexString:myStr4])];
            self.fSelectFourLabel.text = deviceEntity4.name;
            self.fSelectFourLabel.tag = [CSRUtilities numberWithHexString:myStr4];
        }*/
        
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
                        NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(8, 4)]];
                        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                        if (deviceEntity) {
                            _fSelectOneLabel.text = deviceEntity.name;
                            _fSelectOneLabel.tag = deviceId;
                        }else {
                            _fSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                        }
                    }else if ([rcIndex isEqualToString:@"0200"]) {
                        _fConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                        NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(8, 4)]];
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
                        NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(8, 4)]];
                        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                        if (deviceEntity) {
                            _fSelectTwoLabel.text = deviceEntity.name;
                            _fSelectTwoLabel.tag = deviceId;
                        }else {
                            _fSelectTwoLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                        }

                    }else if ([rcIndex isEqualToString:@"0200"]) {
                        _fConrolTwoLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                        NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(8, 4)]];
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
                        NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(8, 4)]];
                        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                        if (deviceEntity) {
                            _fSelectThreeLabel.text = deviceEntity.name;
                            _fSelectThreeLabel.tag = deviceId;
                        }else{
                            _fSelectThreeLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                        }
                        
                    }else if ([rcIndex isEqualToString:@"0200"]) {
                        _fConrolThreeLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                        NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(8, 4)]];
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
                        NSInteger deviceId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(8, 4)]];
                        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                        if (deviceEntity) {
                            _fSelectFourLabel.text = deviceEntity.name;
                            _fSelectFourLabel.tag = deviceId;
                        }else{
                            _fSelectFourLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                        }
                        
                    }else if ([rcIndex isEqualToString:@"0200"]) {
                        _fConrolFourLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                        NSInteger areaId = [self exchangePositionOfDeviceIdString:[brach substringWithRange:NSMakeRange(8, 4)]];
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
                NSInteger deviceId = [self exchangePositionOfDeviceIdString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 4)]];
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:deviceId]];
                if (deviceEntity) {
                    _sSelectOneLabel.text = deviceEntity.name;
                    _sSelectOneLabel.tag = deviceId;
                }else {
                    _sSelectOneLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
                }
            }else if ([rcIndex isEqualToString:@"0200"]) {
                _sConrolOneLabel.text = AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable");
                NSInteger areaId = [self exchangePositionOfDeviceIdString:[self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 4)]];
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
    }
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = done;
//    self.navigationItem.rightBarButtonItem.enabled = NO;
    semaphore = dispatch_semaphore_create(1);
    
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deleteStatus:)
                                                 name:kCSRDeviceManagerDeviceFoundForReset
                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(settingRemoteCall:)
//                                                 name:@"settingRemoteCall" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(getRemoteConfiguration:)
//                                                 name:@"getRemoteConfiguration" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getRemoteBattery:) name:@"getRemoteBattery" object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRDeviceManagerDeviceFoundForReset
                                                  object:nil];
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:@"settingRemoteCall"
//                                                  object:nil];
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:@"getRemoteConfiguration"
//                                                  object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:@"getRemoteBattery" object:nil];
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
    
    /*
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_Single;
    
    if (self.remoteEntity.remoteBranch) {
        NSString *myStr;
        if (sender.tag == 100) {
            myStr = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(0, 4)];
        }
        if (sender.tag == 101) {
            myStr = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(4, 4)];
        }
        if (sender.tag == 102) {
            myStr = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 4)];
        }
        if (sender.tag == 103) {
            myStr = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(12, 4)];
        }
        if (sender.tag == 200) {
            myStr = self.remoteEntity.remoteBranch;
        }
        if (![myStr isEqualToString:@"ffff"]) {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:[CSRUtilities numberWithHexString:myStr]]];
            SingleDeviceModel *deviceModel = [[SingleDeviceModel alloc] init];
            deviceModel.deviceId = device.deviceId;
            deviceModel.deviceName = device.name;
            deviceModel.deviceShortName = device.shortName;
            list.originalMembers = [NSArray arrayWithObject:deviceModel];
        }
    }
    
    [list getSelectedDevices:^(NSArray *devices) {
        
        if ([devices count] > 0) {
            NSNumber *deviceId = devices[0];
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
            if (sender.tag == 100) {
                _fSelectOneLabel.text = deviceEntity.name;
                _fSelectOneLabel.tag = [deviceId integerValue];
                
                if (self.remoteEntity.remoteBranch) {
                    NSString *myStr1 = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(0, 4)];
                    if ([CSRUtilities numberWithHexString:myStr1] != [deviceId integerValue] && !self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }else {
                    if (!self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }
                
                return;
            }
            if (sender.tag == 101) {
                _fSelectTwoLabel.text = deviceEntity.name;
                _fSelectTwoLabel.tag = [deviceId integerValue];
                
                if (self.remoteEntity.remoteBranch) {
                    NSString *myStr2 = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(4, 4)];
                    if ([CSRUtilities numberWithHexString:myStr2] != [deviceId integerValue] && !self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }else {
                    if (!self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }
                
                return;
            }
            if (sender.tag == 102) {
                _fSelectThreeLabel.text = deviceEntity.name;
                _fSelectThreeLabel.tag = [deviceId integerValue];
                
                if (self.remoteEntity.remoteBranch) {
                    NSString *myStr3 = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 4)];
                    if ([CSRUtilities numberWithHexString:myStr3] != [deviceId integerValue] && !self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }else {
                    if (!self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }
                
                return;
            }
            if (sender.tag == 103) {
                _fSelectFourLabel.text = deviceEntity.name;
                _fSelectFourLabel.tag = [deviceId integerValue];
                
                if (self.remoteEntity.remoteBranch) {
                    NSString *myStr4 = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(12, 4)];
                    if ([CSRUtilities numberWithHexString:myStr4] != [deviceId integerValue] && !self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }else {
                    if (!self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }
                
                return;
            }
            if (sender.tag == 200) {
                _sSelectOneLabel.text = deviceEntity.name;
                _sSelectOneLabel.tag = [deviceId integerValue];
                
                if (self.remoteEntity.remoteBranch) {
                    if ([CSRUtilities numberWithHexString:self.remoteEntity.remoteBranch] != [deviceId integerValue] && !self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }else {
                    if (!self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }
                
                
                return;
            }
        }else {
            if (sender.tag == 100) {
                _fSelectOneLabel.text = @"";
                _fSelectOneLabel.tag = 0;
                
                if (self.remoteEntity.remoteBranch) {
                    NSString *myStr1 = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(0, 4)];
                    if (![myStr1 isEqualToString:@"ffff"] && !self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }else {
                    if (!self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }
                
                return;
            }
            if (sender.tag == 101) {
                _fSelectTwoLabel.text = @"";
                _fSelectTwoLabel.tag = 0;
                
                if (self.remoteEntity.remoteBranch) {
                    NSString *myStr2 = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(4, 4)];
                    if (![myStr2 isEqualToString:@"ffff"] && !self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }else {
                    if (!self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }
                
                return;
            }
            if (sender.tag == 102) {
                _fSelectThreeLabel.text = @"";
                _fSelectThreeLabel.tag = 0;
                
                if (self.remoteEntity.remoteBranch) {
                    NSString *myStr3 = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(8, 4)];
                    if (![myStr3 isEqualToString:@"ffff"] && !self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }else {
                    if (!self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }
                
                return;
            }
            if (sender.tag == 103) {
                _fSelectFourLabel.text = @"";
                _fSelectFourLabel.tag = 0;
                
                if (self.remoteEntity.remoteBranch) {
                    NSString *myStr4 = [self.remoteEntity.remoteBranch substringWithRange:NSMakeRange(12, 4)];
                    if (![myStr4 isEqualToString:@"ffff"] && !self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }else {
                    if (!self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }
                
                return;
            }
            if (sender.tag == 200) {
                _sSelectOneLabel.text = @"";
                _sSelectOneLabel.tag = 0;
                
                if (self.remoteEntity.remoteBranch) {
                    if (![self.remoteEntity.remoteBranch isEqualToString:@"ffff"] && !self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }else {
                    if (!self.navigationItem.rightBarButtonItem.enabled) {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                    }
                }
                
                
                return;
            }
        }
    }];
    [self.navigationController pushViewController:list animated:YES];
     */
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
}

- (NSString *)cmdStringWithSceneRcIndex:(NSInteger)rcIndex swIndex:(NSInteger)swIndex {
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:@(rcIndex)];
    NSString *rcIndexStr = [self exchangePositionOfDeviceId:rcIndex];
    NSString *ligCnt = [CSRUtilities stringWithHexNumber:[sceneEntity.members count]];
    NSString *startLigIdx = @"00";
    NSString *endLigIdx = [CSRUtilities stringWithHexNumber:[sceneEntity.members count]-1];
    NSString *dstAddrLevel = @"";
    for (SceneMemberEntity *sceneMember in sceneEntity.members) {
        NSString *eveType = @"";
        if ([sceneMember.powerState boolValue]) {
            eveType = @"12";
        }else {
            eveType = @"11";
        }
        NSString *level = [[NSString alloc] initWithFormat:@"%1lx",(long)[sceneMember.level integerValue]];
        level = level.length > 1 ? level:[NSString stringWithFormat:@"0%@",level];
//        dstAddrLevel = [NSString stringWithFormat:@"%@%@%@",dstAddrLevel,[self exchangePositionOfDeviceId:[sceneMember.deviceID integerValue]],level];
        dstAddrLevel = [NSString stringWithFormat:@"%@%@%@%@000000",dstAddrLevel,[self exchangePositionOfDeviceId:[sceneMember.deviceID integerValue]],eveType,level];
    }
    NSString *nLength = [CSRUtilities stringWithHexNumber:dstAddrLevel.length/2+7];
    if ((dstAddrLevel.length/2+7)<250) {
        NSString *cmdStr = [NSString stringWithFormat:@"73%@010%ld%@%@%@%@%@",nLength,swIndex,rcIndexStr,ligCnt,startLigIdx,endLigIdx,dstAddrLevel];
        return cmdStr;
    }
    return nil;
}

- (void)doneAction {
    _setSuccess = NO;
    timerSeconde = 10;
    [self showHudTogether];
    
    if ([_remoteEntity.shortName isEqualToString:@"RB01"]) {
        NSString *cmdStr1;
        if ([_fConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_fSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
            NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectOneLabel.tag];
            cmdStr1 = [NSString stringWithFormat:@"730e01010100010000%@0000000000",deviceIdString];
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
            cmdStr2 = [NSString stringWithFormat:@"730e01020100010000%@0000000000",deviceIdString];
        }else if ([_fConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_fSelectTwoLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
            NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectTwoLabel.tag];
            cmdStr2 = [NSString stringWithFormat:@"730e010220ee010000%@0000000000",deviceIdString];
        }else if ([_fConrolTwoLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_fSelectTwoLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
            cmdStr2 = [self cmdStringWithSceneRcIndex:_fSelectTwoLabel.tag swIndex:2];
        }else{
            cmdStr2 = @"730701020000000000";
        }
        
        NSString *cmdStr3;
        if ([_fConrolThreeLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_fSelectThreeLabel.text isEqualToString:@"Not found"]) {
            NSString *deviceIdString = [self exchangePositionOfDeviceId:_fSelectThreeLabel.tag];
            cmdStr3 = [NSString stringWithFormat:@"730e01030100010000%@0000000000",deviceIdString];
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
            cmdStr4 = [NSString stringWithFormat:@"730e01040100010000%@0000000000",deviceIdString];
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
                        timerSeconde = 10;
                    } failure:^(NSError * _Nonnull error) {
                        
                    }];
                });
                
                NSLog(@"信号量-1 第一个按键  %@",cmdStr1);
                
            }
            
        });
        
        dispatch_async(queue, ^{
            
            if (cmdStr2.length>0) {
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdStr2] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                        dispatch_semaphore_signal(semaphore);
                        timerSeconde = 10;
                    } failure:^(NSError * _Nonnull error) {
                        
                    }];
                });
                
                NSLog(@"信号量-1 第二个按键  %@",cmdStr2);
                
            }
            
        });
        
        dispatch_async(queue, ^{
            
            if (cmdStr3.length>0) {
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[DataModelApi sharedInstance] sendData:_remoteEntity.deviceId data:[CSRUtilities dataForHexString:cmdStr3] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                        dispatch_semaphore_signal(semaphore);
                        timerSeconde = 10;
                    } failure:^(NSError * _Nonnull error) {
                        
                    }];
                });
                
                NSLog(@"信号量-1 第三个按键  %@",cmdStr3);
                
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
                
            }
            
        });
    }else if ([_remoteEntity.shortName isEqualToString:@"RB02"]) {
        NSString *cmdStr1;
        if ([_sConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Lamp", @"Localizable")] && ![_sSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
            NSString *deviceIdString = [self exchangePositionOfDeviceId:_sSelectOneLabel.tag];
            cmdStr1 = [NSString stringWithFormat:@"730e01010100010000%@0000000000",deviceIdString];
        }else if ([_sConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Group", @"Localizable")] && ![_sSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
            NSString *deviceIdString = [self exchangePositionOfDeviceId:_sSelectOneLabel.tag];
            cmdStr1 = [NSString stringWithFormat:@"730e01012000010000%@0000000000",deviceIdString];
        }else if ([_sConrolOneLabel.text containsString:AcTECLocalizedStringFromTable(@"Scene", @"Localizable")] && ![_sSelectOneLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Notfound", @"Localizable")]) {
            cmdStr1 = [self cmdStringWithSceneRcIndex:_sSelectOneLabel.tag swIndex:1];
        }else{
            cmdStr1 = @"730701010000000000";
        }
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
    }
    
    
    
    
    
    /*
    NSString *cmdStr;
    if ([_remoteEntity.shortName isEqualToString:@"RB01"]) {
        NSString *str1;
        NSString *str2;
        NSString *str3;
        NSString *str4;
        if (_fSelectOneLabel.tag == 0) {
            str1 = @"ffff";
        }else{
            str1 = [self exchangePositionOfDeviceId:_fSelectOneLabel.tag];
        }
        if (_fSelectTwoLabel.tag == 0) {
            str2 = @"ffff";
        }else{
            str2 = [self exchangePositionOfDeviceId:_fSelectTwoLabel.tag];
        }
        if (_fSelectThreeLabel.tag == 0) {
            str3 = @"ffff";
        }else{
            str3 = [self exchangePositionOfDeviceId:_fSelectThreeLabel.tag];
        }
        if (_fSelectFourLabel.tag == 0) {
            str4 = @"ffff";
        }else{
            str4 = [self exchangePositionOfDeviceId:_fSelectFourLabel.tag];
        }
        cmdStr = [NSString stringWithFormat:@"700b010000%@%@%@%@",str1,str2,str3,str4];
        
        NSString *mystr1 = _fSelectOneLabel.tag == 0 ? @"ffff":[[NSString alloc] initWithFormat:@"%1lx",(long)_fSelectOneLabel.tag];
        NSString *mystr2 = _fSelectTwoLabel.tag == 0 ? @"ffff":[[NSString alloc] initWithFormat:@"%1lx",(long)_fSelectTwoLabel.tag];
        NSString *mystr3 = _fSelectThreeLabel.tag == 0 ? @"ffff":[[NSString alloc] initWithFormat:@"%1lx",(long)_fSelectThreeLabel.tag];
        NSString *mystr4 = _fSelectFourLabel.tag == 0 ? @"ffff":[[NSString alloc] initWithFormat:@"%1lx",(long)_fSelectFourLabel.tag];
        _remoteEntity.remoteBranch = [NSString stringWithFormat:@"%@%@%@%@",mystr1,mystr2,mystr3,mystr4];
        [[CSRDatabaseManager sharedInstance] saveContext];
        
    }else if ([_remoteEntity.shortName isEqualToString:@"RB02"]) {
        NSString *string;
        if (_sSelectOneLabel.tag == 0) {
            string = @"ffff";
        }else {
            string = [self exchangePositionOfDeviceId:_sSelectOneLabel.tag];
        }
        cmdStr = [NSString stringWithFormat:@"700b010000%@ffffffffffff",string];
        
        NSString *mystr1 = _sSelectOneLabel.tag == 0 ? @"ffff":[[NSString alloc] initWithFormat:@"%1lx",(long)_sSelectOneLabel.tag];
        _remoteEntity.remoteBranch = mystr1;
        [[CSRDatabaseManager sharedInstance] saveContext];
    }
    [self showHudTogether];
    [[DataModelManager shareInstance] sendCmdData:cmdStr toDeviceId:_remoteEntity.deviceId];
     */
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
    NSLog(@"%d  %ld",_setSuccess,timerSeconde);
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

/*
- (IBAction)readAction:(UIButton *)sender {
    [self showHudTogether];
//    [[DataModelManager shareInstance] sendCmdData:@"72020000" toDeviceId:_remoteEntity.deviceId];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[DataModelManager shareInstance] sendCmdData:@"710100" toDeviceId:_remoteEntity.deviceId];
//    });
}

- (void)getRemoteConfiguration:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSString *deviceID1 = dic[@"deviceID1"];
    NSString *deviceID2 = dic[@"deviceID2"];
    NSString *deviceID3 = dic[@"deviceID3"];
    NSString *deviceID4 = dic[@"deviceID4"];
    if ([self.remoteEntity.shortName isEqualToString:@"RB01"]) {
        
        if ([deviceID1 isEqualToString:@"ffff"]) {
            _fSelectOneLabel.text = @"";
        }else {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:[CSRUtilities numberWithHexString:deviceID1]]];
            _fSelectOneLabel.text = [NSString stringWithFormat:@"%@",device.name];
        }
        if ([deviceID2 isEqualToString:@"ffff"]) {
            _fSelectTwoLabel.text = @"";
        }else {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:[CSRUtilities numberWithHexString:deviceID2]]];
            _fSelectTwoLabel.text = [NSString stringWithFormat:@"%@",device.name];
        }
        if ([deviceID3 isEqualToString:@"ffff"]) {
            _fSelectThreeLabel.text = @"";
        }else {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:[CSRUtilities numberWithHexString:deviceID3]]];
            _fSelectThreeLabel.text = [NSString stringWithFormat:@"%@",device.name];
        }
        if ([deviceID4 isEqualToString:@"ffff"]) {
            _fSelectFourLabel.text = @"";
        }else {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:[CSRUtilities numberWithHexString:deviceID4]]];
            _fSelectFourLabel.text = [NSString stringWithFormat:@"%@",device.name];
        }
        
        NSString *newString = [NSString stringWithFormat:@"%@%@%@%@",deviceID1,deviceID2,deviceID3,deviceID4];
        if (![_remoteEntity.remoteBranch isEqualToString:newString]) {
            _remoteEntity.remoteBranch = newString;
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
        
        
    }else if ([self.remoteEntity.shortName isEqualToString:@"RB02"]) {
        if ([deviceID1 isEqualToString:@"ffff"]) {
            _sSelectOneLabel.text = @"";
        }else {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:[CSRUtilities numberWithHexString:deviceID1]]];
            _sSelectOneLabel.text = [NSString stringWithFormat:@"%@",device.name];
        }
        
        if (![_remoteEntity.remoteBranch isEqualToString:deviceID1]) {
            _remoteEntity.remoteBranch = deviceID1;
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
        
    }
    _setSuccess = YES;
    [_hub hideAnimated:YES];
}
 */

//- (void)getRemoteBattery:(NSNotification *)notification {
//    NSDictionary *dic = notification.userInfo;
//    NSInteger battery = [dic[@"batteryPercent"] integerValue];
//    if (battery<1) {
//        battery = 1;
//    }
//    if (battery>100) {
//        battery =100;
//    }
//    self.batteryLabel.text = [NSString stringWithFormat:@"Battery:%ld%%",(long)battery];
//}
/*
- (void)settingRemoteCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSString *state = dic[@"settingRemoteCall"];
    [_hub hideAnimated:YES];
    if ([state boolValue]) {
        _setSuccess = YES;
        [self showTextHud:@"SUCCESS"];
        if (self.navigationItem.rightBarButtonItem.enabled) {
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    }else {
        _setSuccess = NO;
        [self showTextHud:@"ERROR"];
    }
}
 */

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
