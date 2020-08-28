//
//  LightClusterCell.m
//  BluetoothAcTEC
//
//  Created by hua on 10/8/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "LightClusterCell.h"
#import "LightGroupBringer.h"
#import "LightBringer.h"
//#import "ProfileManager.h"
#import "PureLayout.h"
//#import "BleSupportManager.h"
#import "UIView+DarkEffect.h"
#import "JQProgressView.h"
//#import "BlockCenter.h"
#import "CSRDeviceEntity.h"
#import "CSRmeshDevice.h"
#import "DeviceModel.h"
#import "CSRAreaEntity.h"
#import "AreaModel.h"

@interface LightClusterCell ()


@property (weak, nonatomic) IBOutlet JQProgressView *brightnessIndicator;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UILabel *profileNameLabel;
@property (nonatomic,strong) UIImage *normalImage;
@property (assign, nonatomic) BOOL animating;
@property (assign, nonatomic) CGFloat percentage;
@end

@implementation LightClusterCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.isAlloc = YES;
    self.brightnessIndicator.progressTintColor = DARKORAGE;
    [self.groupView configureWithItemPerSection:3 cellIdentifier:@"LightClusterCell"];
}

- (void)setSelected:(BOOL)selected {
    
}

- (void)setRoundCorner:(CGFloat)radius {
    self.lightPresentation.layer.cornerRadius = radius;
    //better to give the correct size directly
    self.groupView.bounds = CGRectMake(0, 0, radius*2, radius*2);
    self.groupView.layer.cornerRadius = radius;
}

- (IBAction)deleteAction:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(specialFlowLayoutCollectionViewSuperCell:didClickOnDeleteButton:)]) {
        [self.delegate specialFlowLayoutCollectionViewSuperCell:self didClickOnDeleteButton:sender];
    }
}

- (void)updateBrightnessPercentage:(CGFloat)percentage {
    if (_ignoreUpdate) {
        return;
    }
    
    [self updateBrightness:percentage];
}

- (void)updateBrightness:(CGFloat)percentage {
    
    [self updateBrightness:percentage animated:YES];
}

- (void)updateBrightness:(CGFloat)percentage animated:(BOOL)animated {
    NSTimeInterval animationTime = 0.4;
    if (percentage<0.001) {
        [self.lightPresentation darkerInDuration:animationTime];
    } else {
        [self.lightPresentation recoverFormDarkerInDuration:animationTime];
    }
    
    if (_percentage >= percentage-0.001 && _percentage < percentage+0.001) {
        return;
    }
    
    _percentage = percentage;
    if (self.isAlloc) {  //protect
        self.isAlloc = NO;
        self.brightnessIndicator.progress = percentage;
    }
    else {
        [self.brightnessIndicator setProgress:percentage animated:YES];
    }
}

- (void)showDeleteButton:(BOOL)show {
    if (!self.isGroup && [self.deviceID isEqualToNumber:@100000]) {
        return;
    };
    self.deleteButton.hidden = !show;
}

- (void)showGroupDismissButton:(BOOL)show {
    if (self.isGroup) {
        self.deleteButton.hidden = !show;
    }
}

- (BOOL)isGroupOrganizingSelected {
    return (!self.deleteButton.hidden)&&(!self.isGroup);
}

- (void)setIsGroup:(BOOL)isGroup {
    _isGroup = isGroup;
    
    NSString *name = isGroup? @"delete":@"minus";
    [self.deleteButton setImage:[UIImage imageNamed:name] forState:UIControlStateNormal];
}

- (void)configureCellWithInfo:(id)info adjustSize:(CGSize)size {
    self.lightPresentation.layer.cornerRadius = size.width * 0.5;
    self.groupView.layer.cornerRadius = size.width * 0.5;
    self.profileNameLabel.text = @"";
    
    if ([info isKindOfClass:[AreaModel class]]) {
        self.brightnessIndicator.hidden = YES;
        self.lightPresentation.hidden = YES;
        self.groupView.hidden = NO;
        
        AreaModel *areaModel = info;
        self.deleteButton.hidden = !areaModel.isShowDeleteBtn;
        self.profileNameLabel.text = areaModel.areaName;
        self.deviceID = @200000;
        self.groupMember = areaModel.devices;
        self.groupId = areaModel.areaID;
        self.isGroup = YES;
        self.name = areaModel.areaName;
        [self.groupView addLightWithAddress:areaModel.devices];
    }
    
    if ([info isKindOfClass:[NSNumber class]]) {
        self.lightPresentation.alpha = 1.0;
        self.deleteButton.hidden = YES;
        self.brightnessIndicator.hidden = YES;
        self.lightPresentation.hidden = NO;
        self.groupView.hidden = YES;
        
        NSNumber *num = info;
        UIImage *presentation = [num isEqualToNumber:@0] ? [UIImage imageNamed:@"icon_all_light_off.png"] : [UIImage imageNamed:@"icon_plus.png"];
        self.lightPresentation.image = presentation;
        
        self.deviceID = @100000;
        self.isGroup = NO;
        self.groupId = num;
        

        return;
    }

    if ([info isKindOfClass:[DeviceModel class]]) {
        self.brightnessIndicator.hidden = NO;
        self.lightPresentation.hidden = NO;
        self.groupView.hidden= YES;
        
        DeviceModel *device = info;
        self.deleteButton.hidden = !device.isShowDeleteBtn;
        
        if (device.isForGroup) {
            self.profileNameLabel.hidden = YES;
        }else {
            if (device.name != nil) {
                self.profileNameLabel.text = [NSString stringWithFormat:@"%@",device.name];
            }
        }
        
        
        self.deviceID = device.deviceId;
        self.isGroup = NO;
        self.isDimmer = [device.shortName isEqualToString:@"D350BT"];
        if ([device.shortName isEqualToString:@"D350BT"]) {
            self.lightPresentation.image = [UIImage imageNamed:@"dimmer_csr"];
            if ([device.powerState boolValue]) {
                [self.lightPresentation recoverFormDarkerInDuration:0];
                CGFloat percentage = [device.level floatValue]/255.0;
                if (self.isAlloc) {
                    self.brightnessIndicator.progress = percentage;
                }else {
                    [self.brightnessIndicator setProgress:percentage animated:YES];
                }
            }else {
                [self.lightPresentation darkerInDuration:0];
                [self.brightnessIndicator setProgress:0 animated:YES];
                
            }
        }
        if ([device.shortName isEqualToString:@"S350BT"]) {
            self.lightPresentation.image = [UIImage imageNamed:@"switch_csr"];
            self.brightnessIndicator.hidden = YES;
            if ([device.powerState boolValue]) {
                [self.lightPresentation recoverFormDarkerInDuration:0];
            }else {
                [self.lightPresentation darkerInDuration:0];
            }
        }
        return;
    }
    
}

- (void)showOfflineUI {
    self.brightnessIndicator.hidden = YES;
    self.alpha = 0.4;
    self.lightPresentation.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
//    [self.lightPresentation darkerInDuration:0.2];
}

- (void)removeOfflineUI {
    self.brightnessIndicator.hidden = NO;
//    [self.lightPresentation recoverFormDarkerInDuration:0.2];
    self.alpha = 1.0;
    self.lightPresentation.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1];
}

@end
