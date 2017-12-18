//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRBearerOptionTableViewCell.h"

NSString * const CSRBearerOptionCellIdentifier = @"bearerOptionCellIdentifier";

@implementation CSRBearerOptionTableViewCell

@synthesize bearerNameLabel;

- (NSString *)reuseIdentifier
{
    return CSRBearerOptionCellIdentifier;
}

//- (void)layoutSubviews
//{
//    self.contentView.frame = self.bounds;
//    [super layoutSubviews];
//}

@end
