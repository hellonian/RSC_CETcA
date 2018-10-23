//
//  DiscoverViewController.m
//  OTAU
//
/******************************************************************************
 *  Copyright (C) Cambridge Silicon Radio Limited 2014
 *
 *  This software is provided to the customer for evaluation
 *  purposes only and, as such early feedback on performance and operation
 *  is anticipated. The software source code is subject to change and
 *  not intended for production. Use of developmental release software is
 *  at the user's own risk. This software is provided "as is," and CSR
 *  cautions users to determine for themselves the suitability of using the
 *  beta release version of this software. CSR makes no warranty or
 *  representation whatsoever of merchantability or fitness of the product
 *  for any particular purpose or use. In no event shall CSR be liable for
 *  any consequential, incidental or special damages whatsoever arising out
 *  of the use of or inability to use this software, even if the user has
 *  advised CSR of the possibility of such damages.
 *
 ******************************************************************************/
//

#import "DiscoverViewController.h"
#import "CSRBluetoothLE.h"
#import "OTAU.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceEntity.h"
#import "UpdateDeviceModel.h"
#import "DataModelManager.h"
#import "AFHTTPSessionManager.h"
#import "UpdateViewController.h"


@interface DiscoverViewController ()<UITableViewDelegate,UITableViewDataSource,CSRBluetoothLEDelegate>

@property (strong, nonatomic) NSIndexPath *selectedCell;
@property (nonatomic,strong) NSMutableArray *devices;
@property (nonatomic,strong) NSArray *appDevices;
@property (nonatomic,strong) NSDictionary *latestDic;

@end

@implementation DiscoverViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange) name:ZZAppLanguageDidChangeNotification object:nil];
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"BTVersion", @"Localizable");
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Setting", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(backSetting) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
    }
    _devices = [[NSMutableArray alloc] init];
    
    _peripheralsList.delegate = self;
    _peripheralsList.dataSource = self;
    _peripheralsList.rowHeight = 60.0f;
    _peripheralsList.backgroundView = [[UIView alloc] init];
    _peripheralsList.backgroundColor = [UIColor clearColor];
    
    NSString *urlString = @"http://39.108.152.134/firware.php";
    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    sessionManager.responseSerializer.acceptableContentTypes = nil;
    [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        _latestDic = (NSDictionary *)responseObject;
        NSLog(@"%@",_latestDic);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%@",error);
    }];
    

}

- (void)backSetting{
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getFirmwareVersion:) name:@"getFirmwareVersion" object:nil];
    [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
    [[CSRBluetoothLE sharedInstance] setIsUpdateFW:YES];
    [[CSRBluetoothLE sharedInstance] startScan];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[CSRBluetoothLE sharedInstance] setBleDelegate:nil];
    [_devices removeAllObjects];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"getFirmwareVersion" object:nil];
}

/****************************************************************************/
/*							TableView Delegates								*/
/****************************************************************************/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_devices count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    UpdateDeviceModel *upModel = [_devices objectAtIndex:indexPath.row];
    cell.textLabel.text = upModel.name;
    if (!upModel.needUpdate) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@   Version:%ld   Lastest",upModel.kind,(long)upModel.firwareVersion];
        
        cell.detailTextLabel.textColor = [UIColor darkTextColor];
    }else{
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@   Version:%ld   Need update",upModel.kind,(long)upModel.firwareVersion];
        
        cell.detailTextLabel.textColor = DARKORAGE;
    }
    
	return cell;
}



- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UpdateDeviceModel *model = [_devices objectAtIndex:indexPath.row];
    
    if (model.needUpdate) {
        NSArray *connectedPeripherals = [[CSRBluetoothLE sharedInstance] connectedPeripherals];
        for (CBPeripheral *connectedPeripheral  in connectedPeripherals) {
            if ([connectedPeripheral state] == CBPeripheralStateConnected) {
                [[CSRBluetoothLE sharedInstance] disconnectPeripheral:connectedPeripheral];
                break;
            }
        }
    
    
        if ([model.peripheral state] != CBPeripheralStateConnected) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[CSRBluetoothLE sharedInstance] connectPeripheralNoCheck:model.peripheral];
            });
        }
        else if ([self isOTAUPeripheral:model.peripheral]){
            UpdateViewController *uvc = [[UpdateViewController alloc] init];
            uvc.targetModel = model;
            [self.navigationController pushViewController:uvc animated:YES];
        }
    
    }
}


-(BOOL) isOTAUPeripheral:(CBPeripheral *) peripheral {
    NSLog(@"Is this OTAU peripheral: %@",peripheral.name);
    CBUUID *uuid = [CBUUID UUIDWithString:serviceApplicationOtauUuid];
    for (CBService *service in peripheral.services) {
        NSLog(@" -Service = %@",service.UUID);
        if ([service.UUID isEqual:uuid]){
            return (YES);
        }
    }
    return (NO);
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



/****************************************************************************/
/*                       BleDiscoveryDelegate Methods                       */
/****************************************************************************/
- (void) discoveryDidRefresh
{
    _appDevices = [[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects];
    
    NSArray *foundPeripherals = [[CSRBluetoothLE sharedInstance] foundPeripherals];
    for (CBPeripheral *peripheral in foundPeripherals) {
        
        [self checkData:peripheral];
        
    }
    
    NSArray *connectedPeripherals = [[CSRBluetoothLE sharedInstance] connectedPeripherals];
    for (CBPeripheral *peripheral in connectedPeripherals) {
        
        [self checkData:peripheral];
        
    }
    [_peripheralsList reloadData];
}

- (void) checkData: (CBPeripheral *)peripheral {
    
    [_appDevices enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *adUuidString = [peripheral.uuidString substringToIndex:12];
        NSString *deviceUuidString = [deviceEntity.uuid substringFromIndex:24];
        if ([adUuidString isEqualToString:deviceUuidString]) {
            BOOL exist = NO;
            for (UpdateDeviceModel *model in _devices) {
                if ([model.uuidStr isEqualToString:adUuidString]) {
                    exist = YES;
                    break;
                }
            }
            if (!exist) {
                UpdateDeviceModel *upModel = [[UpdateDeviceModel alloc] init];
                upModel.peripheral = peripheral;
                upModel.uuidStr = deviceUuidString;
                upModel.name = deviceEntity.name;
                upModel.kind = deviceEntity.shortName;
                upModel.deviceId = deviceEntity.deviceId;
                [[DataModelManager shareInstance] sendCmdData:@"880100" toDeviceId:deviceEntity.deviceId];
                [_devices addObject:upModel];
            }
            *stop = YES;
        }
    }];
}

- (void) getFirmwareVersion:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    NSInteger firmwareVersion = [dic[@"getFirmwareVersion"] integerValue];
    NSArray *allKeyArray = [_latestDic allKeys];
    [_devices enumerateObjectsUsingBlock:^(UpdateDeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([deviceId isEqualToNumber:model.deviceId]) {
            model.firwareVersion = firmwareVersion;
            if ([allKeyArray containsObject:model.kind]) {
                NSInteger latestV = [[_latestDic objectForKey:model.kind] integerValue];
                if (firmwareVersion < latestV) {
                    model.needUpdate = YES;
                }else {
                    model.needUpdate = NO;
                }
            }
            
            *stop = YES;
        }
    }];
    [_peripheralsList reloadData];
}


//============================================================================
- (void) discoveryStatePoweredOff
{
    NSString *title     = @"Bluetooth Power";
    NSString *message   = @"You must turn on Bluetooth in Settings in order to use LE";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController.view setTintColor:DARKORAGE];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

//============================================================================
// callback: is this an otau capable peripheral
-(void) otauPeripheralTest:(CBPeripheral *) peripheral :(BOOL) isOtau {
    if (isOtau) {
        NSString *adUuidString = [peripheral.uuidString substringToIndex:12];
        [_devices enumerateObjectsUsingBlock:^(UpdateDeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([model.uuidStr isEqualToString:adUuidString]) {
                UpdateViewController *uvc = [[UpdateViewController alloc] init];
                uvc.targetModel = model;
                [self.navigationController pushViewController:uvc animated:YES];
                *stop = YES;
            }
        }];
        
        [[CSRBluetoothLE sharedInstance] stopScan];
    }
    else {
        [[CSRBluetoothLE sharedInstance] disconnectPeripheral:peripheral];
    }
}


//============================================================================
// The central is successfuly powered on
-(void) centralPoweredOn
{
    [[CSRBluetoothLE sharedInstance] retrieveCachedPeripherals];
}

- (void)languageChange {
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"BTVersion", @"Localizable");
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Setting", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(backSetting) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
    }
}


@end
