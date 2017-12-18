//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRCheckbox.h"
#import "CSRmeshStyleKit.h"

@implementation CSRCheckbox

{
    BOOL _invertedMode;
}

#pragma mark - Initialize

- (id)init
{
    self = [super init];
    
    if (self) {
        _invertedMode = NO;
        [self initializeCheckbox];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self) {
        [self initializeCheckbox];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self initializeCheckbox];
    }
    
    return self;
}

- (void)initializeCheckbox
{
    [self setBackgroundImage:[CSRmeshStyleKit imageOfCheckbox_on] forState:UIControlStateSelected];
    [self setBackgroundImage:[CSRmeshStyleKit imageOfCheckbox_off]  forState:UIControlStateNormal];
    [self addTarget:self action:@selector(checkboxSelected) forControlEvents:UIControlEventTouchUpInside];
    self.backgroundColor = [UIColor clearColor];
}


- (void)checkboxSelected
{
    self.selected = !self.selected;
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    if ([_delegate respondsToSelector:@selector(checkbox:stateChangeTo:)]) {
        [_delegate checkbox:self stateChangeTo:self.selected];
    }
}

- (void)invertColors:(int)checkBoxMode
{
    switch (checkBoxMode) {
        case 0:
        {
            [self setBackgroundImage:[CSRmeshStyleKit imageOfCheckbox_on] forState:UIControlStateSelected];
            [self setBackgroundImage:[CSRmeshStyleKit imageOfCheckbox_off] forState:UIControlStateNormal];
            self.backgroundColor = [UIColor clearColor];
        }
            break;
            
        case 1:
        {
            [self setBackgroundImage:[CSRmeshStyleKit imageOfCheckbox_alt_on] forState:UIControlStateSelected];
            [self setBackgroundImage:[CSRmeshStyleKit imageOfCheckbox_alt_off] forState:UIControlStateNormal];
            self.backgroundColor = [UIColor clearColor];
        }
            break;
            
        default:
            break;
    }
}

@end
