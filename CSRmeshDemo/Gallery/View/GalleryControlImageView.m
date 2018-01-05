//
//  GalleryControlImageView.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/3.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "GalleryControlImageView.h"

@interface GalleryControlImageView ()

@property (nonatomic, weak) UIView *closestDropView;
@property (nonatomic, assign) CGRect originRect;
@property (nonatomic, assign) CGPoint originCenter;


@end

@implementation GalleryControlImageView

- (id)init {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        self.clipsToBounds = YES;
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureAction:)];
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureAction:)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
        
        [self addGestureRecognizer:panGesture];
        [self addGestureRecognizer:pinchGesture];
        [self addGestureRecognizer:longPressGesture];
        [self addGestureRecognizer:tapGesture];
        
    }
    return self;
}

- (void)addDropViewInCenter:(GalleryDropView *)view {
    [self addSubview:view];
    view.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

- (void)deleteDropView:(UIView *)view {
    if ([view isDescendantOfView:self]) {
        [view removeFromSuperview];
    }
}

#pragma mark - gestureAction

- (void)panGestureAction:(UIPanGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView:self];
    UIView *hitView = [self hitTest:touchPoint withEvent:nil];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            
            break;
        case UIGestureRecognizerStateChanged:
            if (_isEditing) {
                if ([hitView isKindOfClass:[GalleryDropView class]]) {
                    hitView.center = touchPoint;
                }
            }
            
            break;
        
        default:
            break;
    }
    
    
}

- (void)pinchGestureAction:(UIPinchGestureRecognizer *)sender {
    if (_isEditing) {
        switch (sender.state) {
            case UIGestureRecognizerStateBegan:
                _closestDropView = [self subviewClosestToCenter:[sender locationInView:self] inRegion:[self regionOfPinch:sender]];
                if (_closestDropView) {
                    _originRect = _closestDropView.frame;
                    _originCenter = _closestDropView.center;
                }
                break;
            case UIGestureRecognizerStateChanged:
                if (_closestDropView) {
                    CGFloat scale = sender.scale;
                    CGFloat updateW = _originRect.size.width*scale;
                    CGFloat updateH = _originRect.size.height*scale;
                    _closestDropView.frame = CGRectMake(_originCenter.x-updateW/2, _originCenter.y-updateH/2, updateW, updateH);
                    _closestDropView.layer.cornerRadius = MIN(updateW/2, updateH/2);
                }
                break;
            default:
                break;
        }
    } 
}

- (void)longPressGestureAction:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan && _isEditing) {
        CGPoint touchPoint = [sender locationInView:self];
        UIView *hitView = [self hitTest:touchPoint withEvent:nil];
        if ([hitView isKindOfClass:[GalleryDropView class]] && self.delegate && [self.delegate respondsToSelector:@selector(galleryControlImageViewDeleteDropView:)]) {
            [self.delegate galleryControlImageViewDeleteDropView:hitView];
        }
    }
}

- (void)tapGestureAction:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint touchPoint = [sender locationInView:self];
        UIView *hitView = [self hitTest:touchPoint withEvent:nil];
        if ([hitView isKindOfClass:[GalleryDropView class]]) {
            NSLog(@"dianji");
        }
    }
}

#pragma mark - pinchGesture help

- (UIView*)subviewClosestToCenter:(CGPoint)center inRegion:(CGRect)region {
    if (self.subviews.count==0) {
        return nil;
    }
    
    __block UIView *choosen = nil;
    __block CGFloat shortestDistance = -1;
    
    [self.subviews enumerateObjectsUsingBlock:^(UIView *subview,NSUInteger idx,BOOL *stop){
        if ([subview isKindOfClass:[GalleryDropView class]] && [self isThePoint:subview.center insideRegion:region]) {
            CGFloat myDistance = [self distanceFromPoint:subview.center toPoint:center];
            
            if (shortestDistance < 0) {
                shortestDistance = myDistance;
                choosen = subview;
            }
            else {
                if (myDistance<shortestDistance) {
                    shortestDistance = myDistance;
                    choosen = subview;
                }
            }
        }
    }];
    
    return choosen;
}

- (BOOL)isThePoint:(CGPoint)point insideRegion:(CGRect)region {
    return (point.x>=region.origin.x && point.x<=region.origin.y && point.y>=region.size.width && point.y<=region.size.height);
}

- (CGFloat)distanceFromPoint:(CGPoint)start toPoint:(CGPoint)end {
    CGFloat deltaX = start.x - end.x;
    CGFloat deltaY = start.y - end.y;
    
    return sqrtf(deltaX*deltaX + deltaY*deltaY);
}

- (CGRect)regionOfPinch:(UIPinchGestureRecognizer*)sender {
    if ([sender numberOfTouches] == 2) {
        CGPoint pointA = [sender locationOfTouch:0 inView:self];
        CGPoint pointB = [sender locationOfTouch:1 inView:self];
        
        return CGRectMake(MIN(pointA.x, pointB.x), MAX(pointA.x, pointB.x), MIN(pointA.y, pointB.y), MAX(pointA.y, pointB.y));
    }
    return CGRectZero;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
