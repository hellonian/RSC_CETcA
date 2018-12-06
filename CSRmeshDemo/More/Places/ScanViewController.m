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

@interface ScanViewController ()<GCDAsyncSocketDelegate,NSStreamDelegate,MBProgressHUDDelegate>
{
    SGQRCodeObtain *obtain;
    uint16_t streamNum;
}
@property (nonatomic, strong) SGQRCodeScanView *scanView;
@property (nonatomic, strong) UILabel *promptLabel;
@property (nonatomic, assign) BOOL stop;

@property (nonatomic,strong) GCDAsyncSocket *tcpSocketManager;
@property (nonatomic,strong) MBProgressHUD *hud;

@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    obtain = [SGQRCodeObtain QRCodeObtain];
    
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
            
            NSDictionary *dic = [weakSelf dictionaryWithJsonString:result];
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
    
    if (![dic[@"WIFIName"] isEqualToString:[self getWifiName]]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"noSameWIFI", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *action = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [self connentHost:dic[@"IPAddress"] prot:[dic[@"PORT"] intValue]];
    
    CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
    NSData *jsonData = [parseLoad composeDatabase];
    
    int value = (int)jsonData.length;
    Byte byteData[4] = {};
    byteData[0] =(Byte)((value & 0xFF000000)>>24);
    byteData[1] =(Byte)((value & 0x00FF0000)>>16);
    byteData[2] =(Byte)((value & 0x0000FF00)>>8);
    byteData[3] =(Byte)((value & 0x000000FF));
    
    Byte byte[] = {0x20,0x18,byteData[0],byteData[1],byteData[2],byteData[3]};
    NSData *temphead = [[NSData alloc] initWithBytes:byte length:6];
    NSMutableData *mutableData = [[NSMutableData alloc] init];
    [mutableData appendData:temphead];
    [mutableData appendData:jsonData];
    
    [self.tcpSocketManager writeData:mutableData withTimeout:-1 tag:0];
}

- (void)setupNavigationBar {
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"scan", @"Localizable");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"saomiaodata -> %@\n%ld\n%@",data,tag,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    NSString *backString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([backString isEqualToString:@"AcTEC"]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    [sock readDataWithTimeout:-1 tag:1];
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

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }

    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

- (void)connentHost:(NSString *)host prot:(uint16_t)port{
    if (host==nil || host.length <= 0) {
        NSAssert(host != nil, @"host must be not nil");
    }
    
    [self.tcpSocketManager disconnect];
    if (self.tcpSocketManager == nil) {
        self.tcpSocketManager = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    NSError *connectError = nil;
    BOOL isConnected = [self.tcpSocketManager isConnected];
    NSLog(@"isConnected: %d",isConnected);
    if (!isConnected) {
        if (![self.tcpSocketManager connectToHost:host onPort:port error:&connectError]) {
            NSLog(@"Connect Error: %@", connectError);
        }else {
            NSLog(@"Connect success!");
            [self.tcpSocketManager readDataWithTimeout:-1 tag:1];
        }
    }

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


@end
