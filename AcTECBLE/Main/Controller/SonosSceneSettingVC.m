//
//  SonosSceneSettingVC.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/11/2.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "SonosSceneSettingVC.h"
#import "CSRDatabaseManager.h"
#import "SelectionListView.h"
#import "SelectionListModel.h"
#import "DeviceModelManager.h"
#import "PureLayout.h"
#import "CSRUtilities.h"
#import "CSRConstants.h"
#import "DataModelManager.h"
#import "SocketConnectionTool.h"
#import "SonosSceneSettingCell.h"
#import "UIViewController+BackButtonHandler.h"

@interface SonosSceneSettingVC ()<SelectionListViewDelegate, UITableViewDelegate, UITableViewDataSource, SonosSceneSettingCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataMutAry;
@property (nonatomic, strong) SelectionListView *selectionView;
@property (nonatomic, assign) NSInteger operatingSection;
@property (nonatomic, strong) NSMutableArray *didChannels;
@property (nonatomic,strong) UIView *translucentBgView;
@property (nonatomic,strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) SocketConnectionTool *socketTool;
@property (nonatomic, strong) NSIndexPath *operatingIndexPath;

@end

@implementation SonosSceneSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (_deviceID) {
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
        self.navigationItem.title = device.name;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noticeSceneSettingVC:) name:@"noticeSceneSettingVC" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNetworkConnectionStatus:) name:@"refreshNetworkConnectionStatus" object:nil];
        
        if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
            Byte byte[] = {0xea, 0x77, 0x07};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
        }
    }
    
    self.view.backgroundColor = ColorWithAlpha(234, 238, 243, 1);
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = done;
    
    _dataMutAry = [[NSMutableArray alloc] init];
    if (_source == 1) {
        SonosSelectModel *m = [[SonosSelectModel alloc] init];
        m.deviceID = _sModel.deviceID;
        m.channel = _sModel.channel;
        m.selected = _sModel.selected;
        m.play = _sModel.play;
        m.voice = _sModel.voice;
        m.reSetting = _sModel.reSetting;
        m.songNumber = _sModel.songNumber;
        if (_deviceID) {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
            if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
                if ([device.sonoss count] > 0) {
                    for (SonosEntity *s in device.sonoss) {
                        if ([s.channel integerValue]==[_sModel.channel integerValue]) {
                            m.name = s.name;
                            break;
                        }
                    }
                }
            }
        }
        [_dataMutAry addObject:m];
    }else {
        if (_deviceID) {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
            if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
                if ([device.sonoss count] > 0) {
                    for (SonosEntity *s in device.sonoss) {
                        SonosSelectModel *m = [[SonosSelectModel alloc] init];
                        m.deviceID = s.deviceID;
                        m.channel = s.channel;
                        m.name = s.name;
                        m.selected = NO;
                        m.play = YES;
                        m.voice = 50;
                        [_dataMutAry addObject:m];
                    }
                }
            }else if ([CSRUtilities belongToMusicController:device.shortName]) {
                DeviceModel *dm = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceID];
                if (dm.mcLiveChannels > 0) {
                    for (int i=0; i<16; i++) {
                        if (((dm.mcLiveChannels & (NSInteger)pow(2, i))>>i) == 1) {
                            SonosSelectModel *m = [[SonosSelectModel alloc] init];
                            m.deviceID = _deviceID;
                            m.channel = @(i);
                            m.name = [NSString stringWithFormat:@"Channel %d",i];
                            m.selected = NO;
                            m.play = YES;
                            m.voice = 50;
                            [_dataMutAry addObject:m];
                        }
                    }
                }else {
                    [self showLoading];
                    [self performSelector:@selector(scanOnlineChannelTimeOut) withObject:nil afterDelay:10];
                    Byte byte[] = {0xea, 0x82, 0x00};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
                }
            }
        }
    }
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundView = [[UIView alloc] init];
    _tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_tableView];
    [_tableView autoPinEdgesToSuperviewEdges];
    
    _didChannels = [[NSMutableArray alloc] init];
    
}

//- (void)addChannelAction {
//    [_didChannels removeAllObjects];
//    NSInteger count = 0;
//    for (SonosSelectModel *m in _dataMutAry) {
//        if ([m.channel integerValue] != -1) {
//            NSString *hex = [CSRUtilities stringWithHexNumber:[m.channel integerValue]];
//            NSString *bin = [CSRUtilities getBinaryByhex:hex];
//            for (int i=0; i<[bin length]; i++) {
//                NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
//                if ([bit boolValue]) {
//                    [_didChannels addObject:@(i)];
//                    count ++;
//                }
//            }
//        }
//    }
//
//    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
//    if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
//        if (count < [device.sonoss count] && [_dataMutAry count] < [device.sonoss count]) {
//            SonosSelectModel *m = [[SonosSelectModel alloc] init];
//            m.deviceID = _deviceID;
//            m.channel = @(-1);
//            [_dataMutAry addObject:m];
//            [_tableView reloadData];
//        }
//    }else if ([CSRUtilities belongToMusicController:device.shortName]) {
//        DeviceModel *dm = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceID];
//        NSString *hex = [CSRUtilities stringWithHexNumber:dm.mcLiveChannels];
//        NSString *bin = [CSRUtilities getBinaryByhex:hex];
//        NSInteger mCount = 0;
//        for (int i=0; i<[bin length]; i++) {
//            NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
//            if ([bit boolValue]) {
//                mCount ++;
//            }
//        }
//        if (count < mCount && [_dataMutAry count] < mCount) {
//            SonosSelectModel *m = [[SonosSelectModel alloc] init];
//            m.deviceID = _deviceID;
//            m.channel = @(-1);
//            [_dataMutAry addObject:m];
//            [_tableView reloadData];
//        }
//    }
//
//}

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return [_dataMutAry count];
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
//    if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
//        return 6;
//    }else {
//        return 7;
//    }
    return [_dataMutAry count];
}

//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//    return 30;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return 44;
    SonosSelectModel *ssm = [_dataMutAry objectAtIndex:indexPath.row];
    if (ssm.selected) {
        return 137;
    }else {
        return 44;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    /*
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SONOSSCENESETTINGCELL"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SONOSSCENESETTINGCELL"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        UILabel *sLabel = [[UILabel alloc] init];
        sLabel.tag = 1;
        sLabel.textColor = DARKORAGE;
        sLabel.font = [UIFont systemFontOfSize:14];
        sLabel.textAlignment = NSTextAlignmentRight;
        [cell addSubview:sLabel];
        [sLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 150, 0, 30)];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    UILabel *sLab = [cell viewWithTag:1];
    SonosSelectModel *m = [_dataMutAry objectAtIndex:indexPath.section];
    switch (indexPath.row) {
        case 0:
        {
            cell.imageView.image = nil;
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
            if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
                cell.textLabel.text = @"Select SONOS";
                if ([m.channel integerValue] == -1) {
                    sLab.text = @"";
                }else {
                    NSString *hex = [CSRUtilities stringWithHexNumber:[m.channel integerValue]];
                    NSString *bin = [CSRUtilities getBinaryByhex:hex];
                    NSString *str;
                    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
                    for (int i=0; i<[bin length]; i++) {
                        NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
                        if ([bit boolValue]) {
                            for (SonosEntity *s in device.sonoss) {
                                if ([s.channel integerValue] == i) {
                                    if ([str length]>0) {
                                        str = [NSString stringWithFormat:@"%@, %@",str, s.name];
                                    }else {
                                        str = s.name;
                                    }
                                    break;
                                }
                            }
                        }
                    }
                    sLab.text = str;
                }
            }else if ([CSRUtilities belongToMusicController:device.shortName]) {
                cell.textLabel.text = @"Select Channel";
                if ([m.channel integerValue] == -1) {
                    sLab.text = @"";
                }else {
                    NSString *hex = [CSRUtilities stringWithHexNumber:[m.channel integerValue]];
                    NSString *bin = [CSRUtilities getBinaryByhex:hex];
                    NSString *str;
                    for (int i=0; i<[bin length]; i++) {
                        NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
                        if ([bit boolValue]) {
                            if ([str length]>0) {
                                str = [NSString stringWithFormat:@"%@, Channel %d", str, i];
                            }else {
                                str = [NSString stringWithFormat:@"Channel %d", i];;
                            }
                        }
                    }
                    sLab.text = str;
                }
            }
        }
            break;
        case 1:
        {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
            if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
                cell.textLabel.text = @"Select Music";
                if (m.dataValid & 0x40) {
                    cell.imageView.image = [UIImage imageNamed:@"Be_selected"];
                    if ([device.remoteBranch length]>0) {
                        NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:device.remoteBranch];
                        if ([jsonDictionary count]>0) {
                            NSArray *songs = jsonDictionary[@"song"];
                            for (NSDictionary *dic in songs) {
                                NSInteger n = [dic[@"id"] integerValue];
                                if (n == m.songNumber) {
                                    sLab.text = dic[@"name"];
                                    break;
                                }
                            }
                        }
                    }
                }else {
                    cell.imageView.image = [UIImage imageNamed:@"To_select"];
                    sLab.text = @"";
                }
            }else if ([CSRUtilities belongToMusicController:device.shortName]) {
                cell.textLabel.text = @"Select Audio Source";
                if (m.dataValid & 0x04) {
                    cell.imageView.image = [UIImage imageNamed:@"Be_selected"];
                    sLab.text = [AUDIOSOURCES objectAtIndex:m.source];
                }else {
                    cell.imageView.image = [UIImage imageNamed:@"To_select"];
                    sLab.text = @"";
                }
            }
        }
            break;
        case 2:
        {
            cell.textLabel.text = @"Play/Stop";
            if (m.dataValid & 0x02) {
                cell.imageView.image = [UIImage imageNamed:@"Be_selected"];
                sLab.text = m.play ? @"Play" : @"Stop";
            }else {
                cell.imageView.image = [UIImage imageNamed:@"To_select"];
                sLab.text = @"";
            }
        }
            break;
        case 3:
        {
            cell.textLabel.text = @"Cycle";
            if (m.dataValid & 0x08) {
                cell.imageView.image = [UIImage imageNamed:@"Be_selected"];
                CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
                if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
                    sLab.text = [PLAYMODE_SONOS objectAtIndex:m.cycle];
                }else if ([CSRUtilities belongToMusicController:device.shortName]) {
                    sLab.text = [PLAYMODE objectAtIndex:m.cycle];
                }
            }else {
                cell.imageView.image = [UIImage imageNamed:@"To_select"];
                sLab.text = @"";
            }
        }
            break;
        case 4:
        {
            cell.textLabel.text = @"Mute";
            if (m.dataValid & 0x10) {
                cell.imageView.image = [UIImage imageNamed:@"Be_selected"];
                sLab.text = m.mute ? @"Mute" : @"Normal";
            }else {
                cell.imageView.image = [UIImage imageNamed:@"To_select"];
                sLab.text = @"";
            }
        }
            break;
        case 5:
        {
            cell.textLabel.text = @"Voice";
            if (m.dataValid & 0x20) {
                cell.imageView.image = [UIImage imageNamed:@"Be_selected"];
                sLab.text = [NSString stringWithFormat:@"%ld", m.voice];
            }else {
                cell.imageView.image = [UIImage imageNamed:@"To_select"];
                sLab.text = @"";
            }
        }
            break;
        case 6:
        {
            cell.textLabel.text = @"Channel Power";
            if (m.dataValid & 0x01) {
                cell.imageView.image = [UIImage imageNamed:@"Be_selected"];
                sLab.text = m.channelState ? @"ON" : @"OFF";
            }else {
                cell.imageView.image = [UIImage imageNamed:@"To_select"];
                sLab.text = @"";
            }
        }
            break;
        default:
            break;
    }
    return cell;
     */
    
    SonosSelectModel *ssm = [_dataMutAry objectAtIndex:indexPath.row];
    if (!ssm.selected) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"unselectedcell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"unselectedcell"];
            cell.imageView.image = [UIImage imageNamed:@"To_select"];
            cell.textLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        }
        cell.textLabel.text = ssm.name;
        return cell;
    }else {
        SonosSceneSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"selectedcell"];
        if (!cell) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"SonosSceneSettingCell" owner:self options:nil] firstObject];
            cell.delegate = self;
        }
        [cell configureCellWithSonosSelectModel:ssm indexPath:indexPath];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    /*
    _operatingSection = indexPath.section;
    SonosSelectModel *m = [_dataMutAry objectAtIndex:indexPath.section];
    if (indexPath.row == 0) {
        if (_deviceID) {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
            if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
                if ([device.sonoss count] > 0) {
                    NSMutableArray *ary = [[NSMutableArray alloc] init];
                    for (SonosEntity *s in device.sonoss) {
                        if (![_didChannels containsObject:s.channel]) {
                            SelectionListModel *slm = [[SelectionListModel alloc] init];
                            slm.value = [s.channel integerValue];
                            slm.name = s.name;
                            [ary addObject:slm];
                        }
                    }
                    CGFloat w = WIDTH * 0.618;
                    CGFloat sh = w/0.618;
                    CGFloat mh = [ary count]*44+90;
                    CGFloat h = sh > mh ? mh : sh;
                    [self.view addSubview:self.translucentBgView];
                    _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select SONOS" mode:SelectionListViewSelectionMode_Sonos];
                    _selectionView.delegate = self;
                    [self.view addSubview:_selectionView];
                }
            }else if ([CSRUtilities belongToMusicController:device.shortName]) {
                DeviceModel *dm = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceID];
                if (dm.mcLiveChannels > 0) {
                    NSMutableArray *ary = [[NSMutableArray alloc] init];
                    NSString *hex = [CSRUtilities stringWithHexNumber:dm.mcLiveChannels];
                    NSString *bin = [CSRUtilities getBinaryByhex:hex];
                    for (int i=0; i<[bin length]; i++) {
                        NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
                        if ([bit boolValue] && ![_didChannels containsObject:@(i)]) {
                            SelectionListModel *slm = [[SelectionListModel alloc] init];
                            slm.value = i;
                            slm.name = [NSString stringWithFormat:@"Channel %d", i];
                            [ary addObject:slm];
                        }
                    }
                    CGFloat w = WIDTH * 0.618;
                    CGFloat sh = w/0.618;
                    CGFloat mh = [ary count]*44+90;
                    CGFloat h = sh > mh ? mh : sh;
                    [self.view addSubview:self.translucentBgView];
                    _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Channel" mode:SelectionListViewSelectionMode_Sonos];
                    _selectionView.delegate = self;
                    [self.view addSubview:_selectionView];
                }else {
                    [self showLoading];
                    [self performSelector:@selector(scanOnlineChannelTimeOut) withObject:nil afterDelay:10];
                    Byte byte[] = {0xea, 0x82, 0x00};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
                }
            }
        }
    }else if (indexPath.row == 1) {
        if (_deviceID) {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
            if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
                
                if (m.dataValid & 0x40) {
                    m.dataValid -= 64;
                    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }else {
                    if ([device.remoteBranch length]>0) {
                        NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:device.remoteBranch];
                        if ([jsonDictionary count]>0) {
                            NSArray *songs = jsonDictionary[@"song"];
                            if ([songs count] > 0) {
                                CGFloat w = WIDTH * 0.618;
                                CGFloat sh = w/0.618;
                                CGFloat mh = [songs count]*44+90;
                                CGFloat h = sh > mh ? mh : sh;
                                NSMutableArray *ary = [[NSMutableArray alloc] init];
                                for (NSDictionary *dic in songs) {
                                    SelectionListModel *slm = [[SelectionListModel alloc] init];
                                    slm.value = [dic[@"id"] integerValue];
                                    slm.name = dic[@"name"];
                                    [ary addObject:slm];
                                }
                                _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Music" mode:SelectionListViewSelectionMode_Music];
                                _selectionView.delegate = self;
                                [self.view addSubview:_selectionView];
                            }
                        }
                    }
                }
            }else if ([CSRUtilities belongToMusicController:device.shortName]) {
                if (m.dataValid & 0x04) {
                    m.dataValid -= 4;
                    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }else {
                    CGFloat w = WIDTH * 0.618;
                    CGFloat sh = w/0.618;
                    CGFloat mh = 8*44+90;
                    CGFloat h = sh > mh ? mh : sh;
                    NSMutableArray *ary = [[NSMutableArray alloc] init];
                    for (int i = 0; i < 8; i ++) {
                        SelectionListModel *slm = [[SelectionListModel alloc] init];
                        slm.value = i;
                        slm.name = AUDIOSOURCES[i];
                        [ary addObject:slm];
                    }
                    [self.view addSubview:self.translucentBgView];
                    _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Audio Source" mode:SelectionListViewSelectionMode_Source];
                    _selectionView.delegate = self;
                    [self.view addSubview:_selectionView];
                }
            }
        }
    }else if (indexPath.row == 2) {
        if (m.dataValid & 0x02) {
            m.dataValid -= 2;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }else {
            CGFloat w = WIDTH * 0.618;
            CGFloat sh = w/0.618;
            CGFloat mh = 2*44+90;
            CGFloat h = sh > mh ? mh : sh;
            NSMutableArray *ary = [[NSMutableArray alloc] init];
            for (int i = 0; i < 2; i ++) {
                SelectionListModel *slm = [[SelectionListModel alloc] init];
                slm.value = i;
                if (i==0) {
                    slm.name = @"Play";
                }else if (i == 1) {
                    slm.name = @"Stop";
                }
                [ary addObject:slm];
            }
            [self.view addSubview:self.translucentBgView];
            _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Play/Stop" mode:SelectionListViewSelectionMode_PlayStop];
            _selectionView.delegate = self;
            [self.view addSubview:_selectionView];
        }
    }else if (indexPath.row == 3) {
        if (m.dataValid & 0x08) {
            m.dataValid -= 8;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }else {
            CGFloat w = WIDTH * 0.618;
            CGFloat sh = w/0.618;
            CGFloat mh = 4*44+90;
            CGFloat h = sh > mh ? mh : sh;
            NSMutableArray *ary = [[NSMutableArray alloc] init];
            for (int i = 0; i < 4; i ++) {
                SelectionListModel *slm = [[SelectionListModel alloc] init];
                slm.value = i;
                if (_deviceID) {
                    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
                    if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
                        slm.name = PLAYMODE_SONOS[i];
                    }else if ([CSRUtilities belongToMusicController:device.shortName]) {
                        slm.name = PLAYMODE[i];
                    }
                }
                [ary addObject:slm];
            }
            [self.view addSubview:self.translucentBgView];
            _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Cycle" mode:SelectionListViewSelectionMode_Cycle];
            _selectionView.delegate = self;
            [self.view addSubview:_selectionView];
        }
    }else if (indexPath.row == 4) {
        if (m.dataValid & 0x10) {
            m.dataValid -= 16;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }else {
            CGFloat w = WIDTH * 0.618;
            CGFloat sh = w/0.618;
            CGFloat mh = 2*44+90;
            CGFloat h = sh > mh ? mh : sh;
            NSMutableArray *ary = [[NSMutableArray alloc] init];
            for (int i = 0; i < 2; i ++) {
                SelectionListModel *slm = [[SelectionListModel alloc] init];
                slm.value = i;
                if (i==0) {
                    slm.name = @"Normal";
                }else if (i == 1) {
                    slm.name = @"Mute";
                }
                [ary addObject:slm];
            }
            [self.view addSubview:self.translucentBgView];
            _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Normal/Mute" mode:SelectionListViewSelectionMode_NormalMute];
            _selectionView.delegate = self;
            [self.view addSubview:_selectionView];
        }
    }else if (indexPath.row == 5) {
        if (m.dataValid & 0x20) {
            m.dataValid -= 32;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }else {
            [self.view addSubview:self.translucentBgView];
            UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20, (HEIGHT - 60)/2.0, WIDTH-40, 60)];
            slider.backgroundColor = ColorWithAlpha(246, 246, 246, 0.96);
            slider.tintColor = DARKORAGE;
            slider.minimumValue = 0;
            slider.maximumValue = 100;
            slider.value = m.voice;
            [slider addTarget:self action:@selector(voiceAction:) forControlEvents:UIControlEventValueChanged];
            [slider addTarget:self action:@selector(voiceUpAction:) forControlEvents:UIControlEventTouchUpInside];
            [slider addTarget:self action:@selector(voiceUpAction:) forControlEvents:UIControlEventTouchUpOutside];
            [self.view addSubview:slider];
        }
    }else if (indexPath.row == 6) {
        if (m.dataValid & 0x01) {
            m.dataValid -= 1;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }else {
            CGFloat w = WIDTH * 0.618;
            CGFloat sh = w/0.618;
            CGFloat mh = 2*44+90;
            CGFloat h = sh > mh ? mh : sh;
            NSMutableArray *ary = [[NSMutableArray alloc] init];
            for (int i = 0; i < 2; i ++) {
                SelectionListModel *slm = [[SelectionListModel alloc] init];
                slm.value = i;
                if (i==0) {
                    slm.name = @"ON";
                }else if (i == 1) {
                    slm.name = @"OFF";
                }
                [ary addObject:slm];
            }
            [self.view addSubview:self.translucentBgView];
            _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Channel Power State" mode:SelectionListViewSelectionMode_ChannelPowerState];
            _selectionView.delegate = self;
            [self.view addSubview:_selectionView];
        }
    }
     */
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    SonosSelectModel *ssm = [_dataMutAry objectAtIndex:indexPath.row];
    if (!ssm.selected) {
        ssm.selected = YES;
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
}

- (void)unSelectAction:(NSIndexPath *)indexPath {
    SonosSelectModel *ssm = [_dataMutAry objectAtIndex:indexPath.row];
    ssm.selected = NO;
    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)setPlayAction:(NSIndexPath *)indexPath {
    SonosSelectModel *ssm = [_dataMutAry objectAtIndex:indexPath.row];
    ssm.play = !ssm.play;
    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)setVoiceAction:(NSIndexPath *)indexPath {
    _operatingIndexPath = indexPath;
    SonosSelectModel *ssm = [_dataMutAry objectAtIndex:indexPath.row];
    [self.view addSubview:self.translucentBgView];
    UIView *sView = [[UIView alloc] initWithFrame:CGRectMake(0, HEIGHT - 80, WIDTH, 60)];
    sView.backgroundColor = ColorWithAlpha(246, 246, 246, 0.96);
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(60, 20, WIDTH-90, 20)];
    slider.tintColor = DARKORAGE;
    slider.minimumValue = 0;
    slider.maximumValue = 100;
    slider.value = ssm.voice;
    [slider addTarget:self action:@selector(voiceAction:) forControlEvents:UIControlEventValueChanged];
    [slider addTarget:self action:@selector(voiceUpAction:) forControlEvents:UIControlEventTouchUpInside];
    [slider addTarget:self action:@selector(voiceUpAction:) forControlEvents:UIControlEventTouchUpOutside];
    [sView addSubview:slider];
    UIImageView *imgV = [[UIImageView alloc] initWithFrame:CGRectMake(30, 19, 22, 22)];
    imgV.image = [UIImage imageNamed:@"Ico_voice"];
    [sView addSubview:imgV];
    [self.view addSubview:sView];
}

- (void)setSelectAction:(NSIndexPath *)indexPath {
    _operatingIndexPath = indexPath;
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
    if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
        if ([device.remoteBranch length]>0) {
            NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:device.remoteBranch];
            if ([jsonDictionary count]>0) {
                NSArray *songs = jsonDictionary[@"song"];
                if ([songs count] > 0) {
                    CGFloat w = WIDTH * 0.618;
                    CGFloat sh = w/0.618;
                    CGFloat mh = [songs count]*44+90;
                    CGFloat h = sh > mh ? mh : sh;
                    NSMutableArray *ary = [[NSMutableArray alloc] init];
                    for (NSDictionary *dic in songs) {
                        SelectionListModel *slm = [[SelectionListModel alloc] init];
                        slm.value = [dic[@"id"] integerValue];
                        slm.name = dic[@"name"];
                        [ary addObject:slm];
                    }
                    [self.view addSubview:self.translucentBgView];
                    _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Music" mode:SelectionListViewSelectionMode_Music];
                    _selectionView.delegate = self;
                    [self.view addSubview:_selectionView];
                }
            }
        }
    }else if ([CSRUtilities belongToMusicController:device.shortName]) {
        CGFloat w = WIDTH * 0.618;
        CGFloat sh = w/0.618;
        CGFloat mh = 8*44+90;
        CGFloat h = sh > mh ? mh : sh;
        NSMutableArray *ary = [[NSMutableArray alloc] init];
        for (int i = 0; i < 8; i ++) {
            SelectionListModel *slm = [[SelectionListModel alloc] init];
            slm.value = i;
            slm.name = AUDIOSOURCES[i];
            [ary addObject:slm];
        }
        [self.view addSubview:self.translucentBgView];
        _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Audio Source" mode:SelectionListViewSelectionMode_Source];
        _selectionView.delegate = self;
        [self.view addSubview:_selectionView];
    }
}

- (void)selectionListViewCancelAction {
    [_selectionView removeFromSuperview];
    _selectionView = nil;
    [_translucentBgView removeFromSuperview];
    _translucentBgView = nil;
}

- (void)selectionListViewSaveAction:(NSArray *)ary selectionMode:(SelectionListViewSelectionMode)mode {
    if (mode == SelectionListViewSelectionMode_Sonos) {
        if ([ary count]>0) {
            NSString *s;
            NSInteger c = 0;
            for (SelectionListModel *slm in ary) {
                c = pow(2, slm.value) + c;
                if ([s length]>0) {
                    s = [NSString stringWithFormat:@"%@, %@",s,slm.name];
                }else {
                    s = slm.name;
                }
            }
            SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
            m.channel = @(c);
            NSIndexPath *ind = [NSIndexPath indexPathForRow:0 inSection:_operatingSection];
            [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
        }
    }else if (mode == SelectionListViewSelectionMode_Music) {
        /*
        SelectionListModel *slm = [ary firstObject];
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
        m.songNumber = slm.value;
        m.dataValid += 64;
        NSIndexPath *ind = [NSIndexPath indexPathForRow:1 inSection:_operatingSection];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
         */
        SelectionListModel *slm = [ary firstObject];
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingIndexPath.row];
        m.songNumber = slm.value;
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:_operatingIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }else if (mode == SelectionListViewSelectionMode_Cycle) {
        SelectionListModel *slm = [ary firstObject];
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
        m.cycle = slm.value;
        m.dataValid += 8;
        NSIndexPath *ind = [NSIndexPath indexPathForRow:3 inSection:_operatingSection];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
    }else if (mode == SelectionListViewSelectionMode_Source) {
        /*
        SelectionListModel *slm = [ary firstObject];
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
        m.source = slm.value;
        m.dataValid += 4;
        NSIndexPath *ind = [NSIndexPath indexPathForRow:1 inSection:_operatingSection];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
         */
        SelectionListModel *slm = [ary firstObject];
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingIndexPath.row];
        m.source = slm.value;
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:_operatingIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }else if (mode == SelectionListViewSelectionMode_PlayStop) {
        SelectionListModel *slm = [ary firstObject];
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
        m.play = slm.value == 0 ? YES : NO;
        m.dataValid += 2;
        NSIndexPath *ind = [NSIndexPath indexPathForRow:2 inSection:_operatingSection];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
    }else if (mode == SelectionListViewSelectionMode_NormalMute) {
        SelectionListModel *slm = [ary firstObject];
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
        m.mute = slm.value == 0 ? NO : YES;
        m.dataValid += 16;
        NSIndexPath *ind = [NSIndexPath indexPathForRow:4 inSection:_operatingSection];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
    }else if (mode == SelectionListViewSelectionMode_ChannelPowerState) {
        SelectionListModel *slm = [ary firstObject];
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
        m.channelState = slm.value == 0 ? YES : NO;
        m.dataValid += 1;
        NSIndexPath *ind = [NSIndexPath indexPathForRow:6 inSection:_operatingSection];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    [_selectionView removeFromSuperview];
    _selectionView = nil;
    [_translucentBgView removeFromSuperview];
    _translucentBgView = nil;
}

- (void)voiceAction:(UISlider *)slider {
    /*
    SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
    m.voice = (NSInteger)slider.value;
    NSIndexPath *ind = [NSIndexPath indexPathForRow:5 inSection:_operatingSection];
    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
     */
    SonosSelectModel *ssm = [_dataMutAry objectAtIndex:_operatingIndexPath.row];
    ssm.voice = (NSInteger)slider.value;
    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:_operatingIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)voiceUpAction:(UISlider *)slider {
    /*
    SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
    m.voice = (NSInteger)slider.value;
    m.dataValid += 32;
    NSIndexPath *ind = [NSIndexPath indexPathForRow:5 inSection:_operatingSection];
    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
    [slider removeFromSuperview];
    [_translucentBgView removeFromSuperview];
    _translucentBgView = nil;
     */
    SonosSelectModel *ssm = [_dataMutAry objectAtIndex:_operatingIndexPath.row];
    ssm.voice = (NSInteger)slider.value;
    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:_operatingIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    [slider.superview removeFromSuperview];
    [_translucentBgView removeFromSuperview];
    _translucentBgView = nil;
}

//- (void)viewWillDisappear:(BOOL)animated {
//    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
//        if (self.sonosSceneSettingHandle) {
//            self.sonosSceneSettingHandle(_dataMutAry);
//        }
//    }
//    [super viewWillDisappear:animated];
//}
- (BOOL)navigationShouldPopOnBackButton {
    NSLog(@"navigationShouldPopOnBackButton");
    if (_source != 1) {
        if (self.sonosSceneSettingHandle) {
            [_dataMutAry removeAllObjects];
            self.sonosSceneSettingHandle(_dataMutAry);
        }
    }
    return YES;
}

- (void)doneAction {
    NSString *string;
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
    for (SonosSelectModel *ssm in _dataMutAry) {
        if (ssm.selected && ssm.play) {
            if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
                if (ssm.songNumber == -1) {
                    if ([string length]>0) {
                        string = [NSString stringWithFormat:@"%@、%@", string, ssm.name];
                    }else {
                        string = ssm.name;
                    }
                }
            }else if ([CSRUtilities belongToMusicController:device.shortName]) {
                if (ssm.source == -1) {
                    if ([string length]>0) {
                        string = [NSString stringWithFormat:@"%@、%@", string, ssm.name];
                    }else {
                        string = ssm.name;
                    }
                }
            }
        }
    }
    if ([string length]>0) {
        NSString *message;
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
        if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
            message = [NSString stringWithFormat:@"%@ %@",string, AcTECLocalizedStringFromTable(@"music_of", @"Localizable")];
        }else if ([CSRUtilities belongToMusicController:device.shortName]) {
            message = [NSString stringWithFormat:@"%@ %@",string, AcTECLocalizedStringFromTable(@"source_of", @"Localizable")];
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"go_back_select", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:yes];
        [self presentViewController:alert animated:YES completion:nil];
    }else {
        if (self.sonosSceneSettingHandle) {
            self.sonosSceneSettingHandle(_dataMutAry);
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)showLoading {
    [self.view addSubview:self.translucentBgView];
    [self.view addSubview:self.indicatorView];
    [self.indicatorView autoCenterInSuperview];
    [self.indicatorView startAnimating];
}

- (void)hideLoading {
    [self.indicatorView stopAnimating];
    [self.indicatorView removeFromSuperview];
    [self.translucentBgView removeFromSuperview];
    self.indicatorView = nil;
    self.translucentBgView = nil;
}

- (UIView *)translucentBgView {
    if (!_translucentBgView) {
        _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _translucentBgView.backgroundColor = [UIColor blackColor];
        _translucentBgView.alpha = 0.4;
    }
    return _translucentBgView;
}

- (void)scanOnlineChannelTimeOut {
    [self hideLoading];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"m_select_error_alert", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alert addAction:yes];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)noticeSceneSettingVC:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceID = userInfo[@"deviceId"];
    if ([deviceID isEqualToNumber:_deviceID]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scanOnlineChannelTimeOut) object:nil];
        [self hideLoading];
        DeviceModel *dm = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceID];
        if (dm.mcLiveChannels > 0) {
            /*
            NSMutableArray *ary = [[NSMutableArray alloc] init];
            NSString *hex = [CSRUtilities stringWithHexNumber:dm.mcLiveChannels];
            NSString *bin = [CSRUtilities getBinaryByhex:hex];
            for (int i=0; i<[bin length]; i++) {
                NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
                if ([bit boolValue] && ![_didChannels containsObject:@(i)]) {
                    SelectionListModel *slm = [[SelectionListModel alloc] init];
                    slm.value = i;
                    slm.name = [NSString stringWithFormat:@"Channel %d", i];
                    [ary addObject:slm];
                }
            }
            CGFloat w = WIDTH * 0.618;
            CGFloat sh = w/0.618;
            CGFloat mh = [ary count]*44+90;
            CGFloat h = sh > mh ? mh : sh;
            [self.view addSubview:self.translucentBgView];
            _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Channel" mode:SelectionListViewSelectionMode_Sonos];
            _selectionView.delegate = self;
            [self.view addSubview:_selectionView];
             */
            [_dataMutAry removeAllObjects];
            for (int i=0; i<16; i++) {
                if (((dm.mcLiveChannels & (NSInteger)pow(2, i))>>i) == 1) {
                    SonosSelectModel *m = [[SonosSelectModel alloc] init];
                    m.deviceID = _deviceID;
                    m.channel = @(i);
                    m.name = [NSString stringWithFormat:@"Channel %d",i];
                    m.selected = NO;
                    m.play = YES;
                    m.voice = 50;
                    [_dataMutAry addObject:m];
                }
            }
            [_tableView reloadData];
        }else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"m_select_error_alert", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
            [alert.view setTintColor:DARKORAGE];
            UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            }];
            [alert addAction:yes];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void)refreshNetworkConnectionStatus:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSInteger type = [userInfo[@"type"] integerValue];
    if ([deviceId isEqualToNumber:_deviceID]) {
        if (type == 1) {
            NSString *status = userInfo[@"staus"];
            [self.socketTool connentHost:status prot:8888];
        }
    }
}

- (SocketConnectionTool *)socketTool {
    if (!_socketTool) {
        _socketTool = [[SocketConnectionTool alloc] init];
        _socketTool.deviceID = _deviceID;
    }
    return _socketTool;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
