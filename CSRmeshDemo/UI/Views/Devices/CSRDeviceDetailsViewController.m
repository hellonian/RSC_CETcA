//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRDeviceDetailsViewController.h"
#import "CSRAppStateManager.h"
#import "CSRDatabaseManager.h"
#import "CSRDeviceEntity.h"
#import "CSRmeshStyleKit.h"
#import "CSRUtilities.h"
#import "CSRDevicesManager.h"
#import "CSRAreaSelectionViewController.h"
#import "CSRDeviceSelectionTableViewCell.h"
#import <CSRmesh/BatteryModelApi.h>
#import <CSRmesh/AttentionModelApi.h>
#import <CSRmesh/ConfigModelApi.h>
#import <CSRmesh/DataModelApi.h>
#import <CSRmesh/FirmwareModelApi.h>
#import "CSRDeviceTableViewCell.h"
#import "CSRDeviceDetailsTableViewCell.h"
#import <CSRmeshRestClient/CSRRestAttentionModelApi.h>
#import <CSRmesh/BeaconProxyModelApi.h>
#import <CSRmesh/BeaconModelApi.h>
#import <CSRmesh/ExtensionModelApi.h>
#import <CSRmesh/TuningModelApi.h>
#import <CSRmesh/PingModelApi.h>
#import <CSRmesh/QTIWatchdogModelAPI.h>

@interface CSRDeviceDetailsViewController () <QTIWatchdogModelAPIDelegate>
{
//    id presenter;
}

@property (nonatomic) NSMutableArray *areasArray;
@property (nonatomic, weak) CSRmeshDevice *meshDeviceInAttentation;
@property (nonatomic) BOOL toggleButton;
@property (nonatomic, strong) NSString *batteryLevelString;
@property (nonatomic, strong) NSString *firmwareVersionString;
@property (nonatomic) UIButton *favButton;
@property (nonatomic) UIButton *srtButton;

@property (nonatomic) UIActivityIndicatorView *spinner;

@end

@implementation CSRDeviceDetailsViewController
@synthesize meshDeviceInAttentation;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
    [self.navigationController.interactivePopGestureRecognizer setEnabled:YES];

        //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshView)
                                                 name:kCSRRefreshNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deleteStatus:)
                                                 name:kCSRDeviceManagerDeviceFoundForReset
                                               object:nil];


}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _deviceDetailsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    _areasArray = [NSMutableArray new];

    NSSet *areasSet = _deviceEntity.areas ;
    for (CSRAreaEntity *area in areasSet) {
        [_areasArray addObject:area];
    }

    _deviceTitleTextField.delegate = self;
    
    if (![CSRUtilities isStringEmpty:_deviceEntity.name]) {
        _deviceTitleTextField.text = _deviceEntity.name;
        self.title = _deviceEntity.name;
    }

    if ([_deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameLight)]) {
        _deviceIcon.image = [CSRmeshStyleKit imageOfLightDevice_on];
        _deviceIcon.image = [_deviceIcon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _deviceIcon.tintColor = [UIColor whiteColor];

        _topSectionView.backgroundColor = [CSRUtilities colorFromHex:@"#FEB70D"];
        [self.navigationController.navigationBar setBarTintColor:[CSRUtilities colorFromHex:@"#FEB70D"]];
    } else if ([_deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameSensor)]) {
        _deviceIcon.image = [CSRmeshStyleKit imageOfSensorDevice];
        _topSectionView.backgroundColor = [CSRUtilities colorFromHex:@"#FE997F"];
        [self.navigationController.navigationBar setBarTintColor:[CSRUtilities colorFromHex:@"#FE997F"]];
    } else if ([_deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameHeater)]) {
        _deviceIcon.image = [CSRmeshStyleKit imageOfHeaterDevice];
        _topSectionView.backgroundColor = [CSRUtilities colorFromHex:@"#EA8689"];
        [self.navigationController.navigationBar setBarTintColor:[CSRUtilities colorFromHex:@"#EA8689"]];
    } else if ([_deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameSwitch)]) {
        _deviceIcon.image = [CSRmeshStyleKit imageOfOnOff];
        _topSectionView.backgroundColor = [CSRUtilities colorFromHex:@"#80BEF8"];
        [self.navigationController.navigationBar setBarTintColor:[CSRUtilities colorFromHex:@"#80BEF8"]];
    } else {
        _deviceIcon.image = [CSRmeshStyleKit imageOfLightDevice_on];
        _topSectionView.backgroundColor = [CSRUtilities colorFromHex:@"#409DFF"];
        [self.navigationController.navigationBar setBarTintColor:[CSRUtilities colorFromHex:@"#409DFF"]];
    }
    
    [self getDeviceDetails];
    _toggleButton = YES;
    
    _batteryLevelString = @"Waiting...";
    _firmwareVersionString = @"Waiting...";
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //Clear Notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRDeviceManagerDeviceFoundForReset
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRRefreshNotification
                                                  object:nil];

}


#pragma mark --
#pragma mark Device Details

- (void) getDeviceDetails
{
//    NSNumber *deviceNumber = [_deviceEntity deviceId];
//    
//    
//        [[BatteryModelApi sharedInstance] getState:deviceNumber
//                                           success:^(NSNumber *deviceId, NSNumber *batteryLevel, NSNumber *batteryState) {
//                                               _batteryLevelString = [NSString stringWithFormat:@"%d%%",[batteryLevel unsignedShortValue]];
//                                               [_deviceDetailsTableView reloadData];
//                                               
//                                           } failure:^(NSError *error) {
//                                               NSLog(@"Error :%@", error);
//                                               _batteryLevelString = @"N/A";
//                                               [_deviceDetailsTableView reloadData];
//                                           }];
//    if ([CSRMeshUserManager sharedInstance].bearerType == CSRBearerType_Bluetooth) {
//        
//        [[FirmwareModelApi sharedInstance] getVersionInfo:_deviceEntity.deviceId
//                                                  success:^(NSNumber *deviceId, NSNumber *versionMajor, NSNumber *versionMinor) {
//                                                      _firmwareVersionString = [NSString stringWithFormat:@"%@.%@", versionMajor, versionMinor];
//                                                      [_deviceDetailsTableView reloadData];
//                                                  } failure:^(NSError *error) {
//                                                      NSLog(@"error :%@", error);
//                                                      _firmwareVersionString = @"N/A";
//                                                      [_deviceDetailsTableView reloadData];
//                                                  }];
//    }
}

- (void) refreshView
{
    [_areasArray removeAllObjects];
    
    NSSet *areaSet = _deviceEntity.areas;
    
    for (CSRAreaEntity *area in areaSet) {
        [_areasArray addObject:area];
    }
    
    [self.deviceDetailsTableView reloadData];
}


#pragma mark - Layout Subviews

-(UIImage*) displayFavouriteState :(BOOL) state
{
    if (state) {
        [_favButton setBackgroundImage:[CSRmeshStyleKit imageOfFavourites_on] forState:UIControlStateNormal];
        _favButton.accessibilityLabel = @"Favourites_On";
        return [CSRmeshStyleKit imageOfFavourites_on];
    } else {
        [_favButton setBackgroundImage:[CSRmeshStyleKit imageOfFavourites_off] forState:UIControlStateNormal];
        _favButton.accessibilityLabel = @"Favourites_Off";
        return [CSRmeshStyleKit imageOfFavourites_off];
    }
    return nil;
}


#pragma mark - Button actions

//- (IBAction)saveDeviceConfiguration:(id)sender
//{
//    }


- (IBAction)editAreas:(id)sender
{
    [self performSegueWithIdentifier:@"groupSelectionSegue" sender:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }
    if (section == 1) {
        return 1;
    }
    if (section == 2) {
        return [_areasArray count];
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }
    if (section == 1) {
        return 30;
    }
    if (section == 2) {
        return 30;
    }
    return 0;
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 1)];
        return view;
    }
    if (section == 1) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 5, tableView.frame.size.width/2, 18)];
        [label setText:@"DETAILS"];
        label.backgroundColor=[UIColor clearColor];
        label.textColor = [UIColor orangeColor];;
        [view addSubview:label];

        return view;
    }
    if (section == 2) {
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 5, tableView.frame.size.width/2, 18)];
        [label setText:@"AREAS"];
        label.backgroundColor=[UIColor clearColor];
        label.textColor = [UIColor orangeColor];
        [view addSubview:label];

        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 75., 5, 75., 18)];
        [button setTitle:@"EDIT" forState:UIControlStateNormal];
        
        button.layer.masksToBounds = NO;
        button.layer.shadowColor = [UIColor blackColor].CGColor;
        button.layer.shadowOpacity = 0.6;
        button.layer.shadowRadius = 1;
        button.layer.shadowOffset = CGSizeMake(1., 1.);
        
        [button setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(editAreas:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:button];
        
        return view;
    }
    return nil;
}

//- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
//{
//    //To show a line after section 1
//    if (section == 1) {
//        UITableViewHeaderFooterView *v = (UITableViewHeaderFooterView*)view;
//        v.backgroundView.backgroundColor = [UIColor lightGrayColor];
//    }
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 100.;
    }
    if (indexPath.section == 1) {
        return 80.;
    }
    if (indexPath.section == 2) {
        return 40.;
    }
    return 0.;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        CSRDeviceDetailsButtonsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CSRDeviceDetailsButtonsTableViewCellIdentifier];
        if (!cell) {
            cell = [[CSRDeviceDetailsButtonsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRDeviceDetailsButtonsTableViewCellIdentifier];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [cell.favouriteButton setBackgroundImage:[self displayFavouriteState:[_deviceEntity.favourite boolValue]] forState:UIControlStateNormal];
        [cell.favouriteButton addTarget:self action:@selector(favouriteAction:) forControlEvents:UIControlEventTouchUpInside];
        
        //Added for automation
        cell.favouriteButton.isAccessibilityElement = YES;
        
        _favButton = cell.favouriteButton;
        
        [cell.attentionButton setBackgroundImage:[CSRmeshStyleKit imageOfAttention] forState:UIControlStateNormal];
        [cell.attentionButton addTarget:self action:@selector(attentionAction:) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
        
    }
    if (indexPath.section == 1) {
        CSRDeviceDetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CSRDeviceDetailTableViewCellIdentifier];
        if (!cell) {
            cell = [[CSRDeviceDetailsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRDeviceDetailTableViewCellIdentifier];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if ([CSRMeshUserManager sharedInstance].bearerType == CSRBearerType_Bluetooth) {
            
            cell.firmwareDynamicLabel.text = _firmwareVersionString;
            cell.batteryDynamicLabel.text = _batteryLevelString;
        } else {
            [cell.firmwareStaticLabel setHidden:YES];
            [cell.firmwareDynamicLabel setHidden:YES];
            cell.batteryDynamicLabel.text = _batteryLevelString;

        }

        return cell;

    } 
    if (indexPath.section == 2) {
        
        CSRDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CSRDeviceTableViewCellIdentifier];
        if (!cell) {
            cell = [[CSRDeviceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRDeviceTableViewCellIdentifier];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (_areasArray && [_areasArray count] > 0) {
            
            CSRAreaEntity *areaEntity = [_areasArray objectAtIndex:indexPath.row];
            
            cell.iconImageView.image = [CSRmeshStyleKit imageOfAreaDevice];
            cell.deviceNameLabel.text = areaEntity.areaName;
            return cell;
            
        }
    }
    return nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"groupSelectionSegue"]) {
        CSRAreaSelectionViewController *vc = [segue destinationViewController];
        vc.deviceEntity = _deviceEntity;
    }
    if ([segue.identifier isEqualToString:@"otauSegue"]) {
        
    }
}

- (IBAction)deleteButtonTapped:(id)sender
{
//    [[BeaconProxyModelApi sharedInstance] addDevices:@0x8002
//                                  firstDeviceIsGroup:YES
//                                     deviceAddresses:@[@0x0001, @0x8001, @0x8002]
//                                             success:^(NSNumber * _Nullable deviceId) {
//                                                 
//                                                 NSLog(@"success");
//                                                 
//                                             } failure:^(NSError * _Nullable error) {
//                                                 
//                                                 NSLog(@"failure");
//                                                 
//                                             }];
    
    _device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:_deviceEntity.deviceId];
    
    CSRPlaceEntity *placeEntity = [CSRAppStateManager sharedInstance].selectedPlace;
    
    if (![CSRUtilities isStringEmpty:placeEntity.passPhrase]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Device"
                                                                                 message:[NSString stringWithFormat:@"Are you sure that you want to delete this device :%@?",_device.name]
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action) {
                                                                 [_spinner stopAnimating];
                                                                 [_spinner setHidden:YES];
                                                             }];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Yes"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             
                                                             if (_device) {
                                                                 [[CSRDevicesManager sharedInstance] initiateRemoveDevice:_device];
                                                             }
                                                             
                                                         }];
        [alertController addAction:okAction];
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.view addSubview:_spinner];
        _spinner.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        [_spinner startAnimating];
        
        
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert!!"
                                                                                 message:@"You should be place owner to associate a device"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             
                                                         }];
        
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
    }
    
}

-(void)deleteStatus:(NSNotification *)notification
{
    [_spinner stopAnimating];
    
    NSNumber *num = notification.userInfo[@"boolFlag"];
    if ([num boolValue] == NO) {
            [self showForceAlert];
    } else {
        if(_deviceEntity) {
            [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:_deviceEntity];
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_deviceEntity];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
        NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
//        [[MeshServiceApi sharedInstance] setNextDeviceId:deviceNumber];
        [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
        
        [self.navigationController popToRootViewControllerAnimated:YES];

    }
}

- (void) showForceAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Device Device"
                                                                             message:[NSString stringWithFormat:@"Device wasn't found. Do you want to delete %@ anyway?", _device.name]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [_spinner stopAnimating];
                                                             [_spinner setHidden:YES];
                                                         }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Yes"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         
                                                         if(_deviceEntity) {
                                                             [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:_deviceEntity];
                                                             [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_deviceEntity];
                                                             [[CSRDatabaseManager sharedInstance] saveContext];
                                                         }
                                                        NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
//                                                         [[MeshServiceApi sharedInstance] setNextDeviceId:deviceNumber];
                                                         [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
                                                         
                                                        [self.navigationController popToRootViewControllerAnimated:YES];
                                                     }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];

}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.backgroundColor = [UIColor whiteColor];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    textField.backgroundColor = [UIColor clearColor];
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Button Action Methods

- (IBAction)favouriteAction:(UIButton *)sender
{
    //
    // 1. Toggle favourite for this Device
    // 2. Update image for this device to inidicate new Favourite state
    //

    if (_deviceEntity) {
        BOOL state = [_deviceEntity.favourite boolValue];
        state = !state;
        [_deviceEntity setFavourite:@(state)];
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        // update Image
        [self displayFavouriteState:state];
        
        
        
    }
}

- (IBAction)attentionAction:(UIButton *)sender
{
//    if ([CSRMeshUserManager sharedInstance].bearerType == CSRBearerType_Bluetooth) {
//        if (_deviceEntity.deviceHash != nil) {
//            [[AttentionModelApi sharedInstance] setState:_deviceEntity.deviceId
//                                        attractAttention:YES duration:@(6000)
//                                                 success:^(NSNumber *deviceId, NSNumber *state, NSNumber *duration) {
//                                                     NSLog(@"state :%@", state);
//                                                 } failure:^(NSError *error) {
//                                                     NSLog(@"error :%@", error);
//                                                 }];
//        }
//    } else {
//        
//        CSRRestAttentionSetStateRequest *body = [[CSRRestAttentionSetStateRequest alloc] initWithValues:[NSDictionary dictionaryWithObjectsAndKeys:@1,@"AttractAttention",@(6000),@"Duration",nil]];
//        
//        [[CSRRestAttentionModelApi sharedInstance] setState:[CSRAppStateManager sharedInstance].selectedPlace.settings.cloudTenancyID
//                                                     siteId:[CSRAppStateManager sharedInstance].selectedPlace.cloudSiteID
//                                                     meshId:[CSRMeshUserManager sharedInstance].meshId
//                                                   deviceId:[_deviceEntity.deviceId stringValue]
//                                     csrmeshApplicationCode:kAppCode
//                                                   meshType:nil
//                                                   multiple:nil
//                                                    repeats:nil
//                                   attentionSetStateRequest:body
//                                             requestHandler:^(NSNumber *meshRequestId, NSError *error, CSRRestErrorResponse *errorResponse) {
//                                                 NSLog(@"statusCode :%@", errorResponse.statusCode);
//                                             } responseHandler:^(NSNumber *meshRequestId, CSRRestAttentionStateResponse *output, NSError *error, CSRRestErrorResponse *errorResponse) {
//                                                 NSLog(@"error :%@", error);
//                                             }];
//    }
    
//    [[BeaconProxyModelApi sharedInstance]
//     addDevices:_deviceEntity.deviceId
//     firstDeviceIsGroup:NO
//     deviceAddresses:@[@0x8080, @8081, @8082]
//     success:^(NSNumber * _Nullable deviceId) {
//         
//         NSLog(@"SUCCESS");
//         
//     } failure:^(NSError * _Nullable error) {
//         
//         NSLog(@"FAILURE");
//         
//     }];
//    if (_deviceEntity.uuid) {
//    NSData *deviceHash = [[MeshServiceApi sharedInstance] getDeviceHash64FromUuid:[CBUUID UUIDWithData:_deviceEntity.uuid]];
//    
//    [[ConfigModelApi sharedInstance] resetDevice:_deviceEntity.deviceId
//                                  withDeviceHash:deviceHash
//                                       andDHMKey:_deviceEntity.dhmKey
//                                         failure:^(NSError * _Nullable error) {
//                                             
//                                             NSLog(@"FAILURE");
//                                         }];
//    }
//
//
//    NSData *deviceHash = [[MeshServiceApi sharedInstance] getDeviceHash64FromUuid:[CBUUID UUIDWithData:_deviceEntity.uuid]];
//    
//    [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Gateway
//                                                       withMode:CSRMeshRestMode_Config];
//
//    [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Gateway
//                                                       withMode:CSRMeshRestMode_CNC];
    
    
//    [[MeshServiceApi sharedInstance] addDeviceToBlacklist:_deviceEntity.deviceId
//                                           withDeviceHash:deviceHash
//                                                   dhmkey:_deviceEntity.dhmKey
//                                                 validity:@10
//                                                  failure:^(NSError * _Nullable error) {
//                                                      
//                                                      NSLog(@"BLACKLIST FAILURE :%@", error);
//                                                      
//                                                  }];
////    [[MeshServiceApi sharedInstance] removeDeviceFromBlacklist:_deviceEntity.deviceId
////                                                withDeviceHash:deviceHash
////                                                        dhmkey:_deviceEntity.dhmKey
////                                                      validity:@10
////                                                       failure:^(NSError * _Nullable error) {
////                                                           
////                                                       }];
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        
//        [[LightModelApi sharedInstance] getState:_deviceEntity.deviceId
//                                         success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
//                                             
//                                             NSLog(@"Power SUCCESS");
//                                             
//                                         } failure:^(NSError * _Nullable error) {
//                                             
//                                             NSLog(@"Power FAILURE");
//                                             
//                                         }];
//    });
    
//    uint8_t bytes [] = {1, 2, 3, 4};
//    NSData *missingReplyPartsData = [NSData dataWithBytes:&bytes length:sizeof(bytes)];
//    
//    [[TuningModelApi sharedInstance] tuningStatsRequest:@(0x8001)
//                                      missingReplyParts:missingReplyPartsData
//                                                success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable partNumber, NSNumber * _Nullable neighbourId1, NSNumber * _Nullable neighbourRate1, NSNumber * _Nullable neighbourRssi1, NSNumber * _Nullable neighbourId2, NSNumber * _Nullable neighbourRate2, NSNumber * _Nullable neighbourRssi2) {
//                                                    
//                                                    NSLog(@"SUCCESS");
//                                                    
//                                                } failure:^(NSError  * _Nullable error) {
//                                                    
//                                                   NSLog(@"FAILURE");
//                                                    
//                                                }];
    
//    [[MeshServiceApi sharedInstance] updateNetworkSecurity:_deviceEntity.deviceId
//                                                    dhmkey:_deviceEntity.dhmKey
//                                         networkPassPhrase:@"bobby"
//                                                 networkIv:[[MeshServiceApi sharedInstance] getNetworkIv]
//                                                   success:^(NSNumber * _Nonnull deviceId,
//                                                             CSRNetworkSecurityUpdateStatus updateStatus,
//                                                             NSNumber * _Nonnull meshRequestId) {
//                                                       
//                                                       NSLog(@"SUCCESS");
//                                                       
//                                                   } failure:^(NSError * _Nullable error,
//                                                               NSNumber * _Nullable meshRequestId) {
//                                                       
//                                                       NSLog(@"FAILURE");
//                                                       
//                                                   }];
    
//    [[BeaconModelApi sharedInstance]
//     getPayload:@0x8001
//     payloadType:CSRBeaconType_CSR
//     success:^(NSNumber * _Nullable deviceId,
//               NSNumber * _Nullable payloadType,
//               NSNumber * _Nullable payloadId,
//               NSNumber * _Nullable payloadOffset,
//               NSData * _Nullable payloadData) {
//         
//         NSLog(@"SUCCESS");
//         
//     } failure:^(NSError * _Nullable error) {
//         
//         NSLog(@"FAILURE");
//         
//     }];
    
//    uint8_t message [] = {1,2,3,4};
//    NSData *messageData = [NSData dataWithBytes:&message length:sizeof(message)];
//
//    [[ExtensionModelApi sharedInstance] extensionSendMessage:_deviceEntity.deviceId
//                                                      opcode:@(0x9001)
//                                                     message:messageData
//                                                     failure:^(NSError * _Nullable error) {
//                                                         
//                                                     }];
    
//    [[PingModelApi sharedInstance] ping:_deviceEntity.deviceId
//                                   data:messageData
//                                 rspTTL:@100
//                                success:^(NSNumber * _Nullable deviceId, NSData * _Nullable arbitaryData, NSNumber * _Nullable TTLAtRx, NSNumber * _Nullable RSSIAtRx) {
//                                    
//                                } failure:^(NSError * _Nullable error) {
//                                    
//                                }];
    
    [[QTIWatchdogModelAPI sharedInstance] addDelegate:self];
    
    uint8_t message [] = {1,2,3,4};
    NSData *messageData = [NSData dataWithBytes:&message length:sizeof(message)];

    
    [[QTIWatchdogModelAPI sharedInstance] setMessage:_deviceEntity.deviceId
                                             rspSize:100
                                          randomData:messageData];
}

- (NSNumber *)didGetMessage:(NSNumber *)deviceId
                    rspSize:(uint8_t)rspSize
                 randomData:(NSData *)randomData
{
    NSLog(@"In Delegate");
    return nil;
}

- (IBAction)startModeAction:(UIButton *)sender
{
    if (_toggleButton) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Confirm"
                                                                                  message:@"Enter OTAU mode? You will no longer be able to control the device."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {                                                             //[self performSegueWithIdentifier:@"otauSegue" sender:self];
                                                             
                                                         }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 
                                                             }];
        [alertController addAction:okAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];

    } else {
        for (UIView *view in self.view.subviews) {
            view.userInteractionEnabled = YES;
        }
    }
    _toggleButton = !_toggleButton;
}

- (IBAction)backAction:(id)sender {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)saveAction:(id)sender {
    
    _deviceEntity.name = _deviceTitleTextField.text;
    _device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:_deviceEntity.deviceId];
    _device.name = _deviceTitleTextField.text;
    
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    

}

@end
