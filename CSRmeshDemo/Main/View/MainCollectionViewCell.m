//
//  MainCollectionViewCell.m
//  CSRmeshDemo
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

@interface MainCollectionViewCell ()<UIGestureRecognizerDelegate>
{
    CGFloat distanceX;
    CGFloat distanceY;
}

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *kindLabel;
@property (weak, nonatomic) IBOutlet UILabel *levelLabel;
@property (nonatomic,assign) PanGestureMoveDirection direction;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (weak, nonatomic) IBOutlet UIImageView *moveImageView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;

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

    [self addGestureRecognizer:tapGesture];
    [self addGestureRecognizer:panGesture];
    [self addGestureRecognizer:longPressGesture];
    
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
        if ([areaEntity.areaName isEqualToString:@"Living room"] || [areaEntity.areaName isEqualToString:@"Bed room"] || [areaEntity.areaName isEqualToString:@"Dining room"] || [areaEntity.areaName isEqualToString:@"Toilet"] || [areaEntity.areaName isEqualToString:@"Kitchen"]) {
            self.nameLabel.text = AcTECLocalizedStringFromTable(areaEntity.areaName, @"Localizable");
        }else {
            self.nameLabel.text = areaEntity.areaName;
        }
        self.kindLabel.hidden = NO;
        NSString *kind;
        for (CSRDeviceEntity *deviceEntity in self.groupMembers) {
            NSString *str = [CSRUtilities belongToDimmer:deviceEntity.shortName]? AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable"):AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            if (kind.length>0) {
                kind = [NSString stringWithFormat:@"%@ %@",kind,str];
            }else {
                kind = str;
            }
        }
        self.kindLabel.text = kind;
        if ([kind containsString:AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable")]) {
            self.levelLabel.hidden = NO;
        }else {
            self.levelLabel.hidden = YES;
        }
        
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
        if ([model.areaName isEqualToString:@"Living room"] || [model.areaName isEqualToString:@"Bed room"] || [model.areaName isEqualToString:@"Dining room"] || [model.areaName isEqualToString:@"Toilet"] || [model.areaName isEqualToString:@"Kitchen"]) {
            self.nameLabel.text = AcTECLocalizedStringFromTable(model.areaName, @"Localizable");
        }else {
            self.nameLabel.text = model.areaName;
        }
        self.kindLabel.hidden = NO;
        NSString *kind;
        for (CSRDeviceEntity *deviceEntity in self.groupMembers) {
            NSString *str = [CSRUtilities belongToDimmer:deviceEntity.shortName]? AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable"):AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            if (kind.length>0) {
                kind = [NSString stringWithFormat:@"%@ %@",kind,str];
            }else {
                kind = str;
            }
        }
        self.kindLabel.text = kind;
        if ([kind containsString:AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable")]) {
            self.levelLabel.hidden = NO;
        }else {
            self.levelLabel.hidden = YES;
        }
        
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
            if (model.isSelected) {
                self.selected = YES;
                [self.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
            }else {
                self.selected = NO;
                [self.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
            }
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
            self.iconView.image = [UIImage imageNamed:@"dimmersingle"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            self.levelLabel.hidden = NO;
        }
        if ([CSRUtilities belongToSwitch:deviceEntity.shortName]) {
            self.iconView.image = [UIImage imageNamed:@"switchsingle"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            self.levelLabel.hidden = YES;
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
            self.iconView.image = [UIImage imageNamed:@"Device_Dimmer"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable");
            self.levelLabel.hidden = NO;
        }
        if ([CSRUtilities belongToSwitch:device.deviceShortName]) {
            self.iconView.image = [UIImage imageNamed:@"Device_Switch"];
            self.kindLabel.text = AcTECLocalizedStringFromTable(@"Switch", @"Localizable");
            self.levelLabel.hidden = YES;
        }
        self.cellIndexPath = indexPath;
        self.bottomView.hidden = YES;
        [self adjustCellBgcolorAndLevelLabelWithDeviceId:device.deviceId];
        if (device.isForList) {
            self.seleteButton.hidden = NO;
            if (device.isSelected) {
                self.selected = YES;
                [self.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
            }else {
                self.selected = NO;
                [self.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
            }
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
        return;
    }
    
    if ([info isKindOfClass:[CSRmeshDevice class]]) {
        CSRmeshDevice *device = (CSRmeshDevice *)info;
        self.levelLabel.hidden = YES;
        self.groupId = @4000;
        self.deviceId = @3000;
        NSString *appearanceShortname = [[NSString alloc] initWithData:device.appearanceShortname encoding:NSUTF8StringEncoding];
        //去除不易察觉的空格
        appearanceShortname = [appearanceShortname stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
        self.nameLabel.text = appearanceShortname;
        self.kindLabel.text = [NSString stringWithFormat:@"%@",[device.uuid.UUIDString substringFromIndex:24]];
        if ([CSRUtilities belongToDimmer:appearanceShortname]) {
            self.iconView.image = [UIImage imageNamed:@"Device_Dimmer"];
        }else if ([CSRUtilities belongToSwitch:appearanceShortname]) {
            self.iconView.image = [UIImage imageNamed:@"Device_Switch"];
        }else if ([appearanceShortname containsString:@"RB01"]) {
            self.iconView.image = [UIImage imageNamed:@"Device_Remote1"];
        }else if ([appearanceShortname containsString:@"RB02"]) {
            self.iconView.image = [UIImage imageNamed:@"Device_Remote2"];
        }else if ([appearanceShortname isEqualToString:@"SL02B"]){
            self.iconView.image = [UIImage imageNamed:@"Device_Sensor"];
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
        self.deleteBtn.hidden = YES;
        self.moveImageView.hidden = YES;
        self.bottomView.hidden = YES;
        NSString *iconString = kSceneIcons[[model.iconId integerValue]];
        self.iconView.image = [UIImage imageNamed:[NSString stringWithFormat:@"Scene_%@_select",iconString]];
        self.nameLabel.text = model.sceneName;
        self.sceneId = model.rcIndex;
        self.groupId = @2000;
        self.deviceId = @1000;
        self.seleteButton.hidden = NO;
        self.seleteButton.hidden = NO;
        if (model.isSelected) {
            self.selected = YES;
            [self.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
        }else {
            self.selected = NO;
            [self.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
        }
        return;
    }
    
}

- (void)adjustCellBgcolorAndLevelLabelWithDeviceId:(NSNumber *)deviceId {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
    if (!model.isleave) {
        if (![model.powerState boolValue]) {
            if ([_groupId isEqualToNumber:@1000]) {
                self.nameLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
                self.levelLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
            }else {
                self.backgroundColor = [UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1];
            }
            
            if ([CSRUtilities belongToDimmer:model.shortName]) {
                self.levelLabel.text = @"0%";
            }
        }else {
            if ([_groupId isEqualToNumber:@1000]) {
                self.nameLabel.textColor = DARKORAGE;
                self.levelLabel.textColor = DARKORAGE;
            }else {
                self.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1];
            }
            
            if ([CSRUtilities belongToDimmer:model.shortName]) {
                if ([model.level floatValue]/255.0*100>0 && [model.level floatValue]/255.0*100 < 1.0) {
                    self.levelLabel.text = @"1%";
                    return;
                }
                self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[model.level floatValue]/255.0*100];
            }
        }
        
    }else {
        self.nameLabel.textColor = [UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1];;
        self.levelLabel.textColor = [UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1];;
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

- (void)adjustGroupCellBgcolorAndLevelLabel:(NSNumber *)deviceId {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
    
    if ([model.powerState boolValue]) {
        self.nameLabel.textColor = DARKORAGE;
        self.levelLabel.textColor = DARKORAGE;
        self.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1];
        if ([model.level floatValue]/255.0*100>0 && [model.level floatValue]/255.0*100 < 1.0) {
            self.levelLabel.text = @"1%";
        }else {
            self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[model.level integerValue]/255.0*100];
        }
    }else {
        self.nameLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        self.levelLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        self.backgroundColor = [UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1];
        self.levelLabel.text = @"0%";
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
            [self adjustGroupCellBgcolorAndLevelLabel:deviceId];
        }
    }else if ([deviceId isEqualToNumber:_deviceId]) {
        [self adjustCellBgcolorAndLevelLabelWithDeviceId:deviceId];
    }
}

- (void)mainCellTapGestureAction:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        NSLog(@"maincell00 groupId:%@ deviceId:%@",_groupId,_deviceId);
        if (self.kindLabel.text.length > 0) {
            if ([self.deviceId isEqualToNumber:@1000] || [self.deviceId isEqualToNumber:@3000] || [self.deviceId isEqualToNumber:@4000]) {
                if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateAddDeviceAction:cellIndexPath:)]) {
                    [self.superCellDelegate superCollectionViewCellDelegateAddDeviceAction:self.deviceId cellIndexPath:self.cellIndexPath];
                }
            }else if ([self.deviceId isEqualToNumber:@2000]) {
                __block BOOL isPowerOn = 0;
                __block NSInteger brightest = 0;
                [self.groupMembers enumerateObjectsUsingBlock:^(CSRDeviceEntity *entity, NSUInteger idx, BOOL * _Nonnull stop) {
                    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:entity.deviceId];
                    if ([model.powerState boolValue] && !model.isleave) {
                        isPowerOn = YES;
                    }
                    if ([model.level integerValue]>brightest) {
                        brightest = [model.level integerValue];
                    }
                }];
                if (!isPowerOn) {
                    [[LightModelApi sharedInstance] setLevel:self.groupId level:@(brightest) success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                        
                    } failure:^(NSError * _Nullable error) {
                        
                    }];
                }else {
                    [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:self.groupId withPowerState:@(0)];
                }
                
                
            }else {
                DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
                [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId withPowerState:@(![model.powerState boolValue])];
            }
        }else {
            if ([self.deviceId isEqualToNumber:@2000]) {
                if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateClickEmptyGroupCellAction:)]) {
                    [self.superCellDelegate superCollectionViewCellDelegateClickEmptyGroupCellAction:self.cellIndexPath];
                }
            }
        }
        
        
    }
}

- (void)mainCellPanGestureAction:(UIPanGestureRecognizer *)sender {
    if (![self.groupId isEqualToNumber:@4000] && [self.kindLabel.text containsString:AcTECLocalizedStringFromTable(@"Dimmer", @"Localizable")]) {
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
    
    self.selected = !self.selected;
    if (self.selected) {
        [self.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
    }else {
        [self.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
    }
    
    if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateSelectAction:)]) {
        [self.superCellDelegate superCollectionViewCellDelegateSelectAction:self];
    }
    /*
    if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateSelectAction:cellGroupId:cellSceneId:)]) {
        [self.superCellDelegate superCollectionViewCellDelegateSelectAction:self.deviceId cellGroupId:self.groupId cellSceneId:self.sceneId];
    }
    */
}

@end
