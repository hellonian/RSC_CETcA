//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import "CSRMenuSlidingInteractiveTransition.h"

@interface CSRMenuSlidingInteractiveTransition ()

@property (nonatomic, assign) CSRMenuSlidingViewController *slidingViewController;
@property (nonatomic, assign) BOOL positiveLeftToRight;
@property (nonatomic, assign) CGFloat fullWidth;
@property (nonatomic, assign) CGFloat currentPercentage;
@property (nonatomic, copy) void (^coordinatorInteractionEnded)(id<UIViewControllerTransitionCoordinatorContext>context);
@end

@implementation CSRMenuSlidingInteractiveTransition

#pragma mark - Constructors

- (id)initWithSlidingViewController:(CSRMenuSlidingViewController *)slidingViewController
{
    self = [super init];
    if (self) {
        self.slidingViewController = slidingViewController;
    }
    
    return self;
}

#pragma mark - UIViewControllerInteractiveTransitioning

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    [super startInteractiveTransition:transitionContext];
    
    UIViewController *topViewController = [transitionContext viewControllerForKey:MenuTransitionContextTopViewControllerKey];
    CGFloat finalLeftEdge = CGRectGetMinX([transitionContext finalFrameForViewController:topViewController]);
    CGFloat initialLeftEdge = CGRectGetMinX([transitionContext initialFrameForViewController:topViewController]);
    CGFloat fullWidth = fabs(finalLeftEdge - initialLeftEdge);
    
    self.positiveLeftToRight = initialLeftEdge < finalLeftEdge;
    self.fullWidth           = fullWidth;
    self.currentPercentage   = 0;
}

#pragma mark - UIPanGestureRecognizer action

- (void)updateTopViewHorizontalCenterWithRecognizer:(UIPanGestureRecognizer*)recognizer
{
    CGFloat translationX  = [recognizer translationInView:self.slidingViewController.view].x;
    CGFloat velocityX     = [recognizer velocityInView:self.slidingViewController.view].x;
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            BOOL isMovingRight = velocityX > 0;
            
            if (self.slidingViewController.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionCentered && isMovingRight) {
                [self.slidingViewController anchorTopViewToRightAnimated:YES];
            } else if (self.slidingViewController.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionCentered && !isMovingRight) {
                [self.slidingViewController anchorTopViewToLeftAnimated:YES];
            } else if (self.slidingViewController.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredLeft) {
                [self.slidingViewController resetTopViewAnimated:YES];
            } else if (self.slidingViewController.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredRight) {
                [self.slidingViewController resetTopViewAnimated:YES];
            }
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (!self.positiveLeftToRight) translationX = translationX * -1.0;
            CGFloat percentComplete = (translationX / self.fullWidth);
            if (percentComplete < 0) percentComplete = 0;
            [self updateInteractiveTransition:percentComplete];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            BOOL isPanningRight = velocityX > 0;
            
            if (self.coordinatorInteractionEnded) self.coordinatorInteractionEnded((id<UIViewControllerTransitionCoordinatorContext>)self.slidingViewController);
            
            if (isPanningRight && self.positiveLeftToRight) {
                [self finishInteractiveTransition];
            } else if (isPanningRight && !self.positiveLeftToRight) {
                [self cancelInteractiveTransition];
            } else if (!isPanningRight && self.positiveLeftToRight) {
                [self cancelInteractiveTransition];
            } else if (!isPanningRight && !self.positiveLeftToRight) {
                [self finishInteractiveTransition];
            }
            
            break;
        }
        default:
            break;
    }
}

@end
