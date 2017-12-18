//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSRControllerAssociationVC.h"
#import "CSRDevicesManager.h"
#import "CSRUtilities.h"
#import "CSRConstants.h"
#import "CSRDatabaseManager.h"
#import "CSRControllerDetailsVC.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceEntity.h"
#import "CSRPlaceEntity.h"
#import "CSRParseAndLoad.h"
#import "CSRmeshStyleKit.h"
#import "ZipArchive.h"
#import "AppDelegate.h"

@interface CSRControllerAssociationVC () {
    
    CSRControllerEntity *controllerEntity;
    NSNumber *devId;
    NSURL *_importedURL;
}

@property (nonatomic, retain) CSRPlaceEntity *placeEntity;

@end

@implementation CSRControllerAssociationVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _pinTextField.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceAssociationSuccess:)
                                                 name:kCSRmeshManagerDidAssociateDeviceNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayAssociationProgress:)
                                                 name:kCSRmeshManagerDeviceAssociationProgressNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceAssociationFailed:)
                                                 name:kCSRmeshManagerDeviceAssociationFailedNotification
                                               object:nil];
    
    controllerEntity = nil;
    _successImageView.image = [CSRmeshStyleKit imageOfIconOk];
    _failureImageView.image = [CSRmeshStyleKit imageOfIconCancel];
    
//    _importedURL = ((AppDelegate*)[UIApplication sharedApplication].delegate).passingURL;
}


#pragma mark - Notifications handlers

- (void)deviceAssociationSuccess:(NSNotification *)notification
{
    devId = notification.userInfo[kDeviceIdString];
    
    [self animateStepsBetweenFirstView:_progressView andSecondView:_successView];

    controllerEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRControllerEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    
    if (controllerEntity) {
        
        controllerEntity.deviceId = devId;
        controllerEntity.deviceHash = _meshDevice.deviceHash;
        controllerEntity.controllerName = [[NSString alloc] initWithData:_meshDevice.appearanceShortname encoding:NSUTF8StringEncoding];
        NSData *authCode = [CSRUtilities authCodefromString:_pinTextField.text];
        controllerEntity.authCode = authCode;
        controllerEntity.isAssociated = @(YES);
        controllerEntity.uuid = [_meshDevice.uuid data];
        controllerEntity.updateDate = [NSDate date];
        [[CSRAppStateManager sharedInstance].selectedPlace addControllersObject:controllerEntity];
    }
    [[CSRDatabaseManager sharedInstance] saveContext];
}

- (void)deviceAssociationFailed:(NSNotification *)notification
{
    _associationStepsInfoLabel.text = [NSString stringWithFormat:@"Association error: %@", notification.userInfo[@"error"]];

    _successView.hidden = YES;

    [self animateStepsBetweenFirstView:_progressView andSecondView:_failureView];
}

- (void)displayAssociationProgress:(NSNotification *)notification
{
    NSNumber *completedSteps = notification.userInfo[@"stepsCompleted"];
    NSNumber *totalSteps = notification.userInfo[@"totalSteps"];
    
    if ([completedSteps floatValue] <= [totalSteps floatValue] && [completedSteps floatValue] > 0) {
        
        _associationStepsInfoLabel.text = [NSString stringWithFormat:@"Associating device: %.0f%%", ([completedSteps floatValue]/[totalSteps floatValue] * 100)];
        _associationProgressView.progress = ([completedSteps floatValue] / [totalSteps floatValue]);
        
    } else {
        
        NSLog(@"ERROR: There was and issue with device association");
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)cancelAssociationAction:(id)sender {
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)associateAction:(id)sender {
    
    NSMutableArray *ctrlsHashes = [NSMutableArray new];
    NSSet *controllersSet = [CSRAppStateManager sharedInstance].selectedPlace.controllers;
    for (CSRControllerEntity *ctrl in controllersSet) {
        [ctrlsHashes addObject:ctrl.deviceHash];
    }
    
    NSData *authCode = [CSRUtilities authCodefromString:_pinTextField.text];
    if (![ctrlsHashes containsObject:_meshDevice.deviceHash]) {
        
        [[CSRDevicesManager sharedInstance] associateDeviceFromCSRDeviceManager:_meshDevice.deviceHash authorisationCode:authCode];
        [self animateStepsBetweenFirstView:_pinView andSecondView:_progressView];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Already Associated"
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             
                                                         }];
        
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
    }
}


#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return NO;
}

- (IBAction)cancelAssociationInProgressView:(id)sender {
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)cancelFailureView:(id)sender {
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)tryAgainForAssociationAction:(id)sender {
    
    NSData *authCode = [CSRUtilities authCodefromString:_pinTextField.text];
    [[CSRDevicesManager sharedInstance] associateDeviceFromCSRDeviceManager:_meshDevice.deviceHash authorisationCode:authCode];

    [self animateStepsBetweenFirstView:_failureView andSecondView:_progressView];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)doneAssociationAction:(id)sender {

    [_controllerDelegate dismissAndPush:controllerEntity];
    [self dismissViewControllerAnimated:NO completion:nil];
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

- (IBAction)chooseAppMethod:(id)sender
{
    //TODO: segue to detail view and present UIActivityViewController
    CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
    NSData *jsonData = [parseLoad composeDatabase];
    
    NSError *error;
    NSString *jsonString;
    if (jsonData) {
        jsonString = [CSRUtilities stringFromData:jsonData];
    } else {
        NSLog(@"Got an error while NSJSONSerialization:%@", error);
    }
    
    CSRPlaceEntity *placeEntity = [[CSRAppStateManager sharedInstance] selectedPlace];
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* dPath = [paths objectAtIndex:0];
    NSString* zipfile = [dPath stringByAppendingPathComponent:@"test.zip"] ;
    
    NSString *appFile = [NSString stringWithFormat:@"%@_%@", placeEntity.name, @"Database.qti"];
    NSString *realPath = [dPath stringByAppendingPathComponent:appFile] ;
    [jsonString writeToFile:realPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    
    ZipArchive* zip = [[ZipArchive alloc] init];
    if([zip CreateZipFile2:zipfile Password:[[MeshServiceApi sharedInstance] getMeshId]])
    {
        NSLog(@"Zip File Created");
        if([zip addFileToZip:realPath newname:@"MyFile.qti"])
        {
            NSLog(@"File Added to zip");
        }
    }
    
    NSURL *jsonURL = [NSURL fileURLWithPath:zipfile];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[jsonURL] applicationActivities:nil];
    [activityVC setValue:@"JSON Attached" forKey:@"subject"];
    
    activityVC.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        if (completed) {
            NSLog(@"Activity completed");
        } else {
            if (activityType == NULL) {
                NSLog(@"User dismissed the view controller without making a selection");
            } else {
                NSLog(@"Activity was not performed");
            }
        }
    };
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.parent presentViewController:activityVC animated:YES completion:nil];
}

@end
