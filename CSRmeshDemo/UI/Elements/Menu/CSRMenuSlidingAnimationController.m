//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import "CSRMenuSlidingAnimationController.h"

static NSString *const MenuTransitionContextTopViewControllerKey = @"MenuTransitionContextTopViewControllerKey";
static NSString *const MenuTransitionContextUnderLeftControllerKey = @"MenuTransitionContextUnderLeftControllerKey";
static NSString *const MenuTransitionContextUnderRightControllerKey = @"MenuTransitionContextUnderRightControllerKey";

@interface CSRMenuSlidingAnimationController ()

@property (nonatomic, copy) void (^coordinatorAnimations)(id<UIViewControllerTransitionCoordinatorContext>context);
@property (nonatomic, copy) void (^coordinatorCompletion)(id<UIViewControllerTransitionCoordinatorContext>context);

@end

@implementation CSRMenuSlidingAnimationController

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    if (_defaultTransitionDuration) {
        return _defaultTransitionDuration;
    } else {
        return 0.25;
    }
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *topViewController = [transitionContext viewControllerForKey:MenuTransitionContextTopViewControllerKey];
    UIViewController *toViewController  = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    CGRect topViewInitialFrame = [transitionContext initialFrameForViewController:topViewController];
    CGRect topViewFinalFrame   = [transitionContext finalFrameForViewController:topViewController];
    
    topViewController.view.frame = topViewInitialFrame;
    
    if (topViewController != toViewController) {
        CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toViewController];
        toViewController.view.frame = toViewFinalFrame;
        [containerView insertSubview:toViewController.view belowSubview:topViewController.view];
    }
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration animations:^{
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        if (self.coordinatorAnimations) self.coordinatorAnimations((id<UIViewControllerTransitionCoordinatorContext>)transitionContext);
        topViewController.view.frame = topViewFinalFrame;
    } completion:^(BOOL finished) {
        if ([transitionContext transitionWasCancelled]) {
            topViewController.view.frame = [transitionContext initialFrameForViewController:topViewController];
        }
        
        if (self.coordinatorCompletion) self.coordinatorCompletion((id<UIViewControllerTransitionCoordinatorContext>)transitionContext);
        [transitionContext completeTransition:finished];
        
    }];
}

@end