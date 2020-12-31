//
//  SonosMusicControllerVC.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/9/25.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "SonosMusicControllerVC.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import "DeviceModelManager.h"
#import "DataModelManager.h"
#import "NetworkSettingVC.h"
#import "MusicControllerVC.h"
#import "SocketConnectionTool.h"
#import "AFHTTPSessionManager.h"
#import "PureLayout.h"
#import <MBProgressHUD.h>

@interface SonosMusicControllerVC ()<UITableViewDelegate, UITableViewDataSource, SocketConnectionToolDelegate, MBProgressHUDDelegate>
{
    NSData *retryCmd;
    NSInteger retryCount;
    
    NSInteger latestMCUSVersion;
    NSString *downloadAddress;
    UIButton *updateMCUBtn;
    
    NSInteger refreshWaiting;
}
@property (nonatomic, strong) UIButton *titleBtn;
@property (nonatomic, copy) NSString *originalName;
@property (nonatomic, strong) NSMutableArray *channelsForName;
@property (weak, nonatomic) IBOutlet UITableView *listView;
@property (nonatomic, strong) NSMutableArray *listDataAry;
@property (weak, nonatomic) IBOutlet UIView *noneView;
@property (nonatomic, strong) NSMutableArray *infoQueue;

@property (nonatomic, strong) SocketConnectionTool *socketTool;
@property (weak, nonatomic) IBOutlet UIButton *netWorkSettingBtn;
@property (nonatomic,strong) UIView *translucentBgView;
@property (nonatomic, assign) NSInteger sendCount;
@property (nonatomic, strong) UIAlertController *afterAlert;
@property (nonatomic, strong) MBProgressHUD *updatingHud;

@end

@implementation SonosMusicControllerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (@available(iOS 11.0, *)) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(-35, 0, 0, 0);
    }
    UIButton *btn = [[UIButton alloc] init];
    [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
    [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
    [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = back;
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"refresh", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(refreshInfo)];
    self.navigationItem.rightBarButtonItem = item;
    
    _titleBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_titleBtn addTarget:self action:@selector(rename) forControlEvents:UIControlEventTouchUpInside];
    [_titleBtn setTitleColor:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] forState:UIControlStateNormal];
    [_titleBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
    [_titleBtn sizeToFit];
    self.navigationItem.titleView = _titleBtn;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNetworkConnectionStatus:) name:@"refreshNetworkConnectionStatus" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMCChannels:) name:@"refreshMCChannels" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSonosInfo:) name:@"refreshSonosInfo" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAllInfo:) name:@"refreshAllInfo" object:nil];
    
    _listView.delegate = self;
    _listView.dataSource = self;
    
    if (_deviceId) {
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        [_titleBtn setTitle:device.name forState:UIControlStateNormal];
        
        if ([device.sonoss count]>0) {
            _noneView.hidden = YES;
            _listDataAry = [[device.sonoss allObjects] mutableCopy];
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"channel" ascending:YES];
            [_listDataAry sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [_listView reloadData];
        }else {
            _listView.hidden = YES;
        }
        
        Byte byte[] = {0xea, 0x77, 0x07};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        
        if ([device.hwVersion integerValue] == 2) {
            NSMutableString *mutStr = [NSMutableString stringWithString:device.shortName];
            NSRange range = {0,device.shortName.length};
            [mutStr replaceOccurrencesOfString:@"/" withString:@"" options:NSLiteralSearch range:range];
            NSString *urlString = [NSString stringWithFormat:@"http://39.108.152.134/MCU/%@/%@.php",mutStr,mutStr];
            AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
            sessionManager.responseSerializer.acceptableContentTypes = nil;
            sessionManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
            [sessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                NSDictionary *dic = (NSDictionary *)responseObject;
                latestMCUSVersion = [dic[@"mcu_software_version"] integerValue];
                downloadAddress = dic[@"Download_address"];
                NSLog(@"mcuSVersion:%@  latestMCUSVersion:%ld",device.mcuSVersion, latestMCUSVersion);
                if ([device.mcuSVersion integerValue] != 0 && [device.mcuSVersion integerValue]<latestMCUSVersion) {
                    updateMCUBtn = [UIButton buttonWithType:UIButtonTypeSystem];
                    updateMCUBtn.enabled = NO;
                    [updateMCUBtn setBackgroundColor:[UIColor whiteColor]];
                    [updateMCUBtn setTitle:@"UPDATE MCU" forState:UIControlStateNormal];
                    [updateMCUBtn setTitleColor:DARKORAGE forState:UIControlStateNormal];
                    [updateMCUBtn addTarget:self action:@selector(askUpdateMCU) forControlEvents:UIControlEventTouchUpInside];
                    [self.view addSubview:updateMCUBtn];
                    [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeLeft];
                    [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeRight];
                    [updateMCUBtn autoPinEdgeToSuperviewEdge:ALEdgeBottom];
                    [updateMCUBtn autoSetDimension:ALDimensionHeight toSize:44.0];
                    [_netWorkSettingBtn autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:updateMCUBtn withOffset:-10.0];
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                NSLog(@"%@",error);
            }];
        }
    }
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)rename {
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if (device) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
            NSMutableAttributedString *hogan = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"Rename", @"Localizable")];
            [hogan addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1] range:NSMakeRange(0, [[hogan string] length])];
            [alert setValue:hogan forKey:@"attributedTitle"];
            [alert.view setTintColor:DARKORAGE];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
            UIAlertAction *confirm = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Save", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                UITextField *renameTextField = alert.textFields.firstObject;
                if (![CSRUtilities isStringEmpty:renameTextField.text] && ![renameTextField.text isEqualToString:_originalName]){
                    
                    [_titleBtn setTitle:renameTextField.text forState:UIControlStateNormal];
                    device.name = renameTextField.text;
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    _originalName = renameTextField.text;
                    if (self.reloadDataHandle) {
                        self.reloadDataHandle();
                    }
                    
                }
            }];
            [alert addAction:cancel];
            [alert addAction:confirm];
            
            [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.text = device.name;
                self.originalName = device.name;
            }];
            
            [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)networkingSettingAction:(UIButton *)sender {
    NetworkSettingVC *nsvc = [[NetworkSettingVC alloc] init];
    nsvc.deviceId = _deviceId;
    [self.navigationController pushViewController:nsvc animated:YES];
}

- (NSMutableArray *)channelsForName {
    if (!_channelsForName) {
        _channelsForName = [[NSMutableArray alloc] init];
    }
    return _channelsForName;
}

- (void)refreshMCChannels:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceID = userInfo[@"deviceId"];
    if ([deviceID isEqualToNumber:_deviceId]) {
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        if (model) {
            if (refreshWaiting == 1) {
                for (int i=0; i<8; i++) {
                    if (model.mcLiveChannels & (1 << i)) {
                        for (SonosEntity *so in device.sonoss) {
                            if ([so.channel isEqualToNumber:@(i)]) {
                                so.alive = @(1);
                                break;
                            }
                        }
                    }
                }
                _listDataAry = [[device.sonoss allObjects] mutableCopy];
                NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"channel" ascending:YES];
                [_listDataAry sortUsingDescriptors:[NSArray arrayWithObject:sort]];
                [_listView reloadData];
                refreshWaiting = 0;
            }else if (refreshWaiting == 2) {
                [self.socketTool connentHost:device.ipAddress prot:8888];
                refreshWaiting = 0;
            }else {
                if (model.mcExistChannels != 0) {
                    _noneView.hidden = YES;
                    _listView.hidden = NO;
                    
                    NSString *hex = [CSRUtilities stringWithHexNumber:model.mcExistChannels];
                    NSString *bin = [CSRUtilities getBinaryByhex:hex];
                    for (int i = 0; i < [bin length]; i ++) {
                        NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
                        
                        if ([bit boolValue]) {
                            if ([device.sonoss count] > 0) {
                                BOOL exist = NO;
                                for (SonosEntity *so in device.sonoss) {
                                    if ([so.channel isEqualToNumber:@(i)]) {
                                        exist = YES;
                                        break;
                                    }
                                }
                                if (!exist) {
                                    [self.infoQueue addObject:@(i)];
                                }
                            }else {
                                [self.infoQueue addObject:@(i)];
                            }
                        }
                    }
                    [self nextOperation];
                }else {
                    _noneView.hidden = NO;
                    _listView.hidden = YES;
                }
            }
        }
    }
}

- (BOOL)nextOperation {
    if ([self.infoQueue count] > 0) {
        NSInteger c = [[self.infoQueue firstObject] integerValue];
        
        [self performSelector:@selector(readInfoTimeOut) withObject:nil afterDelay:5];
        
        Byte byte[] = {0xea, 0x86, c, 0x00, 0x00};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
        retryCount = 0;
        retryCmd = cmd;
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        return YES;
    }
    return NO;
}

- (void)readInfoTimeOut {
    if (retryCount < 1) {
        [self performSelector:@selector(readInfoTimeOut) withObject:nil afterDelay:5];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:retryCmd];
        retryCount ++;
    }else {
        [self.infoQueue removeObjectAtIndex:0];
        [self nextOperation];
    }
}

- (NSMutableArray *)infoQueue {
    if (!_infoQueue) {
        _infoQueue = [[NSMutableArray alloc] init];
    }
    return _infoQueue;
}

- (NSMutableArray *)listDataAry {
    if (!_listDataAry) {
        _listDataAry = [[NSMutableArray alloc] init];
    }
    return _listDataAry;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.listDataAry count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sonoscell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"sonoscell"];
        cell.imageView.image = [UIImage imageNamed:@"mc_cell_music"];
    }
    SonosEntity *s = [_listDataAry objectAtIndex:indexPath.row];
    cell.textLabel.text = s.name;
    if ([s.alive boolValue]) {
        cell.textLabel.textColor = ColorWithAlpha(77, 77, 77, 1);
    }else {
        cell.textLabel.textColor = ColorWithAlpha(210, 210, 210, 1);
    }
    switch ([s.modelNumber integerValue]) {
        case 120:
            cell.detailTextLabel.text = @"Connect:Amp";
            break;
        case 90:
            cell.detailTextLabel.text = @"Connect";
            break;
        case 1:
            cell.detailTextLabel.text = @"Play:1";
            break;
        case 11:
            cell.detailTextLabel.text = @"Playbase";
            break;
        case 13:
            cell.detailTextLabel.text = @"One";
            break;
        case 3:
            cell.detailTextLabel.text = @"Play:3";
            break;
        case 5:
            cell.detailTextLabel.text = @"Play:5(v1)";
            break;
        case 6:
            cell.detailTextLabel.text = @"Play:5(v2)";
            break;
        case 9:
            cell.detailTextLabel.text = @"Playbar";
            break;
        case 14:
            cell.detailTextLabel.text = @"Beam";
            break;
        case 17:
            cell.detailTextLabel.text = @"Move";
            break;
        case 18:
            cell.detailTextLabel.text = @"One";
            break;
        case 19:
            cell.detailTextLabel.text = @"Arc";
            break;
        case 20:
            cell.detailTextLabel.text = @"Lamp";
            break;
        case 21:
            cell.detailTextLabel.text = @"Shelf";
            break;
        case 22:
            cell.detailTextLabel.text = @"One SL";
            break;
        case 23:
            cell.detailTextLabel.text = @"Port";
            break;
        case 24:
            cell.detailTextLabel.text = @"Five";
            break;
        case 26:
            cell.detailTextLabel.text = @"Sub";
            break;
        case 27:
            cell.detailTextLabel.text = @"Monaco";
            break;
        case 34:
            cell.detailTextLabel.text = @"Arc SL";
            break;
        case 35:
            cell.detailTextLabel.text = @"Monaco SL";
            break;
        default:
            cell.detailTextLabel.text = @"Sonos";
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    SonosEntity *s = [_listDataAry objectAtIndex:indexPath.row];
    MusicControllerVC *mvc = [[MusicControllerVC alloc] init];
    mvc.deviceId = _deviceId;
    mvc.channel = [s.channel integerValue];
    [self.navigationController pushViewController:mvc animated:YES];
}

- (void)refreshSonosInfo:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceID = userInfo[@"deviceId"];
    if ([deviceID isEqualToNumber:_deviceId]) {
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        if ([device.sonoss count]>0) {
            _noneView.hidden = YES;
            _listView.hidden = NO;
            _listDataAry = [[device.sonoss allObjects] mutableCopy];
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"channel" ascending:YES];
            [_listDataAry sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [_listView reloadData];
        }
        if ([userInfo[@"channel"] integerValue] == [[self.infoQueue firstObject] integerValue]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readInfoTimeOut) object:nil];
            if ([self.infoQueue count] > 0) {
                [self.infoQueue removeObjectAtIndex:0];
                [self nextOperation];
            }
        }
    }
}

- (void)refreshInfo {
//    [_listDataAry removeAllObjects];
//    [_listView reloadData];
//    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
//    deviceEntity.mcSonosInfoVersion = @(-1);
//    [[CSRDatabaseManager sharedInstance] saveContext];
//    Byte byte[] = {0xea, 0x87};
//    NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
//    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    refreshWaiting = 1;
    [self refreshMCChannelsByBluetooth];
}

- (void)refreshAllInfo:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceID = userInfo[@"deviceId"];
    if ([deviceID isEqualToNumber:_deviceId]) {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        NSArray *ary = [deviceEntity.sonoss allObjects];
        for (int i=0; i<ary.count; i++) {
            SonosEntity *so = [ary objectAtIndex:i];
            [deviceEntity removeSonossObject:so];
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:so];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        if (model) {
            model.mcLiveChannels = 0;
            model.mcExistChannels = 0;
        }
        
        if ([self.socketTool.tcpSocketManager isConnected]) {
            [self.socketTool getDeviceList];
        }else {
            Byte byte[] = {0xea, 0x77, 0x07};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }
    }
}

- (void)refreshNetworkConnectionStatus:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSInteger type = [userInfo[@"type"] integerValue];
    if ([deviceId isEqualToNumber:_deviceId]) {
        if (type == 1) {
            refreshWaiting = 2;
            [self refreshMCChannelsByBluetooth];
//            NSString *status = userInfo[@"staus"];
//            [self.socketTool connentHost:status prot:8888];
        }else if (type == 7) {
            BOOL status = [userInfo[@"staus"] boolValue];
            if (!status) {
                if (updateMCUBtn) {
                    updateMCUBtn.enabled = NO;
                }
                refreshWaiting = 0;
                [self refreshMCChannelsByBluetooth];
            }
        }
    }
}

- (SocketConnectionTool *)socketTool {
    if (!_socketTool) {
        _socketTool = [[SocketConnectionTool alloc] init];
        _socketTool.delegate = self;
        _socketTool.deviceID = _deviceId;
    }
    return _socketTool;
}

- (void)saveSonosInfo:(NSNumber *)deviceID {
    if ([deviceID isEqualToNumber:_deviceId]) {
        _noneView.hidden = YES;
        _listView.hidden = NO;
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        _listDataAry = [[device.sonoss allObjects] mutableCopy];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"channel" ascending:YES];
        [_listDataAry sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        [_listView reloadData];
    }
}

- (void)enableMCUUpdateBtn {
    if (updateMCUBtn) {
        updateMCUBtn.enabled = YES;
    }
}

- (void)socketConnectFail:(NSNumber *)deviceID {
    if ([deviceID isEqualToNumber:_deviceId]) {
        if (updateMCUBtn) {
            updateMCUBtn.enabled = NO;
        }
        [self refreshMCChannelsByBluetooth];
    }
}

- (void)refreshMCChannelsByBluetooth {
    Byte byte[] = {0xea, 0x82, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (void)askUpdateMCU {
    [self performSelector:@selector(askUpdateMCUDelay) withObject:nil afterDelay:60.0];
    [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
    if (!_updatingHud) {
        _updatingHud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        _updatingHud.mode = MBProgressHUDModeAnnularDeterminate;
        _updatingHud.delegate = self;
    }
    NSDictionary *dic = @{@"type":@1,@"version":@(latestMCUSVersion),@"url":downloadAddress};
    NSString *jsString = [CSRUtilities convertToJsonData2:dic];
    NSData *jsData = [jsString dataUsingEncoding:NSUTF8StringEncoding];
    [self.socketTool updateMCU:jsData];
}

- (void)freshHudProgress:(CGFloat)progress {
    if (_updatingHud) {
        _updatingHud.progress = progress;
    }
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

- (void)sendedDownloadAddress:(BOOL)result {
    if (result) {
        [self freshHudProgress:0.23];
    }else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(askUpdateMCUDelay) object:nil];
        if (_updatingHud) {
            [_updatingHud hideAnimated:YES];
        }
        [self.translucentBgView removeFromSuperview];
        _translucentBgView = nil;
        if (!_afterAlert) {
            _afterAlert = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"fail", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
            [_afterAlert.view setTintColor:DARKORAGE];
            UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [_afterAlert addAction:yes];
            [self presentViewController:_afterAlert animated:YES completion:nil];
        }else {
            [_afterAlert setMessage:AcTECLocalizedStringFromTable(@"fail", @"Localizable")];
        }
    }
}

- (void)updateMCUResult:(BOOL)result {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(askUpdateMCUDelay) object:nil];
    if (result) {
        [self freshHudProgress:0.78];
        
        [updateMCUBtn removeFromSuperview];
        updateMCUBtn = nil;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedMCUVersionData:) name:@"receivedMCUVersionData" object:nil];
        
        _sendCount = 0;
        [self performSelector:@selector(readVersionTimeOutMethod) withObject:nil afterDelay:3.0];
        Byte byte[] = {0xea, 0x35};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }else {
        if (_updatingHud) {
            [_updatingHud hideAnimated:YES];
        }
        [self.translucentBgView removeFromSuperview];
        _translucentBgView = nil;
        if (!_afterAlert) {
            _afterAlert = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"fail", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
            [_afterAlert.view setTintColor:DARKORAGE];
            UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [_afterAlert addAction:yes];
            [self presentViewController:_afterAlert animated:YES completion:nil];
        }else {
            [_afterAlert setMessage:AcTECLocalizedStringFromTable(@"fail", @"Localizable")];
        }
    }
}

- (void)readVersionTimeOutMethod {
    if (_sendCount < 3) {
        _sendCount ++;
        [self performSelector:@selector(readVersionTimeOutMethod) withObject:nil afterDelay:3.0];
        Byte byte[] = {0xea, 0x35};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }else {
        //读取版本超时
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(askUpdateMCUDelay) object:nil];
        if (_updatingHud) {
            [_updatingHud hideAnimated:YES];
        }
        [self.translucentBgView removeFromSuperview];
        _translucentBgView = nil;
        if (!_afterAlert) {
            _afterAlert = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"mcu_read_version_fail", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
            [_afterAlert.view setTintColor:DARKORAGE];
            UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [_afterAlert addAction:yes];
            [self presentViewController:_afterAlert animated:YES completion:nil];
        }else {
            [_afterAlert setMessage:AcTECLocalizedStringFromTable(@"mcu_read_version_fail", @"Localizable")];
        }
    }
}

- (void)receivedMCUVersionData:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *sourceDeviceId = dic[@"deviceId"];
    BOOL higher = [dic[@"higher"] boolValue];
    if ([sourceDeviceId isEqualToNumber:_deviceId]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readVersionTimeOutMethod) object:nil];
        [self freshHudProgress:1.0];
        if (_updatingHud) {
            [_updatingHud hideAnimated:YES];
        }
        [self.translucentBgView removeFromSuperview];
        _translucentBgView = nil;
        if (higher) {
            //版本更新
            if (!_afterAlert) {
                _afterAlert = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"mcu_update_success", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
                [_afterAlert.view setTintColor:DARKORAGE];
                UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                [_afterAlert addAction:yes];
                [self presentViewController:_afterAlert animated:YES completion:nil];
            }else {
                [_afterAlert setMessage:AcTECLocalizedStringFromTable(@"mcu_update_success", @"Localizable")];
            }
        }else {
            //版本一样或更旧
            if (!_afterAlert) {
                _afterAlert = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"mcu_version_less", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
                [_afterAlert.view setTintColor:DARKORAGE];
                UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                [_afterAlert addAction:yes];
                [self presentViewController:_afterAlert animated:YES completion:nil];
            }else {
                [_afterAlert setMessage:AcTECLocalizedStringFromTable(@"mcu_version_less", @"Localizable")];
            }
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"receivedMCUVersionData" object:nil];
    }
}

- (UIView *)translucentBgView {
    if (!_translucentBgView) {
        _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _translucentBgView.backgroundColor = [UIColor blackColor];
        _translucentBgView.alpha = 0.4;
    }
    return _translucentBgView;
}

- (void)askUpdateMCUDelay {
    if (_updatingHud) {
        [_updatingHud hideAnimated:YES];
    }
    [self.translucentBgView removeFromSuperview];
    _translucentBgView = nil;
    if (!_afterAlert) {
        _afterAlert = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"mcu_update_timeout", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
        [_afterAlert.view setTintColor:DARKORAGE];
        UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [_afterAlert addAction:yes];
        [self presentViewController:_afterAlert animated:YES completion:nil];
    }else {
        [_afterAlert setMessage:AcTECLocalizedStringFromTable(@"mcu_update_timeout", @"Localizable")];
    }
}

@end
