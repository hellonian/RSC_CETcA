//
//  DiscoveryTableViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/3/15.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
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

@interface DiscoveryTableViewController ()<CSRBluetoothLEDelegate,OTAUDelegate>

@property (nonatomic,strong)NSMutableArray *dataArray;
@property (nonatomic,strong)NSMutableArray *uuids;
@property (nonatomic,strong)NSArray *appAllDevcies;
@property (nonatomic,strong) NSDictionary *latestDic;
@property (nonatomic,strong) CustomizeProgressHud *customizeHud;
@property (nonatomic,strong) UIView *translucentBgView;

@end

@implementation DiscoveryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
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
    if ([[OTAU shareInstance] parseCsKeyJson:@"cskey_db"]) {
        NSLog(@"Success: Load CS key JSON");
    }else {
        NSLog(@"Fail: Load CS key JSON");
    }
    [[OTAU shareInstance] setOtauDelegate:self];
    _dataArray = [[NSMutableArray alloc] init];
    _uuids = [[NSMutableArray alloc] init];
    _appAllDevcies = [[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects];
    NSString *urlString = @"http://39.108.152.134/firware.php";
    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    sessionManager.responseSerializer.acceptableContentTypes = nil;
    sessionManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        _latestDic = nil;
        _latestDic = (NSDictionary *)responseObject;
        if ([_dataArray count]>0) {
            for (UpdateDeviceModel *model in _dataArray) {
                NSInteger lastestVersion = [[_latestDic objectForKey:model.kind] integerValue];
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:model.deviceId];
                if (deviceEntity.firVersion && [deviceEntity.firVersion integerValue] < lastestVersion) {
                    model.needUpdate = YES;
                }else {
                    model.needUpdate = NO;
                }
            }
        }
        [[CSRBluetoothLE sharedInstance] setIsUpdateFW:YES];
        [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
        [[CSRBluetoothLE sharedInstance] startScan];
        NSLog(@"%@",_latestDic);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%@",error);
    }];
    
     NSArray *connectedPeripherals = [[CSRBluetoothLE sharedInstance] connectedPeripherals];
    for (CBPeripheral *peripheral in connectedPeripherals) {
        __block CSRDeviceEntity *connectDevice;
        [_appAllDevcies enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *adUuidString = [peripheral.uuidString substringToIndex:12];
            NSString *deviceUuidString = [deviceEntity.uuid substringFromIndex:24];
            if ([adUuidString isEqualToString:deviceUuidString]) {
                connectDevice = deviceEntity;
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
            [_dataArray addObject:model];
            [self.tableView reloadData];
        }
    }
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
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dicoveryListCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"dicoveryListCell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    UpdateDeviceModel *model = [self.dataArray objectAtIndex:indexPath.row];
    cell.textLabel.text = model.name;
    if (model.needUpdate) {
        cell.textLabel.textColor = DARKORAGE;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UpdateDeviceModel *model = [self.dataArray objectAtIndex:indexPath.row];
    if (model.needUpdate) {
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
        NSLog(@"%@",urlString);
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
    }
}

- (void)downloadfirware:(NSString *)urlString :(UpdateDeviceModel *)model {
    NSLog(@"downloadfirware");
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    NSString *fileName = [urlString lastPathComponent];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
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

- (void)discoveryDidRefresh:(CBPeripheral *)peripheral {
    for (CSRDeviceEntity *deviceEntity in _appAllDevcies) {
        NSString *adUuidString = [peripheral.uuidString substringToIndex:12];
        NSString *deviceUuidString = [deviceEntity.uuid substringFromIndex:24];
        if ([adUuidString isEqualToString:deviceUuidString]) {
            UpdateDeviceModel *model = [[UpdateDeviceModel alloc] init];
            model.peripheral = peripheral;
            model.name = deviceEntity.name;
            model.connected = NO;
            model.kind = deviceEntity.shortName;
            NSInteger lastestVersion = [[_latestDic objectForKey:deviceEntity.shortName] integerValue];
            NSLog(@"%@ %ld",deviceEntity.firVersion,lastestVersion);
            if (deviceEntity.firVersion && [deviceEntity.firVersion integerValue] < lastestVersion) {
                model.needUpdate = YES;
            }else {
                model.needUpdate = NO;
            }
            if (![_uuids containsObject:peripheral.uuidString]) {
                [_uuids addObject:peripheral.uuidString];
                [_dataArray addObject:model];
                [self.tableView reloadData];
            }
            break;
        }
    }
}

- (void)regetVersion {
    [self.tableView reloadData];
    [_customizeHud removeFromSuperview];
    _customizeHud = nil;
    [_translucentBgView removeFromSuperview];
    _translucentBgView = nil;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
}

- (void)updateProgressDelegteMethod:(CGFloat)percentage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_customizeHud updateProgress:percentage];
    });
}

@end
