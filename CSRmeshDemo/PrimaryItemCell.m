//
//  PrimaryItemCell.m
//  BluetoothAcTEC
//
//  Created by hua on 10/11/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "PrimaryItemCell.h"
#import "CSRmeshDevice.h"

@interface PrimaryItemCell ()

@end

@implementation PrimaryItemCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)configureCellWithInfo:(id)info adjustSize:(CGSize)size {
    if ([info isKindOfClass:[CSRmeshDevice class]]) {
        CSRmeshDevice *device =  (CSRmeshDevice *)info;
        NSString *appearanceShortname = [[NSString alloc] initWithData:device.appearanceShortname encoding:NSUTF8StringEncoding];
        self.lightAddressLabel.text = appearanceShortname;
        if ([appearanceShortname containsString:@"D350BT"]) {
            self.itemPresentation.image = [UIImage imageNamed:@"dimmer_csr"];
        }
        if ([appearanceShortname containsString:@"S350BT"]) {
            self.itemPresentation.image = [UIImage imageNamed:@"switch_csr"];
        }
        if ([appearanceShortname containsString:@"RC350"]) {
            self.itemPresentation.image = [UIImage imageNamed:@"remoteIcon"];
        }
        if ([appearanceShortname containsString:@"RC351"]) {
            self.itemPresentation.image = [UIImage imageNamed:@"singleBtnRemote"];
        }
    }
    self.itemPresentation.layer.cornerRadius = size.width*0.5;
}


@end
