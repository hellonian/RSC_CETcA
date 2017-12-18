//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRWizardPopoverViewController.h"
#import "CSRmeshStyleKit.h"
#import "CSRUtilities.h"
#import "CSRMeshUtilities.h"
#import "CSRConstants.h"
#import "CSRBluetoothLE.h"
#import "CSRDevicesManager.h"
#import "CSRmeshSettings.h"
#import "CSRDatabaseManager.h"
#import "CSRAppStateManager.h"
#import "CSRDatabaseManager.h"
#import "CSRBluetoothLE.h"

@interface CSRWizardPopoverViewController () <UITextFieldDelegate>
{
    BOOL isAssociationInProgress;
    BOOL isAssociationFinished;
    NSNumber *meshRequestId;
}

@property (nonatomic, weak) CSRmeshDevice *meshDeviceInAttentation;

@end

@implementation CSRWizardPopoverViewController


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set text field delegates
    _shortCodeTextField.delegate = self;
    _authorisationCodeSecurityTextField.delegate = self;
    
    _associationProgressView.progress = 0;
    
    //Set textfields input
    _shortCodeTextField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    _authorisationCodeSecurityTextField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceAssociationSuccess:)
                                                 name:kCSRmeshManagerDidAssociateDeviceNotification //kCSRmeshManagerDidAssociateDeviceNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceAssociationFailed:)
                                                 name:kCSRmeshManagerDeviceAssociationFailedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayAssociationProgress:)
                                                 name:kCSRmeshManagerDeviceAssociationProgressNotification
                                               object:nil];
    
    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDiscoverDeviceNotification:)
                                                 name:kCSRmeshManagerDidDiscoverDeviceNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateAppearanceNotification:)
                                                 name:kCSRmeshManagerDidUpdateAppearanceNotification
                                               object:nil];


    [self hideAllViews];
    [self showScreensWithMode:_mode];
    
}

-(void)didDiscoverDeviceNotification:(NSNotification *)notification
{
    [[CSRDevicesManager sharedInstance] addDeviceWithUUID:notification.userInfo [kDeviceUuidString] andRSSI:notification.userInfo [kDeviceRssiString]];
        
}

- (void)didUpdateAppearanceNotification:(NSNotification *)notification
{
    NSData *updatedDeviceHash = notification.userInfo [kDeviceHashString];
    NSNumber *appearanceValue = notification.userInfo [kAppearanceValueString];
    NSData *shortName = notification.userInfo [kShortNameString];
//    if (![self alreadyDiscoveredDeviceFilteringWithDeviceHash:notification.userInfo[kDeviceHashString]]) {
        [[CSRDevicesManager sharedInstance] updateAppearance:updatedDeviceHash appearanceValue:appearanceValue shortName:shortName];
//    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.superview.layer.cornerRadius = 0;
    
    // Start the BLE scan
//    [[MeshServiceApi sharedInstance] setContinuousLeScanEnabled:YES];
//    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[CSRDevicesManager sharedInstance].unassociatedMeshDevices removeAllObjects];
    // Stop the BLE scan
    [[CSRBluetoothLE sharedInstance]setScanner:NO source:self];
    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:NO];
}


- (void)dealloc
{
    self.view = nil;
}

#pragma mark - Screens/Views configuration

- (void)hideAllViews
{
    
    for (UIView *view in self.view.subviews) {
        view.hidden = YES;
    }
}

- (void)showScreensWithMode:(CSRWizardPopoverMode)mode
{
    
    switch (mode) {
            
        case CSRWizardPopoverMode_ShortCode:
        {
            _shortCodeView.hidden = NO;
        }
            break;
            
        case CSRWizardPopoverMode_SecurityCode:
        {
            _securityCodeView.hidden = NO;
        }
            break;
            
        case CSRWizardPopoverMode_AssociationFromDeviceList:
        {
            _associationView.hidden = NO;
            [CSRDevicesManager sharedInstance].isDeviceTypeGateway = NO;
            if (_meshDevice.appearanceShortname) {
                [[CSRDevicesManager sharedInstance] associateDeviceFromCSRDeviceManager:_meshDevice.deviceHash authorisationCode:_authCode];
            }
        }
            break;
            
        case CSRWizardPopoverMode_AssociationFromQRScan:
        {
            _associationView.hidden = NO;
            CSRmeshDevice *meshDevice = [[CSRDevicesManager sharedInstance] addDeviceWithDeviceHash:_deviceHash authCode:_authCode];
            
            if (meshDevice) {
                //If the mesh device has short name then start association
                //If there is no short name, don't associate
                if (meshDevice.appearanceShortname) {
                    isAssociationInProgress = YES;
                    [meshDevice startAssociation];
                }
            }
        }
            break;
            
        default:
            break;
    }
    
}

#pragma mark - Actions

- (IBAction)cancelAll:(id)sender
{

    if (isAssociationInProgress && (meshRequestId && [meshRequestId intValue] != 0)) {
        
        [[MeshServiceApi sharedInstance] cancelTransaction:meshRequestId];
        
    }
    
    
    [[[CSRDevicesManager sharedInstance] unassociatedMeshDevices] removeAllObjects];
    _deviceEntity = nil;
    _meshDevice = nil;
    _authCode = nil;
    _deviceHash = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDidDiscoverDeviceNotification
                                                  object:nil];
    
    [self dismissViewControllerAnimated:YES
                             completion:nil];
    
}

- (IBAction)securityNext:(id)sender
{
    
    if (![self validateActionWithMode:CSRWizardPopoverValidationMode_Security]) {
        
        [self showAlertViewControllerWithMessage:kAddWizardValidationMessage_Security];
        
    } else {
        
        [self animateStepsBetweenFirstView:_securityCodeView andSecondView:_associationView];
        
        if ([CSRUtilities isStringEmpty:_authorisationCodeSecurityTextField.text]) {
            
            [CSRDevicesManager sharedInstance].isDeviceTypeGateway = NO;
            if (_meshDevice.appearanceShortname) {
                [[CSRDevicesManager sharedInstance] associateDeviceFromCSRDeviceManager:_meshDevice.deviceHash authorisationCode:nil];
            }
            //save the authcode to database
            
            
        } else {
            
            [CSRDevicesManager sharedInstance].isDeviceTypeGateway = NO;
            if (_meshDevice.appearanceShortname) {
                NSData *authData = [CSRUtilities dataFromHexString:_authorisationCodeSecurityTextField.text];
                if (authData.length != 0 && authData.length != 8) {
                    NSMutableData *dummydata = [NSMutableData dataWithData:authData];
                    if (dummydata.length < 8) {
                        uint8_t dummyByte [] = {0,0,0,0,0,0,0,0};
                        [dummydata appendBytes:dummyByte length:8-dummydata.length];
                        authData = dummydata;
                    } else {
                        authData = [dummydata subdataWithRange:NSMakeRange(0, 8)];
                    }
                }
                [[CSRDevicesManager sharedInstance] associateDeviceFromCSRDeviceManager:_meshDevice.deviceHash authorisationCode:authData];
                
                
                
            }
            
        }
        
    }
    
}

- (IBAction)shortCodeNext:(id)sender
{
#warning If we pass a invalid short code the below method is going bonkers...
    //    _shortCodeTextField.text = [CSRMeshUtilities shortCodeFromString:_shortCodeTextField.text];
    
    NSData *hashData;
    NSData *authCode;
    
    if (![CSRUtilities isStringEmpty:_shortCodeTextField.text]) {
        hashData   = [[MeshServiceApi sharedInstance] getDeviceHashFromShortCode:_shortCodeTextField.text];
        authCode  = [[MeshServiceApi sharedInstance] getAuthorizationCode:_shortCodeTextField.text];
    }
    if (hashData && authCode) {
        [self animateStepsBetweenFirstView:_shortCodeView andSecondView:_associationView];
        [CSRDevicesManager sharedInstance].isDeviceTypeGateway = NO;
        CSRmeshDevice *meshDevice = [[CSRDevicesManager sharedInstance] getDeviceWithDevicePredicate:hashData];
        if (meshDevice.appearanceShortname) {
            [[CSRDevicesManager sharedInstance] associateDeviceFromCSRDeviceManager:hashData authorisationCode:authCode];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert!"
                                                            message:@"Short Name is not available."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
            [alert show];

        }
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid!"
                                                        message:@"Please enter a valid Shortcode."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
    
    
    //    CSRDeviceEntity *devEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRDeviceEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    //
    //    [devEntity setAuthCode:authCode];
    //    [devEntity setDeviceHash:hashData];
    //    [devEntity setDeviceId:[[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"]];
    //    [[CSRDatabaseManager sharedInstance] saveContext];
    
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

#pragma mark - Validation

- (BOOL)validateActionWithMode:(CSRWizardPopoverValidationMode)mode
{
    BOOL isPassed = NO;
    
    switch (mode) {
            
        case CSRWizardPopoverValidationMode_Security:
            isPassed = YES;
            break;
            
        case CSRWizardPopoverValidationMode_ShortCode:
            if (![CSRUtilities isStringEmpty:_shortCodeTextField.text]) {
                isPassed = YES;
            }
            break;
            
        default:
            break;
    }
    
    return isPassed;
    
}

#pragma mark - Validation Alert controller

- (void)showAlertViewControllerWithMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Validation"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                         }];
    
    
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark - Notifications handlers

- (void)deviceAssociationSuccess:(NSNotification *)notification
{
    isAssociationInProgress = NO;
    
    NSNumber *deviceID = notification.userInfo[kDeviceIdString];
    _deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceID];
    
    [self dismissViewControllerAnimated:NO completion:nil];
    [_deviceDelegate dismissAndPush:_deviceEntity];
    
}

- (BOOL)alreadyDiscoveredDeviceFilteringWithDeviceHash:(NSData *)data
{
    for (id value in [[CSRDevicesManager sharedInstance] unassociatedMeshDevices]) {
        if ([value isKindOfClass:[CSRmeshDevice class]]) {
            CSRmeshDevice *device = value;
            if ([device.deviceHash isEqualToData:data]) {
                return YES;
            }
        }
    }
    
    return NO;
}


- (void)deviceAssociationFailed:(NSNotification *)notification
{
    _associationStepsInfoLabel.text = [NSString stringWithFormat:@"Association error: %@", notification.userInfo[@"error"]];
}

- (void)displayAssociationProgress:(NSNotification *)notification
{
    
    NSNumber *completedSteps = notification.userInfo[@"stepsCompleted"];
    NSNumber *totalSteps = notification.userInfo[@"totalSteps"];
    meshRequestId = notification.userInfo[@"meshRequestId"];
    
    if ([completedSteps floatValue] <= [totalSteps floatValue] && [completedSteps floatValue] > 0) {
        
        _associationStepsInfoLabel.text = [NSString stringWithFormat:@"Associating device: %.0f%%", ([completedSteps floatValue]/[totalSteps floatValue] * 100)];
        _associationProgressView.progress = ([completedSteps floatValue] / [totalSteps floatValue]);
        
    } else {
        
        NSLog(@"ERROR: There was and issue with device association");
        
    }
    
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

@end
