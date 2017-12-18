//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CSRMenuPercentDrivenInteractiveTransition : NSObject <UIViewControllerInteractiveTransitioning>

@property (nonatomic, strong) id<UIViewControllerAnimatedTransitioning> animationController;
@property (nonatomic, assign, readonly) CGFloat percentComplete;

- (void)updateInteractiveTransition:(CGFloat)percentComplete;
- (void)cancelInteractiveTransition;
- (void)finishInteractiveTransition;

@end
