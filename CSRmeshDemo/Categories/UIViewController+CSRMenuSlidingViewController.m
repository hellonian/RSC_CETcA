//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import "UIViewController+CSRMenuSlidingViewController.h"

@implementation UIViewController (CSRMenuSlidingViewController)

- (CSRMenuSlidingViewController *)slidingViewController
{
    UIViewController *viewController = self.parentViewController ? self.parentViewController : self.presentingViewController;
    
    while (!(viewController == nil || [viewController isKindOfClass:[CSRMenuSlidingViewController class]])) {
        viewController = viewController.parentViewController ? viewController.parentViewController : viewController.presentingViewController;
    }
    
    return (CSRMenuSlidingViewController*)viewController;
}

@end
