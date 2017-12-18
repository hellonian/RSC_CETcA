//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRMenuActionTableViewCell.h"

NSString * const CSRMenuActionTableViewCellIdentifier = @"menuActionTableViewCellIdentifier";

@implementation CSRMenuActionTableViewCell

@synthesize actionNameLabel;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (NSString *)reuseIdentifier
{
    return CSRMenuActionTableViewCellIdentifier;
}

- (void)layoutSubviews
{
    self.contentView.frame = self.bounds;
    
    [super layoutSubviews];
}

@end
