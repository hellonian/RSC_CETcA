//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRGatewayDetailsTableViewCell.h"

NSString * const CSRGatewayDetailsTableCellIdentifier = @"gatewayDetailsCellIdentifier";

@implementation CSRGatewayDetailsTableViewCell

@synthesize detailName, detailValue;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (NSString *)reuseIdentifier
{
    return CSRGatewayDetailsTableCellIdentifier;
}

@end
