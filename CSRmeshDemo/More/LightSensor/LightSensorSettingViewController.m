//
//  LightSensorSettingViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/6/14.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "LightSensorSettingViewController.h"
#import "DeviceListViewController.h"
#import <CSRmesh/DataModelApi.h>
#import "CSRUtilities.h"
#import "CSRDatabaseManager.h"
#import "CSRDevicesManager.h"
#import "CSRAppStateManager.h"
#import "SingleDeviceModel.h"
#import "PureLayout.h"
#import <MBProgressHUD.h>

@interface LightSensorSettingViewController ()<UITableViewDelegate,UITableViewDataSource,PowerModelApiDelegate,UITextFieldDelegate,MBProgressHUDDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *dataArray;
@property (nonatomic,strong) CSRmeshDevice *deleteDevice;
@property (nonatomic,strong) UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UITextField *nameTF;
@property (nonatomic,copy) NSString *originalName;
@property (weak, nonatomic) IBOutlet UITextField *luxTF;
@property (weak, nonatomic) IBOutlet UILabel *minLabel;
@property (weak, nonatomic) IBOutlet UISlider *minSlider;
@property (weak, nonatomic) IBOutlet UILabel *maxLabel;
@property (weak, nonatomic) IBOutlet UISlider *maxSlider;
@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (nonatomic,strong) MBProgressHUD *hud;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;

@end

@implementation LightSensorSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = done;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
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
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundView = [[UIView alloc] init];
    _tableView.backgroundColor = [UIColor clearColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deleteStatus:)
                                                 name:kCSRDeviceManagerDeviceFoundForReset
                                               object:nil];
    if (@available(iOS 11.0, *)){
    }else {
        [_bgView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64];
    }
    
    if (self.lightSensor.remoteBranch.length > 13) {
        NSString *luxStr = [self.lightSensor.remoteBranch substringWithRange:NSMakeRange(10, 4)];
        NSInteger lux = [CSRUtilities numberWithHexString:luxStr];
        self.luxTF.text = [NSString stringWithFormat:@"%ld",lux];
        NSString *minStr = [self.lightSensor.remoteBranch substringWithRange:NSMakeRange(14, 2)];
        NSInteger min = [CSRUtilities numberWithHexString:minStr];
        self.minLabel.text = [NSString stringWithFormat:@"%.f%%",min/255.0*100];
        [self.minSlider setValue:min];
        NSString *maxStr = [self.lightSensor.remoteBranch substringWithRange:NSMakeRange(16, 2)];
        NSInteger max = [CSRUtilities numberWithHexString:maxStr];
        self.maxLabel.text = [NSString stringWithFormat:@"%.f%%",max/255.0*100];
        [self.maxSlider setValue:max];
        NSString *cntStr = [self.lightSensor.remoteBranch substringWithRange:NSMakeRange(4, 2)];
        NSInteger cnt = [CSRUtilities numberWithHexString:cntStr];
        [self.dataArray removeAllObjects];
        for (int i = 0; i<cnt; i++) {
            NSString *deviceIdStr = [self.lightSensor.remoteBranch substringWithRange:NSMakeRange(6+12*i, 4)];
            NSString *str1 = [deviceIdStr substringToIndex:2];
            NSString *str2 = [deviceIdStr substringFromIndex:2];
            NSNumber *deviceId = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[NSString stringWithFormat:@"%@%@",str2,str1]]];
            [self.dataArray addObject:deviceId];
        }
        [self.tableView reloadData];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settedLightSensorCall:) name:@"settedLightSensorCall" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"settedLightSensorCall" object:nil];
}

- (void)settedLightSensorCall:(NSNotification *)info {
    if (_hud) {
        [_hud hideAnimated:YES];
        _hud = nil;
        [self showTextHud:AcTECLocalizedStringFromTable(@"Success", @"Localizable")];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    NSNumber *deviceId = [self.dataArray objectAtIndex:indexPath.row];
    cell.tag = [deviceId integerValue];
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
    if (deviceEntity) {
        cell.textLabel.text = deviceEntity.name;
    }else {
        cell.textLabel.text = AcTECLocalizedStringFromTable(@"Notfound", @"Localizable");
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)selectDevices:(id)sender {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_ForLightSensor;
    list.originalMembers = [self.dataArray copy];
    [list getSelectedDevices:^(NSArray *devices) {
        [self.dataArray removeAllObjects];
        [self.dataArray addObjectsFromArray:devices];
        [self.tableView reloadData];
        if (devices != nil && [devices count] != 0) {
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)doneAction {
    
    if ([self.dataArray count] != 0 && self.dataArray != nil) {
        if (!_hud) {
            _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            _hud.mode = MBProgressHUDModeIndeterminate;
            _hud.delegate = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (_hud) {
                    [_hud removeFromSuperview];
                    _hud = nil;
                    [self showTextHud:AcTECLocalizedStringFromTable(@"TimeOut", @"Localizable")];
                }
            });
        }
        
        NSInteger cnt = [self.dataArray count];
        NSInteger num = 6*cnt+1;
        NSString *cmdHead = [NSString stringWithFormat:@"74%@%@",[CSRUtilities stringWithHexNumber:num],[CSRUtilities stringWithHexNumber:cnt]];
        
        NSString *targetLux = [self exchangePositionOfDeviceId:[_luxTF.text integerValue]];
        NSString *minLevel = [CSRUtilities stringWithHexNumber:_minSlider.value];
        NSString *maxLevel = [CSRUtilities stringWithHexNumber:_maxSlider.value];
        
        __block NSString *blockCmd = cmdHead;
        __weak LightSensorSettingViewController *weakSelf = self;
        [self.tableView.visibleCells enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *deviceIdStr = [weakSelf exchangePositionOfDeviceId:obj.tag];
            blockCmd = [NSString stringWithFormat:@"%@%@%@%@%@",blockCmd,deviceIdStr,targetLux,minLevel,maxLevel];
        }];
        
        self.lightSensor.remoteBranch = blockCmd;
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        [[DataModelApi sharedInstance] sendData:self.lightSensor.deviceId data:[CSRUtilities dataForHexString:blockCmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
            
        } failure:^(NSError * _Nonnull error) {
            
        }];
    }

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

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc] init];
    }
    return _dataArray;
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
    if ([textField isEqual:_luxTF]) {
        if ([self.dataArray count]>0) {
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
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

- (IBAction)minValue:(UISlider *)sender {
    if (sender.value>_maxSlider.value) {
        sender.value = _maxSlider.value-3;
    }
    self.minLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value/255.0*100];
}

- (IBAction)maxValue:(UISlider *)sender {
    if (sender.value<_minSlider.value) {
        sender.value = _minSlider.value + 3;
    }
    self.maxLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value/255.0*100];
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


@end
