//
//  ScanViewController.m
//  SocketDemo
//
//  Created by AcTEC on 2018/11/29.
//  Copyright © 2018 BAO. All rights reserved.
//

#import "ScanViewController.h"

#import "SGQRCode.h"

#import "GCDAsyncSocket.h"
#import "CSRParseAndLoad.h"
#import <MBProgressHUD.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "CSRUtilities.h"
#import "CSRAppStateManager.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"

#import <CoreLocation/CLLocationManager.h>

@interface ScanViewController ()<GCDAsyncSocketDelegate,NSStreamDelegate,MBProgressHUDDelegate,CLLocationManagerDelegate>
{
    SGQRCodeObtain *obtain;
    NSData *headData;
    NSMutableData *receiveData;
    NSInteger dataLengthByHead;
    
    NSInteger fileCount;
    BOOL firstFile;
}
@property (nonatomic, strong) SGQRCodeScanView *scanView;
@property (nonatomic, strong) UILabel *promptLabel;
@property (nonatomic, assign) BOOL stop;

@property (nonatomic,strong) GCDAsyncSocket *tcpSocketManager;
@property (nonatomic,strong) MBProgressHUD *hud;
@property (nonatomic,strong) NSString *from;
@property (nonatomic,strong) NSMutableArray *files;

@property (nonatomic, strong) CLLocationManager *locManager;
@property (nonatomic, strong) NSDictionary *scanDic;

@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    obtain = [SGQRCodeObtain QRCodeObtain];
    receiveData = [[NSMutableData alloc] init];
    firstFile = YES;
    [self setupQRCodeScan];
    [self setupNavigationBar];
    [self.view addSubview:self.scanView];
    [self.view addSubview:self.promptLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_stop) {
        [obtain startRunningWithBefore:nil completion:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.scanView addTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.scanView removeTimer];
}

- (void)dealloc {
    [self removeScanningView];
}

- (void)setupQRCodeScan {
    __weak typeof(self) weakSelf = self;
    
    SGQRCodeObtainConfigure *configure = [SGQRCodeObtainConfigure QRCodeObtainConfigure];
    configure.openLog = YES;
    configure.rectOfInterest = CGRectMake(0.05, 0.2, 0.7, 0.6);
    // 这里只是提供了几种作为参考（共：13）；需什么类型添加什么类型即可
    NSArray *arr = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    configure.metadataObjectTypes = arr;
    
    [obtain establishQRCodeObtainScanWithController:self configure:configure];
    [obtain startRunningWithBefore:^{
        
    } completion:^{
        
    }];
    
    [obtain setBlockWithQRCodeObtainScanResult:^(SGQRCodeObtain *obtain, NSString *result) {
        if (result) {
            [obtain stopRunning];
            weakSelf.stop = YES;
            [obtain playSoundName:@"SGQRCode.bundle/sound.caf"];
            
            NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:result];
            if (dic && dic[@"PORT"] && dic[@"IPAddress"]) {
                [weakSelf afterScan:dic];
            }
        }
    }];
    
}

- (void)afterScan:(NSDictionary *)dic {
    if (!_hud) {
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.delegate = self;
    }
    self.scanDic = dic;
    [self getcurrentLocation];
    
}

- (void)getcurrentLocation {
    if (@available(iOS 13.0, *)) {
        //用户明确拒绝，可以弹窗提示用户到设置中手动打开权限
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                                     message:AcTECLocalizedStringFromTable(@"gotosetting", @"Localizable")
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            [alertController.view setTintColor:DARKORAGE];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable")
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
//                                                                 //使用下面接口可以打开当前应用的设置页面
//                                                                 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                             }];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
        
        self.locManager = [[CLLocationManager alloc] init];
        self.locManager.delegate = self;
        if(![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
            //弹框提示用户是否开启位置权限
            [self.locManager requestWhenInUseAuthorization];
        }
    }else {
        [self compareWifiInfo];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self compareWifiInfo];
}

- (void)compareWifiInfo {
    NSString *wifiName = [self getWifiName];
    if ((wifiName && ![self.scanDic[@"WIFIName"] isEqualToString:[self getWifiName]])||!wifiName) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"noSameWIFI", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *action = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    _from = self.scanDic[@"FROM"];
    if ([_from isEqualToString:@"ios"]) {
        Byte byte[] = {0x20,0x18};
        headData = [[NSData alloc] initWithBytes:byte length:2];
    }
    
    [self connentHost:self.scanDic[@"IPAddress"] prot:[self.scanDic[@"PORT"] intValue]];
}

- (void)setupNavigationBar {
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"scan", @"Localizable");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if ([_from isEqualToString:@"ios"]) {
        NSData *head = [data subdataWithRange:NSMakeRange(0, 2)];
        if ([head isEqualToData:headData]) {
            NSData *dataLengthData = [data subdataWithRange:NSMakeRange(2, 4)];
            dataLengthByHead = [CSRUtilities numberWithHexString:[CSRUtilities hexStringForData:dataLengthData]];
            [receiveData appendData:[data subdataWithRange:NSMakeRange(6, data.length-6)]];
        }else {
            [receiveData appendData:data];
        }
        if (receiveData.length == dataLengthByHead) {
            NSString *jsonString = [[NSString alloc] initWithData:receiveData encoding:NSUTF8StringEncoding];
//            NBSLog(@"%@", jsonString);
            NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:jsonString];
            CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
            CSRPlaceEntity *sharePlace = [parseLoad parseIncomingDictionary:jsonDictionary];
            [CSRAppStateManager sharedInstance].selectedPlace = sharePlace;
            if (![[CSRUtilities getValueFromDefaultsForKey:@"kCSRLastSelectedPlaceID"] isEqualToString:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString]]) {
                
                [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
                
            }
            
            [[CSRAppStateManager sharedInstance] setupPlace];
            
            if (self.scanVCHandle) {
                self.scanVCHandle();
            }
            
            [NSThread sleepForTimeInterval:3.0];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reGetDataForPlaceChanged" object:nil];
            
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else if ([_from isEqualToString:@"Android"]) {
        BOOL first = NO;
        if ([receiveData length]<13) {
            first = YES;
        }
        [receiveData appendData:data];
        
        if (first) {
            if ([receiveData length]>12) {
                NSData *fileCountData = [receiveData subdataWithRange:NSMakeRange(0, 4)];
                fileCount = [CSRUtilities numberWithHexString:[CSRUtilities hexStringForData:fileCountData]];
                NSInteger length = [receiveData length];
                receiveData = [NSMutableData dataWithData:[receiveData subdataWithRange:NSMakeRange(4, length-4)]];
            }
        }else {
            if ([receiveData length]>8) {
                NSData *fileLengthData = [receiveData subdataWithRange:NSMakeRange(0, 8)];
                NSInteger fileLength = [CSRUtilities numberWithHexString:[CSRUtilities hexStringForData:fileLengthData]];
                if ([receiveData length] >= fileLength + 8) {
                    NSData *fileData = [NSMutableData dataWithData:[receiveData subdataWithRange:NSMakeRange(8, fileLength)]];
                    if (firstFile) {
                        NSString *jsonString = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
//                        NBSLog(@"ajsonString>> %@",jsonString);
                        NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:jsonString];
                        [self.files addObject:jsonDictionary];
                        
                        firstFile = NO;
                    }else {
                        [self.files addObject:fileData];
                    }
                    if ([self.files count] == fileCount) {
                        CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
                        
                        CSRPlaceEntity *sharePlace = [parseLoad parseIncomingDictionaryFromAndroid:self.files];
                        [CSRAppStateManager sharedInstance].selectedPlace = sharePlace;
                        if (![[CSRUtilities getValueFromDefaultsForKey:@"kCSRLastSelectedPlaceID"] isEqualToString:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString]]) {
                            
                            [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
                            
                        }
                        
                        [[CSRAppStateManager sharedInstance] setupPlace];
                        
                        if (self.scanVCHandle) {
                            self.scanVCHandle();
                        }
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"reGetDataForPlaceChanged" object:nil];
                        
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                    
                    NSInteger length = [receiveData length];
                    receiveData = [NSMutableData dataWithData:[receiveData subdataWithRange:NSMakeRange(fileLength+8, length-fileLength-8)]];
                }
            }
        }
    }
    
    [sock readDataWithTimeout:-1 tag:0];
}

- (SGQRCodeScanView *)scanView {
    if (!_scanView) {
        _scanView = [[SGQRCodeScanView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        // 静态库加载 bundle 里面的资源使用 SGQRCode.bundle/QRCodeScanLineGrid
        // 动态库加载直接使用 QRCodeScanLineGrid
        _scanView.scanImageName = @"SGQRCode.bundle/QRCodeScanLineGrid";
        _scanView.scanAnimationStyle = ScanAnimationStyleGrid;
        _scanView.cornerLocation = CornerLoactionOutside;
        _scanView.cornerColor = [UIColor orangeColor];
    }
    return _scanView;
}

- (void)removeScanningView {
    [self.scanView removeTimer];
    [self.scanView removeFromSuperview];
    self.scanView = nil;
}

- (UILabel *)promptLabel {
    if (!_promptLabel) {
        _promptLabel = [[UILabel alloc] init];
        _promptLabel.backgroundColor = [UIColor clearColor];
        CGFloat promptLabelX = 0;
        CGFloat promptLabelY = 0.73 * self.view.frame.size.height;
        CGFloat promptLabelW = self.view.frame.size.width;
        CGFloat promptLabelH = 40;
        _promptLabel.frame = CGRectMake(promptLabelX, promptLabelY, promptLabelW, promptLabelH);
        _promptLabel.textAlignment = NSTextAlignmentCenter;
        _promptLabel.numberOfLines = 0;
        _promptLabel.font = [UIFont boldSystemFontOfSize:13.0];
        _promptLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
        _promptLabel.text = AcTECLocalizedStringFromTable(@"scanWords", @"Localizable");
    }
    return _promptLabel;
}

- (void)connentHost:(NSString *)host prot:(uint16_t)port{
    if (host==nil || host.length <= 0) {
        NSAssert(host != nil, @"host must be not nil");
    }
    
    if (self.tcpSocketManager == nil) {
        self.tcpSocketManager = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    NSError *connectError = nil;
    BOOL isConnected = [self.tcpSocketManager isConnected];
    NSLog(@"isConnected: %d",isConnected);
    if (!isConnected) {
        [self.tcpSocketManager connectToHost:host onPort:port error:&connectError];
    }else {
        [self.tcpSocketManager readDataWithTimeout:-1 tag:0];
    }

}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@">>>>> didConnectToHost <<<<<");
    [self.tcpSocketManager readDataWithTimeout:-1 tag:0];
}

//获取本机wifi名称
- (NSString *)getWifiName {
    NSArray *ifs = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
    if (!ifs) {
        return nil;
    }
    NSString *WiFiName = nil;
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) {
            // 这里其实对应的有三个key:kCNNetworkInfoKeySSID、kCNNetworkInfoKeyBSSID、kCNNetworkInfoKeySSIDData，
            // 不过它们都是CFStringRef类型的
            WiFiName = [info objectForKey:(__bridge NSString *)kCNNetworkInfoKeySSID];
            break;
        }
    }
    return WiFiName;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

- (NSMutableArray *)files {
    if (!_files) {
        _files = [[NSMutableArray alloc] init];
    }
    return _files;
}


@end
