//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *const MenuTransitionContextTopViewControllerKey = @"MenuTransitionContextTopViewControllerKey";
static NSString *const MenuTransitionContextUnderLeftControllerKey = @"MenuTransitionContextUnderLeftControllerKey";
static NSString *const MenuTransitionContextUnderRightControllerKey = @"MenuTransitionContextUnderRightControllerKey";

typedef NS_ENUM(NSInteger, MenuSlidingViewControllerOperation) {
    MenuSlidingViewControllerOperationNone,
    MenuSlidingViewControllerOperationAnchorLeft,
    MenuSlidingViewControllerOperationAnchorRight,
    MenuSlidingViewControllerOperationResetFromLeft,
    MenuSlidingViewControllerOperationResetFromRight
};

typedef NS_ENUM(NSInteger, MenuSlidingViewControllerTopViewPosition) {
    MenuSlidingViewControllerTopViewPositionAnchoredLeft,
    MenuSlidingViewControllerTopViewPositionAnchoredRight,
    MenuSlidingViewControllerTopViewPositionCentered
};

typedef NS_OPTIONS(NSInteger, MenuSlidingViewControllerAnchoredGesture) {
    MenuSlidingViewControllerAnchoredGestureNone     = 0,
    MenuSlidingViewControllerAnchoredGesturePanning  = 1 << 0,
    MenuSlidingViewControllerAnchoredGestureTapping  = 1 << 1,
    MenuSlidingViewControllerAnchoredGestureCustom   = 1 << 2,
    MenuSlidingViewControllerAnchoredGestureDisabled = 1 << 3
};

@class CSRMenuSlidingViewController;

@protocol MenuSlidingViewControllerLayout <NSObject>

- (CGRect)slidingViewController:(CSRMenuSlidingViewController *)slidingViewController
         frameForViewController:(UIViewController *)viewController
                topViewPosition:(MenuSlidingViewControllerTopViewPosition)topViewPosition;
@end


@protocol MenuSlidingViewControllerDelegate

@optional

- (id<UIViewControllerAnimatedTransitioning>)slidingViewController:(CSRMenuSlidingViewController*)slidingViewController
                                   animationControllerForOperation:(MenuSlidingViewControllerOperation)operation
                                                 topViewController:(UIViewController*)topViewController;

- (id<UIViewControllerInteractiveTransitioning>)slidingViewController:(CSRMenuSlidingViewController*)slidingViewController
                          interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>)animationController;

- (id<MenuSlidingViewControllerLayout>)slidingViewController:(CSRMenuSlidingViewController*)slidingViewController
                        layoutControllerForTopViewPosition:(MenuSlidingViewControllerTopViewPosition)topViewPosition;

@end

@interface CSRMenuSlidingViewController : UIViewController <UIViewControllerContextTransitioning, UIViewControllerTransitionCoordinator, UIViewControllerTransitionCoordinatorContext>
{
    
@private
    CGFloat _anchorLeftPeekAmount;
    CGFloat _anchorLeftRevealAmount;
    CGFloat _anchorRightPeekAmount;
    CGFloat _anchorRightRevealAmount;
    UIPanGestureRecognizer *_panGesture;
    UITapGestureRecognizer *_resetTapGesture;
    
@protected
    UIViewController *_topViewController;
    UIViewController *_underLeftViewController;
    UIViewController *_underRightViewController;
}

+ (instancetype)slidingWithTopViewController:(UIViewController*)viewController;
- (instancetype)initWithTopViewController:(UIViewController*)viewController;

@property (nonatomic, strong) UIViewController *topViewController;
@property (nonatomic, strong) UIViewController *underLeftViewController;
@property (nonatomic, strong) UIViewController *underRightViewController;

@property (nonatomic, assign) CGFloat anchorLeftPeekAmount;
@property (nonatomic, assign) CGFloat anchorLeftRevealAmount;
@property (nonatomic, assign) CGFloat anchorRightPeekAmount;
@property (nonatomic, assign) CGFloat anchorRightRevealAmount;

- (void)anchorTopViewToRightAnimated:(BOOL)animated;
- (void)anchorTopViewToRightAnimated:(BOOL)animated onComplete:(void (^)())complete;
- (void)anchorTopViewToLeftAnimated:(BOOL)animated;
- (void)anchorTopViewToLeftAnimated:(BOOL)animated onComplete:(void (^)())complete;
- (void)resetTopViewAnimated:(BOOL)animated;
- (void)resetTopViewAnimated:(BOOL)animated onComplete:(void(^)())complete;

@property (nonatomic, strong) NSString *topViewControllerStoryboardId;
@property (nonatomic, strong) NSString *underLeftViewControllerStoryboardId;
@property (nonatomic, strong) NSString *underRightViewControllerStoryboardId;

@property (nonatomic, assign) id<MenuSlidingViewControllerDelegate> delegate;
@property (nonatomic, assign) MenuSlidingViewControllerAnchoredGesture topViewAnchoredGesture;
@property (nonatomic, assign, readonly) MenuSlidingViewControllerTopViewPosition currentTopViewPosition;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong, readonly) UITapGestureRecognizer *resetTapGesture;
@property (nonatomic, strong) NSArray *customAnchoredGestures;
@property (nonatomic, assign) NSTimeInterval defaultTransitionDuration;


@end
