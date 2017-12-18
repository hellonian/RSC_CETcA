//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CSRMenuPercentDrivenInteractiveTransition.h"
#import "CSRMenuSlidingViewController.h"

@class CSRMenuSlidingViewController;

@interface CSRMenuSlidingInteractiveTransition : CSRMenuPercentDrivenInteractiveTransition

- (id)initWithSlidingViewController:(CSRMenuSlidingViewController*)slidingViewController;
- (void)updateTopViewHorizontalCenterWithRecognizer:(UIPanGestureRecognizer*)recognizer;

@end
