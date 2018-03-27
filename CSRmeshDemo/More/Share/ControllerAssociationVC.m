//
//  ControllerAssociationVC.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/16.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "ControllerAssociationVC.h"
#import "CSRAppStateManager.h"
#import "CSRUtilities.h"
#import "CSRDevicesManager.h"
#import "CSRmeshStyleKit.h"
#import "AppDelegate.h"
#import "CSRDatabaseManager.h"

@interface ControllerAssociationVC ()<UITextFieldDelegate>{
    
    CSRControllerEntity *controllerEntity;
    NSNumber *devId;
    NSURL *_importedURL;
}

@property (nonatomic, retain) CSRPlaceEntity *placeEntity;

@end

@implementation ControllerAssociationVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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
    _importedURL = ((AppDelegate*)[UIApplication sharedApplication].delegate).passingURL;
}

- (IBAction)cancelAssociationAction:(UIButton *)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelAssociationInProgressView:(UIButton *)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)cancelFailureView:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneAssociationAction:(UIButton *)sender {
    if (self.controllerDelegate && [self.controllerDelegate respondsToSelector:@selector(dismissAndPush:)]) {
        [self.controllerDelegate dismissAndPush:controllerEntity];
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (IBAction)tryAgainForAssociationAction:(UIButton *)sender {
    NSData *authCode = [CSRUtilities authCodefromString:_pinTextField.text];
    [[CSRDevicesManager sharedInstance] associateDeviceFromCSRDeviceManager:_meshDevice.deviceHash authorisationCode:authCode];
    
    [self animateStepsBetweenFirstView:_failureView andSecondView:_progressView];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
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

#pragma mark - Notifications handlers

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

- (void)deviceAssociationFailed:(NSNotification *)notification
{
    _associationStepsInfoLabel.text = [NSString stringWithFormat:@"Association error: %@", notification.userInfo[@"error"]];
    
    _successView.hidden = YES;
    
    [self animateStepsBetweenFirstView:_progressView andSecondView:_failureView];
}

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

@end
