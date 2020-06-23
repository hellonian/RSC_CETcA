//
//  SceneViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/6/10.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
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

@interface SceneViewController ()<UITableViewDelegate,UITableViewDataSource,SceneMemberCellDelegate>

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
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(editClick)];
    self.navigationItem.rightBarButtonItem = edit;
    
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
    
    if (_sceneIndex) {
        SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
        if (sceneEntity) {
            self.navigationItem.title = sceneEntity.sceneName;
            if ([sceneEntity.members count]>0) {
                _members = [[sceneEntity.members allObjects] mutableCopy];
                [_sceneMemberList reloadData];
            }else {
                _members = [[NSMutableArray alloc] init];
            }
        }
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

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)editClick {
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addClick)];
    self.navigationItem.leftBarButtonItem = add;
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneClick)];
    self.navigationItem.rightBarButtonItem = done;
    
    for (SceneMemberEntity *m in _members) {
        m.colorBlue = @1;
    }
    [_sceneMemberList reloadData];
}

- (void)doneClick {
    UIButton *btn = [[UIButton alloc] init];
    [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
    [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
    [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = back;
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(editClick)];
    self.navigationItem.rightBarButtonItem = edit;
    
    for (SceneMemberEntity *m in _members) {
        m.colorBlue = @0;
    }
    [_sceneMemberList reloadData];
}

- (void)addClick {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_Multiple;
    list.originalMembers = _members;
    
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count] > 0) {
            [self showLoading];
            for (SelectModel *model in devices) {
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
                }else if ([CSRUtilities belongToOneChannelCurtainController:device.shortName]) {
                    [self createSceneMemberCurtain:device channel:1];
                }else if ([CSRUtilities belongToTwoChannelCurtainController:device.shortName]) {
                    [self createSceneMemberCurtain:device channel:1];
                    [self createSceneMemberCurtain:device channel:2];
                }else if ([CSRUtilities belongToFanController:device.shortName]) {
                    [self createSceneMemberFan:device];
                }
            }
            
            [self nextOperation];
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
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
                || [CSRUtilities belongToTwoChannelCurtainController:m.kindString]) {
                Byte byte[] = {0x59, 0x08, [m.channel integerValue], b[1], b[0], e, d0, d1, d2, d3};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:m.deviceID data:cmd];
            }else {
                Byte byte[] = {0x93, 0x07, b[1], b[0], e, d0, d1, d2, d3};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:9];
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
        NSString *t = [CSRUtilities stringWithHexNumber:[device.colorTemperature integerValue]];
        NSString *t1 = [t substringToIndex:2];
        NSString *t2 = [t substringFromIndex:2];
        m.eveD1 = @([CSRUtilities numberWithHexString:t1]);
        m.eveD2 = @([CSRUtilities numberWithHexString:t2]);
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
            NSString *t = [CSRUtilities stringWithHexNumber:[device.colorTemperature integerValue]];
            NSString *t1 = [t substringToIndex:2];
            NSString *t2 = [t substringFromIndex:2];
            m.eveD1 = @([CSRUtilities numberWithHexString:t1]);
            m.eveD2 = @([CSRUtilities numberWithHexString:t2]);
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
    m.eveD0 = @(device.fanState);
    m.eveD1 = @(device.fansSpeed);
    m.eveD2 = @(device.lampState);
    m.eveD3 = @0;
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
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setSceneIDTimerOut) object:nil];
        SceneMemberEntity *m = [self.selects firstObject];
        [self.selects removeObject:m];
        if ([userInfo[@"state"] boolValue]) {
            [_members addObject:m];
            [_sceneMemberList reloadData];
        }else {
            [self.fails addObject:m];
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

- (void)setSceneIDTimerOut {
    SceneMemberEntity *m = [self.selects firstObject];
    [self.selects removeObject:m];
    [self.fails addObject:m];
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
    for (SceneMemberEntity *m in self.fails) {
        CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:m.deviceID];
        s = [NSString stringWithFormat:@"%@ %@",s,d.name];
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"%@ %@",s,AcTECLocalizedStringFromTable(@"setscenefail", @"Localizable")] preferredStyle:UIAlertControllerStyleAlert];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
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
    }
    return _indicatorView;
}

- (void)removeSceneMember:(SceneMemberEntity *)mSceneMember {
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
        || [CSRUtilities belongToTwoChannelCurtainController:mSceneMember.kindString]) {
        Byte byte[] = {0x5d, 0x03, [mSceneMember.channel integerValue], b[1], b[0]};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:mSceneMember.deviceID data:cmd];
    }else {
        Byte byte[] = {0x98, 0x02, b[1], b[0]};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:mSceneMember.deviceID data:cmd];
    }
}

- (void)removeSceneIDTimerOut {
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
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:yes];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
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
        
        [self hideLoading];
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
