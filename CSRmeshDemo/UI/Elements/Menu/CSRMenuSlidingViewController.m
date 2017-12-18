//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import "CSRMenuSlidingViewController.h"

#import "CSRMenuSlidingAnimationController.h"
#import "CSRMenuSlidingInteractiveTransition.h"
#import "CSRMenuSlidingSegue.h"

#import "CSRConstants.h"

@interface CSRMenuSlidingViewController ()

@property (nonatomic, assign) MenuSlidingViewControllerOperation currentOperation;
@property (nonatomic, strong) CSRMenuSlidingAnimationController *defaultAnimationController;
@property (nonatomic, strong) CSRMenuSlidingInteractiveTransition *defaultInteractiveTransition;
@property (nonatomic, strong) id<UIViewControllerAnimatedTransitioning> currentAnimationController;
@property (nonatomic, strong) id<UIViewControllerInteractiveTransitioning> currentInteractiveTransition;
@property (nonatomic, strong) UIView *gestureView;
@property (nonatomic, strong) NSMapTable *customAnchoredGesturesViewMap;
@property (nonatomic, assign) CGFloat currentAnimationPercentage;
@property (nonatomic, assign) BOOL preserveLeftPeekAmount;
@property (nonatomic, assign) BOOL preserveRightPeekAmount;
@property (nonatomic, assign) BOOL transitionWasCancelled;
@property (nonatomic, assign) BOOL isAnimated;
@property (nonatomic, assign) BOOL isInteractive;
@property (nonatomic, assign) BOOL transitionInProgress;
@property (nonatomic, copy) void (^animationComplete)();
@property (nonatomic, copy) void (^coordinatorAnimations)(id<UIViewControllerTransitionCoordinatorContext>context);
@property (nonatomic, copy) void (^coordinatorCompletion)(id<UIViewControllerTransitionCoordinatorContext>context);
@property (nonatomic, copy) void (^coordinatorInteractionEnded)(id<UIViewControllerTransitionCoordinatorContext>context);
@property (nonatomic, assign) CGFloat statusBarFrameHeight;
@property (nonatomic, assign) BOOL statusBarResizeUp;
@property (nonatomic, assign) BOOL statusBarResizeDown;

- (void)setup;

- (void)moveTopViewToPosition:(MenuSlidingViewControllerTopViewPosition)position animated:(BOOL)animated onComplete:(void(^)())complete;
- (CGRect)topViewCalculatedFrameForPosition:(MenuSlidingViewControllerTopViewPosition)position;
- (CGRect)underLeftViewCalculatedFrameForTopViewPosition:(MenuSlidingViewControllerTopViewPosition)position;
- (CGRect)underRightViewCalculatedFrameForTopViewPosition:(MenuSlidingViewControllerTopViewPosition)position;
- (CGRect)frameFromDelegateForViewController:(UIViewController*)viewController
                             topViewPosition:(MenuSlidingViewControllerTopViewPosition)topViewPosition;
- (MenuSlidingViewControllerOperation)operationFromPosition:(MenuSlidingViewControllerTopViewPosition)fromPosition
                                                 toPosition:(MenuSlidingViewControllerTopViewPosition)toPosition;
- (void)animateOperation:(MenuSlidingViewControllerOperation)operation;
- (BOOL)operationIsValid:(MenuSlidingViewControllerOperation)operation;
- (void)beginAppearanceTransitionForOperation:(MenuSlidingViewControllerOperation)operation;
- (void)endAppearanceTransitionForOperation:(MenuSlidingViewControllerOperation)operation isCancelled:(BOOL)canceled;
- (UIViewController*)viewControllerWillAppearForSuccessfulOperation:(MenuSlidingViewControllerOperation)operation;
- (UIViewController*)viewControllerWillDisappearForSuccessfulOperation:(MenuSlidingViewControllerOperation)operation;
- (void)updateTopViewGestures;
@end

@implementation CSRMenuSlidingViewController

- (UIView *)viewForKey:(NSString *)key
{
    return nil;
}

- (CGAffineTransform)targetTransform
{
    return CGAffineTransformIdentity;
}

#pragma mark - Constructors

+ (instancetype)slidingWithTopViewController:(UIViewController*)viewController
{
    return [[self alloc] initWithTopViewController:viewController];
}

- (instancetype)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithTopViewController:(UIViewController*)viewController
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.topViewController = viewController;
    }
    
    return self;
}

- (void)setup {
    
    self.anchorRightRevealAmount = 276;
    self.anchorLeftPeekAmount = [UIScreen mainScreen].bounds.size.width - self.anchorRightRevealAmount;
    _currentTopViewPosition = MenuSlidingViewControllerTopViewPositionCentered;
    self.transitionInProgress = NO;
}

#pragma mark - UIViewController

- (void)awakeFromNib {
    if (self.topViewControllerStoryboardId)
    {
        self.topViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.topViewControllerStoryboardId];
    }
    
    if (self.underLeftViewControllerStoryboardId)
    {
        self.underLeftViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.underLeftViewControllerStoryboardId];
    }
    
    if (self.underRightViewControllerStoryboardId)
    {
        self.underRightViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.underRightViewControllerStoryboardId];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Hello word!!!!!");

    // User is logged in, do work such as go to next view controller.
    self.topViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"DevicesNavigationController"];
    self.underLeftViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];

//    [self.view addGestureRecognizer:self.panGesture];
    
    if (!self.topViewController) [NSException raise:@"Missing topViewController"
                                             format:@"Set the topViewController before loading MenuSlidingViewController"];
    self.topViewController.view.frame = [self topViewCalculatedFrameForPosition:self.currentTopViewPosition];
    [self.view addSubview:self.topViewController.view];
    
    //Add notification observer for status bar resize
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarResize:)
                                                 name:UIApplicationWillChangeStatusBarFrameNotification
                                               object:nil];
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleOpenURL)
                                                 name:kCSRImportPlaceDataNotification
                                               object:nil];

}

- (void)handleOpenURL
{
    [self performSegueWithIdentifier:@"importDataSegue" sender:nil];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.topViewController beginAppearanceTransition:YES animated:animated];
    
    if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredLeft) {
        [self.underRightViewController beginAppearanceTransition:YES animated:animated];
    } else if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredRight) {
        [self.underLeftViewController beginAppearanceTransition:YES animated:animated];
    }
    
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.topViewController endAppearanceTransition];
    
    if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredLeft) {
        [self.underRightViewController endAppearanceTransition];
    } else if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredRight) {
        [self.underLeftViewController endAppearanceTransition];
    }
    
    [self.underLeftViewController.navigationController.view addGestureRecognizer:self.panGesture];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.topViewController beginAppearanceTransition:NO animated:animated];
    
    if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredLeft) {
        [self.underRightViewController beginAppearanceTransition:NO animated:animated];
    } else if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredRight) {
        [self.underLeftViewController beginAppearanceTransition:NO animated:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.topViewController endAppearanceTransition];
    
    if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredLeft) {
        [self.underRightViewController endAppearanceTransition];
    } else if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredRight) {
        [self.underLeftViewController endAppearanceTransition];
    }
    
    [self.underLeftViewController.navigationController.view removeGestureRecognizer:_panGesture];
}

- (void)viewDidLayoutSubviews
{
    if (self.currentOperation == MenuSlidingViewControllerOperationNone) {
        self.gestureView.frame = [self topViewCalculatedFrameForPosition:self.currentTopViewPosition];
        self.topViewController.view.frame = [self topViewCalculatedFrameForPosition:self.currentTopViewPosition];
        self.underLeftViewController.view.frame = [self underLeftViewCalculatedFrameForTopViewPosition:self.currentTopViewPosition];
        self.underRightViewController.view.frame = [self underRightViewCalculatedFrameForTopViewPosition:self.currentTopViewPosition];
    }
    
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:self.topViewController.view.bounds];
    self.topViewController.view.layer.masksToBounds = NO;
    self.topViewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    self.topViewController.view.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    self.topViewController.view.layer.shadowOpacity = 0.5f;
    self.topViewController.view.layer.shadowPath = shadowPath.CGPath;
}

- (BOOL)shouldAutorotate
{
    return self.currentOperation == MenuSlidingViewControllerOperationNone;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return NO;
}

- (BOOL)shouldAutomaticallyForwardRotationMethods
{
    return YES;
}

- (UIStoryboardSegue*)segueForUnwindingToViewController:(UIViewController*)toViewController fromViewController:(UIViewController*)fromViewController identifier:(NSString*)identifier
{
    if ([self.underLeftViewController isMemberOfClass:[toViewController class]] || [self.underRightViewController isMemberOfClass:[toViewController class]]) {
        CSRMenuSlidingSegue *unwindSegue = [[CSRMenuSlidingSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
        [unwindSegue setValue:@YES forKey:@"isUnwinding"];
        return unwindSegue;
    } else {
        return [super segueForUnwindingToViewController:toViewController fromViewController:fromViewController identifier:identifier];
    }
}

- (UIViewController*)childViewControllerForStatusBarHidden
{
    if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionCentered) {
        return self.topViewController;
    } else if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredLeft) {
        return self.underRightViewController;
    } else if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredRight) {
        return self.underLeftViewController;
    } else {
        return nil;
    }
}

- (UIViewController*)childViewControllerForStatusBarStyle
{
    if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionCentered) {
        return self.topViewController;
    } else if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredLeft) {
        return self.underRightViewController;
    } else if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredRight) {
        return self.underLeftViewController;
    } else {
        return nil;
    }
}

- (id<UIViewControllerTransitionCoordinator>)transitionCoordinator
{
    if (!self.transitionInProgress){
        return [super transitionCoordinator];
    }
    return self;
}

#pragma mark - Properties

- (void)setTopViewController:(UIViewController*)topViewController
{
    UIViewController *oldTopViewController = _topViewController;
    
    [oldTopViewController.view removeFromSuperview];
    [oldTopViewController willMoveToParentViewController:nil];
    [oldTopViewController beginAppearanceTransition:NO animated:NO];
    [oldTopViewController removeFromParentViewController];
    [oldTopViewController endAppearanceTransition];
    
    _topViewController = topViewController;
    
    if (_topViewController) {
        [self addChildViewController:_topViewController];
        [_topViewController didMoveToParentViewController:self];
        
        if ([self isViewLoaded]) {
            [_topViewController beginAppearanceTransition:YES animated:NO];
            [self.view addSubview:_topViewController.view];
            [_topViewController endAppearanceTransition];
        }
    }
}

- (void)setUnderLeftViewController:(UIViewController*)underLeftViewController
{
    UIViewController *oldUnderLeftViewController = _underLeftViewController;
    
    [oldUnderLeftViewController.view removeFromSuperview];
    [oldUnderLeftViewController willMoveToParentViewController:nil];
    [oldUnderLeftViewController beginAppearanceTransition:NO animated:NO];
    [oldUnderLeftViewController removeFromParentViewController];
    [oldUnderLeftViewController endAppearanceTransition];
    
    _underLeftViewController = underLeftViewController;
    
    if (_underLeftViewController) {
        [self addChildViewController:_underLeftViewController];
        [_underLeftViewController didMoveToParentViewController:self];
    }
}

- (void)setUnderRightViewController:(UIViewController*)underRightViewController
{
    UIViewController *oldUnderRightViewController = _underRightViewController;
    
    [oldUnderRightViewController.view removeFromSuperview];
    [oldUnderRightViewController willMoveToParentViewController:nil];
    [oldUnderRightViewController beginAppearanceTransition:NO animated:NO];
    [oldUnderRightViewController removeFromParentViewController];
    [oldUnderRightViewController endAppearanceTransition];
    
    _underRightViewController = underRightViewController;
    
    if (_underRightViewController) {
        [self addChildViewController:_underRightViewController];
        [_underRightViewController didMoveToParentViewController:self];
    }
}

- (void)setAnchorLeftPeekAmount:(CGFloat)anchorLeftPeekAmount
{
    _anchorLeftPeekAmount   = anchorLeftPeekAmount;
    _anchorLeftRevealAmount = CGFLOAT_MAX;
    self.preserveLeftPeekAmount = YES;
}

- (void)setAnchorLeftRevealAmount:(CGFloat)anchorLeftRevealAmount
{
    _anchorLeftRevealAmount = anchorLeftRevealAmount;
    _anchorLeftPeekAmount   = CGFLOAT_MAX;
    self.preserveLeftPeekAmount = NO;
}

- (void)setAnchorRightPeekAmount:(CGFloat)anchorRightPeekAmount
{
    _anchorRightPeekAmount   = anchorRightPeekAmount;
    _anchorRightRevealAmount = CGFLOAT_MAX;
    self.preserveRightPeekAmount = YES;
}

- (void)setAnchorRightRevealAmount:(CGFloat)anchorRightRevealAmount
{
    _anchorRightRevealAmount = anchorRightRevealAmount;
    _anchorRightPeekAmount   = CGFLOAT_MAX;
    self.preserveRightPeekAmount = NO;
}

- (void)setDefaultTransitionDuration:(NSTimeInterval)defaultTransitionDuration
{
    self.defaultAnimationController.defaultTransitionDuration = defaultTransitionDuration;
}

- (CGFloat)anchorLeftPeekAmount
{
    if (_anchorLeftPeekAmount == CGFLOAT_MAX && _anchorLeftRevealAmount != CGFLOAT_MAX) {
        return CGRectGetWidth(self.view.bounds) - _anchorLeftRevealAmount;
    } else if (_anchorLeftPeekAmount != CGFLOAT_MAX && _anchorLeftRevealAmount == CGFLOAT_MAX) {
        return _anchorLeftPeekAmount;
    } else {
        return CGFLOAT_MAX;
    }
}

- (CGFloat)anchorLeftRevealAmount
{
    if (_anchorLeftRevealAmount == CGFLOAT_MAX && _anchorLeftPeekAmount != CGFLOAT_MAX) {
        return CGRectGetWidth(self.view.bounds) - _anchorLeftPeekAmount;
    } else if (_anchorLeftRevealAmount != CGFLOAT_MAX && _anchorLeftPeekAmount == CGFLOAT_MAX) {
        return _anchorLeftRevealAmount;
    } else {
        return CGFLOAT_MAX;
    }
}

- (CGFloat)anchorRightPeekAmount
{
    if (_anchorRightPeekAmount == CGFLOAT_MAX && _anchorRightRevealAmount != CGFLOAT_MAX) {
        return CGRectGetWidth(self.view.bounds) - _anchorRightRevealAmount;
    } else if (_anchorRightPeekAmount != CGFLOAT_MAX && _anchorRightRevealAmount == CGFLOAT_MAX) {
        return _anchorRightPeekAmount;
    } else {
        return CGFLOAT_MAX;
    }
}

- (CGFloat)anchorRightRevealAmount
{
    if (_anchorRightRevealAmount == CGFLOAT_MAX && _anchorRightPeekAmount != CGFLOAT_MAX) {
        return CGRectGetWidth(self.view.bounds) - _anchorRightPeekAmount;
    } else if (_anchorRightRevealAmount != CGFLOAT_MAX && _anchorRightPeekAmount == CGFLOAT_MAX) {
        return _anchorRightRevealAmount;
    } else {
        return CGFLOAT_MAX;
    }
}

- (CSRMenuSlidingAnimationController*)defaultAnimationController
{
    if (_defaultAnimationController) return _defaultAnimationController;
    
    _defaultAnimationController = [[CSRMenuSlidingAnimationController alloc] init];
    
    return _defaultAnimationController;
}

- (CSRMenuSlidingInteractiveTransition*)defaultInteractiveTransition
{
    if (_defaultInteractiveTransition) return _defaultInteractiveTransition;
    
    _defaultInteractiveTransition = [[CSRMenuSlidingInteractiveTransition alloc] initWithSlidingViewController:self];
    _defaultInteractiveTransition.animationController = self.defaultAnimationController;
    
    return _defaultInteractiveTransition;
}

- (UIView*)gestureView
{
    if (_gestureView) return _gestureView;
    
    _gestureView = [[UIView alloc] initWithFrame:CGRectZero];
    
    return _gestureView;
}

- (NSMapTable*)customAnchoredGesturesViewMap
{
    if (_customAnchoredGesturesViewMap) return _customAnchoredGesturesViewMap;
    
    _customAnchoredGesturesViewMap = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableWeakMemory];
    
    return _customAnchoredGesturesViewMap;
}

- (UITapGestureRecognizer*)resetTapGesture
{
    if (_resetTapGesture) return _resetTapGesture;
    
    _resetTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetTopViewAnimated:)];
    
    return _resetTapGesture;
}

- (UIPanGestureRecognizer*)panGesture
{
    if (_panGesture) return _panGesture;
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(detectPanGestureRecognizer:)];
    
    return _panGesture;
}

#pragma mark - Public

- (void)anchorTopViewToRightAnimated:(BOOL)animated
{
    [self anchorTopViewToRightAnimated:animated onComplete:nil];
}

- (void)anchorTopViewToLeftAnimated:(BOOL)animated
{
    [self anchorTopViewToLeftAnimated:animated onComplete:nil];
}

- (void)resetTopViewAnimated:(BOOL)animated
{
    [self resetTopViewAnimated:animated onComplete:nil];
}

- (void)anchorTopViewToRightAnimated:(BOOL)animated onComplete:(void (^)())complete
{
    [self moveTopViewToPosition:MenuSlidingViewControllerTopViewPositionAnchoredRight animated:animated onComplete:complete];
}

- (void)anchorTopViewToLeftAnimated:(BOOL)animated onComplete:(void (^)())complete
{
    [self moveTopViewToPosition:MenuSlidingViewControllerTopViewPositionAnchoredLeft animated:animated onComplete:complete];
}

- (void)resetTopViewAnimated:(BOOL)animated onComplete:(void(^)())complete
{
    [self moveTopViewToPosition:MenuSlidingViewControllerTopViewPositionCentered animated:animated onComplete:complete];
}

#pragma mark - Private

- (void)moveTopViewToPosition:(MenuSlidingViewControllerTopViewPosition)position animated:(BOOL)animated onComplete:(void(^)())complete
{
    self.isAnimated = animated;
    self.animationComplete = complete;
    [self.view endEditing:YES];
    MenuSlidingViewControllerOperation operation = [self operationFromPosition:self.currentTopViewPosition toPosition:position];
    [self animateOperation:operation];
}

- (CGRect)topViewCalculatedFrameForPosition:(MenuSlidingViewControllerTopViewPosition)position
{
    CGRect frameFromDelegate = [self frameFromDelegateForViewController:self.topViewController
                                                        topViewPosition:position];
    if (!CGRectIsInfinite(frameFromDelegate)) return frameFromDelegate;
    
    CGRect containerViewFrame = self.view.bounds;
    
    if (!(self.topViewController.edgesForExtendedLayout & UIRectEdgeTop)) {
        CGFloat topLayoutGuideLength = [self.topLayoutGuide length];
        containerViewFrame.origin.y     = topLayoutGuideLength;
        containerViewFrame.size.height -= topLayoutGuideLength;
    }
    
    if (!(self.topViewController.edgesForExtendedLayout & UIRectEdgeBottom)) {
        CGFloat bottomLayoutGuideLength = [self.bottomLayoutGuide length];
        containerViewFrame.size.height -= bottomLayoutGuideLength;
    }
    
    switch(position) {
        case MenuSlidingViewControllerTopViewPositionCentered:
            return containerViewFrame;
        case MenuSlidingViewControllerTopViewPositionAnchoredLeft:
            containerViewFrame.origin.x = -self.anchorLeftRevealAmount;
            return containerViewFrame;
        case MenuSlidingViewControllerTopViewPositionAnchoredRight:
            containerViewFrame.origin.x = self.anchorRightRevealAmount;
            return containerViewFrame;
        default:
            return CGRectZero;
    }
}

- (CGRect)underLeftViewCalculatedFrameForTopViewPosition:(MenuSlidingViewControllerTopViewPosition)position
{
    CGRect frameFromDelegate = [self frameFromDelegateForViewController:self.underLeftViewController
                                                        topViewPosition:position];
    if (!CGRectIsInfinite(frameFromDelegate)) return frameFromDelegate;
    
    CGRect containerViewFrame = self.view.bounds;
    
    if (!(self.underLeftViewController.edgesForExtendedLayout & UIRectEdgeTop)) {
        CGFloat topLayoutGuideLength    = [self.topLayoutGuide length];
        containerViewFrame.origin.y     = topLayoutGuideLength;
        containerViewFrame.size.height -= topLayoutGuideLength;
    }
    
    if (!(self.underLeftViewController.edgesForExtendedLayout & UIRectEdgeBottom)) {
        CGFloat bottomLayoutGuideLength = [self.bottomLayoutGuide length];
        containerViewFrame.size.height -= bottomLayoutGuideLength;
    }
    
    if (!(self.underLeftViewController.edgesForExtendedLayout & UIRectEdgeRight)) {
        containerViewFrame.size.width = self.anchorRightRevealAmount;
    }
    
    return containerViewFrame;
}

- (CGRect)underRightViewCalculatedFrameForTopViewPosition:(MenuSlidingViewControllerTopViewPosition)position
{
    CGRect frameFromDelegate = [self frameFromDelegateForViewController:self.underRightViewController
                                                        topViewPosition:position];
    if (!CGRectIsInfinite(frameFromDelegate)) return frameFromDelegate;
    
    CGRect containerViewFrame = self.view.bounds;
    
    if (!(self.underRightViewController.edgesForExtendedLayout & UIRectEdgeTop)) {
        CGFloat topLayoutGuideLength    = [self.topLayoutGuide length];
        containerViewFrame.origin.y     = topLayoutGuideLength;
        containerViewFrame.size.height -= topLayoutGuideLength;
    }
    
    if (!(self.underRightViewController.edgesForExtendedLayout & UIRectEdgeBottom)) {
        CGFloat bottomLayoutGuideLength = [self.bottomLayoutGuide length];
        containerViewFrame.size.height -= bottomLayoutGuideLength;
    }
    
    if (!(self.underRightViewController.edgesForExtendedLayout & UIRectEdgeLeft)) {
        containerViewFrame.origin.x   = self.anchorLeftPeekAmount;
        containerViewFrame.size.width = self.anchorLeftRevealAmount;
    }
    
    return containerViewFrame;
}

- (CGRect)frameFromDelegateForViewController:(UIViewController*)viewController
                             topViewPosition:(MenuSlidingViewControllerTopViewPosition)topViewPosition
{
    CGRect frame = CGRectInfinite;
    
    if ([(NSObject *)self.delegate respondsToSelector:@selector(slidingViewController:layoutControllerForTopViewPosition:)]) {
        id<MenuSlidingViewControllerLayout> layoutController = [self.delegate slidingViewController:self
                                                               layoutControllerForTopViewPosition:topViewPosition];
        
        if (layoutController) {
            frame = [layoutController slidingViewController:self
                                     frameForViewController:viewController
                                            topViewPosition:topViewPosition];
        }
    }
    
    return frame;
}

- (MenuSlidingViewControllerOperation)operationFromPosition:(MenuSlidingViewControllerTopViewPosition)fromPosition
                                               toPosition:(MenuSlidingViewControllerTopViewPosition)toPosition
{
    if (fromPosition == MenuSlidingViewControllerTopViewPositionCentered &&
        toPosition   == MenuSlidingViewControllerTopViewPositionAnchoredLeft) {
        return MenuSlidingViewControllerOperationAnchorLeft;
    } else if (fromPosition == MenuSlidingViewControllerTopViewPositionCentered &&
               toPosition   == MenuSlidingViewControllerTopViewPositionAnchoredRight) {
        return MenuSlidingViewControllerOperationAnchorRight;
    } else if (fromPosition == MenuSlidingViewControllerTopViewPositionAnchoredLeft &&
               toPosition   == MenuSlidingViewControllerTopViewPositionCentered) {
        return MenuSlidingViewControllerOperationResetFromLeft;
    } else if (fromPosition == MenuSlidingViewControllerTopViewPositionAnchoredRight &&
               toPosition   == MenuSlidingViewControllerTopViewPositionCentered) {
        return MenuSlidingViewControllerOperationResetFromRight;
    } else {
        return MenuSlidingViewControllerOperationNone;
    }
}

- (void)animateOperation:(MenuSlidingViewControllerOperation)operation
{
    if (![self operationIsValid:operation]){
        _isInteractive = NO;
        return;
    }
    if (self.transitionInProgress) return;
    
    self.view.userInteractionEnabled = NO;
    
    self.transitionInProgress = YES;
    
    self.currentOperation = operation;
    
    if ([(NSObject*)self.delegate respondsToSelector:@selector(slidingViewController:animationControllerForOperation:topViewController:)]) {
        self.currentAnimationController = [self.delegate slidingViewController:self
                                               animationControllerForOperation:operation
                                                             topViewController:self.topViewController];
        
        if ([(NSObject *)self.delegate respondsToSelector:@selector(slidingViewController:interactionControllerForAnimationController:)]) {
            self.currentInteractiveTransition = [self.delegate slidingViewController:self
                                         interactionControllerForAnimationController:self.currentAnimationController];
        } else {
            self.currentInteractiveTransition = nil;
        }
    } else {
        self.currentAnimationController = nil;
    }
    
    if (self.currentAnimationController) {
        if (self.currentInteractiveTransition) {
            _isInteractive = YES;
        } else {
            self.defaultInteractiveTransition.animationController = self.currentAnimationController;
            self.currentInteractiveTransition = self.defaultInteractiveTransition;
        }
    } else {
        self.currentAnimationController = self.defaultAnimationController;
        
        self.defaultInteractiveTransition.animationController = self.currentAnimationController;
        self.currentInteractiveTransition = self.defaultInteractiveTransition;
    }
    
    [self beginAppearanceTransitionForOperation:operation];
    
    [self.defaultAnimationController setValue:self.coordinatorAnimations forKey:@"coordinatorAnimations"];
    [self.defaultAnimationController setValue:self.coordinatorCompletion forKey:@"coordinatorCompletion"];
    [self.defaultInteractiveTransition setValue:self.coordinatorInteractionEnded forKey:@"coordinatorInteractionEnded"];
    
    if ([self isInteractive]) {
        [self.currentInteractiveTransition startInteractiveTransition:self];
    } else {
        [self.currentAnimationController animateTransition:self];
    }
}

- (BOOL)operationIsValid:(MenuSlidingViewControllerOperation)operation
{
    if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredLeft) {
        if (operation == MenuSlidingViewControllerOperationResetFromLeft) return YES;
    } else if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredRight) {
        if (operation == MenuSlidingViewControllerOperationResetFromRight) return YES;
    } else if (self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionCentered) {
        if (operation == MenuSlidingViewControllerOperationAnchorLeft  && self.underRightViewController) return YES;
        if (operation == MenuSlidingViewControllerOperationAnchorRight && self.underLeftViewController)  return YES;
    }
    
    return NO;
}

- (void)beginAppearanceTransitionForOperation:(MenuSlidingViewControllerOperation)operation
{
    UIViewController *viewControllerWillAppear    = [self viewControllerWillAppearForSuccessfulOperation:operation];
    UIViewController *viewControllerWillDisappear = [self viewControllerWillDisappearForSuccessfulOperation:operation];
    
    [viewControllerWillAppear    beginAppearanceTransition:YES animated:_isAnimated];
    [viewControllerWillDisappear beginAppearanceTransition:NO animated:_isAnimated];
}

- (void)endAppearanceTransitionForOperation:(MenuSlidingViewControllerOperation)operation isCancelled:(BOOL)canceled
{
    UIViewController *viewControllerWillAppear    = [self viewControllerWillAppearForSuccessfulOperation:operation];
    UIViewController *viewControllerWillDisappear = [self viewControllerWillDisappearForSuccessfulOperation:operation];
    
    if (canceled) {
        [viewControllerWillDisappear beginAppearanceTransition:YES animated:_isAnimated];
        [viewControllerWillDisappear endAppearanceTransition];
        [viewControllerWillAppear beginAppearanceTransition:NO animated:_isAnimated];
        [viewControllerWillAppear endAppearanceTransition];
    } else {
        [viewControllerWillDisappear endAppearanceTransition];
        [viewControllerWillAppear endAppearanceTransition];
    }
}

- (UIViewController*)viewControllerWillAppearForSuccessfulOperation:(MenuSlidingViewControllerOperation)operation
{
    UIViewController *viewControllerWillAppear = nil;
    
    if (operation == MenuSlidingViewControllerOperationAnchorLeft) {
        viewControllerWillAppear = self.underRightViewController;
    } else if (operation == MenuSlidingViewControllerOperationAnchorRight) {
        viewControllerWillAppear = self.underLeftViewController;
    }
    
    return viewControllerWillAppear;
}

- (UIViewController*)viewControllerWillDisappearForSuccessfulOperation:(MenuSlidingViewControllerOperation)operation
{
    UIViewController *viewControllerWillDisappear = nil;
    
    if (operation == MenuSlidingViewControllerOperationResetFromLeft) {
        viewControllerWillDisappear = self.underRightViewController;
    } else if (operation == MenuSlidingViewControllerOperationResetFromRight) {
        viewControllerWillDisappear = self.underLeftViewController;
    }
    
    return viewControllerWillDisappear;
}

- (void)updateTopViewGestures
{
    BOOL topViewIsAnchored = self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredLeft ||
    self.currentTopViewPosition == MenuSlidingViewControllerTopViewPositionAnchoredRight;
    UIView *topView = self.topViewController.view;
    
    if (topViewIsAnchored) {
        if (self.topViewAnchoredGesture & MenuSlidingViewControllerAnchoredGestureDisabled) {
            topView.userInteractionEnabled = NO;
        } else {
            self.gestureView.frame = topView.frame;
            
            if (self.topViewAnchoredGesture & MenuSlidingViewControllerAnchoredGesturePanning &&
                ![self.customAnchoredGesturesViewMap objectForKey:self.panGesture]) {
                [self.customAnchoredGesturesViewMap setObject:self.panGesture.view forKey:self.panGesture];
                [self.panGesture.view removeGestureRecognizer:self.panGesture];
                [self.gestureView addGestureRecognizer:self.panGesture];
                if (!self.gestureView.superview) [self.view insertSubview:self.gestureView aboveSubview:topView];
            }
            
            if (self.topViewAnchoredGesture & MenuSlidingViewControllerAnchoredGestureTapping &&
                ![self.customAnchoredGesturesViewMap objectForKey:self.resetTapGesture]) {
                [self.gestureView addGestureRecognizer:self.resetTapGesture];
                if (!self.gestureView.superview) [self.view insertSubview:self.gestureView aboveSubview:topView];
            }
            
            if (self.topViewAnchoredGesture & MenuSlidingViewControllerAnchoredGestureCustom) {
                for (UIGestureRecognizer *gesture in self.customAnchoredGestures) {
                    if (![self.customAnchoredGesturesViewMap objectForKey:gesture]) {
                        [self.customAnchoredGesturesViewMap setObject:gesture.view forKey:gesture];
                        [gesture.view removeGestureRecognizer:gesture];
                        [self.gestureView addGestureRecognizer:gesture];
                    }
                }
                if (!self.gestureView.superview) [self.view insertSubview:self.gestureView aboveSubview:topView];
            }
        }
    } else {
        self.topViewController.view.userInteractionEnabled = YES;
        [self.gestureView removeFromSuperview];
        for (UIGestureRecognizer *gesture in self.customAnchoredGestures) {
            UIView *originalView = [self.customAnchoredGesturesViewMap objectForKey:gesture];
            if ([originalView isDescendantOfView:self.topViewController.view]) {
                [originalView addGestureRecognizer:gesture];
            }
        }
        if ([self.customAnchoredGesturesViewMap objectForKey:self.panGesture]) {
            UIView *view = [self.customAnchoredGesturesViewMap objectForKey:self.panGesture];
            if ([view isDescendantOfView:self.topViewController.view]) {
                [view addGestureRecognizer:self.panGesture];
            }
        }
        [self.customAnchoredGesturesViewMap removeAllObjects];
    }
}

- (void)statusBarResize:(NSNotification *)notification
{
//    NSLog(@"notification: %@", notification);
    
    if ([notification.userInfo valueForKey:@"UIApplicationStatusBarFrameUserInfoKey"]) {
        NSValue *statusBarFrameRect = [notification.userInfo valueForKey:@"UIApplicationStatusBarFrameUserInfoKey"];
        CGRect statusBarFrame;
        [statusBarFrameRect getValue:&statusBarFrame];
        
        if (statusBarFrame.size.height > 0.f & statusBarFrame.size.height < 40.f) {
            _statusBarResizeDown = YES;
            _statusBarResizeUp = NO;
        } else if (statusBarFrame.size.height >= 40.f) {
            _statusBarResizeUp = YES;
            _statusBarResizeDown = NO;
        }
        
        
    }
    
}

#pragma mark - UIPanGestureRecognizer action

- (void)detectPanGestureRecognizer:(UIPanGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self.view endEditing:YES];
        _isInteractive = YES;
    }
    
    [self.defaultInteractiveTransition updateTopViewHorizontalCenterWithRecognizer:recognizer];
    _isInteractive = NO;
}

#pragma mark - UIViewControllerTransitionCoordinatorContext

- (BOOL)initiallyInteractive
{
    return _isAnimated && _isInteractive;
}

- (BOOL)isCancelled
{
    return _transitionWasCancelled;
}

- (NSTimeInterval)transitionDuration
{
    return [self.currentAnimationController transitionDuration:self];
}

- (CGFloat)percentComplete
{
    return self.currentAnimationPercentage;
}

- (CGFloat)completionVelocity
{
    return 1.0;
}

- (UIViewAnimationCurve)completionCurve
{
    return UIViewAnimationCurveLinear;
}

#pragma mark - UIViewControllerContextTransitioning and UIViewControllerTransitionCoordinatorContext

- (UIView*)containerView
{
    return self.view;
}

- (BOOL)isAnimated
{
    return _isAnimated;
}

- (BOOL)isInteractive
{
    return _isInteractive;
}

- (BOOL)transitionWasCancelled
{
    return _transitionWasCancelled;
}

- (UIModalPresentationStyle)presentationStyle
{
    return UIModalPresentationCustom;
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete
{
    self.currentAnimationPercentage = percentComplete;
}

- (void)finishInteractiveTransition
{
    _transitionWasCancelled = NO;
}

- (void)cancelInteractiveTransition
{
    _transitionWasCancelled = YES;
}

- (void)completeTransition:(BOOL)didComplete
{
    if (self.currentOperation == MenuSlidingViewControllerOperationNone) return;
    
    if ([self transitionWasCancelled]) {
        if (self.currentOperation == MenuSlidingViewControllerOperationAnchorLeft) {
            _currentTopViewPosition = MenuSlidingViewControllerTopViewPositionCentered;
        } else if (self.currentOperation == MenuSlidingViewControllerOperationAnchorRight) {
            _currentTopViewPosition = MenuSlidingViewControllerTopViewPositionCentered;
        } else if (self.currentOperation == MenuSlidingViewControllerOperationResetFromLeft) {
            _currentTopViewPosition = MenuSlidingViewControllerTopViewPositionAnchoredLeft;
        } else if (self.currentOperation == MenuSlidingViewControllerOperationResetFromRight) {
            _currentTopViewPosition = MenuSlidingViewControllerTopViewPositionAnchoredRight;
        }
    } else {
        if (self.currentOperation == MenuSlidingViewControllerOperationAnchorLeft) {
            _currentTopViewPosition = MenuSlidingViewControllerTopViewPositionAnchoredLeft;
        } else if (self.currentOperation == MenuSlidingViewControllerOperationAnchorRight) {
            _currentTopViewPosition = MenuSlidingViewControllerTopViewPositionAnchoredRight;
            [[NSNotificationCenter defaultCenter] postNotificationName:kCSRMenuShowedNotification object:nil];
        } else if (self.currentOperation == MenuSlidingViewControllerOperationResetFromLeft) {
            _currentTopViewPosition = MenuSlidingViewControllerTopViewPositionCentered;
        } else if (self.currentOperation == MenuSlidingViewControllerOperationResetFromRight) {
            _currentTopViewPosition = MenuSlidingViewControllerTopViewPositionCentered;
            [[NSNotificationCenter defaultCenter] postNotificationName:kCSRMenuHiddenNotification object:nil];
        }
    }
    
    if ([self.currentAnimationController respondsToSelector:@selector(animationEnded:)]) {
        [self.currentAnimationController animationEnded:didComplete];
    }
    
    if (self.animationComplete) self.animationComplete();
    self.animationComplete = nil;
    
    [self updateTopViewGestures];
    [self endAppearanceTransitionForOperation:self.currentOperation isCancelled:[self transitionWasCancelled]];
    
    _transitionWasCancelled          = NO;
    _isInteractive                   = NO;
    self.coordinatorAnimations       = nil;
    self.coordinatorCompletion       = nil;
    self.coordinatorInteractionEnded = nil;
    self.currentAnimationPercentage  = 0;
    self.currentOperation            = MenuSlidingViewControllerOperationNone;
    self.transitionInProgress        = NO;
    self.view.userInteractionEnabled = YES;
    [UIViewController attemptRotationToDeviceOrientation];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIViewController*)viewControllerForKey:(NSString*)key
{
    if ([key isEqualToString:MenuTransitionContextTopViewControllerKey]) {
        return self.topViewController;
    } else if ([key isEqualToString:MenuTransitionContextUnderLeftControllerKey]) {
        return self.underLeftViewController;
    } else if ([key isEqualToString:MenuTransitionContextUnderRightControllerKey]) {
        return self.underRightViewController;
    }
    
    if (self.currentOperation == MenuSlidingViewControllerOperationAnchorLeft) {
        if (key == UITransitionContextFromViewControllerKey) return self.topViewController;
        if (key == UITransitionContextToViewControllerKey)   return self.underRightViewController;
    } else if (self.currentOperation == MenuSlidingViewControllerOperationAnchorRight) {
        if (key == UITransitionContextFromViewControllerKey) return self.topViewController;
        if (key == UITransitionContextToViewControllerKey)   return self.underLeftViewController;
    } else if (self.currentOperation == MenuSlidingViewControllerOperationResetFromLeft) {
        if (key == UITransitionContextFromViewControllerKey) return self.underRightViewController;
        if (key == UITransitionContextToViewControllerKey)   return self.topViewController;
    } else if (self.currentOperation == MenuSlidingViewControllerOperationResetFromRight) {
        if (key == UITransitionContextFromViewControllerKey) return self.underLeftViewController;
        if (key == UITransitionContextToViewControllerKey)   return self.topViewController;
    }
    
    return nil;
}

- (CGRect)initialFrameForViewController:(UIViewController*)vc
{
    if (self.currentOperation == MenuSlidingViewControllerOperationAnchorLeft) {
        if ([vc isEqual:self.topViewController]) return [self topViewCalculatedFrameForPosition:MenuSlidingViewControllerTopViewPositionCentered];
    } else if (self.currentOperation == MenuSlidingViewControllerOperationAnchorRight) {
        if ([vc isEqual:self.topViewController]) return [self topViewCalculatedFrameForPosition:MenuSlidingViewControllerTopViewPositionCentered];
    } else if (self.currentOperation == MenuSlidingViewControllerOperationResetFromLeft) {
        if ([vc isEqual:self.topViewController])        return [self topViewCalculatedFrameForPosition:MenuSlidingViewControllerTopViewPositionAnchoredLeft];
        if ([vc isEqual:self.underRightViewController]) return [self underRightViewCalculatedFrameForTopViewPosition:MenuSlidingViewControllerTopViewPositionAnchoredLeft];
    } else if (self.currentOperation == MenuSlidingViewControllerOperationResetFromRight) {
        if ([vc isEqual:self.topViewController])        return [self topViewCalculatedFrameForPosition:MenuSlidingViewControllerTopViewPositionAnchoredRight];
        if ([vc isEqual:self.underLeftViewController])  return [self underLeftViewCalculatedFrameForTopViewPosition:MenuSlidingViewControllerTopViewPositionAnchoredRight];
    }
    
    return CGRectZero;
}

- (CGRect)finalFrameForViewController:(UIViewController*)vc
{
    if (self.currentOperation == MenuSlidingViewControllerOperationAnchorLeft) {
        if (vc == self.topViewController)        return [self topViewCalculatedFrameForPosition:MenuSlidingViewControllerTopViewPositionAnchoredLeft];
        if (vc == self.underRightViewController) return [self underRightViewCalculatedFrameForTopViewPosition:MenuSlidingViewControllerTopViewPositionAnchoredLeft];
    } else if (self.currentOperation == MenuSlidingViewControllerOperationAnchorRight) {
        if (vc == self.topViewController) return [self topViewCalculatedFrameForPosition:MenuSlidingViewControllerTopViewPositionAnchoredRight];
        if (vc == self.underLeftViewController)  return [self underLeftViewCalculatedFrameForTopViewPosition:MenuSlidingViewControllerTopViewPositionAnchoredRight];
    } else if (self.currentOperation == MenuSlidingViewControllerOperationResetFromLeft) {
        if (vc == self.topViewController) return [self topViewCalculatedFrameForPosition:MenuSlidingViewControllerTopViewPositionCentered];
    } else if (self.currentOperation == MenuSlidingViewControllerOperationResetFromRight) {
        if (vc == self.topViewController) return [self topViewCalculatedFrameForPosition:MenuSlidingViewControllerTopViewPositionCentered];
    }
    
    return CGRectZero;
}

#pragma mark - UIViewControllerTransitionCoordinator

- (BOOL)animateAlongsideTransition:(void(^)(id<UIViewControllerTransitionCoordinatorContext>context))animation
                        completion:(void(^)(id<UIViewControllerTransitionCoordinatorContext>context))completion
{
    self.coordinatorAnimations = animation;
    self.coordinatorCompletion = completion;
    return YES;
}

- (BOOL)animateAlongsideTransitionInView:(UIView *)view
                               animation:(void(^)(id<UIViewControllerTransitionCoordinatorContext>context))animation
                              completion:(void(^)(id<UIViewControllerTransitionCoordinatorContext>context))completion
{
    self.coordinatorAnimations = animation;
    self.coordinatorCompletion = completion;
    return YES;
}

- (void)notifyWhenInteractionEndsUsingBlock:(void(^)(id<UIViewControllerTransitionCoordinatorContext>context))handler
{
    self.coordinatorInteractionEnded = handler;
}

@end
