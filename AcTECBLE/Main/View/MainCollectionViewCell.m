//
//  MainCollectionViewCell.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "MainCollectionViewCell.h"
#import "CSRDeviceEntity.h"
#import "CSRAreaEntity.h"
#import "DeviceModelManager.h"
#import "CSRmeshDevice.h"
#import "CSRConstants.h"
#import "SingleDeviceModel.h"
#import "CSRUtilities.h"
#import <CSRmesh/LightModelApi.h>
#import "SceneListSModel.h"
#import "GroupListSModel.h"
#import "CSRDatabaseManager.h"
#import "SoundListenTool.h"

@interface MainCollectionViewCell ()<UIGestureRecognizerDelegate>
{
    CGFloat distanceX;
    CGFloat distanceY;
    BOOL tapLimite;
}

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *kindLabel;
@property (weak, nonatomic) IBOutlet UILabel *levelLabel;
@property (nonatomic,assign) PanGestureMoveDirection direction;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (weak, nonatomic) IBOutlet UIImageView *moveImageView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UILabel *level2Label;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *levelTextTopCon;
@property (weak, nonatomic) IBOutlet UILabel *level3Label;
@property (nonatomic, assign) BOOL adjustableBrightness;

@end

@implementation MainCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setPowerStateSuccess:) name:@"setPowerStateSuccess" object:nil];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mainCellTapGestureAction:)];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(mainCellPanGestureAction:)];
    panGesture.delegate = self;
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(mainCellLongPressGestureAction:)];
    UITapGestureRecognizer *twoFingersTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mainCellTwoFingersTapGestureAction:)];
    twoFingersTapGesture.numberOfTouchesRequired = 2;

    [self addGestureRecognizer:tapGesture];
    [self addGestureRecognizer:panGesture];
    [self addGestureRecognizer:longPressGesture];
    [self addGestureRecognizer:twoFingersTapGesture];
    
    UIPanGestureRecognizer *movePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(mainCellMovePanGestureAction:)];
    [self.moveImageView addGestureRecognizer:movePanGesture];
    
}

- (void)configureCellWithiInfo:(id)info withCellIndexPath:(NSIndexPath *)indexPath{
    self.hidden = NO;

    if ([info isKindOfClass:[CSRAreaEntity class]]) {
        CSRAreaEntity *areaEntity = (CSRAreaEntity *)info;
        self.groupId = areaEntity.areaID;
        self.deviceId = @2000;
        self.groupMembers = [areaEntity.devices allObjects];
        self.nameLabel.hidden = NO;
        self.level2Label.hidden = YES;
        self.level3Label.hidden = YES;
        self.levelTextTopCon.constant = 0;
        self.nameLabel.text = areaEntity.areaName;
        self.kindLabel.hidden = NO;
        self.kindLabel.text = [NSString stringWithFormat:@"× %ld",[_groupMembers count]];
        _adjustableBrightness = NO;
        for (CSRDeviceEntity *deviceEntity in self.groupMembers) {
            if ([CSRUtilities belongToDimmer:deviceEntity.shortName]
                || [CSRUtilities belongToTwoChannelDimmer:deviceEntity.shortName]
                || [CSRUtilities belongToThreeChannelDimmer:deviceEntity.shortName]
                || [CSRUtilities belongToCWDevice:deviceEntity.shortName]
                || [CSRUtilities belongToRGBDevice:deviceEntity.shortName]
                || [CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
                _adjustableBrightness = YES;
                break;
            }
        }
        if (_adjustableBrightness) {
            self.levelLabel.hidden = NO;
        }else {
            self.levelLabel.hidden = YES;
        }
        /*
        NSString *kind=@"";
        NSInteger dimmerNum = 0;
        NSInteger switchNum = 0;
        NSInteger controllerNum = 0;
        for (CSRDeviceEntity *deviceEntity in self.groupMembers) {
            if ([CSRUtilities belongToDimmer:deviceEntity.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceEntity.shortName] || [CSRUtilities belongToThreeChannelDimmer:deviceEntity.shortName]) {
                dimmerNum ++;
            }else if ([CSRUtilities belongToCWDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
                dimmerNum ++;
            }else if ([CSRUtilities belongToSwitch:deviceEntity.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceEntity.shortName] || [CSRUtilities belongToThreeChannelSwitch:deviceEntity.shortName]) {
                switchNum ++;
            }else {
                controllerNum ++;
            }
        }
        if (dimmerNum > 0) {
            kind = [NSString stringWithFormat:@"%@ ×%ld",AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable"),(long)dimmerNum];
        }
        if (switchNum > 0) {
            if (kind.length>0) {
                kind = [NSString stringWithFormat:@"%@  %@ ×%ld",kind,AcTECLocalizedStringFromTable(@"Switch", @"Localizable"),(long)switchNum];
            }else {
                kind = [NSString stringWithFormat:@"%@ ×%ld",AcTECLocalizedStringFromTable(@"Switch", @"Localizable"),(long)switchNum];
            }
            
        }
        if (controllerNum > 0) {
            if (kind.length > 0) {
                kind = [NSString stringWithFormat:@"%@  %@ ×%ld",kind,AcTECLocalizedStringFromTable(@"Controller", @"Localizable"),(long)controllerNum];
            }else {
                kind = [NSString stringWithFormat:@"%@ ×%ld",AcTECLocalizedStringFromTable(@"Controller", @"Localizable"),(long)controllerNum];
            }
        }
        
        if ([kind containsString:AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable")]) {
            self.levelLabel.hidden = NO;
        }else {
            self.levelLabel.hidden = YES;
        }*/
        
        if ([areaEntity.areaIconNum isEqualToNumber:@99]) {
            self.iconView.image = [UIImage imageWithData:areaEntity.areaImage];
        }else {
            NSArray *iconArray = kGroupIcons;
            NSString *imageString = [iconArray objectAtIndex:[areaEntity.areaIconNum integerValue]];
            self.iconView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@room",imageString]];
        }
        self.cellIndexPath = indexPath;
        [self adjustGroupCellBgcolorAndLevelLabel];
        self.bottomView.hidden = NO;
        [self showDeleteBtnAndMoveImageView:![areaEntity.isEditting boolValue]];
        return;
    }
    
    if ([info isKindOfClass:[GroupListSModel class]]) {
        GroupListSModel *model = (GroupListSModel *)info;
        self.groupId = model.areaID;
        self.deviceId = @2000;
        self.groupMembers = [model.devices allObjects];
        self.nameLabel.hidden = NO;
        self.level2Label.hidden = YES;
        self.level3Label.hidden = YES;
        self.levelTextTopCon.constant = 0;
        self.nameLabel.text = model.areaName;
        self.kindLabel.hidden = NO;
        _adjustableBrightness = NO;
        for (CSRDeviceEntity *deviceEntity in self.groupMembers) {
            if ([CSRUtilities belongToDimmer:deviceEntity.shortName]
                || [CSRUtilities belongToTwoChannelDimmer:deviceEntity.shortName]
                || [CSRUtilities belongToThreeChannelDimmer:deviceEntity.shortName]
                || [CSRUtilities belongToCWDevice:deviceEntity.shortName]
                || [CSRUtilities belongToRGBDevice:deviceEntity.shortName]
                || [CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
                _adjustableBrightness = YES;
                break;
            }
        }
        if (_adjustableBrightness) {
            self.levelLabel.hidden = NO;
        }else {
            self.levelLabel.hidden = YES;
        }
        /*
        NSString *kind=@"";
        NSInteger dimmerNum = 0;
        NSInteger switchNum = 0;
        NSInteger controllerNum = 0;
        for (CSRDeviceEntity *deviceEntity in self.groupMembers) {
            if ([CSRUtilities belongToDimmer:deviceEntity.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceEntity.shortName] || [CSRUtilities belongToThreeChannelDimmer:deviceEntity.shortName]) {
                dimmerNum ++;
            }else if ([CSRUtilities belongToCWDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
                dimmerNum ++;
            }else if ([CSRUtilities belongToSwitch:deviceEntity.shortName] || [CSRUtilities belongToTwoChannelSwitch:deviceEntity.shortName] || [CSRUtilities belongToThreeChannelSwitch:deviceEntity.shortName]) {
                switchNum ++;
            }else {
                controllerNum ++;
            }
        }
        if (dimmerNum > 0) {
            kind = [NSString stringWithFormat:@"%@ ×%ld",AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable"),(long)dimmerNum];
        }
        if (switchNum > 0) {
            if (kind.length>0) {
                kind = [NSString stringWithFormat:@"%@  %@ ×%ld",kind,AcTECLocalizedStringFromTable(@"Switch", @"Localizable"),(long)switchNum];
            }else {
                kind = [NSString stringWithFormat:@"%@ ×%ld",AcTECLocalizedStringFromTable(@"Switch", @"Localizable"),(long)switchNum];
            }
            
        }
        if (controllerNum > 0) {
            if (kind.length > 0) {
                kind = [NSString stringWithFormat:@"%@  %@ ×%ld",kind,AcTECLocalizedStringFromTable(@"Controller", @"Localizable"),(long)controllerNum];
            }else {
                kind = [NSString stringWithFormat:@"%@ ×%ld",AcTECLocalizedStringFromTable(@"Controller", @"Localizable"),(long)controllerNum];
            }
        }
        self.kindLabel.text = kind;
        if ([kind containsString:AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable")] || [kind containsString:AcTECLocalizedStringFromTable(@"Controller", @"Localizable")]) {
            self.levelLabel.hidden = NO;
        }else {
            self.levelLabel.hidden = YES;
        }*/
        
        if ([model.areaIconNum isEqualToNumber:@99]) {
            self.iconView.image = [UIImage imageWithData:model.areaImage];
        }else {
            NSArray *iconArray = kGroupIcons;
            NSString *imageString = [iconArray objectAtIndex:[model.areaIconNum integerValue]];
            self.iconView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@room",imageString]];
        }
        self.cellIndexPath = indexPath;
        [self adjustGroupCellBgcolorAndLevelLabel];
        self.bottomView.hidden = NO;
        if (model.isForList) {
            self.seleteButton.hidden = NO;
            self.seleteButton.selected = model.isSelected;
        }
        
        return;
    }
    
    if ([info isKindOfClass:[CSRDeviceEntity class]]) {
        
        CSRDeviceEntity *deviceEntity = (CSRDeviceEntity *)info;
        
        self.groupId = @1000;
        self.deviceId = deviceEntity.deviceId;
        self.nameLabel.hidden = NO;
        self.nameLabel.text = deviceEntity.name;
        self.kindLabel.hidden = NO;
        if ([CSRUtilities belongToDimmer:deviceEntity.shortName]) {
            if ([CSRUtilities belongToESeriesDimmer:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_E_press"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            }else if ([CSRUtilities belongToESeriesKnobDimmer:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_E_knob"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            }else if ([CSRUtilities belongToTSeriesPanel:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_T_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"dimmer_panel", @"Localizable");
            }else if ([CSRUtilities belongToPSeriesPanel:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_P_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"dimmer_panel", @"Localizable");
            }else if ([CSRUtilities belongToHiddenController:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_hidden_controller"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"dimmersingle"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            }
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = YES;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToSwitch:deviceEntity.shortName]) {
            if ([CSRUtilities belongToESeriesSingleWireSwitch:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_E_press"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            }else if ([CSRUtilities belongToTSeriesPanel:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_T_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"switch_panel", @"Localizable");
            }else if ([CSRUtilities belongToPSeriesPanel:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_P_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"switch_panel", @"Localizable");
            }else if ([CSRUtilities belongToHiddenController:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_hidden_controller"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"switchsingle"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            }
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToCWDevice:deviceEntity.shortName]
                  || [CSRUtilities belongToRGBDevice:deviceEntity.shortName]
                  || [CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
            if ([CSRUtilities belongToIEMLEDDriver:deviceEntity.shortName]
                || [CSRUtilities belongToIELEDDriver:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_IE_driver"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"drive", @"Localizable");
            }else if ([CSRUtilities belongToLIMLEDDriver:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_LIM_driver"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"drive", @"Localizable");
            }else if ([CSRUtilities belongToC3ABLEDDriver:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_C3AB_driver"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"led_trip_controller", @"Localizable");
            }else if ([CSRUtilities belongToC2ABLEDDriver:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_C2AB_driver"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"led_trip_controller", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"room_LED_strip"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"led_trip_controller", @"Localizable");
            }
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = YES;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToOneChannelCurtainController:deviceEntity.shortName]) {
            if ([CSRUtilities belongToHiddenController:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_hidden_controller"];
            }else {
                self.iconView.image = [UIImage imageNamed:@"room_curtain"];
            }
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"curtain_controller", @"Localizable");
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToHOneChannelCurtainController:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"room_curtain"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"curtain_controller", @"Localizable");
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToTwoChannelCurtainController:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"room_curtain"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"curtain_controller", @"Localizable");
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = NO;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToFanController:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"room_fan"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"fan_controller", @"Localizable");
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToSocketTwoChannel:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"room_socket"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"smart_socket", @"Localizable");
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = NO;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToTwoChannelDimmer:deviceEntity.shortName]) {
            if ([CSRUtilities belongToTSeriesPanel:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_T_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"dimmer_panel", @"Localizable");
            }else if ([CSRUtilities belongToPSeriesPanel:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_P_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"dimmer_panel", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"dimmersingle2"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            }
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = NO;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = YES;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToSocketOneChannel:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"room_socket"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"smart_socket", @"Localizable");
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToTwoChannelSwitch:deviceEntity.shortName]) {
            if ([CSRUtilities belongToTSeriesPanel:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_T_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"switch_panel", @"Localizable");
            }else if ([CSRUtilities belongToPSeriesPanel:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_P_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"switch_panel", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"switchsingle2"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            }
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = NO;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToSceneRemoteSixKeys:deviceEntity.shortName]
                  || [CSRUtilities belongToSceneRemoteFourKeys:deviceEntity.shortName]
                  || [CSRUtilities belongToSceneRemoteThreeKeys:deviceEntity.shortName]
                  || [CSRUtilities belongToSceneRemoteTwoKeys:deviceEntity.shortName]
                  || [CSRUtilities belongToSceneRemoteOneKey:deviceEntity.shortName]
                  || [CSRUtilities belongToMusicControlRemote:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"room_T_panel"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"scene_panel", @"Localizable");
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToCWRemote:deviceEntity.shortName]
                  || [CSRUtilities belongToRGBRemote:deviceEntity.shortName]
                  || [CSRUtilities belongToRGBCWRemote:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"room_T_color_panel"];
            if ([CSRUtilities belongToCWRemote:deviceEntity.shortName]) {
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"color_temperature_panel", @"Localizable");
            }else if ([CSRUtilities belongToRGBRemote:deviceEntity.shortName]) {
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"color_panel", @"Localizable");
            }else if ([CSRUtilities belongToRGBCWRemote:deviceEntity.shortName]) {
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"color_and_color_temperature_panel", @"Localizable");
            }
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToSceneRemoteSixKeysV:deviceEntity.shortName]
                  || [CSRUtilities belongToSceneRemoteFourKeysV:deviceEntity.shortName]
                  || [CSRUtilities belongToSceneRemoteThreeKeysV:deviceEntity.shortName]
                  || [CSRUtilities belongToSceneRemoteTwoKeysV:deviceEntity.shortName]
                  || [CSRUtilities belongToSceneRemoteOneKeyV:deviceEntity.shortName]
                  || [CSRUtilities belongToMusicControlRemoteV:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"room_P_panel"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"scene_panel", @"Localizable");
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToLCDRemote:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"room_LCD_panel"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"Controller", @"Localizable");
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToThreeChannelSwitch:deviceEntity.shortName]) {
            if ([CSRUtilities belongToTSeriesPanel:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_T_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"switch_panel", @"Localizable");
            }else if ([CSRUtilities belongToPSeriesPanel:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_P_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"switch_panel", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"switchsingle3"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            }
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = NO;
            self.level3Label.hidden = NO;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = -14.0;
        }else if ([CSRUtilities belongToThreeChannelDimmer:deviceEntity.shortName]) {
            if ([CSRUtilities belongToTSeriesPanel:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_T_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"dimmer_panel", @"Localizable");
            }else if ([CSRUtilities belongToPSeriesPanel:deviceEntity.shortName]) {
                self.iconView.image = [UIImage imageNamed:@"room_P_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"dimmer_panel", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"dimmer3"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            }
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = NO;
            self.level3Label.hidden = NO;
            self.adjustableBrightness = YES;
            self.levelTextTopCon.constant = -14.0;
        }else if ([CSRUtilities belongToMusicController:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"room_hidden_controller"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"Controller", @"Localizable");
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToSonosMusicController:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"room_sonos"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"module", @"Localizable");
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongtoDALIDeviceTwo:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"dimmersingle"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"dali_dimmer", @"Localizable");
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToPIRDevice:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"room_hidden_controller"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"human_body_sensor", @"Localizable");
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }
        
        self.cellIndexPath = indexPath;
        [self adjustGroupCellBgcolorAndLevelLabel];
        [self adjustCellBgcolorAndLevelLabelWithDeviceId:deviceEntity.deviceId];
        self.bottomView.hidden = NO;
        [self showDeleteBtnAndMoveImageView:![deviceEntity.isEditting boolValue]];
        return;
    }
    
    if ([info isKindOfClass:[SingleDeviceModel class]]) {
        
        SingleDeviceModel *device = (SingleDeviceModel *)info;
        self.groupId = @2000;
        self.deviceId = device.deviceId;
        self.nameLabel.hidden = NO;
        self.nameLabel.text = device.deviceName;
        self.kindLabel.hidden = NO;
        if ([CSRUtilities belongToDimmer:device.deviceShortName]) {
            if ([CSRUtilities belongToESeriesDimmer:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_E_press"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            }else if ([CSRUtilities belongToESeriesKnobDimmer:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_E_knob"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            }else if ([CSRUtilities belongToTSeriesPanel:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_T_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"dimmer_panel", @"Localizable");
            }else if ([CSRUtilities belongToPSeriesPanel:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_P_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"dimmer_panel", @"Localizable");
            }else if ([CSRUtilities belongToHiddenController:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_hidden_controller"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"Device_Dimmer"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            }
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = YES;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToSwitch:device.deviceShortName]) {
            if ([CSRUtilities belongToESeriesSingleWireSwitch:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_E_press"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            }else if ([CSRUtilities belongToTSeriesPanel:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_T_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"switch_panel", @"Localizable");
            }else if ([CSRUtilities belongToPSeriesPanel:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_P_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"switch_panel", @"Localizable");
            }else if ([CSRUtilities belongToHiddenController:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_hidden_controller"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"Device_Switch"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            }
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToCWDevice:device.deviceShortName]
                  || [CSRUtilities belongToRGBDevice:device.deviceShortName]
                  || [CSRUtilities belongToRGBCWDevice:device.deviceShortName]) {
            if ([CSRUtilities belongToIEMLEDDriver:device.deviceShortName]
                || [CSRUtilities belongToIELEDDriver:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_IE_driver"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"drive", @"Localizable");
            }else if ([CSRUtilities belongToLIMLEDDriver:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_LIM_driver"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"drive", @"Localizable");
            }else if ([CSRUtilities belongToC3ABLEDDriver:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_C3AB_driver"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"led_trip_controller", @"Localizable");
            }else if ([CSRUtilities belongToC2ABLEDDriver:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_C2AB_driver"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"led_trip_controller", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"device_LED_strip"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"led_trip_controller", @"Localizable");
            }
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = YES;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToOneChannelCurtainController:device.deviceShortName]) {
            if ([CSRUtilities belongToHiddenController:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_hidden_controller"];
            }else {
                self.iconView.image = [UIImage imageNamed:@"device_curtain"];
            }
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"curtain_controller", @"Localizable");
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToHOneChannelCurtainController:device.deviceShortName]) {
            self.iconView.image = [UIImage imageNamed:@"device_curtain"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"curtain_controller", @"Localizable");
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToTwoChannelCurtainController:device.deviceShortName]) {
            self.iconView.image = [UIImage imageNamed:@"device_curtain"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"curtain_controller", @"Localizable");
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = NO;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToFanController:device.deviceShortName]) {
            self.iconView.image = [UIImage imageNamed:@"device_fan"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"fan_controller", @"Localizable");
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToSocketTwoChannel:device.deviceShortName]) {
            self.iconView.image = [UIImage imageNamed:@"device_socket"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"smart_socket", @"Localizable");
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = NO;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToTwoChannelDimmer:device.deviceShortName]) {
            if ([CSRUtilities belongToTSeriesPanel:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_T_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"dimmer_panel", @"Localizable");
            }else if ([CSRUtilities belongToPSeriesPanel:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_P_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"dimmer_panel", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"Device_dimmer2"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            }
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = NO;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = YES;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToSocketOneChannel:device.deviceShortName]) {
            self.iconView.image = [UIImage imageNamed:@"device_socket"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"smart_socket", @"Localizable");
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToTwoChannelSwitch:device.deviceShortName]) {
            if ([CSRUtilities belongToTSeriesPanel:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_T_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"switch_panel", @"Localizable");
            }else if ([CSRUtilities belongToPSeriesPanel:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_P_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"switch_panel", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"Device_switch2"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            }
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = NO;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToThreeChannelSwitch:device.deviceShortName]) {
            if ([CSRUtilities belongToTSeriesPanel:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_T_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"switch_panel", @"Localizable");
            }else if ([CSRUtilities belongToPSeriesPanel:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_P_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"switch_panel", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"Device_switch3"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            }
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = NO;
            self.level3Label.hidden = NO;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = -14.0;
        }else if ([CSRUtilities belongToThreeChannelDimmer:device.deviceShortName]) {
            if ([CSRUtilities belongToTSeriesPanel:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_T_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"dimmer_panel", @"Localizable");
            }else if ([CSRUtilities belongToPSeriesPanel:device.deviceShortName]) {
                self.iconView.image = [UIImage imageNamed:@"device_P_panel"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"dimmer_panel", @"Localizable");
            }else {
                self.iconView.image = [UIImage imageNamed:@"device_dimmer3"];
                self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            }
            self.levelLabel.hidden = NO;
            self.level2Label.hidden = NO;
            self.level3Label.hidden = NO;
            self.adjustableBrightness = YES;
            self.levelTextTopCon.constant = -14.0;
        }else if ([CSRUtilities belongToMusicController:device.deviceShortName]) {
            self.iconView.image = [UIImage imageNamed:@"device_hidden_controller"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"Controller", @"Localizable");
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToSonosMusicController:device.deviceShortName]) {
            self.iconView.image = [UIImage imageNamed:@"device_sonos"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"module", @"Localizable");
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongtoDALIDeviceTwo:device.deviceShortName]) {
            self.iconView.image = [UIImage imageNamed:@"Device_Dimmer"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"dali_dimmer", @"Localizable");
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }else if ([CSRUtilities belongToPIRDevice:device.deviceShortName]) {
            self.iconView.image = [UIImage imageNamed:@"device_hidden_controller"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"human_body_sensor", @"Localizable");
            self.levelLabel.hidden = YES;
            self.level2Label.hidden = YES;
            self.level3Label.hidden = YES;
            self.adjustableBrightness = NO;
            self.levelTextTopCon.constant = 0;
        }
        self.cellIndexPath = indexPath;
        self.bottomView.hidden = YES;
        [self adjustCellBgcolorAndLevelLabelWithDeviceId:device.deviceId];
        if (device.isForList) {
            self.seleteButton.hidden = NO;
            self.seleteButton.selected = device.isSelected;
        }
        return;
    }
    
    if ([info isKindOfClass:[NSNumber class]]) {
        self.groupId = @4000;
        NSNumber *num = (NSNumber *)info;
        if ([num isEqualToNumber:@0]) {
            self.deviceId = @1000;
        }else if ([num isEqualToNumber:@1]) {
            self.deviceId = @4000;
        }
        self.kindLabel.text = @"addItem";
        self.iconView.image = [UIImage imageNamed:@"addroom"];
        self.cellIndexPath = indexPath;
        self.nameLabel.hidden = YES;
        self.kindLabel.hidden = YES;
        self.levelLabel.hidden = YES;
        self.deleteBtn.hidden = YES;
        self.moveImageView.hidden = YES;
        self.bottomView.hidden = YES;
        self.level2Label.hidden = YES;
        self.level3Label.hidden = YES;
        self.adjustableBrightness = NO;
        self.levelTextTopCon.constant = 0;
        return;
    }
    
    if ([info isKindOfClass:[CSRmeshDevice class]]) {
        CSRmeshDevice *device = (CSRmeshDevice *)info;
        self.levelLabel.hidden = YES;
        self.level2Label.hidden = YES;
        self.level3Label.hidden = YES;
        self.levelTextTopCon.constant = 0;
        self.groupId = @4000;
        self.deviceId = @3000;
        self.adjustableBrightness = NO;
        NSString *appearanceShortname = [[NSString alloc] initWithData:device.appearanceShortname encoding:NSUTF8StringEncoding];
        //去除不易察觉的空格
        appearanceShortname = [appearanceShortname stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
        self.nameLabel.text = appearanceShortname;
        self.kindLabel.text = [NSString stringWithFormat:@"%@",[device.uuid.UUIDString substringFromIndex:24]];
        if ([CSRUtilities belongToDimmer:appearanceShortname]
            || [CSRUtilities belongtoDALIDeviceTwo:appearanceShortname]) {
            if ([CSRUtilities belongToESeriesDimmer:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_E_press"];
            }else if ([CSRUtilities belongToESeriesKnobDimmer:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_E_knob"];
            }else if ([CSRUtilities belongToTSeriesPanel:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_T_panel"];
            }else if ([CSRUtilities belongToPSeriesPanel:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_P_panel"];
            }else if ([CSRUtilities belongToHiddenController:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_hidden_controller"];
            }else {
                self.iconView.image = [UIImage imageNamed:@"Device_Dimmer"];
            }
        }else if ([CSRUtilities belongToSwitch:appearanceShortname]) {
            if ([CSRUtilities belongToESeriesSingleWireSwitch:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_E_press"];
            }else if ([CSRUtilities belongToTSeriesPanel:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_T_panel"];
            }else if ([CSRUtilities belongToPSeriesPanel:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_P_panel"];
            }else if ([CSRUtilities belongToHiddenController:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_hidden_controller"];
            }else {
                self.iconView.image = [UIImage imageNamed:@"Device_Switch"];
            }
        }else if ([appearanceShortname containsString:@"RB01"] || [appearanceShortname containsString:@"R5BSBH"] || [appearanceShortname containsString:@"5BCBH"]) {
            self.iconView.image = [UIImage imageNamed:@"device_round_five_key_remote"];
        }else if ([appearanceShortname containsString:@"RB02"]
                  ||[appearanceShortname isEqualToString:@"RB06"]
                  ||[appearanceShortname isEqualToString:@"RSBH"]
                  ||[appearanceShortname isEqualToString:@"1BMBH"]) {
            self.iconView.image = [UIImage imageNamed:@"Device_Remote2"];
        }else if ([appearanceShortname containsString:@"RB04"]
                  || [appearanceShortname containsString:@"RSIBH"]
                  || [appearanceShortname containsString:@"RB07"]) {
            self.iconView.image = [UIImage imageNamed:@"device_hidden_controller"];
        }else if ([appearanceShortname containsString:@"R9BSBH"]) {
            self.iconView.image = [UIImage imageNamed:@"device_round_five_key_remote"];
        }else if ([appearanceShortname containsString:@"RB05"]) {
            self.iconView.image = [UIImage imageNamed:@"device_square_five_key_remote"];
        }else if ([appearanceShortname containsString:@"RB08"]) {
            self.iconView.image = [UIImage imageNamed:@"device_E_knob"];
        }else if ([appearanceShortname isEqualToString:@"H1CSWB"]
                  || [appearanceShortname isEqualToString:@"H2CSWB"]
                  || [appearanceShortname isEqualToString:@"H3CSWB"]
                  || [appearanceShortname isEqualToString:@"H4CSWB"]
                  || [appearanceShortname isEqualToString:@"H6CSWB"]
                  || [appearanceShortname isEqualToString:@"H1CSB"]
                  || [appearanceShortname isEqualToString:@"H2CSB"]
                  || [appearanceShortname isEqualToString:@"H3CSB"]
                  || [appearanceShortname isEqualToString:@"H4CSB"]
                  || [appearanceShortname isEqualToString:@"H6CSB"]
                  || [appearanceShortname isEqualToString:@"KT6RS"]
                  || [appearanceShortname isEqualToString:@"H1RSMB"]
                  || [appearanceShortname isEqualToString:@"H2RSMB"]
                  || [appearanceShortname isEqualToString:@"H3RSMB"]
                  || [appearanceShortname isEqualToString:@"H4RSMB"]
                  || [appearanceShortname isEqualToString:@"H5RSMB"]
                  || [appearanceShortname isEqualToString:@"H6RSMB"]) {
            self.iconView.image = [UIImage imageNamed:@"device_T_pannel"];
        }else if ([CSRUtilities belongToLightSensor:appearanceShortname]){
            self.iconView.image = [UIImage imageNamed:@"Device_Sensor"];
        }else if ([CSRUtilities belongToCWDevice:appearanceShortname]
                  || [CSRUtilities belongToRGBDevice:appearanceShortname]
                  || [CSRUtilities belongToRGBCWDevice:appearanceShortname]) {
            if ([CSRUtilities belongToIEMLEDDriver:appearanceShortname]
                || [CSRUtilities belongToIELEDDriver:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_IE_driver"];
            }else if ([CSRUtilities belongToLIMLEDDriver:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_LIM_driver"];
            }else if ([CSRUtilities belongToC3ABLEDDriver:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_C3AB_driver"];
            }else if ([CSRUtilities belongToC2ABLEDDriver:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_C2AB_driver"];
            }else {
                self.iconView.image = [UIImage imageNamed:@"device_LED_strip"];
            }
        }else if ([CSRUtilities belongToOneChannelCurtainController:appearanceShortname]
                  || [CSRUtilities belongToHOneChannelCurtainController:appearanceShortname]) {
            if ([CSRUtilities belongToHiddenController:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_hidden_controller"];
            }else {
                self.iconView.image = [UIImage imageNamed:@"device_curtain"];
            }
        }else if ([CSRUtilities belongToTwoChannelCurtainController:appearanceShortname]) {
            self.iconView.image = [UIImage imageNamed:@"device_curtain"];
        }else if ([CSRUtilities belongToFanController:appearanceShortname]) {
            self.iconView.image = [UIImage imageNamed:@"device_fan"];
        }else if ([CSRUtilities belongToSocketTwoChannel:appearanceShortname]) {
            self.iconView.image = [UIImage imageNamed:@"device_socket"];
        }else if ([CSRUtilities belongToTwoChannelDimmer:appearanceShortname]) {
            if ([CSRUtilities belongToTSeriesPanel:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_T_panel"];
            }else if ([CSRUtilities belongToPSeriesPanel:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_P_panel"];
            }else {
                self.iconView.image = [UIImage imageNamed:@"Device_dimmer2"];
            }
        }else if ([CSRUtilities belongToSocketOneChannel:appearanceShortname]) {
            self.iconView.image = [UIImage imageNamed:@"device_socket"];
        }else if ([appearanceShortname containsString:@"RB09"]||[appearanceShortname containsString:@"5RSIBH"]) {
            self.iconView.image = [UIImage imageNamed:@"device_hidden_controller"];
        }else if ([CSRUtilities belongToTwoChannelSwitch:appearanceShortname]) {
            if ([CSRUtilities belongToTSeriesPanel:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_T_panel"];
            }else if ([CSRUtilities belongToPSeriesPanel:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_P_panel"];
            }else {
                self.iconView.image = [UIImage imageNamed:@"Device_switch2"];
            }
        }else if ([CSRUtilities belongToSceneRemoteSixKeys:appearanceShortname]
                  || [CSRUtilities belongToSceneRemoteFourKeys:appearanceShortname]
                  || [CSRUtilities belongToSceneRemoteThreeKeys:appearanceShortname]
                  || [CSRUtilities belongToSceneRemoteTwoKeys:appearanceShortname]
                  || [CSRUtilities belongToSceneRemoteOneKey:appearanceShortname]
                  || [CSRUtilities belongToMusicControlRemote:appearanceShortname]) {
            self.iconView.image = [UIImage imageNamed:@"device_T_panel"];
        }else if ([CSRUtilities belongToCWRemote:appearanceShortname]
                  || [CSRUtilities belongToRGBRemote:appearanceShortname]
                  || [CSRUtilities belongToRGBCWRemote:appearanceShortname]) {
            self.iconView.image = [UIImage imageNamed:@"device_T_color_panel"];
        }else if ([CSRUtilities belongToSceneRemoteSixKeysV:appearanceShortname]
                  || [CSRUtilities belongToSceneRemoteFourKeysV:appearanceShortname]
                  || [CSRUtilities belongToSceneRemoteThreeKeysV:appearanceShortname]
                  || [CSRUtilities belongToSceneRemoteTwoKeysV:appearanceShortname]
                  || [CSRUtilities belongToSceneRemoteOneKeyV:appearanceShortname]
                  || [CSRUtilities belongToMusicControlRemoteV:appearanceShortname]) {
            self.iconView.image = [UIImage imageNamed:@"device_P_panel"];
        }else if ([CSRUtilities belongToLCDRemote:appearanceShortname]) {
            self.iconView.image = [UIImage imageNamed:@"device_LCD_panel"];
        }else if ([CSRUtilities belongToThreeChannelSwitch:appearanceShortname]) {
            if ([CSRUtilities belongToTSeriesPanel:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_T_panel"];
            }else if ([CSRUtilities belongToPSeriesPanel:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_P_panel"];
            }else {
                self.iconView.image = [UIImage imageNamed:@"Device_switch3"];
            }
        }else if ([CSRUtilities belongToThreeChannelDimmer:appearanceShortname]) {
            if ([CSRUtilities belongToTSeriesPanel:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_T_panel"];
            }else if ([CSRUtilities belongToPSeriesPanel:appearanceShortname]) {
                self.iconView.image = [UIImage imageNamed:@"device_P_panel"];
            }else {
                self.iconView.image = [UIImage imageNamed:@"device_dimmer3"];
            }
        }else if ([CSRUtilities belongToMusicController:appearanceShortname]) {
            self.iconView.image = [UIImage imageNamed:@"device_hidden_controller"];
        }else if ([CSRUtilities belongToSonosMusicController:appearanceShortname]) {
            self.iconView.image = [UIImage imageNamed:@"device_sonos"];
        }else if ([CSRUtilities belongToPIRDevice:appearanceShortname]) {
            self.iconView.image = [UIImage imageNamed:@"device_hidden_controller"];
        }
        self.cellIndexPath = indexPath;
        self.bottomView.hidden = YES;
        return;
    }
    
    if ([info isKindOfClass:[SceneListSModel class]]) {
        SceneListSModel *model = (SceneListSModel *)info;
        self.nameLabel.hidden = NO;
        self.kindLabel.hidden = YES;
        self.levelLabel.hidden = YES;
        self.level2Label.hidden = YES;
        self.level3Label.hidden = YES;
        self.levelTextTopCon.constant = 0;
        self.deleteBtn.hidden = YES;
        self.moveImageView.hidden = YES;
        self.bottomView.hidden = YES;
        NSString *iconString = kSceneIcons[[model.iconId integerValue]];
        self.iconView.image = [UIImage imageNamed:[NSString stringWithFormat:@"Scene_%@_select",iconString]];
        self.nameLabel.text = model.sceneName;
        self.rcIndex = model.rcIndex;
        self.groupId = @2000;
        self.deviceId = @1000;
        self.seleteButton.hidden = NO;
        self.seleteButton.selected = model.isSelected;
        self.adjustableBrightness = NO;
        return;
    }
    
}

- (void)adjustCellBgcolorAndLevelLabelWithDeviceId:(NSNumber *)deviceId {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
    if (!model.isleave) {
        if ([CSRUtilities belongToSocketTwoChannel:model.shortName]
            || [CSRUtilities belongToTwoChannelCurtainController:model.shortName]
            || [CSRUtilities belongToTwoChannelSwitch:model.shortName]) {
            if ([model.powerState boolValue]) {
                self.nameLabel.textColor = DARKORAGE;
            }else {
                self.nameLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
            }
            if (model.channel1PowerState) {
                self.levelLabel.text = @"ON";
                self.levelLabel.textColor = DARKORAGE;
            }else {
                self.levelLabel.text = @"OFF";
                self.levelLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
            }
            if (model.channel2PowerState) {
                self.level2Label.text = @"ON";
                self.level2Label.textColor = DARKORAGE;
            }else {
                self.level2Label.text = @"OFF";
                self.level2Label.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
            }
        }else if ([CSRUtilities belongToSocketOneChannel:model.shortName]
                  || [CSRUtilities belongToOneChannelCurtainController:model.shortName]
                  || [CSRUtilities belongToHOneChannelCurtainController:model.shortName]) {
            if ([model.powerState boolValue]) {
                self.nameLabel.textColor = DARKORAGE;
                self.levelLabel.text = @"ON";
                self.levelLabel.textColor = DARKORAGE;
            }else {
                self.nameLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
                self.levelLabel.text = @"OFF";
                self.levelLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
            }
        }else if ([CSRUtilities belongToTwoChannelDimmer:model.shortName]) {
            if (model.channel1PowerState) {
                self.levelLabel.textColor = DARKORAGE;
                if (model.channel1Level/255.0*100>0 && model.channel1Level/255.0*100 < 1.0) {
                    self.levelLabel.text = @"1%";
                }else {
                    self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",model.channel1Level/255.0*100];
                }
            }else {
                self.levelLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
                self.levelLabel.text = @"0%";
            }
            if (model.channel2PowerState) {
                self.level2Label.textColor = DARKORAGE;
                if (model.channel2Level/255.0*100>0 && model.channel2Level/255.0*100 < 1.0) {
                    self.level2Label.text = @"1%";
                }else {
                    self.level2Label.text = [NSString stringWithFormat:@"%.f%%",model.channel2Level/255.0*100];
                }
            }else {
                self.level2Label.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
                self.level2Label.text = @"0%";
            }
            if (model.channel1PowerState || model.channel2PowerState) {
                self.nameLabel.textColor = DARKORAGE;
            }else {
                self.nameLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
            }
        }else if ([CSRUtilities belongToThreeChannelSwitch:model.shortName]) {
            if ([model.powerState boolValue]) {
                self.nameLabel.textColor = DARKORAGE;
            }else {
                self.nameLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
            }
            if (model.channel1PowerState) {
                self.levelLabel.text = @"ON";
                self.levelLabel.textColor = DARKORAGE;
            }else {
                self.levelLabel.text = @"OFF";
                self.levelLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
            }
            if (model.channel2PowerState) {
                self.level2Label.text = @"ON";
                self.level2Label.textColor = DARKORAGE;
            }else {
                self.level2Label.text = @"OFF";
                self.level2Label.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
            }
            if (model.channel3PowerState) {
                self.level3Label.text = @"ON";
                self.level3Label.textColor = DARKORAGE;
            }else {
                self.level3Label.text = @"OFF";
                self.level3Label.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
            }
        }else if ([CSRUtilities belongToThreeChannelDimmer:model.shortName]) {
            if (model.channel1PowerState) {
                float l = model.channel1Level/255.0*100;
                self.levelLabel.text = (l>0 && l<1) ? @"1%" : [NSString stringWithFormat:@"%.f%%",l];
                self.levelLabel.textColor = DARKORAGE;
            }else {
                self.levelLabel.text = @"0%";
                self.levelLabel.textColor = ColorWithAlpha(77, 77, 77, 1);
            }
            if (model.channel2PowerState) {
                float l = model.channel2Level/255.0*100;
                self.level2Label.text = (l>0 && l<1) ? @"1%" : [NSString stringWithFormat:@"%.f%%",l];
                self.level2Label.textColor = DARKORAGE;
            }else {
                self.level2Label.text = @"0%";
                self.level2Label.textColor = ColorWithAlpha(77, 77, 77, 1);
            }
            if (model.channel3PowerState) {
                float l = model.channel3Level/255.0*100;
                self.level3Label.text = (l>0 && l<1) ? @"1%" : [NSString stringWithFormat:@"%.f%%",l];
                self.level3Label.textColor = DARKORAGE;
            }else {
                self.level3Label.text = @"0%";
                self.level3Label.textColor = ColorWithAlpha(77, 77, 77, 1);
            }
            if (model.channel1PowerState || model.channel2PowerState || model.channel3PowerState) {
                self.nameLabel.textColor = DARKORAGE;
            }else {
                self.nameLabel.textColor = ColorWithAlpha(77, 77, 77, 1);
            }
        }else {
            if ([CSRUtilities belongToSceneRemoteOneKey:model.shortName]
                || [CSRUtilities belongToSceneRemoteTwoKeys:model.shortName]
                || [CSRUtilities belongToSceneRemoteThreeKeys:model.shortName]
                || [CSRUtilities belongToSceneRemoteFourKeys:model.shortName]
                || [CSRUtilities belongToSceneRemoteSixKeys:model.shortName]
                || [CSRUtilities belongToSceneRemoteOneKeyV:model.shortName]
                || [CSRUtilities belongToSceneRemoteTwoKeysV:model.shortName]
                || [CSRUtilities belongToSceneRemoteThreeKeysV:model.shortName]
                || [CSRUtilities belongToSceneRemoteFourKeysV:model.shortName]
                || [CSRUtilities belongToSceneRemoteSixKeysV:model.shortName]
                || [CSRUtilities belongToMusicController:model.shortName]
                || [CSRUtilities belongToMusicControlRemote:model.shortName]
                || [CSRUtilities belongToMusicControlRemoteV:model.shortName]
                || [CSRUtilities belongToSonosMusicController:model.shortName]
                || [CSRUtilities belongToRGBRemote:model.shortName]
                || [CSRUtilities belongToRGBCWRemote:model.shortName]
                || [CSRUtilities belongToCWRemote:model.shortName]
                || [CSRUtilities belongToLCDRemote:model.shortName]
                || [CSRUtilities belongToPIRDevice:model.shortName]) {
                self.nameLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
            }else {
                if (![model.powerState boolValue]) {
                    if ([_groupId isEqualToNumber:@1000] || [_groupId isEqualToNumber:@2000]) {
                        self.nameLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
                        self.levelLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
                    }else {
                        self.backgroundColor = [UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1];
                    }
                    
                    if ([CSRUtilities belongToDimmer:model.shortName]
                        || [CSRUtilities belongToCWDevice:model.shortName]
                        || [CSRUtilities belongToRGBDevice:model.shortName]
                        || [CSRUtilities belongToRGBCWDevice:model.shortName]
                        || [CSRUtilities belongToTwoChannelDimmer:model.shortName]) {
                        self.levelLabel.text = @"0%";
                    }
                    
                }else {
                    if ([_groupId isEqualToNumber:@1000]  || [_groupId isEqualToNumber:@2000]) {
                        self.nameLabel.textColor = DARKORAGE;
                        self.levelLabel.textColor = DARKORAGE;
                    }else {
                        self.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1];
                    }
                    
                    if ([CSRUtilities belongToDimmer:model.shortName]
                        || [CSRUtilities belongToCWDevice:model.shortName]
                        || [CSRUtilities belongToRGBDevice:model.shortName]
                        || [CSRUtilities belongToRGBCWDevice:model.shortName]
                        || [CSRUtilities belongToTwoChannelDimmer:model.shortName]) {
                        if ([model.level floatValue]/255.0*100>0 && [model.level floatValue]/255.0*100 < 1.0) {
                            self.levelLabel.text = @"1%";
                            return;
                        }
                        self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[model.level floatValue]/255.0*100];
                    }
                }
            }
        }
    }else {
        if (!([CSRUtilities belongToSceneRemoteOneKey:model.shortName]
            || [CSRUtilities belongToSceneRemoteTwoKeys:model.shortName]
            || [CSRUtilities belongToSceneRemoteThreeKeys:model.shortName]
            || [CSRUtilities belongToSceneRemoteFourKeys:model.shortName]
            || [CSRUtilities belongToSceneRemoteSixKeys:model.shortName]
            || [CSRUtilities belongToSceneRemoteOneKeyV:model.shortName]
            || [CSRUtilities belongToSceneRemoteTwoKeysV:model.shortName]
            || [CSRUtilities belongToSceneRemoteThreeKeysV:model.shortName]
            || [CSRUtilities belongToSceneRemoteFourKeysV:model.shortName]
            || [CSRUtilities belongToSceneRemoteSixKeysV:model.shortName]
            || [CSRUtilities belongToMusicController:model.shortName]
            || [CSRUtilities belongToMusicControlRemote:model.shortName]
            || [CSRUtilities belongToMusicControlRemoteV:model.shortName]
            || [CSRUtilities belongToSonosMusicController:model.shortName]
            || [CSRUtilities belongToRGBRemote:model.shortName]
            || [CSRUtilities belongToRGBCWRemote:model.shortName]
            || [CSRUtilities belongToCWRemote:model.shortName]
            || [CSRUtilities belongToLCDRemote:model.shortName]
            || [CSRUtilities belongToPIRDevice:model.shortName])) {
            self.nameLabel.textColor = [UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1];
            self.levelLabel.textColor = [UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1];
            self.level2Label.textColor = [UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1];
            self.level3Label.textColor = [UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1];
        }
    }
}

- (void)adjustGroupCellBgcolorAndLevelLabel {
    __block NSInteger brightness = 0;
    if (self.groupMembers.count == 0) {
        self.nameLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        self.levelLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        self.backgroundColor = [UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1];
    }else {
        [self.groupMembers enumerateObjectsUsingBlock:^(CSRDeviceEntity *device, NSUInteger idx, BOOL * _Nonnull stop) {
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:device.deviceId];
            if ([model.powerState boolValue] && [model.level integerValue]>brightness && !model.isleave) {
                brightness = [model.level integerValue];
            }
        }];
        if (brightness) {
            self.nameLabel.textColor = DARKORAGE;
            self.levelLabel.textColor = DARKORAGE;
            self.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1];
            if (brightness/255.0*100>0 && brightness/255.0*100 < 1.0) {
                self.levelLabel.text = @"1%";
            }else {
                self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",brightness/255.0*100];
            }
        }else {
            self.nameLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
            self.levelLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
            self.backgroundColor = [UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1];
            self.levelLabel.text = @"0%";
        }
    }
    
}

- (void)setPowerStateSuccess:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([_deviceId isEqualToNumber:@2000]) {
        __block BOOL exist=0;
        [_groupMembers enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([deviceEntity.deviceId isEqualToNumber:deviceId]) {
                exist = YES;
                *stop = YES;
            }
        }];
        if (exist) {
            [self adjustGroupCellBgcolorAndLevelLabel];
        }
    }else if ([deviceId isEqualToNumber:_deviceId]) {
        [self adjustCellBgcolorAndLevelLabelWithDeviceId:deviceId];
    }
}

- (void)mainCellTapGestureAction:(UITapGestureRecognizer *)sender {
    if (!tapLimite) {
        tapLimite = YES;
        if (sender.state == UIGestureRecognizerStateEnded) {
            if (self.kindLabel.text.length > 0) {
                if ([self.deviceId isEqualToNumber:@1000] || [self.deviceId isEqualToNumber:@3000] || [self.deviceId isEqualToNumber:@4000]) {
                    if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateAddDeviceAction:cellIndexPath:)]) {
                        [self.superCellDelegate superCollectionViewCellDelegateAddDeviceAction:self.deviceId cellIndexPath:self.cellIndexPath];
                    }
                }else if ([self.deviceId isEqualToNumber:@2000]) {
                    if ([SoundListenTool sharedInstance].audioRecorder.recording) {
                        [[SoundListenTool sharedInstance] stopRecord:_groupId];
                    }
                    [[DeviceModelManager sharedInstance] invalidateColofulTimerWithDeviceId:_groupId];
                    
                    BOOL powerState = NO;
                    for (CSRDeviceEntity *d in _groupMembers) {
                        DeviceModel *m = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:d.deviceId];
                        if ([m.powerState boolValue]) {
                            powerState = YES;
                            break;
                        }
                    }
                    [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_groupId channel:@1 withPowerState:!powerState];
                    
                }else {
                    if ([SoundListenTool sharedInstance].audioRecorder.recording) {
                        [[SoundListenTool sharedInstance] stopRecord:_deviceId];
                    }
                    [[DeviceModelManager sharedInstance] invalidateColofulTimerWithDeviceId:_deviceId];
                    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                    if (![CSRUtilities belongToRGBCWRemote:deviceEntity.shortName]
                        &&![CSRUtilities belongToRGBRemote:deviceEntity.shortName]
                        &&![CSRUtilities belongToCWRemote:deviceEntity.shortName]
                        &&![CSRUtilities belongToSceneRemoteSixKeys:deviceEntity.shortName]
                        &&![CSRUtilities belongToSceneRemoteFourKeys:deviceEntity.shortName]
                        &&![CSRUtilities belongToSceneRemoteThreeKeys:deviceEntity.shortName]
                        &&![CSRUtilities belongToSceneRemoteTwoKeys:deviceEntity.shortName]
                        &&![CSRUtilities belongToSceneRemoteOneKey:deviceEntity.shortName]
                        &&![CSRUtilities belongToSceneRemoteSixKeysV:deviceEntity.shortName]
                        &&![CSRUtilities belongToSceneRemoteFourKeysV:deviceEntity.shortName]
                        &&![CSRUtilities belongToSceneRemoteThreeKeysV:deviceEntity.shortName]
                        &&![CSRUtilities belongToSceneRemoteTwoKeysV:deviceEntity.shortName]
                        &&![CSRUtilities belongToSceneRemoteOneKeyV:deviceEntity.shortName]
                        &&![CSRUtilities belongToLCDRemote:deviceEntity.shortName]
                        &&![CSRUtilities belongToMusicController:deviceEntity.shortName]
                        &&![CSRUtilities belongToSonosMusicController:deviceEntity.shortName]
                        &&![CSRUtilities belongToMusicControlRemote:deviceEntity.shortName]
                        &&![CSRUtilities belongToMusicControlRemoteV:deviceEntity.shortName]
                        &&![CSRUtilities belongToPIRDevice:deviceEntity.shortName]) {
                        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
                        [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId channel:@1 withPowerState:![model.powerState boolValue]];
                    }
                }
            }else {
                if ([self.deviceId isEqualToNumber:@2000]) {
                    if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateClickEmptyGroupCellAction:)]) {
                        [self.superCellDelegate superCollectionViewCellDelegateClickEmptyGroupCellAction:self.cellIndexPath];
                    }
                }
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            tapLimite = NO;
        });
    }
}

- (void)mainCellPanGestureAction:(UIPanGestureRecognizer *)sender {
    if (![self.groupId isEqualToNumber:@4000] && _adjustableBrightness) {
        CGPoint translation = [sender translationInView:self];
        CGPoint touchPoint = [sender locationInView:self.superview];
        
        switch (sender.state) {
            case UIGestureRecognizerStateBegan:
            {
                _direction = PanGestureMoveDirectionNone;
                
                if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegatePanBrightnessWithTouchPoint:withOrigin:toLight:groupId:withPanState:direction:)]) {
                    [self.superCellDelegate superCollectionViewCellDelegatePanBrightnessWithTouchPoint:touchPoint withOrigin:self.center toLight:self.deviceId groupId:self.groupId withPanState:sender.state direction:_direction];
                }
                break;
            }
            case UIGestureRecognizerStateChanged:
            {
                if (_direction == PanGestureMoveDirectionNone) {
                    _direction = [self determineCameraDirectionIfNeeded:translation];
                }
                if (_direction == PanGestureMoveDirectionHorizontal) {
                    if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegatePanBrightnessWithTouchPoint:withOrigin:toLight:groupId:withPanState:direction:)]) {
                        [self.superCellDelegate superCollectionViewCellDelegatePanBrightnessWithTouchPoint:touchPoint withOrigin:self.center toLight:self.deviceId groupId:self.groupId withPanState:sender.state direction:_direction];
                    }
                }
                
                break;
            }
            case UIGestureRecognizerStateEnded:
            {
                if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegatePanBrightnessWithTouchPoint:withOrigin:toLight:groupId:withPanState:direction:)]) {
                    [self.superCellDelegate superCollectionViewCellDelegatePanBrightnessWithTouchPoint:touchPoint withOrigin:self.center toLight:self.deviceId groupId:self.groupId withPanState:sender.state direction:_direction];
                }
                break;
            }
            default:
                break;
        }
    }
}

- (void)mainCellTwoFingersTapGestureAction:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.kindLabel.text.length > 0 && [self.deviceId isEqualToNumber:@2000]) {
            if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateTwoFingersTapAction:)]) {
                [self.superCellDelegate superCollectionViewCellDelegateTwoFingersTapAction:self.groupId];
            }
        }
    }
}

- (PanGestureMoveDirection)determineCameraDirectionIfNeeded:(CGPoint)translation {
    if (_direction != PanGestureMoveDirectionNone) {
        return _direction;
    }
    if (fabs(translation.x)>20.0) {
        BOOL gestureHorizontal = NO;
        if (translation.y == 0.0) {
            gestureHorizontal = YES;
        }else {
            gestureHorizontal = (fabs(translation.x / translation.y) > 5.0);
        }
        if (gestureHorizontal) {
            return PanGestureMoveDirectionHorizontal;
        }
    }else if (fabs(translation.y) > 20.0) {
        BOOL gestureVertical = NO;
        if (translation.x == 0.0) {
            gestureVertical = YES;
        }else {
            gestureVertical = (fabs(translation.y / translation.x) > 5.0);
        }
        if (gestureVertical) {
            return gestureVertical;
        }
        return _direction;
    }
    return _direction;
}

- (void)mainCellLongPressGestureAction:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateLongPressAction:)]) {
            [self.superCellDelegate superCollectionViewCellDelegateLongPressAction:self];
        }
    }
}

- (void)mainCellMovePanGestureAction:(UIPanGestureRecognizer *)sender {
    CGPoint touchAt = [sender locationInView:self.superview];
    if (sender.state == UIGestureRecognizerStateBegan) {
        distanceX = self.center.x - touchAt.x;
        distanceY = self.center.y - touchAt.y;
    }
    CGPoint touchPoint = CGPointMake(touchAt.x+distanceX, touchAt.y+distanceY);
    if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateMoveCellPanAction:touchPoint:)]) {
        [self.superCellDelegate superCollectionViewCellDelegateMoveCellPanAction:sender.state touchPoint:touchPoint];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer.view isKindOfClass:[UICollectionView class]]) {
        return YES;
    }
    return NO;
}

- (void)showDeleteBtnAndMoveImageView:(BOOL)value {
    self.deleteBtn.hidden = value;
    self.moveImageView.hidden = value;
}

- (IBAction)deleteMainCell:(UIButton *)sender {
    if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateDeleteDeviceAction:cellGroupId:)]) {
        [self.superCellDelegate superCollectionViewCellDelegateDeleteDeviceAction:self.deviceId cellGroupId:self.groupId];
    }
}

- (IBAction)selectAction:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    
    if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateSelectAction:)]) {
        [self.superCellDelegate superCollectionViewCellDelegateSelectAction:self];
    }
}

@end
