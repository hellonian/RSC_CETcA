//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRDeviceSelectionTableViewCell.h"

NSString * const CSRDeviceSelectionTableViewCellIdentifier = @"deviceSelectionCellIdentifier";

@implementation CSRDeviceSelectionTableViewCell

@synthesize deviceNameLabel, deviceIcon;

- (id) init
{
    
    return self;
}

-(id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (NSString *)reuseIdentifier
{
    return CSRDeviceSelectionTableViewCellIdentifier;
}


@end
