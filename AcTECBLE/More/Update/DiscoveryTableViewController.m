//
//  DiscoveryTableViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2019/3/15.
//  Copyright © 2019 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "DiscoveryTableViewController.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceEntity.h"
#import "AFHTTPSessionManager.h"
#import "UpdateDeviceModel.h"
#import "OTAU.h"
#import "CSRDatabaseManager.h"
#import "CustomizeProgressHud.h"
#import "PureLayout.h"
#import "CSRUtilities.h"

#import "CSRGaia.h"
#import "CSRGaiaManager.h"
#import "DataModelManager.h"

#import "UpdataMCUTool.h"

@interface DiscoveryTableViewController ()<CSRBluetoothLEDelegate,OTAUDelegate,CSRUpdateManagerDelegate,UITableViewDelegate, UITableViewDataSource,UpdataMCUToolDelegate>
{
    NSInteger retrycout;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic,strong)NSMutableArray *dataArray;
@property (nonatomic,strong)NSMutableArray *uuids;
@property (nonatomic,strong)NSArray *appAllDevcies;
@property (nonatomic,strong) NSDictionary *latestDic;
@property (nonatomic,strong) CustomizeProgressHud *customizeHud;
@property (nonatomic,strong) UIView *translucentBgView;

@property (nonatomic,assign) BOOL isDataEndPointAvailabile;
@property (nonatomic,strong) NSString *sourceFilePath;

@property (nonatomic, strong) UILabel *noneLabel;

@property (nonatomic, strong) UIAlertController *mcuAlert;
@property (nonatomic,strong) UpdateDeviceModel *targetModel;
@property (nonatomic, assign) BOOL otauConnectedCase;

@end

@implementation DiscoveryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(-35, 0, 0, 0);
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange) name:ZZAppLanguageDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(afterGetVersion:) name:@"reGetDataForPlaceChanged" object:nil];
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
    if ([[OTAU shareInstance] parseCsKeyJson:@"cskey_db"]) {
        NSLog(@"Success: Load CS key JSON");
    }else {
        NSLog(@"Fail: Load CS key JSON");
    }
    [[OTAU shareInstance] setOtauDelegate:self];
    _dataArray = [[NSMutableArray alloc] init];
    _uuids = [[NSMutableArray alloc] init];
    _appAllDevcies = [[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects];
    
    self.view.backgroundColor = ColorWithAlpha(220, 220, 220, 1);
    
    _noneLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _noneLabel.text = AcTECLocalizedStringFromTable(@"update_view_none_alert", @"Localizable");
    _noneLabel.font = [UIFont systemFontOfSize:14];
    _noneLabel.textColor = ColorWithAlpha(77, 77, 77, 1);
    _noneLabel.textAlignment = NSTextAlignmentCenter;
    _noneLabel.numberOfLines = 0;
    [self.view addSubview:_noneLabel];
    [_noneLabel autoCenterInSuperview];
    [_noneLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [_noneLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:50];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundView = [[UIView alloc] init];
    _tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_tableView];
    [_tableView autoPinEdgesToSuperviewEdges];
    
    NSString *urlString = @"http://39.108.152.134/ble_mcu_info.php";
    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    sessionManager.responseSerializer.acceptableContentTypes = nil;
    sessionManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        _latestDic = nil;
        _latestDic = (NSDictionary *)responseObject;
        
        NSArray *connectedPeripherals = [[CSRBluetoothLE sharedInstance] connectedPeripherals];
        for (CBPeripheral *peripheral in connectedPeripherals) {
            if ([peripheral.uuidString length] == 14) {
                [_appAllDevcies enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([deviceEntity.uuid length] == 36) {
                        NSString *adUuidString = [peripheral.uuidString substringToIndex:12];
                        NSString *deviceUuidString = [deviceEntity.uuid substringFromIndex:24];
                        if ([adUuidString isEqualToString:deviceUuidString]) {
                            NSInteger devhversion = [[[_latestDic objectForKey:deviceEntity.shortName] objectForKey:@"device_hardware_version"] integerValue];
                            NSInteger devfversion = [[[_latestDic objectForKey:deviceEntity.shortName] objectForKey:@"device_software_version"] integerValue];
                            NSInteger mcuhversion = [[[_latestDic objectForKey:deviceEntity.shortName] objectForKey:@"mcu_hardware_version"] integerValue];
                            NSInteger mcufversion = [[[_latestDic objectForKey:deviceEntity.shortName] objectForKey:@"mcu_software_version"] integerValue];
                            NSInteger un = 0;
                            if ([deviceEntity.hwVersion integerValue] == devhversion) {
                                if ([deviceEntity.firVersion integerValue] < devfversion) {
                                    if ([deviceEntity.mcuHVersion integerValue] == mcuhversion) {
                                        if ([deviceEntity.mcuSVersion integerValue] < mcufversion) {
                                            if ([deviceEntity.bleHwVersion integerValue] >= 16 && [deviceEntity.bleHwVersion integerValue] < 32) {
                                                un = 4;
                                            }else if ([deviceEntity.bleHwVersion integerValue] >= 32 && [deviceEntity.bleHwVersion integerValue] < 48) {
                                                un = 5;
                                            }
                                        }else {
                                            if ([deviceEntity.bleHwVersion integerValue] >= 16 && [deviceEntity.bleHwVersion integerValue] < 32) {
                                                un = 1;
                                            }else if ([deviceEntity.bleHwVersion integerValue] >= 32 && [deviceEntity.bleHwVersion integerValue] < 48) {
                                                un = 2;
                                            }
                                        }
                                    }else {
                                        if ([deviceEntity.bleHwVersion integerValue] >= 16 && [deviceEntity.bleHwVersion integerValue] < 32) {
                                            un = 1;
                                        }else if ([deviceEntity.bleHwVersion integerValue] >= 32 && [deviceEntity.bleHwVersion integerValue] < 48) {
                                            un = 2;
                                        }
                                    }
                                }else {
                                    if ([deviceEntity.mcuHVersion integerValue] == mcuhversion) {
                                        if ([deviceEntity.mcuSVersion integerValue] < mcufversion) {
                                            un = 3;
                                        }
                                    }
                                }
                            }else {
                                if ([deviceEntity.mcuHVersion integerValue] == mcuhversion) {
                                    if ([deviceEntity.mcuSVersion integerValue] < mcufversion) {
                                        un = 3;
                                    }
                                }
                            }
                            if (un != 0) {
                                UpdateDeviceModel *model = [[UpdateDeviceModel alloc] init];
                                model.peripheral = peripheral;
                                model.name = deviceEntity.name;
                                model.connected = YES;
                                model.kind = deviceEntity.shortName;
                                model.deviceId = deviceEntity.deviceId;
                                model.bleHwVersion = deviceEntity.bleHwVersion;
                                model.bleFVersion = deviceEntity.bleFirVersion;
                                model.fVersion = deviceEntity.firVersion;
                                model.hVersion = deviceEntity.hwVersion;
                                model.hmcuVersion = deviceEntity.mcuHVersion;
                                model.fmcuVersion = deviceEntity.mcuSVersion;
                                model.updateNumber = un;
                                [_dataArray addObject:model];
                                _noneLabel.hidden = YES;
                                [self.tableView reloadData];
                            }
                            *stop = YES;
                        }
                    }
                }];
            }
        }
        
        [[CSRBluetoothLE sharedInstance] setIsUpdateFW:YES];
        [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
        [[CSRBluetoothLE sharedInstance] startScan];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%@",error);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"check_network", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }];
    
    self.isDataEndPointAvailabile = NO;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor grayColor];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Scanning for devices"];
    [refreshControl addTarget:self action:@selector(refreshDevices:) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
}

- (void)refreshDevices:(id)sender {
    [self.dataArray removeAllObjects];
    [self.uuids removeAllObjects];
    [[[CSRBluetoothLE sharedInstance] foundPeripherals] removeAllObjects];
    NSArray *connectedPeripherals = [[CSRBluetoothLE sharedInstance] connectedPeripherals];
    for (CBPeripheral *peripheral in connectedPeripherals) {
        if ([peripheral.uuidString length] == 14) {
            [_appAllDevcies enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([deviceEntity.uuid length] == 36) {
                    NSString *adUuidString = [peripheral.uuidString substringToIndex:12];
                    NSString *deviceUuidString = [deviceEntity.uuid substringFromIndex:24];
                    if ([adUuidString isEqualToString:deviceUuidString]) {
                        NSInteger devhversion = [[[_latestDic objectForKey:deviceEntity.shortName] objectForKey:@"device_hardware_version"] integerValue];
                        NSInteger devfversion = [[[_latestDic objectForKey:deviceEntity.shortName] objectForKey:@"device_software_version"] integerValue];
                        NSInteger mcuhversion = [[[_latestDic objectForKey:deviceEntity.shortName] objectForKey:@"mcu_hardware_version"] integerValue];
                        NSInteger mcufversion = [[[_latestDic objectForKey:deviceEntity.shortName] objectForKey:@"mcu_software_version"] integerValue];
                        NSInteger un = 0;
                        if ([deviceEntity.hwVersion integerValue] == devhversion) {
                            if ([deviceEntity.firVersion integerValue] < devfversion) {
                                if ([deviceEntity.mcuHVersion integerValue] == mcuhversion) {
                                    if ([deviceEntity.mcuSVersion integerValue] < mcufversion) {
                                        if ([deviceEntity.bleHwVersion integerValue] >= 16 && [deviceEntity.bleHwVersion integerValue] < 32) {
                                            un = 4;
                                        }else if ([deviceEntity.bleHwVersion integerValue] >= 32 && [deviceEntity.bleHwVersion integerValue] < 48) {
                                            un = 5;
                                        }
                                    }else {
                                        if ([deviceEntity.bleHwVersion integerValue] >= 16 && [deviceEntity.bleHwVersion integerValue] < 32) {
                                            un = 1;
                                        }else if ([deviceEntity.bleHwVersion integerValue] >= 32 && [deviceEntity.bleHwVersion integerValue] < 48) {
                                            un = 2;
                                        }
                                    }
                                }else {
                                    if ([deviceEntity.bleHwVersion integerValue] >= 16 && [deviceEntity.bleHwVersion integerValue] < 32) {
                                        un = 1;
                                    }else if ([deviceEntity.bleHwVersion integerValue] >= 32 && [deviceEntity.bleHwVersion integerValue] < 48) {
                                        un = 2;
                                    }
                                }
                            }else {
                                if ([deviceEntity.mcuHVersion integerValue] == mcuhversion) {
                                    if ([deviceEntity.mcuSVersion integerValue] < mcufversion) {
                                        un = 3;
                                    }
                                }
                            }
                        }else {
                            if ([deviceEntity.mcuHVersion integerValue] == mcuhversion) {
                                if ([deviceEntity.mcuSVersion integerValue] < mcufversion) {
                                    un = 3;
                                }
                            }
                        }
                        if (un != 0) {
                            UpdateDeviceModel *model = [[UpdateDeviceModel alloc] init];
                            model.peripheral = peripheral;
                            model.name = deviceEntity.name;
                            model.connected = YES;
                            model.kind = deviceEntity.shortName;
                            model.deviceId = deviceEntity.deviceId;
                            model.bleHwVersion = deviceEntity.bleHwVersion;
                            model.bleFVersion = deviceEntity.bleFirVersion;
                            model.fVersion = deviceEntity.firVersion;
                            model.hVersion = deviceEntity.hwVersion;
                            model.hmcuVersion = deviceEntity.mcuHVersion;
                            model.fmcuVersion = deviceEntity.mcuSVersion;
                            model.updateNumber = un;
                            [_dataArray addObject:model];
                            _noneLabel.hidden = YES;
                            [self.tableView reloadData];
                        }
                        *stop = YES;
                    }
                }
            }];
        }
    }
    [self.tableView.refreshControl endRefreshing];
    if ([_dataArray count] > 0) {
        _noneLabel.hidden = YES;
    }else {
        _noneLabel.hidden = NO;
    }
    [self.tableView reloadData];
    [[CSRBluetoothLE sharedInstance] stopScan];
    [[CSRBluetoothLE sharedInstance] startScan];
    
}

- (void)backSetting{
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (![[CSRBluetoothLE sharedInstance] isUpdateFW]) {
        [[CSRBluetoothLE sharedInstance] setIsUpdateFW:YES];
    }
    if (![[CSRBluetoothLE sharedInstance] bleDelegate]) {
        [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[CSRBluetoothLE sharedInstance] stopScan];
    [[CSRBluetoothLE sharedInstance] setBleDelegate:nil];
    [[CSRBluetoothLE sharedInstance] setIsUpdateFW:NO];
    [[CSRBluetoothLE sharedInstance] setIsForGAIA:NO];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dicoveryListCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"dicoveryListCell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.numberOfLines = 0;
    }
    UpdateDeviceModel *model = [self.dataArray objectAtIndex:indexPath.row];
    cell.textLabel.text = model.name;
    if (model.updateNumber == 1 || model.updateNumber == 2) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"ble: %@", model.fVersion];
    }else if (model.updateNumber == 3) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"mcu: %@", model.fmcuVersion];
    }else if (model.updateNumber == 4 || model.updateNumber == 5) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"ble: %@\nmcu: %@", model.fVersion, model.fmcuVersion];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UpdateDeviceModel *model = [self.dataArray objectAtIndex:indexPath.row];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"upgrade_ble_firmware", @"Localizable")];
    [attributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedTitle string] length])];
    [alert setValue:attributedTitle forKey:@"attributedTitle"];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [cancel setValue:DARKORAGE forKey:@"titleTextColor"];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        _customizeHud = [[CustomizeProgressHud alloc] initWithFrame:CGRectZero];
        dispatch_async(dispatch_get_main_queue(), ^{
            _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
            _translucentBgView.backgroundColor = [UIColor blackColor];
            _translucentBgView.alpha = 0.4;
            [[UIApplication sharedApplication].keyWindow addSubview:_translucentBgView];
            
            [[UIApplication sharedApplication].keyWindow addSubview:_customizeHud];
            [_customizeHud autoCenterInSuperview];
            [_customizeHud autoSetDimensionsToSize:CGSizeMake(270, 130)];
            _customizeHud.text = @"Updating...";
            [_customizeHud updateProgress:0];
        });
        self.targetModel = model;
        if (model.updateNumber == 1 || model.updateNumber == 4 || model.updateNumber == 2 || model.updateNumber == 5) {
            [self downloadfirware:[[_latestDic objectForKey:model.kind] objectForKey:@"ble_download_address"] :model];
        }else if (model.updateNumber == 3) {
            if (model.connected) {
                [self askUpdateMCU];
            }else {
                [self disconnectForMCUUpdate];
            }
        }
    }];
    [confirm setValue:DARKORAGE forKey:@"titleTextColor"];
    [alert addAction:cancel];
    [alert addAction:confirm];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)downloadfirware:(NSString *)urlString :(UpdateDeviceModel *)model {
    NSLog(@"downloadfirware");
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    NSString *fileName = [urlString lastPathComponent];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    NSProgress *progress = nil;
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:&progress destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@",fileName]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path]) {
            [fileManager removeItemAtPath:path error:nil];
        }
        NSLog(@"downloadTaskWithRequest: %@",path);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_targetModel.updateNumber == 4 || _targetModel.updateNumber == 5) {
                [_customizeHud updateProgress:0.1*0.5];
            }else {
                [_customizeHud updateProgress:0.1];
            }
        });
        
        if (model.updateNumber == 1 || model.updateNumber == 4) {
            [[CSRBluetoothLE sharedInstance] setIsForGAIA:NO];
            [[OTAU shareInstance] setSourceFilePath:path];
            if (model.connected) {
                _otauConnectedCase = YES;
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(BridgeConnectedNotification:)
                                                             name:@"BridgeConnectedNotification"
                                                           object:nil];
                [[CSRBluetoothLE sharedInstance] disconnectPeripheralForOTAUConnectedcase:[model.peripheral.uuidString substringToIndex:12]];
            }else {
                [[CSRBluetoothLE sharedInstance] setSecondConnectBool:NO];
                [[CSRBluetoothLE sharedInstance] connectPeripheralNoCheck:model.peripheral];
            }
        }else if (model.updateNumber == 2 || model.updateNumber == 5) {
            self.sourceFilePath = path;
            [[CSRBluetoothLE sharedInstance] setIsForGAIA:YES];
            self.isDataEndPointAvailabile = false;
            [CSRGaiaManager sharedInstance].delegate = self;
            
            if (model.connected) {
                CBUUID *uuid = [CBUUID UUIDWithString:UUID_GAIA_SERVICE];
                for (CBService *service in model.peripheral.services) {
                    if ([service.UUID isEqual:uuid]) {
                        [[CSRBluetoothLE sharedInstance] setTargetPeripheral:model.peripheral];
                        [[CSRGaia sharedInstance] connectPeripheral:[[CSRBluetoothLE sharedInstance] targetPeripheral]];
                        [[CSRGaiaManager sharedInstance] connect];
                        [[CSRGaiaManager sharedInstance] setDataEndPointMode:true];
                        break;
                    }
                }
            }else {
                [[CSRBluetoothLE sharedInstance] connectPeripheralNoCheck:model.peripheral];
            }
        }
        
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"unable_get_firmware", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
            [alert.view setTintColor:DARKORAGE];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:cancel];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
    [task resume];
    
    [progress addObserver:self forKeyPath:@"completedUnitCount" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([object isKindOfClass:[NSProgress class]]) {
        __block NSProgress *progress = object;
        NSLog(@"已完成大小:%lld  总大小:%lld", progress.completedUnitCount, progress.totalUnitCount);
        NSLog(@"进度:%0.2f%%", progress.fractionCompleted * 100);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_targetModel.updateNumber == 4 || _targetModel.updateNumber == 5) {
                [_customizeHud updateProgress:progress.fractionCompleted * 0.1 * 0.5];
            }else {
                [_customizeHud updateProgress:progress.fractionCompleted * 0.1];
            }
        });
    }
}

- (void)discoveredPripheralDetails {
    CBUUID *uuid = [CBUUID UUIDWithString:UUID_GAIA_SERVICE];
    for (CBService *service in [[CSRBluetoothLE sharedInstance] targetPeripheral].services) {
        if ([service.UUID isEqual:uuid]) {
            [[CSRGaia sharedInstance] connectPeripheral:[[CSRBluetoothLE sharedInstance] targetPeripheral]];
            [[CSRGaiaManager sharedInstance] connect];
            [[CSRGaiaManager sharedInstance] setDataEndPointMode:true];
            break;
        }
    }
}

- (void)discoveryDidRefresh:(CBPeripheral *)peripheral {
    if ([peripheral.uuidString length] == 14) {
        if (![_uuids containsObject:peripheral.uuidString]) {
            for (CSRDeviceEntity *deviceEntity in _appAllDevcies) {
                if ([deviceEntity.uuid length] == 36) {
                    NSString *adUuidString = [peripheral.uuidString substringToIndex:12];
                    NSString *deviceUuidString = [deviceEntity.uuid substringFromIndex:24];
                    if ([adUuidString isEqualToString:deviceUuidString]) {
                        [_uuids addObject:peripheral.uuidString];
                        NSInteger devhversion = [[[_latestDic objectForKey:deviceEntity.shortName] objectForKey:@"device_hardware_version"] integerValue];
                        NSInteger devfversion = [[[_latestDic objectForKey:deviceEntity.shortName] objectForKey:@"device_software_version"] integerValue];
                        NSInteger mcuhversion = [[[_latestDic objectForKey:deviceEntity.shortName] objectForKey:@"mcu_hardware_version"] integerValue];
                        NSInteger mcufversion = [[[_latestDic objectForKey:deviceEntity.shortName] objectForKey:@"mcu_software_version"] integerValue];
                        NSInteger un = 0;
                        if ([deviceEntity.hwVersion integerValue] == devhversion) {
                            if ([deviceEntity.firVersion integerValue] < devfversion) {
                                if ([deviceEntity.mcuHVersion integerValue] == mcuhversion) {
                                    if ([deviceEntity.mcuSVersion integerValue] < mcufversion) {
                                        if ([deviceEntity.bleHwVersion integerValue] >= 16 && [deviceEntity.bleHwVersion integerValue] < 32) {
                                            un = 4;
                                        }else if ([deviceEntity.bleHwVersion integerValue] >= 32 && [deviceEntity.bleHwVersion integerValue] < 48) {
                                            un = 5;
                                        }
                                    }else {
                                        if ([deviceEntity.bleHwVersion integerValue] >= 16 && [deviceEntity.bleHwVersion integerValue] < 32) {
                                            un = 1;
                                        }else if ([deviceEntity.bleHwVersion integerValue] >= 32 && [deviceEntity.bleHwVersion integerValue] < 48) {
                                            un = 2;
                                        }
                                    }
                                }else {
                                    if ([deviceEntity.bleHwVersion integerValue] >= 16 && [deviceEntity.bleHwVersion integerValue] < 32) {
                                        un = 1;
                                    }else if ([deviceEntity.bleHwVersion integerValue] >= 32 && [deviceEntity.bleHwVersion integerValue] < 48) {
                                        un = 2;
                                    }
                                }
                            }else {
                                if ([deviceEntity.mcuHVersion integerValue] == mcuhversion) {
                                    if ([deviceEntity.mcuSVersion integerValue] < mcufversion) {
                                        un = 3;
                                    }
                                }
                            }
                        }else {
                            if ([deviceEntity.mcuHVersion integerValue] == mcuhversion) {
                                if ([deviceEntity.mcuSVersion integerValue] < mcufversion) {
                                    un = 3;
                                }
                            }
                        }
                        if (un != 0) {
                            UpdateDeviceModel *model = [[UpdateDeviceModel alloc] init];
                            model.peripheral = peripheral;
                            model.name = deviceEntity.name;
                            model.connected = NO;
                            model.kind = deviceEntity.shortName;
                            model.deviceId = deviceEntity.deviceId;
                            model.bleHwVersion = deviceEntity.bleHwVersion;
                            model.bleFVersion = deviceEntity.bleFirVersion;
                            model.fVersion = deviceEntity.firVersion;
                            model.hVersion = deviceEntity.hwVersion;
                            model.hmcuVersion = deviceEntity.mcuHVersion;
                            model.fmcuVersion = deviceEntity.mcuSVersion;
                            model.updateNumber = un;
                            [_dataArray addObject:model];
                            _noneLabel.hidden = YES;
                            [self.tableView reloadData];
                        }
                        break;
                    }
                }
            }
        }
    }
}

- (void)regetVersion:(NSString *)uuidstring {
    retrycout = 0;
    [self performSelector:@selector(getVersionDelayMethod) withObject:nil afterDelay:2.0];
    Byte byte[] = {0x88, 0x01, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:self.targetModel.deviceId data:cmd];
}

- (void)updateProgressDelegteMethod:(CGFloat)percentage {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_targetModel.updateNumber == 4 || _targetModel.updateNumber == 5) {
            [_customizeHud updateProgress:percentage*0.5];
        }else {
            [_customizeHud updateProgress:percentage];
        }
    });
}

- (void)didReceiveGaiaGattResponse:(CSRGaiaGattCommand *)command {
    GaiaCommandType cmdType = [command getCommandId];
    NSData *requestPayload = [command getPayload];
    uint8_t success = 0;
    
    [requestPayload getBytes:&success range:NSMakeRange(0, sizeof(uint8_t))];
    
    if (cmdType == GaiaCommand_SetDataEndPointMode && requestPayload.length > 0) {
        uint8_t value = 0;
        
        [requestPayload getBytes:&value range:NSMakeRange(0, sizeof(uint8_t))];
        
        if (value == GaiaStatus_Success) {
            self.isDataEndPointAvailabile = true;
        } else {
            self.isDataEndPointAvailabile = false;
        }
        
        [[CSRGaiaManager sharedInstance] start:self.sourceFilePath useDataEndpoint:self.isDataEndPointAvailabile];
        
    }
}

- (void)confirmRequired {
    
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Finalise Update"
                                message:@"Would you like to complete the upgrade?"
                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   [[CSRGaiaManager sharedInstance] commitConfirm:YES];
                               }];
    UIAlertAction *cancelActionButton = [UIAlertAction
                                         actionWithTitle:@"Cancel"
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * action) {
                                             [[CSRGaiaManager sharedInstance] commitConfirm:NO];
                                         }];
    
    [alert addAction:okButton];
    [alert addAction:cancelActionButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmForceUpgrade {
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Synchronisation Failed"
                                message:@"Another update has already been started. Would you like to force the upgrade?"
                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   [[CSRGaiaManager sharedInstance] abortAndRestart];
                               }];
    UIAlertAction *cancelActionButton = [UIAlertAction
                                         actionWithTitle:@"Cancel"
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * action) {
                                             [self tidyUp];
                                         }];
    
    [alert addAction:okButton];
    [alert addAction:cancelActionButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)okayRequired {
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"SQIF Erase"
                                message:@"About to erase SQIF partition"
                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   [[CSRGaiaManager sharedInstance] eraseSqifConfirm];
                               }];
    
    [alert addAction:okButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)didAbortWithError:(NSError *)error {
    NSString *errorMessage = [error.userInfo objectForKey:CSRGaiaErrorParam];
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:error.code <= 128 ? @"Update failed" : @"Warning"
                                message:errorMessage
                                preferredStyle:UIAlertControllerStyleAlert];
    
    if (error.code <= 128) {
        
        [[CSRGaiaManager sharedInstance] confirmError];
        
    }
    
    UIAlertAction *okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   if (error.code <= 128) {
                                       [self tidyUp];
                                   }
                               }];
    
    [alert addAction:okButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)didMakeProgress:(double)value eta:(NSString *)eta {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_targetModel.updateNumber == 4 || _targetModel.updateNumber == 5) {
            [_customizeHud updateProgress:value*0.5];
        }else {
            [_customizeHud updateProgress:value];
        }
    });
}

- (void)didCompleteUpgrade {
    
    NSString *message = [NSString stringWithFormat:@"Update with: %@", self.sourceFilePath];
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Update successful"
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   [self tidyUp];
                               }];
    
    [alert addAction:okButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)didAbortUpgrade {
    NSString *message = [NSString stringWithFormat:@"Update with: %@", self.sourceFilePath];
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Update aborted"
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   [self abortTidyUp];
                               }];
    
    [alert addAction:okButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmTransferRequired {
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"File transfer complete"
                                message:@"Would you like to proceed?"
                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   [[CSRGaiaManager sharedInstance] updateTransferComplete];
                               }];
    UIAlertAction *cancelActionButton = [UIAlertAction
                                         actionWithTitle:@"Cancel"
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * action) {
                                             [self tidyUp];
                                         }];
    
    [alert addAction:okButton];
    [alert addAction:cancelActionButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmBatteryOkay {
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Battery Low"
                                message:@"The battery is low on your audio device. Please connect it to a charger"
                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   [[CSRGaiaManager sharedInstance] syncRequest];
                               }];
    
    [alert addAction:okButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)tidyUp {
    [[CSRGaiaManager sharedInstance] disconnect];
    [CSRGaiaManager sharedInstance].delegate = nil;
    [CSRGaiaManager sharedInstance].updateInProgress = NO;
    [[CSRBluetoothLE sharedInstance] setIsForGAIA:NO];
    
    if (_targetModel.connected) {
        CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_targetModel.deviceId];
        [[CSRBluetoothLE sharedInstance] setMacformcuupdateConnection:[de.uuid substringFromIndex:24]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            retrycout = 0;
            [self performSelector:@selector(getVersionDelayMethod) withObject:nil afterDelay:2.0];
            Byte byte[] = {0x88, 0x01, 0x00};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:self.targetModel.deviceId data:cmd];
        });
    }else {
        retrycout = 0;
        [self performSelector:@selector(getVersionDelayMethod) withObject:nil afterDelay:2.0];
        Byte byte[] = {0x88, 0x01, 0x00};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:self.targetModel.deviceId data:cmd];
    }
}

- (void)abortTidyUp {
    
    [CSRGaiaManager sharedInstance].updateInProgress = NO;
}

- (void)didUpdateStatus:(NSString *)value {
    NSLog(@"didUpdateStatus 》》 %@",value);
}

- (void)didWarmBoot {
    NSLog(@"didWarmBoot");
}

- (void)getVersionDelayMethod {
    if (retrycout < 3) {
        retrycout ++;
        [self performSelector:@selector(getVersionDelayMethod) withObject:nil afterDelay:2.0];
        Byte byte[] = {0x88, 0x01, 0x00};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:self.targetModel.deviceId data:cmd];
    }else {
        [_customizeHud removeFromSuperview];
        _customizeHud = nil;
        [_translucentBgView removeFromSuperview];
        _translucentBgView = nil;
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}

- (void)afterGetVersion:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *uDeviceID = userInfo[@"deviceId"];
    if (self.targetModel) {
        if ([uDeviceID isEqualToNumber:self.targetModel.deviceId]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getVersionDelayMethod) object:nil];
            
            if (self.targetModel.updateNumber == 4 || self.targetModel.updateNumber == 5) {
                if (self.targetModel.connected) {
                    [self askUpdateMCU];
                }else {
                    [self disconnectForMCUUpdate];
                }
            }else {
                [_dataArray removeObject:self.targetModel];
                if ([_dataArray count] == 0) {
                    _noneLabel.hidden = NO;
                }
                [self.tableView reloadData];
                [_customizeHud removeFromSuperview];
                _customizeHud = nil;
                [_translucentBgView removeFromSuperview];
                _translucentBgView = nil;
                [UIApplication sharedApplication].idleTimerDisabled = NO;
            }
        }
    }
}

- (void)disconnectForMCUUpdate {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(BridgeConnectedNotification:)
                                                 name:@"BridgeConnectedNotification"
                                               object:nil];
    CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_targetModel.deviceId];
    [[CSRBluetoothLE sharedInstance] disconnectPeripheralForMCUUpdate:[de.uuid substringFromIndex:24]];
    [self performSelector:@selector(connectForMCUUpdateDelayMethod) withObject:nil afterDelay:10.0];
}

- (void)connectForMCUUpdateDelayMethod {
    _mcuAlert = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"mcu_connetion_alert", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
    [_mcuAlert.view setTintColor:DARKORAGE];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [[CSRBluetoothLE sharedInstance] cancelMCUUpdate];
        [_customizeHud removeFromSuperview];
        _customizeHud = nil;
        [_translucentBgView removeFromSuperview];
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
    if ([peripheral.uuidString length] == 14) {
        if (_otauConnectedCase) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BridgeConnectedNotification" object:nil];
            [[CSRBluetoothLE sharedInstance] cancelDisconnectPeripheralForOTAUConnectedcase];
            [[CSRBluetoothLE sharedInstance] setSecondConnectBool:NO];
            [[CSRBluetoothLE sharedInstance] connectPeripheralNoCheck:_targetModel.peripheral];
        }else {
            CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_targetModel.deviceId];
            if ([de.uuid length] == 36) {
                NSString *adUuidString = [peripheral.uuidString substringToIndex:12];
                NSString *deviceUuidString = [de.uuid substringFromIndex:24];
                if ([adUuidString isEqualToString:deviceUuidString]) {
                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectForMCUUpdateDelayMethod) object:nil];
                    if (_mcuAlert) {
                        [_mcuAlert dismissViewControllerAnimated:YES completion:nil];
                        _mcuAlert = nil;
                    }
                    [self askUpdateMCU];
                }
            }
        }
    }
}

- (void)askUpdateMCU {
    [UpdataMCUTool sharedInstace].toolDelegate = self;
    CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_targetModel.deviceId];
    [[UpdataMCUTool sharedInstace] askUpdateMCU:_targetModel.deviceId downloadAddress:[[_latestDic objectForKey:de.shortName] objectForKey:@"mcu_download_address"] latestMCUSVersion:[[[_latestDic objectForKey:de.shortName] objectForKey:@"mcu_software_version"] integerValue]];
}

- (void)starteUpdateHud {
    
}

- (void)updateHudProgress:(CGFloat)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_targetModel.updateNumber == 4 || _targetModel.updateNumber == 5) {
            [_customizeHud updateProgress:progress * 0.5 + 0.5];
        }else {
            [_customizeHud updateProgress:progress];
        }
    });
}

- (void)updateSuccess:(NSString *)value {
    [_dataArray removeObject:self.targetModel];
    if ([_dataArray count] == 0) {
        _noneLabel.hidden = NO;
    }
    [self.tableView reloadData];
    [_customizeHud removeFromSuperview];
    _customizeHud = nil;
    [_translucentBgView removeFromSuperview];
    _translucentBgView = nil;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
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

@end
