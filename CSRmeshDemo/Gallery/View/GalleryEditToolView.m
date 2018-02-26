//
//  GalleryEditToolView.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/9.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "GalleryEditToolView.h"

@implementation GalleryEditToolView

- (id)init {
    self = [super init];
    if (self) {
        self.bounds = CGRectMake(0, 0, WIDTH, 30);
        self.backgroundColor = DARKORAGE;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(WIDTH-30, 0, 30, 30)];
        imageView.image = [UIImage imageNamed:@"burger"];
        [self addSubview:imageView];
        self.isLimitHeight = -1.0f;
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(toolViewPanGestureAction:)];
        [self addGestureRecognizer:panGesture];
    }
    return self;
}

- (void)toolViewPanGestureAction:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateChanged) {
        if (_isLimitHeight<0) {
            CGPoint touchPoint = [sender locationInView:self.superview];
            touchPoint.x = WIDTH/2.0f;
            self.center = touchPoint;
            if (self.delegate && [self.delegate respondsToSelector:@selector(adjustControlImageSize:adjustHeight:)]) {
                [self.delegate adjustControlImageSize:self.tag-100 adjustHeight:(touchPoint.y + 15.0)/WIDTH];
            }
        }
    }
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (_isLimitHeight>0) {
            [UIView animateWithDuration:0.3 animations:^{
                self.center = CGPointMake(WIDTH/2.0f, _isLimitHeight*WIDTH-15);
            }];
        }
        _isLimitHeight = -1.0f;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
