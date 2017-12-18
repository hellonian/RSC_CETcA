//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRPlaceIconCollectionViewCell.h"

NSString * const CSRPlaceIconCellIdentifier = @"placeIconCellIdentifier";

@implementation CSRPlaceIconCollectionViewCell

@synthesize placeIcon;

- (NSString *)reuseIdentifier
{
    return CSRPlaceIconCellIdentifier;
}

- (void)layoutSubviews
{
    self.contentView.frame = self.bounds;
    [super layoutSubviews];
}

@end
