//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRGatewayTableViewCell.h"

NSString * const CSRGatewayTableViewCellIdentifier = @"gatewayCellIdentifier";

@implementation CSRGatewayTableViewCell

@synthesize iconImageView, gatewayNameLabel, gatewayIPLabel;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (NSString *)reuseIdentifier
{
    return CSRGatewayTableViewCellIdentifier;
}

@end
