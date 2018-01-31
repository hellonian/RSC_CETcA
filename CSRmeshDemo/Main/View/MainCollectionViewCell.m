//
//  MainCollectionViewCell.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MainCollectionViewCell.h"
#import "CSRDeviceEntity.h"
#import "CSRAreaEntity.h"
#import "DeviceModelManager.h"
#import "CSRmeshDevice.h"

typedef enum : NSUInteger {
    PanGestureMoveDirectionNone,
    PanGestureMoveDirectionVertical,
    PanGestureMoveDirectionHorizontal,
} PanGestureMoveDirection;

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
//    if ([info isKindOfClass:[NSString class]]) {
//        self.iconView.image = [UIImage imageNamed:@"dimmersingle"];
//        self.nameLabel.text = @"D350BT";
//    }
    if ([info isKindOfClass:[CSRAreaEntity class]]) {
        CSRAreaEntity *areaEntity = (CSRAreaEntity *)info;
        self.groupId = areaEntity.areaID;
        self.deviceId = @2000;
        
        self.groupMembers = [areaEntity.devices allObjects];
//        self.iconView.image = areaEntity.image;
        return;
    }
    
    if ([info isKindOfClass:[CSRDeviceEntity class]]) {
        
        CSRDeviceEntity *deviceEntity = (CSRDeviceEntity *)info;
        NSLog(@">> %@ >> %@ ",deviceEntity.name,deviceEntity.shortName);
        
        self.groupId = @1000;
        self.deviceId = deviceEntity.deviceId;
        self.nameLabel.hidden = NO;
        self.nameLabel.text = deviceEntity.name;
        self.kindLabel.hidden = NO;
        if ([deviceEntity.shortName isEqualToString:@"D350BT"]) {
            self.iconView.image = [UIImage imageNamed:@"dimmersingle"];
            self.kindLabel.text = @"Dimmer";
            self.levelLabel.hidden = NO;
        }
        if ([deviceEntity.shortName isEqualToString:@"S350BT"]) {
            self.iconView.image = [UIImage imageNamed:@"switchsingle"];
            self.kindLabel.text = @"Switch";
            self.levelLabel.hidden = YES;
        }
        self.cellIndexPath = indexPath;
        
        [self adjustCellBgcolorAndLevelLabelWithDeviceId:deviceEntity.deviceId];
        
        NSLog(@">> %d",self.hidden);
        
        return;
    }
    
    if ([info isKindOfClass:[NSNumber class]]) {
        self.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1];
        self.groupId = @4000;
        NSNumber *num = (NSNumber *)info;
        if ([num isEqualToNumber:@0]) {
            self.deviceId = @1000;
        }else if ([num isEqualToNumber:@1]) {
            self.deviceId = @4000;
        }
        self.iconView.image = [UIImage imageNamed:@"addroom"];
        self.cellIndexPath = indexPath;
        self.nameLabel.hidden = YES;
        self.kindLabel.hidden = YES;
        self.levelLabel.hidden = YES;
        self.deleteBtn.hidden = YES;
        self.moveImageView.hidden = YES;
        return;
    }
    
    if ([info isKindOfClass:[CSRmeshDevice class]]) {
        CSRmeshDevice *device = (CSRmeshDevice *)info;
        self.levelLabel.hidden = YES;
        self.groupId = @4000;
        self.deviceId = @3000;
        NSString *appearanceShortname = [[NSString alloc] initWithData:device.appearanceShortname encoding:NSUTF8StringEncoding];
        self.nameLabel.text = appearanceShortname;
        self.kindLabel.text = [NSString stringWithFormat:@"%@",device.appearanceValue];
        if ([appearanceShortname containsString:@"D350BT"]) {
            self.iconView.image = [UIImage imageNamed:@"dimmersingle"];
        }else if ([appearanceShortname containsString:@"S350BT"]) {
            self.iconView.image = [UIImage imageNamed:@"switchsingle"];
        }else if ([appearanceShortname containsString:@"RC350"]) {
            self.iconView.image = [UIImage imageNamed:@"remoteIcon"];
        }else if ([appearanceShortname containsString:@"RC351"]) {
            self.iconView.image = [UIImage imageNamed:@"singleBtnRemote"];
        }
        self.cellIndexPath = indexPath;
    }
    
}

- (void)adjustCellBgcolorAndLevelLabelWithDeviceId:(NSNumber *)deviceId {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
    if (![model.powerState boolValue]) {
        self.backgroundColor = [UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1];
        if ([model.shortName isEqualToString:@"D350BT"]) {
            self.levelLabel.text = @"0%";
        }
    }else {
        self.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1];
        if ([model.shortName isEqualToString:@"D350BT"]) {
            self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[model.level floatValue]/255.0*100];
        }
    }
}

- (void)setPowerStateSuccess:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        [self adjustCellBgcolorAndLevelLabelWithDeviceId:deviceId];
    }
}

- (void)mainCellTapGestureAction:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        NSLog(@"maincell00");
        if ([self.deviceId isEqualToNumber:@1000] || [self.deviceId isEqualToNumber:@3000] || [self.deviceId isEqualToNumber:@4000]) {
            if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateAddDeviceAction:cellIndexPath:)]) {
                [self.superCellDelegate superCollectionViewCellDelegateAddDeviceAction:self.deviceId cellIndexPath:self.cellIndexPath];
            }
        }
        else {
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
            [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId withPowerState:@(![model.powerState boolValue])];
        }
    }
}

- (void)mainCellPanGestureAction:(UIPanGestureRecognizer *)sender {
    if (![self.deviceId isEqualToNumber:@1000] && ![self.deviceId isEqualToNumber:@3000] && [self.kindLabel.text containsString:@"Dimmer"]) {
        CGPoint translation = [sender translationInView:self];
        CGPoint touchPoint = [sender locationInView:self.superview];
        switch (sender.state) {
            case UIGestureRecognizerStateBegan:
            {
                _direction = PanGestureMoveDirectionNone;
                
                if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegatePanBrightnessWithTouchPoint:withOrigin:toLight:withPanState:)]) {
                    [self.superCellDelegate superCollectionViewCellDelegatePanBrightnessWithTouchPoint:touchPoint withOrigin:self.center toLight:self.deviceId withPanState:sender.state];
                }
                break;
            }
            case UIGestureRecognizerStateChanged:
            {
                if (_direction == PanGestureMoveDirectionNone) {
                    _direction = [self determineCameraDirectionIfNeeded:translation];
                }
                if (_direction == PanGestureMoveDirectionHorizontal) {
                    if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegatePanBrightnessWithTouchPoint:withOrigin:toLight:withPanState:)]) {
                        [self.superCellDelegate superCollectionViewCellDelegatePanBrightnessWithTouchPoint:touchPoint withOrigin:self.center toLight:self.deviceId withPanState:sender.state];
                    }
                }
                
                break;
            }
            case UIGestureRecognizerStateEnded:
            {
                if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegatePanBrightnessWithTouchPoint:withOrigin:toLight:withPanState:)]) {
                    [self.superCellDelegate superCollectionViewCellDelegatePanBrightnessWithTouchPoint:touchPoint withOrigin:self.center toLight:self.deviceId withPanState:sender.state];
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
    if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateDeleteDeviceAction:)]) {
        [self.superCellDelegate superCollectionViewCellDelegateDeleteDeviceAction:self.deviceId];
    }
}



@end
