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
    
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
    self.navigationItem.leftBarButtonItem = back;
    
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
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_placeEntity) {
        _deleteButton.hidden = YES;
    }
}

#pragma mark - Actions

- (void) backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveAction {
    
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
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Can't Delete" message:@"You can't delete current selected place" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
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
