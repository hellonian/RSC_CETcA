//
//  SceneMemberCell.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/6/10.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SceneMemberCell.h"
#import "CSRUtilities.h"
#import "CSRDatabaseManager.h"

@implementation SceneMemberCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureCellWithSceneMember:(SceneMemberEntity *)member{
    _mSceneMember = member;
    if ([member.editing boolValue]) {
        _removeBtn.hidden = NO;
    }else {
        _removeBtn.hidden = YES;
    }
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
    _nameLabel.text = deviceEntity.name;
    _label3.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
    if ([CSRUtilities belongToSwitch:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_switch1"];
        _channelLabel.hidden = YES;
        _imgv2.hidden = YES;
        _label2.hidden = YES;
        _imgv3.hidden = YES;
        _label3.hidden = YES;
        _imgv1.image = [UIImage imageNamed:@"Ico_power"];
        if ([member.eveType integerValue] == 16) {
            _label1.text = @"ON";
        }else {
            _label1.text = @"OFF";
        }
    }else if ([CSRUtilities belongToTwoChannelSwitch:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_switch2"];
        _channelLabel.hidden = NO;
        _imgv2.hidden = YES;
        _label2.hidden = YES;
        _imgv3.hidden = YES;
        _label3.hidden = YES;
        if ([member.channel integerValue] == 1) {
            _channelLabel.text = AcTECLocalizedStringFromTable(@"Channel1", @"Localizable");
        }else if ([member.channel integerValue] == 2) {
            _channelLabel.text = AcTECLocalizedStringFromTable(@"Channel2", @"Localizable");
        }
        _imgv1.image = [UIImage imageNamed:@"Ico_power"];
        if ([member.eveType integerValue] == 16) {
            _label1.text = @"ON";
        }else {
            _label1.text = @"OFF";
        }
    }else if ([CSRUtilities belongToThreeChannelSwitch:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_switch3"];
        _channelLabel.hidden = NO;
        _imgv2.hidden = YES;
        _label2.hidden = YES;
        _imgv3.hidden = YES;
        _label3.hidden = YES;
        if ([member.channel integerValue] == 1) {
            _channelLabel.text = AcTECLocalizedStringFromTable(@"Channel1", @"Localizable");
        }else if ([member.channel integerValue] == 2) {
            _channelLabel.text = AcTECLocalizedStringFromTable(@"Channel2", @"Localizable");
        }else if ([member.channel integerValue] == 4) {
            _channelLabel.text = AcTECLocalizedStringFromTable(@"Channel3", @"Localizable");
        }
        _imgv1.image = [UIImage imageNamed:@"Ico_power"];
        if ([member.eveType integerValue] == 16) {
            _label1.text = @"ON";
        }else {
            _label1.text = @"OFF";
        }
    }else if ([CSRUtilities belongToDimmer:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_dimmer1"];
        _channelLabel.hidden = YES;
        _imgv3.hidden = YES;
        _label3.hidden = YES;
        _imgv1.image = [UIImage imageNamed:@"Ico_power"];
        if ([member.eveType integerValue] == 17) {
            _label1.text = @"OFF";
            _imgv2.hidden = YES;
            _label2.hidden = YES;
        }else if ([member.eveType integerValue] == 18) {
            _label1.text = @"ON";
            _imgv2.hidden = NO;
            _label2.hidden = NO;
            _imgv2.image = [UIImage imageNamed:@"Ico_sun"];
            _label2.text = [NSString stringWithFormat:@"%.f %%",[member.eveD0 integerValue]/255.0*100];
        }
    }else if ([CSRUtilities belongToTwoChannelDimmer:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_dimmer2"];
        _channelLabel.hidden = NO;
        _imgv3.hidden = YES;
        _label3.hidden = YES;
        if ([member.channel integerValue] == 1) {
            _channelLabel.text = AcTECLocalizedStringFromTable(@"Channel1", @"Localizable");
        }else if ([member.channel integerValue] == 2) {
            _channelLabel.text = AcTECLocalizedStringFromTable(@"Channel2", @"Localizable");
        }
        _imgv1.image = [UIImage imageNamed:@"Ico_power"];
        if ([member.eveType integerValue] == 17) {
            _label1.text = @"OFF";
            _imgv2.hidden = YES;
            _label2.hidden = YES;
        }else if ([member.eveType integerValue] == 18) {
            _label1.text = @"ON";
            _imgv2.hidden = NO;
            _label2.hidden = NO;
            _imgv2.image = [UIImage imageNamed:@"Ico_sun"];
            _label2.text = [NSString stringWithFormat:@"%.f %%",[member.eveD0 integerValue]/255.0*100];
        }
    }else if ([CSRUtilities belongToCWDevice:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_rgb"];
        _channelLabel.hidden = YES;
        _imgv1.image = [UIImage imageNamed:@"Ico_power"];
        if ([member.eveType integerValue] == 17) {
            _label1.text = @"OFF";
            _imgv2.hidden = YES;
            _label2.hidden = YES;
            _imgv3.hidden = YES;
            _label3.hidden = YES;
        }else if ([member.eveType integerValue] == 25) {
            _label1.text = @"ON";
            _imgv2.hidden = NO;
            _label2.hidden = NO;
            _imgv3.hidden = NO;
            _label3.hidden = NO;
            _imgv2.image = [UIImage imageNamed:@"Ico_sun"];
            _label2.text = [NSString stringWithFormat:@"%.f %%",[member.eveD0 integerValue]/255.0*100];
            _imgv3.image = [UIImage imageNamed:@"Ico_cw"];
            NSString *s = [NSString stringWithFormat:@"%@%@",[CSRUtilities stringWithHexNumber:[member.eveD1 integerValue]],[CSRUtilities stringWithHexNumber:[member.eveD2 integerValue]]];
            NSInteger t = [CSRUtilities numberWithHexString:s];
            _label3.text = [NSString stringWithFormat:@"%ld K",t];
        }
    }else if ([CSRUtilities belongToRGBDevice:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_rgb"];
        _channelLabel.hidden = YES;
        _imgv1.image = [UIImage imageNamed:@"Ico_power"];
        if ([member.eveType integerValue] == 17) {
            _label1.text = @"OFF";
            _imgv2.hidden = YES;
            _label2.hidden = YES;
            _imgv3.hidden = YES;
            _label3.hidden = YES;
        }else if ([member.eveType integerValue] == 20) {
            _label1.text = @"ON";
            _imgv2.hidden = NO;
            _label2.hidden = NO;
            _imgv3.hidden = NO;
            _label3.hidden = NO;
            _imgv2.image = [UIImage imageNamed:@"Ico_sun"];
            _label2.text = [NSString stringWithFormat:@"%.f %%",[member.eveD0 integerValue]/255.0*100];
            _imgv3.image = [UIImage imageNamed:@"Ico_color"];
            _label3.text = @"●";
            _label3.textColor = [UIColor colorWithRed:[member.eveD1 integerValue]/255.0 green:[member.eveD2 integerValue]/255.0 blue:[member.eveD3 integerValue]/255.0 alpha:1];
        }
    }else if ([CSRUtilities belongToRGBCWDevice:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_rgb"];
        _channelLabel.hidden = YES;
        _imgv1.image = [UIImage imageNamed:@"Ico_power"];
        if ([member.eveType integerValue] == 17) {
            _label1.text = @"OFF";
            _imgv2.hidden = YES;
            _label2.hidden = YES;
            _imgv3.hidden = YES;
            _label3.hidden = YES;
        }else if ([member.eveType integerValue] == 25) {
            _label1.text = @"ON";
            _imgv2.hidden = NO;
            _label2.hidden = NO;
            _imgv3.hidden = NO;
            _label3.hidden = NO;
            _imgv2.image = [UIImage imageNamed:@"Ico_sun"];
            _label2.text = [NSString stringWithFormat:@"%.f %%",[member.eveD0 integerValue]/255.0*100];
            _imgv3.image = [UIImage imageNamed:@"Ico_cw"];
            NSString *s = [NSString stringWithFormat:@"%@%@",[CSRUtilities stringWithHexNumber:[member.eveD1 integerValue]],[CSRUtilities stringWithHexNumber:[member.eveD2 integerValue]]];
            NSInteger t = [CSRUtilities numberWithHexString:s];
            _label3.text = [NSString stringWithFormat:@"%ld K",t];
        }else if ([member.eveType integerValue] == 20) {
            _label1.text = @"ON";
            _imgv2.hidden = NO;
            _label2.hidden = NO;
            _imgv3.hidden = NO;
            _label3.hidden = NO;
            _imgv2.image = [UIImage imageNamed:@"Ico_sun"];
            _label2.text = [NSString stringWithFormat:@"%.f %%",[member.eveD0 integerValue]/255.0*100];
            _imgv3.image = [UIImage imageNamed:@"Ico_color"];
            _label3.text = @"●";
            _label3.textColor = [UIColor colorWithRed:[member.eveD1 integerValue]/255.0 green:[member.eveD2 integerValue]/255.0 blue:[member.eveD3 integerValue]/255.0 alpha:1];
        }
    }else if ([CSRUtilities belongToSocketOneChannel:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_socket1"];
        _channelLabel.hidden = YES;
        _imgv2.hidden = NO;
        _label2.hidden = NO;
        _imgv3.hidden = YES;
        _label3.hidden = YES;
        _imgv1.image = [UIImage imageNamed:@"Ico_power"];
        if ([member.eveD0 boolValue]) {
            _label1.text = @"ON";
        }else {
            _label1.text = @"OFF";
        }
        _imgv2.image = [UIImage imageNamed:@"Ico_suo"];
        if ([member.eveD1 boolValue]) {
            _label2.text = @"ON";
        }else {
            _label2.text = @"OFF";
        }
    }else if ([CSRUtilities belongToSocketTwoChannel:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_socket2"];
        _channelLabel.hidden = NO;
        _imgv2.hidden = NO;
        _label2.hidden = NO;
        _imgv3.hidden = YES;
        _label3.hidden = YES;
        if ([member.channel integerValue] == 1) {
            _channelLabel.text = AcTECLocalizedStringFromTable(@"Channel1", @"Localizable");
        }else if ([member.channel integerValue] == 2) {
            _channelLabel.text = AcTECLocalizedStringFromTable(@"Channel2", @"Localizable");
        }
        _imgv1.image = [UIImage imageNamed:@"Ico_power"];
        if ([member.eveD0 boolValue]) {
            _label1.text = @"ON";
        }else {
            _label1.text = @"OFF";
        }
        _imgv2.image = [UIImage imageNamed:@"Ico_suo"];
        if ([member.eveD1 boolValue]) {//colorRed存储儿童模式开启状态
            _label2.text = @"ON";
        }else {
            _label2.text = @"OFF";
        }
    }else if ([CSRUtilities belongToOneChannelCurtainController:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_curtain"];
        _channelLabel.hidden = YES;
        _imgv3.hidden = YES;
        _label3.hidden = YES;
        _imgv1.image = [UIImage imageNamed:@"Ico_power"];
        if ([member.eveType integerValue] == 17) {
            _label1.text = @"OFF";
            _imgv2.hidden = YES;
            _label2.hidden = YES;
        }else if ([member.eveType integerValue] == 18) {
            _label1.text = @"ON";
            _imgv2.hidden = NO;
            _label2.hidden = NO;
            _imgv2.image = [UIImage imageNamed:@"Ico_cur"];
            _label2.text = [NSString stringWithFormat:@"%.f %%",(255 - [member.eveD0 integerValue])/255.0*100];
        }
    }else if ([CSRUtilities belongToTwoChannelCurtainController:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_curtain"];
        _channelLabel.hidden = NO;
        _imgv3.hidden = YES;
        _label3.hidden = YES;
        if ([member.channel integerValue] == 1) {
            _channelLabel.text = AcTECLocalizedStringFromTable(@"Channel1", @"Localizable");
        }else if ([member.channel integerValue] == 2) {
            _channelLabel.text = AcTECLocalizedStringFromTable(@"Channel2", @"Localizable");
        }
        _imgv1.image = [UIImage imageNamed:@"Ico_power"];
        if ([member.eveType integerValue] == 17) {
            _label1.text = @"OFF";
            _imgv2.hidden = YES;
            _label2.hidden = YES;
        }else if ([member.eveType integerValue] == 18) {
            _label1.text = @"ON";
            _imgv2.hidden = NO;
            _label2.hidden = NO;
            _imgv2.image = [UIImage imageNamed:@"Ico_cur"];
            _label2.text = [NSString stringWithFormat:@"%.f %%",(255 - [member.eveD0 integerValue])/255.0*100];
        }
    }else if ([CSRUtilities belongToFanController:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_fan"];
        _channelLabel.hidden = YES;
        _imgv2.hidden = NO;
        _label2.hidden = NO;
        _imgv3.hidden = NO;
        _label3.hidden = NO;
        _imgv1.image = [UIImage imageNamed:@"Ico_power"];
        if ([member.eveD0 boolValue]) {
            _label1.text = @"ON";
        }else {
            _label1.text = @"OFF";
        }
        _imgv2.image = [UIImage imageNamed:@"Ico_fengli"];
        if ([member.eveD1 integerValue] == 0) {
            _label2.text = AcTECLocalizedStringFromTable(@"low", @"Localizable");
        }else if ([member.eveD1 integerValue] == 1) {
            _label2.text = AcTECLocalizedStringFromTable(@"medium", @"Localizable");
        }else if ([member.eveD1 integerValue] == 2) {
            _label2.text = AcTECLocalizedStringFromTable(@"high", @"Localizable");
        }
        _imgv3.image = [UIImage imageNamed:@"Ico_lamp"];
        if ([member.eveD2 boolValue]) {
            _label3.text = @"ON";
        }else {
            _label3.text = @"OFF";
        }
    }
    
    
}

- (IBAction)removeAction:(UIButton *)sender {
    if (self.cellDelegate && [self.cellDelegate respondsToSelector:@selector(removeSceneMember:)]) {
        [self.cellDelegate removeSceneMember:_mSceneMember];
    }
}


@end
