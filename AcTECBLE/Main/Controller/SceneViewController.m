//
//  SceneViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/6/10.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "SceneViewController.h"
#import "SceneMemberCell.h"
#import "SceneMemberEntity.h"
#import "CSRDatabaseManager.h"
#import "DeviceListViewController.h"
#import "SelectModel.h"
#import "CSRUtilities.h"
#import "DeviceModelManager.h"
#import "DataModelManager.h"
#import "PureLayout.h"
#import "CSRAppStateManager.h"
#import "SonosSelectModel.h"
#import "DeviceViewController.h"
#import "CurtainViewController.h"
#import "FanViewController.h"
#import "SocketViewController.h"
#import "SonosSceneSettingVC.h"

@interface SceneViewController ()<UITableViewDelegate,UITableViewDataSource,SceneMemberCellDelegate>
{
    NSInteger retryCount;
    NSData *retryCmd;
    NSNumber *retryDeviceId;
}

@property (weak, nonatomic) IBOutlet UITableView *sceneMemberList;
@property (nonatomic, strong) NSMutableArray *members;
@property (nonatomic, strong) NSMutableArray *selects;
@property (nonatomic, strong) CSRDeviceEntity *mDeviceToApplay;
@property (nonatomic, strong) NSMutableArray *fails;
@property (nonatomic,strong) UIView *translucentBgView;
@property (nonatomic,strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) SceneMemberEntity *mMemberToApply;

@end

@implementation SceneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIButton *btn = [[UIButton alloc] init];
    [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
    [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
    [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = back;
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addClick)];
    self.navigationItem.rightBarButtonItem = add;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sceneAddedSuccessCall:)
                                                 name:@"SceneAddedSuccessCall"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeSceneCall:)
                                                 name:@"RemoveSceneCall"
                                               object:nil];
    
    _sceneMemberList.dataSource = self;
    _sceneMemberList.delegate = self;
    _sceneMemberList.rowHeight = 60.0f;
    _sceneMemberList.backgroundView = [[UIView alloc] init];
    _sceneMemberList.backgroundColor = [UIColor clearColor];
    [_sceneMemberList registerNib:[UINib nibWithNibName:@"SceneMemberCell" bundle:nil] forCellReuseIdentifier:@"SCENEMEMBERCELL"];
    
    _members = [[NSMutableArray alloc] init];
    if ([_sceneIndex integerValue] != 0) {
        SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
        if (sceneEntity) {
            if (sceneEntity.sceneName) {
                self.navigationItem.title = sceneEntity.sceneName;
            }
            
            if ([sceneEntity.members count]>0) {
                _members = [[sceneEntity.members allObjects] mutableCopy];
                [_sceneMemberList reloadData];
            }
        }
    }else {
        CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_srDeviceId];
        if (d) {
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@ %ld",d.name,AcTECLocalizedStringFromTable(@"key", @"Localizable"),(long)_keyNumber];
        }
        
        _sceneIndex = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"SceneEntity_sceneIndex"];
        SceneEntity *scene = [NSEntityDescription insertNewObjectForEntityForName:@"SceneEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
        scene.rcIndex = _sceneIndex;
        scene.sceneID = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"SceneEntity_sceneID"];
        scene.srDeviceId = _srDeviceId;
        [[CSRAppStateManager sharedInstance].selectedPlace addScenesObject:scene];
        [[CSRDatabaseManager sharedInstance] saveContext];
    }
    
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_members count];
}

- (SceneMemberCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SceneMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SCENEMEMBERCELL" forIndexPath:indexPath];
    cell.cellDelegate = self;
    SceneMemberEntity *member = [_members objectAtIndex:indexPath.row];
    [cell configureCellWithSceneMember:member];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self reSetting:indexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        SceneMemberEntity *member = [_members objectAtIndex:indexPath.row];
        [self removeSceneMember:member];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AcTECLocalizedStringFromTable(@"Remove", @"Localizable");
}

- (void)closeAction {
    if (_forSceneRemote) {
        if ([_members count] == 0) {
            SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
            if (scene) {
                [[CSRAppStateManager sharedInstance].selectedPlace removeScenesObject:scene];
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:scene];
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            
            if (self.sceneRemoteHandle) {
                self.sceneRemoteHandle(_keyNumber, 0);
            }
            
        }else {
            if (self.sceneRemoteHandle) {
                self.sceneRemoteHandle(_keyNumber, [_sceneIndex integerValue]);
            }
        }
        [self.navigationController popViewControllerAnimated:YES];
    }else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)addClick {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_Multiple;
    list.originalMembers = _members;
    
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count] > 0) {
            [self showLoading];
            for (id d in devices) {
                if ([d isKindOfClass:[SonosSelectModel class]]) {
                    SonosSelectModel *ssm = (SonosSelectModel *)d;
                    if ([ssm.channel integerValue] != -1) {
                        [self createSceneMemberSonos:ssm];
                    }
                }else {
                    SelectModel *model = (SelectModel *)d;
                    DeviceModel *device = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:model.deviceID];
                    if ([CSRUtilities belongToSwitch:device.shortName]) {
                        [self createSceneMemberSwitch:device channel:1];
                    }else if ([CSRUtilities belongToTwoChannelSwitch:device.shortName]) {
                        if ([model.channel integerValue] == 2) {
                            [self createSceneMemberSwitch:device channel:1];
                        }else if ([model.channel integerValue] == 3) {
                            [self createSceneMemberSwitch:device channel:2];
                        }else if ([model.channel integerValue] == 4) {
                            [self createSceneMemberSwitch:device channel:1];
                            [self createSceneMemberSwitch:device channel:2];
                        }
                    }else if ([CSRUtilities belongToThreeChannelSwitch:device.shortName]) {
                        if ([model.channel integerValue] == 2) {
                            [self createSceneMemberSwitch:device channel:1];
                        }else if ([model.channel integerValue] == 3) {
                            [self createSceneMemberSwitch:device channel:2];
                        }else if ([model.channel integerValue] == 5) {
                            [self createSceneMemberSwitch:device channel:4];
                        }else if ([model.channel integerValue] == 4) {
                            [self createSceneMemberSwitch:device channel:1];
                            [self createSceneMemberSwitch:device channel:2];
                        }else if ([model.channel integerValue] == 6) {
                            [self createSceneMemberSwitch:device channel:1];
                            [self createSceneMemberSwitch:device channel:4];
                        }else if ([model.channel integerValue] == 7) {
                            [self createSceneMemberSwitch:device channel:2];
                            [self createSceneMemberSwitch:device channel:4];
                        }else if ([model.channel integerValue] == 8) {
                            [self createSceneMemberSwitch:device channel:1];
                            [self createSceneMemberSwitch:device channel:2];
                            [self createSceneMemberSwitch:device channel:4];
                        }
                    }else if ([CSRUtilities belongToDimmer:device.shortName]) {
                        [self createSceneMemberDimmer:device channel:1];
                    }else if ([CSRUtilities belongToTwoChannelDimmer:device.shortName]) {
                        if ([model.channel integerValue] == 2) {
                            [self createSceneMemberDimmer:device channel:1];
                        }else if ([model.channel integerValue] == 3) {
                            [self createSceneMemberDimmer:device channel:2];
                        }else if ([model.channel integerValue] == 4) {
                            [self createSceneMemberDimmer:device channel:1];
                            [self createSceneMemberDimmer:device channel:2];
                        }
                    }else if ([CSRUtilities belongToThreeChannelDimmer:device.shortName]) {
                        if ([model.channel integerValue] == 2) {
                            [self createSceneMemberDimmer:device channel:1];
                        }else if ([model.channel integerValue] == 3) {
                            [self createSceneMemberDimmer:device channel:2];
                        }else if ([model.channel integerValue] == 5) {
                            [self createSceneMemberDimmer:device channel:4];
                        }else if ([model.channel integerValue] == 4) {
                            [self createSceneMemberDimmer:device channel:1];
                            [self createSceneMemberDimmer:device channel:2];
                        }else if ([model.channel integerValue] == 6) {
                            [self createSceneMemberDimmer:device channel:1];
                            [self createSceneMemberDimmer:device channel:4];
                        }else if ([model.channel integerValue] == 7) {
                            [self createSceneMemberDimmer:device channel:2];
                            [self createSceneMemberDimmer:device channel:4];
                        }else if ([model.channel integerValue] == 8) {
                            [self createSceneMemberDimmer:device channel:1];
                            [self createSceneMemberDimmer:device channel:2];
                            [self createSceneMemberDimmer:device channel:4];
                        }
                    }else if ([CSRUtilities belongToCWDevice:device.shortName]) {
                        [self createSceneMemberCW:device];
                    }else if ([CSRUtilities belongToRGBDevice:device.shortName]) {
                        [self createSceneMemberRGB:device];
                    }else if ([CSRUtilities belongToRGBCWDevice:device.shortName]) {
                        [self createSceneMemberRGBCW:device];
                    }else if ([CSRUtilities belongToSocketOneChannel:device.shortName]) {
                        [self createSceneMemberSocket:device channel:1];
                    }else if ([CSRUtilities belongToSocketTwoChannel:device.shortName]) {
                        if ([model.channel integerValue] == 2) {
                            [self createSceneMemberSocket:device channel:1];
                        }else if ([model.channel integerValue] == 3) {
                            [self createSceneMemberSocket:device channel:2];
                        }else if ([model.channel integerValue] == 4) {
                            [self createSceneMemberSocket:device channel:1];
                            [self createSceneMemberSocket:device channel:2];
                        }
                    }else if ([CSRUtilities belongToOneChannelCurtainController:device.shortName]
                              || [CSRUtilities belongToHOneChannelCurtainController:device.shortName]) {
                        [self createSceneMemberCurtain:device channel:1];
                    }else if ([CSRUtilities belongToTwoChannelCurtainController:device.shortName]) {
                        if ([model.channel integerValue] == 2) {
                            [self createSceneMemberCurtain:device channel:1];
                        }else if ([model.channel integerValue] == 3) {
                            [self createSceneMemberCurtain:device channel:2];
                        }else if ([model.channel integerValue] == 4) {
                            [self createSceneMemberCurtain:device channel:1];
                            [self createSceneMemberCurtain:device channel:2];
                        }
                    }else if ([CSRUtilities belongToFanController:device.shortName]) {
                        [self createSceneMemberFan:device];
                    }
                }
            }
            
            [self nextOperation];
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (BOOL)nextOperation {
    if ([self.selects count] > 0) {
        SceneMemberEntity *m = [self.selects firstObject];
        _mDeviceToApplay = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:m.deviceID];
        if (_mDeviceToApplay == nil) {
            [self.selects removeObject:m];
            return [self nextOperation];
        }else {
            [self performSelector:@selector(setSceneIDTimerOut) withObject:nil afterDelay:10];
            
            NSInteger s = [_sceneIndex integerValue];
            Byte b[] = {};
            b[0] = (Byte)((s & 0xFF00)>>8);
            b[1] = (Byte)(s & 0x00FF);
            
            NSInteger e = [m.eveType integerValue];
            NSInteger d0 = [m.eveD0 integerValue];
            NSInteger d1 = [m.eveD1 integerValue];
            NSInteger d2 = [m.eveD2 integerValue];
            NSInteger d3 = [m.eveD3 integerValue];
            
            if ([CSRUtilities belongToTwoChannelSwitch:m.kindString]
                || [CSRUtilities belongToThreeChannelSwitch:m.kindString]
                || [CSRUtilities belongToTwoChannelDimmer:m.kindString]
                || [CSRUtilities belongToSocketTwoChannel:m.kindString]
                || [CSRUtilities belongToTwoChannelCurtainController:m.kindString]
                || [CSRUtilities belongToThreeChannelDimmer:m.kindString]
                || [CSRUtilities belongToMusicController:m.kindString]
                || [CSRUtilities belongToSonosMusicController:m.kindString]) {
                Byte byte[] = {0x59, 0x08, [m.channel integerValue], b[1], b[0], e, d0, d1, d2, d3};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                retryCount = 0;
                retryCmd = cmd;
                retryDeviceId = m.deviceID;
                NSLog(@"%@",cmd);
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:m.deviceID data:cmd];
            }else {
                Byte byte[] = {0x93, 0x07, b[1], b[0], e, d0, d1, d2, d3};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:9];
                retryCount = 0;
                retryCmd = cmd;
                retryDeviceId = m.deviceID;
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:m.deviceID data:cmd];
            }
            return YES;
        }
        
    }
    return NO;
}

- (NSMutableArray *)selects {
    if (!_selects) {
        _selects = [[NSMutableArray alloc] init];
    }
    return _selects;
}

- (NSMutableArray *)fails {
    if (!_fails) {
        _fails = [[NSMutableArray alloc] init];
    }
    return _fails;
}

- (void)createSceneMemberSwitch:(DeviceModel *)device channel:(int)channel {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = _sceneIndex;
    m.kindString = device.shortName;
    m.deviceID = device.deviceId;
    m.channel = @(channel);
    if (channel == 1) {
        if (!device.channel1PowerState) {
            m.eveType = @(17);
        }else if (device.channel1PowerState) {
            m.eveType = @(16);
        }
    }else if (channel == 2) {
        if (!device.channel2PowerState) {
            m.eveType = @(17);
        }else if (device.channel2PowerState) {
            m.eveType = @(16);
        }
    }else if (channel == 4) {
        if (!device.channel3PowerState) {
            m.eveType = @(17);
        }else if (device.channel3PowerState) {
            m.eveType = @(16);
        }
    }
    m.eveD0 = @0;
    m.eveD1 = @0;
    m.eveD2 = @0;
    m.eveD3 = @0;
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    [sceneEntity addMembersObject:m];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self.selects addObject:m];
}

- (void)createSceneMemberDimmer:(DeviceModel *)device channel:(int)channel {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = _sceneIndex;
    m.kindString = device.shortName;
    m.deviceID = device.deviceId;
    m.channel = @(channel);
    if (channel == 1) {
        if (!device.channel1PowerState) {
            m.eveType = @(17);
            m.eveD0 = @0;
        }else if (device.channel1PowerState) {
            m.eveType = @(18);
            m.eveD0 = @(device.channel1Level);
        }
    }else if (channel == 2) {
        if (!device.channel2PowerState) {
            m.eveType = @(17);
            m.eveD0 = @0;
        }else if (device.channel2PowerState) {
            m.eveType = @(18);
            m.eveD0 = @(device.channel2Level);
        }
    }else if (channel == 4) {
        if (!device.channel3PowerState) {
            m.eveType = @(17);
            m.eveD0 = @0;
        }else {
            m.eveType = @(18);
            m.eveD0 = @(device.channel3Level);
        }
    }
    m.eveD2 = @0;
    m.eveD3 = @0;
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    [sceneEntity addMembersObject:m];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self.selects addObject:m];
}

- (void)createSceneMemberCW:(DeviceModel *)device {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = _sceneIndex;
    m.kindString = device.shortName;
    m.deviceID = device.deviceId;
    m.channel = @1;
    if (!device.channel1PowerState) {
        m.eveType = @(17);
        m.eveD0 = @0;
        m.eveD1 = @0;
        m.eveD2 = @0;
    }else if (device.channel1PowerState) {
        m.eveType = @(25);
        m.eveD0 = @(device.channel1Level);
        NSInteger c = [device.colorTemperature integerValue];
        m.eveD2 = @((c & 0xFF00) >> 8);
        m.eveD1 = @(c & 0x00FF);
    }
    m.eveD3 = @0;
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    [sceneEntity addMembersObject:m];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self.selects addObject:m];
}

- (void)createSceneMemberRGB:(DeviceModel *)device {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = _sceneIndex;
    m.kindString = device.shortName;
    m.deviceID = device.deviceId;
    m.channel = @1;
    if (!device.channel1PowerState) {
        m.eveType = @(17);
        m.eveD0 = @0;
        m.eveD1 = @0;
        m.eveD2 = @0;
        m.eveD3 = @0;
    }else if (device.channel1PowerState) {
        m.eveType = @(20);
        m.eveD0 = @(device.channel1Level);
        m.eveD1 = device.red;
        m.eveD2 = device.green;
        m.eveD3 = device.blue;
    }
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    [sceneEntity addMembersObject:m];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self.selects addObject:m];
}

- (void)createSceneMemberRGBCW:(DeviceModel *)device {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = _sceneIndex;
    m.kindString = device.shortName;
    m.deviceID = device.deviceId;
    m.channel = @1;
    if (!device.channel1PowerState) {
        m.eveType = @(17);
        m.eveD0 = @0;
        m.eveD1 = @0;
        m.eveD2 = @0;
        m.eveD3 = @0;
    }else if (device.channel1PowerState) {
        if ([device.supports integerValue] == 0) {
            m.eveType = @(20);
            m.eveD0 = @(device.channel1Level);
            m.eveD1 = device.red;
            m.eveD2 = device.green;
            m.eveD3 = device.blue;
        }else if ([device.supports integerValue] == 1) {
            m.eveType = @(25);
            m.eveD0 = @(device.channel1Level);
            NSInteger c = [device.colorTemperature integerValue];
            m.eveD2 = @((c & 0xFF00) >> 8);
            m.eveD1 = @(c & 0x00FF);
            m.eveD3 = @0;
        }
    }
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    [sceneEntity addMembersObject:m];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self.selects addObject:m];
}

- (void)createSceneMemberSocket:(DeviceModel *)device channel:(int)channel {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = _sceneIndex;
    m.kindString = device.shortName;
    m.deviceID = device.deviceId;
    m.channel = @(channel);
    m.eveType = @(29);
    if (channel == 1) {
        m.eveD0 = @(device.channel1PowerState);
        m.eveD1 = @(device.childrenState1);
    }else if (channel == 2) {
        m.eveD0 = @(device.channel2PowerState);
        m.eveD1 = @(device.childrenState2);
    }
    m.eveD2 = @0;
    m.eveD3 = @0;
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    [sceneEntity addMembersObject:m];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self.selects addObject:m];
}

- (void)createSceneMemberCurtain:(DeviceModel *)device channel:(int)channel {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = _sceneIndex;
    m.kindString = device.shortName;
    m.deviceID = device.deviceId;
    m.channel = @(channel);
    if (channel == 1) {
        if (!device.channel1PowerState) {
            m.eveType = @(17);
            m.eveD0 = @0;
        }else if (device.channel1PowerState) {
            m.eveType = @(18);
            m.eveD0 = @(device.channel1Level);
        }
    }else if (channel == 2) {
        if (!device.channel2PowerState) {
            m.eveType = @(17);
            m.eveD0 = @0;
        }else if (device.channel2PowerState) {
            m.eveType = @(18);
            m.eveD0 = @(device.channel2Level);
        }
    }
    m.eveD1 = @0;
    m.eveD2 = @0;
    m.eveD3 = @0;
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    [sceneEntity addMembersObject:m];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self.selects addObject:m];
}

- (void)createSceneMemberFan:(DeviceModel *)device {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = _sceneIndex;
    m.kindString = device.shortName;
    m.deviceID = device.deviceId;
    m.channel = @1;
    m.eveType = @32;
    m.eveD0 = @(device.fanState);
    m.eveD1 = @(device.fansSpeed);
    m.eveD2 = @(device.lampState);
    m.eveD3 = @0;
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    [sceneEntity addMembersObject:m];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self.selects addObject:m];
}

- (void)createSceneMemberMusicController:(DeviceModel *)device channel:(NSInteger)channel {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = _sceneIndex;
    m.kindString = device.shortName;
    m.deviceID = device.deviceId;
    NSString *hex = [CSRUtilities stringWithHexNumber:channel];
    NSString *bin = [CSRUtilities getBinaryByhex:hex];
    for (int i = 0; i < [bin length]; i ++) {
        NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
        if ([bit boolValue]) {
            m.channel = @(i+1);
            break;
        }
    }
    m.eveType = @34;
    m.eveD0 = @(device.mcStatus);
    m.eveD1 = @(device.mcVoice);
    m.eveD2 = @(device.mcSong);
    m.eveD3 = @0;
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    [sceneEntity addMembersObject:m];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self.selects addObject:m];
}

- (void)createSceneMemberSonos:(SonosSelectModel *)model {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = _sceneIndex;
    m.deviceID = model.deviceID;
    m.channel = @(pow(2, [model.channel integerValue]));
    
    NSInteger status;
    CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:model.deviceID];
    if ([CSRUtilities belongToSonosMusicController:de.shortName]) {
        if (model.play) {
            m.eveType = @(226);
        }else {
            m.eveType = @(130);
        }
        
        status = model.play*2+1;
    }else {
        if (model.play) {
            m.eveType = @(166);
        }else {
            m.eveType = @(130);
        }
        status = model.play*2 + model.source*4+1;
    }
    
    m.eveD0 = @(status);
    m.eveD1 = @(model.voice*2);
    m.eveD2 = @(model.songNumber);
    m.eveD3 = @0;
    m.kindString = de.shortName;
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    [sceneEntity addMembersObject:m];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self.selects addObject:m];
}

- (void)sceneAddedSuccessCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceID = userInfo[@"deviceId"];
    NSNumber *sceneID = userInfo[@"index"];
    if (_mDeviceToApplay && [_mDeviceToApplay.deviceId isEqualToNumber:deviceID] && [sceneID isEqualToNumber:_sceneIndex]) {
        if (_mMemberToApply) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reSettingOperationDelayMethod) object:nil];
            if ([userInfo[@"state"] boolValue]) {
                [[CSRDatabaseManager sharedInstance] saveContext];
                [_sceneMemberList reloadData];
            }
            _mDeviceToApplay = nil;
            [self hideLoading];
        }else {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setSceneIDTimerOut) object:nil];
            SceneMemberEntity *m = [self.selects firstObject];
            [self.selects removeObject:m];
            if ([userInfo[@"state"] boolValue]) {
                [_members addObject:m];
                [_sceneMemberList reloadData];
            }else {
                [self.fails addObject:[m.deviceID copy]];
                SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
                [s removeMembersObject:m];
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:m];
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            
            _mDeviceToApplay = nil;
            
            if (![self nextOperation]) {
                if ([self.fails count] > 0) {
                    [self hideLoading];
                    [self showFailAler];
                }else {
                    [self hideLoading];
                }
            }
        }
    }
}

- (void)setSceneIDTimerOut {
    if (retryCount < 1) {
        [self performSelector:@selector(setSceneIDTimerOut) withObject:nil afterDelay:10];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:retryDeviceId data:retryCmd];
        retryCount ++;
    }else {
        SceneMemberEntity *m = [self.selects firstObject];
        [self.selects removeObject:m];
        [self.fails addObject:[m.deviceID copy]];
        SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
        [s removeMembersObject:m];
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:m];
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        _mDeviceToApplay = nil;
        
        if (![self nextOperation]) {
            [self hideLoading];
            [self showFailAler];
        }
    }
}

- (void)showLoading {
    [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
    [[UIApplication sharedApplication].keyWindow addSubview:self.indicatorView];
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

- (void)showFailAler {
    NSString *s = @"";
    for (NSNumber *i in self.fails) {
        CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:i];
        s = [NSString stringWithFormat:@"%@ %@",s,d.name];
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"%@ %@",s,AcTECLocalizedStringFromTable(@"setscenefail", @"Localizable")] preferredStyle:UIAlertControllerStyleAlert];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.fails removeAllObjects];
    }];
    [alert addAction:yes];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIView *)translucentBgView {
    if (!_translucentBgView) {
        _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _translucentBgView.backgroundColor = [UIColor blackColor];
        _translucentBgView.alpha = 0.4;
    }
    return _translucentBgView;
}

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] init];
        _indicatorView.hidesWhenStopped = YES;
        _indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    }
    return _indicatorView;
}

- (void)removeSceneMember:(SceneMemberEntity *)mSceneMember {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"removeSceneMemberAlert", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showLoading];
        [self performSelector:@selector(removeSceneIDTimerOut) withObject:nil afterDelay:10.0];
        _mMemberToApply = mSceneMember;
        _mDeviceToApplay = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:mSceneMember.deviceID];
        
        NSInteger s = [_sceneIndex integerValue];
        Byte b[] = {};
        b[0] = (Byte)((s & 0xFF00)>>8);
        b[1] = (Byte)(s & 0x00FF);
        
        if ([CSRUtilities belongToTwoChannelSwitch:mSceneMember.kindString]
            || [CSRUtilities belongToThreeChannelSwitch:mSceneMember.kindString]
            || [CSRUtilities belongToTwoChannelDimmer:mSceneMember.kindString]
            || [CSRUtilities belongToSocketTwoChannel:mSceneMember.kindString]
            || [CSRUtilities belongToTwoChannelCurtainController:mSceneMember.kindString]
            || [CSRUtilities belongToThreeChannelDimmer:mSceneMember.kindString]
            || [CSRUtilities belongToMusicController:mSceneMember.kindString]
            || [CSRUtilities belongToSonosMusicController:mSceneMember.kindString]) {
            Byte byte[] = {0x5d, 0x03, [mSceneMember.channel integerValue], b[1], b[0]};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
            retryCount = 0;
            retryCmd = cmd;
            retryDeviceId = mSceneMember.deviceID;
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:mSceneMember.deviceID data:cmd];
        }else {
            Byte byte[] = {0x98, 0x02, b[1], b[0]};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
            retryCount = 0;
            retryCmd = cmd;
            retryDeviceId = mSceneMember.deviceID;
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:mSceneMember.deviceID data:cmd];
        }
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:yes];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)removeSceneIDTimerOut {
    if (retryCount < 1) {
        [self performSelector:@selector(removeSceneIDTimerOut) withObject:nil afterDelay:10.0];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:retryDeviceId data:retryCmd];
        retryCount ++;
    }else {
        [self hideLoading];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"%@ %@",_mDeviceToApplay.name,AcTECLocalizedStringFromTable(@"removescenefail", @"Localizable")] preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
            [s removeMembersObject:_mMemberToApply];
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_mMemberToApply];
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            [_members removeObject:_mMemberToApply];
            [_sceneMemberList reloadData];
            _mMemberToApply = nil;
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:cancel];
        [alert addAction:yes];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)removeSceneCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceID = userInfo[@"deviceId"];
    NSNumber *sceneID = userInfo[@"index"];
    if (_mDeviceToApplay && [_mDeviceToApplay.deviceId isEqualToNumber:deviceID] && [sceneID isEqualToNumber:_sceneIndex]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeSceneIDTimerOut) object:nil];
        
        SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
        [s removeMembersObject:_mMemberToApply];
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_mMemberToApply];
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        [_members removeObject:_mMemberToApply];
        [_sceneMemberList reloadData];
        _mMemberToApply = nil;
        [self hideLoading];
    }
}

- (void)reSetting:(NSInteger )row {
    SceneMemberEntity *member = [_members objectAtIndex:row];
    if ([CSRUtilities belongToOneChannelCurtainController:member.kindString]
        || [CSRUtilities belongToTwoChannelCurtainController:member.kindString]
        || [CSRUtilities belongToHOneChannelCurtainController:member.kindString]) {
        CurtainViewController *cvc = [[CurtainViewController alloc] init];
        cvc.deviceId = member.deviceID;
        cvc.source = 1;
        cvc.reloadDataHandle = ^{
            [self reSettingDimmer:member];
        };
        [self.navigationController pushViewController:cvc animated:YES];
    }else if ([CSRUtilities belongToFanController:member.kindString]) {
        FanViewController *fvc = [[FanViewController alloc] init];
        fvc.deviceId = member.deviceID;
        fvc.source = 1;
        fvc.reloadDataHandle = ^{
            [self reSettingFan:member];
        };
        [self.navigationController pushViewController:fvc animated:YES];
    }else if ([CSRUtilities belongToSocketOneChannel:member.kindString]
              || [CSRUtilities belongToSocketTwoChannel:member.kindString]) {
        SocketViewController *svc = [[SocketViewController alloc] init];
        svc.deviceId = member.deviceID;
        svc.source = 1;
        svc.reloadDataHandle = ^{
            [self reSettingSocket:member];
        };
        [self.navigationController pushViewController:svc animated:YES];
    }else if ([CSRUtilities belongToSonosMusicController:member.kindString]) {
        SonosSceneSettingVC *sssvc = [[SonosSceneSettingVC alloc] init];
        sssvc.deviceID = member.deviceID;
        sssvc.source = 1;
        SonosSelectModel *model = [[SonosSelectModel alloc] init];
        model.reSetting = YES;
        model.selected = YES;
        model.deviceID = member.deviceID;
        for (int i=0; i<8; i++) {
            if (([member.channel integerValue] & (NSInteger)pow(2, i))>>i == 1) {
                model.channel = @(i);
                break;
            }
        }
        model.play = [member.eveType integerValue] == 226 ? YES : NO;
        model.voice = [member.eveD1 integerValue]/2;
        model.songNumber = [member.eveD2 integerValue];
        sssvc.sModel = model;
        sssvc.sonosSceneSettingHandle = ^(NSArray * _Nonnull sModels) {
            SonosSelectModel *sm = [sModels firstObject];
            if (sm.play != model.play || sm.voice != model.voice || sm.songNumber != model.songNumber) {
                if (sm.play) {
                    member.eveType = @(226);
                }else {
                    member.eveType = @(130);
                }
                member.eveD0 = @(sm.play*2+1);
                member.eveD1 = @(sm.voice*2);
                member.eveD2 = @(sm.songNumber);
                [self reSettingOperation:member];
            }
        };
        [self.navigationController pushViewController:sssvc animated:YES];
    }else {
        DeviceViewController *dvc = [[DeviceViewController alloc] init];
        dvc.deviceId = member.deviceID;
        dvc.source = 1;
        dvc.reloadDataHandle = ^{
            NSLog(@">> %@",member.deviceID);
            if ([CSRUtilities belongToSwitch:member.kindString]
                || [CSRUtilities belongToTwoChannelSwitch:member.kindString]
                || [CSRUtilities belongToThreeChannelSwitch:member.kindString]) {
                [self reSettingSwitch:member];
            }else if ([CSRUtilities belongToDimmer:member.kindString]
                      || [CSRUtilities belongToTwoChannelDimmer:member.kindString]
                      || [CSRUtilities belongToThreeChannelDimmer:member.kindString]) {
                [self reSettingDimmer:member];
            }else if ([CSRUtilities belongToCWDevice:member.kindString]) {
                [self reSettingCW:member];
            }else if ([CSRUtilities belongToRGBDevice:member.kindString]) {
                [self reSettingRGB:member];
            }else if ([CSRUtilities belongToRGBCWDevice:member.kindString]) {
                [self reSettingRGBCW:member];
            }
        };
        
        [self.navigationController pushViewController:dvc animated:YES];
    }
}

- (void)reSettingSwitch:(SceneMemberEntity *)member {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    if ([member.channel integerValue] == 1) {
        if ([member.eveType integerValue] == 17) {
            if (model.channel1PowerState) {
                member.eveType = @(16);
                [self reSettingOperation:member];
            }
        }else if ([member.eveType integerValue] == 16) {
            if (!model.channel1PowerState) {
                member.eveType = @(17);
                [self reSettingOperation:member];
            }
        }
    }else if ([member.channel integerValue] == 2) {
        if ([member.eveType integerValue] == 17) {
            if (model.channel2PowerState) {
                member.eveType = @(16);
                [self reSettingOperation:member];
            }
        }else if ([member.eveType integerValue] == 16) {
            if (!model.channel2PowerState) {
                member.eveType = @(17);
                [self reSettingOperation:member];
            }
        }
    }else if ([member.channel integerValue] == 4) {
        if ([member.eveType integerValue] == 17) {
            if (model.channel3PowerState) {
                member.eveType = @(16);
                [self reSettingOperation:member];
            }
        }else if ([member.eveType integerValue] == 16) {
            if (!model.channel3PowerState) {
                member.eveType = @(17);
                [self reSettingOperation:member];
            }
        }
    }
}

- (void)reSettingDimmer:(SceneMemberEntity *)member {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    if ([member.channel integerValue] == 1) {
        if ([member.eveType integerValue] == 17) {
            if (model.channel1PowerState) {
                member.eveType = @(18);
                member.eveD0 = @(model.channel1Level);
                [self reSettingOperation:member];
            }
        }else if ([member.eveType integerValue] == 18) {
            if (!model.channel1PowerState) {
                member.eveType = @(17);
                member.eveD0 = @(0);
                [self reSettingOperation:member];
            }else if ([member.eveD0 integerValue] != model.channel1Level) {
                member.eveD0 = @(model.channel1Level);
                [self reSettingOperation:member];
            }
        }
    }else if ([member.channel integerValue] == 2) {
        if ([member.eveType integerValue] == 17) {
            if (model.channel2PowerState) {
                member.eveType = @(18);
                member.eveD0 = @(model.channel2Level);
                [self reSettingOperation:member];
            }
        }else if ([member.eveType integerValue] == 18) {
            if (!model.channel2PowerState) {
                member.eveType = @(17);
                member.eveD0 = @(0);
                [self reSettingOperation:member];
            }else if ([member.eveD0 integerValue] != model.channel2Level) {
                member.eveD0 = @(model.channel2Level);
                [self reSettingOperation:member];
            }
        }
    }else if ([member.channel integerValue] == 4) {
        if ([member.eveType integerValue] == 17) {
            if (model.channel3PowerState) {
                member.eveType = @(18);
                member.eveD0 = @(model.channel3Level);
                [self reSettingOperation:member];
            }
        }else if ([member.eveType integerValue] == 18) {
            if (!model.channel3PowerState) {
                member.eveType = @(17);
                member.eveD0 = @(0);
                [self reSettingOperation:member];
            }else if ([member.eveD0 integerValue] != model.channel3Level) {
                member.eveD0 = @(model.channel3Level);
                [self reSettingOperation:member];
            }
        }
    }
}

- (void)reSettingCW:(SceneMemberEntity *)member {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    if ([member.eveType integerValue] == 17) {
        if (model.channel1PowerState) {
            member.eveType = @(25);
            member.eveD0 = @(model.channel1Level);
            NSInteger c = [model.colorTemperature integerValue];
            member.eveD2 = @((c & 0xFF00) >> 8);
            member.eveD1 = @(c & 0x00FF);
            [self reSettingOperation:member];
        }
    }else if ([member.eveType integerValue] == 25) {
        if (!model.channel1PowerState) {
            member.eveType = @(17);
            member.eveD0 = @0;
            member.eveD1 = @0;
            member.eveD2 = @0;
            [self reSettingOperation:member];
        }else {
            NSInteger c = [model.colorTemperature integerValue];
            NSInteger l = (c & 0xFF00) >> 8;
            NSInteger h = c & 0x00FF;
            if ([member.eveD0 integerValue] != model.channel1Level || [member.eveD2 integerValue] != l || [member.eveD1 integerValue] != h) {
                member.eveD0 = @(model.channel1Level);
                member.eveD2 = @(l);
                member.eveD1 = @(h);
                [self reSettingOperation:member];
            }
        }
    }
}

- (void)reSettingRGB:(SceneMemberEntity *)member {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    if ([member.eveType integerValue] == 17) {
        if (model.channel1PowerState) {
            member.eveType = @(20);
            member.eveD0 = @(model.channel1Level);
            member.eveD1 = model.red;
            member.eveD2 = model.green;
            member.eveD3 = model.blue;
            [self reSettingOperation:member];
        }
    }else if ([member.eveType integerValue] == 20) {
        if (!model.channel1PowerState) {
            member.eveType = @(17);
            member.eveD0 = @0;
            member.eveD1 = @0;
            member.eveD2 = @0;
            member.eveD3 = @0;
            [self reSettingOperation:member];
        }else if ([member.eveD0 integerValue] != model.channel1Level || [member.eveD1 integerValue] != [model.red integerValue] || [member.eveD2 integerValue] != [model.green integerValue] || [member.eveD3 integerValue] != [model.blue integerValue]) {
            member.eveD0 = @(model.channel1Level);
            member.eveD1 = model.red;
            member.eveD2 = model.green;
            member.eveD3 = model.blue;
            [self reSettingOperation:member];
        }
    }
}

- (void)reSettingRGBCW:(SceneMemberEntity *)member {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    if ([member.eveType integerValue] == 17) {
        if (model.channel1PowerState) {
            if ([model.supports integerValue] == 0) {
                member.eveType = @(20);
                member.eveD0 = @(model.channel1Level);
                member.eveD1 = model.red;
                member.eveD2 = model.green;
                member.eveD3 = model.blue;
                [self reSettingOperation:member];
            }else if ([model.supports integerValue] == 1) {
                member.eveType = @(25);
                member.eveD0 = @(model.channel1Level);
                NSInteger c = [model.colorTemperature integerValue];
                member.eveD2 = @((c & 0xFF00) >> 8);
                member.eveD1 = @(c & 0x00FF);
                [self reSettingOperation:member];
            }
        }
    }else if ([member.eveType integerValue] == 20 || [member.eveType integerValue] == 25) {
        if (!model.channel1PowerState) {
            member.eveType = @(17);
            member.eveD0 = @0;
            member.eveD1 = @0;
            member.eveD2 = @0;
            member.eveD3 = @0;
            [self reSettingOperation:member];
        }else if ([member.eveType integerValue] == 20) {
            if ([model.supports integerValue] == 1) {
                member.eveType = @(25);
                member.eveD0 = @(model.channel1Level);
                NSInteger c = [model.colorTemperature integerValue];
                member.eveD2 = @((c & 0xFF00) >> 8);
                member.eveD1 = @(c & 0x00FF);
                [self reSettingOperation:member];
            }else if ([model.supports integerValue] == 0) {
                if ([member.eveD0 integerValue] != model.channel1Level || [member.eveD1 integerValue] != [model.red integerValue] || [member.eveD2 integerValue] != [model.green integerValue] || [member.eveD3 integerValue] != [model.blue integerValue]) {
                    member.eveD0 = @(model.channel1Level);
                    member.eveD1 = model.red;
                    member.eveD2 = model.green;
                    member.eveD3 = model.blue;
                    [self reSettingOperation:member];
                }
            }
        }else if ([member.eveType integerValue] == 25) {
            if ([model.supports integerValue] == 0) {
                member.eveType = @(20);
                member.eveD0 = @(model.channel1Level);
                member.eveD1 = model.red;
                member.eveD2 = model.green;
                member.eveD3 = model.blue;
                [self reSettingOperation:member];
            }else if ([model.supports integerValue] == 1) {
                NSInteger c = [model.colorTemperature integerValue];
                NSInteger l = (c & 0xFF00) >> 8;
                NSInteger h = c & 0x00FF;
                if ([member.eveD0 integerValue] != model.channel1Level || [member.eveD2 integerValue] != l || [member.eveD1 integerValue] != h) {
                    member.eveD0 = @(model.channel1Level);
                    member.eveD2 = @(l);
                    member.eveD1 = @(h);
                    [self reSettingOperation:member];
                }
            }
        }
    }
}

- (void)reSettingSocket:(SceneMemberEntity *)member {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    if ([member.channel integerValue] == 1) {
        if ([member.eveD0 integerValue] != model.channel1PowerState || [member.eveD1 integerValue] != model.childrenState1) {
            member.eveD0 = @(model.channel1PowerState);
            member.eveD1 = @(model.childrenState1);
            [self reSettingOperation:member];
        }
    }else if ([member.channel integerValue] == 2) {
        if ([member.eveD0 integerValue] != model.channel2PowerState || [member.eveD1 integerValue] != model.childrenState2) {
            member.eveD0 = @(model.channel2PowerState);
            member.eveD1 = @(model.childrenState2);
            [self reSettingOperation:member];
        }
    }
}

- (void)reSettingFan:(SceneMemberEntity *)member {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    if ([member.eveD0 boolValue] != model.fanState || [member.eveD1 integerValue] != model.fansSpeed || [member.eveD2 boolValue] != model.lampState) {
        member.eveD0 = @(model.fanState);
        member.eveD1 = @(model.fansSpeed);
        member.eveD2 = @(model.lampState);
        [self reSettingOperation:member];
    }
}

- (void)reSettingOperation:(SceneMemberEntity *)member {
    [self showLoading];
    [self performSelector:@selector(reSettingOperationDelayMethod) withObject:nil afterDelay:10];
    _mMemberToApply = member;
    _mDeviceToApplay = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
    
    NSInteger s = [_sceneIndex integerValue];
    Byte b[] = {};
    b[0] = (Byte)((s & 0xFF00)>>8);
    b[1] = (Byte)(s & 0x00FF);
    
    NSInteger e = [member.eveType integerValue];
    NSInteger d0 = [member.eveD0 integerValue];
    NSInteger d1 = [member.eveD1 integerValue];
    NSInteger d2 = [member.eveD2 integerValue];
    NSInteger d3 = [member.eveD3 integerValue];
    
    if ([CSRUtilities belongToTwoChannelSwitch:member.kindString]
        || [CSRUtilities belongToThreeChannelSwitch:member.kindString]
        || [CSRUtilities belongToTwoChannelDimmer:member.kindString]
        || [CSRUtilities belongToSocketTwoChannel:member.kindString]
        || [CSRUtilities belongToTwoChannelCurtainController:member.kindString]
        || [CSRUtilities belongToThreeChannelDimmer:member.kindString]
        || [CSRUtilities belongToMusicController:member.kindString]
        || [CSRUtilities belongToSonosMusicController:member.kindString]) {
        Byte byte[] = {0x59, 0x08, [member.channel integerValue], b[1], b[0], e, d0, d1, d2, d3};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
        retryCount = 0;
        retryCmd = cmd;
        retryDeviceId = member.deviceID;
        NSLog(@"%@",cmd);
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:member.deviceID data:cmd];
    }else {
        Byte byte[] = {0x93, 0x07, b[1], b[0], e, d0, d1, d2, d3};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:9];
        retryCount = 0;
        retryCmd = cmd;
        retryDeviceId = member.deviceID;
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:member.deviceID data:cmd];
    }
}

- (void)reSettingOperationDelayMethod {
    if (retryCount < 1) {
        [self performSelector:@selector(reSettingOperationDelayMethod) withObject:nil afterDelay:10];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:retryDeviceId data:retryCmd];
        retryCount ++;
    }else {
        [self hideLoading];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"%@ %@",_mDeviceToApplay.name,AcTECLocalizedStringFromTable(@"removescenefail", @"Localizable")] preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            _mMemberToApply = nil;
        }];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
