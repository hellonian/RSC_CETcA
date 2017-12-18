//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRNewDeviceTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

NSString * const CSRNewDeviceTableViewCellIdentifier = @"newDeviceTableViewCellIdentifier";

@implementation CSRNewDeviceTableViewCell

@synthesize iconImageView, deviceNameLabel, deviceUUIDLabel, deviceActivityIndicator;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (NSString *)reuseIdentifier
{
    return CSRNewDeviceTableViewCellIdentifier;
}

@end
