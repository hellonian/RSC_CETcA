//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRDeviceDetailsTableViewCell.h"

NSString * const CSRDeviceDetailTableViewCellIdentifier = @"deviceDetailTableViewCellIdentifier";

@implementation CSRDeviceDetailsTableViewCell

@synthesize batteryStaticLabel, batteryDynamicLabel, firmwareStaticLabel, firmwareDynamicLabel;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (NSString *)reuseIdentifier
{
    return CSRDeviceDetailTableViewCellIdentifier;
}


@end
