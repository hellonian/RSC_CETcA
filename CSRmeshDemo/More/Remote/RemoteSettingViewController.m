//
//  RemoteSettingViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/1.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
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

@interface RemoteSettingViewController ()<UITextFieldDelegate,MBProgressHUDDelegate>

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
@property (nonatomic,strong) MBProgressHUD *hub;
@property (nonatomic,assign) BOOL setSuccess;
@property (weak, nonatomic) IBOutlet UILabel *batteryLabel;

@end

@implementation RemoteSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = self.remoteEntity.name;
    self.nameTF.delegate = self;
    self.nameTF.text = self.remoteEntity.name;
    self.originalName = self.remoteEntity.name;
    
    if ([self.remoteEntity.shortName isEqualToString:@"RB01"]) {
        [self.view addSubview:self.fiveRemoteView];
        [self.fiveRemoteView autoSetDimension:ALDimensionHeight toSize:179.0f];
        [self.fiveRemoteView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.fiveRemoteView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.fiveRemoteView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
    }else if ([self.remoteEntity.shortName isEqualToString:@"RB02"]) {
        [self.view addSubview:self.singleRemoteView];
        [self.singleRemoteView autoSetDimension:ALDimensionHeight toSize:44.0f];
        [self.singleRemoteView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.singleRemoteView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.singleRemoteView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameBgView withOffset:30];
    }
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = done;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deleteStatus:)
                                                 name:kCSRDeviceManagerDeviceFoundForReset
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingRemoteCall:)
                                                 name:@"settingRemoteCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getRemoteConfiguration:) name:@"getRemoteConfiguration" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getRemoteBattery:) name:@"getRemoteBattery" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRDeviceManagerDeviceFoundForReset
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"getRemoteConfiguration" object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:@"getRemoteBattery" object:nil];
}

- (IBAction)fSelectDevice:(UIButton *)sender {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_Single;
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count] > 0) {
            NSNumber *deviceId = devices[0];
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
            if (sender.tag == 100) {
                _fSelectOneLabel.text = deviceEntity.name;
                _fSelectOneLabel.tag = [deviceId integerValue];
                return;
            }
            if (sender.tag == 101) {
                _fSelectTwoLabel.text = deviceEntity.name;
                _fSelectTwoLabel.tag = [deviceId integerValue];
                return;
            }
            if (sender.tag == 102) {
                _fSelectThreeLabel.text = deviceEntity.name;
                _fSelectThreeLabel.tag = [deviceId integerValue];
                return;
            }
            if (sender.tag == 103) {
                _fSelectFourLabel.text = deviceEntity.name;
                _fSelectFourLabel.tag = [deviceId integerValue];
                return;
            }
            if (sender.tag == 200) {
                _sSelectOneLabel.text = deviceEntity.name;
                _sSelectOneLabel.tag = [deviceId integerValue];
                return;
            }
        }
    }];
    [self.navigationController pushViewController:list animated:YES];
}

- (void)doneAction {
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
        
    }else if ([_remoteEntity.shortName isEqualToString:@"RB02"]) {
        NSString *string;
        if (_sSelectOneLabel.tag == 0) {
            string = @"ffff";
        }else {
            string = [self exchangePositionOfDeviceId:_sSelectOneLabel.tag];
        }
        cmdStr = [NSString stringWithFormat:@"700b010000%@ffffffffffff",string];
    }
    [self showHudTogether];
    [[DataModelManager shareInstance] sendCmdData:cmdStr toDeviceId:_remoteEntity.deviceId];
}

- (NSString *)exchangePositionOfDeviceId:(NSInteger)deviceId {
    NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1lx",(long)deviceId]];
    NSString *str11 = [hexString substringToIndex:2];
    NSString *str22 = [hexString substringFromIndex:2];
    NSString *deviceIdStr = [NSString stringWithFormat:@"%@%@",str22,str11];
    return deviceIdStr;
}

- (void)showHudTogether {
    _hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hub.mode = MBProgressHUDModeDeterminateHorizontalBar;
    _hub.delegate = self;
    _hub.label.text = @"Please press the button in the middle of the remote nine times continuously";
    _hub.label.font = [UIFont systemFontOfSize:13];
    _hub.label.numberOfLines = 0;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        float progress = 0.0f;
        while (progress < 1.0f) {
            progress +=0.01f;
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD HUDForView:self.view].progress = progress;
            });
            usleep(100000);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_hub hideAnimated:YES];
            if (_setSuccess == NO) {
                [self showTextHud:@"Time out"];
            }
        });
        
    });
}

- (IBAction)readAction:(UIButton *)sender {
    [self showHudTogether];
//    [[DataModelManager shareInstance] sendCmdData:@"72020000" toDeviceId:_remoteEntity.deviceId];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[DataModelManager shareInstance] sendCmdData:@"710100" toDeviceId:_remoteEntity.deviceId];
//    });
}

- (void)getRemoteConfiguration:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceID1 = dic[@"deviceID1"];
    NSNumber *deviceID2 = dic[@"deviceID2"];
    NSNumber *deviceID3 = dic[@"deviceID3"];
    NSNumber *deviceID4 = dic[@"deviceID4"];
    
    if ([self.remoteEntity.shortName isEqualToString:@"RB01"]) {
        if ([deviceID1 isEqualToNumber:@(65535)]) {
            _fSelectOneLabel.text = @"NULL";
        }else {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID1];
            _fSelectOneLabel.text = [NSString stringWithFormat:@"%@(%@)",device.name,deviceID1];
        }
        if ([deviceID2 isEqualToNumber:@(65535)]) {
            _fSelectTwoLabel.text = @"NULL";
        }else {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID2];
            _fSelectTwoLabel.text = [NSString stringWithFormat:@"%@(%@)",device.name,deviceID2];
        }
        if ([deviceID3 isEqualToNumber:@(65535)]) {
            _fSelectThreeLabel.text = @"NULL";
        }else {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID3];
            _fSelectThreeLabel.text = [NSString stringWithFormat:@"%@(%@)",device.name,deviceID3];
        }
        if ([deviceID4 isEqualToNumber:@(65535)]) {
            _fSelectFourLabel.text = @"NULL";
        }else {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID4];
            _fSelectFourLabel.text = [NSString stringWithFormat:@"%@(%@)",device.name,deviceID4];
        }
        
    }else if ([self.remoteEntity.shortName isEqualToString:@"RB02"]) {
        if ([deviceID1 isEqualToNumber:@(65535)]) {
            _sSelectOneLabel.text = @"NULL";
        }else {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID1];
            _sSelectOneLabel.text = [NSString stringWithFormat:@"%@(%@)",device.name,deviceID1];
        }
    }
    _setSuccess = YES;
    [_hub hideAnimated:YES];
}

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

- (void)settingRemoteCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSString *state = dic[@"settingRemoteCall"];
    [_hub hideAnimated:YES];
    if ([state boolValue]) {
        _setSuccess = YES;
        [self showTextHud:@"SUCCESS"];
    }else {
        _setSuccess = NO;
        [self showTextHud:@"ERROR"];
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
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Device" message:[NSString stringWithFormat:@"Are you sure that you want to delete this device :%@?",self.remoteEntity.name] preferredStyle:UIAlertControllerStyleAlert];
        [alertController.view setTintColor:DARKORAGE];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[CSRDevicesManager sharedInstance] initiateRemoveDevice:_deleteDevice];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Device Device"
                                                                             message:[NSString stringWithFormat:@"Device wasn't found. Do you want to delete %@ anyway?", _deleteDevice.name]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [_spinner stopAnimating];
                                                             [_spinner setHidden:YES];
                                                         }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Yes"
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
