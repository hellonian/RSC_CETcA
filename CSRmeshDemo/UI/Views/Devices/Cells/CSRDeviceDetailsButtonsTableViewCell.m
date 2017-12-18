//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//
#import "CSRDeviceDetailsButtonsTableViewCell.h"

NSString * const CSRDeviceDetailsButtonsTableViewCellIdentifier = @"deviceDetailsButtonsTableViewCellIdentifier";

@implementation CSRDeviceDetailsButtonsTableViewCell

@synthesize favouriteButton, attentionButton, attentionLabel;


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

- (void)awakeFromNib {
    // Initialization code
    [self addFloatingEffectToButton:favouriteButton];
    [self addFloatingEffectToButton:attentionButton];
//    [self addFloatingEffectToButton:otauButton];

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (NSString *)reuseIdentifier
{
    return CSRDeviceDetailsButtonsTableViewCellIdentifier;
}

- (void) addFloatingEffectToButton:(UIButton*)button
{
    button.layer.masksToBounds = NO;
    button.layer.shadowColor = [UIColor blackColor].CGColor;
    button.layer.shadowOpacity = 0.3;
    button.layer.shadowRadius = .5;
    button.layer.shadowOffset = CGSizeMake(1., 1.);

}


@end
