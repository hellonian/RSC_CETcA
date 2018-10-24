//
//  UpdateViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/11/2.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "UpdateViewController.h"
#import "AppDelegate.h"

#import "DataModelManager.h"
#import "AFHTTPSessionManager.h"
#import <MBProgressHUD.h>
#import "PureLayout.h"

@interface UpdateViewController ()<MBProgressHUDDelegate>

@property BOOL isUpdateRunning;
@property BOOL isInitRunning;
@property BOOL isAbortButton;
@property BOOL peripheralConnected;
@property (nonatomic,strong) MBProgressHUD *hud;
@property (weak, nonatomic) IBOutlet UILabel *deviceAdress;


@end

@implementation UpdateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (@available(iOS 11.0,*)) {
    }else {
        [_deviceAdress autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:74.0f];
    }
    
    [[OTAU sharedInstance] setOTAUDelegate:self];
    
    [self statusMessage: @"Start: Load CS key JSON\n"];
    if ([[OTAU sharedInstance] parseCsKeyJson:@"cskey_db"]) {
        [self statusMessage: @"Success: Load CS key JSON\n"];
    }
    else {
        [self statusMessage: @"Fail: Load CS key JSON\n"];
    }
    
    _peripheralConnected = NO;
    [_connectionState setText:@"DISCONNECTED"];
    
    _progressBar.progress = 0.0;
    _statusLog.layoutManager.allowsNonContiguousLayout = NO;
    _isInitRunning = NO;
    
    if (_targetModel != nil) {
        [_targetName setTitle:[_targetModel name] forState:UIControlStateNormal];
        [_targetName setAlpha:1.0];
        
        [_connectionState setText:@"CONNECTED"];
        _isInitRunning = YES;
        [self setStartAndAbortButtonLook];
        [[OTAU sharedInstance] initOTAU:_targetModel.peripheral];
    }
    
    // Dismiss Discovery View and any nulify all delegates set up for it.
    [[CSRBluetoothLE sharedInstance] setBleDelegate:nil];
    [[CSRBluetoothLE sharedInstance] stopScan];
    [self setStartAndAbortButtonLook];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    AppDelegate *appDelegate= (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!_peripheralConnected) {
        [_modeLabel setText:@"-"];
    }
    else if ([appDelegate.peripheralInBoot boolValue]==YES) {
        [_modeLabel setText:@"BOOT"];
    }
    else {
        [_modeLabel setText:@"APP"];
    }
}

- (IBAction)chooseFirmare:(UIButton *)sender {
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.delegate = self;
    _hud.label.numberOfLines = 0;
    _hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    _hud.label.text = @"firmware downloading: 0%";
    _hud.label.font = [UIFont systemFontOfSize:14];
    
    NSString *urlString = [NSString stringWithFormat:@"http://39.108.152.134/%@.php",_targetModel.kind];
    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    sessionManager.responseSerializer.acceptableContentTypes = nil;
    __weak UpdateViewController *weakSelf = self;
    [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *dic = (NSDictionary *)responseObject;
        NSString *downloadAddress = dic[@"Download_address"];
        [weakSelf downloadfirware:downloadAddress];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.hud.label.text = [NSString stringWithFormat:@"error:%@",error];
        });
    }];
}

- (void)downloadfirware:(NSString *)urlString {
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    NSString *fileName = [urlString lastPathComponent];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSProgress *progress = nil;
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:&progress destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@",fileName]];
        _firmwareFilename = path;
        
        __weak UpdateViewController *weakSelf = self;
        __block NSString *string = [urlString lastPathComponent];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [_firmwareName setTitle:string forState:UIControlStateNormal];
            [_firmwareName setAlpha:1.0];
            [weakSelf setStartAndAbortButtonLook];
            
        });
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.hud.label.text = [NSString stringWithFormat:@"error:%@",error];
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.hud hideAnimated:YES];
            });
            
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
            self.hud.label.text = [NSString stringWithFormat:@"firmware downloading: %0.2f%%",progress.fractionCompleted*100];
            self.hud.progress = progress.fractionCompleted;
        });
        
    }
}

- (IBAction)startUpdate:(id)sender
{
    if (_isAbortButton==NO)
    {
        if (_firmwareFilename!=nil && _targetModel.peripheral!=nil)
        {
            _isAbortButton=YES;
            _isUpdateRunning=YES;
            [self statusMessage:@"------[ Update Started ]------\n"];
            [[OTAU sharedInstance] startOTAU:_firmwareFilename];
            self.progressBar.progress = 0.0;
            [_percentLabel setText: @"0%"];
            [self setStartAndAbortButtonLook];
        }
    }
}

//============================================================================
// Called when the Abort button is pressed
//
- (IBAction)abortUpdate:(id)sender
{
    if (_isAbortButton==YES)
    {
        _isAbortButton=NO;
        [self statusMessage:@"Update Aborted\n"];
        [[OTAU sharedInstance]  abortOTAU:_targetModel.peripheral];
        _isUpdateRunning=NO;
        [self setStartAndAbortButtonLook];
    }
}

-(void) clearTarget {
    [_targetName setTitle:@" " forState:UIControlStateNormal];
    [_targetName setAlpha:1.0];
    _targetModel=nil;
    [self setStartAndAbortButtonLook];
}

-(void) setStartAndAbortButtonLook
{
    if (_isInitRunning || _isUpdateRunning) {
        [_startButton setEnabled:NO];
        [_firmwareName setEnabled:NO];
        [_targetName setEnabled:NO];
    }
    else {
        
        if (![_targetName.titleLabel.text isEqualToString:@" "]&&[_firmwareName.titleLabel.text isEqualToString:@"Download the firmware"]) {
            [_firmwareName setEnabled:YES];
        }else {
            [_firmwareName setEnabled:NO];
        }
        [_targetName setEnabled:YES];
        if (_targetModel.peripheral!=nil && _firmwareFilename!=nil)
        {
            [_startButton setEnabled:YES];
        }
        else
        {
            [_startButton setEnabled:NO];
        }
    }
    
    if (_isUpdateRunning)
    {
        [_abortButton setHidden:NO];
        [_progressBar setHidden:NO];
        [_percentLabel setHidden:NO];
        [_abortButton setEnabled:YES];
        [_startButton setHidden:YES];
    }
    else
    {
        [_abortButton setHidden:YES];
        [_abortButton setEnabled:NO];
        [_progressBar setHidden:YES];
        [_percentLabel setHidden: YES];
        [_startButton setHidden:NO];
    }
}

/****************************************************************************/
/*                                Delegates                                 */
/****************************************************************************/
//============================================================================
// Update the progress bar when a progress percentage update is received during OTAU update.
-(void) didUpdateProgress: (uint8_t) percent {
    self.progressBar.progress = percent / 100.0f;
    [_percentLabel setText: [NSString stringWithFormat:@"%d%%", percent]];
    if (percent == 100) {
        // Transfer is complete so update controls to hide abort and progress bar,
        // but show a disabled start button as init is running again to query versions
        // and cs keys. We will receive the "complete" delegate when that is done.
        _isUpdateRunning = NO;
        _isInitRunning = YES;
        [self setStartAndAbortButtonLook];
    }
}

//============================================================================
//
-(void) didUpdateBtaAndTrim:(NSData *)btMacAddress :(NSData *)crystalTrimValue {
    [self.deviceAddress setText: @"-"];
    [self.crystalTrim setText: @"-"];
    
    if (btMacAddress != nil && crystalTrimValue != nil) {
        // Display bluetooth address.
        const uint8_t *octets = (uint8_t*)[btMacAddress bytes];
        NSString *display = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                             octets[0], octets[1], octets[2], octets[3], octets[4], octets[5]];
        
        [_deviceAddress setText:display];
        
        // Display crystal trim.
        const uint16_t *trim = (uint16_t*)[crystalTrimValue bytes];
        display = [NSString stringWithFormat:@"0x%X", *trim];
        [_crystalTrim setText:display];
        [self statusMessage: @"Success: Read CS keys.\n"];
    }
    else {
        [self statusMessage: @"Failed to read CS keys.\n"];
    }
    
    if (_isInitRunning) {
        _isInitRunning = NO;
        [self setStartAndAbortButtonLook];
    }
}

//============================================================================
// This delegate is called after we have called initOTAU and the library has finished
// querying the peripheral.
-(void) didUpdateVersion:(uint8_t)otauVersion {
    [self.fwVersion setText: @"-"];
    
    if (otauVersion > 3) {
        [_fwVersion setText: [NSString stringWithFormat:@"%d", otauVersion]];
        [self statusMessage: @"Success: Get version.\n"];
    }
    else {
        [self statusMessage: @"Failed to read OTAU version.\n"];
    }
}

//============================================================================
//
-(void) didUpdateAppVersion:(NSString*)appVersionString {
    [self statusMessage: [NSString stringWithFormat:@"Success: Got app version:%@\n", appVersionString]];
    if (appVersionString != nil) {
        [_appVersion setText: appVersionString];
        [_appVersionLabel setHidden: NO];
        [_appVersion setHidden: NO];
    }
    else {
        [_appVersionLabel setHidden: YES];
        [_appVersion setHidden: YES];
    }
}

//============================================================================
// This delegate is called when the selected peripheral connection state changes.
-(void) didChangeConnectionState:(bool)isConnected {
    [_deviceAddress setText: @"-"];
    [_crystalTrim setText: @"-"];
    [_fwVersion setText: @"-"];
    [_modeLabel setText: @"-"];
    [_challengeLabel setText: @"-"];
    [_appVersion setText: @"-"];
    if (isConnected) {
        _peripheralConnected = YES;
        [_connectionState setText:@"CONNECTED"];
    }
    else {
        _peripheralConnected = NO;
        [_connectionState setText:@"DISCONNECTED"];
    }
}

//============================================================================
//
-(void) didChangeMode: (bool) isBootMode {
    if (isBootMode) {
        [_modeLabel setText: @"BOOT"];
    }
    else {
        [_modeLabel setText: @"APP"];
    }
}

//============================================================================
//
-(void) didUpdateChallengeResponse:(bool)challengeEnabled {
    if (challengeEnabled) {
        [_challengeLabel setText: @"ENABLED"];
    }
    else {
        [_challengeLabel setText: @"DISABLED"];
    }
}

//============================================================================
// Display an Alert upon successful completion
//
-(void) completed:(NSString *) message {
    _isAbortButton=NO;
    _isUpdateRunning=NO;
    [self setStartAndAbortButtonLook];
    NSString *title;
    title = @"OTAU";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController.view setTintColor:DARKORAGE];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([message isEqualToString:@"Success: Application Update"]) {
            [[CSRBluetoothLE sharedInstance] setIsUpdateFW:NO];
            [[CSRBluetoothLE sharedInstance] disconnectPeripheral:_targetModel.peripheral];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[CSRBluetoothLE sharedInstance] connectPeripheralNoCheck:_targetModel.peripheral];
            });
            
            CATransition *animation = [CATransition animation];
            [animation setDuration:0.3];
            [animation setType:kCATransitionMoveIn];
            [animation setSubtype:kCATransitionFromLeft];
            [self.view.window.layer addAnimation:animation forKey:nil];
            [self dismissViewControllerAnimated:NO completion:nil];
        }
        
    }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

//============================================================================
// Display the status in the Text view
-(void) statusMessage:(NSString *)message
{
    [_statusLog setText:[_statusLog.text stringByAppendingString:message]];
    NSRange range = NSMakeRange(_statusLog.text.length - 1, 1);
    [_statusLog scrollRangeToVisible:range];
}

//============================================================================
// Display error as an Alert
-(void) otauError:(NSError *) error {
    
    if (_isInitRunning) {
        _isInitRunning = NO;
        [self clearTarget];
    }
    else if (_isUpdateRunning) {
        _isAbortButton = NO;
        _isUpdateRunning = NO;
    }
    
    // Convert error code to 4 character string, as error codes will be in the range 1000-9999
    NSString *errorCodeString = [NSString stringWithFormat:@"%4d",(int)error.code];
    
    // Lookup Error string from error code
    NSString *errorString = NSLocalizedStringFromTable (errorCodeString, @"ErrorCodes", nil);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"OTAU Error"
                                                                             message:errorString
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController.view setTintColor:DARKORAGE];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
    [self setStartAndAbortButtonLook];
}


#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hudd {
    [hudd removeFromSuperview];
    hudd = nil;
}


@end
