//
//  PlaceDetailsViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2017/12/26.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
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
#import "CSRParseAndLoad.h"

#import <SystemConfiguration/CaptiveNetwork.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#import "SGQRCode.h"
#import "GCDAsyncSocket.h"
#import <MBProgressHUD.h>

#import <CoreLocation/CLLocationManager.h>

@interface PlaceDetailsViewController ()<UITextFieldDelegate,CSRCheckboxDelegate,CSRCheckboxDelegate,GCDAsyncSocketDelegate,MBProgressHUDDelegate,CLLocationManagerDelegate>

@property (nonatomic,strong) NSString *oldName;
@property (weak, nonatomic) IBOutlet UILabel *placeName;
@property (nonatomic,strong) GCDAsyncSocket *serverSocket;
@property (nonatomic,strong) NSMutableArray *clientSocketArray;
@property (nonatomic,strong) MBProgressHUD *hud;
@property (weak, nonatomic) IBOutlet UIImageView *QRCodeImageView;
@property (weak, nonatomic) IBOutlet UILabel *QRCodeLabel;

@property (nonatomic, strong) CLLocationManager *locManager;

@end

@implementation PlaceDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (@available(iOS 11.0,*)) {
    }else {
        [_placeName autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:84.0f];
    }
    _placeNameTF.delegate = self;
    _placeNetworkKeyTF.delegate = self;
    
    _showPasswordCheckbox.delegate = self;
    _showPasswordCheckbox.selected = YES;
    _showPasswordCheckbox.highlighted = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange:) name:ZZAppLanguageDidChangeNotification object:nil];
    
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Save", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(saveAction)];
    self.navigationItem.rightBarButtonItem = save;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [_deleteButton setImage:[[CSRmeshStyleKit imageOfTrashcan] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    _deleteButton.imageView.tintColor = [UIColor whiteColor];
    
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
        _QRCodeImageView.hidden = YES;
        _QRCodeLabel.hidden = YES;
    }else if (![[_placeEntity objectID] isEqual:[[CSRAppStateManager sharedInstance].selectedPlace objectID]]) {
        _QRCodeImageView.hidden = YES;
        _QRCodeLabel.hidden = YES;
    }else if ([[_placeEntity objectID] isEqual:[[CSRAppStateManager sharedInstance].selectedPlace objectID]]) {
        _deleteButton.hidden = YES;
        if ([self startListenPort:4321]) {
            if (@available(iOS 13.0, *)) {
                [self getcurrentLocation];
            }else {
                [self displayQRCode];
            }
        }
    }
}

- (void)getcurrentLocation {
    if (@available(iOS 13.0, *)) {
        //用户明确拒绝，可以弹窗提示用户到设置中手动打开权限
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                                     message:AcTECLocalizedStringFromTable(@"gotosetting", @"Localizable")
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            [alertController.view setTintColor:DARKORAGE];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable")
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
//                                                                 //使用下面接口可以打开当前应用的设置页面
//                                                                 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                             }];
            
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
        
        self.locManager = [[CLLocationManager alloc] init];
        self.locManager.delegate = self;
        if(![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
            //弹框提示用户是否开启位置权限
            [self.locManager requestWhenInUseAuthorization];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self displayQRCode];
}

- (void)displayQRCode {
    NSString *wifiName = [self getWifiName];
    if (wifiName) {
        NSDictionary *dic = @{@"WIFIName":wifiName,
                              @"IPAddress":[self localIpAddressForCurrentDevice],
                              @"PORT":@(4321),
                              @"FROM":@"ios"};
        NSString *jsonString = [CSRUtilities convertToJsonData:dic];
        if (jsonString) {
            self.QRCodeImageView.image = [SGQRCodeObtain generateQRCodeWithData:jsonString size:200];
        }
    }else {
        _QRCodeLabel.text = AcTECLocalizedStringFromTable(@"noWifiAlert", @"Localizable");
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
            NSArray *placesArray = [[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"CSRPlaceEntity" withPredicate:@"passPhrase == %@ and name == %@",_placeNetworkKeyTF.text,_placeNameTF.text];
            if (placesArray && placesArray.count>0) {
                 UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                                             message:AcTECLocalizedStringFromTable(@"place_exists", @"Localizable")
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                    [alertController.view setTintColor:DARKORAGE];
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction *action) {
                                                                         
                                                                     }];
                    
                    [alertController addAction:okAction];
                    [self presentViewController:alertController animated:YES completion:nil];
            }else {
                _placeEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRPlaceEntity"
                                                                         inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                            
                            _placeEntity.name = _placeNameTF.text;
                            _placeEntity.passPhrase = _placeNetworkKeyTF.text;
                //            _placeEntity.color = @([CSRUtilities rgbFromColor:[CSRUtilities colorFromHex:@"#2196f3"]]);
                            _placeEntity.iconID = @(8);
                            _placeEntity.owner = @"My place";
                            _placeEntity.networkKey = nil;
                            
                            [self checkForSettings];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            
                            for (int i=0; i<6; i++) {
                                SceneEntity *defaultScene = [NSEntityDescription insertNewObjectForEntityForName:@"SceneEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                                
                                defaultScene.rcIndex = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"SceneEntity_sceneIndex"];
                                defaultScene.sceneID = @(i);
                                defaultScene.srDeviceId = @(-1);
                                if (i==0) {
                                    defaultScene.iconID = @0;
                                    defaultScene.sceneName = @"Home";
                                }
                                if (i==1) {
                                    defaultScene.iconID = @1;
                                    defaultScene.sceneName = @"Away";
                                }
                                if (i==2) {
                                    defaultScene.iconID = @8;
                                    defaultScene.sceneName = @"Scene1";
                                }
                                if (i==3) {
                                    defaultScene.iconID = @8;
                                    defaultScene.sceneName = @"Scene2";
                                }
                                if (i==4) {
                                    defaultScene.iconID = @8;
                                    defaultScene.sceneName = @"Scene3";
                                }
                                if (i==5) {
                                    defaultScene.iconID = @8;
                                    defaultScene.sceneName = @"Scene4";
                                }
                                
                                [_placeEntity addScenesObject:defaultScene];
                                [[CSRDatabaseManager sharedInstance] saveContext];
                            }
                            
                            NSArray *defaultAreaNames = @[@"Living room",@"Bed room",@"Dining room",@"Toilet",@"Kitchen"];
                            for (int i=0; i<5; i++) {
                                CSRAreaEntity *defaultArea = [NSEntityDescription insertNewObjectForEntityForName:@"CSRAreaEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                                
                                defaultArea.areaID = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRAreaEntity"];
                                defaultArea.areaName = AcTECLocalizedStringFromTable(defaultAreaNames[i], @"Localizable");
                                defaultArea.areaIconNum = @(i);
                                defaultArea.sortId = @(i);
                                
                                [_placeEntity addAreasObject:defaultArea];
                                [[CSRDatabaseManager sharedInstance] saveContext];
                            }
                            
                            [CSRAppStateManager sharedInstance].selectedPlace = _placeEntity;
                            if (![[CSRUtilities getValueFromDefaultsForKey:@"kCSRLastSelectedPlaceID"] isEqualToString:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString]]) {
                                
                                [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
                                
                            }
                            
                            [[CSRAppStateManager sharedInstance] setupPlace];
                            if (self.placeDetailVCHandle) {
                                self.placeDetailVCHandle();
                            }
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"reGetDataForPlaceChanged" object:nil];
                            
                            [self.navigationController popViewControllerAnimated:YES];
            }
            
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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                             message:@"Name and Pass Phrase should not be empty, please enter some values"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
//    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:@"Alert!"];
//    [attributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1] range:NSMakeRange(0, [[attributedTitle string] length])];
//    [alertController setValue:attributedTitle forKey:@"attributedTitle"];
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"NamePhraseEmpryAlert", @"Localizable")];
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
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"DeleteCurrentPlaceAlert", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
        [alertController.view setTintColor:DARKORAGE];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
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

- (void)languageChange:(id)sender {
    if (self.isViewLoaded && !self.view.window) {
        self.view = nil;
    }
}

#pragma mark - socket

//获取本机wifi名称
- (NSString *)getWifiName {
    NSArray *ifs = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
    if (!ifs) {
        return nil;
    }
    NSString *WiFiName = nil;
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) {
            // 这里其实对应的有三个key:kCNNetworkInfoKeySSID、kCNNetworkInfoKeyBSSID、kCNNetworkInfoKeySSIDData，
            // 不过它们都是CFStringRef类型的
            WiFiName = [info objectForKey:(__bridge NSString *)kCNNetworkInfoKeySSID];
            break;
        }
    }
    return WiFiName;
}

//获取本机wifi环境下本机ip地址
- (NSString *)localIpAddressForCurrentDevice
{
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    return address;
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
        freeifaddrs(interfaces);
    }
    return nil;
}

- (BOOL)startListenPort:(uint16_t)prot{
    if (prot <= 0) {
        NSAssert(prot > 0, @"prot must be more zero");
    }
    if (!self.serverSocket) {
        self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    [self.serverSocket disconnect];
    NSError *error = nil;
    BOOL result = [self.serverSocket acceptOnPort:prot error:&error];
    if (result && !error) {
        return YES;
    }else{
        return NO;
    }
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    if (!_hud) {
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.delegate = self;
    }
    if (!self.clientSocketArray) {
        self.clientSocketArray = [NSMutableArray array];
    }
    [self.clientSocketArray addObject:newSocket];
    [newSocket readDataWithTimeout:- 1 tag:0];
    
    CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
    NSData *jsonData = [parseLoad composeDatabase];
    
    int value = (int)jsonData.length;
    Byte byteData[4] = {};
    byteData[0] =(Byte)((value & 0xFF000000)>>24);
    byteData[1] =(Byte)((value & 0x00FF0000)>>16);
    byteData[2] =(Byte)((value & 0x0000FF00)>>8);
    byteData[3] =(Byte)((value & 0x000000FF));
    
    Byte byte[] = {0x20,0x18,byteData[0],byteData[1],byteData[2],byteData[3]};
    NSData *temphead = [[NSData alloc] initWithBytes:byte length:6];
    NSMutableData *mutableData = [[NSMutableData alloc] init];
    [mutableData appendData:temphead];
    [mutableData appendData:jsonData];
    
    [newSocket writeData:mutableData withTimeout:-1 tag:0];
    
    if (_hud) {
        [_hud hideAnimated:YES];
        _hud = nil;
    }
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

@end
