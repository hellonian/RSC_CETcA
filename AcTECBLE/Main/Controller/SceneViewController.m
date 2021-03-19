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
        [_members addObject:model];
    }
    if ([memberEntity.channel integerValue] == 1) {
        model.eve1Type = [memberEntity.eveType integerValue];
        model.eve1D0 = [memberEntity.eveD0 integerValue];
        model.eve1D1 = [memberEntity.eveD1 integerValue];
        model.eve1D2 = [memberEntity.eveD2 integerValue];
        model.eve1D3 = [memberEntity.eveD3 integerValue];
    }else if ([memberEntity.channel integerValue] == 2) {
        model.eve2Type = [memberEntity.eveType integerValue];
        model.eve2D0 = [memberEntity.eveD0 integerValue];
        model.eve2D1 = [memberEntity.eveD1 integerValue];
        model.eve2D2 = [memberEntity.eveD2 integerValue];
        model.eve2D3 = [memberEntity.eveD3 integerValue];
    }else if ([memberEntity.channel integerValue] == 4) {
        model.eve3Type = [memberEntity.eveType integerValue];
        model.eve3D0 = [memberEntity.eveD0 integerValue];
        model.eve3D1 = [memberEntity.eveD1 integerValue];
        model.eve3D2 = [memberEntity.eveD2 integerValue];
        model.eve3D3 = [memberEntity.eveD3 integerValue];
    }else if ([memberEntity.channel integerValue] == 8) {
        model.eve4Type = [memberEntity.eveType integerValue];
        model.eve4D0 = [memberEntity.eveD0 integerValue];
        model.eve4D1 = [memberEntity.eveD1 integerValue];
        model.eve4D2 = [memberEntity.eveD2 integerValue];
        model.eve4D3 = [memberEntity.eveD3 integerValue];
    }else if ([memberEntity.channel integerValue] == 16) {
        model.eve5Type = [memberEntity.eveType integerValue];
        model.eve5D0 = [memberEntity.eveD0 integerValue];
        model.eve5D1 = [memberEntity.eveD1 integerValue];
        model.eve5D2 = [memberEntity.eveD2 integerValue];
        model.eve5D3 = [memberEntity.eveD3 integerValue];
    }else if ([memberEntity.channel integerValue] == 32) {
        model.eve6Type = [memberEntity.eveType integerValue];
        model.eve6D0 = [memberEntity.eveD0 integerValue];
        model.eve6D1 = [memberEntity.eveD1 integerValue];
        model.eve6D2 = [memberEntity.eveD2 integerValue];
        model.eve6D3 = [memberEntity.eveD3 integerValue];
    }else if ([memberEntity.channel integerValue] == 64) {
        model.eve7Type = [memberEntity.eveType integerValue];
        model.eve7D0 = [memberEntity.eveD0 integerValue];
        model.eve7D1 = [memberEntity.eveD1 integerValue];
        model.eve7D2 = [memberEntity.eveD2 integerValue];
        model.eve7D3 = [memberEntity.eveD3 integerValue];
    }else if ([memberEntity.channel integerValue] == 128) {
        model.eve8Type = [memberEntity.eveType integerValue];
        model.eve8D0 = [memberEntity.eveD0 integerValue];
        model.eve8D1 = [memberEntity.eveD1 integerValue];
        model.eve8D2 = [memberEntity.eveD2 integerValue];
        model.eve8D3 = [memberEntity.eveD3 integerValue];
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
        || [CSRUtilities belongToSocketOneChannel:member.kindString]) {
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
        if (member.eve1Type == 16) {
            cell.detailTextLabel.text = @"ON";
        }else {
            cell.detailTextLabel.text = @"OFF";
        }
    }else if ([CSRUtilities belongToTwoChannelSwitch:member.kindString]
              || [CSRUtilities belongToThreeChannelSwitch:member.kindString]
              || [CSRUtilities belongToSocketTwoChannel:member.kindString]) {
        if ([CSRUtilities belongToTSeriesPanel:member.kindString]) {
            cell.imageView.image = [UIImage imageNamed:@"icon_T_panel"];
        }else if ([CSRUtilities belongToPSeriesPanel:member.kindString]) {
            cell.imageView.image = [UIImage imageNamed:@"icon_P_panel"];
        }else if ([CSRUtilities belongToSocketTwoChannel:member.kindString]) {
            cell.imageView.image = [UIImage imageNamed:@"icon_socket"];
        }else {
            cell.imageView.image = [UIImage imageNamed:@"icon_switch1"];
        }
        NSString *detailText = @"";
        if (member.eve1Type) {
            if (member.eve1Type == 16) {
                detailText = @"ON";
            }else {
                detailText = @"OFF";
            }
        }
        if (member.eve2Type) {
            if (member.eve2Type == 16) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | ON",detailText] : @"ON";
            }else {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | OFF",detailText] : @"OFF";
            }
        }
        if (member.eve3Type) {
            if (member.eve3Type == 16) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | ON",detailText] : @"ON";
            }else {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | OFF",detailText] : @"OFF";
            }
        }
        cell.detailTextLabel.text = detailText;
    }else if ([CSRUtilities belongToDimmer:member.kindString]) {
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
        }else {
            cell.imageView.image = [UIImage imageNamed:@"icon_dimmer1"];
        }
        if (member.eve1Type == 17) {
            cell.detailTextLabel.text = @"OFF";
        }else if (member.eve1Type == 18) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.f%%",member.eve1D0/255.0*100];
        }
    }else if ([CSRUtilities belongToTwoChannelDimmer:member.kindString]
              || [CSRUtilities belongToThreeChannelDimmer:member.kindString]) {
        if ([CSRUtilities belongToTSeriesPanel:member.kindString]) {
            cell.imageView.image = [UIImage imageNamed:@"icon_T_panel"];
        }else if ([CSRUtilities belongToPSeriesPanel:member.kindString]) {
            cell.imageView.image = [UIImage imageNamed:@"icon_P_panel"];
        }else {
            cell.imageView.image = [UIImage imageNamed:@"icon_dimmer1"];
        }
        NSString *detailText = @"";
        if (member.eve1Type) {
            if (member.eve1Type == 17) {
                detailText = @"OFF";
            }else if (member.eve1Type == 18) {
                detailText = [NSString stringWithFormat:@"%.f%%",member.eve1D0/255.0*100];
            }
        }
        if (member.eve2Type) {
            if (member.eve2Type == 17) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | OFF", detailText] : @"OFF";
            }else if (member.eve2Type == 18) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %.f%%", detailText, member.eve2D0/255.0*100] : [NSString stringWithFormat:@"%.f%%", member.eve2D0/255.0*100];
            }
        }
        if (member.eve3Type) {
            if (member.eve3Type == 17) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | OFF", detailText] : @"OFF";
            }else if (member.eve3Type == 18) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %.f%%", detailText, member.eve3D0/255.0*100] : [NSString stringWithFormat:@"%.f%%", member.eve3D0/255.0*100];
            }
        }
        cell.detailTextLabel.text = detailText;
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
        if (member.eve1Type == 17) {
            cell.detailTextLabel.text = @"OFF";
        }else if (member.eve1Type == 25) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ldK %.f%%", member.eve1D2*256+member.eve1D1, member.eve1D0/255.0*100];
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
        
        if (member.eve1Type == 17) {
            cell.detailTextLabel.text = @"OFF";
        }else if (member.eve1Type == 20) {
            NSMutableAttributedString *detailText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"● %.f%%", member.eve1D0/255.0*100]];
            [detailText addAttribute:NSForegroundColorAttributeName value:ColorWithAlpha(member.eve1D1, member.eve1D2, member.eve1D3, 1) range:NSMakeRange(0, 1)];
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
        if (member.eve1Type == 17) {
            cell.detailTextLabel.text = @"OFF";
        }else if (member.eve1Type == 25) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ldK %.f%%", member.eve1D2*256+member.eve1D1, member.eve1D0/255.0*100];
        }else if (member.eve1Type == 20) {
            NSMutableAttributedString *detailText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"● %.f%%", member.eve1D0/255.0*100]];
            [detailText addAttribute:NSForegroundColorAttributeName value:ColorWithAlpha(member.eve1D1, member.eve1D2, member.eve1D3, 1) range:NSMakeRange(0, 1)];
            cell.detailTextLabel.attributedText = detailText;
        }
    }else if ([CSRUtilities belongToOneChannelCurtainController:member.kindString]
              || [CSRUtilities belongToHOneChannelCurtainController:member.kindString]) {
        cell.imageView.image = [UIImage imageNamed:@"icon_curtain"];
        if (member.eve1Type == 17) {
            cell.detailTextLabel.text = @"OFF";
        }else if (member.eve1Type == 18) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.f%%",member.eve1D0/255.0*100];
        }
    }else if ([CSRUtilities belongToTwoChannelCurtainController:member.kindString]) {
        cell.imageView.image = [UIImage imageNamed:@"icon_curtain"];
        NSString *detailText = @"";
        if (member.eve1Type) {
            if (member.eve1Type == 17) {
                detailText = @"OFF";
            }else if (member.eve1Type == 18) {
                detailText = [NSString stringWithFormat:@"%.f %%",member.eve1D0/255.0*100];
            }
        }
        if (member.eve2Type) {
            if (member.eve2Type == 17) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | OFF", detailText] : @"OFF";
            }else if (member.eve2Type == 18) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %.f%%", detailText, member.eve2D0/255.0*100] : [NSString stringWithFormat:@"%.f%%", member.eve2D0/255.0*100];
            }
        }
        cell.detailTextLabel.text = detailText;
    }else if ([CSRUtilities belongToFanController:member.kindString]) {
        cell.imageView.image = [UIImage imageNamed:@"icon_fan"];
        NSString *detailText = @"";
        if (member.eve1D0) {
            if (member.eve1D1 == 0) {
                detailText = AcTECLocalizedStringFromTable(@"low", @"Localizable");
            }else if (member.eve1D1 == 1) {
                detailText = AcTECLocalizedStringFromTable(@"medium", @"Localizable");
            }else if (member.eve1D1 == 2) {
                detailText = AcTECLocalizedStringFromTable(@"high", @"Localizable");
            }
        }else {
            detailText = @"OFF";
        }
        if (member.eve1D2) {
            detailText = [NSString stringWithFormat:@"%@, %@",detailText, AcTECLocalizedStringFromTable(@"light_on", @"Localizable")];
        }else {
            detailText = [NSString stringWithFormat:@"%@, %@",detailText, AcTECLocalizedStringFromTable(@"light_off", @"Localizable")];
        }
        cell.detailTextLabel.text = detailText;
    }else if ([CSRUtilities belongToSonosMusicController:member.kindString]) {
        cell.imageView.image = [UIImage imageNamed:@"icon_sonos"];
        NSString *detailText = @"";
        if (member.eve1Type) {
            if (member.eve1Type == 130) {
                detailText = @"STOP";
            }else if (member.eve1Type == 226) {
                NSString *song= @"";
                if ([deviceEntity.remoteBranch length]>0) {
                    NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:deviceEntity.remoteBranch];
                    if ([jsonDictionary count]>0) {
                        NSArray *songs = jsonDictionary[@"song"];
                        for (NSDictionary *dic in songs) {
                            NSInteger n = [dic[@"id"] integerValue];
                            if (n == member.eve1D2) {
                                song = dic[@"name"];
                                break;
                            }
                        }
                    }
                }
                detailText = [NSString stringWithFormat:@"%@, %ld%%", song, (member.eve1D1 & 0xfe)>>1];
            }
        }
        if (member.eve2Type) {
            if (member.eve2Type == 130) {
                detailText = [NSString stringWithFormat:@"%@ | STOP",detailText];
            }else if (member.eve2Type == 226) {
                NSString *song= @"";
                if ([deviceEntity.remoteBranch length]>0) {
                    NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:deviceEntity.remoteBranch];
                    if ([jsonDictionary count]>0) {
                        NSArray *songs = jsonDictionary[@"song"];
                        for (NSDictionary *dic in songs) {
                            NSInteger n = [dic[@"id"] integerValue];
                            if (n == member.eve2D2) {
                                song = dic[@"name"];
                                break;
                            }
                        }
                    }
                }
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@, %ld%%", detailText, song, (member.eve2D1 & 0xfe)>>1] : [NSString stringWithFormat:@"%@, %ld%%", song, (member.eve2D1 & 0xfe)>>1];
            }
        }
        if (member.eve3Type) {
            if (member.eve3Type == 130) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | STOP",detailText] : @"STOP";
            }else if (member.eve3Type == 226) {
                NSString *song= @"";
                if ([deviceEntity.remoteBranch length]>0) {
                    NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:deviceEntity.remoteBranch];
                    if ([jsonDictionary count]>0) {
                        NSArray *songs = jsonDictionary[@"song"];
                        for (NSDictionary *dic in songs) {
                            NSInteger n = [dic[@"id"] integerValue];
                            if (n == member.eve3D2) {
                                song = dic[@"name"];
                                break;
                            }
                        }
                    }
                }
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@, %ld%%", detailText, song, (member.eve3D1 & 0xfe)>>1] : [NSString stringWithFormat:@"%@, %ld%%", song, (member.eve3D1 & 0xfe)>>1];
            }
        }
        if (member.eve4Type) {
            if (member.eve4Type == 130) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | STOP",detailText] : @"STOP";
            }else if (member.eve4Type == 226) {
                NSString *song= @"";
                if ([deviceEntity.remoteBranch length]>0) {
                    NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:deviceEntity.remoteBranch];
                    if ([jsonDictionary count]>0) {
                        NSArray *songs = jsonDictionary[@"song"];
                        for (NSDictionary *dic in songs) {
                            NSInteger n = [dic[@"id"] integerValue];
                            if (n == member.eve4D2) {
                                song = dic[@"name"];
                                break;
                            }
                        }
                    }
                }
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@, %ld%%", detailText, song, (member.eve4D1 & 0xfe)>>1] : [NSString stringWithFormat:@"%@, %ld%%", song, (member.eve4D1 & 0xfe)>>1];
            }
        }
        if (member.eve5Type) {
            if (member.eve5Type == 130) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | STOP",detailText] : @"STOP";
            }else if (member.eve5Type == 226) {
                NSString *song= @"";
                if ([deviceEntity.remoteBranch length]>0) {
                    NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:deviceEntity.remoteBranch];
                    if ([jsonDictionary count]>0) {
                        NSArray *songs = jsonDictionary[@"song"];
                        for (NSDictionary *dic in songs) {
                            NSInteger n = [dic[@"id"] integerValue];
                            if (n == member.eve5D2) {
                                song = dic[@"name"];
                                break;
                            }
                        }
                    }
                }
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@, %ld%%", detailText, song, (member.eve5D1 & 0xfe)>>1] : [NSString stringWithFormat:@"%@, %ld%%", song, (member.eve5D1 & 0xfe)>>1];
            }
        }
        if (member.eve6Type) {
            if (member.eve6Type == 130) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | STOP",detailText] : @"STOP";
            }else if (member.eve6Type == 226) {
                NSString *song= @"";
                if ([deviceEntity.remoteBranch length]>0) {
                    NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:deviceEntity.remoteBranch];
                    if ([jsonDictionary count]>0) {
                        NSArray *songs = jsonDictionary[@"song"];
                        for (NSDictionary *dic in songs) {
                            NSInteger n = [dic[@"id"] integerValue];
                            if (n == member.eve6D2) {
                                song = dic[@"name"];
                                break;
                            }
                        }
                    }
                }
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@, %ld%%", detailText, song, (member.eve6D1 & 0xfe)>>1] : [NSString stringWithFormat:@"%@, %ld%%", song, (member.eve6D1 & 0xfe)>>1];
            }
        }
        if (member.eve7Type) {
            if (member.eve7Type == 130) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | STOP",detailText] : @"STOP";
            }else if (member.eve7Type == 226) {
                NSString *song= @"";
                if ([deviceEntity.remoteBranch length]>0) {
                    NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:deviceEntity.remoteBranch];
                    if ([jsonDictionary count]>0) {
                        NSArray *songs = jsonDictionary[@"song"];
                        for (NSDictionary *dic in songs) {
                            NSInteger n = [dic[@"id"] integerValue];
                            if (n == member.eve7D2) {
                                song = dic[@"name"];
                                break;
                            }
                        }
                    }
                }
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@, %ld%%", detailText, song, (member.eve7D1 & 0xfe)>>1] : [NSString stringWithFormat:@"%@, %ld%%", song, (member.eve7D1 & 0xfe)>>1];
            }
        }
        if (member.eve8Type) {
            if (member.eve8Type == 130) {
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | STOP",detailText] : @"STOP";
            }else if (member.eve8Type == 226) {
                NSString *song= @"";
                if ([deviceEntity.remoteBranch length]>0) {
                    NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:deviceEntity.remoteBranch];
                    if ([jsonDictionary count]>0) {
                        NSArray *songs = jsonDictionary[@"song"];
                        for (NSDictionary *dic in songs) {
                            NSInteger n = [dic[@"id"] integerValue];
                            if (n == member.eve8D2) {
                                song = dic[@"name"];
                                break;
                            }
                        }
                    }
                }
                detailText = [detailText length] > 0 ? [NSString stringWithFormat:@"%@ | %@, %ld%%", detailText, song, (member.eve8D1 & 0xfe)>>1] : [NSString stringWithFormat:@"%@, %ld%%", song, (member.eve8D1 & 0xfe)>>1];
            }
        }
        cell.detailTextLabel.text = detailText;
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
            for (id d in devices) {
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
    
    if (member.eve1Type) {
        NSString *title = AcTECLocalizedStringFromTable(@"Yes", @"Localizable");
        if ([CSRUtilities belongToTwoChannelSwitch:member.kindString]
            || [CSRUtilities belongToThreeChannelSwitch:member.kindString]
            || [CSRUtilities belongToTwoChannelDimmer:member.kindString]
            || [CSRUtilities belongToSocketTwoChannel:member.kindString]
            || [CSRUtilities belongToTwoChannelCurtainController:member.kindString]
            || [CSRUtilities belongToThreeChannelDimmer:member.kindString]
            || [CSRUtilities belongToMusicController:member.kindString]
            || [CSRUtilities belongToSonosMusicController:member.kindString]) {
            title = @"1";
        }
        UIAlertAction *eve1 = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showLoading];
            [self performSelector:@selector(removeSceneIDTimerOut) withObject:nil afterDelay:10.0];
            _mDeviceToApplay = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
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
                Byte byte[] = {0x5d, 0x03, 0x01, b[1], b[0]};
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
        [alert addAction:eve1];
    }
    if (member.eve2Type) {
        UIAlertAction *eve2 = [UIAlertAction actionWithTitle:@"2" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showLoading];
            [self performSelector:@selector(removeSceneIDTimerOut) withObject:nil afterDelay:10.0];
            _mDeviceToApplay = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 2) {
                    _mMemberToApply = sme;
                    break;
                }
            }
            NSInteger s = [_sceneIndex integerValue];
            Byte b[] = {};
            b[0] = (Byte)((s & 0xFF00)>>8);
            b[1] = (Byte)(s & 0x00FF);
            Byte byte[] = {0x5d, 0x03, 0x02, b[1], b[0]};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
            retryCount = 0;
            retryCmd = cmd;
            retryDeviceId = member.deviceID;
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:member.deviceID data:cmd];
        }];
        [alert addAction:eve2];
    }
    if (member.eve3Type) {
        UIAlertAction *eve3 = [UIAlertAction actionWithTitle:@"3" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showLoading];
            [self performSelector:@selector(removeSceneIDTimerOut) withObject:nil afterDelay:10.0];
            _mDeviceToApplay = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 4) {
                    _mMemberToApply = sme;
                    break;
                }
            }
            NSInteger s = [_sceneIndex integerValue];
            Byte b[] = {};
            b[0] = (Byte)((s & 0xFF00)>>8);
            b[1] = (Byte)(s & 0x00FF);
            Byte byte[] = {0x5d, 0x03, 0x04, b[1], b[0]};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
            retryCount = 0;
            retryCmd = cmd;
            retryDeviceId = member.deviceID;
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:member.deviceID data:cmd];
        }];
        [alert addAction:eve3];
    }
    if (member.eve4Type) {
        UIAlertAction *eve4 = [UIAlertAction actionWithTitle:@"4" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showLoading];
            [self performSelector:@selector(removeSceneIDTimerOut) withObject:nil afterDelay:10.0];
            _mDeviceToApplay = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 8) {
                    _mMemberToApply = sme;
                    break;
                }
            }
            NSInteger s = [_sceneIndex integerValue];
            Byte b[] = {};
            b[0] = (Byte)((s & 0xFF00)>>8);
            b[1] = (Byte)(s & 0x00FF);
            Byte byte[] = {0x5d, 0x03, 0x08, b[1], b[0]};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
            retryCount = 0;
            retryCmd = cmd;
            retryDeviceId = member.deviceID;
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:member.deviceID data:cmd];
        }];
        [alert addAction:eve4];
    }
    if (member.eve5Type) {
        UIAlertAction *eve5 = [UIAlertAction actionWithTitle:@"5" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showLoading];
            [self performSelector:@selector(removeSceneIDTimerOut) withObject:nil afterDelay:10.0];
            _mDeviceToApplay = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 16) {
                    _mMemberToApply = sme;
                    break;
                }
            }
            NSInteger s = [_sceneIndex integerValue];
            Byte b[] = {};
            b[0] = (Byte)((s & 0xFF00)>>8);
            b[1] = (Byte)(s & 0x00FF);
            Byte byte[] = {0x5d, 0x03, 0x10, b[1], b[0]};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
            retryCount = 0;
            retryCmd = cmd;
            retryDeviceId = member.deviceID;
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:member.deviceID data:cmd];
        }];
        [alert addAction:eve5];
    }
    if (member.eve6Type) {
        UIAlertAction *eve6 = [UIAlertAction actionWithTitle:@"6" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showLoading];
            [self performSelector:@selector(removeSceneIDTimerOut) withObject:nil afterDelay:10.0];
            _mDeviceToApplay = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 32) {
                    _mMemberToApply = sme;
                    break;
                }
            }
            NSInteger s = [_sceneIndex integerValue];
            Byte b[] = {};
            b[0] = (Byte)((s & 0xFF00)>>8);
            b[1] = (Byte)(s & 0x00FF);
            Byte byte[] = {0x5d, 0x03, 0x20, b[1], b[0]};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
            retryCount = 0;
            retryCmd = cmd;
            retryDeviceId = member.deviceID;
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:member.deviceID data:cmd];
        }];
        [alert addAction:eve6];
    }
    if (member.eve7Type) {
        UIAlertAction *eve7 = [UIAlertAction actionWithTitle:@"7" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showLoading];
            [self performSelector:@selector(removeSceneIDTimerOut) withObject:nil afterDelay:10.0];
            _mDeviceToApplay = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 64) {
                    _mMemberToApply = sme;
                    break;
                }
            }
            NSInteger s = [_sceneIndex integerValue];
            Byte b[] = {};
            b[0] = (Byte)((s & 0xFF00)>>8);
            b[1] = (Byte)(s & 0x00FF);
            Byte byte[] = {0x5d, 0x03, 0x40, b[1], b[0]};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
            retryCount = 0;
            retryCmd = cmd;
            retryDeviceId = member.deviceID;
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:member.deviceID data:cmd];
        }];
        [alert addAction:eve7];
    }
    if (member.eve8Type) {
        UIAlertAction *eve8 = [UIAlertAction actionWithTitle:@"8" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showLoading];
            [self performSelector:@selector(removeSceneIDTimerOut) withObject:nil afterDelay:10.0];
            _mDeviceToApplay = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
            SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
            for (SceneMemberEntity *sme in sceneEntity.members) {
                if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 128) {
                    _mMemberToApply = sme;
                    break;
                }
            }
            NSInteger s = [_sceneIndex integerValue];
            Byte b[] = {};
            b[0] = (Byte)((s & 0xFF00)>>8);
            b[1] = (Byte)(s & 0x00FF);
            Byte byte[] = {0x5d, 0x03, 0x80, b[1], b[0]};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
            retryCount = 0;
            retryCmd = cmd;
            retryDeviceId = member.deviceID;
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:member.deviceID data:cmd];
        }];
        [alert addAction:eve8];
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
            if ([memberEntity.channel integerValue] == 1) {
                eModel.eve1Type = 0;
                eModel.eve1D0 = 0;
                eModel.eve1D1 = 0;
                eModel.eve1D2 = 0;
                eModel.eve1D3 = 0;
            }else if ([memberEntity.channel integerValue] == 2) {
                eModel.eve2Type = 0;
                eModel.eve2D0 = 0;
                eModel.eve2D1 = 0;
                eModel.eve2D2 = 0;
                eModel.eve2D3 = 0;
            }else if ([memberEntity.channel integerValue] == 4) {
                eModel.eve3Type = 0;
                eModel.eve3D0 = 0;
                eModel.eve3D1 = 0;
                eModel.eve3D2 = 0;
                eModel.eve3D3 = 0;
            }else if ([memberEntity.channel integerValue] == 8) {
                eModel.eve4Type = 0;
                eModel.eve4D0 = 0;
                eModel.eve4D1 = 0;
                eModel.eve4D2 = 0;
                eModel.eve4D3 = 0;
            }else if ([memberEntity.channel integerValue] == 16) {
                eModel.eve5Type = 0;
                eModel.eve5D0 = 0;
                eModel.eve5D1 = 0;
                eModel.eve5D2 = 0;
                eModel.eve5D3 = 0;
            }else if ([memberEntity.channel integerValue] == 32) {
                eModel.eve6Type = 0;
                eModel.eve6D0 = 0;
                eModel.eve6D1 = 0;
                eModel.eve6D2 = 0;
                eModel.eve6D3 = 0;
            }else if ([memberEntity.channel integerValue] == 64) {
                eModel.eve7Type = 0;
                eModel.eve7D0 = 0;
                eModel.eve7D1 = 0;
                eModel.eve7D2 = 0;
                eModel.eve7D3 = 0;
            }else if ([memberEntity.channel integerValue] == 128) {
                eModel.eve8Type = 0;
                eModel.eve8D0 = 0;
                eModel.eve8D1 = 0;
                eModel.eve8D2 = 0;
                eModel.eve8D3 = 0;
            }
            if (!eModel.eve1Type && !eModel.eve2Type && !eModel.eve3Type && !eModel.eve4Type && !eModel.eve5Type && !eModel.eve6Type && !eModel.eve7Type && !eModel.eve8Type) {
                [_members removeObject:eModel];
            }
            break;
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
        if (member.eve1Type) {
            SonosSelectModel *model = [[SonosSelectModel alloc] init];
            model.reSetting = YES;
            model.selected = YES;
            model.deviceID = member.deviceID;
            model.channel = @(0);
            model.play = member.eve1Type == 226 ? YES : NO;
            model.voice = member.eve1D1/2;
            model.songNumber = member.eve1D2;
            [smodels addObject:model];
        }
        if (member.eve2Type) {
            SonosSelectModel *model = [[SonosSelectModel alloc] init];
            model.reSetting = YES;
            model.selected = YES;
            model.deviceID = member.deviceID;
            model.channel = @(1);
            model.play = member.eve2Type == 226 ? YES : NO;
            model.voice = member.eve2D1/2;
            model.songNumber = member.eve2D2;
            [smodels addObject:model];
        }
        if (member.eve3Type) {
            SonosSelectModel *model = [[SonosSelectModel alloc] init];
            model.reSetting = YES;
            model.selected = YES;
            model.deviceID = member.deviceID;
            model.channel = @(2);
            model.play = member.eve3Type == 226 ? YES : NO;
            model.voice = member.eve3D1/2;
            model.songNumber = member.eve3D2;
            [smodels addObject:model];
        }
        if (member.eve4Type) {
            SonosSelectModel *model = [[SonosSelectModel alloc] init];
            model.reSetting = YES;
            model.selected = YES;
            model.deviceID = member.deviceID;
            model.channel = @(3);
            model.play = member.eve4Type == 226 ? YES : NO;
            model.voice = member.eve4D1/2;
            model.songNumber = member.eve4D2;
            [smodels addObject:model];
        }
        if (member.eve5Type) {
            SonosSelectModel *model = [[SonosSelectModel alloc] init];
            model.reSetting = YES;
            model.selected = YES;
            model.deviceID = member.deviceID;
            model.channel = @(4);
            model.play = member.eve5Type == 226 ? YES : NO;
            model.voice = member.eve5D1/2;
            model.songNumber = member.eve5D2;
            [smodels addObject:model];
        }
        if (member.eve6Type) {
            SonosSelectModel *model = [[SonosSelectModel alloc] init];
            model.reSetting = YES;
            model.selected = YES;
            model.deviceID = member.deviceID;
            model.channel = @(5);
            model.play = member.eve6Type == 226 ? YES : NO;
            model.voice = member.eve6D1/2;
            model.songNumber = member.eve6D2;
            [smodels addObject:model];
        }
        if (member.eve7Type) {
            SonosSelectModel *model = [[SonosSelectModel alloc] init];
            model.reSetting = YES;
            model.selected = YES;
            model.deviceID = member.deviceID;
            model.channel = @(6);
            model.play = member.eve7Type == 226 ? YES : NO;
            model.voice = member.eve7D1/2;
            model.songNumber = member.eve7D2;
            [smodels addObject:model];
        }
        if (member.eve8Type) {
            SonosSelectModel *model = [[SonosSelectModel alloc] init];
            model.reSetting = YES;
            model.selected = YES;
            model.deviceID = member.deviceID;
            model.channel = @(7);
            model.play = member.eve8Type == 226 ? YES : NO;
            model.voice = member.eve8D1/2;
            model.songNumber = member.eve8D2;
            [smodels addObject:model];
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
    if (member.eve1Type) {
        if (member.eve1Type == 17) {
            if (model.channel1PowerState) {
                for (SceneMemberEntity *sme in sceneEntity.members) {
                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                        sme.eveType = @(16);
                        [self.selects addObject:sme];
                        break;
                    }
                }
            }
        }else if (member.eve1Type == 16) {
            if (!model.channel1PowerState) {
                for (SceneMemberEntity *sme in sceneEntity.members) {
                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                        sme.eveType = @(17);
                        [self.selects addObject:sme];
                        break;
                    }
                }
            }
        }
    }
    if (member.eve2Type) {
        if (member.eve2Type == 17) {
            if (model.channel2PowerState) {
                for (SceneMemberEntity *sme in sceneEntity.members) {
                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 2) {
                        sme.eveType = @(16);
                        [self.selects addObject:sme];
                        break;
                    }
                }
            }
        }else if (member.eve2Type == 16) {
            if (!model.channel2PowerState) {
                for (SceneMemberEntity *sme in sceneEntity.members) {
                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 2) {
                        sme.eveType = @(17);
                        [self.selects addObject:sme];
                        break;
                    }
                }
            }
        }
    }
    if (member.eve3Type) {
        if (member.eve3Type == 17) {
            if (model.channel3PowerState) {
                for (SceneMemberEntity *sme in sceneEntity.members) {
                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 4) {
                        sme.eveType = @(16);
                        [self.selects addObject:sme];
                        break;
                    }
                }
            }
        }else if (member.eve3Type == 16) {
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
    [self nextOperation];
}

- (void)reSettingDimmer:(SceneMemberExpandModel *)member {
    [self showLoading];
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    if (member.eve1Type) {
        if (member.eve1Type == 17) {
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
        }else if (member.eve1Type == 18) {
            if (!model.channel1PowerState) {
                for (SceneMemberEntity *sme in sceneEntity.members) {
                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                        sme.eveType = @(17);
                        sme.eveD0 = @(0);
                        [self.selects addObject:sme];
                        break;
                    }
                }
            }else if (model.channel1Level != member.eve1D0) {
                for (SceneMemberEntity *sme in sceneEntity.members) {
                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 1) {
                        sme.eveD0 = @(model.channel1Level);
                        [self.selects addObject:sme];
                        break;
                    }
                }
            }
        }
    }
    if (member.eve2Type) {
        if (member.eve2Type == 17) {
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
        }else if (member.eve2Type == 18) {
            if (!model.channel2PowerState) {
                for (SceneMemberEntity *sme in sceneEntity.members) {
                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 2) {
                        sme.eveType = @(17);
                        sme.eveD0 = @(0);
                        [self.selects addObject:sme];
                        break;
                    }
                }
            }else if (model.channel2Level != member.eve2D0) {
                for (SceneMemberEntity *sme in sceneEntity.members) {
                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 2) {
                        sme.eveD0 = @(model.channel2Level);
                        [self.selects addObject:sme];
                        break;
                    }
                }
            }
        }
    }
    if (member.eve3Type) {
        if (member.eve3Type == 17) {
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
        }else if (member.eve3Type == 18) {
            if (!model.channel3PowerState) {
                for (SceneMemberEntity *sme in sceneEntity.members) {
                    if ([sme.deviceID isEqualToNumber:member.deviceID] && [sme.channel integerValue] == 4) {
                        sme.eveType = @(17);
                        sme.eveD0 = @(0);
                        [self.selects addObject:sme];
                        break;
                    }
                }
            }else if (model.channel3Level != member.eve3D0) {
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
    [self nextOperation];
}

- (void)reSettingCW:(SceneMemberExpandModel *)member {
    [self showLoading];
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    if (member.eve1Type == 17) {
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
    }else if (member.eve1Type == 25) {
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
            if (member.eve1D0 != model.channel1Level || member.eve1D2 != l || member.eve1D1 != h) {
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
    [self nextOperation];
}

- (void)reSettingRGB:(SceneMemberExpandModel *)member {
    [self showLoading];
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    if (member.eve1Type == 17) {
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
    }else if (member.eve1Type == 20) {
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
            if (member.eve1D0 != model.channel1Level || member.eve1D1 != [model.red integerValue] || member.eve1D2 != [model.green integerValue] || member.eve1D3 != [model.green integerValue]) {
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
    [self nextOperation];
}

- (void)reSettingRGBCW:(SceneMemberExpandModel *)member {
    [self showLoading];
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    if (member.eve1Type == 17) {
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
    }else if (member.eve1Type == 20 || member.eve1Type == 25) {
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
            if (member.eve1Type == 20) {
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
                    if (member.eve1D0 != model.channel1Level || member.eve1D1 != [model.red integerValue] || member.eve1D2 != [model.green integerValue] || member.eve1D3 != [model.green integerValue]) {
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
            }else if (member.eve1Type == 25) {
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
                    if (member.eve1D0 != model.channel1Level || member.eve1D2 != l || member.eve1D1 != h) {
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
    [self nextOperation];
}

- (void)reSettingFan:(SceneMemberExpandModel *)member {
    [self showLoading];
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:member.deviceID];
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:_sceneIndex];
    if (member.eve1D0 != model.fanState || member.eve1D1 != model.fansSpeed || member.eve1D2 != model.lampState) {
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
    [self nextOperation];
}

@end
