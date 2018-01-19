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

@interface MainCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *kindLabel;
@property (weak, nonatomic) IBOutlet UILabel *levelLabel;


@end

@implementation MainCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setPowerStateSuccess:) name:@"setPowerStateSuccess" object:nil];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mainCelltapGestureAction:)];

    [self addGestureRecognizer:tapGesture];
    
}

- (void)configureCellWithiInfo:(id)info {
    if ([info isKindOfClass:[NSString class]]) {
        self.iconView.image = [UIImage imageNamed:@"dimmersingle"];
        self.nameLabel.text = @"D350BT";
        
    }
    if ([info isKindOfClass:[CSRDeviceEntity class]]) {
        
        CSRDeviceEntity *deviceEntity = (CSRDeviceEntity *)info;
        self.deviceId = deviceEntity.deviceId;
        self.nameLabel.text = deviceEntity.name;
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
        
        [self adjustCellBgcolorAndLevelLabelWithDeviceId:deviceEntity.deviceId];
        
        return;
    }
    
    if ([info isKindOfClass:[NSNumber class]]) {
        self.deviceId = @1000;
        self.iconView.image = [UIImage imageNamed:@"addroom"];
        self.nameLabel.hidden = YES;
        self.kindLabel.hidden = YES;
        self.levelLabel.hidden = YES;
        return;
    }
    
    if ([info isKindOfClass:[CSRmeshDevice class]]) {
        CSRmeshDevice *device = (CSRmeshDevice *)info;
        self.levelLabel.hidden = YES;
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

- (void)mainCelltapGestureAction:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.superCellDelegate && [self.superCellDelegate respondsToSelector:@selector(superCollectionViewCellDelegateAddDeviceAction:)]) {
            [self.superCellDelegate superCollectionViewCellDelegateAddDeviceAction:_deviceId];
        } 
    }
}

@end
