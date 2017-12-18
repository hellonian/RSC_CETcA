//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRActionTableViewCell.h"

NSString * const CSRActionCellIdentifier = @"actionCellIdentifier";

@implementation CSRActionTableViewCell

@synthesize titleLabel, detailLabel;

- (NSString *)reuseIdentifier
{
    return CSRActionCellIdentifier;
}

//- (void)layoutSubviews
//{
//    self.contentView.frame = self.bounds;
//    [super layoutSubviews];
//}

@end
