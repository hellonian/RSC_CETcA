//
//  PlaceDetailsViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/12/26.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "PlaceDetailsViewController.h"
#import "PlaceColorIconPickerView.h"
#import "PureLayout.h"
#import "CSRUtilities.h"
#import "CSRmeshStyleKit.h"
#import "CSRConstants.h"
#import "CSRmeshStyleKit.h"
#import "CSRDatabaseManager.h"
#import "CSRSettingsEntity.h"
#import "CSRAppStateManager.h"
#import "SceneEntity.h"
#import "AppDelegate.h"
#import "ZipArchive.h"
#import "CSRParseAndLoad.h"

@interface PlaceDetailsViewController ()<UITextFieldDelegate,CSRCheckboxDelegate,CSRCheckboxDelegate>

@end

@implementation PlaceDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _placeNameTF.delegate = self;
    _placeNetworkKeyTF.delegate = self;
    _placeNetworkKeyTF.secureTextEntry = YES;
    
    _showPasswordCheckbox.delegate = self;
    _showPasswordCheckbox.selected = YES;
    _showPasswordCheckbox.highlighted = NO;
    
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveAction)];
    self.navigationItem.rightBarButtonItem = save;
    
    [_deleteButton setImage:[[CSRmeshStyleKit imageOfTrashcan] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    _deleteButton.imageView.tintColor = [UIColor whiteColor];
    [_deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    
    if (_placeEntity.name) {
        _placeNameTF.text = _placeEntity.name;
    }
    if (_placeEntity && ![CSRUtilities isStringEmpty:_placeEntity.passPhrase]) {
        _placeNetworkKeyTF.text = _placeEntity.passPhrase;
    }else if (!_placeEntity) {
        _placeNetworkKeyTF.text = _placeEntity.passPhrase;
    } else {
        _placeNetworkKeyTF.hidden = YES;
        _networkKeyLabel.hidden = YES;
        _showPasswordCheckbox.hidden = YES;
        _passwordLineView.hidden = YES;
        _showPasswordLabel.hidden = YES;
    }
    _importedURL = ((AppDelegate*)[UIApplication sharedApplication].delegate).passingURL;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_placeEntity) {
        _deleteButton.hidden = YES;
        _exportButton.hidden = YES;
    }
}

#pragma mark - Actions

- (void)saveAction {
    /*
    if (_placeEntity && ![CSRUtilities isStringEmpty:_placeEntity.passPhrase]) {
        if (![CSRUtilities isStringEmpty:_placeNameTF.text] && ![CSRUtilities isStringEmpty:_placeNetworkKeyTF.text]) {
            
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.passPhrase = _placeNetworkKeyTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:[CSRUtilities colorFromHex:@"#2196f3"]]);
            _placeEntity.iconID = @(8);
            _placeEntity.owner = @"My place";
            _placeEntity.networkKey = nil;
            
            [self checkForSettings];
            [[CSRDatabaseManager sharedInstance] saveContext];
            [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
            [[CSRAppStateManager sharedInstance] setupPlace];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            [self showAlert];
        }
    }
    
    if (!_placeEntity) {
        if (![CSRUtilities isStringEmpty:_placeNameTF.text] && ![CSRUtilities isStringEmpty:_placeNetworkKeyTF.text]) {
            
            _placeEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRPlaceEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
            
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.passPhrase = _placeNetworkKeyTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:[CSRUtilities colorFromHex:@"#2196f3"]]);
            _placeEntity.iconID = @(8);
            _placeEntity.owner = @"My place";
            _placeEntity.networkKey = nil;
            
            [self checkForSettings];
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            for (int i=0; i<4; i++) {
                SceneEntity *defaultScene = [NSEntityDescription insertNewObjectForEntityForName:@"SceneEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                
                defaultScene.sceneID = @(i);
                if (i==0) {
                    defaultScene.iconID = @0;
                    defaultScene.sceneName = @"Home";
                }
                if (i==1) {
                    defaultScene.iconID = @5;
                    defaultScene.sceneName = @"Away";
                }
                if (i==2 || i==3) {
                    defaultScene.iconID = @8;
                    defaultScene.sceneName = @"Custom";
                }
                
                [_placeEntity addScenesObject:defaultScene];
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            
            NSArray *defaultAreaNames = @[@"Livingroom",@"Bedroom",@"Diningroom",@"Washroom",@"Kitchen"];
            for (int i=0; i<5; i++) {
                CSRAreaEntity *defaultArea = [NSEntityDescription insertNewObjectForEntityForName:@"CSRAreaEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                
                defaultArea.areaID = @(i+1);
                defaultArea.areaName = defaultAreaNames[i];
                defaultArea.areaIconNum = @(i);
                defaultArea.sortId = @(i);
                
                [_placeEntity addAreasObject:defaultArea];
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            
            [[CSRAppStateManager sharedInstance] setupPlace];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            [self showAlert];
        }
    }
    */
    
    if (_placeEntity && ![CSRUtilities isStringEmpty:_placeEntity.passPhrase] && !_importedURL) { //detail, configure
        NSLog(@">>>111");
        if (![CSRUtilities isStringEmpty:_placeNameTF.text] && ![CSRUtilities isStringEmpty:_placeNetworkKeyTF.text]) {
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.passPhrase = _placeNetworkKeyTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:[CSRUtilities colorFromHex:@"#2196f3"]]);
            _placeEntity.iconID = @(8);
            _placeEntity.owner = @"My place";
            _placeEntity.networkKey = nil;
            
            [self checkForSettings];
            [[CSRDatabaseManager sharedInstance] saveContext];
            [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
            [[CSRAppStateManager sharedInstance] setupPlace];
            
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self showAlert];
        }
        
        
    } else if (!_placeEntity && !_importedURL) { //new place
        NSLog(@">>>222");
        if (![CSRUtilities isStringEmpty:_placeNameTF.text] && ![CSRUtilities isStringEmpty:_placeNetworkKeyTF.text]) {
            _placeEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRPlaceEntity"
                                                         inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
            
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.passPhrase = _placeNetworkKeyTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:[CSRUtilities colorFromHex:@"#2196f3"]]);
            _placeEntity.iconID = @(8);
            _placeEntity.owner = @"My place";
            _placeEntity.networkKey = nil;
            
            [self checkForSettings];
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            for (int i=0; i<4; i++) {
                SceneEntity *defaultScene = [NSEntityDescription insertNewObjectForEntityForName:@"SceneEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                
                defaultScene.sceneID = @(i);
                if (i==0) {
                    defaultScene.iconID = @0;
                    defaultScene.sceneName = @"Home";
                }
                if (i==1) {
                    defaultScene.iconID = @5;
                    defaultScene.sceneName = @"Away";
                }
                if (i==2 || i==3) {
                    defaultScene.iconID = @8;
                    defaultScene.sceneName = @"Custom";
                }
                
                [_placeEntity addScenesObject:defaultScene];
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            
            NSArray *defaultAreaNames = @[@"Livingroom",@"Bedroom",@"Diningroom",@"Washroom",@"Kitchen"];
            for (int i=0; i<5; i++) {
                CSRAreaEntity *defaultArea = [NSEntityDescription insertNewObjectForEntityForName:@"CSRAreaEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                
                defaultArea.areaID = @(i+1);
                defaultArea.areaName = defaultAreaNames[i];
                defaultArea.areaIconNum = @(i);
                defaultArea.sortId = @(i);
                
                [_placeEntity addAreasObject:defaultArea];
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            
            [[CSRAppStateManager sharedInstance] setupPlace];
            
            [self.navigationController popViewControllerAnimated:YES];
            
        } else {
            [self showAlert];
        }
    } else if (_placeEntity && [CSRUtilities isStringEmpty:_placeEntity.passPhrase] && !_importedURL) { //from MASP
        NSLog(@">>>333");
        if (![CSRUtilities isStringEmpty:_placeNameTF.text]) {
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:[CSRUtilities colorFromHex:@"#2196f3"]]);
            _placeEntity.iconID = @(8);
            
            [self checkForSettings];
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            [self showAlert];
        }
        
    } else if (_placeEntity && _importedURL && ![CSRUtilities isStringEmpty:_placeEntity.passPhrase]) {
        
        if (![CSRUtilities isStringEmpty:_placeNameTF.text] ) {
            NSLog(@"333333333");
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.passPhrase = _placeNetworkKeyTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:[CSRUtilities colorFromHex:@"#2196f3"]]);
            _placeEntity.iconID = @(8);
            _placeEntity.owner = @"My place";
            _placeEntity.networkKey = nil;
            
            [self checkForSettings];
            [[CSRAppStateManager sharedInstance] setSelectedPlace:_placeEntity];
            [self unZipDecrypt];
            [[MeshServiceApi sharedInstance] setNetworkPassPhrase:_placeNetworkKeyTF.text];
            
            ((AppDelegate*)[UIApplication sharedApplication].delegate).passingURL = nil;
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self showAlert];
        }
    } else if (!_placeEntity && _importedURL) {
        if (![CSRUtilities isStringEmpty:_placeNameTF.text] && ![CSRUtilities isStringEmpty:_placeNetworkKeyTF.text]) {
            NSLog(@"222222222");
            CSRPlaceEntity *newPlace = [NSEntityDescription insertNewObjectForEntityForName:@"CSRPlaceEntity"
                                                                     inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
            
            newPlace.name = _placeNameTF.text;
            newPlace.passPhrase = _placeNetworkKeyTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:[CSRUtilities colorFromHex:@"#2196f3"]]);
            newPlace.iconID = @(8);
            newPlace.owner = @"My place";
            newPlace.networkKey = nil;
            
            [self checkForSettings];
            [[CSRAppStateManager sharedInstance] setSelectedPlace:newPlace];
            [self unZipDecrypt];
            [[MeshServiceApi sharedInstance] setNetworkPassPhrase:_placeNetworkKeyTF.text];
            
            ((AppDelegate*)[UIApplication sharedApplication].delegate).passingURL = nil;
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self showAlert];
        }
        
    } else if (_placeEntity && _importedURL && [CSRUtilities isStringEmpty:_placeEntity.passPhrase]) {
        NSLog(@"111111111");
        if (![CSRUtilities isStringEmpty:_placeNameTF.text]) {
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.color = @([CSRUtilities rgbFromColor:[CSRUtilities colorFromHex:@"#2196f3"]]);
            _placeEntity.iconID = @(8);
            
            [self checkForSettings];
            [self unZipDecrypt];
            
            [[MeshServiceApi sharedInstance] setNetworkKey:_placeEntity.networkKey];
            
            ((AppDelegate*)[UIApplication sharedApplication].delegate).passingURL = nil;
            [self.navigationController popViewControllerAnimated:YES];
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
    [parseLoad deleteEntitiesInSelectedPlace]; //Delete Core data Entities
    [parseLoad parseIncomingDictionary:jsonDictionary]; //parse and load fresh data
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

- (void) showAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert!"
                                                                             message:@"Name and Pass Phrase should not be empty, please enter some values"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:@"Alert!"];
    [attributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1] range:NSMakeRange(0, [[attributedTitle string] length])];
    [alertController setValue:attributedTitle forKey:@"attributedTitle"];
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"AName and Pass Phrase should not be empty, please enter some values"]];
    [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
    [alertController setValue:attributedMessage forKey:@"attributedMessage"];
    [alertController.view setTintColor:DARKORAGE];
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
        
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Can't Delete" message:@"You can't delete current selected place" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:cancelAction];
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
    NSString* zipfile = [dPath stringByAppendingPathComponent:@"AcTEC.zip"];
    
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
        activity.sourceView = (UIButton *)sender;
    }
}



#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - <CSRCheckbox>

- (void)checkbox:(CSRCheckbox *)sender stateChangeTo:(BOOL)state {
    if (state == _showPasswordCheckbox.selected) {
        _placeNetworkKeyTF.secureTextEntry = state;
    }else {
        _placeNetworkKeyTF.secureTextEntry = _showPasswordCheckbox.selected;
    }
}

@end
