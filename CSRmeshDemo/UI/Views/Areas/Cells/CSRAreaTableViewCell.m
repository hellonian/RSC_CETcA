//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRAreaTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

NSString * const CSRAreaTableViewCellIdentifier = @"areaTableViewCellIdentifier";

@implementation CSRAreaTableViewCell

@synthesize areaNameLabel, numberOfAreasLabel;

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
    return CSRAreaTableViewCellIdentifier;
}

@end

