//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRPlaceColorCollectionViewCell.h"

NSString * const CSRPlaceColorCellIdentifier = @"placeColorCellIdentifier";

@implementation CSRPlaceColorCollectionViewCell

@synthesize placeColor;

- (NSString *)reuseIdentifier
{
    return CSRPlaceColorCellIdentifier;
}

- (void)layoutSubviews
{
    self.contentView.frame = self.bounds;
    [super layoutSubviews];
}

@end
