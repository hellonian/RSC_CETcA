//
//  HitTestAlrightCollectionView.m
//  BluetoothAcTEC
//
//  Created by hua on 10/10/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "HitTestAlrightCollectionView.h"

@interface HitTestAlrightCollectionView ()
@property (nonatomic,assign) BOOL allowExternalPanGestureRecognizer;
@end

@implementation HitTestAlrightCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    
    if (self) {
        self.allowExternalPanGestureRecognizer = NO;
        self.panGestureRecognizer.delegate = self;
    }
    
    return self;
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    __block UIView *hitCell = nil;
    
    [self.visibleCells enumerateObjectsUsingBlock:^(UICollectionViewCell *cell,NSUInteger idx,BOOL *stop){
        CGSize reference = cell.bounds.size;
        CGFloat offsetX = ABS(cell.center.x-point.x);
        CGFloat offsetY = ABS(cell.center.y-point.y);
        
        if (offsetX<=reference.width*0.5 && offsetY<=reference.height*0.5) {
            hitCell = cell;
            *stop = YES;
        }
    }];
    
    UIView *primaryHitObject = [super hitTest:point withEvent:event];
    
    if ([primaryHitObject isKindOfClass:[UIButton class]]) {
        return primaryHitObject;
    }
    
    if (hitCell) {
        self.allowExternalPanGestureRecognizer = YES;
        return hitCell;
    }
    
    self.allowExternalPanGestureRecognizer = NO;
    return [super hitTest:point withEvent:event];
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer==self.panGestureRecognizer) {
        return !self.allowExternalPanGestureRecognizer;
    }
    return YES;
}

@end
