//
//  GalleryControlImageView.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/3.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "GalleryControlImageView.h"
#import "CSRDeviceEntity.h"

@interface GalleryControlImageView ()
{
    CGFloat distanceX;
    CGFloat distanceY;
    CGRect oldRect;
}

@property (nonatomic, weak) UIView *closestDropView;
@property (nonatomic, assign) CGRect originRect;
@property (nonatomic, assign) CGPoint originCenter;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

@end

@implementation GalleryControlImageView

- (id)init {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        
        self.drops = [[NSMutableArray alloc] init];
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteButton.frame = CGRectMake(-10, -10, 30, 30);
        [_deleteButton setBackgroundImage:[UIImage imageNamed:@"icon_delete"] forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_deleteButton];
        
//        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureAction:)];
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureAction:)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
        
//        [self addGestureRecognizer:panGesture];
        [self addGestureRecognizer:pinchGesture];
        [self addGestureRecognizer:longPressGesture];
        [self addGestureRecognizer:tapGesture];
        
    }
    return self;
}

- (void)addPanGestureRecognizer {
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    [self addGestureRecognizer:self.panGesture];
}

- (void)removePanGestureRecognizer {
    [self removeGestureRecognizer:self.panGesture];
}

- (void)deleteAction:(UIButton *)btn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(galleryControlImageViewDeleteAction:)]) {
        [self.delegate galleryControlImageViewDeleteAction:self];
    }
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

- (GalleryDropView *)addDropViewInRightLocation:(DropEntity *)drop {
    float boundWidth = [drop.boundRatio floatValue]*self.bounds.size.width;
    float centerX = [drop.centerXRatio floatValue]*self.bounds.size.width;
    float centerY = [drop.centerYRatio floatValue]*self.bounds.size.height;
    GalleryDropView *dropView = [[GalleryDropView alloc] initWithFrame:CGRectMake(centerX-boundWidth/2, centerY-boundWidth/2, boundWidth, boundWidth)];
    dropView.boundRatio = drop.boundRatio;
    dropView.centerXRatio = drop.centerXRatio;
    dropView.centerYRatio = drop.centerYRatio;
    dropView.deviceId = drop.device.deviceId;
    dropView.dropId = drop.dropID;
    dropView.kindName = drop.device.shortName;
    [self addSubview:dropView];
    [dropView adjustDropViewBgcolorWithdeviceId:dropView.deviceId];
    [self.drops addObject:dropView];
    
    return dropView;
}



- (void)adjustDropViewInRightLocation {
    
    [self.drops enumerateObjectsUsingBlock:^(GalleryDropView *dropView, NSUInteger idx, BOOL * _Nonnull stop) {
        float boundWidth = [dropView.boundRatio floatValue]*self.bounds.size.width;
        float centerX = [dropView.centerXRatio floatValue]*self.bounds.size.width;
        float centerY = [dropView.centerYRatio floatValue]*self.bounds.size.height;
        dropView.layer.cornerRadius = boundWidth/2;
        dropView.frame = CGRectMake(centerX-boundWidth/2, centerY-boundWidth/2, boundWidth, boundWidth);
    }];
}

#pragma mark - gestureAction

- (void)panGestureAction:(UIPanGestureRecognizer *)sender {
    
    CGPoint touchPoint = [sender locationInView:self.superview];

    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            distanceX = self.center.x - touchPoint.x;
            distanceY = self.center.y - touchPoint.y;
            oldRect = self.frame;
            
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            self.center = CGPointMake(touchPoint.x + distanceX, touchPoint.y + distanceY);

            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(galleryControlImageViewAdjustLocation:oldRect:)]) {
                [self.delegate galleryControlImageViewAdjustLocation:self oldRect:oldRect];
            }
            
            break;
        }
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
            case UIGestureRecognizerStateEnded:
                if (self.delegate && [self.delegate respondsToSelector:@selector(galleryControlImageViewPichDropView:)]) {
                    [self.delegate galleryControlImageViewPichDropView:@(YES)];
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
        if (self.delegate && [self.delegate respondsToSelector:@selector(galleryControlImageViewPresentDetailViewAction:)]) {
            [self.delegate galleryControlImageViewPresentDetailViewAction:self.galleryId];
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
