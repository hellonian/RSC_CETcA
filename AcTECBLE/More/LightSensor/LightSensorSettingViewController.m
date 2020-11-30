//
//  LightSensorSettingViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/6/14.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "LightSensorSettingViewController.h"
#import "DeviceListViewController.h"
#import "CSRUtilities.h"
#import "CSRDatabaseManager.h"
#import "CSRDevicesManager.h"
#import "CSRAppStateManager.h"
#import "SingleDeviceModel.h"
#import "PureLayout.h"
#import <MBProgressHUD.h>
#import "DataModelManager.h"
#import "SelectModel.h"

@interface LightSensorSettingViewController ()</*UITableViewDelegate,UITableViewDataSource,*/PowerModelApiDelegate,UITextFieldDelegate,MBProgressHUDDelegate>

//@property (weak, nonatomic) IBOutlet UITableView *tableView;
//@property (nonatomic,strong) NSMutableArray *dataArray;
@property (nonatomic,strong) CSRmeshDevice *deleteDevice;
@property (nonatomic,strong) UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UITextField *nameTF;
@property (nonatomic,copy) NSString *originalName;
@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (nonatomic,strong) MBProgressHUD *hud;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (nonatomic, strong) NSNumber *selectedNum;
@property (weak, nonatomic) IBOutlet UILabel *selectedLabel;

@property (weak, nonatomic) IBOutlet UILabel *targetIllLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentIllLabel;


@end

@implementation LightSensorSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationItem.title = self.lightSensor.name;
    self.nameTF.delegate = self;
    self.nameTF.text = self.lightSensor.name;
    self.originalName = self.lightSensor.name;
    NSString *macAddr = [self.lightSensor.uuid substringFromIndex:24];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deleteStatus:)
                                                 name:kCSRDeviceManagerDeviceFoundForReset
                                               object:nil];
    if (@available(iOS 11.0, *)){
    }else {
        [_bgView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64];
    }
    
    if (self.lightSensor.remoteBranch && [self.lightSensor.remoteBranch length]>=10) {
        NSInteger idInteger = [self exchangeLowHigh:[self.lightSensor.remoteBranch substringWithRange:NSMakeRange(2, 4)]];
        self.selectedNum = [NSNumber numberWithInteger:idInteger];
        NSString *name;
        if (idInteger > 32768) {
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:[NSNumber numberWithInteger:idInteger]];
            name = deviceEntity.name;
        }else {
            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:[NSNumber numberWithInteger:idInteger]];
            name = areaEntity.areaName;
        }
        self.selectedLabel.text = name;
        
        NSInteger luxInteger = [self exchangeLowHigh:[self.lightSensor.remoteBranch substringWithRange:NSMakeRange(6, 4)]];
        self.targetIllLabel.text = [NSString stringWithFormat:@"%ld Lux",(long)luxInteger];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settedLightSensorCall:) name:@"settedLightSensorCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCurrenIllumination:) name:@"getCurrenIllumination" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"settedLightSensorCall" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"getCurrenIllumination" object:nil];
}

- (void)settedLightSensorCall:(NSNotification *)info {
    NSDictionary *dic = info.userInfo;
    NSString *dataStr = dic[@"dataStr"];
    NSNumber *sourceDeviceId = dic[@"deviceId"];
    if ([sourceDeviceId isEqualToNumber:_lightSensor.deviceId]) {
        if (_hud) {
            [_hud hideAnimated:YES];
            _hud = nil;
        }
        BOOL state = [[dataStr substringToIndex:2] boolValue];
        if (state) {
            [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
        }
        
        NSString *targetIllStr = [dataStr substringWithRange:NSMakeRange(6, 4)];
        NSInteger targetIllInt = [self exchangeLowHigh:targetIllStr];
        _targetIllLabel.text = [NSString stringWithFormat:@"%ld Lux",(long)targetIllInt];
        
        self.lightSensor.remoteBranch = dataStr;
        [[CSRDatabaseManager sharedInstance] saveContext];
    }
   
}

- (NSInteger)exchangeLowHigh:(NSString *)string {
    NSString *str1 = [string substringToIndex:2];
    NSString *str2 = [string substringFromIndex:2];
    NSString *newString = [NSString stringWithFormat:@"%@%@",str2,str1];
    return [CSRUtilities numberWithHexString:newString];
}

- (IBAction)selectDeviceOrGroup:(id)sender {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_ForLightSensor;
    if (self.selectedNum) {
        SelectModel *model = [[SelectModel alloc] init];
        model.deviceID = _selectedNum;
        model.channel = @1;
        model.sourceID = _lightSensor.deviceId;
        list.originalMembers = [NSArray arrayWithObject:model];
    }
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count]>0) {
            SelectModel *mod = devices[0];
            [self didSelected:mod.deviceID];
        }else {
            self.selectedNum = nil;
            self.targetIllLabel.text = nil;
            [[DataModelManager shareInstance] sendCmdData:@"760400000000" toDeviceId:self.lightSensor.deviceId];
            self.lightSensor.remoteBranch = nil;
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)didSelected:(NSNumber *)number {
    if ((number && self.selectedNum && ![number isEqualToNumber:self.selectedNum]) || !self.selectedNum) {
        self.selectedNum = number;
        NSString *name;
        if ([number integerValue]>32768) {
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:number];
            name = deviceEntity.name;
        }else {
            CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:number];
            name = areaEntity.areaName;
        }
        self.selectedLabel.text = name;
        NSString *address = [CSRUtilities exchangePositionOfDeviceId:[self.selectedNum integerValue]];
        
        [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"76040001%@",address] toDeviceId:self.lightSensor.deviceId];
    }
}

#pragma mark - 删除光感

- (IBAction)deleteAction:(id)sender {
    _deleteDevice = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:self.lightSensor.deviceId];
    CSRPlaceEntity *placeEntity = [CSRAppStateManager sharedInstance].selectedPlace;
    if (![CSRUtilities isStringEmpty:placeEntity.passPhrase]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AcTECLocalizedStringFromTable(@"DeleteDevice", @"Localizable") message:[NSString stringWithFormat:@"%@ : %@?",AcTECLocalizedStringFromTable(@"DeleteDeviceAlert", @"Localizable"),self.lightSensor.name] preferredStyle:UIAlertControllerStyleAlert];
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
        [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:self.lightSensor];
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:self.lightSensor];
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
    [alertController.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [_spinner stopAnimating];
                                                             [_spinner setHidden:YES];
                                                         }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         
                                                         [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:self.lightSensor];
                                                         [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:self.lightSensor];
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

#pragma mark - 修改光感名称

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
    if ([textField isEqual:_nameTF]) {
        [self saveNickName];
        return;
    }
}

- (void)saveNickName {
    if (![_nameTF.text isEqualToString:_originalName] && _nameTF.text.length > 0) {
        self.navigationItem.title = _nameTF.text;
        self.lightSensor.name = _nameTF.text;
        [[CSRDatabaseManager sharedInstance] saveContext];
        if (self.reloadDataHandle) {
            self.reloadDataHandle();
        }
    }
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

- (void)showTextHud:(NSString *)text {
    MBProgressHUD *successHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    successHud.mode = MBProgressHUDModeText;
    successHud.label.text = text;
    successHud.delegate = self;
    [successHud hideAnimated:YES afterDelay:1.5f];
}

- (IBAction)getCurrenLux:(id)sender {
    [[DataModelManager shareInstance] sendCmdData:@"760104" toDeviceId:self.lightSensor.deviceId];
}

- (void)getCurrenIllumination:(NSNotification *)info {
    NSDictionary *dic = info.userInfo;
    NSString *dataStr = dic[@"dataStr"];
    NSNumber *sourceDeviceId = dic[@"deviceId"];
    if ([sourceDeviceId isEqualToNumber:_lightSensor.deviceId]) {
        NSInteger currentIllInt = [self exchangeLowHigh:dataStr];
        _currentIllLabel.text = [NSString stringWithFormat:@"%ld Lux",(long)currentIllInt];
    }
}
    
- (IBAction)learn:(UIButton *)sender {
    if (self.selectedNum) {
        NSString *address = [CSRUtilities exchangePositionOfDeviceId:[self.selectedNum integerValue]];
        [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"76040001%@",address] toDeviceId:self.lightSensor.deviceId];
    }else {
        [[DataModelManager shareInstance] sendCmdData:@"760400000000" toDeviceId:self.lightSensor.deviceId];
    }
}
    
@end
