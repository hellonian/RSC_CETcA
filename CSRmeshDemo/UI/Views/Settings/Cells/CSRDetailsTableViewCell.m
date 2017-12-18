//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRDetailsTableViewCell.h"

NSString * const CSRDetailsCellIdentifier = @"detailsCellIdentifier";

@implementation CSRDetailsTableViewCell

@synthesize titleLabel, detailsLabel, cover;

- (NSString *)reuseIdentifier
{
    return CSRDetailsCellIdentifier;
}

//- (void)layoutSubviews
//{
//    self.contentView.frame = self.bounds;
//    [super layoutSubviews];
//}

@end
