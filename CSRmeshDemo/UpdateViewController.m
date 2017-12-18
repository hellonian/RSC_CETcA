//
//  UpdateViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/11/2.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "UpdateViewController.h"
#import "AppDelegate.h"

#import "DataModelManager.h"
#import "AFHTTPSessionManager.h"

@interface UpdateViewController ()

@property BOOL isUpdateRunning;
@property BOOL isInitRunning;
@property BOOL isAbortButton;
@property BOOL peripheralConnected;

@end

@implementation UpdateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"Update";
    
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
    
    // Did we open App with email or dropbox attachment?
    AppDelegate *appDelegate= (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.urlImageFile) {
        [self handleOpenURL:appDelegate.urlImageFile];
    }
    
//    UIButton *playPauseButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
//    playPauseButton.center = CGPointMake(WIDTH/2, 200);
//    playPauseButton.bounds = CGRectMake(0, 0, 60, 60);
//    playPauseButton.backgroundColor = [UIColor redColor];
//    [self.view addSubview:playPauseButton];
//    [playPauseButton addTarget:self action:@selector(playPauseButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)playPauseButtonAction:(UIButton *)sender {
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Inbox"];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *array = [manager contentsOfDirectoryAtPath:path error:nil];
    NSLog(@"%ld >>>>>>>>>>>>>>>>>>>>>> %@",array.count,array);
    NSString *doc = [path stringByAppendingPathComponent:@"s350bt-2017-11-1_update.img"];
    BOOL isE = [manager fileExistsAtPath:doc];
    NSLog(@"isE > > %d",isE);

    NSString *path1 = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSArray *array1 = [manager contentsOfDirectoryAtPath:path1 error:nil];
    NSLog(@"%ld >>>>>>>>>>Documents>>>>>>>>>>>> %@",array1.count,array1);

    NSString *path0 = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/localFile"];
    NSArray *array0 = [manager contentsOfDirectoryAtPath:path0 error:nil];
    NSLog(@"%ld >>>>>>>>>>Documents/localFile>>>>>>>>>>>> %@",array0.count,array0);
    
    [[DataModelManager shareInstance] sendCmdData:@"880100" toDeviceId:@(32771)];
    
//    if ([[_targetPeripheral name] hasSuffix:@"S350BT"]) {
//    
//    }
    
//    NSString *urlStr = @"http://39.108.152.134/s350bt.php";
//    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
//    sessionManager.responseSerializer.acceptableContentTypes = nil;
//    [sessionManager GET:urlStr parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
//        NSDictionary *dic = (NSDictionary *)responseObject;
//        NSLog(@"%@",dic);
//    } failure:^(NSURLSessionDataTask *task, NSError *error) {
//        NSLog(@"%@",error);
//    }];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[CSRBluetoothLE sharedInstance] setIsUpdatePage:YES];
}
-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[CSRBluetoothLE sharedInstance] setIsUpdatePage:NO];
    
    NSArray *imgAry = @[@"s350bt",@"d350bt",@"rc350",@"rc351"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *imgStr in imgAry) {
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.img",imgStr]];
        BOOL result = [fileManager fileExistsAtPath:path];
        if (result) {
            [fileManager removeItemAtPath:path error:nil];
        }
    }
    
    NSString *inboxPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Inbox"];
    BOOL inboxResult = [fileManager fileExistsAtPath:inboxPath];
    if (inboxResult) {
        [fileManager removeItemAtPath:inboxPath error:nil];
    }
    
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
    NSLog(@"chooseFirmware");
//    FirmwareSelector *fs = [[FirmwareSelector alloc] init];
//    fs.firmwareDelegate = self;
//    [self.navigationController pushViewController:fs animated:YES];
    
    if ([[_targetPeripheral name] hasSuffix:@"S350BT"]) {
        NSString *urlStr = @"http://39.108.152.134/S350BT_V1.1.3.1.1.img";
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/s350bt.img"];
            [_firmwareName setTitle:@"S350BT" forState:UIControlStateNormal];
            [_firmwareName setAlpha:1.0];
            _firmwareFilename = path;
            [self setStartAndAbortButtonLook];
            return [NSURL fileURLWithPath:path];
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            if (error) {
                NSLog(@"%@",error);
            }
        }];
        [task resume];
    }

}

- (IBAction)chooseTarger:(UIButton *)sender {
    NSLog(@"chooseTarget");
    DiscoverViewController *dvc = [[DiscoverViewController alloc] init];
    dvc.discoveryViewDelegate = self;
    [self.navigationController pushViewController:dvc animated:YES];
}

// Delegates
-(void) firmwareSelector:(NSString *) filepath {
    if ([filepath isEqualToString:@""]) {
    }
    else {
        NSString *filename = [[filepath lastPathComponent] stringByDeletingPathExtension];
        [_firmwareName setTitle:filename forState:UIControlStateNormal];
        [_firmwareName setAlpha:1.0];
        _firmwareFilename = filepath;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    [self setStartAndAbortButtonLook];
}

-(void) setTarget:(id)peripheral
{
    if (peripheral != nil)
    {
        NSLog(@"11111111111111");
        [_targetName setTitle:[peripheral name] forState:UIControlStateNormal];
        [_targetName setAlpha:1.0];
        _targetPeripheral = peripheral;
        [_connectionState setText:@"CONNECTED"];
        _isInitRunning = YES;
        [self setStartAndAbortButtonLook];
        [[OTAU sharedInstance] initOTAU:peripheral];
    }
    
    // Dismiss Discovery View and any nulify all delegates set up for it.
    [[CSRBluetoothLE sharedInstance] setBleDelegate:nil];
//    [self dismissViewControllerAnimated:YES completion:nil];
    [[CSRBluetoothLE sharedInstance] stopScan];
    [self setStartAndAbortButtonLook];
}

//============================================================================
// Called when the Start button is pressed
//
- (IBAction)startUpdate:(id)sender
{
    if (_isAbortButton==NO)
    {
        if (_firmwareFilename!=nil && _targetPeripheral!=nil)
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
        [[OTAU sharedInstance]  abortOTAU:_targetPeripheral];
        _isUpdateRunning=NO;
        [self setStartAndAbortButtonLook];
    }
}

-(void) clearTarget {
    [_targetName setTitle:@"set target" forState:UIControlStateNormal];
    [_targetName setAlpha:1.0];
    _targetPeripheral=nil;
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
        
        if (![_targetName.titleLabel.text isEqualToString:@"set target"]&&[_firmwareName.titleLabel.text isEqualToString:@"set filename"]) {
            [_firmwareName setEnabled:YES];
        }else {
            [_firmwareName setEnabled:NO];
        }
        [_targetName setEnabled:YES];
        if (_targetPeripheral!=nil && _firmwareFilename!=nil)
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
/*                                Open With.....                            */
/****************************************************************************/
-(void) handleOpenURL:(NSURL *)url {
    NSString *filename = [[url lastPathComponent] stringByDeletingPathExtension];
    [_firmwareName setTitle:filename forState:UIControlStateNormal];
    [_firmwareName setAlpha:1.0];
    _firmwareFilename = url.path;
    [self statusMessage:[NSString stringWithFormat:@"Imported File %@\n >>%@\n",_firmwareFilename,url]];
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
        [self statusMessage: @"1717>>Success: Read CS keys.\n"];
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
        [self statusMessage: @"66>>Success: Get version.\n"];
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

//============================================================================
// Display the status in the Text view
-(void) statusMessage:(NSString *)message
{
    NSLog(@"文档 %@",message);
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
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OTAU Error"
                                                    message:errorString
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
    [self setStartAndAbortButtonLook];
}

@end
