//
//  PlacesViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/12/22.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "PlacesViewController.h"
#import "CSRDatabaseManager.h"
#import "CSRPlaceEntity.h"
#import "CSRConstants.h"
#import "CSRmeshStyleKit.h"
#import "CSRUtilities.h"
#import "CSRAppStateManager.h"
#import "PlaceDetailsViewController.h"

#import <MBProgressHUD.h>
#import "CSRParseAndLoad.h"

#import <SystemConfiguration/CaptiveNetwork.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#import "SGQRCode.h"
#import "GCDAsyncSocket.h"
#import "PureLayout.h"

@interface PlacesViewController ()<UITableViewDelegate,UITableViewDataSource,GCDAsyncSocketDelegate,MBProgressHUDDelegate>
{
    NSInteger dataLengthByHead;
    NSData *headData;
    NSMutableData *receiveData;
}

@property (nonatomic,strong) NSMutableArray *placesArray;
@property (nonatomic,assign) NSInteger selectedRow;

@property (nonatomic,strong) MBProgressHUD *hud;

@property (nonatomic,strong) GCDAsyncSocket *serverSocket;
@property (nonatomic,strong) NSMutableArray *clientSocketArray;
@property (nonatomic,strong) UIView *translucentBgView;
@property (nonatomic,strong) UIImageView *QRCodeImageView;
@property (nonatomic,strong) UILabel *QRCodeWordsLabel;

@end

@implementation PlacesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange) name:ZZAppLanguageDidChangeNotification object:nil];
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Place", @"Localizable");
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Setting", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(backSetting) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
    }
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction)];
    self.navigationItem.rightBarButtonItem = add;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 60.0f;
    self.tableView.backgroundView = [[UIView alloc] init];
    self.tableView.backgroundColor = [UIColor clearColor];
}

- (void)addAction {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *create = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"CreatNewPlace", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        PlaceDetailsViewController *pdvc = [[PlaceDetailsViewController alloc] init];
        pdvc.navigationItem.title = AcTECLocalizedStringFromTable(@"CreatNewPlace", @"Localizable");
        [self.navigationController pushViewController:pdvc animated:YES];
        
    }];
    UIAlertAction *join = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"JoinPlace", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if ([self startListenPort:4321]) {
            NSDictionary *dic = @{@"WIFIName":[self getWifiName],
                                  @"IPAddress":[self localIpAddressForCurrentDevice],
                                  @"PORT":@(4321)};
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            if (jsonString) {
                [self.view addSubview:self.translucentBgView];
                [self.view addSubview:self.QRCodeImageView];
                [self.view addSubview:self.QRCodeWordsLabel];
                self.QRCodeImageView.image = [SGQRCodeObtain generateQRCodeWithData:jsonString size:200];
                [self.QRCodeImageView autoCenterInSuperview];
                [self.QRCodeWordsLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_QRCodeImageView withOffset:20.0];
                [self.QRCodeWordsLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
                [self.QRCodeWordsLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20.0];
                [self.QRCodeWordsLabel autoSetDimension:ALDimensionHeight toSize:100];
                
            }
            Byte byte[] = {0x20,0x18};
            headData = [[NSData alloc] initWithBytes:byte length:2];
        }
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:create];
    [alert addAction:join];
    [alert addAction:cancel];
    
    alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    
    [self presentViewController:alert animated:YES completion:nil];
    
    
}

- (void)backSetting{
    if (_QRCodeImageView) {
        [_QRCodeImageView removeFromSuperview];
        _QRCodeImageView = nil;
    }
    
    if (_QRCodeWordsLabel) {
        [_QRCodeWordsLabel removeFromSuperview];
        _QRCodeWordsLabel = nil;
    }
    
    if (_translucentBgView) {
        [_translucentBgView removeFromSuperview];
        _translucentBgView = nil;
    }
    
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshPlaces];
}

- (void)refreshPlaces {
    [self.placesArray removeAllObjects];
    self.placesArray = [[[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"CSRPlaceEntity" withPredicate:nil] mutableCopy];
    if (self.placesArray != nil || [self.placesArray count] != 0 ) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        [_placesArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    }
    [self.tableView reloadData];
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_placesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.textLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        
    }
    UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [accessoryButton setBackgroundImage:[CSRmeshStyleKit imageOfGear] forState:UIControlStateNormal];
    [accessoryButton addTarget:self action:(@selector(jumpDetaileView:)) forControlEvents:UIControlEventTouchUpInside];
    accessoryButton.tag = indexPath.row;
    cell.accessoryView = accessoryButton;
    
    if (self.placesArray && [self.placesArray count] > 0) {
        CSRPlaceEntity *placeEntity = [self.placesArray objectAtIndex:indexPath.row];
        if (placeEntity) {
            cell.textLabel.text = placeEntity.name;
            if ([CSRAppStateManager sharedInstance].selectedPlace && [[placeEntity objectID] isEqual:[[CSRAppStateManager sharedInstance].selectedPlace objectID]]) {
                _selectedRow = indexPath.row;
                cell.imageView.image = [UIImage imageNamed:@"Be_selected"];
            }else {
                cell.imageView.image = [UIImage imageNamed:@"To_select"];
            }
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

-(void)jumpDetaileView:(UIButton *)sender {
    PlaceDetailsViewController *pdvc = [[PlaceDetailsViewController alloc] init];
    pdvc.placeEntity = [self.placesArray objectAtIndex:sender.tag];
    [self.navigationController pushViewController:pdvc animated:YES];
}

#pragma mark - table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == _selectedRow) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if (_placesArray && [_placesArray count] > 0) {
        if ([[_placesArray objectAtIndex:indexPath.row] isKindOfClass:[CSRPlaceEntity class]]) {
            CSRPlaceEntity *placeEntuty = [_placesArray objectAtIndex:indexPath.row];
            [self showAlert:placeEntuty];
        }
    }
}

- (void) showAlert:(CSRPlaceEntity *)placeEntuty
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                             message:@""
                                                                      preferredStyle:UIAlertControllerStyleAlert];
//    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:@"Alert!"];
//    [attributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1] range:NSMakeRange(0, [[attributedTitle string] length])];
//    [alertController setValue:attributedTitle forKey:@"attributedTitle"];
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@ ?",AcTECLocalizedStringFromTable(@"SwitchPlaceAlert", @"Localizable"),placeEntuty.name]];
    [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
    [alertController setValue:attributedMessage forKey:@"attributedMessage"];
    [alertController.view setTintColor:DARKORAGE];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         [CSRAppStateManager sharedInstance].selectedPlace = placeEntuty;
                                                         
                                                         if (![[CSRUtilities getValueFromDefaultsForKey:@"kCSRLastSelectedPlaceID"] isEqualToString:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString]]) {
                                                             
                                                             [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
                                                             
                                                         }
                                                         
                                                         [[CSRAppStateManager sharedInstance] setupPlace];
                                                         
                                                         [self.tableView reloadData];
                                                         [[NSNotificationCenter defaultCenter] postNotificationName:@"reGetDataForPlaceChanged" object:nil];
                                                     }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable")
                                                     style:UIAlertActionStyleCancel 
                                                   handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

#pragma mark - lazy

- (NSMutableArray *)placesArray {
    if (!_placesArray) {
        _placesArray = [[NSMutableArray alloc] init];
    }
    return _placesArray;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

- (void)languageChange {
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Place", @"Localizable");
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Setting", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(backSetting) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
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
    
    if (_QRCodeImageView) {
        [_QRCodeImageView removeFromSuperview];
        _QRCodeImageView = nil;
    }
    
    if (_QRCodeWordsLabel) {
        [_QRCodeWordsLabel removeFromSuperview];
        _QRCodeWordsLabel = nil;
    }
    
    if (_translucentBgView) {
        [_translucentBgView removeFromSuperview];
        _translucentBgView = nil;
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    NSData *head = [data subdataWithRange:NSMakeRange(0, 2)];
    
    if ([head isEqualToData:headData]) {
        NSData *dataLengthData = [data subdataWithRange:NSMakeRange(2, 4)];
        dataLengthByHead = [CSRUtilities numberWithHexString:[CSRUtilities hexStringForData:dataLengthData]];
        receiveData = nil;
        receiveData = [[NSMutableData alloc] init];
        [receiveData appendData:[data subdataWithRange:NSMakeRange(6, data.length-6)]];
    }else {
        [receiveData appendData:data];
    }
    
    if (receiveData.length == dataLengthByHead) {
        NSError *error = nil;
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:receiveData options:NSJSONReadingMutableLeaves error:&error];
        CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
        if (jsonDictionary[@"place"]) {
            NSDictionary *placeDict = jsonDictionary[@"place"];
            NSString *passPhrase = placeDict[@"placePassword"];
            [self.placesArray enumerateObjectsUsingBlock:^(CSRPlaceEntity  *placeEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([placeEntity.passPhrase isEqualToString:passPhrase]) {
                    [parseLoad deleteEntitiesInSelectedPlace:placeEntity];
                    *stop = YES;
                }
            }];
        }
        CSRPlaceEntity *sharePlace = [parseLoad parseIncomingDictionary:jsonDictionary];
        [CSRAppStateManager sharedInstance].selectedPlace = sharePlace;
        if (![[CSRUtilities getValueFromDefaultsForKey:@"kCSRLastSelectedPlaceID"] isEqualToString:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString]]) {
            
            [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
            
        }
        
        [[CSRAppStateManager sharedInstance] setupPlace];
        
        [self refreshPlaces];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reGetDataForPlaceChanged" object:nil];
        
        for (GCDAsyncSocket *clientSocket in self.clientSocketArray) {
            NSData *backData = [@"AcTEC" dataUsingEncoding:NSUTF8StringEncoding];
            [clientSocket writeData:backData withTimeout:-1 tag:1];
        }
        
        if (_hud) {
            [_hud hideAnimated:YES];
            _hud = nil;
        }
    }
    
    [sock readDataWithTimeout:-1 tag:0];
}


- (UIView *)translucentBgView {
    if (!_translucentBgView) {
        _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _translucentBgView.backgroundColor = [UIColor blackColor];
        _translucentBgView.alpha = 0.4;
    }
    return _translucentBgView;
}

- (UIImageView *)QRCodeImageView {
    if (!_QRCodeImageView) {
        _QRCodeImageView = [[UIImageView alloc] init];
        _QRCodeImageView.bounds = CGRectMake(0, 0, 200, 200);
    }
    return _QRCodeImageView;
}

- (UILabel *)QRCodeWordsLabel {
    if (!_QRCodeWordsLabel) {
        _QRCodeWordsLabel = [[UILabel alloc] init];
        _QRCodeWordsLabel.text = AcTECLocalizedStringFromTable(@"RCCodeWords", @"Localizable");
        _QRCodeWordsLabel.numberOfLines = 0;
        _QRCodeWordsLabel.textColor = [UIColor whiteColor];
        _QRCodeWordsLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _QRCodeWordsLabel;
}

@end
