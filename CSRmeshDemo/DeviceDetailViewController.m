//
//  DeviceDetailViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/21.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "DeviceDetailViewController.h"
#import "CSRDevicesManager.h"
#import "CSRDatabaseManager.h"
#import "CSRAppStateManager.h"
#import "CSRUtilities.h"

@interface DeviceDetailViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *brightnessLabel;
@property (weak, nonatomic) IBOutlet UITextField *lightNameTF;
@property (weak, nonatomic) IBOutlet UILabel *deviceIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;
@property (nonatomic,copy) NSString *originalName;
@property (nonatomic,strong) UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UISwitch *kaiguan;
@property (weak, nonatomic) IBOutlet UISlider *huadongtiao;

@end

@implementation DeviceDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeAdvancedSettingPanel)];
        self.navigationItem.rightBarButtonItem = done;
    }
    
    
    self.navigationItem.title = _lightDevice.name;
    self.lightNameTF.text = _lightDevice.name;
    self.deviceIdLabel.text = [NSString stringWithFormat:@"%@",_lightDevice.deviceId];
    self.rssiLabel.text = [NSString stringWithFormat:@"%@",_lightDevice.rssi];
    
    self.lightNameTF.delegate = self;
    self.originalName = _lightDevice.name;
    
    [_kaiguan setOn:[_powerState boolValue]];
    [self enableHuadongtiao];
    
}

- (void)enableHuadongtiao {
    
    if ([_lightDevice.shortName isEqualToString:@"D350BT"]) {
        _huadongtiao.enabled = YES;
        if (_kaiguan.isOn) {
            [_huadongtiao setValue:[_level floatValue]/2.55];
            
        }else {
            [_huadongtiao setValue:0];
        }
    }else {
        _huadongtiao.enabled = NO;
        if (_kaiguan.isOn) {
            [_huadongtiao setValue:100];
        }else {
            [_huadongtiao setValue:0];
        }
    }
    self.brightnessLabel.text = [NSString stringWithFormat:@"%.f%%",_huadongtiao.value];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deleteStatus:)
                                                 name:kCSRDeviceManagerDeviceFoundForReset
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRDeviceManagerDeviceFoundForReset
                                                  object:nil];
}

//点击开关
- (IBAction)powerSwitchChanged:(UISwitch *)sender {
    if (_lightDevice) {
        [_lightDevice setPower:sender.isOn];
        [self enableHuadongtiao];
        
    }
}

//拖动滑动条
- (IBAction)brightnessSliderDragged:(UISlider *)sender {
    
    if (sender.value < 5) {
        sender.value = 5;
    }
    if (sender.value > 0) {
        _kaiguan.on = YES;
    }
    
    if (_lightDevice) {
        _level = @(sender.value * 2.55);
        [_lightDevice setLevel:sender.value * 2.55];
        self.brightnessLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value];
    }
}

#pragma mark - 删除设备

- (IBAction)deleteButtonTapped:(UIButton *)sender {
    _lightDevice = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:_deviceEntity.deviceId];
    CSRPlaceEntity *placeEntity = [CSRAppStateManager sharedInstance].selectedPlace;
    
    if (![CSRUtilities isStringEmpty:placeEntity.passPhrase]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Device" message:[NSString stringWithFormat:@"Are you sure that you want to delete this device :%@?",_lightDevice.name] preferredStyle:UIAlertControllerStyleAlert];
        [alertController.view setTintColor:DARKORAGE];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (_lightDevice) {
                [[CSRDevicesManager sharedInstance] initiateRemoveDevice:_lightDevice];
            }
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
        if(_deviceEntity) {
            [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:_deviceEntity];
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_deviceEntity];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
        NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
        //        [[MeshServiceApi sharedInstance] setNextDeviceId:deviceNumber];
        [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reGetData" object:self];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) showForceAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Device Device"
                                                                             message:[NSString stringWithFormat:@"Device wasn't found. Do you want to delete %@ anyway?", _lightDevice.name]
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
                                                         
                                                         if(_deviceEntity) {
                                                             [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:_deviceEntity];
                                                             [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_deviceEntity];
                                                             [[CSRDatabaseManager sharedInstance] saveContext];
                                                         }
                                                         NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
                                                         //                                                         [[MeshServiceApi sharedInstance] setNextDeviceId:deviceNumber];
                                                         [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
                                                         [[NSNotificationCenter defaultCenter] postNotificationName:@"reGetData" object:self];
                                                         [self dismissViewControllerAnimated:YES completion:nil];
                                                     }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
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
    if (![_lightNameTF.text isEqualToString:_originalName] && _lightNameTF.text.length > 0) {
        self.navigationItem.title = _lightNameTF.text;
        _deviceEntity.name = _lightNameTF.text;
        _lightDevice = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:_deviceEntity.deviceId];
        _lightDevice.name = _lightNameTF.text;
        [[CSRDatabaseManager sharedInstance] saveContext];
        if (self.handle) {
            self.handle();
        }
    }
    
}

- (void)closeAdvancedSettingPanel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
