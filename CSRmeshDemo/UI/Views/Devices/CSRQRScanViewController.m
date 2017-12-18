//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRQRScanViewController.h"
#import "CSRmeshStyleKit.h"
#import "CSRConstants.h"
#import "CSRUtilities.h"
#import "CSRDatabaseManager.h"
#import "CSRDevicesManager.h"
#import "CSRMeshUtilities.h"
#import "CSRWizardPopoverViewController.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceDetailsViewController.h"

@interface CSRQRScanViewController ()
{
    BOOL scanState;
    NSInteger selectedDeviceIndex;
    NSUInteger wizardMode;
    NSData *deviceHash;
    NSData *authCode;
    
}

@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic) CALayer *targetLayer;
@property (nonatomic) NSMutableArray *qrCodeObjects;
@property (nonatomic) BOOL isReading;
@property (nonatomic) NSMutableArray *discoveredDevicesArray;

- (BOOL)startQRReading;
- (void)stopQRReading;

@end

@implementation CSRQRScanViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setNeedsStatusBarAppearanceUpdate];
    self.title = @"Scan QR Code";

    //Set navigation buttons
//    _backButton = [[UIBarButtonItem alloc] init];
//    _backButton.image = [CSRmeshStyleKit imageOfBack_arrow];
//    _backButton.action = @selector(back:);
//    _backButton.target = self;
    
//    [super addCustomBackButtonItem:_backButton];
    
    
    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDiscoverDeviceNotification:)
                                                 name:kCSRmeshManagerDidDiscoverDeviceNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateAppearanceNotification:)
                                                 name:kCSRmeshManagerDidUpdateAppearanceNotification
                                               object:nil];
    
    scanState = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _deviceEntity = nil;
    _selectedDevice = nil;
    deviceHash = nil;
    authCode = nil;
    _uuidStringFromQRScan = nil;
    _acStringFromQRScan = nil;
    
    // Start the BLE scan
//    [[MeshServiceApi sharedInstance] setContinuousLeScanEnabled:YES];
//    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:YES];
    
    // Disable 'Associate' buttons
    _associateQRButton.enabled = NO;
    
    //Set initial UUID and AC strings to
    _uuidStringFromQRScan = @"";
    _acStringFromQRScan = @"";
    
    [self setupQRmode];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //Notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDidDiscoverDeviceNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDidUpdateAppearanceNotification
                                                  object:nil];
    [[CSRDevicesManager sharedInstance].unassociatedMeshDevices removeAllObjects];
    // Stop the BLE scan
    // [[MeshServiceApi sharedInstance] setContinuousLeScanEnabled:NO];
    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:NO];
}

- (void) dismissAndPush:(CSRDeviceEntity *)dvcEnt
{
    _deviceEntity = dvcEnt;
    [self performSegueWithIdentifier:@"editAssociatedDevice" sender:nil];
}


#pragma mark - Layout Subviews

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _videoPreviewLayer.frame = _qrPreview.layer.bounds;
        _videoPreviewLayer.position = CGPointMake(CGRectGetMidX(_qrPreview.layer.bounds), CGRectGetMidY(_qrPreview.layer.bounds));
        
    });
}

- (void)dealloc
{
    self.view = nil;
}




#pragma mark - Setup QR code screen

- (void)setupQRmode
{
    _scanQRview.hidden = NO;
    
    //Set initially capture session to nil
    _captureSession = nil;
    _isReading = NO;
    
    _successTickboxImageView.image = [CSRmeshStyleKit imageOfIconQRScanOk];
    
    _scanSuccessView.backgroundColor = [UIColor clearColor];
    _scanSuccessView.alpha = 0.85;
    _scanSuccessView.hidden = YES;
    
    _qrPreview.layer.borderWidth = 0.5;
    _qrPreview.layer.borderColor = [[CSRUtilities colorFromHex:kColorBlueCSR] CGColor];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self startQRReading];
    });
}


#pragma mark - QR reading methods

- (BOOL)startQRReading
{
    
    _scanSuccessView.hidden = YES;
    
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    //Initialize the captureSession object.
    _captureSession = [[AVCaptureSession alloc] init];
    _captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    // Set the input device on the capture session.
    [_captureSession addInput:input];
    
    
    //Initialize a AVCaptureMetadataOutput object
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    //Create a new serial dispatch queue.
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("QRQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    //Initialize the video preview layer
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _videoPreviewLayer.frame = _qrPreview.layer.bounds;
    _videoPreviewLayer.position = CGPointMake(CGRectGetMidX(_qrPreview.layer.bounds), CGRectGetMidY(_qrPreview.layer.bounds));
    [_qrPreview.layer addSublayer:_videoPreviewLayer];
    
    self.targetLayer = [CALayer layer];
    self.targetLayer.frame = _qrPreview.layer.bounds;
    [_qrPreview.layer insertSublayer:self.targetLayer above:_videoPreviewLayer];
    
    [_captureSession startRunning];
    
    return YES;
}

- (void)stopQRReading
{
    [_captureSession stopRunning];
    _captureSession = nil;
    [_videoPreviewLayer removeFromSuperlayer];
    
}

- (void)prepareQRDataFromString:(NSString *)qrDataString;
{
    
    if ([CSRUtilities isString:qrDataString containsCharacters:@"https://mesh.example.com"]) {
        qrDataString = [qrDataString substringFromIndex:29];
    } else {
        qrDataString = [qrDataString substringFromIndex:1];
    }
    
    NSMutableArray *qrDataArray = [NSMutableArray arrayWithArray:[qrDataString componentsSeparatedByString:@"&"]];
    NSLog(@"qrDataArray: %@", qrDataArray);
    
    
    for (NSString *string in qrDataArray) {
        
        if ([CSRUtilities isString:string containsCharacters:@"UUID="]) {
            
            NSRange range = [string rangeOfString:@"UUID="];
            _uuidStringFromQRScan = [string substringFromIndex:range.length];
            NSLog(@"uuidString: %@", _uuidStringFromQRScan);
            
        } else if ([CSRUtilities isString:string containsCharacters:@"AC="]) {
            
            NSRange range = [string rangeOfString:@"AC="];
            _acStringFromQRScan = [string substringFromIndex:range.length];
            NSLog(@"acString: %@", _acStringFromQRScan);
            
        } else {
            
            _uuidStringFromQRScan = @"";
            _acStringFromQRScan = @"";
            
        }
        
    }
    
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate method

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    
    _qrCodeObjects = [NSMutableArray new];
    
    for (AVMetadataObject *metadataObject in metadataObjects) {
        
        AVMetadataObject *transformedObject = [_videoPreviewLayer transformedMetadataObjectForMetadataObject:metadataObject];
        [_qrCodeObjects addObject:transformedObject];
    }
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        // Get the metadata object.
        
        AVMetadataMachineReadableCodeObject *metaDataObject = [metadataObjects objectAtIndex:0];
        
        if ([[metaDataObject type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            // If the found metadata is equal to the QR code metadata then update the status label's text,
            // stop reading and change the bar button item's title and the flag's value.
            // Everything is done on the main thread.
            
            NSLog(@"metaDataObject: %@", [metaDataObject stringValue]);
            
            [self performSelectorOnMainThread:@selector(prepareQRDataFromString:) withObject:[metaDataObject stringValue] waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:YES];
            [_qrTriggerButton performSelectorOnMainThread:@selector(setTitle:) withObject:@"Scan again" waitUntilDone:NO];
            
            _qrTriggerButton.accessibilityLabel = @"QRbutton";
            
            _isReading = NO;
        }
        
    }
    
}

#pragma mark - Visual aid methods

- (void)clearTargetLayer
{
    NSArray *sublayers = [[self.targetLayer sublayers] copy];
    for (CALayer *sublayer in sublayers)
    {
        [sublayer removeFromSuperlayer];
    }
}

- (void)showDetectedObjects
{
    for (AVMetadataObject *object in _qrCodeObjects)
    {
        if ([object isKindOfClass:[AVMetadataMachineReadableCodeObject class]])
        {
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.strokeColor = [UIColor redColor].CGColor;
            shapeLayer.fillColor = [UIColor clearColor].CGColor;
            shapeLayer.lineWidth = 2.0;
            shapeLayer.lineJoin = kCALineJoinRound;
            CGPathRef path = createPathForPoints([(AVMetadataMachineReadableCodeObject *)object corners]);
            shapeLayer.path = path;
            CFRelease(path);
            [self.targetLayer addSublayer:shapeLayer];
        }
    }
}

CGMutablePathRef createPathForPoints(NSArray* points)
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPoint point;
    
    if ([points count] > 0)
    {
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)[points objectAtIndex:0], &point);
        CGPathMoveToPoint(path, nil, point.x, point.y);
        
        int i = 1;
        while (i < [points count])
        {
            CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)[points objectAtIndex:i], &point);
            CGPathAddLineToPoint(path, nil, point.x, point.y);
            i++;
        }
        
        CGPathCloseSubpath(path);
    }
    
    return path;
}

- (void)stopReading
{
    
    _associateQRButton.enabled = YES;
    
    [self clearTargetLayer];
    [self showDetectedObjects];
    
    // Stop video capture and make the capture session object nil.
    [_captureSession stopRunning];
    _captureSession = nil;
    
    // Remove the video preview layer from the viewPreview view's layer.
    
    _deviceEntity = nil;
    __block BOOL alreadyPresent = NO;
//    NSArray *devices = [[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"CSRDeviceEntity" withPredicate:nil];
    
    if (_uuidStringFromQRScan && ![CSRUtilities isStringEmpty:_uuidStringFromQRScan] && ![CSRUtilities isStringEmpty:_acStringFromQRScan] && ([CSRUtilities isStringContainsValidHexCharacters:_uuidStringFromQRScan] && [CSRUtilities isStringContainsValidHexCharacters:_acStringFromQRScan]) && [CSRMeshUtilities isStringValidUUIDString:_uuidStringFromQRScan]) {
        
        _successTickboxImageView.image = [CSRmeshStyleKit imageOfIconQRScanOk];
        _scanSuccessView.hidden = NO;
        [_qrTriggerButton setTitle:@"Scan again" forState:UIControlStateNormal];
        
        [[CSRAppStateManager sharedInstance].selectedPlace.devices enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            CSRDeviceEntity *device = (CSRDeviceEntity *)obj;
            if ([[[NSString alloc] initWithData:device.authCode encoding:NSUTF8StringEncoding] isEqualToString:_acStringFromQRScan]) {
                alreadyPresent = YES;
                *stop = YES;
            }
        }];
        
        if (alreadyPresent == NO) {
            
            NSData *acData = [CSRUtilities dataFromHexString:_acStringFromQRScan];
            
            _deviceEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRDeviceEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
            
            [_deviceEntity setUuid:[CSRUtilities dataFromHexString:_uuidStringFromQRScan]];
            [_deviceEntity setAuthCode:acData];
            
            NSData *hashData = [[MeshServiceApi sharedInstance] getDeviceHashFromUuid:[CSRMeshUtilities CBUUIDWithFlatUUIDString:_uuidStringFromQRScan]];
            
            [[CSRDevicesManager sharedInstance] addScannedDevice:[[CSRDevicesManager sharedInstance] addDeviceWithDeviceHash:hashData authCode:acData]];
            
            [_deviceEntity setDeviceHash:hashData];
            [_deviceEntity setDeviceId:[[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"]];
            
            
            [[CSRDatabaseManager sharedInstance] saveContext];
            
        }
        
        _associateQRButton.enabled = YES;
        
    } else {
        
        //Alert view or something
        
        _successTickboxImageView.image = [CSRmeshStyleKit imageOfIconQRScanFail];
        _scanSuccessView.hidden = NO;
        [_qrTriggerButton setTitle:@"Scan again" forState:UIControlStateNormal];
        
        _associateQRButton.enabled = NO;
        
    }
    
    
}

#pragma mark - Actions

- (IBAction)back:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)toggleQRScan:(id)sender
{
    if (!_isReading) {
        
        if ([self startQRReading]) {
            
            [_qrTriggerButton setTitle:@"Scan again" forState:UIControlStateNormal];
            
        }
        
    } else {
        
        [self startQRReading];
        [_qrTriggerButton setTitle:@"Scan again" forState:UIControlStateNormal];
        
    }
    _isReading = !_isReading;
}

- (IBAction)cancelAll:(id)sender
{
    [[[CSRDevicesManager sharedInstance] unassociatedMeshDevices] removeAllObjects];
    _deviceEntity = nil;
    _selectedDevice = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCSRmeshManagerDidDiscoverDeviceNotification object:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender
{
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Association actions

- (IBAction)qrScanAssociate:(id)sender
{
    
    _scanSuccessView.hidden = YES;
    
    NSData *hashData = [[MeshServiceApi sharedInstance] getDeviceHashFromUuid:[CSRMeshUtilities CBUUIDWithFlatUUIDString:_uuidStringFromQRScan]];
    
//    NSLog(@"UUID: %@\nCBUUID: %@", _uuidStringFromQRScan, [CSRMeshUtilities CBUUIDWithFlatUUIDString:_uuidStringFromQRScan].UUIDString);
    
//    NSLog(@"hash data: %@", hashData);
    
    wizardMode = CSRWizardPopoverMode_AssociationFromQRScan;
    deviceHash = hashData;
    authCode = [CSRUtilities dataFromHexString:_acStringFromQRScan];
    
    [self performSegueWithIdentifier:@"wizardPopoverSegue" sender:self];
    
}

#pragma mark - Steps animation

- (void)animateStepsBetweenFirstView:(UIView *)firstView andSecondView:(UIView *)secondView
{
    
    [secondView setTransform:(CGAffineTransformMakeScale(0.8f, 0.8f))];
    secondView.alpha = 0.f;
    secondView.hidden = NO;
    
    [UIView animateWithDuration:0.5
                          delay:0.1
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         firstView.alpha = 0.f;
                         [firstView setTransform:(CGAffineTransformMakeScale(1.2f, 1.2f))];
                         
                         secondView.alpha = 1.f;
                         [secondView setTransform:(CGAffineTransformMakeScale(1.0f, 1.0f))];
                         
                     } completion:^(BOOL finished) {
                         firstView.hidden = YES;
                         
                     }];
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Notifications handlers

-(void)didDiscoverDeviceNotification:(NSNotification *)notification
{
    if (![self alreadyDiscoveredDeviceFilteringWithDeviceUUID:(NSUUID *)notification.userInfo[kDeviceUuidString]]) {
        [[CSRDevicesManager sharedInstance] addDeviceWithUUID:notification.userInfo [kDeviceUuidString] andRSSI:notification.userInfo [kDeviceRssiString]];
        
    }
}

- (void)didUpdateAppearanceNotification:(NSNotification *)notification
{
    NSData *updatedDeviceHash = notification.userInfo [kDeviceHashString];
    NSNumber *appearanceValue = notification.userInfo [kAppearanceValueString];
    NSData *shortName = notification.userInfo [kShortNameString];
    
    [[CSRDevicesManager sharedInstance] updateAppearance:updatedDeviceHash appearanceValue:appearanceValue shortName:shortName];
}


#pragma mark - Device filtering

- (BOOL)alreadyDiscoveredDeviceFilteringWithDeviceUUID:(NSUUID *)uuid
{
    for (id value in [[CSRDevicesManager sharedInstance] unassociatedMeshDevices]) {
        if ([value isKindOfClass:[CSRmeshDevice class]]) {
            CSRmeshDevice *device = value;
            if ([device.uuid.UUIDString isEqualToString:uuid.UUIDString]) {
                return YES;
            }
        }
    }
    
    return NO;
}



#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([segue.identifier isEqualToString:@"wizardPopoverSegue"]) {
        
        CSRWizardPopoverViewController *vc = segue.destinationViewController;
        vc.mode = wizardMode;
        vc.meshDevice = _selectedDevice;
        vc.authCode = authCode;
        vc.deviceHash = deviceHash;
        
        vc.deviceDelegate = self;
        
        vc.popoverPresentationController.delegate = self;
        vc.popoverPresentationController.presentedViewController.view.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        vc.popoverPresentationController.presentedViewController.view.layer.borderWidth = 0.5;
        
        vc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20., 150.);
    }
    if ([segue.identifier isEqualToString:@"editAssociatedDevice"]) {
        CSRDeviceDetailsViewController *vc = segue.destinationViewController;
        vc.deviceEntity = _deviceEntity;
        
    }
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // Return no adaptive presentation style, use default presentation behaviour
    return UIModalPresentationNone;
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return NO;
}

@end
