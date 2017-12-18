//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRSwitchableTableViewCell.h"

NSString * const CSRSwitchableCellIdentifier = @"switchableCellIdentifier";

@implementation CSRSwitchableTableViewCell

@synthesize titleLabel, stateSwitch;

- (NSString *)reuseIdentifier
{
    return CSRSwitchableCellIdentifier;
}

//- (void)layoutSubviews
//{
//    self.contentView.frame = self.bounds;
//    [super layoutSubviews];
//}

@end
