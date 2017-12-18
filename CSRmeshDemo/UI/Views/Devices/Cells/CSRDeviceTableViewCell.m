//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRDeviceTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

NSString * const CSRDeviceTableViewCellIdentifier = @"deviceTableViewCellIdentifier";

@implementation CSRDeviceTableViewCell

@synthesize iconImageView, deviceNameLabel, deviceStateLabel, statusView;

- (id) init
{
    
    return self;
}

-(id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self) {

    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (NSString *)reuseIdentifier
{
    return CSRDeviceTableViewCellIdentifier;
}

@end
