//
//  JoinPlaceViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/15.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "JoinPlaceViewController.h"
#import "CSRPlaceEntity.h"
#import "CSRDatabaseManager.h"
#import <CSRmesh/MeshServiceApi.h>
#import "CSRConstants.h"
#import "CSRUtilities.h"
#import "CSRAppStateManager.h"
#import "PlaceDetailsViewController.h"

@interface JoinPlaceViewController ()
{
    NSMutableData *allData;
}

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) CSRPlaceEntity *placeEntity;

@end

@implementation JoinPlaceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Looking for a place to join";
    _managedObjectContext = [CSRDatabaseManager sharedInstance].managedObjectContext;
    
    allData = [[NSMutableData alloc] init];
    
    _pinLabel.text = [NSString stringWithFormat:@"%i", arc4random() % 9000 + 1000];
    _successLabel.hidden = YES;
    _okButton.hidden = YES;
    _okImageView.hidden = YES;
    
    
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startAdvertiseForAssociation];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[MeshServiceApi sharedInstance] stopAdvertisingForAssociation];
}

- (void) startAdvertiseForAssociation
{
    //uuid
    uint8_t deviceChar [] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15};
    NSData *randomUUID = [NSData dataWithBytes:&deviceChar length:sizeof(deviceChar)];
    CBUUID *uuid = [CBUUID UUIDWithData:randomUUID];
    
    //authcode
    NSData *authCode = [CSRUtilities authCodefromString:_pinLabel.text];
    
    //appearence and shortName
    NSNumber *appearance = @(CSRApperanceNameController);
    NSString *shortName = @"Ctrl";
    
    [[MeshServiceApi sharedInstance] advertiseForAssociation:uuid
                                           authorisationCode:authCode
                                                  appearance:appearance
                                                   shortName:shortName
                                                     success:^(NSNumber *deviceId, NSData *deviceHash, NSData *networkKey, NSData *dhmKey, NSNumber *meshRequestId) {
                                                         
                                                         [self hideSubViews];
                                                         
                                                         _placeEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRPlaceEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                                                         
                                                         _placeEntity.name = @"New Place";
                                                         _placeEntity.networkKey = networkKey;
                                                         _placeEntity.passPhrase = nil;
                                                         _placeEntity.color = @([CSRUtilities rgbFromColor:[UIColor redColor]]);
                                                         _placeEntity.iconID = @(1);
                                                         _placeEntity.owner = @"My place";
                                                         _placeEntity.hostControllerID = deviceId;
                                                         
                                                         [[CSRAppStateManager sharedInstance] setSelectedPlace:_placeEntity];
                                                         
                                                         [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
                                                         [[CSRAppStateManager sharedInstance] setupPlace];
                                                         [[CSRDatabaseManager sharedInstance] saveContext];
                                                         
                                                         [[MeshServiceApi sharedInstance] setControllerAddress:deviceId];
                                                         
                                                         
                                                     } progress:^(NSData *deviceHash, NSNumber *stepsCompleted, NSNumber *totalSteps, NSNumber *meshRequestId) {
                                                         if (totalSteps.intValue > stepsCompleted.intValue || ([totalSteps isEqualToNumber:stepsCompleted])) {
                                                             UIAlertController *alertController = [UIAlertController
                                                                                                   alertControllerWithTitle:@"Association Progress\n\n\n"
                                                                                                   message:nil
                                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                                                             UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                                style:UIAlertActionStyleDefault
                                                                                                              handler:^(UIAlertAction *action) {
                                                                                                                  
                                                                                                              }];
                                                             [alertController addAction:okAction];
                                                             //Progress Bar
                                                             //                                                             UIProgressView *pv = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
                                                             //                                                             pv.frame = CGRectMake(20, 100, 200, 30);
                                                             //                                                             pv.progress = ([stepsCompleted floatValue] / [totalSteps floatValue]);
                                                             //                                                             [alertController.view addSubview:pv];
                                                             
                                                             //Spinner
                                                             UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                                                             spinner.center = CGPointMake(130.5, 65.5);
                                                             spinner.color = [UIColor blackColor];
                                                             [spinner startAnimating];
                                                             [alertController.view addSubview:spinner];
                                                             
                                                             [self presentViewController:alertController animated:YES completion:nil];
                                                             NSLog(@"stepsCompleted :%@ of totalSteps :%@", stepsCompleted, totalSteps);
                                                             if ([stepsCompleted isEqualToNumber:totalSteps]) {
                                                                 [self dismissViewControllerAnimated:YES completion:nil];
                                                             }
                                                         }
                                                         
                                                     } failure:^(NSError *error) {
                                                         UIAlertController *alertController = [UIAlertController
                                                                                               alertControllerWithTitle:@"Failed Associating"
                                                                                               message:[error localizedDescription]
                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                                         UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                            style:UIAlertActionStyleDefault
                                                                                                          handler:^(UIAlertAction *action) {
                                                                                                              
                                                                                                          }];
                                                         
                                                         [alertController addAction:okAction];
                                                         [self presentViewController:alertController animated:YES completion:nil];
                                                         
                                                     }];
}

- (void) hideSubViews
{
    self.title = @"Place joined";
    
    _placefoundLabel.hidden = YES;
    _infoLabel.hidden = YES;
    _pinLabel.hidden = YES;
    
    _successLabel.hidden = NO;
    _okButton.hidden = NO;
    _okImageView.hidden = NO;
}

- (IBAction)okAction:(UIButton *)sender {
    PlaceDetailsViewController *pdvc = [[PlaceDetailsViewController alloc] init];
    
    pdvc.placeEntity = _placeEntity;
    [self.navigationController pushViewController:pdvc animated:YES];
}

@end
