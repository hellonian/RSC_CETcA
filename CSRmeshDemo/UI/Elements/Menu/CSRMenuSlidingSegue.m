//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import "CSRMenuSlidingSegue.h"
#import "UIViewController+CSRMenuSlidingViewController.h"

@interface CSRMenuSlidingSegue ()

@property (nonatomic, assign) BOOL isUnwinding;

@end

@implementation CSRMenuSlidingSegue

- (id)initWithIdentifier:(NSString*)identifier source:(UIViewController*)sourceController destination:(UIViewController*)destinationController
{
    self = [super initWithIdentifier:identifier source:sourceController destination:destinationController];
    if (self) {
        self.isUnwinding = NO;
        self.skipSettingTopViewController = NO;
    }
    
    return self;
}

- (void)perform
{
    CSRMenuSlidingViewController *slidingViewController = [[self sourceViewController] slidingViewController];
    UIViewController *destinationViewController = [self destinationViewController];
    
    if (self.isUnwinding) {
        if ([slidingViewController.underLeftViewController isMemberOfClass:[destinationViewController class]]) {
            [slidingViewController anchorTopViewToRightAnimated:YES];
        } else if ([slidingViewController.underRightViewController isMemberOfClass:[destinationViewController class]]) {
            [slidingViewController anchorTopViewToLeftAnimated:YES];
        }
    } else {
        if (!self.skipSettingTopViewController) {
            slidingViewController.topViewController = destinationViewController;
        }
        
        [slidingViewController resetTopViewAnimated:YES];
    }
}

@end
