//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSRJoinPlaceVC.h"
#import "CSRConstants.h"
#import "CSRDevicesManager.h"
#import "CSRUtilities.h"
#import "CSRDatabaseManager.h"
#import "CSRDeviceEntity.h"
#import "CSRAppStateManager.h"
#import "CSRParseAndLoad.h"
#import "CSRReceivingDataProgressVC.h"
#import "CSRPlaceDetailsViewController.h"
#import "CSRParseAndLoad.h"

@interface CSRJoinPlaceVC () {
    NSMutableData *allData;
}

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) CSRPlaceEntity *placeEntity;

@end

@implementation CSRJoinPlaceVC

- (void)viewDidLoad {
    [super viewDidLoad];

    _managedObjectContext = [CSRDatabaseManager sharedInstance].managedObjectContext;
    
    allData = [[NSMutableData alloc] init];
    
    _pinLabel.text = [NSString stringWithFormat:@"%i", arc4random() % 9000 + 1000];
    _successTextView.hidden = YES;
    _okButton.hidden = YES;
    _okImageView.hidden = YES;
    
    [self startAdvertiseForAssociation];
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
    _infoTextView.hidden = YES;
    _activityIndicator.hidden = YES;
    _pinLabel.hidden = YES;
    
    _successTextView.hidden = NO;
    _okButton.hidden = NO;
    _okImageView.hidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)okAction:(id)sender {
    
//    [self performSegueWithIdentifier:@"joinedPlaceDetails" sender:self];
    
}

- (IBAction)backAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

//- (void)didReceiveStreamData:(NSNumber *)deviceId streamNumber:(NSNumber *)streamNumber data:(NSData *)data
//{
//    [self performSegueWithIdentifier:@"receivingProgressSegue" sender:nil];
//    
//    if (data) {
//        [allData appendData:data];
//    }
//}
//
//- (void)didReceiveStreamDataEnd:(NSNumber *)deviceId streamNumber:(NSNumber *)streamNumber
//{
//    NSError *error;
//    NSData *uncompressedData = [CSRUtilities uncompressGZip:allData];
//
//    NSDictionary *jsonDictionary;
//    if (uncompressedData) {
//        jsonDictionary = [NSJSONSerialization JSONObjectWithData:uncompressedData options:NSJSONReadingMutableLeaves error:&error];
//    }
//    
//    if (!error && jsonDictionary) {
//        CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
//        //TODO:  Check if we receive the data stream here
////        [parseLoad deComposeDatabase:jsonDictionary];
//    }else {
//        NSLog(@"%@", [error localizedDescription]);
//    }
//    
//    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
//}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return YES;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//    if ([segue.identifier isEqualToString:@"receivingProgressSegue"]) {
//        CSRReceivingDataProgressVC *vc = segue.destinationViewController;
//        vc.popoverPresentationController.delegate = self;
//        vc.popoverPresentationController.presentedViewController.view.layer.borderColor = [[UIColor lightGrayColor] CGColor];
//        vc.popoverPresentationController.presentedViewController.view.layer.borderWidth = 0.5;
//        vc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20, 190);
//        
//    } else
    if ([segue.identifier isEqualToString:@"joinedPlaceDetails"]) {
//        UINavigationController *navController = (UINavigationController*)[segue destinationViewController];
        CSRPlaceDetailsViewController *vc = [segue destinationViewController];
        vc.placeEntity = _placeEntity;

    }
}

@end
