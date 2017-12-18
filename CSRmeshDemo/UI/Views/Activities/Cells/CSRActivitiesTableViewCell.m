//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRActivitiesTableViewCell.h"

NSString * const CSRActivitiesTableViewCellIdentifier = @"activitiesTableViewCellIdentifier";
@implementation CSRActivitiesTableViewCell

@synthesize activityImageView, activityNameLabel;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (NSString *)reuseIdentifier
{
    return CSRActivitiesTableViewCellIdentifier;
}


@end
