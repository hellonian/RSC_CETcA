//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import "CSRMenuPercentDrivenInteractiveTransition.h"

@interface CSRMenuPercentDrivenInteractiveTransition ()

@property (nonatomic, assign) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, assign) BOOL isActive;

- (void)removeAnimationsRecursively:(CALayer *)layer;

@end

@implementation CSRMenuPercentDrivenInteractiveTransition

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.isActive = YES;
    self.transitionContext = transitionContext;
    
    CALayer *containerLayer = [self.transitionContext containerView].layer;
    [self removeAnimationsRecursively:containerLayer];
    [self.animationController animateTransition:transitionContext];
    [self updateInteractiveTransition:0];
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    if (!self.isActive) return;
    
    [self.transitionContext updateInteractiveTransition:_percentComplete];
    
    CGFloat boundedPercentage;
    if (percentComplete > 1.0) {
        boundedPercentage = 1.0;
    } else if (percentComplete < 0.0) {
        boundedPercentage = 0.0;
    } else {
        boundedPercentage = percentComplete;
    }
    
    _percentComplete = boundedPercentage;
    CALayer *layer = [self.transitionContext containerView].layer;
    CFTimeInterval pausedTime = [self.animationController transitionDuration:self.transitionContext] * _percentComplete;
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
}

- (void)cancelInteractiveTransition {
    if (!self.isActive) return;
    
    [self.transitionContext cancelInteractiveTransition];
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(reversePausedAnimation:)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)finishInteractiveTransition {
    if (!self.isActive) return;
    self.isActive = NO;
    
    [self.transitionContext finishInteractiveTransition];
    
    CALayer *layer = [self.transitionContext containerView].layer;
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}

#pragma mark - CADisplayLink action

- (void)reversePausedAnimation:(CADisplayLink *)displayLink
{
    double percentInterval = displayLink.duration / [self.animationController transitionDuration:self.transitionContext];
    
    _percentComplete -= percentInterval;
    
    if (_percentComplete <= 0.0) {
        _percentComplete = 0.0;
        [displayLink invalidate];
    }
    
    [self updateInteractiveTransition:self.percentComplete];
    
    if (_percentComplete == 0.0) {
        self.isActive = NO;
        CALayer *layer = [self.transitionContext containerView].layer;
        [layer removeAllAnimations];
        layer.speed = 1.0;
    }
}

#pragma mark - Private

- (void)removeAnimationsRecursively:(CALayer *)layer
{
    if (layer.sublayers.count > 0) {
        for (CALayer *subLayer in layer.sublayers) {
            [subLayer removeAllAnimations];
            [self removeAnimationsRecursively:subLayer];
        }
    }
}

@end
