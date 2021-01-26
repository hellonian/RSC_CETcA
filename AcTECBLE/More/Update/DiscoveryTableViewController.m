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

@interface DiscoveryTableViewController ()<CSRBluetoothLEDelegate,OTAUDelegate,CSRUpdateManagerDelegate,UITableViewDelegate, UITableViewDataSource>
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
@property (nonatomic,strong) NSNumber *targetDeviceId;

@end

@implementation DiscoveryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
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
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundView = [[UIView alloc] init];
    _tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_tableView];
    
    NSString *urlString = @"http://39.108.152.134/firware.php";
    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    sessionManager.responseSerializer.acceptableContentTypes = nil;
    sessionManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        _latestDic = nil;
        _latestDic = (NSDictionary *)responseObject;
        
        NSArray *connectedPeripherals = [[CSRBluetoothLE sharedInstance] connectedPeripherals];
        for (CBPeripheral *peripheral in connectedPeripherals) {
            __block CSRDeviceEntity *connectDevice;
            [_appAllDevcies enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *adUuidString = [peripheral.uuidString substringToIndex:12];
                NSString *deviceUuidString = [deviceEntity.uuid substringFromIndex:24];
                if ([adUuidString isEqualToString:deviceUuidString]) {
                    NSInteger lastestVersion = [[_latestDic objectForKey:deviceEntity.shortName] integerValue];
                    if (deviceEntity.firVersion && [deviceEntity.firVersion integerValue] < lastestVersion) {
                        connectDevice = deviceEntity;
                    }
                    *stop = YES;
                }
            }];
            if (connectDevice) {
                UpdateDeviceModel *model = [[UpdateDeviceModel alloc] init];
                model.peripheral = peripheral;
                model.name = connectDevice.name;
                model.connected = YES;
                model.kind = connectDevice.shortName;
                model.deviceId = connectDevice.deviceId;
                model.bleHwVersion = connectDevice.bleHwVersion;
                model.bleFVersion = connectDevice.bleFirVersion;
                model.fVersion = connectDevice.firVersion;
                model.hVersion = connectDevice.hwVersion;
                [_dataArray addObject:model];
                [self.tableView reloadData];
            }
        }
        
        [[CSRBluetoothLE sharedInstance] setIsUpdateFW:YES];
        [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
        [[CSRBluetoothLE sharedInstance] startScan];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%@",error);
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
        __block CSRDeviceEntity *connectDevice;
        [_appAllDevcies enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *adUuidString = [peripheral.uuidString substringToIndex:12];
            NSString *deviceUuidString = [deviceEntity.uuid substringFromIndex:24];
            if ([adUuidString isEqualToString:deviceUuidString]) {
                NSInteger lastestVersion = [[_latestDic objectForKey:connectDevice.shortName] integerValue];
                if (connectDevice.firVersion && [connectDevice.firVersion integerValue] < lastestVersion) {
                    connectDevice = deviceEntity;
                }
                *stop = YES;
            }
        }];
        if (connectDevice) {
            UpdateDeviceModel *model = [[UpdateDeviceModel alloc] init];
            model.peripheral = peripheral;
            model.name = connectDevice.name;
            model.connected = YES;
            model.kind = connectDevice.shortName;
            model.deviceId = connectDevice.deviceId;
            model.bleHwVersion = connectDevice.bleHwVersion;
            model.bleFVersion = connectDevice.bleFirVersion;
            model.fVersion = connectDevice.firVersion;
            model.hVersion = connectDevice.hwVersion;
            [_dataArray addObject:model];
        }
    }
    [self.tableView.refreshControl endRefreshing];
    [self.tableView reloadData];
    [[CSRBluetoothLE sharedInstance] stopScan];
    [[CSRBluetoothLE sharedInstance] startScan];;
    
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
    }
    UpdateDeviceModel *model = [self.dataArray objectAtIndex:indexPath.row];
    cell.textLabel.text = model.name;
    NSString *bleFString = @"";
    NSString *s = [CSRUtilities stringWithHexNumber:[model.bleFVersion integerValue]];
    switch ([s length]) {
        case 3:
            s = [NSString stringWithFormat:@"0%@",s];
            break;
        case 2:
            s = [NSString stringWithFormat:@"00%@",s];
            break;
        case 1:
            s = [NSString stringWithFormat:@"000%@",s];
            break;
        default:
            break;
    }
    NSInteger s1 = [CSRUtilities numberWithHexString:[s substringWithRange:NSMakeRange(0, 2)]];
    NSInteger s2 = [CSRUtilities numberWithHexString:[s substringWithRange:NSMakeRange(2, 2)]];
    bleFString = [NSString stringWithFormat:@"%ld%ld",s1,s2];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"V%@.%@.%@.%@",[CSRUtilities stringWithHexNumber:[model.bleHwVersion integerValue]],bleFString,model.hVersion,model.fVersion];
    
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
        
        NSString *urlString = [NSString stringWithFormat:@"http://39.108.152.134/Firmware/%@/%@.php",model.kind,model.kind];
        AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
        sessionManager.responseSerializer.acceptableContentTypes = nil;
        sessionManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
        __weak DiscoveryTableViewController *weakSelf = self;
        [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSDictionary *dic = (NSDictionary *)responseObject;
            NSString *downloadAddress = dic[@"Download_address"];
            [weakSelf downloadfirware:downloadAddress :model];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            
        }];
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
            [_customizeHud updateProgress:0.1];
        });
        
        if (([model.bleHwVersion integerValue] >= 16 && [model.bleHwVersion integerValue] < 32)|| ([model.kind isEqualToString:@"S350B"] || [model.kind isEqualToString:@"S2400IB"] || [model.kind isEqualToString:@"S2400IB-Q"] || [model.kind isEqualToString:@"D350SB"] || [model.kind isEqualToString:@"D350B"] || [model.kind isEqualToString:@"D300IB-T2"] || [model.kind isEqualToString:@"D350SB-Q2"] || [model.kind isEqualToString:@"D300SB"] || [model.kind isEqualToString:@"D350SB-Q"] || [model.kind isEqualToString:@"D300IB-Q"] || [model.kind isEqualToString:@"RB01"] || [model.kind isEqualToString:@"RB05"] || [model.kind isEqualToString:@"D300IB"])) {
            [[CSRBluetoothLE sharedInstance] setIsForGAIA:NO];
            [[OTAU shareInstance] setSourceFilePath:path];
            if (model.connected) {
                CBUUID *uuid = [CBUUID UUIDWithString:serviceApplicationOtauUuid];
                CBUUID *bl_uuid = [CBUUID UUIDWithString:serviceBootOtauUuid];
                for (CBService *service in model.peripheral.services) {
                    if ([service.UUID isEqual:uuid] || [service.UUID isEqual:bl_uuid]) {
                        [[CSRBluetoothLE sharedInstance] setTargetPeripheral:model.peripheral];
                        [[CSRBluetoothLE sharedInstance] setDiscoveredChars:[NSNumber numberWithBool:YES]];
                        [[OTAU shareInstance] initOTAU:model.peripheral];
                        break;
                    }
                }
            }else {
                [[CSRBluetoothLE sharedInstance] setSecondConnectBool:NO];
                [[CSRBluetoothLE sharedInstance] connectPeripheralNoCheck:model.peripheral];
            }
        }else if ([model.bleHwVersion integerValue] >= 32 && [model.bleHwVersion integerValue] < 48) {
            self.sourceFilePath = path;
            self.targetDeviceId = model.deviceId;
            [[CSRBluetoothLE sharedInstance] setIsForGAIA:YES];
            self.isDataEndPointAvailabile = false;
            [CSRGaiaManager sharedInstance].delegate = self;
            
            if (model.connected) {
                CBUUID *uuid = [CBUUID UUIDWithString:UUID_GAIA_SERVICE];
                for (CBService *service in model.peripheral.services) {
                    if ([service.UUID isEqual:uuid]) {
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
            [_customizeHud updateProgress:progress.fractionCompleted * 0.1];
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
    if (![_uuids containsObject:peripheral.uuidString]) {
        for (CSRDeviceEntity *deviceEntity in _appAllDevcies) {
            NSString *adUuidString = [peripheral.uuidString substringToIndex:12];
            NSString *deviceUuidString = [deviceEntity.uuid substringFromIndex:24];
            if ([adUuidString isEqualToString:deviceUuidString]) {
                NSInteger lastestVersion = [[_latestDic objectForKey:deviceEntity.shortName] integerValue];
                if (deviceEntity.firVersion && [deviceEntity.firVersion integerValue] < lastestVersion) {
                    UpdateDeviceModel *model = [[UpdateDeviceModel alloc] init];
                    model.peripheral = peripheral;
                    model.name = deviceEntity.name;
                    model.deviceId = deviceEntity.deviceId;
                    model.connected = NO;
                    model.kind = deviceEntity.shortName;
                    model.bleHwVersion = deviceEntity.bleHwVersion;
                    model.bleFVersion = deviceEntity.bleFirVersion;
                    model.fVersion = deviceEntity.firVersion;
                    model.hVersion = deviceEntity.hwVersion;
                    
                    [_dataArray addObject:model];
                    [self.tableView reloadData];
                }
                [_uuids addObject:peripheral.uuidString];
                break;
            }
        }
        
    }
    
}

- (void)regetVersion:(NSString *)uuidstring {
    UpdateDeviceModel *targetModel;
    for (UpdateDeviceModel *model in _dataArray) {
        if ([[model.peripheral.uuidString substringToIndex:12] isEqualToString:uuidstring]) {
            targetModel = model;
            _targetDeviceId = model.deviceId;
        }
    }
    if (targetModel) {
        [_dataArray removeObject:targetModel];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
    
    retrycout = 0;
    [self performSelector:@selector(getVersionDelayMethod) withObject:nil afterDelay:2.0];
    Byte byte[] = {0x88, 0x01, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:self.targetDeviceId data:cmd];
}

- (void)updateProgressDelegteMethod:(CGFloat)percentage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_customizeHud updateProgress:percentage];
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
//    self.updateProgressView.progress = value / 100;
//
//    self.title = [NSString stringWithFormat:@"%.2f%% Complete", value];
//    self.timeLeftLabel.text = eta;
//    NSLog(@"%@\n%@",[NSString stringWithFormat:@"%.2f%% Complete", value],eta);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_customizeHud updateProgress:value];
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
    
    
    if (self.targetDeviceId) {
        UpdateDeviceModel *targetModel;
        for (UpdateDeviceModel *model in _dataArray) {
            if ([model.deviceId isEqualToNumber:self.targetDeviceId]) {
                targetModel = model;
                break;
            }
        }
        if (targetModel) {
            [_dataArray removeObject:targetModel];
            [self.tableView reloadData];
        }
    }
    
    retrycout = 0;
    [self performSelector:@selector(getVersionDelayMethod) withObject:nil afterDelay:2.0];
    Byte byte[] = {0x88, 0x01, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:self.targetDeviceId data:cmd];
    
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
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:self.targetDeviceId data:cmd];
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
    if (self.targetDeviceId) {
        if ([uDeviceID isEqualToNumber:self.targetDeviceId]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getVersionDelayMethod) object:nil];
            [_customizeHud removeFromSuperview];
            _customizeHud = nil;
            [_translucentBgView removeFromSuperview];
            _translucentBgView = nil;
            [UIApplication sharedApplication].idleTimerDisabled = NO;
        }
    }
}

@end
