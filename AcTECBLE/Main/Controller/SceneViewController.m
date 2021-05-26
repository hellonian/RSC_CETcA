//
//  SceneViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/6/10.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "SceneViewController.h"
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
#import "SceneMemberExpandModel.h"
#import "ThermoregulatorViewController.h"

#define TFENGSU @[@"自动", @"超低速", @"中低速", @"中速", @"中高速", @"高速", @"超高速"]
#define TWENDU @[@"16 ℃", @"17 ℃", @"18 ℃", @"19 ℃", @"20 ℃", @"21 ℃", @"22 ℃", @"23 ℃", @"24 ℃", @"25 ℃", @"26 ℃", @"27 ℃", @"28 ℃", @"29 ℃", @"30 ℃"]
#define TMOSHI @[@"自动", @"制冷", @"制热", @"除湿", @"送风"]
#define TFENGXIANG @[@"自动", @"向上", @"向下", @"向左", @"向右"]

@interface SceneViewController ()<UITableViewDelegate,UITableViewDataSource>
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
@property (nonatomic, assign) BOOL isResetting;
@property (nonatomic, strong) NSArray *devices;

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
    _sceneMemberList.rowHeight = 56.0f;
    _sceneMemberList.backgroundView = [[UIView alloc] init];
    _sceneMemberList.backgroundColor = [UIColor clearColor];
    
    _members = [[NSMutableArray alloc] init];
    
    if (_sceneIndex) {
        SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
        if (sceneEntity) {
            if (_srDeviceId) {
                CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_srDeviceId];
                if (d) {
                    self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@ %ld",d.name,AcTECLocalizedStringFromTable(@"key", @"Localizable"),(long)_keyNumber];
                }
            }else {
                if (sceneEntity.sceneName) {
                    self.navigationItem.title = sceneEntity.sceneName;
                }
            }
            
            if ([sceneEntity.members count]>0) {
                for (SceneMemberEntity *memberEntity in sceneEntity.members) {
                    [self addMemberToMembers:memberEntity];
                }
            }
        }
    }
    
    if (_srDeviceId) {
        CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_srDeviceId];
        if (d) {
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %@ %ld",d.name,AcTECLocalizedStringFromTable(@"key", @"Localizable"),(long)_keyNumber];
        }
        if (_sceneIndex > 0) {
            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
            if (sceneEntity) {
                self.navigationItem.title = sceneEntity.sceneName;
                if ([sceneEntity.members count] > 0) {
                    for (SceneMemberEntity *memberEntity in sceneEntity.members) {
                        [self addMemberToMembers:memberEntity];
                    }
                }
            }
        }
    }else {
        if (_sceneIndex) {
            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
            if (sceneEntity) {
                self.navigationItem.title = sceneEntity.sceneName;
                if ([sceneEntity.members count] > 0) {
                    for (SceneMemberEntity *memberEntity in sceneEntity.members) {
                        [self addMemberToMembers:memberEntity];
                    }
                }
            }
        }
    }
    
}

- (void)addMemberToMembers:(SceneMemberEntity *)memberEntity {
    SceneMemberExpandModel *model;
    for (SceneMemberExpandModel *eModel in _members) {
        if ([eModel.deviceID isEqualToNumber:memberEntity.deviceID]) {
            model = eModel;
            break;
        }
    }
    if (!model) {
        model = [[SceneMemberExpandModel alloc] init];
        model.deviceID = memberEntity.deviceID;
        model.kindString = memberEntity.kindString;
        model.sceneID = memberEntity.sceneID;
        model.stateDic = @{memberEntity.channel : @[memberEntity.eveType, memberEntity.eveD0, memberEntity.eveD1, memberEntity.eveD2, memberEntity.eveD3]};
        [_members addObject:model];
    }else {
        NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithDictionary:model.stateDic];
        [mutableDic setObject:@[memberEntity.eveType, memberEntity.eveD0, memberEntity.eveD1, memberEntity.eveD2, memberEntity.eveD3] forKey:memberEntity.channel];
        model.stateDic = mutableDic;
    }
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
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    SceneMemberExpandModel *member = [_members objectAtIndex:indexPath.row];
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
        SceneMemberExpandModel *member = [_members objectAtIndex:indexPath.row];
        [self removeSceneMember:member];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AcTECLocalizedStringFromTable(@"Remove", @"Localizable");
}

- (void)closeAction {
    if (_forSceneRemote) {
        [self.navigationController popViewControllerAnimated:YES];
    }else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)addClick {
    _isResetting = NO;
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_Multiple;
    list.originalMembers = _members;
    
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count] > 0) {
            [self showLoading];
            _devices = devices;
            if (_srDeviceId && [_sceneIndex integerValue] == 0) {
                for (SceneEntity *scene in [CSRAppStateManager sharedInstance].selectedPlace.scenes) {
                    if ([scene.srDeviceId isEqualToNumber:_srDeviceId] && [scene.iconID integerValue] == _keyNumber) {
                        [[NSNotificationCenter defaultCenter] addObserver:self
                                                                 selector:@selector(callbackOfRemoteConfigruation:)
                                                                     name:@"CALLBACKOFREMOTECONFIGURATION"
                                                                   object:nil];
                        NSLog(@"%@  %@  %@  %@",scene.rcIndex, scene.sceneID, scene.srDeviceId, scene.iconID);
                        Byte byte[] = {0x9b, 0x06, 0x01, _keyNumber, [scene.rcIndex integerValue] & 0x00FF, ([scene.rcIndex integerValue] & 0xFF00)>>8, 0x00, 0x00};
                        retryCount = 0;
                        retryCmd = [[NSData alloc] initWithBytes:byte length:8];
                        [self performSelector:@selector(configureSceneRemoteTimeOut) withObject:nil afterDelay:15.0f];
                        [[DataModelManager shareInstance] sendDataByStreamDataTransfer:_srDeviceId data:retryCmd];
                        break;
                    }
                }
            }else {
                [self createMembers];
            }
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)configureSceneRemoteTimeOut {
    if (retryCount < 5) {
        retryCount ++;
        [self performSelector:@selector(configureSceneRemoteTimeOut) withObject:nil afterDelay:15.0f];
        [[DataModelManager shareInstance] sendDataByStreamDataTransfer:_srDeviceId data:retryCmd];
    }
}

- (void)callbackOfRemoteConfigruation:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *sourceDeviceId = userInfo[@"DEVICEID"];
    if ([sourceDeviceId isEqualToNumber:_srDeviceId]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(configureSceneRemoteTimeOut) object:nil];
        NSNumber *state = userInfo[@"STATE"];
        if ([state boolValue] && [retryCmd length] == 8) {
            Byte *byte = (Byte *)[retryCmd bytes];
            _sceneIndex = @(byte[4] + byte[5] * 256);
            CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_srDeviceId];
            NSLog(@"~~> %@  %@",d.remoteBranch, retryCmd);
            if (d) {
                NSString *p = [d.remoteBranch substringToIndex:(_keyNumber-1)*6+2];
                NSString *l = [d.remoteBranch substringFromIndex:(_keyNumber-1)*6+6];
                NSString *n = [CSRUtilities hexStringForData:[retryCmd subdataWithRange:NSMakeRange(4, 2)]];
                d.remoteBranch = [NSString stringWithFormat:@"%@%@%@",p,n,l];
                NSLog(@">> %@",d.remoteBranch);
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            [self createMembers];
        }
    }
}

- (void)createMembers {
    for (id d in _devices) {
        if ([d isKindOfClass:[SonosSelectModel class]]) {
            SonosSelectModel *ssm = (SonosSelectModel *)d;
            if ([ssm.channel integerValue] != -1) {
                [self createSceneMemberSonos:ssm];
            }
        }else {
            SelectModel *model = (SelectModel *)d;
            DeviceModel *device = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:model.deviceID];
            if ([CSRUtilities belongToSwitch:device.shortName]
                || [CSRUtilities belongToSocketOneChannel:device.shortName]) {
                [self createSceneMemberSwitch:device channel:1];
            }else if ([CSRUtilities belongToTwoChannelSwitch:device.shortName]
                      || [CSRUtilities belongToSocketTwoChannel:device.shortName]) {
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
            }else if ([CSRUtilities belongToThermoregulator:device.shortName]) {
                [self createSceneMemberThermoregulator:device channel:[model.channel intValue]];
            }
        }
    }
        
    [self nextOperation];
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
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:m.deviceID data:cmd];
            }else if ([CSRUtilities belongToThermoregulator:m.kindString]) {
                Byte byte[] = {0x7c, 0x08, [m.channel integerValue], b[1], b[0], e, d0, d1, d2, d3};
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

- (void)createSceneMemberThermoregulator:(DeviceModel *)device channel:(int)channel {
    for (int i=0; i<64; i++) {
        int a = pow(2, i);
        int b = (channel & a) >> i;
        if (b == 1) {
            if ([device.stateDic count] > 0) {
                NSArray *ary = [device.stateDic objectForKey:@(i+1)];
                if ([ary count] == 5) {
                    SceneMemberEntity *m = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                    m.sceneID = _sceneIndex;
                    m.kindString = device.shortName;
                    m.deviceID = device.deviceId;
                    m.channel = @(i+1);
                    m.eveType = @(34);
                    uint8_t d1 = [ary[0] boolValue] + ([ary[3] integerValue] << 1) + ([ary[4] integerValue] << 4);
                    uint8_t d2 = [ary[1] integerValue];
                    uint8_t d3 = [ary[2] intValue]+16;
                    m.eveD0 = @(d1);
                    m.eveD1 = @(d2);
                    m.eveD2 = @(d3);
                    m.eveD3 = @(0);
                    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
                    [sceneEntity addMembersObject:m];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    [self.selects addObject:m];
                }
            }
        }
    }
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
            if (_isResetting) {
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            [self addMemberToMembers:m];
            [_sceneMemberList reloadData];
        }else {
            [self.fails addObject:[m.deviceID copy]];
            if (!_isResetting) {
                SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
                [s removeMembersObject:m];
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:m];
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
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
    if (retryCount < 1) {
        [self performSelector:@selector(setSceneIDTimerOut) withObject:nil afterDelay:10];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:retryDeviceId data:retryCmd];
        retryCount ++;
    }else {
        SceneMemberEntity *m = [self.selects firstObject];
        [self.selects removeObject:m];
        [self.fails addObject:[m.deviceID copy]];
        if (!_isResetting) {
            SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
            [s removeMembersObject:m];
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:m];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
        
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
                            [self showLoading];
                            [self performSelector:@selector(removeSceneIDTimerOut) withObject:nil afterDelay:10.0];
                            _mDeviceToApplay = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
                            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
                            for (SceneMemberEntity *sme in sceneEntity.members) {
                                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel isEqualToNumber:channel]) {
                                    _mMemberToApply = sme;
                                    break;
                                }
                            }
                            NSInteger s = [_sceneIndex integerValue];
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
                            }else if ([CSRUtilities belongToThermoregulator:member.kindString]) {
                                Byte byte[] = {0x67, 0x03, c, b[1], b[0]};
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
        [self hideLoading];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"%@ %@",_mDeviceToApplay.name,AcTECLocalizedStringFromTable(@"removescenefail", @"Localizable")] preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *yes = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self removeMemberFromMembers:_mMemberToApply];
            [_sceneMemberList reloadData];
            
            SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
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
    if (_mDeviceToApplay && [_mDeviceToApplay.deviceId isEqualToNumber:deviceID] && [sceneID isEqualToNumber:_sceneIndex]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeSceneIDTimerOut) object:nil];
        
        [self removeMemberFromMembers:_mMemberToApply];
        [_sceneMemberList reloadData];
        
        SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
        [s removeMembersObject:_mMemberToApply];
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_mMemberToApply];
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        _mMemberToApply = nil;
        [self hideLoading];
    }
}

- (void)removeMemberFromMembers:(SceneMemberEntity *)memberEntity {
    for (SceneMemberExpandModel *eModel in _members) {
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
                    }
                    break;
                }
            }
        }
    }
}

- (void)reSetting:(NSInteger )row {
    [self.selects removeAllObjects];
    _isResetting = YES;
    SceneMemberExpandModel *member = [_members objectAtIndex:row];
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
            [self reSettingSwitch:member];
        };
        [self.navigationController pushViewController:svc animated:YES];
    }else if ([CSRUtilities belongToSonosMusicController:member.kindString]) {
        SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
        SonosSceneSettingVC *sssvc = [[SonosSceneSettingVC alloc] init];
        sssvc.deviceID = member.deviceID;
        sssvc.source = 1;
        NSMutableArray *smodels = [[NSMutableArray alloc] init];
        if ([member.stateDic count] > 0) {
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
                    SonosSelectModel *model = [[SonosSelectModel alloc] init];
                    model.reSetting = YES;
                    model.selected = YES;
                    model.deviceID = member.deviceID;
                    for (int i=0; i<64; i++) {
                        NSInteger c = [channel integerValue];
                        NSInteger b = (c & (NSInteger)pow(2, i)) >> i;
                        if (b == 1) {
                            model.channel = @(i);
                            break;
                        }
                    }
                    model.play = [ary[0] integerValue] == 226 ? YES : NO;
                    model.voice = [ary[2] integerValue]/2;
                    model.songNumber = [ary[3] integerValue];
                    [smodels addObject:model];
                }
            }
        }
        sssvc.sModels = smodels;
        sssvc.sonosSceneSettingHandle = ^(NSArray * _Nonnull sModels) {
            for (SonosSelectModel *sm in sModels) {
                for (SonosSelectModel *m  in smodels) {
                    if (m.play != sm.play || m.voice != sm.voice || m.songNumber != sm.songNumber) {
                        for (SceneMemberEntity *sme in sceneEntity.members) {
                            if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == pow(2, [sm.channel integerValue])) {
                                if (sm.play) {
                                    sme.eveType = @(226);
                                }else {
                                    sme.eveType = @(130);
                                }
                                sme.eveD0 = @(sm.play*2+1);
                                sme.eveD1 = @(sm.voice*2);
                                sme.eveD2 = @(sm.songNumber);
                                [self.selects addObject:sme];
                                break;
                            }
                        }
                    }
                }
            }
            [self nextOperation];
        };
        [self.navigationController pushViewController:sssvc animated:YES];
    }else if ([CSRUtilities belongToThermoregulator:member.kindString]) {
        ThermoregulatorViewController *tvc = [[ThermoregulatorViewController alloc] init];
        tvc.deviceId = member.deviceID;
        tvc.source = 1;
        tvc.reloadDataHandle = ^{
            [self reSettingThermoregulator:member];
        };
        [self.navigationController pushViewController:tvc animated:YES];
    }else {
        DeviceViewController *dvc = [[DeviceViewController alloc] init];
        dvc.deviceId = member.deviceID;
        dvc.source = 1;
        dvc.reloadDataHandle = ^{
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

- (void)reSettingSwitch:(SceneMemberExpandModel *)member {
    [self showLoading];
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    if ([member.stateDic count] > 0) {
        NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
        [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1 intValue] < [obj2 integerValue]) {
                return NSOrderedAscending;
            }else {
                return NSOrderedDescending;
            }
        }];
        for (NSNumber *channel in keys) {
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel isEqualToNumber:channel]) {
                    NSInteger c = [channel integerValue];
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    NSInteger eve = [ary[0] integerValue];
                    if (eve == 17) {
                        if (c == 1) {
                            if (model.channel1PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                        sme.eveType = @(16);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }else if (c == 2) {
                            if (model.channel2PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 2) {
                                        sme.eveType = @(16);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }else if (c == 4) {
                            if (model.channel3PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 4) {
                                        sme.eveType = @(16);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }
                    }else if (eve == 16) {
                        if (c == 1) {
                            if (!model.channel1PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                        sme.eveType = @(17);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }else if (c == 2) {
                            if (!model.channel2PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 2) {
                                        sme.eveType = @(17);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }else if (c == 4) {
                            if (!model.channel3PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 4) {
                                        sme.eveType = @(17);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    break;
                }
            }
        }
    }
    [self nextOperation];
}

- (void)reSettingDimmer:(SceneMemberExpandModel *)member {
    [self showLoading];
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    if ([member.stateDic count] > 0) {
        NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
        [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1 intValue] < [obj2 integerValue]) {
                return NSOrderedAscending;
            }else {
                return NSOrderedDescending;
            }
        }];
        for (NSNumber *channel in keys) {
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel isEqualToNumber:channel]) {
                    NSInteger c = [channel integerValue];
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    NSInteger eve = [ary[0] integerValue];
                    if (eve == 17) {
                        if (c == 1) {
                            if (model.channel1PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                        sme.eveType = @(18);
                                        sme.eveD0 = @(model.channel1Level);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }else if (c == 2) {
                            if (model.channel2PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 2) {
                                        sme.eveType = @(18);
                                        sme.eveD0 = @(model.channel2Level);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }else if (c == 4) {
                            if (model.channel3PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 4) {
                                        sme.eveType = @(18);
                                        sme.eveD0 = @(model.channel3Level);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }
                    }else if (eve == 18) {
                        if (c == 1) {
                            if (!model.channel1PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                        sme.eveType = @(17);
                                        sme.eveD0 = @(0);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }else if (model.channel1Level != [ary[1] integerValue]) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                        sme.eveD0 = @(model.channel1Level);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }else if (c == 2) {
                            if (!model.channel2PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 2) {
                                        sme.eveType = @(17);
                                        sme.eveD0 = @(0);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }else if (model.channel2Level != [ary[1] integerValue]) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 2) {
                                        sme.eveD0 = @(model.channel2Level);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }else if (c == 4) {
                            if (!model.channel3PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 4) {
                                        sme.eveType = @(17);
                                        sme.eveD0 = @(0);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }else if (model.channel3Level != [ary[1] integerValue]) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 4) {
                                        sme.eveD0 = @(model.channel3Level);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    [self nextOperation];
}

- (void)reSettingCW:(SceneMemberExpandModel *)member {
    [self showLoading];
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    if ([member.stateDic count] > 0) {
        NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
        [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1 intValue] < [obj2 integerValue]) {
                return NSOrderedAscending;
            }else {
                return NSOrderedDescending;
            }
        }];
        for (NSNumber *channel in keys) {
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel isEqualToNumber:channel]) {
                    NSInteger c = [channel integerValue];
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    NSInteger eve = [ary[0] integerValue];
                    if (eve == 17) {
                        if (c == 1) {
                            if (model.channel1PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                        sme.eveType = @(25);
                                        sme.eveD0 = @(model.channel1Level);
                                        NSInteger c = [model.colorTemperature integerValue];
                                        sme.eveD2 = @((c & 0xFF00) >> 8);
                                        sme.eveD1 = @(c & 0x00FF);
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }
                    }else if (eve == 25) {
                        if (c == 1) {
                            if (!model.channel1PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                        sme.eveType = @(17);
                                        sme.eveD0 = @0;
                                        sme.eveD1 = @0;
                                        sme.eveD2 = @0;
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }else {
                                NSInteger c = [model.colorTemperature integerValue];
                                NSInteger l = (c & 0xFF00) >> 8;
                                NSInteger h = c & 0x00FF;
                                if ([ary[1] integerValue] != model.channel1Level || [ary[3] integerValue] != l || [ary[2] integerValue] != h) {
                                    for (SceneMemberEntity *sme in sceneEntity.members) {
                                        if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                            sme.eveD0 = @(model.channel1Level);
                                            sme.eveD2 = @(l);
                                            sme.eveD1 = @(h);
                                            [self.selects addObject:sme];
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    [self nextOperation];
}

- (void)reSettingRGB:(SceneMemberExpandModel *)member {
    [self showLoading];
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    if ([member.stateDic count] > 0) {
        NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
        [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1 intValue] < [obj2 integerValue]) {
                return NSOrderedAscending;
            }else {
                return NSOrderedDescending;
            }
        }];
        for (NSNumber *channel in keys) {
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel isEqualToNumber:channel]) {
                    NSInteger c = [channel integerValue];
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    NSInteger eve = [ary[0] integerValue];
                    if (eve == 17) {
                        if (c == 1) {
                            if (model.channel1PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                        sme.eveType = @(20);
                                        sme.eveD0 = @(model.channel1Level);
                                        sme.eveD1 = model.red;
                                        sme.eveD2 = model.green;
                                        sme.eveD3 = model.blue;
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }
                    }else if (eve == 20) {
                        if (!model.channel1PowerState) {
                            for (SceneMemberEntity *sme in sceneEntity.members) {
                                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                    sme.eveType = @(17);
                                    sme.eveD0 = @0;
                                    sme.eveD1 = @0;
                                    sme.eveD2 = @0;
                                    sme.eveD3 = @0;
                                    [self.selects addObject:sme];
                                    break;
                                }
                            }
                        }else {
                            if ([ary[1] integerValue] != model.channel1Level || [ary[2] integerValue] != [model.red integerValue] || [ary[3] integerValue] != [model.green integerValue] || [ary[4] integerValue] != [model.green integerValue]) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                        sme.eveD0 = @(model.channel1Level);
                                        sme.eveD1 = model.red;
                                        sme.eveD2 = model.green;
                                        sme.eveD3 = model.blue;
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    [self nextOperation];
}

- (void)reSettingRGBCW:(SceneMemberExpandModel *)member {
    [self showLoading];
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    if ([member.stateDic count] > 0) {
        NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
        [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1 intValue] < [obj2 integerValue]) {
                return NSOrderedAscending;
            }else {
                return NSOrderedDescending;
            }
        }];
        for (NSNumber *channel in keys) {
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel isEqualToNumber:channel]) {
                    NSInteger c = [channel integerValue];
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    NSInteger eve = [ary[0] integerValue];
                    if (eve == 17) {
                        if (c == 1) {
                            if (model.channel1PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                        if ([model.supports integerValue] == 0) {
                                            sme.eveType = @(20);
                                            sme.eveD0 = @(model.channel1Level);
                                            sme.eveD1 = model.red;
                                            sme.eveD2 = model.green;
                                            sme.eveD3 = model.blue;
                                        }else if ([model.supports integerValue] == 1) {
                                            sme.eveType = @(25);
                                            sme.eveD0 = @(model.channel1Level);
                                            NSInteger c = [model.colorTemperature integerValue];
                                            sme.eveD2 = @((c & 0xFF00) >> 8);
                                            sme.eveD1 = @(c & 0x00FF);
                                        }
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }
                        }
                    }else if (eve == 20 || eve == 25) {
                        if (c == 1) {
                            if (!model.channel1PowerState) {
                                for (SceneMemberEntity *sme in sceneEntity.members) {
                                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                        sme.eveType = @(17);
                                        sme.eveD0 = @0;
                                        sme.eveD1 = @0;
                                        sme.eveD2 = @0;
                                        sme.eveD3 = @0;
                                        [self.selects addObject:sme];
                                        break;
                                    }
                                }
                            }else {
                                if (eve == 20) {
                                    if ([model.supports integerValue] == 1) {
                                        for (SceneMemberEntity *sme in sceneEntity.members) {
                                            if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                                sme.eveType = @(25);
                                                sme.eveD0 = @(model.channel1Level);
                                                NSInteger c = [model.colorTemperature integerValue];
                                                sme.eveD2 = @((c & 0xFF00) >> 8);
                                                sme.eveD1 = @(c & 0x00FF);
                                                [self.selects addObject:sme];
                                                break;
                                            }
                                        }
                                    }else if ([model.supports integerValue] == 0) {
                                        if ([ary[1] integerValue] != model.channel1Level || [ary[2] integerValue] != [model.red integerValue] || [ary[3] integerValue] != [model.green integerValue] || [ary[4] integerValue] != [model.green integerValue]) {
                                            for (SceneMemberEntity *sme in sceneEntity.members) {
                                                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                                    sme.eveD0 = @(model.channel1Level);
                                                    sme.eveD1 = model.red;
                                                    sme.eveD2 = model.green;
                                                    sme.eveD3 = model.blue;
                                                    [self.selects addObject:sme];
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }else if (eve == 25) {
                                    if ([model.supports integerValue] == 0) {
                                        for (SceneMemberEntity *sme in sceneEntity.members) {
                                            if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                                sme.eveType = @(20);
                                                sme.eveD0 = @(model.channel1Level);
                                                sme.eveD1 = model.red;
                                                sme.eveD2 = model.green;
                                                sme.eveD3 = model.blue;
                                                [self.selects addObject:sme];
                                                break;
                                            }
                                        }
                                    }else if ([model.supports integerValue] == 1) {
                                        NSInteger c = [model.colorTemperature integerValue];
                                        NSInteger l = (c & 0xFF00) >> 8;
                                        NSInteger h = c & 0x00FF;
                                        if ([ary[1] integerValue] != model.channel1Level || [ary[3] integerValue] != l || [ary[2] integerValue] != h) {
                                            for (SceneMemberEntity *sme in sceneEntity.members) {
                                                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                                    sme.eveD0 = @(model.channel1Level);
                                                    sme.eveD2 = @(l);
                                                    sme.eveD1 = @(h);
                                                    [self.selects addObject:sme];
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    [self nextOperation];
}

- (void)reSettingFan:(SceneMemberExpandModel *)member {
    [self showLoading];
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    if ([member.stateDic count] > 0) {
        NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
        [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1 intValue] < [obj2 integerValue]) {
                return NSOrderedAscending;
            }else {
                return NSOrderedDescending;
            }
        }];
        for (NSNumber *channel in keys) {
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel isEqualToNumber:channel]) {
                    NSInteger c = [channel integerValue];
                    NSArray *ary = [member.stateDic objectForKey:channel];
                    if (c == 1) {
                        if ([ary[1] integerValue] != model.fanState || [ary[2] integerValue] != model.fansSpeed || [ary[3] integerValue] != model.lampState) {
                            for (SceneMemberEntity *sme in sceneEntity.members) {
                                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                                    sme.eveD0 = @(model.fanState);
                                    sme.eveD1 = @(model.fansSpeed);
                                    sme.eveD2 = @(model.lampState);
                                    [self.selects addObject:sme];
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    [self nextOperation];
}

- (void)reSettingThermoregulator:(SceneMemberExpandModel *)member {
    [self showLoading];
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    if ([member.stateDic count] > 0) {
        NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[member.stateDic allKeys]];
        [keys sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1 intValue] < [obj2 integerValue]) {
                return NSOrderedAscending;
            }else {
                return NSOrderedDescending;
            }
        }];
        for (NSNumber *channel in keys) {
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel isEqualToNumber:channel]) {
                    NSInteger c = [channel integerValue];
                    for (int i=0; i<64; i++) {
                        int b = (c & (int)pow(2, i)) >> i;
                        if (b == 1) {
                            if ([model.stateDic count] > 0) {
                                NSArray *ary = [model.stateDic objectForKey:@(i+1)];
                                if ([ary count] == 5) {
                                    uint8_t d1 = [ary[0] boolValue] + ([ary[3] integerValue] << 1) + ([ary[4] integerValue] << 4);
                                    uint8_t d2 = [ary[1] integerValue];
                                    uint8_t d3 = [ary[2] intValue]+16;
                                    if (d1 != [sme.eveD0 intValue] || d2 != [sme.eveD1 intValue] || d3 != [sme.eveD2 intValue]) {
                                        sme.eveD0 = @(d1);
                                        sme.eveD1 = @(d2);
                                        sme.eveD2 = @(d3);
                                        [self.selects addObject:sme];
                                    }
                                }
                            }
                            break;
                        }
                    }
                    break;
                }
            }
        }
        [self nextOperation];
    }
}

@end
