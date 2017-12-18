//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRPlaceTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

NSString * const CSRPlaceTableViewCellIdentifier = @"placeTableViewCellIdentifier";

@implementation CSRPlaceTableViewCell

@synthesize placeIcon, placeNameLabel, placeOwnerNameLabel, currentPlaceIndicator;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (NSString *)reuseIdentifier
{
    return CSRPlaceTableViewCellIdentifier;
}

@end
