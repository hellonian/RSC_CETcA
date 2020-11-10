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
#import "SonosSelectModel.h"
#import "DataModelManager.h"

@interface SonosSceneSettingVC ()<SelectionListViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataMutAry;
@property (nonatomic, strong) SelectionListView *selectionView;
@property (nonatomic, assign) NSInteger operatingSection;
@property (nonatomic, strong) NSMutableArray *didChannels;
@property (nonatomic,strong) UIView *translucentBgView;
@property (nonatomic,strong) UIActivityIndicatorView *indicatorView;

@end

@implementation SonosSceneSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (_deviceID) {
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
        self.navigationItem.title = device.name;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noticeSceneSettingVC:) name:@"noticeSceneSettingVC" object:nil];
    }
    
    self.view.backgroundColor = ColorWithAlpha(234, 238, 243, 1);
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addChannelAction)];
    self.navigationItem.rightBarButtonItem = add;
    
    _dataMutAry = [[NSMutableArray alloc] init];
    SonosSelectModel *m = [[SonosSelectModel alloc] init];
    m.deviceID = _deviceID;
    m.channel = @(-1);
    [_dataMutAry addObject:m];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundView = [[UIView alloc] init];
    _tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_tableView];
    [_tableView autoPinEdgesToSuperviewEdges];
    
    _didChannels = [[NSMutableArray alloc] init];
    
}

- (void)addChannelAction {
    [_didChannels removeAllObjects];
    NSInteger count = 0;
    for (SonosSelectModel *m in _dataMutAry) {
        if ([m.channel integerValue] != -1) {
            NSString *hex = [CSRUtilities stringWithHexNumber:[m.channel integerValue]];
            NSString *bin = [CSRUtilities getBinaryByhex:hex];
            for (int i=0; i<[bin length]; i++) {
                NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
                if ([bit boolValue]) {
                    [_didChannels addObject:@(i)];
                    count ++;
                }
            }
        }
    }
    
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
    if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
        if (count < [device.sonoss count] && [_dataMutAry count] < [device.sonoss count]) {
            SonosSelectModel *m = [[SonosSelectModel alloc] init];
            m.deviceID = _deviceID;
            m.channel = @(-1);
            [_dataMutAry addObject:m];
            [_tableView reloadData];
        }
    }else if ([CSRUtilities belongToMusicController:device.shortName]) {
        DeviceModel *dm = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceID];
        NSString *hex = [CSRUtilities stringWithHexNumber:dm.mcLiveChannels];
        NSString *bin = [CSRUtilities getBinaryByhex:hex];
        NSInteger mCount = 0;
        for (int i=0; i<[bin length]; i++) {
            NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
            if ([bit boolValue]) {
                mCount ++;
            }
        }
        if (count < mCount && [_dataMutAry count] < mCount) {
            SonosSelectModel *m = [[SonosSelectModel alloc] init];
            m.deviceID = _deviceID;
            m.channel = @(-1);
            [_dataMutAry addObject:m];
            [_tableView reloadData];
        }
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_dataMutAry count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
    if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
        return 6;
    }else {
        return 7;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
    UILabel *sLab = [cell viewWithTag:1];
    SonosSelectModel *m = [_dataMutAry objectAtIndex:indexPath.section];
    switch (indexPath.row) {
        case 0:
        {
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
                if ([m.channel integerValue] == -1) {
                    sLab.text = @"";
                }else {
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
                }
            }else if ([CSRUtilities belongToMusicController:device.shortName]) {
                cell.textLabel.text = @"Select Audio Source";
                if ([m.channel integerValue] == -1) {
                    sLab.text = @"";
                }else {
                    sLab.text = [AUDIOSOURCES objectAtIndex:m.source];
                }
            }
        }
            break;
        case 2:
            cell.textLabel.text = @"Play/Stop";
            if ([m.channel integerValue] == -1) {
                sLab.text = @"";
            }else {
                sLab.text = m.play ? @"Play" : @"Stop";
            }
            break;
        case 3:
            cell.textLabel.text = @"Cycle";
            if ([m.channel integerValue] == -1) {
                sLab.text = @"";
            }else {
                CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
                if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
                    sLab.text = [PLAYMODE_SONOS objectAtIndex:m.cycle];
                }else if ([CSRUtilities belongToMusicController:device.shortName]) {
                    sLab.text = [PLAYMODE objectAtIndex:m.cycle];
                }
            }
            break;
        case 4:
            cell.textLabel.text = @"Mute";
            if ([m.channel integerValue] == -1) {
                sLab.text = @"";
            }else {
                sLab.text = m.mute ? @"Mute" : @"Normal";
            }
            break;
        case 5:
            cell.textLabel.text = @"Voice";
            if ([m.channel integerValue] == -1) {
                sLab.text = @"";
            }else {
                sLab.text = [NSString stringWithFormat:@"%ld", m.voice];
            }
            break;
        case 6:
            cell.textLabel.text = @"Channel Power";
            if ([m.channel integerValue] == -1) {
                sLab.text = @"";
            }else {
                sLab.text = m.channelState ? @"ON" : @"OFF";
            }
            break;
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _operatingSection = indexPath.section;
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
                _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Audio Source" mode:SelectionListViewSelectionMode_Source];
                _selectionView.delegate = self;
                [self.view addSubview:_selectionView];
            }
        }
    }else if (indexPath.row == 2) {
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
        m.play = !m.play;
        NSIndexPath *ind = [NSIndexPath indexPathForRow:2 inSection:_operatingSection];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
    }else if (indexPath.row == 3) {
        if (_deviceID) {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
            if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
                CGFloat w = WIDTH * 0.618;
                CGFloat sh = w/0.618;
                CGFloat mh = 4*44+90;
                CGFloat h = sh > mh ? mh : sh;
                NSMutableArray *ary = [[NSMutableArray alloc] init];
                for (int i = 0; i < 4; i ++) {
                    SelectionListModel *slm = [[SelectionListModel alloc] init];
                    slm.value = i;
                    slm.name = PLAYMODE_SONOS[i];
                    [ary addObject:slm];
                }
                _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Cycle" mode:SelectionListViewSelectionMode_Cycle];
                _selectionView.delegate = self;
                [self.view addSubview:_selectionView];
            }else if ([CSRUtilities belongToMusicController:device.shortName]) {
                CGFloat w = WIDTH * 0.618;
                CGFloat sh = w/0.618;
                CGFloat mh = 5*44+90;
                CGFloat h = sh > mh ? mh : sh;
                NSMutableArray *ary = [[NSMutableArray alloc] init];
                for (int i = 0; i < 5; i ++) {
                    SelectionListModel *slm = [[SelectionListModel alloc] init];
                    slm.value = i;
                    slm.name = PLAYMODE[i];
                    [ary addObject:slm];
                }
                _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Cycle" mode:SelectionListViewSelectionMode_Cycle];
                _selectionView.delegate = self;
                [self.view addSubview:_selectionView];
            }
        }
    }else if (indexPath.row == 4) {
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
        m.mute = !m.mute;
        NSIndexPath *ind = [NSIndexPath indexPathForRow:4 inSection:_operatingSection];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
    }else if (indexPath.row == 5) {
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20, (HEIGHT - 60)/2.0, WIDTH-40, 60)];
        slider.backgroundColor = ColorWithAlpha(246, 246, 246, 0.96);
        slider.tintColor = DARKORAGE;
        slider.minimumValue = 0;
        slider.maximumValue = 100;
        [slider addTarget:self action:@selector(voiceAction:) forControlEvents:UIControlEventValueChanged];
        [slider addTarget:self action:@selector(voiceUpAction:) forControlEvents:UIControlEventTouchUpInside];
        [slider addTarget:self action:@selector(voiceUpAction:) forControlEvents:UIControlEventTouchUpOutside];
        [self.view addSubview:slider];
    }else if (indexPath.row == 6) {
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
        m.channelState = !m.channelState;
        NSIndexPath *ind = [NSIndexPath indexPathForRow:6 inSection:_operatingSection];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)selectionListViewCancelAction {
    [_selectionView removeFromSuperview];
    _selectionView = nil;
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
        SelectionListModel *slm = [ary firstObject];
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
        m.songNumber = slm.value;
        NSIndexPath *ind = [NSIndexPath indexPathForRow:1 inSection:_operatingSection];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
    }else if (mode == SelectionListViewSelectionMode_Cycle) {
        SelectionListModel *slm = [ary firstObject];
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
        m.cycle = slm.value;
        NSIndexPath *ind = [NSIndexPath indexPathForRow:3 inSection:_operatingSection];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
    }else if (mode == SelectionListViewSelectionMode_Source) {
        SelectionListModel *slm = [ary firstObject];
        SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
        m.source = slm.value;
        NSIndexPath *ind = [NSIndexPath indexPathForRow:1 inSection:_operatingSection];
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
    }
        
    [_selectionView removeFromSuperview];
    _selectionView = nil;
}

- (void)voiceAction:(UISlider *)slider {
    SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
    m.voice = (NSInteger)slider.value;
    NSIndexPath *ind = [NSIndexPath indexPathForRow:5 inSection:_operatingSection];
    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)voiceUpAction:(UISlider *)slider {
    SonosSelectModel *m = [_dataMutAry objectAtIndex:_operatingSection];
    m.voice = (NSInteger)slider.value;
    NSIndexPath *ind = [NSIndexPath indexPathForRow:5 inSection:_operatingSection];
    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ind] withRowAnimation:UITableViewRowAnimationNone];
    [slider removeFromSuperview];
}

- (void)viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        if (self.sonosSceneSettingHandle) {
            self.sonosSceneSettingHandle(_dataMutAry);
        }
    }
    [super viewWillDisappear:animated];
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
            _selectionView = [[SelectionListView alloc] initWithFrame:CGRectMake((WIDTH-w)/2.0, (HEIGHT-h)/2.0, w, h) dataArray:ary tite:@"Select Channel" mode:SelectionListViewSelectionMode_Sonos];
            _selectionView.delegate = self;
            [self.view addSubview:_selectionView];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
