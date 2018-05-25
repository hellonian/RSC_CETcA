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
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <MBProgressHUD.h>

@interface PlaceDetailsViewController ()<UITextFieldDelegate,CSRCheckboxDelegate,CSRCheckboxDelegate,MCNearbyServiceBrowserDelegate,MCBrowserViewControllerDelegate>

@property (nonatomic,strong)MCPeerID * peerID;
@property (nonatomic,strong)MCSession * session;
@property (nonatomic,strong)MCNearbyServiceBrowser * brower;
@property (nonatomic,strong)MCBrowserViewController * browserViewController;
@property (nonatomic,strong) MBProgressHUD *hud;
@property (nonatomic,strong) NSString *oldName;

@end

@implementation PlaceDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _placeNameTF.delegate = self;
    _placeNetworkKeyTF.delegate = self;
    
    _showPasswordCheckbox.delegate = self;
    _showPasswordCheckbox.selected = YES;
    _showPasswordCheckbox.highlighted = NO;
    
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveAction)];
    self.navigationItem.rightBarButtonItem = save;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [_deleteButton setImage:[[CSRmeshStyleKit imageOfTrashcan] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    _deleteButton.imageView.tintColor = [UIColor whiteColor];
    [_deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    
    if (_placeEntity.name) {
        _placeNameTF.text = _placeEntity.name;
        _oldName = _placeEntity.name;
    }
    if (_placeEntity && ![CSRUtilities isStringEmpty:_placeEntity.passPhrase]) {
        _placeNetworkKeyTF.text = _placeEntity.passPhrase;
    }else if (!_placeEntity) {
        
    } else {
        _placeNetworkKeyTF.hidden = YES;
        _networkKeyLabel.hidden = YES;
        _showPasswordCheckbox.hidden = YES;
        _passwordLineView.hidden = YES;
        _showPasswordLabel.hidden = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_placeEntity) {
        _deleteButton.hidden = YES;
        _exportButton.hidden = YES;
    }else if (![[_placeEntity objectID] isEqual:[[CSRAppStateManager sharedInstance].selectedPlace objectID]]) {
        _exportButton.hidden = YES;
    }else if ([[_placeEntity objectID] isEqual:[[CSRAppStateManager sharedInstance].selectedPlace objectID]]) {
        _deleteButton.hidden = YES;
    }
    
}

#pragma mark - Actions

- (void)saveAction {
    
    if (_placeEntity && ![CSRUtilities isStringEmpty:_placeEntity.passPhrase]) { //detail, configure
        NSLog(@">>>111");
        if (![CSRUtilities isStringEmpty:_placeNameTF.text] && ![CSRUtilities isStringEmpty:_placeNetworkKeyTF.text]) {
            _placeEntity.name = _placeNameTF.text;
            _placeEntity.passPhrase = _placeNetworkKeyTF.text;
//            _placeEntity.color = @([CSRUtilities rgbFromColor:[CSRUtilities colorFromHex:@"#2196f3"]]);
//            _placeEntity.iconID = @(8);
//            _placeEntity.owner = @"My place";
            _placeEntity.networkKey = nil;
            
            [self checkForSettings];
            [[CSRDatabaseManager sharedInstance] saveContext];
            [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
            [[CSRAppStateManager sharedInstance] setupPlace];
            
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self showAlert];
        }
        
        
    } else if (!_placeEntity) { //new place
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
                if (i==2) {
                    defaultScene.iconID = @8;
                    defaultScene.sceneName = @"Scene1";
                }
                if (i==2) {
                    defaultScene.iconID = @8;
                    defaultScene.sceneName = @"Scene2";
                }
                
                [_placeEntity addScenesObject:defaultScene];
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            
            NSArray *defaultAreaNames = @[@"Living room",@"Bed room",@"Dining room",@"Toilet",@"Kitchen"];
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
        [alertController.view setTintColor:DARKORAGE];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (IBAction)exportPlace:(id)sender {
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.label.text = @"Searching recepient······";
    
    NSString *name = [UIDevice currentDevice].name;
    _peerID = [[MCPeerID alloc]initWithDisplayName:name];
    _session = [[MCSession alloc]initWithPeer:_peerID];
    
    _brower = [[MCNearbyServiceBrowser alloc]initWithPeer:_peerID serviceType:@"actec-place"];
    _brower.delegate = self;
    [_brower startBrowsingForPeers];
    
}



#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return NO;
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if (![CSRUtilities isStringEmpty:_placeNameTF.text] && ![CSRUtilities isStringEmpty:_placeNetworkKeyTF.text]) {
        if (_placeEntity) {
            if (![_placeNameTF.text isEqualToString:_oldName]) {
                self.navigationItem.rightBarButtonItem.enabled = YES;
            }else {
                self.navigationItem.rightBarButtonItem.enabled = NO;
            }
        }else {
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
        
    }else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (_placeEntity && textField.tag == 2) {
        return NO;
    }
    return YES;
}

#pragma mark - <CSRCheckbox>

- (void)checkbox:(CSRCheckbox *)sender stateChangeTo:(BOOL)state {
    if (state == _showPasswordCheckbox.selected) {
        _placeNetworkKeyTF.secureTextEntry = state;
    }else {
        _placeNetworkKeyTF.secureTextEntry = _showPasswordCheckbox.selected;
    }
}

#pragma MC相关代理方法

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info{
    if (_browserViewController == nil) {
        _browserViewController = [[MCBrowserViewController alloc]initWithServiceType:@"actec-place" session:_session];
        _browserViewController.delegate = self;
        [self presentViewController:_browserViewController animated:YES completion:nil];
        if (_hud) {
            [_hud hideAnimated:NO];
        }
    }
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    
}

#pragma mark - BrowserViewController附近用户列表视图相关代理方法

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{

    CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
    NSData *jsonData = [parseLoad composeDatabase];
    
    [_session sendData:jsonData toPeers:_session.connectedPeers withMode:MCSessionSendDataUnreliable error:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    _browserViewController = nil;
    
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    
    [self dismissViewControllerAnimated:YES completion:nil];
    _browserViewController = nil;
    
}

@end
