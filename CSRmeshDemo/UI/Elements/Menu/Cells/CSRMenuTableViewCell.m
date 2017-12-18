//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRMenuTableViewCell.h"

NSString * const CSRMenuTableViewCellIdentifier = @"menuTableViewCellIdentifier";

@implementation CSRMenuTableViewCell

@synthesize iconImageView;
@synthesize nameLabel;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (NSString *)reuseIdentifier
{
    return CSRMenuTableViewCellIdentifier;
}

- (void)layoutSubviews
{
    self.contentView.frame = self.bounds;
    
    [super layoutSubviews];
}

@end
