//
//  PIRAutomaticDetailViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2021/3/5.
//  Copyright © 2021 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "PIRAutomaticDetailViewController.h"
#import "PureLayout.h"
#import "DeviceListViewController.h"
#import "SonosSelectModel.h"
#import "DeviceModelManager.h"
#import "CSRUtilities.h"
#import "CSRDatabaseManager.h"
#import "DataModelManager.h"
#import "CSRAppStateManager.h"
#import "SceneMemberExpandModel.h"

#define TFENGSU @[@"自动", @"超低速", @"中低速", @"中速", @"中高速", @"高速", @"超高速"]
#define TWENDU @[@"16 ℃", @"17 ℃", @"18 ℃", @"19 ℃", @"20 ℃", @"21 ℃", @"22 ℃", @"23 ℃", @"24 ℃", @"25 ℃", @"26 ℃", @"27 ℃", @"28 ℃", @"29 ℃", @"30 ℃"]
#define TMOSHI @[@"自动", @"制冷", @"制热", @"除湿", @"送风"]
#define TFENGXIANG @[@"自动", @"向上", @"向下", @"向左", @"向右"]

@interface PIRAutomaticDetailViewController ()<UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate>
{
    NSInteger retryCount;
    NSData *retryCmd;
    NSNumber *retryDeviceId;
}
@property (weak, nonatomic) IBOutlet UILabel *triggerLabel;
@property (nonatomic, assign) int triggerNumber;//1、有人；2、无人；3、有人/无人中的有人；4、有人/无人中的无人；5、温度大于等于；6、温度小于。
@property (nonatomic, strong) NSMutableArray *temperatures;
@property (nonatomic, assign) NSInteger selectedRow;
@property (weak, nonatomic) IBOutlet UILabel *triggerTitleLabel;
@property (nonatomic, strong) NSMutableDictionary *mDic;
@property (nonatomic, strong) NSMutableArray *selects;
@property (nonatomic, strong) NSMutableArray *fails;
@property (nonatomic, strong) CSRDeviceEntity *mDeviceToApplay;
@property (nonatomic, assign) NSInteger applyIndex;
@property (nonatomic, strong) NSMutableArray *members;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, assign) int applyAction;
@property (nonatomic, assign) int applyDelay;
@property (nonatomic, assign) BOOL applyRepeat;
@property (nonatomic, strong) NSMutableArray *scenes;
@property (nonatomic, strong) NSMutableArray *sceneMembers;
@property (nonatomic, strong) SceneMemberEntity *mMemberToApply;
@property (nonatomic, assign) int actionIDToApply;

@end

@implementation PIRAutomaticDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sceneAddedSuccessCall:)
                                                 name:@"SceneAddedSuccessCall"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeSceneCall:)
                                                 name:@"RemoveSceneCall"
                                               object:nil];
    _mDic = [NSMutableDictionary new];
    _members = [NSMutableArray new];
    _actionIDToApply = -1;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 56.0f;
    _tableView.backgroundView = [[UIView alloc] init];
    _tableView.backgroundColor = [UIColor clearColor];
    
    if (_sourseNumber == 1) {
        _triggerTitleLabel.text = AcTECLocalizedStringFromTable(@"body_sensor", @"Localizable");
        self.navigationItem.title = AcTECLocalizedStringFromTable(@"body_sensor", @"Localizable");
        if (_deviceId) {
            CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
            if ([de.remoteBranch length] > 0) {
                NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                if (dic) {
                    NSDictionary *bodySensorDic = [dic objectForKey:@"body_sensor"];
                    if (bodySensorDic) {
                        if ([bodySensorDic count] == 3) {
                            NSArray *bodyActions = [bodySensorDic objectForKey:@"body"][@"actions"];
                            NSArray *nobodyActions = [bodySensorDic objectForKey:@"no_body"][@"actions"];
                            if ([bodyActions count]>0 && [nobodyActions count]>0) {
                                _triggerNumber = 3;
                                _triggerLabel.text = [NSString stringWithFormat:@"%@/%@",AcTECLocalizedStringFromTable(@"body", @"Localizable"),AcTECLocalizedStringFromTable(@"no_body", @"Localizable")];
                                [_members addObject:AcTECLocalizedStringFromTable(@"body", @"Localizable")];
                                for (NSDictionary *action in bodyActions) {
                                    NSNumber *sceneIndex = [action objectForKey:@"scene_index"];
                                    if (sceneIndex) {
                                        SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:sceneIndex];
                                        if (scene) {
                                            if ([scene.members count] > 0) {
                                                for (SceneMemberEntity *member in scene.members) {
                                                    [self addMemberToMembers:member];
                                                }
                                            }
                                        }
                                    }
                                    NSNumber *delay = [action objectForKey:@"delay"];
                                    if (delay) {
                                        [_members addObject:delay];
                                    }
                                }
                                [_members addObject:AcTECLocalizedStringFromTable(@"no_body", @"Localizable")];
                                for (NSDictionary *action in nobodyActions) {
                                    NSNumber *sceneIndex = [action objectForKey:@"scene_index"];
                                    if (sceneIndex) {
                                        SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:sceneIndex];
                                        if (scene) {
                                            if ([scene.members count] > 0) {
                                                for (SceneMemberEntity *member in scene.members) {
                                                    [self addMemberToMembers:member];
                                                }
                                            }
                                        }
                                    }
                                    NSNumber *delay = [action objectForKey:@"delay"];
                                    if (delay) {
                                        [_members addObject:delay];
                                    }
                                }
                                NSNumber *repeat = [bodySensorDic objectForKey:@"repeat"];
                                if (repeat) {
                                    if ([repeat boolValue]) {
                                        [_members addObject:@"Y"];
                                    }else {
                                        [_members addObject:@"N"];
                                    }
                                }
                            }
                        }else if ([bodySensorDic count] == 2) {
                            NSArray *keys = [bodySensorDic allKeys];
                            if ([keys containsObject:@"body"]) {
                                NSArray *bodyActions = [bodySensorDic objectForKey:@"body"][@"actions"];
                                if ([bodyActions count] > 0) {
                                    _triggerNumber = 1;
                                    _triggerLabel.text = AcTECLocalizedStringFromTable(@"body", @"Localizable");
                                    for (NSDictionary *action in bodyActions) {
                                        NSNumber *sceneIndex = [action objectForKey:@"scene_index"];
                                        if (sceneIndex) {
                                            SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:sceneIndex];
                                            if (scene) {
                                                if ([scene.members count] > 0) {
                                                    for (SceneMemberEntity *member in scene.members) {
                                                        [self addMemberToMembers:member];
                                                    }
                                                }
                                            }
                                        }
                                        NSNumber *delay = [action objectForKey:@"delay"];
                                        if (delay) {
                                            [_members addObject:delay];
                                        }
                                    }
                                    NSNumber *repeat = [bodySensorDic objectForKey:@"repeat"];
                                    if (repeat) {
                                        if ([repeat boolValue]) {
                                            [_members addObject:@"Y"];
                                        }else {
                                            [_members addObject:@"N"];
                                        }
                                    }
                                }
                            }else if ([keys containsObject:@"no_body"]) {
                                NSArray *nobodyActions = [bodySensorDic objectForKey:@"no_body"][@"actions"];
                                if ([nobodyActions count] > 0) {
                                    _triggerNumber = 2;
                                    _triggerLabel.text = AcTECLocalizedStringFromTable(@"no_body", @"Localizable");
                                    for (NSDictionary *action in nobodyActions) {
                                        NSNumber *sceneIndex = [action objectForKey:@"scene_index"];
                                        if (sceneIndex) {
                                            SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:sceneIndex];
                                            if (scene) {
                                                if ([scene.members count] > 0) {
                                                    for (SceneMemberEntity *member in scene.members) {
                                                        [self addMemberToMembers:member];
                                                    }
                                                }
                                            }
                                        }
                                        NSNumber *delay = [action objectForKey:@"delay"];
                                        if (delay) {
                                            [_members addObject:delay];
                                        }
                                    }
                                    NSNumber *repeat = [bodySensorDic objectForKey:@"repeat"];
                                    if (repeat) {
                                        if ([repeat boolValue]) {
                                            [_members addObject:@"Y"];
                                        }else {
                                            [_members addObject:@"N"];
                                        }
                                    }
                                }
                            }
                        }
                        _mDic = [[NSMutableDictionary alloc] initWithDictionary:bodySensorDic];
                        NSLog(@"%@", _mDic);
                    }
                }
            }
            [_tableView reloadData];
        }
    }else if (_sourseNumber == 2) {
        _triggerTitleLabel.text = AcTECLocalizedStringFromTable(@"temperature_sensor", @"Localizable");
        self.navigationItem.title = AcTECLocalizedStringFromTable(@"temperature_sensor", @"Localizable");
        _temperatures = [NSMutableArray new];
        for (int i=40; i>=-20; i--) {
            [_temperatures addObject:@(i)];
        }
        _selectedRow = 20;
        if (_deviceId) {
            CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
            if ([de.remoteBranch length] > 0) {
                NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                if (dic) {
                    NSDictionary *tempSensorDic = [dic objectForKey:@"temperature_sensor"];
                    if (tempSensorDic) {
                        if ([tempSensorDic count] == 2) {
                            NSArray *keys = [tempSensorDic allKeys];
                            if ([keys containsObject:@"greater"]) {
                                _triggerNumber = 5;
                                _triggerLabel.text = [NSString stringWithFormat:@"≥%@℃",[tempSensorDic[@"greater"][@"temperature_value"] stringValue]];
                                NSArray *greaterActions = tempSensorDic[@"greater"][@"actions"];
                                if ([greaterActions count] > 0) {
                                    for (NSDictionary *action in greaterActions) {
                                        NSNumber *sceneIndex = [action objectForKey:@"scene_index"];
                                        if (sceneIndex) {
                                            SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:sceneIndex];
                                            if (scene) {
                                                if ([scene.members count] > 0) {
                                                    for (SceneMemberEntity *member in scene.members) {
                                                        [self addMemberToMembers:member];
                                                    }
                                                }
                                            }
                                        }
                                        NSNumber *delay = [action objectForKey:@"delay"];
                                        if (delay) {
                                            [_members addObject:delay];
                                        }
                                    }
                                    NSNumber *repeat = [tempSensorDic objectForKey:@"repeat"];
                                    if (repeat) {
                                        if ([repeat boolValue]) {
                                            [_members addObject:@"Y"];
                                        }else {
                                            [_members addObject:@"N"];
                                        }
                                    }
                                }
                            }else if ([keys containsObject:@"less"]) {
                                _triggerNumber = 6;
                                _triggerLabel.text = [NSString stringWithFormat:@"＜%@℃",[tempSensorDic[@"less"][@"temperature_value"] stringValue]];
                                NSArray *lessActions = tempSensorDic[@"less"][@"actions"];
                                if ([lessActions count] > 0) {
                                    for (NSDictionary *action in lessActions) {
                                        NSNumber *sceneIndex = [action objectForKey:@"scene_index"];
                                        if (sceneIndex) {
                                            SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:sceneIndex];
                                            if (scene) {
                                                if ([scene.members count] > 0) {
                                                    for (SceneMemberEntity *member in scene.members) {
                                                        [self addMemberToMembers:member];
                                                    }
                                                }
                                            }
                                        }
                                        NSNumber *delay = [action objectForKey:@"delay"];
                                        if (delay) {
                                            [_members addObject:delay];
                                        }
                                    }
                                    NSNumber *repeat = [tempSensorDic objectForKey:@"repeat"];
                                    if (repeat) {
                                        if ([repeat boolValue]) {
                                            [_members addObject:@"Y"];
                                        }else {
                                            [_members addObject:@"N"];
                                        }
                                    }
                                }
                            }
                        }
                        _mDic = [[NSMutableDictionary alloc] initWithDictionary:tempSensorDic];
                    }
                }
            }
        }
    }

    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addItemAction)];
    self.navigationItem.rightBarButtonItem = addItem;
    
}

- (IBAction)triggerCondition:(id)sender {
    if (_sourseNumber == 1) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"body", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (_triggerNumber != 1) {
                _triggerLabel.text = AcTECLocalizedStringFromTable(@"body", @"Localizable");
                if (_triggerNumber) {
                    _scenes = [NSMutableArray new];
                    _members = [NSMutableArray new];
                    if (_triggerNumber == 2) {
                        _triggerNumber = 1;
                        NSArray *actions = _mDic[@"no_body"][@"actions"];
                        [self sceneMemberFrom:actions];
                        [self nextMemberOperation];
                    }else if (_triggerNumber == 3 || _triggerNumber == 4) {
                        _triggerNumber = 1;
                        NSArray *bodyActions = _mDic[@"body"][@"actions"];
                        [self sceneMemberFrom:bodyActions];
                        NSArray *nobodyActions = _mDic[@"no_body"][@"actions"];
                        [self sceneMemberFrom:nobodyActions];
                        [self nextMemberOperation];
                    }
                }else {
                    _triggerNumber = 1;
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                    Byte byte[] = {0xea, 0x8b, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                }
            }
        }];
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"no_body", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (_triggerNumber != 2) {
                _triggerLabel.text = AcTECLocalizedStringFromTable(@"no_body", @"Localizable");
                if (_triggerNumber) {
                    _scenes = [NSMutableArray new];
                    _members = [NSMutableArray new];
                    if (_triggerNumber == 1) {
                        _triggerNumber = 2;
                        NSArray *actions = _mDic[@"body"][@"actions"];
                        [self sceneMemberFrom:actions];
                        [self nextMemberOperation];
                    }else if (_triggerNumber == 3 || _triggerNumber == 4) {
                        _triggerNumber = 2;
                        NSArray *bodyActions = _mDic[@"body"][@"actions"];
                        [self sceneMemberFrom:bodyActions];
                        NSArray *nobodyActions = _mDic[@"no_body"][@"actions"];
                        [self sceneMemberFrom:nobodyActions];
                        [self nextMemberOperation];
                    }
                }else {
                    _triggerNumber = 2;
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                    Byte byte[] = {0xea, 0x8b, 0x00, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                }
            }
        }];
        UIAlertAction *action3 = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@/%@",AcTECLocalizedStringFromTable(@"body", @"Localizable"),AcTECLocalizedStringFromTable(@"no_body", @"Localizable")] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (_triggerNumber != 3) {
                _triggerLabel.text = [NSString stringWithFormat:@"%@/%@",AcTECLocalizedStringFromTable(@"body", @"Localizable"),AcTECLocalizedStringFromTable(@"no_body", @"Localizable")];
                if (_triggerNumber) {
                    _scenes = [NSMutableArray new];
                    _members = [NSMutableArray new];
                    if (_triggerNumber == 1) {
                        _triggerNumber = 3;
                        NSArray *actions = _mDic[@"body"][@"actions"];
                        [self sceneMemberFrom:actions];
                        [self nextMemberOperation];
                    }else if (_triggerNumber == 2) {
                        _triggerNumber = 3;
                        NSArray *actions = _mDic[@"no_body"][@"actions"];
                        [self sceneMemberFrom:actions];
                        [self nextMemberOperation];
                    }
                }else {
                    _triggerNumber = 3;
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                    Byte byte[] = {0xea, 0x8b, 0x00, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00, 0x00};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                }
            }
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action1];
        [alert addAction:action2];
        [alert addAction:action3];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }else if (_sourseNumber == 2) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"temperature_greater_equal", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showTemperaturePickAlerWithTrigger:5];
        }];
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"temperature_less", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showTemperaturePickAlerWithTrigger:6];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
        
        [alert addAction:action1];
        [alert addAction:action2];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)showTemperaturePickAlerWithTrigger:(int)trigger {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"\n\n\n\n\n\n" preferredStyle:UIAlertControllerStyleAlert];
    [alert.view setTintColor:DARKORAGE];
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.dataSource = self;
    picker.delegate = self;
    [alert.view addSubview:picker];
    [picker selectRow:20 inComponent:0 animated:YES];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *save = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Save", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (trigger == 5) {
            if (_triggerNumber != 5) {
                _triggerLabel.text = [NSString stringWithFormat:@"≥%@℃",[_temperatures[_selectedRow] stringValue]];
                if (_triggerNumber == 6) {
                    _scenes = [NSMutableArray new];
                    _members = [NSMutableArray new];
                    _triggerNumber = 5;
                    NSArray *actions = _mDic[@"less"][@"actions"];
                    [self sceneMemberFrom:actions];
                    [self nextMemberOperation];
                }else {
                    _triggerNumber = 5;
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                    NSInteger temp = [_temperatures[_selectedRow] integerValue];
                    if (temp < 0) {
                        temp = ((-temp) & 0x7F) + 0x80;
                    }else {
                        temp = (temp & 0x7F);
                    }
                    Byte byte[] = {0xea, 0x8b, 0x00, 0x02, 0x02, 0x00, temp, 0x00, 0x00, 0x00};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                }
            }
        }else if (trigger == 6) {
            if (_triggerNumber != 6) {
                _triggerLabel.text = [NSString stringWithFormat:@"＜%@℃",[_temperatures[_selectedRow] stringValue]];
                if (_triggerNumber == 5) {
                    _scenes = [NSMutableArray new];
                    _members = [NSMutableArray new];
                    _triggerNumber = 6;
                    NSArray *actions = _mDic[@"greater"][@"actions"];
                    [self sceneMemberFrom:actions];
                    [self nextMemberOperation];
                }else {
                    _triggerNumber = 6;
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                    NSInteger temp = [_temperatures[_selectedRow] integerValue];
                    if (temp < 0) {
                        temp = ((-temp) & 0x7F) + 0x80;
                    }else {
                        temp = (temp & 0x7F);
                    }
                    Byte byte[] = {0xea, 0x8b, 0x00, 0x02, 0x02, 0x04, temp, 0x00, 0x00, 0x00};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                }
            }
        }
    }];
    [alert addAction:cancel];
    [alert addAction:save];
    [self presentViewController:alert animated:YES completion:nil];
    [picker autoSetDimension:ALDimensionWidth toSize:260];
    [picker autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [picker autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
    [picker autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:55];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_temperatures count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"%@ ℃",[_temperatures[row] stringValue]];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    _selectedRow = row;
}

- (void)addItemAction {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_Multiple;
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count] > 0) {
            NSMutableArray *allIndexs = [[NSMutableArray alloc] initWithObjects:@(0), nil];
            for (SceneEntity *scene in [CSRAppStateManager sharedInstance].selectedPlace.scenes) {
                [allIndexs addObject:scene.rcIndex];
            }
            _applyIndex = 0;
            while ([allIndexs containsObject:@(_applyIndex)]) {
                _applyIndex = arc4random()%65470 + 64;
            }
            SceneEntity *newScene = [NSEntityDescription insertNewObjectForEntityForName:@"SceneEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
            newScene.rcIndex = @(_applyIndex);
            newScene.sceneID = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"SceneEntity_sceneID"];
            newScene.srDeviceId = _deviceId;
            [[CSRAppStateManager sharedInstance].selectedPlace addScenesObject:newScene];
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            for (id d in devices) {
                if ([d isKindOfClass:[SonosSelectModel class]]) {
                    SonosSelectModel *ssm = (SonosSelectModel *)d;
                    if ([ssm.channel integerValue] != -1) {
                        SceneMemberEntity *m = [self createSceneMemberSonos:ssm];
                        [newScene addMembersObject:m];
                        [[CSRDatabaseManager sharedInstance] saveContext];
                        [self.selects addObject:m];
                    }
                }else {
                    SelectModel *model = (SelectModel *)d;
                    DeviceModel *device = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:model.deviceID];
                    if ([CSRUtilities belongToSwitch:device.shortName]
                        || [CSRUtilities belongToSocketOneChannel:device.shortName]) {
                        SceneMemberEntity *m = [self createSceneMemberSwitch:device channel:1];
                        [newScene addMembersObject:m];
                        [[CSRDatabaseManager sharedInstance] saveContext];
                        [self.selects addObject:m];
                    }else if ([CSRUtilities belongToTwoChannelSwitch:device.shortName]
                              || [CSRUtilities belongToSocketTwoChannel:device.shortName]) {
                        if ([model.channel integerValue] == 2) {
                            SceneMemberEntity *m = [self createSceneMemberSwitch:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                        }else if ([model.channel integerValue] == 3) {
                            SceneMemberEntity *m = [self createSceneMemberSwitch:device channel:2];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                        }else if ([model.channel integerValue] == 4) {
                            SceneMemberEntity *m = [self createSceneMemberSwitch:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                            SceneMemberEntity *m2 = [self createSceneMemberSwitch:device channel:1];
                            [newScene addMembersObject:m2];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m2];
                        }
                    }else if ([CSRUtilities belongToThreeChannelSwitch:device.shortName]) {
                        if ([model.channel integerValue] == 2) {
                            SceneMemberEntity *m = [self createSceneMemberSwitch:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                        }else if ([model.channel integerValue] == 3) {
                            SceneMemberEntity *m = [self createSceneMemberSwitch:device channel:2];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                        }else if ([model.channel integerValue] == 5) {
                            SceneMemberEntity *m = [self createSceneMemberSwitch:device channel:4];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                        }else if ([model.channel integerValue] == 4) {
                            SceneMemberEntity *m = [self createSceneMemberSwitch:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                            SceneMemberEntity *m2 = [self createSceneMemberSwitch:device channel:2];
                            [newScene addMembersObject:m2];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m2];
                        }else if ([model.channel integerValue] == 6) {
                            SceneMemberEntity *m = [self createSceneMemberSwitch:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                            SceneMemberEntity *m4 = [self createSceneMemberSwitch:device channel:4];
                            [newScene addMembersObject:m4];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m4];
                        }else if ([model.channel integerValue] == 7) {
                            SceneMemberEntity *m2 = [self createSceneMemberSwitch:device channel:2];
                            [newScene addMembersObject:m2];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m2];
                            SceneMemberEntity *m4 = [self createSceneMemberSwitch:device channel:4];
                            [newScene addMembersObject:m4];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m4];
                        }else if ([model.channel integerValue] == 8) {
                            SceneMemberEntity *m = [self createSceneMemberSwitch:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                            SceneMemberEntity *m2 = [self createSceneMemberSwitch:device channel:2];
                            [newScene addMembersObject:m2];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m2];
                            SceneMemberEntity *m4 = [self createSceneMemberSwitch:device channel:4];
                            [newScene addMembersObject:m4];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m4];
                        }
                    }else if ([CSRUtilities belongToDimmer:device.shortName]) {
                        SceneMemberEntity *m = [self createSceneMemberDimmer:device channel:1];
                        [newScene addMembersObject:m];
                        [[CSRDatabaseManager sharedInstance] saveContext];
                        [self.selects addObject:m];
                    }else if ([CSRUtilities belongToTwoChannelDimmer:device.shortName]) {
                        if ([model.channel integerValue] == 2) {
                            SceneMemberEntity *m = [self createSceneMemberDimmer:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                        }else if ([model.channel integerValue] == 3) {
                            SceneMemberEntity *m = [self createSceneMemberDimmer:device channel:2];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                        }else if ([model.channel integerValue] == 4) {
                            SceneMemberEntity *m = [self createSceneMemberDimmer:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                            SceneMemberEntity *m2 = [self createSceneMemberDimmer:device channel:2];
                            [newScene addMembersObject:m2];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m2];
                        }
                    }else if ([CSRUtilities belongToThreeChannelDimmer:device.shortName]) {
                        if ([model.channel integerValue] == 2) {
                            SceneMemberEntity *m = [self createSceneMemberDimmer:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                        }else if ([model.channel integerValue] == 3) {
                            SceneMemberEntity *m = [self createSceneMemberDimmer:device channel:2];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                        }else if ([model.channel integerValue] == 5) {
                            SceneMemberEntity *m = [self createSceneMemberDimmer:device channel:4];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                        }else if ([model.channel integerValue] == 4) {
                            SceneMemberEntity *m = [self createSceneMemberDimmer:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                            SceneMemberEntity *m2 = [self createSceneMemberDimmer:device channel:2];
                            [newScene addMembersObject:m2];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                        }else if ([model.channel integerValue] == 6) {
                            SceneMemberEntity *m = [self createSceneMemberDimmer:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                            SceneMemberEntity *m4 = [self createSceneMemberDimmer:device channel:4];
                            [newScene addMembersObject:m4];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m4];
                        }else if ([model.channel integerValue] == 7) {
                            SceneMemberEntity *m2 = [self createSceneMemberDimmer:device channel:2];
                            [newScene addMembersObject:m2];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m2];
                            SceneMemberEntity *m4 = [self createSceneMemberDimmer:device channel:4];
                            [newScene addMembersObject:m4];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m4];
                        }else if ([model.channel integerValue] == 8) {
                            SceneMemberEntity *m = [self createSceneMemberDimmer:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                            SceneMemberEntity *m2 = [self createSceneMemberDimmer:device channel:2];
                            [newScene addMembersObject:m2];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m2];
                            SceneMemberEntity *m4 = [self createSceneMemberDimmer:device channel:4];
                            [newScene addMembersObject:m4];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m4];
                        }
                    }else if ([CSRUtilities belongToCWDevice:device.shortName]) {
                        SceneMemberEntity *m = [self createSceneMemberCW:device];
                        [newScene addMembersObject:m];
                        [[CSRDatabaseManager sharedInstance] saveContext];
                        [self.selects addObject:m];
                    }else if ([CSRUtilities belongToRGBDevice:device.shortName]) {
                        SceneMemberEntity *m = [self createSceneMemberRGB:device];
                        [newScene addMembersObject:m];
                        [[CSRDatabaseManager sharedInstance] saveContext];
                        [self.selects addObject:m];
                    }else if ([CSRUtilities belongToRGBCWDevice:device.shortName]) {
                        SceneMemberEntity *m = [self createSceneMemberRGBCW:device];
                        [newScene addMembersObject:m];
                        [[CSRDatabaseManager sharedInstance] saveContext];
                        [self.selects addObject:m];
                    }else if ([CSRUtilities belongToOneChannelCurtainController:device.shortName]
                              || [CSRUtilities belongToHOneChannelCurtainController:device.shortName]) {
                        SceneMemberEntity *m = [self createSceneMemberCurtain:device channel:1];
                        [newScene addMembersObject:m];
                        [[CSRDatabaseManager sharedInstance] saveContext];
                        [self.selects addObject:m];
                    }else if ([CSRUtilities belongToTwoChannelCurtainController:device.shortName]) {
                        if ([model.channel integerValue] == 2) {
                            SceneMemberEntity *m = [self createSceneMemberCurtain:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                        }else if ([model.channel integerValue] == 3) {
                            SceneMemberEntity *m = [self createSceneMemberCurtain:device channel:2];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                        }else if ([model.channel integerValue] == 4) {
                            SceneMemberEntity *m = [self createSceneMemberCurtain:device channel:1];
                            [newScene addMembersObject:m];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m];
                            SceneMemberEntity *m2 = [self createSceneMemberCurtain:device channel:2];
                            [newScene addMembersObject:m2];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            [self.selects addObject:m2];
                        }
                    }else if ([CSRUtilities belongToFanController:device.shortName]) {
                        SceneMemberEntity *m = [self createSceneMemberFan:device];
                        [newScene addMembersObject:m];
                        [[CSRDatabaseManager sharedInstance] saveContext];
                        [self.selects addObject:m];
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

- (SceneMemberEntity *)createSceneMemberSwitch:(DeviceModel *)device channel:(int)channel {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = @(_applyIndex);
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
    return m;
}

- (SceneMemberEntity *)createSceneMemberDimmer:(DeviceModel *)device channel:(int)channel {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = @(_applyIndex);
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
    return m;
}

- (SceneMemberEntity *)createSceneMemberCW:(DeviceModel *)device {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = @(_applyIndex);
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
    return m;
}

- (SceneMemberEntity *)createSceneMemberRGB:(DeviceModel *)device {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = @(_applyIndex);
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
    return m;
}

- (SceneMemberEntity *)createSceneMemberRGBCW:(DeviceModel *)device {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = @(_applyIndex);
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
    return m;
}

- (SceneMemberEntity *)createSceneMemberCurtain:(DeviceModel *)device channel:(int)channel {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = @(_applyIndex);
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
    return m;
}

- (SceneMemberEntity *)createSceneMemberFan:(DeviceModel *)device {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = @(_applyIndex);
    m.kindString = device.shortName;
    m.deviceID = device.deviceId;
    m.channel = @1;
    m.eveType = @32;
    m.eveD0 = @(device.fanState);
    m.eveD1 = @(device.fansSpeed);
    m.eveD2 = @(device.lampState);
    m.eveD3 = @0;
    return m;
}

- (SceneMemberEntity *)createSceneMemberSonos:(SonosSelectModel *)model {
    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    m.sceneID = @(_applyIndex);
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
    return m;
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
            
            NSInteger s = [m.sceneID integerValue];
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

- (void)sceneAddedSuccessCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceID = userInfo[@"deviceId"];
    NSNumber *sceneID = userInfo[@"index"];
    if (_mDeviceToApplay && [_mDeviceToApplay.deviceId isEqualToNumber:deviceID] && _applyIndex == [sceneID integerValue]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setSceneIDTimerOut) object:nil];
        SceneMemberEntity *m = [self.selects firstObject];
        [self.selects removeObject:m];
        if ([userInfo[@"state"] boolValue]) {
            [self addMemberToMembers:m];
            [_tableView reloadData];
        }else {
            [self.fails addObject:[m.deviceID copy]];
        }
        
        _mDeviceToApplay = nil;
        
        if (![self nextOperation]) {
            if ([self.fails count] > 0) {
                
            }else {
                [self alertAddDelay];
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
        
        _mDeviceToApplay = nil;
        
        if (![self nextOperation]) {
            
        }
    }
}

- (void)addMemberToMembers:(SceneMemberEntity *)memberEntity {
    SceneMemberExpandModel *model;
    for (id obj in _members) {
        if ([obj isKindOfClass:[SceneMemberExpandModel class]]) {
            SceneMemberExpandModel *eModel = (SceneMemberExpandModel *)obj;
            if ([eModel.deviceID isEqualToNumber:memberEntity.deviceID]) {
                model = eModel;
                break;
            }
        }
    }
    if (!model) {
        model = [[SceneMemberExpandModel alloc] init];
        model.deviceID = memberEntity.deviceID;
        model.kindString = memberEntity.kindString;
        model.sceneID = memberEntity.sceneID;
        BOOL exist = NO;
        if ([_members count]>0) {
            id obj = [_members lastObject];
            if ([obj isKindOfClass:[NSString class]]) {
                NSString *str = (NSString *)obj;
                if ([str length]==1) {
                    exist = YES;
                }
            }
        }
        if (exist) {
            [_members insertObject:model atIndex:[_members count]-1];
        }else {
            [_members addObject:model];
        }
        model.stateDic = @{memberEntity.channel : @[memberEntity.eveType, memberEntity.eveD0, memberEntity.eveD1, memberEntity.eveD2, memberEntity.eveD3]};
    }else {
        NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithDictionary:model.stateDic];
        [mutableDic setObject:@[memberEntity.eveType, memberEntity.eveD0, memberEntity.eveD1, memberEntity.eveD2, memberEntity.eveD3] forKey:memberEntity.channel];
        model.stateDic = mutableDic;
    }
}

- (void)alertAddDelay {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"设置延时" preferredStyle:UIAlertControllerStyleAlert];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *save = [UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        uint8_t trigger = 0;
        if (_triggerNumber == 1 || _triggerNumber == 3) {
            trigger = 0;
        }else if (_triggerNumber == 2 || _triggerNumber == 4) {
            trigger = 1;
        }else if (_triggerNumber == 5 || _triggerNumber == 6) {
            trigger = 2;
        }
        uint8_t act = [self getFreeActionID];
        if (act <= 4) {
            _applyAction = act;
            UITextField *textField = alert.textFields.firstObject;
            if ([textField.text length]>0 && [textField.text integerValue] >= 0 && [textField.text integerValue] <= 255) {
                _applyDelay = [textField.text intValue];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionCall:) name:@"PIRACTIONCALL" object:nil];
                Byte byte[] = {0xea, 0x8b, 0x04, trigger, act, 0x00, 0x00, _applyIndex & 0x00FF, (_applyIndex & 0xFF00)>>8, _applyDelay};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }
        }
    }];
    [alert addAction:save];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textAlignment = NSTextAlignmentCenter;
        textField.placeholder = @"输入一个0~255的数字";
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

- (uint8_t)getFreeActionID {
    if ([_mDic count]>0) {
        if (_triggerNumber == 1 || _triggerNumber == 3) {
            id bodys = _mDic[@"body"];
            if ([bodys isKindOfClass:[NSNumber class]]) {
                return 0;
            }else {
                NSDictionary *bodyDic = (NSDictionary *)bodys;
                NSArray *actions = [bodyDic objectForKey:@"actions"];
                return [actions count];
            }
        }else if (_triggerNumber == 2 || _triggerNumber == 4) {
            id nobodys = _mDic[@"no_body"];
            if ([nobodys isKindOfClass:[NSNumber class]]) {
                return 0;
            }else {
                NSDictionary *nobodyDic = (NSDictionary *)nobodys;
                NSArray *actions = [nobodyDic objectForKey:@"actions"];
                return [actions count];
            }
        }else if (_triggerNumber == 5) {
            id greaters = _mDic[@"greater"];
            if ([greaters isKindOfClass:[NSNumber class]]) {
                return 0;
            }else {
                NSDictionary *greaterDic = (NSDictionary *)greaters;
                NSArray *actions = [greaterDic objectForKey:@"actions"];
                return [actions count];
            }
        }else if (_triggerNumber == 6) {
            id lesss = _mDic[@"less"];
            if ([lesss isKindOfClass:[NSNumber class]]) {
                return 0;
            }else {
                NSDictionary *lessDic = (NSDictionary *)lesss;
                NSArray *actions = [lessDic objectForKey:@"actions"];
                return [actions count];
            }
        }
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_members count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.textLabel.textColor = ColorWithAlpha(77, 77, 77, 1);
        cell.detailTextLabel.textColor = ColorWithAlpha(150, 150, 150, 1);
        UISwitch *swi = [[UISwitch alloc] init];
        swi.onTintColor = DARKORAGE;
        swi.tag = 1;
        [swi addTarget:self action:@selector(repeatSwitch:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:swi];
        [swi autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [swi autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20.0];
    }
    UISwitch *swi = (UISwitch *)[cell.contentView viewWithTag:1];
    swi.hidden = YES;
    id obj = [_members objectAtIndex:indexPath.row];
    if ([obj isKindOfClass:[SceneMemberExpandModel class]]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        SceneMemberExpandModel *member = (SceneMemberExpandModel *)obj;
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
        cell.textLabel.text = deviceEntity.name;
        if ([CSRUtilities belongToSwitch:member.kindString]
            || [CSRUtilities belongToSocketOneChannel:member.kindString]
            || [CSRUtilities belongToTwoChannelSwitch:member.kindString]
            || [CSRUtilities belongToThreeChannelSwitch:member.kindString]
            || [CSRUtilities belongToSocketTwoChannel:member.kindString]) {
            if ([CSRUtilities belongToESeriesSingleWireSwitch:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_E_press"];
            }else if ([CSRUtilities belongToTSeriesPanel:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_T_panel"];
            }else if ([CSRUtilities belongToPSeriesPanel:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_P_panel"];
            }else if ([CSRUtilities belongToHiddenController:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_hidden_controller"];
            }else if ([CSRUtilities belongToSocketOneChannel:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_socket"];
            }else {
                cell.imageView.image = [UIImage imageNamed:@"icon_switch1"];
            }
            if ([member.stateDic count]>0) {
                NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
                [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    if ([obj1 intValue] < [obj2 integerValue]) {
                        return NSOrderedAscending;
                    }else {
                        return NSOrderedDescending;
                    }
                }];
                NSString *detailText = @"";
                for (NSNumber *channel in keys) {
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    if (ary) {
                        NSInteger eveType = [ary[0] integerValue];
                        if (eveType == 16) {
                            detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@", detailText, @"ON"] : @"ON";
                        }else {
                            detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@", detailText, @"OFF"] : @"OFF";
                        }
                    }
                }
                cell.detailTextLabel.text = detailText;
            }
        }else if ([CSRUtilities belongToDimmer:member.kindString]
                  || [CSRUtilities belongToTwoChannelDimmer:member.kindString]
                  || [CSRUtilities belongToThreeChannelDimmer:member.kindString]
                  || [CSRUtilities belongToOneChannelCurtainController:member.kindString]
                  || [CSRUtilities belongToHOneChannelCurtainController:member.kindString]
                  || [CSRUtilities belongToTwoChannelCurtainController:member.kindString]) {
            if ([CSRUtilities belongToESeriesDimmer:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_E_press"];
            }else if ([CSRUtilities belongToESeriesKnobDimmer:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_E_knob"];
            }else if ([CSRUtilities belongToTSeriesPanel:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_T_panel"];
            }else if ([CSRUtilities belongToPSeriesPanel:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_P_panel"];
            }else if ([CSRUtilities belongToHiddenController:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_hidden_controller"];
            }else if ([CSRUtilities belongToOneChannelCurtainController:member.kindString]
                      || [CSRUtilities belongToHOneChannelCurtainController:member.kindString]
                      || [CSRUtilities belongToTwoChannelCurtainController:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_curtain"];
            }else {
                cell.imageView.image = [UIImage imageNamed:@"icon_dimmer1"];
            }
            if ([member.stateDic count]>0) {
                NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
                [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    if ([obj1 intValue] < [obj2 integerValue]) {
                        return NSOrderedAscending;
                    }else {
                        return NSOrderedDescending;
                    }
                }];
                NSString *detailText = @"";
                for (NSNumber *channel in keys) {
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    if (ary) {
                        NSInteger eveType = [ary[0] integerValue];
                        if (eveType == 17) {
                            detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@", detailText, @"OFF"] : @"OFF";
                        }else if (eveType == 18) {
                            detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %.f%%", detailText, [ary[1] integerValue]/255.0*100] : [NSString stringWithFormat:@"%.f%%", [ary[1] integerValue]/255.0*100];
                        }
                    }
                }
                cell.detailTextLabel.text = detailText;
            }
        }else if ([CSRUtilities belongToCWDevice:member.kindString]) {
            if ([CSRUtilities belongToIEMLEDDriver:member.kindString]
                || [CSRUtilities belongToIELEDDriver:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_IE_driver"];
            }else if ([CSRUtilities belongToLIMLEDDriver:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_LIM_driver"];
            }else if ([CSRUtilities belongToC3ABLEDDriver:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_C3AB_driver"];
            }else if ([CSRUtilities belongToC2ABLEDDriver:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_C2AB_driver"];
            }else {
                cell.imageView.image = [UIImage imageNamed:@"icon_LED_strip"];
            }
            if ([member.stateDic count]>0) {
                NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
                [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    if ([obj1 intValue] < [obj2 integerValue]) {
                        return NSOrderedAscending;
                    }else {
                        return NSOrderedDescending;
                    }
                }];
                NSString *detailText = @"";
                for (NSNumber *channel in keys) {
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    if (ary) {
                        NSInteger eveType = [ary[0] integerValue];
                        if (eveType == 17) {
                            detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@", detailText, @"OFF"] : @"OFF";
                        }else if (eveType == 25) {
                            detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %ldK %.f%%", detailText, [ary[3] integerValue]*256+[ary[2] integerValue], [ary[1] integerValue]/255.0*100] : [NSString stringWithFormat:@"%ldK %.f%%", [ary[3] integerValue]*256+[ary[2] integerValue], [ary[1] integerValue]/255.0*100];
                        }
                    }
                }
                cell.detailTextLabel.text = detailText;
            }
        }else if ([CSRUtilities belongToRGBDevice:member.kindString]) {
            if ([CSRUtilities belongToIEMLEDDriver:member.kindString]
                || [CSRUtilities belongToIELEDDriver:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_IE_driver"];
            }else if ([CSRUtilities belongToLIMLEDDriver:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_LIM_driver"];
            }else if ([CSRUtilities belongToC3ABLEDDriver:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_C3AB_driver"];
            }else if ([CSRUtilities belongToC2ABLEDDriver:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_C2AB_driver"];
            }else {
                cell.imageView.image = [UIImage imageNamed:@"icon_LED_strip"];
            }
            if ([member.stateDic count]>0) {
                NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
                [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    if ([obj1 intValue] < [obj2 integerValue]) {
                        return NSOrderedAscending;
                    }else {
                        return NSOrderedDescending;
                    }
                }];
                NSMutableAttributedString *detailText = [[NSMutableAttributedString alloc] init];;
                for (NSNumber *channel in keys) {
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    if (ary) {
                        NSInteger eveType = [ary[0] integerValue];
                        NSMutableAttributedString *p = [[NSMutableAttributedString alloc] initWithString:@" | "];
                        if (eveType == 17) {
                            NSMutableAttributedString *t = [[NSMutableAttributedString alloc] initWithString:@"OFF"];
                            if ([detailText length] > 0) {
                                [detailText appendAttributedString:p];
                                [detailText appendAttributedString:t];
                            }else {
                                [detailText appendAttributedString:t];
                            }
                        }else if (eveType == 20) {
                            NSMutableAttributedString *t = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"● %.f%%", [ary[1] integerValue]/255.0*100]];
                            [t addAttribute:NSForegroundColorAttributeName value:ColorWithAlpha([ary[2] integerValue], [ary[3] integerValue], [ary[4] integerValue], 1) range:NSMakeRange(0, 1)];
                            if ([detailText length] > 0) {
                                [detailText appendAttributedString:p];
                                [detailText appendAttributedString:t];
                            }else {
                                [detailText appendAttributedString:t];
                            }
                        }
                    }
                }
                cell.detailTextLabel.attributedText = detailText;
            }
        }else if ([CSRUtilities belongToRGBCWDevice:member.kindString]) {
            if ([CSRUtilities belongToIEMLEDDriver:member.kindString]
                || [CSRUtilities belongToIELEDDriver:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_IE_driver"];
            }else if ([CSRUtilities belongToLIMLEDDriver:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_LIM_driver"];
            }else if ([CSRUtilities belongToC3ABLEDDriver:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_C3AB_driver"];
            }else if ([CSRUtilities belongToC2ABLEDDriver:member.kindString]) {
                cell.imageView.image = [UIImage imageNamed:@"icon_C2AB_driver"];
            }else {
                cell.imageView.image = [UIImage imageNamed:@"icon_LED_strip"];
            }
            if ([member.stateDic count]>0) {
                NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
                [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    if ([obj1 intValue] < [obj2 integerValue]) {
                        return NSOrderedAscending;
                    }else {
                        return NSOrderedDescending;
                    }
                }];
                NSMutableAttributedString *detailText = [[NSMutableAttributedString alloc] init];;
                for (NSNumber *channel in keys) {
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    if (ary) {
                        NSInteger eveType = [ary[0] integerValue];
                        NSMutableAttributedString *p = [[NSMutableAttributedString alloc] initWithString:@" | "];
                        if (eveType == 17) {
                            NSMutableAttributedString *t = [[NSMutableAttributedString alloc] initWithString:@"OFF"];
                            if ([detailText length] > 0) {
                                [detailText appendAttributedString:p];
                                [detailText appendAttributedString:t];
                            }else {
                                [detailText appendAttributedString:t];
                            }
                        }else if (eveType == 20) {
                            NSMutableAttributedString *t = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"● %.f%%", [ary[1] integerValue]/255.0*100]];
                            [t addAttribute:NSForegroundColorAttributeName value:ColorWithAlpha([ary[2] integerValue], [ary[3] integerValue], [ary[4] integerValue], 1) range:NSMakeRange(0, 1)];
                            if ([detailText length] > 0) {
                                [detailText appendAttributedString:p];
                                [detailText appendAttributedString:t];
                            }else {
                                [detailText appendAttributedString:t];
                            }
                        }else if (eveType == 25) {
                            NSMutableAttributedString *t = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ldK %.f%%", [ary[3] integerValue]*256+[ary[2] integerValue], [ary[1] integerValue]/255.0*100]];
                            if ([detailText length] > 0) {
                                [detailText appendAttributedString:p];
                                [detailText appendAttributedString:t];
                            }else {
                                [detailText appendAttributedString:t];
                            }
                        }
                    }
                }
                cell.detailTextLabel.attributedText = detailText;
            }
        }else if ([CSRUtilities belongToFanController:member.kindString]) {
            cell.imageView.image = [UIImage imageNamed:@"icon_fan"];
            if ([member.stateDic count]>0) {
                NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
                [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    if ([obj1 intValue] < [obj2 integerValue]) {
                        return NSOrderedAscending;
                    }else {
                        return NSOrderedDescending;
                    }
                }];
                NSString *detailText = @"";
                for (NSNumber *channel in keys) {
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    if (ary) {
                        if ([ary[1] integerValue] == 0) {
                            detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@", detailText, @"OFF"] : @"OFF";
                        }else {
                            if ([ary[2] integerValue] == 0) {
                                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@", detailText, AcTECLocalizedStringFromTable(@"low", @"Localizable")] : AcTECLocalizedStringFromTable(@"low", @"Localizable");
                            }else if ([ary[2] integerValue] == 1) {
                                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@", detailText, AcTECLocalizedStringFromTable(@"medium", @"Localizable")] : AcTECLocalizedStringFromTable(@"medium", @"Localizable");
                            }else if ([ary[2] integerValue] == 2) {
                                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@", detailText, AcTECLocalizedStringFromTable(@"high", @"Localizable")] : AcTECLocalizedStringFromTable(@"high", @"Localizable");
                            }
                        }
                        if ([ary[3] integerValue] == 0) {
                            detailText = [NSString stringWithFormat:@"%@, %@",detailText, AcTECLocalizedStringFromTable(@"light_off", @"Localizable")];
                        }else {
                            detailText = [NSString stringWithFormat:@"%@, %@",detailText, AcTECLocalizedStringFromTable(@"light_on", @"Localizable")];
                        }
                    }
                }
                cell.detailTextLabel.text = detailText;
            }
        }else if ([CSRUtilities belongToSonosMusicController:member.kindString]) {
            cell.imageView.image = [UIImage imageNamed:@"icon_sonos"];
            if ([member.stateDic count]>0) {
                NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
                [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    if ([obj1 intValue] < [obj2 integerValue]) {
                        return NSOrderedAscending;
                    }else {
                        return NSOrderedDescending;
                    }
                }];
                NSString *detailText = @"";
                for (NSNumber *channel in keys) {
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    if (ary) {
                        NSInteger eveType = [ary[0] integerValue];
                        if (eveType == 130) {
                            detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@", detailText, @"STOP"] : @"STOP";
                        }else if (eveType == 226) {
                            NSString *song= @"";
                            if ([deviceEntity.remoteBranch length]>0) {
                                NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:deviceEntity.remoteBranch];
                                if ([jsonDictionary count]>0) {
                                    NSArray *songs = jsonDictionary[@"song"];
                                    for (NSDictionary *dic in songs) {
                                        NSInteger n = [dic[@"id"] integerValue];
                                        if (n == [ary[3] integerValue]) {
                                            song = dic[@"name"];
                                            break;
                                        }
                                    }
                                }
                            }
                            detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@, %ld%%", detailText, song, ([ary[2] integerValue] & 0xfe)>>1] : [NSString stringWithFormat:@"%@, %ld%%", song, ([ary[2] integerValue] & 0xfe)>>1];
                        }
                    }
                }
                cell.detailTextLabel.text = detailText;
            }
        }else if ([CSRUtilities belongToThermoregulator:member.kindString]) {
            cell.imageView.image = [UIImage imageNamed:@"icon_sonos"];
            if ([member.stateDic count]>0) {
                NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
                [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    if ([obj1 intValue] < [obj2 integerValue]) {
                        return NSOrderedAscending;
                    }else {
                        return NSOrderedDescending;
                    }
                }];
                NSString *detailText = @"";
                for (NSNumber *channel in keys) {
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    if (ary) {
                        int tpower = ([ary[1] integerValue] & 0x01);
                        int tmoshi = ([ary[1] integerValue] & 0x0e) >> 1;
                        int tfengxiang = ([ary[1] integerValue] & 0x70) >> 4;
                        int tfengsu = ([ary[2] integerValue] & 0x07);
                        int twendu = ([ary[3] integerValue] & 0x7f) * pow(-1, (([ary[3] integerValue] & 0x80) >> 7));
                        if (twendu < 16) {
                            twendu = 0;
                        }else if (twendu >= 16 && twendu <= 30) {
                            twendu = twendu - 16;
                        }else if (twendu > 30) {
                            twendu = 14;
                        }
                        NSString *str = [NSString stringWithFormat:@"%@ %@ %@ %@ %@", tpower==1?@"ON":@"OFF", TFENGSU[tfengsu], TWENDU[twendu], TMOSHI[tmoshi], TFENGXIANG[tfengxiang]];
                        detailText = [detailText length] > 0 ? str : [NSString stringWithFormat:@"%@ | %@",detailText, str];
                    }
                }
                cell.detailTextLabel.text = detailText;
            }
        }
    }else if ([obj isKindOfClass:[NSNumber class]]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        NSNumber *num = (NSNumber *)obj;
        cell.imageView.image = [UIImage imageNamed:@"icon_delay"];
        cell.textLabel.text = [num stringValue];
        cell.detailTextLabel.text = @"";
    }else if ([obj isKindOfClass:[NSString class]]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        NSString *str = (NSString *)obj;
        if ([str length] == 1) {
            cell.textLabel.text = @"是否重复";
            swi.hidden = NO;
            if ([str isEqualToString:@"Y"]) {
                swi.on = YES;
            }else if ([str isEqualToString:@"N"]) {
                swi.on = NO;
            }
        }else {
            cell.textLabel.text = str;
        }
        cell.imageView.image = nil;
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

- (void)triggerCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceID = [userInfo objectForKey:@"DEVICEID"];
    if ([deviceID isEqualToNumber:_deviceId]) {
        NSNumber *trigger = [userInfo objectForKey:@"TRIGGET"];
        NSNumber *state = [userInfo objectForKey:@"STATE"];
        if ([trigger integerValue] == 0 && _triggerNumber == 1) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRTRIGGERCALL" object:nil];
            if (![state boolValue]) {
                if (![[_mDic allKeys] containsObject:@"body"]) {
                    [_mDic setObject:@(0) forKey:@"body"];
                }
                [self addItemAction];
            }else {
                //切换至有人，反馈失败。
            }
        }else if ([trigger integerValue] == 1 && _triggerNumber == 2) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRTRIGGERCALL" object:nil];
            if (![state boolValue]) {
                if (![[_mDic allKeys] containsObject:@"no_body"]) {
                    [_mDic setObject:@(0) forKey:@"no_body"];
                }
                [self addItemAction];
            }else {
                //切换至无人，反馈失败。
            }
        }else if ([trigger integerValue] == 0 && _triggerNumber == 3) {
            if (![state boolValue]) {
                if (![[_mDic allKeys] containsObject:@"body"]) {
                    [_mDic setObject:@(0) forKey:@"body"];
                }
                [self addItemAction];
            }else {
                //切换至有人/无人，有人反馈失败。
            }
        }else if ([trigger integerValue] == 1 && _triggerNumber == 4) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRTRIGGERCALL" object:nil];
            if (![state boolValue]) {
                if (![[_mDic allKeys] containsObject:@"no_body"]) {
                    [_mDic setObject:@(0) forKey:@"no_body"];
                }
                [self addItemAction];
            }else {
                //切换至有人/无人，无人反馈失败。
            }
        }else if ([trigger integerValue] == 2 && _triggerNumber == 5) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRTRIGGERCALL" object:nil];
            if (![state boolValue]) {
                if (![[_mDic allKeys] containsObject:@"greater"]) {
                    [_mDic setObject:@(0) forKey:@"greater"];
                }
                [self addItemAction];
            }else {
                //切换至温度大于等于，反馈失败。
            }
        }else if ([trigger integerValue] == 2 && _triggerNumber == 6) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRTRIGGERCALL" object:nil];
            if (![state boolValue]) {
                if (![[_mDic allKeys] containsObject:@"less"]) {
                    [_mDic setObject:@(0) forKey:@"less"];
                }
                [self addItemAction];
            }else {
                //切换至温度大于等于，反馈失败。
            }
        }
    }
}

- (void)actionCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceID = [userInfo objectForKey:@"DEVICEID"];
    if ([deviceID isEqualToNumber:_deviceId]) {
        NSNumber *trigger = [userInfo objectForKey:@"TRIGGET"];
        NSNumber *action = [userInfo objectForKey:@"ACTION"];
        NSNumber *state = [userInfo objectForKey:@"STATE"];
        
        if (_actionIDToApply != -1) {
            if ([trigger intValue] == 0 && (_triggerNumber == 1 || _triggerNumber == 3) && [action intValue] == _actionIDToApply) {
                if (_actionIDToApply == 255) {
                    _actionIDToApply = -1;
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                }else {
                    NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:_mDic[@"body"][@"actions"]];
                    NSMutableDictionary *md;
                    int index = 0;
                    for (int i = 0; i < [actions count]; i ++) {
                        NSDictionary *action = actions[i];
                        int actionID = [action[@"actionID"] intValue];
                        if (actionID > _actionIDToApply) {
                            md = [[NSMutableDictionary alloc] initWithDictionary:action];
                            [md setObject:@(_actionIDToApply) forKey:@"actionID"];
                            index = i;
                            break;
                        }
                    }
                    if (md) {
                        [actions replaceObjectAtIndex:index withObject:md];
                        [_mDic setObject:@{@"actions":actions} forKey:@"body"];
                    }
                    _actionIDToApply ++;
                    if (_actionIDToApply < [actions count]) {
                        for (NSDictionary *action in actions) {
                            int eActionID = [action[@"actionID"] intValue];
                            if (eActionID > _actionIDToApply) {
                                Byte byte[] = {0xea, 0x8b, 0x04, 0x00, _actionIDToApply, 0x00, 0x00, [action[@"scene_index"] integerValue] & 0x00FF, ([action[@"scene_index"] integerValue] & 0xFF00)>>8, [action[@"delay"] intValue]};
                                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                            }
                        }
                    }else {
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x00, 0xff, [actions count],[repeat boolValue],0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }
                }
            }else if ([trigger intValue] == 1 && (_triggerNumber == 2 || _triggerNumber == 4) && [action intValue] == _actionIDToApply) {
                if (_actionIDToApply == 255) {
                    _actionIDToApply = -1;
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                }else {
                    NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:_mDic[@"no_body"][@"actions"]];
                    NSMutableDictionary *md;
                    int index = 0;
                    for (int i = 0; i < [actions count]; i ++) {
                        NSDictionary *action = actions[i];
                        int actionID = [action[@"actionID"] intValue];
                        if (actionID > _actionIDToApply) {
                            md = [[NSMutableDictionary alloc] initWithDictionary:action];
                            [md setObject:@(_actionIDToApply) forKey:@"actionID"];
                            index = i;
                            break;
                        }
                    }
                    if (md) {
                        [actions replaceObjectAtIndex:index withObject:md];
                        [_mDic setObject:@{@"actions":actions} forKey:@"no_body"];
                    }
                    _actionIDToApply ++;
                    if (_actionIDToApply < [actions count]) {
                        for (NSDictionary *action in actions) {
                            int eActionID = [action[@"actionID"] intValue];
                            if (eActionID > _actionIDToApply) {
                                Byte byte[] = {0xea, 0x8b, 0x04, 0x01, _actionIDToApply, 0x00, 0x00, [action[@"scene_index"] integerValue] & 0x00FF, ([action[@"scene_index"] integerValue] & 0xFF00)>>8, [action[@"delay"] intValue]};
                                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                            }
                        }
                    }else {
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x01, 0xff, [actions count],[repeat boolValue],0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }
                }
            }else if ([trigger intValue] == 2 && _triggerNumber == 5 && [action intValue] == _actionIDToApply) {
                if (_actionIDToApply == 255) {
                    _actionIDToApply = -1;
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                }else {
                    NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:_mDic[@"greater"][@"actions"]];
                    NSMutableDictionary *md;
                    int index = 0;
                    for (int i = 0; i < [actions count]; i ++) {
                        NSDictionary *action = actions[i];
                        int actionID = [action[@"actionID"] intValue];
                        if (actionID > _actionIDToApply) {
                            md = [[NSMutableDictionary alloc] initWithDictionary:action];
                            [md setObject:@(_actionIDToApply) forKey:@"actionID"];
                            index = i;
                            break;
                        }
                    }
                    if (md) {
                        [actions replaceObjectAtIndex:index withObject:md];
                        [_mDic setObject:@{@"actions":actions} forKey:@"greater"];
                    }
                    _actionIDToApply ++;
                    if (_actionIDToApply < [actions count]) {
                        for (NSDictionary *action in actions) {
                            int eActionID = [action[@"actionID"] intValue];
                            if (eActionID > _actionIDToApply) {
                                Byte byte[] = {0xea, 0x8b, 0x04, 0x02, _actionIDToApply, 0x00, 0x00, [action[@"scene_index"] integerValue] & 0x00FF, ([action[@"scene_index"] integerValue] & 0xFF00)>>8, [action[@"delay"] intValue]};
                                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                            }
                        }
                    }else {
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x02, 0xff, [actions count],[repeat boolValue],0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }
                }
            }else if ([trigger intValue] == 2 && _triggerNumber == 6 && [action intValue] == _actionIDToApply) {
                if (_actionIDToApply == 255) {
                    _actionIDToApply = -1;
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                }else {
                    NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:_mDic[@"less"][@"actions"]];
                    NSMutableDictionary *md;
                    int index = 0;
                    for (int i = 0; i < [actions count]; i ++) {
                        NSDictionary *action = actions[i];
                        int actionID = [action[@"actionID"] intValue];
                        if (actionID > _actionIDToApply) {
                            md = [[NSMutableDictionary alloc] initWithDictionary:action];
                            [md setObject:@(_actionIDToApply) forKey:@"actionID"];
                            index = i;
                            break;
                        }
                    }
                    if (md) {
                        [actions replaceObjectAtIndex:index withObject:md];
                        [_mDic setObject:@{@"actions":actions} forKey:@"less"];
                    }
                    _actionIDToApply ++;
                    if (_actionIDToApply < [actions count]) {
                        for (NSDictionary *action in actions) {
                            int eActionID = [action[@"actionID"] intValue];
                            if (eActionID > _actionIDToApply) {
                                Byte byte[] = {0xea, 0x8b, 0x04, 0x02, _actionIDToApply, 0x00, 0x00, [action[@"scene_index"] integerValue] & 0x00FF, ([action[@"scene_index"] integerValue] & 0xFF00)>>8, [action[@"delay"] intValue]};
                                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                            }
                        }
                    }else {
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x02, 0xff, [actions count],[repeat boolValue],0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }
                }
            }
        }else {
            int actionsCount = 0;
            if ([trigger intValue] == 0 && _triggerNumber == 1 && [action intValue] == _applyAction) {
                if (_applyAction == 255) {
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                    if (![[_mDic allKeys] containsObject:@"repeat"]) {
                        if (_applyRepeat) {
                            [_members addObject:@"Y"];
                        }else {
                            [_members addObject:@"N"];
                        }
                        [_tableView reloadData];
                    }
                    [_mDic setObject:@(_applyRepeat) forKey:@"repeat"];
                    CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                    NSMutableDictionary *bsDic;
                    if ([de.remoteBranch length] > 0) {
                        NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                        if (dic) {
                            bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                        }else {
                            bsDic = [NSMutableDictionary new];
                        }
                        [bsDic setObject:_mDic forKey:@"body_sensor"];
                    }else {
                        bsDic = [NSMutableDictionary new];
                        [bsDic setObject:_mDic forKey:@"body_sensor"];
                    }
                    de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }else {
                    if (![state boolValue]) {
                        id obj = [_mDic objectForKey:@"body"];
                        if (obj) {
                            if ([obj isKindOfClass:[NSNumber class]]) {
                                NSDictionary *actionDic = @{@"actionID":@(_applyAction), @"scene_index":@(_applyIndex), @"delay":@(_applyDelay)};
                                [_mDic setObject:@{@"actions":@[actionDic]} forKey:@"body"];
                                actionsCount = 1;
                            }else if ([obj isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *actionDic = @{@"actionID":@(_applyAction), @"scene_index":@(_applyIndex), @"delay":@(_applyDelay)};
                                NSDictionary *bodyDic = (NSDictionary *)obj;
                                NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:[bodyDic objectForKey:@"actions"]];
                                [actions addObject:actionDic];
                                [_mDic setObject:@{@"actions":actions} forKey:@"body"];
                                actionsCount = (int)[actions count];
                            }
                            CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                            NSMutableDictionary *bsDic;
                            if ([de.remoteBranch length] > 0) {
                                NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                                if (dic) {
                                    bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                                }else {
                                    bsDic = [NSMutableDictionary new];
                                }
                                [bsDic setObject:_mDic forKey:@"body_sensor"];
                            }else {
                                bsDic = [NSMutableDictionary new];
                                [bsDic setObject:_mDic forKey:@"body_sensor"];
                            }
                            de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            
                            BOOL exist = NO;
                            if ([_members count]>0) {
                                id robj = [_members lastObject];
                                if ([robj isKindOfClass:[NSString class]]) {
                                    NSString *str = (NSString *)robj;
                                    if ([str length]==1) {
                                        exist = YES;
                                    }
                                }
                            }
                            if (exist) {
                                [_members insertObject:@(_applyDelay) atIndex:[_members count]-1];
                            }else {
                                [_members addObject:@(_applyDelay)];
                            }
                            [_tableView reloadData];
                        }
                    }else {
                        
                    }
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"下个步骤：" preferredStyle:UIAlertControllerStyleAlert];
                    [alert.view setTintColor:DARKORAGE];
                    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"动作不重复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        _applyAction = 255;
                        _applyRepeat = NO;
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x00, 0xff, actionsCount,0x00,0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }];
                    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"动作重复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        _applyAction = 255;
                        _applyRepeat = YES;
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x00, 0xff, actionsCount,0x01,0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }];
                    if (_applyAction == 4) {
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        if (!repeat) {
                            [alert addAction:action1];
                            [alert addAction:action2];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }else {
                        UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"继续添加动作" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                            [self addItemAction];
                        }];
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        if (!repeat) {
                            [alert addAction:action3];
                            [alert addAction:action1];
                            [alert addAction:action2];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }
                }
            }else if ([trigger intValue] == 1 && _triggerNumber == 2 && [action intValue] == _applyAction) {
                if (_applyAction == 255) {
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                    if (![[_mDic allKeys] containsObject:@"repeat"]) {
                        if (_applyRepeat) {
                            [_members addObject:@"Y"];
                        }else {
                            [_members addObject:@"N"];
                        }
                        [_tableView reloadData];
                    }
                    [_mDic setObject:@(_applyRepeat) forKey:@"repeat"];
                    CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                    NSMutableDictionary *bsDic;
                    if ([de.remoteBranch length] > 0) {
                        NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                        if (dic) {
                            bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                        }else {
                            bsDic = [NSMutableDictionary new];
                        }
                        [bsDic setObject:_mDic forKey:@"body_sensor"];
                    }else {
                        bsDic = [NSMutableDictionary new];
                        [bsDic setObject:_mDic forKey:@"body_sensor"];
                    }
                    de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }else {
                    if (![state boolValue]) {
                        id obj = [_mDic objectForKey:@"no_body"];
                        if (obj) {
                            if ([obj isKindOfClass:[NSNumber class]]) {
                                NSDictionary *actionDic = @{@"actionID":@(_applyAction), @"scene_index":@(_applyIndex), @"delay":@(_applyDelay)};
                                [_mDic setObject:@{@"actions":@[actionDic]} forKey:@"no_body"];
                                actionsCount = 1;
                            }else if ([obj isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *actionDic = @{@"actionID":@(_applyAction), @"scene_index":@(_applyIndex), @"delay":@(_applyDelay)};
                                NSDictionary *bodyDic = (NSDictionary *)obj;
                                NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:[bodyDic objectForKey:@"actions"]];
                                [actions addObject:actionDic];
                                [_mDic setObject:@{@"actions":actions} forKey:@"no_body"];
                                actionsCount = (int)[actions count];
                            }
                            CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                            NSMutableDictionary *bsDic;
                            if ([de.remoteBranch length] > 0) {
                                NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                                if (dic) {
                                    bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                                }else {
                                    bsDic = [NSMutableDictionary new];
                                }
                                [bsDic setObject:_mDic forKey:@"body_sensor"];
                            }else {
                                bsDic = [NSMutableDictionary new];
                                [bsDic setObject:_mDic forKey:@"body_sensor"];
                            }
                            de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            
                            BOOL exist = NO;
                            if ([_members count]>0) {
                                id robj = [_members lastObject];
                                if ([robj isKindOfClass:[NSString class]]) {
                                    NSString *str = (NSString *)robj;
                                    if ([str length]==1) {
                                        exist = YES;
                                    }
                                }
                            }
                            if (exist) {
                                [_members insertObject:@(_applyDelay) atIndex:[_members count]-1];
                            }else {
                                [_members addObject:@(_applyDelay)];
                            }
                            [_tableView reloadData];
                        }
                    }else {
                        
                    }
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"下个步骤：" preferredStyle:UIAlertControllerStyleAlert];
                    [alert.view setTintColor:DARKORAGE];
                    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"动作不重复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        _applyAction = 255;
                        _applyRepeat = NO;
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x01, 0xff, actionsCount,0x00,0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }];
                    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"动作重复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        _applyAction = 255;
                        _applyRepeat = YES;
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x01, 0xff, actionsCount,0x01,0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }];
                    if (_applyAction == 4) {
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        if (!repeat) {
                            [alert addAction:action1];
                            [alert addAction:action2];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }else {
                        UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"继续添加动作" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                            [self addItemAction];
                        }];
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        if (!repeat) {
                            [alert addAction:action3];
                            [alert addAction:action1];
                            [alert addAction:action2];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }
                }
            }else if ([trigger intValue] == 0 && _triggerNumber == 3 && [action intValue] == _applyAction) {
                if (_applyAction == 255) {
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                    if (![[_mDic allKeys] containsObject:@"repeat"]) {
                        if (_applyRepeat) {
                            [_members addObject:@"Y"];
                        }else {
                            [_members addObject:@"N"];
                        }
                        [_tableView reloadData];
                    }
                    [_mDic setObject:@(_applyRepeat) forKey:@"repeat"];
                    CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                    NSMutableDictionary *bsDic;
                    if ([de.remoteBranch length] > 0) {
                        NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                        if (dic) {
                            bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                        }else {
                            bsDic = [NSMutableDictionary new];
                        }
                        [bsDic setObject:_mDic forKey:@"body_sensor"];
                    }else {
                        bsDic = [NSMutableDictionary new];
                        [bsDic setObject:_mDic forKey:@"body_sensor"];
                    }
                    de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }else {
                    if (![state boolValue]) {
                        id obj = [_mDic objectForKey:@"body"];
                        if (obj) {
                            if ([obj isKindOfClass:[NSNumber class]]) {
                                NSDictionary *actionDic = @{@"actionID":@(_applyAction), @"scene_index":@(_applyIndex), @"delay":@(_applyDelay)};
                                [_mDic setObject:@{@"actions":@[actionDic]} forKey:@"body"];
                                actionsCount = 1;
                            }else if ([obj isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *actionDic = @{@"actionID":@(_applyAction), @"scene_index":@(_applyIndex), @"delay":@(_applyDelay)};
                                NSDictionary *bodyDic = (NSDictionary *)obj;
                                NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:[bodyDic objectForKey:@"actions"]];
                                [actions addObject:actionDic];
                                [_mDic setObject:@{@"actions":actions} forKey:@"body"];
                                actionsCount = (int)[actions count];
                            }
                            CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                            NSMutableDictionary *bsDic;
                            if ([de.remoteBranch length] > 0) {
                                NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                                if (dic) {
                                    bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                                }else {
                                    bsDic = [NSMutableDictionary new];
                                }
                                [bsDic setObject:_mDic forKey:@"body_sensor"];
                            }else {
                                bsDic = [NSMutableDictionary new];
                                [bsDic setObject:_mDic forKey:@"body_sensor"];
                            }
                            de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            BOOL exist = NO;
                            if ([_members count]>0) {
                                id robj = [_members lastObject];
                                if ([robj isKindOfClass:[NSString class]]) {
                                    NSString *str = (NSString *)robj;
                                    if ([str length]==1) {
                                        exist = YES;
                                    }
                                }
                            }
                            if (exist) {
                                [_members insertObject:@(_applyDelay) atIndex:[_members count]-1];
                            }else {
                                [_members addObject:@(_applyDelay)];
                            }
                            [_tableView reloadData];
                        }
                    }else {
                        
                    }
                    if (_applyAction == 4) {
                        Byte byte[] = {0xea, 0x8b, 0x00, 0x01, 0x01, 0x03, 0x00, 0x00, 0x00, 0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }else {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"下个步骤：" preferredStyle:UIAlertControllerStyleAlert];
                        [alert.view setTintColor:DARKORAGE];
                        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"继续添加动作" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                            [self addItemAction];
                        }];
                        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"添加有人/无人中的无人执行动作" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            Byte byte[] = {0xea, 0x8b, 0x00, 0x01, 0x01, 0x03, 0x00, 0x00, 0x00, 0x00};
                            NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        }];
                        [alert addAction:action1];
                        [alert addAction:action2];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                }
            }else if ([trigger intValue] == 1 && _triggerNumber == 4 && [action intValue] == _applyAction) {
                if (_applyAction == 255) {
                    id obj = [_mDic objectForKey:@"body"];
                    if ([obj isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *bodyDic = (NSDictionary *)obj;
                        NSArray *actions = [bodyDic objectForKey:@"actions"];
                        actionsCount = (int)[actions count];
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x01, 0xff, actionsCount,_applyRepeat,0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }
                }else {
                    if (![state boolValue]) {
                        id obj = [_mDic objectForKey:@"no_body"];
                        if (obj) {
                            if ([obj isKindOfClass:[NSNumber class]]) {
                                NSDictionary *actionDic = @{@"actionID":@(_applyAction), @"scene_index":@(_applyIndex), @"delay":@(_applyDelay)};
                                [_mDic setObject:@{@"actions":@[actionDic]} forKey:@"no_body"];
                                actionsCount = 1;
                            }else if ([obj isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *actionDic = @{@"actionID":@(_applyAction), @"scene_index":@(_applyIndex), @"delay":@(_applyDelay)};
                                NSDictionary *bodyDic = (NSDictionary *)obj;
                                NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:[bodyDic objectForKey:@"actions"]];
                                [actions addObject:actionDic];
                                [_mDic setObject:@{@"actions":actions} forKey:@"no_body"];
                                actionsCount = (int)[actions count];
                            }
                            CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                            NSMutableDictionary *bsDic;
                            if ([de.remoteBranch length] > 0) {
                                NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                                if (dic) {
                                    bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                                }else {
                                    bsDic = [NSMutableDictionary new];
                                }
                                [bsDic setObject:_mDic forKey:@"body_sensor"];
                            }else {
                                bsDic = [NSMutableDictionary new];
                                [bsDic setObject:_mDic forKey:@"body_sensor"];
                            }
                            de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            
                            BOOL exist = NO;
                            if ([_members count]>0) {
                                id robj = [_members lastObject];
                                if ([robj isKindOfClass:[NSString class]]) {
                                    NSString *str = (NSString *)robj;
                                    if ([str length]==1) {
                                        exist = YES;
                                    }
                                }
                            }
                            if (exist) {
                                [_members insertObject:@(_applyDelay) atIndex:[_members count]-1];
                            }else {
                                [_members addObject:@(_applyDelay)];
                            }
                            [_tableView reloadData];
                        }
                    }else {
                        
                    }
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"下个步骤：" preferredStyle:UIAlertControllerStyleAlert];
                    [alert.view setTintColor:DARKORAGE];
                    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"动作不重复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        _applyAction = 255;
                        _applyRepeat = NO;
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x01, 0xff, actionsCount,0x00,0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }];
                    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"动作重复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        _applyAction = 255;
                        _applyRepeat = YES;
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x01, 0xff, actionsCount,0x01,0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }];
                    if (_applyAction == 4) {
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        if (!repeat) {
                            [alert addAction:action1];
                            [alert addAction:action2];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }else {
                        UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"继续添加动作" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                            [self addItemAction];
                        }];
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        if (!repeat) {
                            [alert addAction:action3];
                            [alert addAction:action1];
                            [alert addAction:action2];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }
                }
            }else if ([trigger intValue] == 2 && _triggerNumber == 5 && [action intValue] == _applyAction) {
                if (_applyAction == 255) {
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                    if (![[_mDic allKeys] containsObject:@"repeat"]) {
                        if (_applyRepeat) {
                            [_members addObject:@"Y"];
                        }else {
                            [_members addObject:@"N"];
                        }
                        [_tableView reloadData];
                    }
                    [_mDic setObject:@(_applyRepeat) forKey:@"repeat"];
                    CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                    NSMutableDictionary *bsDic;
                    if ([de.remoteBranch length] > 0) {
                        NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                        if (dic) {
                            bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                        }else {
                            bsDic = [NSMutableDictionary new];
                        }
                        [bsDic setObject:_mDic forKey:@"temperature_sensor"];
                    }else {
                        bsDic = [NSMutableDictionary new];
                        [bsDic setObject:_mDic forKey:@"temperature_sensor"];
                    }
                    de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }else {
                    if (![state boolValue]) {
                        id obj = [_mDic objectForKey:@"greater"];
                        if (obj) {
                            if ([obj isKindOfClass:[NSNumber class]]) {
                                NSDictionary *actionDic = @{@"actionID":@(_applyAction), @"scene_index":@(_applyIndex), @"delay":@(_applyDelay)};
                                [_mDic setObject:@{@"actions":@[actionDic], @"temperature_value":_temperatures[_selectedRow]} forKey:@"greater"];
                                actionsCount = 1;
                            }else if ([obj isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *actionDic = @{@"actionID":@(_applyAction), @"scene_index":@(_applyIndex), @"delay":@(_applyDelay)};
                                NSDictionary *bodyDic = (NSDictionary *)obj;
                                NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:[bodyDic objectForKey:@"actions"]];
                                [actions addObject:actionDic];
                                [_mDic setObject:@{@"actions":actions, @"temperature_value":_temperatures[_selectedRow]} forKey:@"greater"];
                                actionsCount = (int)[actions count];
                            }
                            CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                            NSMutableDictionary *bsDic;
                            if ([de.remoteBranch length] > 0) {
                                NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                                if (dic) {
                                    bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                                }else {
                                    bsDic = [NSMutableDictionary new];
                                }
                                [bsDic setObject:_mDic forKey:@"temperature_sensor"];
                            }else {
                                bsDic = [NSMutableDictionary new];
                                [bsDic setObject:_mDic forKey:@"temperature_sensor"];
                            }
                            de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            BOOL exist = NO;
                            if ([_members count]>0) {
                                id robj = [_members lastObject];
                                if ([robj isKindOfClass:[NSString class]]) {
                                    NSString *str = (NSString *)robj;
                                    if ([str length]==1) {
                                        exist = YES;
                                    }
                                }
                            }
                            if (exist) {
                                [_members insertObject:@(_applyDelay) atIndex:[_members count]-1];
                            }else {
                                [_members addObject:@(_applyDelay)];
                            }
                            [_tableView reloadData];
                        }
                    }else {
                        
                    }
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"下个步骤：" preferredStyle:UIAlertControllerStyleAlert];
                    [alert.view setTintColor:DARKORAGE];
                    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"动作不重复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        _applyAction = 255;
                        _applyRepeat = NO;
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x02, 0xff, actionsCount,0x00,0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }];
                    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"动作重复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        _applyAction = 255;
                        _applyRepeat = YES;
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x02, 0xff, actionsCount,0x01,0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }];
                    if (_applyAction == 4) {
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        if (!repeat) {
                            [alert addAction:action1];
                            [alert addAction:action2];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }else {
                        UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"继续添加动作" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                            [self addItemAction];
                        }];
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        if (!repeat) {
                            [alert addAction:action3];
                            [alert addAction:action1];
                            [alert addAction:action2];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }
                }
            }else if ([trigger intValue] == 2 && _triggerNumber == 6 && [action intValue] == _applyAction) {
                if (_applyAction == 255) {
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                    if (![[_mDic allKeys] containsObject:@"repeat"]) {
                        if (_applyRepeat) {
                            [_members addObject:@"Y"];
                        }else {
                            [_members addObject:@"N"];
                        }
                        [_tableView reloadData];
                    }
                    [_mDic setObject:@(_applyRepeat) forKey:@"repeat"];
                    CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                    NSMutableDictionary *bsDic;
                    if ([de.remoteBranch length] > 0) {
                        NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                        if (dic) {
                            bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                        }else {
                            bsDic = [NSMutableDictionary new];
                        }
                        [bsDic setObject:_mDic forKey:@"temperature_sensor"];
                    }else {
                        bsDic = [NSMutableDictionary new];
                        [bsDic setObject:_mDic forKey:@"temperature_sensor"];
                    }
                    de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }else {
                    if (![state boolValue]) {
                        id obj = [_mDic objectForKey:@"less"];
                        if (obj) {
                            if ([obj isKindOfClass:[NSNumber class]]) {
                                NSDictionary *actionDic = @{@"actionID":@(_applyAction), @"scene_index":@(_applyIndex), @"delay":@(_applyDelay)};
                                [_mDic setObject:@{@"actions":@[actionDic], @"temperature_value":_temperatures[_selectedRow]} forKey:@"less"];
                                actionsCount = 1;
                            }else if ([obj isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *actionDic = @{@"actionID":@(_applyAction), @"scene_index":@(_applyIndex), @"delay":@(_applyDelay)};
                                NSDictionary *bodyDic = (NSDictionary *)obj;
                                NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:[bodyDic objectForKey:@"actions"]];
                                [actions addObject:actionDic];
                                [_mDic setObject:@{@"actions":actions, @"temperature_value":_temperatures[_selectedRow]} forKey:@"less"];
                                actionsCount = (int)[actions count];
                            }
                            CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                            NSMutableDictionary *bsDic;
                            if ([de.remoteBranch length] > 0) {
                                NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                                if (dic) {
                                    bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                                }else {
                                    bsDic = [NSMutableDictionary new];
                                }
                                [bsDic setObject:_mDic forKey:@"temperature_sensor"];
                            }else {
                                bsDic = [NSMutableDictionary new];
                                [bsDic setObject:_mDic forKey:@"temperature_sensor"];
                            }
                            de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            BOOL exist = NO;
                            if ([_members count]>0) {
                                id robj = [_members lastObject];
                                if ([robj isKindOfClass:[NSString class]]) {
                                    NSString *str = (NSString *)robj;
                                    if ([str length]==1) {
                                        exist = YES;
                                    }
                                }
                            }
                            if (exist) {
                                [_members insertObject:@(_applyDelay) atIndex:[_members count]-1];
                            }else {
                                [_members addObject:@(_applyDelay)];
                            }
                            [_tableView reloadData];
                        }
                    }else {
                        
                    }
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"下个步骤：" preferredStyle:UIAlertControllerStyleAlert];
                    [alert.view setTintColor:DARKORAGE];
                    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"动作不重复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        _applyAction = 255;
                        _applyRepeat = NO;
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x02, 0xff, actionsCount,0x00,0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }];
                    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"动作重复" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        _applyAction = 255;
                        _applyRepeat = YES;
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x02, 0xff, actionsCount,0x01,0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }];
                    if (_applyAction == 4) {
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        if (!repeat) {
                            [alert addAction:action1];
                            [alert addAction:action2];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }else {
                        UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"继续添加动作" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PIRACTIONCALL" object:nil];
                            [self addItemAction];
                        }];
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        if (!repeat) {
                            [alert addAction:action3];
                            [alert addAction:action1];
                            [alert addAction:action2];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }
                }
            }
        }
        
    }
}

- (void)sceneMemberFrom:(NSArray *)actions {
    for (NSDictionary *dic in actions) {
        NSNumber *sIndex = dic[@"scene_index"];
        SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:sIndex];
        [_scenes addObject:scene];
        for (SceneMemberEntity *member in scene.members) {
            [_sceneMembers addObject:member];
        }
    }
}

- (BOOL)nextMemberOperation {
    if ([_sceneMembers count]>0) {
        SceneMemberEntity *m = [_sceneMembers firstObject];
        CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:m.deviceID];
        if (d == nil) {
            [_sceneMembers removeObject:m];
            return [self nextMemberOperation];
        }else {
            [self performSelector:@selector(removeSceneIDTimeOut) withObject:nil afterDelay:10];
            
            NSInteger s = [m.sceneID integerValue];
            Byte b[] = {};
            b[0] = (Byte)((s & 0xFF00)>>8);
            b[1] = (Byte)(s & 0x00FF);
            
            if ([CSRUtilities belongToTwoChannelSwitch:m.kindString]
                || [CSRUtilities belongToThreeChannelSwitch:m.kindString]
                || [CSRUtilities belongToTwoChannelDimmer:m.kindString]
                || [CSRUtilities belongToSocketTwoChannel:m.kindString]
                || [CSRUtilities belongToTwoChannelCurtainController:m.kindString]) {
                Byte byte[] = {0x5d, 0x03, [m.channel integerValue], b[1], b[0]};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
                retryCount = 0;
                retryCmd = cmd;
                retryDeviceId = m.deviceID;
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:m.deviceID data:cmd];
            }else {
                Byte byte[] = {0x98, 0x02, b[1], b[0]};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
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

- (void)removeSceneIDTimeOut {
    if (retryCount < 1) {
        [self performSelector:@selector(removeSceneIDTimeOut) withObject:nil afterDelay:10];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:retryDeviceId data:retryCmd];
        retryCount ++;
    }else {
        SceneMemberEntity *m = [_sceneMembers firstObject];
        [_sceneMembers removeObject:m];
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:m];
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        if (![self nextMemberOperation]) {
            for (SceneEntity *srs in _scenes) {
                [[CSRAppStateManager sharedInstance].selectedPlace removeScenesObject:srs];
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:srs];
            }
            [[CSRDatabaseManager sharedInstance] saveContext];
            if (_triggerNumber == 1) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                Byte byte[] = {0xea, 0x8b, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }else if (_triggerNumber == 2) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                Byte byte[] = {0xea, 0x8b, 0x00, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }else if (_triggerNumber == 3) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                Byte byte[] = {0xea, 0x8b, 0x00, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00, 0x00};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }else if (_triggerNumber == 5) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                NSInteger temp = [_temperatures[_selectedRow] integerValue];
                if (temp < 0) {
                    temp = ((-temp) & 0x7F) + 0x80;
                }else {
                    temp = (temp & 0x7F);
                }
                Byte byte[] = {0xea, 0x8b, 0x00, 0x02, 0x02, 0x00, temp, 0x00, 0x00, 0x00};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }else if (_triggerNumber == 6) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                NSInteger temp = [_temperatures[_selectedRow] integerValue];
                if (temp < 0) {
                    temp = ((-temp) & 0x7F) + 0x80;
                }else {
                    temp = (temp & 0x7F);
                }
                Byte byte[] = {0xea, 0x8b, 0x00, 0x02, 0x02, 0x04, temp, 0x00, 0x00, 0x00};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    id obj = [_members objectAtIndex:indexPath.row];
    if ([obj isKindOfClass:[SceneMemberExpandModel class]]) {
        return YES;
    }
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        SceneMemberExpandModel *member = [_members objectAtIndex:indexPath.row];
        [self removeSceneMember:member];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AcTECLocalizedStringFromTable(@"Remove", @"Localizable");
}

- (void)removeSceneMember:(SceneMemberExpandModel *)member {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"removeSceneMemberAlert", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
    [alert.view setTintColor:DARKORAGE];
    if ([member.stateDic count]>0) {
        NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
        [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1 intValue] < [obj2 integerValue]) {
                return NSOrderedAscending;
            }else {
                return NSOrderedDescending;
            }
        }];
        for (NSNumber *channel in keys) {
            NSArray *ary = [member.stateDic objectForKey:channel];
            if (ary) {
                for (NSInteger i=0; i<64; i++) {
                    NSInteger c = [channel integerValue];
                    NSInteger b = (c & (NSInteger)pow(2, i)) >> i;
                    if (b == 1) {
                        NSString *title = [NSString stringWithFormat:@"%ld", i+1];
                        UIAlertAction *eve = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                            [self showLoading];
                            [self performSelector:@selector(removeSceneIDTimerOut) withObject:nil afterDelay:10.0];
                            _mDeviceToApplay = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:member.sceneID];
                            for (SceneMemberEntity *sme in sceneEntity.members) {
                                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                    _mMemberToApply = sme;
                                    break;
                                }
                            }
                            NSInteger s = [member.sceneID integerValue];
                            Byte b[] = {};
                            b[0] = (Byte)((s & 0xFF00)>>8);
                            b[1] = (Byte)(s & 0x00FF);
                            if ([CSRUtilities belongToTwoChannelSwitch:member.kindString]
                                || [CSRUtilities belongToThreeChannelSwitch:member.kindString]
                                || [CSRUtilities belongToTwoChannelDimmer:member.kindString]
                                || [CSRUtilities belongToSocketTwoChannel:member.kindString]
                                || [CSRUtilities belongToTwoChannelCurtainController:member.kindString]
                                || [CSRUtilities belongToThreeChannelDimmer:member.kindString]
                                || [CSRUtilities belongToMusicController:member.kindString]
                                || [CSRUtilities belongToSonosMusicController:member.kindString]) {
                                Byte byte[] = {0x5d, 0x03, c, b[1], b[0]};
                                NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
                                retryCount = 0;
                                retryCmd = cmd;
                                retryDeviceId = member.deviceID;
                                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:member.deviceID data:cmd];
                            }else {
                                Byte byte[] = {0x98, 0x02, b[1], b[0]};
                                NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                                retryCount = 0;
                                retryCmd = cmd;
                                retryDeviceId = member.deviceID;
                                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:member.deviceID data:cmd];
                            }
                        }];
                        [alert addAction:eve];
                        break;
                    }
                }
            }
        }
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

    }];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)removeSceneIDTimerOut {
    if (retryCount < 1) {
        [self performSelector:@selector(removeSceneIDTimerOut) withObject:nil afterDelay:10.0];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:retryDeviceId data:retryCmd];
        retryCount ++;
    }else {
//        [self hideLoading];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"%@ %@",_mDeviceToApplay.name,AcTECLocalizedStringFromTable(@"removescenefail", @"Localizable")] preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self removeMemberFromMembers:_mMemberToApply];
            [_tableView reloadData];
            
            SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_mMemberToApply.sceneID];
            [s removeMembersObject:_mMemberToApply];
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_mMemberToApply];
            [[CSRDatabaseManager sharedInstance] saveContext];
            
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
    if ([_sceneMembers count] > 0) {
        SceneMemberEntity *m = [_sceneMembers firstObject];
        if ([deviceID isEqualToNumber:m.deviceID] && [sceneID isEqualToNumber:m.sceneID]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeSceneIDTimeOut) object:nil];
            
            [_sceneMembers removeObject:m];
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:m];
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            if (![self nextOperation]) {
                for (SceneEntity *srs in _scenes) {
                    [[CSRAppStateManager sharedInstance].selectedPlace removeScenesObject:srs];
                    [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:srs];
                }
                [[CSRDatabaseManager sharedInstance] saveContext];
                if (_triggerNumber == 1) {
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                    Byte byte[] = {0xea, 0x8b, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                }else if (_triggerNumber == 2) {
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                    Byte byte[] = {0xea, 0x8b, 0x00, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                }else if (_triggerNumber == 3) {
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                    Byte byte[] = {0xea, 0x8b, 0x00, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00, 0x00};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                }else if (_triggerNumber == 5) {
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                    NSInteger temp = [_temperatures[_selectedRow] integerValue];
                    if (temp < 0) {
                        temp = ((-temp) & 0x7F) + 0x80;
                    }else {
                        temp = (temp & 0x7F);
                    }
                    Byte byte[] = {0xea, 0x8b, 0x00, 0x02, 0x02, 0x00, temp, 0x00, 0x00, 0x00};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                }else if (_triggerNumber == 6) {
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerCall:) name:@"PIRTRIGGERCALL" object:nil];
                    NSInteger temp = [_temperatures[_selectedRow] integerValue];
                    if (temp < 0) {
                        temp = ((-temp) & 0x7F) + 0x80;
                    }else {
                        temp = (temp & 0x7F);
                    }
                    Byte byte[] = {0xea, 0x8b, 0x00, 0x02, 0x02, 0x04, temp, 0x00, 0x00, 0x00};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                }
            }
        }
    }else if (_mDeviceToApplay && [_mDeviceToApplay.deviceId isEqualToNumber:deviceID] && [sceneID isEqualToNumber:_mMemberToApply.sceneID]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeSceneIDTimerOut) object:nil];
        
        [self removeMemberFromMembers:_mMemberToApply];
        [_tableView reloadData];
        
        SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:sceneID];
        [s removeMembersObject:_mMemberToApply];
        if ([s.members count] == 0) {
            NSDictionary *dAction;
            if (_triggerNumber == 1 || _triggerNumber == 3) {
                NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:_mDic[@"body"][@"actions"]];
                for (NSDictionary *action in actions) {
                    NSNumber *sceneIndex = action[@"scene_index"];
                    if ([sceneIndex isEqualToNumber:sceneID]) {
                        dAction = action;
                        break;
                    }
                }
                if (dAction) {
                    [actions removeObject:dAction];
                    _actionIDToApply = [dAction[@"actionID"] intValue];
                    if (_actionIDToApply < [actions count]) {
                        for (NSDictionary *action in actions) {
                            int eActionID = [action[@"actionID"] intValue];
                            if (eActionID > _actionIDToApply) {
                                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionCall:) name:@"PIRACTIONCALL" object:nil];
                                Byte byte[] = {0xea, 0x8b, 0x04, 0x00, _actionIDToApply, 0x00, 0x00, [action[@"scene_index"] integerValue] & 0x00FF, ([action[@"scene_index"] integerValue] & 0xFF00)>>8, [action[@"delay"] intValue]};
                                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                            }
                        }
                    }else {
                        _actionIDToApply = 255;
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x00, 0xff, [actions count], [repeat boolValue],0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }
                    [_mDic setObject:@{@"actions":actions} forKey:@"body"];
                    CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                    NSMutableDictionary *bsDic;
                    if ([de.remoteBranch length] > 0) {
                        NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                        if (dic) {
                            bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                        }else {
                            bsDic = [NSMutableDictionary new];
                        }
                        [bsDic setObject:_mDic forKey:@"body_sensor"];
                    }else {
                        bsDic = [NSMutableDictionary new];
                        [bsDic setObject:_mDic forKey:@"body_sensor"];
                    }
                    de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    NSLog(@">> %@", _mDic);
                }
            }else if (_triggerNumber == 2 || _triggerNumber == 4) {
                NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:_mDic[@"no_body"][@"actions"]];
                for (NSDictionary *action in actions) {
                    NSNumber *sceneIndex = action[@"scene_index"];
                    if ([sceneIndex isEqualToNumber:sceneID]) {
                        dAction = action;
                        break;
                    }
                }
                if (dAction) {
                    [actions removeObject:dAction];
                    _actionIDToApply = [dAction[@"actionID"] intValue];
                    if (_actionIDToApply < [actions count]) {
                        for (NSDictionary *action in actions) {
                            int eActionID = [action[@"actionID"] intValue];
                            if (eActionID > _actionIDToApply) {
                                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionCall:) name:@"PIRACTIONCALL" object:nil];
                                Byte byte[] = {0xea, 0x8b, 0x04, 0x01, _actionIDToApply, 0x00, 0x00, [action[@"scene_index"] integerValue] & 0x00FF, ([action[@"scene_index"] integerValue] & 0xFF00)>>8, [action[@"delay"] intValue]};
                                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                            }
                        }
                    }else {
                        _actionIDToApply = 255;
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x01, 0xff, [actions count],[repeat boolValue],0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }
                    [_mDic setObject:@{@"actions":actions} forKey:@"no_body"];
                    CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                    NSMutableDictionary *bsDic;
                    if ([de.remoteBranch length] > 0) {
                        NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                        if (dic) {
                            bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                        }else {
                            bsDic = [NSMutableDictionary new];
                        }
                        [bsDic setObject:_mDic forKey:@"body_sensor"];
                    }else {
                        bsDic = [NSMutableDictionary new];
                        [bsDic setObject:_mDic forKey:@"body_sensor"];
                    }
                    de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }
            }else if (_triggerNumber == 5) {
                NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:_mDic[@"greater"][@"actions"]];
                for (NSDictionary *action in actions) {
                    NSNumber *sceneIndex = action[@"scene_index"];
                    if ([sceneIndex isEqualToNumber:sceneID]) {
                        dAction = action;
                        break;
                    }
                }
                if (dAction) {
                    [actions removeObject:dAction];
                    _actionIDToApply = [dAction[@"actionID"] intValue];
                    if (_actionIDToApply < [actions count]) {
                        for (NSDictionary *action in actions) {
                            int eActionID = [action[@"actionID"] intValue];
                            if (eActionID > _actionIDToApply) {
                                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionCall:) name:@"PIRACTIONCALL" object:nil];
                                Byte byte[] = {0xea, 0x8b, 0x04, 0x02, _actionIDToApply, 0x00, 0x00, [action[@"scene_index"] integerValue] & 0x00FF, ([action[@"scene_index"] integerValue] & 0xFF00)>>8, [action[@"delay"] intValue]};
                                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                            }
                        }
                    }else {
                        _actionIDToApply = 255;
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x02, 0xff, [actions count],[repeat boolValue],0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }
                    [_mDic setObject:@{@"actions":actions} forKey:@"greater"];
                    CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                    NSMutableDictionary *bsDic;
                    if ([de.remoteBranch length] > 0) {
                        NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                        if (dic) {
                            bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                        }else {
                            bsDic = [NSMutableDictionary new];
                        }
                        [bsDic setObject:_mDic forKey:@"temperature_sensor"];
                    }else {
                        bsDic = [NSMutableDictionary new];
                        [bsDic setObject:_mDic forKey:@"temperature_sensor"];
                    }
                    de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }
            }else if (_triggerNumber == 6) {
                NSMutableArray *actions = [[NSMutableArray alloc] initWithArray:_mDic[@"less"][@"actions"]];
                for (NSDictionary *action in actions) {
                    NSNumber *sceneIndex = action[@"scene_index"];
                    if ([sceneIndex isEqualToNumber:sceneID]) {
                        dAction = action;
                        break;
                    }
                }
                if (dAction) {
                    [actions removeObject:dAction];
                    _actionIDToApply = [dAction[@"actionID"] intValue];
                    if (_actionIDToApply < [actions count]) {
                        for (NSDictionary *action in actions) {
                            int eActionID = [action[@"actionID"] intValue];
                            if (eActionID > _actionIDToApply) {
                                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionCall:) name:@"PIRACTIONCALL" object:nil];
                                Byte byte[] = {0xea, 0x8b, 0x04, 0x02, _actionIDToApply, 0x00, 0x00, [action[@"scene_index"] integerValue] & 0x00FF, ([action[@"scene_index"] integerValue] & 0xFF00)>>8, [action[@"delay"] intValue]};
                                NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                            }
                        }
                    }else {
                        _actionIDToApply = 255;
                        NSNumber *repeat = [_mDic objectForKey:@"repeat"];
                        Byte byte[] = {0xea, 0x8b, 0x04, 0x02, 0xff, [actions count],[repeat boolValue],0x01,0x00,0x00};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    }
                    [_mDic setObject:@{@"actions":actions} forKey:@"less"];
                    CSRDeviceEntity *de = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                    NSMutableDictionary *bsDic;
                    if ([de.remoteBranch length] > 0) {
                        NSDictionary *dic = [CSRUtilities dictionaryWithJsonString:de.remoteBranch];
                        if (dic) {
                            bsDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
                        }else {
                            bsDic = [NSMutableDictionary new];
                        }
                        [bsDic setObject:_mDic forKey:@"temperature_sensor"];
                    }else {
                        bsDic = [NSMutableDictionary new];
                        [bsDic setObject:_mDic forKey:@"temperature_sensor"];
                    }
                    de.remoteBranch = [CSRUtilities convertToJsonData2:bsDic];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }
            }
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:s];
        }
        
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_mMemberToApply];
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        _mMemberToApply = nil;
        
//        [self hideLoading];
    }
}

- (void)removeMemberFromMembers:(SceneMemberEntity *)memberEntity {
    for (int i=0; i<_members.count; i++) {
        id obj = _members[i];
        if ([obj isKindOfClass:[SceneMemberExpandModel class]]) {
            SceneMemberExpandModel *eModel = (SceneMemberExpandModel *)obj;
            int dIndex = -1;
            if ([eModel.deviceID isEqualToNumber:memberEntity.deviceID]) {
                if ([eModel.stateDic count] > 0) {
                    NSMutableDictionary *mDic = [[NSMutableDictionary alloc] initWithDictionary:eModel.stateDic];
                    id obj = [mDic objectForKey:memberEntity.channel];
                    if (obj) {
                        [mDic removeObjectForKey:memberEntity.channel];
                        if ([mDic count] > 0) {
                            eModel.stateDic = mDic;
                        }else {
                            [_members removeObject:eModel];
                            SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:memberEntity.sceneID];
                            if ([s.members count] == 1) {
                                dIndex = i;
                            }
                        }
                    }
                }
                if (dIndex != -1) {
                    [_members removeObjectAtIndex:i];
                }
                NSLog(@"m: %@", _members);
                break;
            }
        }
    }
}

- (void)repeatSwitch:(UISwitch *)sender {
    if (_triggerNumber == 1) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionCall:) name:@"PIRACTIONCALL" object:nil];
        _applyAction = 255;
        _applyRepeat = sender.on;
        NSArray *actions = _mDic[@"body"][@"actions"];
        Byte byte[] = {0xea, 0x8b, 0x04, 0x00, 0xff, [actions count],sender.on,0x01,0x00,0x00};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }else if (_triggerNumber == 2) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionCall:) name:@"PIRACTIONCALL" object:nil];
        _applyAction = 255;
        _applyRepeat = sender.on;
        NSArray *actions = _mDic[@"no_body"][@"actions"];
        Byte byte[] = {0xea, 0x8b, 0x04, 0x01, 0xff, [actions count],sender.on,0x01,0x00,0x00};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }else if (_triggerNumber == 4) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionCall:) name:@"PIRACTIONCALL" object:nil];
        _applyAction = 255;
        _applyRepeat = sender.on;
        NSArray *actions = _mDic[@"body"][@"actions"];
        Byte byte[] = {0xea, 0x8b, 0x04, 0x00, 0xff, [actions count],sender.on,0x01,0x00,0x00};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        [NSThread sleepForTimeInterval:0.5];
        NSArray *nactions = _mDic[@"no_body"][@"actions"];
        Byte nbyte[] = {0xea, 0x8b, 0x04, 0x01, 0xff, [nactions count],sender.on,0x01,0x00,0x00};
        NSData *ncmd = [[NSData alloc] initWithBytes:nbyte length:10];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:ncmd];
    }else if (_triggerNumber == 5) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionCall:) name:@"PIRACTIONCALL" object:nil];
        _applyAction = 255;
        _applyRepeat = sender.on;
        NSArray *actions = _mDic[@"greater"][@"actions"];
        Byte byte[] = {0xea, 0x8b, 0x04, 0x02, 0xff, [actions count],sender.on,0x01,0x00,0x00};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }else if (_triggerNumber == 6) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionCall:) name:@"PIRACTIONCALL" object:nil];
        _applyAction = 255;
        _applyRepeat = sender.on;
        NSArray *actions = _mDic[@"less"][@"actions"];
        Byte byte[] = {0xea, 0x8b, 0x04, 0x02, 0xff, [actions count],sender.on,0x01,0x00,0x00};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
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
