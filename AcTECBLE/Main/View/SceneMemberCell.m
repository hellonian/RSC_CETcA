//
//  SceneMemberCell.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/6/10.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "SceneMemberCell.h"
#import "CSRUtilities.h"
#import "CSRDatabaseManager.h"
#import "CSRConstants.h"
#import "DeviceModelManager.h"

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
    }else if ([CSRUtilities belongToThreeChannelDimmer:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_dimmer3"];
        _channelLabel.hidden = NO;
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
            _label3.text = [NSString stringWithFormat:@"%ld K",[member.eveD2 integerValue]*256+[member.eveD1 integerValue]];
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
            _label3.text = [NSString stringWithFormat:@"%ld K",[member.eveD2 integerValue]*256+[member.eveD1 integerValue]];
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
    }else if ([CSRUtilities belongToOneChannelCurtainController:member.kindString]
              || [CSRUtilities belongToHOneChannelCurtainController:member.kindString]) {
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
    }else if ([CSRUtilities belongToMusicController:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_bajiao"];
        _channelLabel.hidden = NO;
        _imgv2.hidden = NO;
        _label2.hidden = NO;
        _imgv3.hidden = NO;
        _label3.hidden = NO;
        NSString *hex = [CSRUtilities stringWithHexNumber:[member.channel integerValue]];
        NSString *bin = [CSRUtilities getBinaryByhex:hex];
        for (int i = 0; i < [bin length]; i ++) {
            NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
            if ([bit boolValue]) {
                _channelLabel.text = [NSString stringWithFormat:@"%@ %d",AcTECLocalizedStringFromTable(@"channel", @"Localizable"), i];
                break;
            }
        }
        
        _imgv1.image = nil;
        _imgv2.image = nil;
        _imgv3.image = nil;
        _label1.text = @"";
        _label2.text = @"";
        _label3.text = @"";
        
        NSInteger et = [member.eveType integerValue];
        if (et & 0x01) {
            _label1.text = ([member.eveD0 integerValue] & 0x01) ? @"ON":@"OFF";
        }
        
        if (et & 0x4) {
            NSInteger is = ([member.eveD0 integerValue] & 0x1c) >> 2;
            if ([_label1.text length] > 0) {
                _label1.text = [NSString stringWithFormat:@"%@  %@",_label1.text,AUDIOSOURCES[is]];
            }else {
                _label1.text = [NSString stringWithFormat:@"%@",AUDIOSOURCES[is]];
            }
        }
        
        if (et & 0x02) {
            _label2.text = ([member.eveD0 integerValue] & 0x02) ? @"Play":@"Stop";
        }
        
        if (et & 0x08) {
            NSInteger ic = ([member.eveD0 integerValue] & 0xe0) >> 5;
            if (ic < 5) {
                if ([_label2.text length] > 0) {
                    _label2.text = [NSString stringWithFormat:@"%@ %@",_label2.text,PLAYMODE[ic-1]];
                }else {
                    _label2.text = [NSString stringWithFormat:@"%@",PLAYMODE[ic-1]];
                }
            }
        }
        
        if (et & 0x10) {
            _label3.text = @"Mute";
        }else if (et & 0x20) {
            NSInteger iv = ([member.eveD1 integerValue] & 0xfe) >> 1;
            _label3.text = [NSString stringWithFormat:@"%ld",iv];
        }
    }else if ([CSRUtilities belongToSonosMusicController:member.kindString]) {
        _icon.image = [UIImage imageNamed:@"icon_sonos"];
        _channelLabel.hidden = NO;
        NSString *hex = [CSRUtilities stringWithHexNumber:[member.channel integerValue]];
        NSString *bin = [CSRUtilities getBinaryByhex:hex];
        NSString *str;
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:member.deviceID];
        for (int i=0; i<[bin length]; i++) {
            NSString *bit = [bin substringWithRange:NSMakeRange([bin length]-1-i, 1)];
            if ([bit boolValue]) {
                for (SonosEntity *s in device.sonoss) {
                    if ([s.channel integerValue] == i) {
                        if ([str length]>0) {
                            str = [NSString stringWithFormat:@"%@, %@",str, s.name];
                        }else {
                            str = s.name;
                        }
                        break;
                    }
                }
            }
        }
        _channelLabel.text = str;
        
        _imgv1.image = nil;
        _imgv2.image = nil;
        _imgv3.image = nil;
        _label1.text = @"";
        _label2.text = @"";
        _label3.text = @"";
        
        NSInteger et = [member.eveType integerValue];
        /*
        if (et & 0x40) {
            if ([device.remoteBranch length]>0) {
                NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:device.remoteBranch];
                if ([jsonDictionary count]>0) {
                    NSArray *songs = jsonDictionary[@"song"];
                    for (NSDictionary *dic in songs) {
                        NSInteger n = [dic[@"id"] integerValue];
                        if (n == [member.eveD2 integerValue]) {
                            _label1.text = dic[@"name"];
                            break;
                        }
                    }
                }
            }
        }
        
        if (et & 0x02) {
            _label2.text = ([member.eveD0 integerValue] & 0x02) ? @"Play":@"Stop";
        }
        
        if (et & 0x03) {
            NSInteger ic = ([member.eveD0 integerValue] & 0xe0) >> 5;
            if (ic>2) {
                ic = ic-1;
            }
            if (ic<4) {
                if ([_label2.text length] > 0) {
                    _label2.text = [NSString stringWithFormat:@"%@ %@",_label2.text,PLAYMODE[ic]];
                }else {
                    _label2.text = [NSString stringWithFormat:@"%@",PLAYMODE[ic]];
                }
            }
        }
        
        if (et & 0x10) {
            _label3.text = @"Mute";
        }else if (et & 0x20) {
            NSInteger iv = ([member.eveD1 integerValue] & 0xfe) >> 1;
            _label3.text = [NSString stringWithFormat:@"%ld",iv];
        }*/
        if (et == 130) {
            _label2.text = @"Stop";
        }else if (et == 226) {
            if ([device.remoteBranch length]>0) {
                NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:device.remoteBranch];
                if ([jsonDictionary count]>0) {
                    NSArray *songs = jsonDictionary[@"song"];
                    for (NSDictionary *dic in songs) {
                        NSInteger n = [dic[@"id"] integerValue];
                        if (n == [member.eveD2 integerValue]) {
                            _label1.text = dic[@"name"];
                            break;
                        }
                    }
                }
            }
            _label2.text = @"Play";
            NSInteger iv = ([member.eveD1 integerValue] & 0xfe) >> 1;
            _label3.text = [NSString stringWithFormat:@"%ld",iv];
        }
        
    }
}

- (IBAction)removeAction:(UIButton *)sender {
    if (self.cellDelegate && [self.cellDelegate respondsToSelector:@selector(removeSceneMember:)]) {
        [self.cellDelegate removeSceneMember:_mSceneMember];
    }
}


- (NSString *)fixBinStringEightLenth:(NSString *)bin {
    switch ([bin length]) {
        case 7:
            bin = [NSString stringWithFormat:@"0%@",bin];
            break;
        case 6:
            bin = [NSString stringWithFormat:@"00%@",bin];
            break;
        case 5:
            bin = [NSString stringWithFormat:@"000%@",bin];
            break;
        case 4:
            bin = [NSString stringWithFormat:@"0000%@",bin];
            break;
        case 3:
            bin = [NSString stringWithFormat:@"00000%@",bin];
            break;
        case 2:
            bin = [NSString stringWithFormat:@"000000%@",bin];
            break;
        case 1:
            bin = [NSString stringWithFormat:@"0000000%@",bin];
            break;
        default:
            break;
    }
    return bin;
}

@end
