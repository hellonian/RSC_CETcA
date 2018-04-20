//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRPlaceDetailsViewController.h"
#import "CSRUtilities.h"
#import "CSRConstants.h"
#import "CSRmeshStyleKit.h"
#import "CSRSettingsEntity.h"
#import "CSRDeviceEntity.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import "AppDelegate.h"
#import "CSRParseAndLoad.h"
#import "CSRAppStateManager.h"
#import "CSRGatewayEntity.h"
#import "ZipArchive.h"
#import "CSRmesh/MeshServiceApi.h"
#import "NSData+Encryption.h"

//Cloud
#import <CSRmeshRestClient/CSRRestMeshConfigApi.h>

@interface CSRPlaceDetailsViewController ()
{
    NSUInteger pickerMode;
    NSDictionary *iconImageDictionary;
    NSUInteger placeIconId;
    NSUInteger placeColor;
}

@end

@implementation CSRPlaceDetailsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set image on delete button
//    _deleteButton.backgroundColor = [UIColor clearColor];
//    _deleteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
//    [_deleteButton setImage:[[CSRmeshStyleKit imageOfTrashcan] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
//    [_deleteButton.imageView sizeToFit];
//    _deleteButton.tintColor = [UIColor lightGrayColor];
//    _deleteButton.imageView.tintColor = [UIColor grayColor];
    [_deleteButton setImage:[[CSRmeshStyleKit imageOfTrashcan] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    _deleteButton.imageView.tintColor = [UIColor whiteColor];
    [_deleteButton setTitle:@"Delete" forState:UIControlStateNormal];

    //Set image on back up button
    [_cloudBacupButton setImage:[[CSRmeshStyleKit imageOfCloud] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    _cloudBacupButton.imageView.tintColor = [UIColor whiteColor];
    [_cloudBacupButton setTitle:@"Backup to Cloud" forState:UIControlStateNormal];
   
    _placeIconSelectionButton.backgroundColor = [UIColor clearColor];
    _placeIconSelectionButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    _placeIconSelectionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    _placeIconSelectionButton.imageView.image = [_placeIconSelectionButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_placeIconSelectionButton.imageView sizeToFit];
    _placeIconSelectionButton.tintColor = [UIColor grayColor];
    
    _placeColorSelectionButton.backgroundColor = [UIColor clearColor];
    _placeColorSelectionButton.layer.cornerRadius = _placeColorSelectionButton.bounds.size.width / 2;
    _placeColorSelectionButton.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    _placeColorSelectionButton.layer.borderWidth = 0.5;
    
    _placeNameTF.delegate = self;
    _placeNetworkKeyTF.delegate = self;
    _placeNetworkKeyTF.secureTextEntry = YES;
    
    _showPasswordCheckbox.delegate = self;
    _showPasswordCheckbox.selected = YES;
    _showPasswordCheckbox.highlighted = NO;
    
    // populate values
    if (_placeEntity.name) {
        _placeNameTF.text = _placeEntity.name;
    }
    
    if (_placeEntity && ![CSRUtilities isStringEmpty:_placeEntity.passPhrase]) {
        _placeNetworkKeyTF.text = _placeEntity.passPhrase;
    } else if (!_placeEntity) {
        _placeNetworkKeyTF.text = _placeEntity.passPhrase;
    } else {
        _placeNetworkKeyTF.hidden = YES;
        _networkKeyLabel.hidden = YES;
        _showPasswordCheckbox.hidden = YES;
        _passwordLineView.hidden = YES;
        _showPasswordLabel.hidden = YES;
    }
    
    if ([_placeEntity.iconID integerValue] > -1) {
        
        NSArray *placeIcons = kPlaceIcons;
        
        [placeIcons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            NSDictionary *placeDictionary = (NSDictionary *)obj;
            
            if ([placeDictionary[@"id"] integerValue] > -1 && [placeDictionary[@"id"] integerValue] == [_placeEntity.iconID integerValue]) {
                
                SEL imageSelector = NSSelectorFromString(placeDictionary[@"iconImage"]);
                
                if ([CSRmeshStyleKit respondsToSelector:imageSelector]) {
                    [_placeIconSelectionButton setImage:(UIImage *)[CSRmeshStyleKit performSelector:imageSelector] forState:UIControlStateNormal];
                    _placeIconSelectionButton.imageView.tintColor = [UIColor grayColor];
                }
                
                *stop = YES;
            }
        }];
        
    }
    
    if (_placeEntity.color) {
        _placeColorSelectionButton.backgroundColor = [CSRUtilities colorFromRGB:[_placeEntity.color integerValue]];
    }
    
    if (!_placeIconSelectionButton.imageView.image) {
        [_placeIconSelectionButton setImage:[CSRmeshStyleKit imageOfIconHouse] forState:UIControlStateNormal];
    }
//    _importedURL = ((AppDelegate*)[UIApplication sharedApplication].delegate).passingURL;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    _deleteButton.imageView.image = [CSRmeshStyleKit imageOfTrashcan];
//    _deleteButton.titleLabel.text = @"Delete";

    if (!_placeEntity) {
        _deleteButton.hidden = YES;
    }
    if ([CSRAppStateManager sharedInstance].bearerType == CSRSelectedBearerType_Gateway) {
        
        [_cloudBacupButton setTitle:@"Backup file to Gateway" forState:UIControlStateNormal];
        
    } else if ([CSRAppStateManager sharedInstance].bearerType == CSRSelectedBearerType_Cloud) {
        
        [_cloudBacupButton setTitle:@"Backup file to Cloud" forState:UIControlStateNormal];
        
    } else if ([CSRAppStateManager sharedInstance].bearerType == CSRSelectedBearerType_Bluetooth) {
        
        _cloudBacupButton.hidden = YES;
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"placeColorIconPickerSegue"]) {
        CSRPlacesColorIconPickerViewController *vc = segue.destinationViewController;
        vc.delegate = self;
        vc.mode = pickerMode;
        vc.popoverPresentationController.delegate = self;
        vc.popoverPresentationController.containerView.superview.layer.cornerRadius = 0;
        vc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20., 235.);
    }
}

#pragma mark - Actions

- (IBAction)openPicker:(id)sender
{
    if ([sender isEqual:_placeColorSelectionButton]) {
        
        pickerMode = CSRPlacesCollectionViewMode_ColorPicker;
        [self performSegueWithIdentifier:@"placeColorIconPickerSegue" sender:self];
        
    } else if ([sender isEqual:_placeIconSelectionButton]) {
        
        pickerMode = CSRPlacesCollectionViewMode_IconPicker;
        [self performSegueWithIdentifier:@"placeColorIconPickerSegue" sender:self];
        
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

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - <CSRPlacesColorIconPickerDelegate>

- (id)selectedItem:(id)item
{
    if (pickerMode == CSRPlacesCollectionViewMode_ColorPicker) {
        
        NSString *selectedColorHex = (NSString *)item;
        _placeColorSelectionButton.backgroundColor = [CSRUtilities colorFromHex:[NSString stringWithFormat:@"%@", selectedColorHex]];
        
    } else if (pickerMode == CSRPlacesCollectionViewMode_IconPicker) {
        
        iconImageDictionary = (NSDictionary *)item;
        
        placeIconId = [(NSNumber *)iconImageDictionary[@"id"] integerValue];
        SEL imageSelector = NSSelectorFromString(iconImageDictionary[@"iconImage"]);
        
        if ([CSRmeshStyleKit respondsToSelector:imageSelector]) {
            [_placeIconSelectionButton setImage:(UIImage *)[CSRmeshStyleKit performSelector:imageSelector] forState:UIControlStateNormal];
        }
        
        _placeIconSelectionButton.imageView.image = [_placeIconSelectionButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_placeIconSelectionButton.imageView sizeToFit];
        _placeIconSelectionButton.imageView.tintColor = [UIColor grayColor];
        
    }
    
    return nil;
}

#pragma mark - <CSRCheckbox>
- (void)checkbox:(CSRCheckbox*)sender stateChangeTo:(BOOL)state
{
    if (state == _showPasswordCheckbox.selected) {
        _placeNetworkKeyTF.secureTextEntry = state;
    } else {
        _placeNetworkKeyTF.secureTextEntry = _showPasswordCheckbox.selected;
    }
}

#pragma mark - Actions

- (IBAction)backbuttonTapped:(id)sender
{
    if ([self isModal]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

//
//http://stackoverflow.com/questions/23620276/check-if-view-controller-is-presented-modally-or-pushed-on-a-navigation-stack
//
- (BOOL)isModal {
    if([self presentingViewController])
        return YES;
    if([[self presentingViewController] presentedViewController] == self)
        return YES;
    if([[[self navigationController] presentingViewController] presentedViewController] == [self navigationController])
        return YES;
    
    return NO;
}

- (IBAction)savePlace:(id)sender
{
    
    NSLog(@"MeshID :%@", [[MeshServiceApi sharedInstance] getMeshId]);
    
    if (!placeIconId) {
        
        placeIconId = [_placeEntity.iconID integerValue];
        
    }
    if (_placeEntity && ![CSRUtilities isStringEmpty:_placeEntity.passPhrase] && !_importedURL) { //detail, configure
        
        if (![CSRUtilities isStringEmpty:_placeNameTF.text] && ![CSRUtilities isStringEmpty:_placeNetworkKeyTF.text]) {
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.passPhrase = _placeNetworkKeyTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:_placeColorSelectionButton.backgroundColor]);
            _placeEntity.iconID = @(placeIconId);
            _placeEntity.owner = @"My place";
            _placeEntity.networkKey = nil;
            
            [self checkForSettings];
            [[CSRDatabaseManager sharedInstance] saveContext];
            [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
            [[CSRAppStateManager sharedInstance] setupPlace];
            
//            [self.navigationController popToRootViewControllerAnimated:YES];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self showAlert];
        }
        
        
    } else if (!_placeEntity && !_importedURL) { //new place
        
        if (![CSRUtilities isStringEmpty:_placeNameTF.text] && ![CSRUtilities isStringEmpty:_placeNetworkKeyTF.text]) {
            _placeEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRPlaceEntity"
                                                         inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
            
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.passPhrase = _placeNetworkKeyTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:_placeColorSelectionButton.backgroundColor]);
            _placeEntity.iconID = @(placeIconId);
            _placeEntity.owner = @"My place";
            _placeEntity.networkKey = nil;
            
            [self checkForSettings];
            [[CSRDatabaseManager sharedInstance] saveContext];
            [[CSRAppStateManager sharedInstance] setupPlace];
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
        } else {
            [self showAlert];
        }
    } else if (_placeEntity && [CSRUtilities isStringEmpty:_placeEntity.passPhrase] && !_importedURL) { //from MASP
        
        if (![CSRUtilities isStringEmpty:_placeNameTF.text]) {
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:_placeColorSelectionButton.backgroundColor]);
            _placeEntity.iconID = @(placeIconId);
            
            [self checkForSettings];
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            [self showAlert];
        }
    
    } else if (_placeEntity && _importedURL && ![CSRUtilities isStringEmpty:_placeEntity.passPhrase]) {
        
        if (![CSRUtilities isStringEmpty:_placeNameTF.text] ) {
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.passPhrase = _placeNetworkKeyTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:_placeColorSelectionButton.backgroundColor]);
            _placeEntity.iconID = @(placeIconId);
            _placeEntity.owner = @"My place";
            _placeEntity.networkKey = nil;
            
            [self checkForSettings];
            [[CSRAppStateManager sharedInstance] setSelectedPlace:_placeEntity];
            [self unZipDecrypt];
            [[MeshServiceApi sharedInstance] setNetworkPassPhrase:_placeNetworkKeyTF.text];
            
//            ((AppDelegate*)[UIApplication sharedApplication].delegate).passingURL = nil;
            [self dismissViewControllerAnimated:NO completion:nil];
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            
        } else {
            [self showAlert];
        }
    } else if (!_placeEntity && _importedURL) {
        if (![CSRUtilities isStringEmpty:_placeNameTF.text] && ![CSRUtilities isStringEmpty:_placeNetworkKeyTF.text]) {
            CSRPlaceEntity *newPlace = [NSEntityDescription insertNewObjectForEntityForName:@"CSRPlaceEntity"
                                                         inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];

            newPlace.name = _placeNameTF.text;
            newPlace.passPhrase = _placeNetworkKeyTF.text;
            newPlace.color = @([CSRUtilities rgbFromColor:_placeColorSelectionButton.backgroundColor]);
            newPlace.iconID = @(placeIconId);
            newPlace.owner = @"My place";
            newPlace.networkKey = nil;
            
            [self checkForSettings];
            [[CSRAppStateManager sharedInstance] setSelectedPlace:newPlace];
            [self unZipDecrypt];
            [[MeshServiceApi sharedInstance] setNetworkPassPhrase:_placeNetworkKeyTF.text];
            
//            ((AppDelegate*)[UIApplication sharedApplication].delegate).passingURL = nil;
            [self dismissViewControllerAnimated:NO completion:nil];
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            
        } else {
            [self showAlert];
        }

    } else if (_placeEntity && _importedURL && [CSRUtilities isStringEmpty:_placeEntity.passPhrase]) {
        if (![CSRUtilities isStringEmpty:_placeNameTF.text]) {
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:_placeColorSelectionButton.backgroundColor]);
            _placeEntity.iconID = @(placeIconId);
            
            [self checkForSettings];
            [self unZipDecrypt];
            
            [[MeshServiceApi sharedInstance] setNetworkKey:_placeEntity.networkKey];
            
//            ((AppDelegate*)[UIApplication sharedApplication].delegate).passingURL = nil;
            [self dismissViewControllerAnimated:NO completion:nil];
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            
        } else {
            [self showAlert];
        }
        
    }
}

- (void) unZipDecrypt {
    
    NSError *error = nil;
    NSString *zipPath = [_importedURL path];
    
    NSString *outputPath = [CSRUtilities createFile:@"Regular"];
        ZipArchive* zip = [[ZipArchive alloc] init];
        if([zip UnzipOpenFile:zipPath Password:[[MeshServiceApi sharedInstance] getMeshId]])
        {
            if([zip UnzipFileTo:outputPath overWrite:YES])
            {
                NSLog(@"success");
            } else {
                //TODO: crash fix
                NSLog(@"Zip is Wrong!!");
            }
            [zip UnzipCloseFile];
        }
    
    NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:outputPath error:&error];
    NSString *fullURLString = [outputPath stringByAppendingString:[NSString stringWithFormat:@"/%@", [directoryContents objectAtIndex:0]]];
    NSString *validStr = [NSString stringWithFormat:@"file:///%@", fullURLString];
    NSData *jsonDataImported = [NSData dataWithContentsOfURL:[NSURL URLWithString:validStr]];
    
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonDataImported options:NSJSONReadingMutableLeaves error:&error];
    
    [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
    
    [[CSRAppStateManager sharedInstance] setupPlace];

    CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
//    [parseLoad deleteEntitiesInSelectedPlace]; //Delete Core data Entities
    [parseLoad parseIncomingDictionary:jsonDictionary]; //parse and load fresh data
}

- (void) showAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert!"
                                                                             message:@"Name and Pass Phrase should not be empty, please enter some values"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                       
                                                     }];
    
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];

}

- (IBAction)deletePlace:(id)sender
{
    if (![[_placeEntity objectID] isEqual:[[CSRAppStateManager sharedInstance].selectedPlace objectID]]) {
        
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_placeEntity];
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't Delete"
                                                        message:@"You can't delete current selected place"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (IBAction)backupToCloud:(id)sender
{
    NSString *tenantString = [CSRAppStateManager sharedInstance].selectedPlace.settings.cloudTenancyID;
    CSRGatewayEntity *currentGateway;
    if ([[CSRAppStateManager sharedInstance].selectedPlace.gateways allObjects].count) {
        
        currentGateway = (CSRGatewayEntity *)[[[CSRAppStateManager sharedInstance].selectedPlace.gateways allObjects] objectAtIndex:0];
    }
    
    CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
    NSData *jsonData = [parseLoad composeDatabase];
    
    //Encryption (NSData + Encryption)
    NSData *ivData = [CSRUtilities randomDataOfLength:16];
    NSData *ciper = [jsonData AES256EncryptWithKey:[[MeshServiceApi sharedInstance] getMeshId] iv:ivData];
    
    NSMutableData *fullData = [NSMutableData dataWithData:ivData];
    [fullData appendData:ciper];
    NSData *dataToSend = [NSData dataWithData:fullData];
    
    if ([CSRAppStateManager sharedInstance].bearerType == CSRSelectedBearerType_Gateway) {
        [[CSRRestConfig sharedInstance] setServerUrl:CSRRestServerComponent_CONFIG
                                           uriScheme:kGatewayServerUriScheme
                                                host:currentGateway.host
                                                port:[NSString stringWithFormat:@"%@", currentGateway.port]
                                            basePath:[NSString stringWithFormat:@"/cgi-bin%@", kConfigServerBasePath]
                                   connectionChannel:CSRRestConnectionChannel_GATEWAY];
        
        
        CSRRestCreateFileRequest *req = [[CSRRestCreateFileRequest alloc] initWithcontent:dataToSend];
        [[CSRRestMeshConfigApi sharedInstance] createFile:[[NSBundle mainBundle] bundleIdentifier]
                                            contentLength:[NSString stringWithFormat:@"%lu",(unsigned long)jsonData.length]
                                                 tenantId:tenantString
                                                 fileName:@"csrmesh_db"
                                                overwrite:nil
                                                parentRev:nil
                                           deletionPolicy:nil
                                        createFileRequest:req
                                          responseHandler:^(NSNumber *meshRequestId, CSRRestCreateFileResponse *output, NSError *error, CSRRestErrorResponse *errorResponse) {
                                              NSLog(@"meshRequestId%@, output%@, error%@, errorResponse%@", meshRequestId, output, error, errorResponse);
                                          }];
    } else if ([CSRAppStateManager sharedInstance].bearerType == CSRSelectedBearerType_Cloud) {
        [[CSRRestConfig sharedInstance] setServerUrl:CSRRestServerComponent_CONFIG
                                           uriScheme:kGatewayServerUriScheme
                                                host:currentGateway.host
                                                port:[NSString stringWithFormat:@"%@", currentGateway.port]
                                            basePath:[NSString stringWithFormat:@"/cgi-bin%@", kConfigServerBasePath]
                                   connectionChannel:CSRRestConnectionChannel_CLOUD];
        
        
        CSRRestCreateFileRequest *req = [[CSRRestCreateFileRequest alloc] initWithcontent:jsonData];
        [[CSRRestMeshConfigApi sharedInstance] createFile:[[NSBundle mainBundle] bundleIdentifier]
                                            contentLength:[NSString stringWithFormat:@"%lu",(unsigned long)jsonData.length]
                                                 tenantId:tenantString
                                                 fileName:@"csrmesh_db"
                                                overwrite:nil
                                                parentRev:nil
                                           deletionPolicy:nil
                                        createFileRequest:req
                                          responseHandler:^(NSNumber *meshRequestId, CSRRestCreateFileResponse *output, NSError *error, CSRRestErrorResponse *errorResponse) {
                                              NSLog(@"meshRequestId%@, output%@, error%@, errorResponse%@", meshRequestId, output, error, errorResponse);
                                          }];
        
    } else {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert!!"
                                                                                 message:@"You should be on a Gateway or Cloud to back up your file"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             
                                                         }];
        
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (IBAction)exportPlace:(id)sender {
    
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
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[jsonURL]
                                                                             applicationActivities:nil];
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
    [self presentViewController:activityVC animated:YES completion:nil];
    if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
        UIPopoverPresentationController *activity = [activityVC popoverPresentationController];
        activity.sourceRect = CGRectMake(10, 10, 200, 100);
        activity.sourceView = _cloudBacupButton;
    }
}


- (void)checkForSettings
{
    if (_placeEntity.settings) {
        
        _placeEntity.settings.retryInterval = @500;
        _placeEntity.settings.retryCount = @10;
        _placeEntity.settings.concurrentConnections = @1;
        _placeEntity.settings.listeningMode = @1;
        
    } else {
        
        CSRSettingsEntity *settings = [NSEntityDescription insertNewObjectForEntityForName:@"CSRSettingsEntity"
                                                                    inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
        settings.retryInterval = @500;
        settings.retryCount = @10;
        settings.concurrentConnections = @1;
        settings.listeningMode = @1;
        
        _placeEntity.settings = settings;
        
    }
}

@end
