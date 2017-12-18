//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRFavouritesCollectionViewCell.h"

NSString * const CSRFavouriteCellIdentifier = @"favouriteCellIdentifier";

@implementation CSRFavouritesCollectionViewCell

- (NSString *)reuseIdentifier
{
    return CSRFavouriteCellIdentifier;
}

- (void)layoutSubviews
{
    self.contentView.frame = self.bounds;
    [super layoutSubviews];
}


@end
