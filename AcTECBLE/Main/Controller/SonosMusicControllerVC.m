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

@interface SonosMusicControllerVC ()<UITableViewDelegate, UITableViewDataSource, SocketConnectionToolDelegate>
{
    NSData *retryCmd;
    NSInteger retryCount;
}
@property (nonatomic, strong) UIButton *titleBtn;
@property (nonatomic, copy) NSString *originalName;
@property (nonatomic, strong) NSMutableArray *channelsForName;
@property (weak, nonatomic) IBOutlet UITableView *listView;
@property (nonatomic, strong) NSMutableArray *listDataAry;
@property (weak, nonatomic) IBOutlet UIView *noneView;
@property (nonatomic, strong) NSMutableArray *infoQueue;

@property (nonatomic, strong) SocketConnectionTool *socketTool;

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
    [_listDataAry removeAllObjects];
    [_listView reloadData];
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    deviceEntity.mcSonosInfoVersion = @(-1);
    [[CSRDatabaseManager sharedInstance] saveContext];
    Byte byte[] = {0xea, 0x87};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
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
        
        Byte byte[] = {0xea, 0x77, 0x07};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }
}

- (void)refreshNetworkConnectionStatus:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSInteger type = [userInfo[@"type"] integerValue];
    if ([deviceId isEqualToNumber:_deviceId]) {
        if (type == 1) {
            NSString *status = userInfo[@"staus"];
            [self.socketTool connentHost:status prot:8888];
        }else if (type == 7) {
            BOOL status = [userInfo[@"staus"] boolValue];
            if (!status) {
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
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        _listDataAry = [[device.sonoss allObjects] mutableCopy];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"channel" ascending:YES];
        [_listDataAry sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        [_listView reloadData];
    }
}

- (void)socketConnectFail:(NSNumber *)deviceID {
    if ([deviceID isEqualToNumber:_deviceId]) {
        [self refreshMCChannelsByBluetooth];
    }
}

- (void)refreshMCChannelsByBluetooth {
    Byte byte[] = {0xea, 0x82, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}


@end
