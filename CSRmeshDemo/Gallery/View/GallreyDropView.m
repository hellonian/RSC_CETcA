//
//  DropView.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/3.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "GalleryDropView.h"

@implementation GalleryDropView

- (id)initWithFrame:(CGRect)frame {
    CGFloat unit = MIN(frame.size.width, frame.size.height);
    CGRect fixFrame = CGRectMake(frame.origin.x, frame.origin.y, unit, unit);
    
    self = [super initWithFrame:fixFrame];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.alpha = 0.8;
        self.layer.cornerRadius = unit/2;
        self.layer.borderWidth =1;
        self.layer.borderColor = [UIColor darkGrayColor].CGColor;
        
        self.userInteractionEnabled = YES;
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
        
        [self addGestureRecognizer:panGesture];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

#pragma mark - gestureAction

- (void)panGestureAction:(UIPanGestureRecognizer *)sender {
    NSLog(@"pan");
    CGPoint touchPoint = [sender locationInView:self.superview];
//    UIView *hitView = [self hitTest:touchPoint withEvent:nil];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            
            break;
        case UIGestureRecognizerStateChanged:
            if (_isEditing) {

                if (touchPoint.x < self.frame.size.width/2.0f) {
                    touchPoint.x = self.frame.size.width/2.0f;
                }
                if (touchPoint.x > self.superview.frame.size.width - self.frame.size.width/2.0f) {
                    touchPoint.x = self.superview.frame.size.width - self.frame.size.width/2.0f;
                }
                if (touchPoint.y < self.frame.size.height/2.0f) {
                    touchPoint.y = self.frame.size.height/2.0f;
                }
                if (touchPoint.y > self.superview.frame.size.height - self.frame.size.height/2.0f) {
                    touchPoint.y = self.superview.frame.size.height - self.frame.size.height/2.0f;
                }
                self.center = touchPoint;
            }
            
            break;
            
        default:
            break;
    }
    
    
}

- (void)tapGestureAction:(UITapGestureRecognizer *)sender {
    NSLog(@"tap");
    if (sender.state == UIGestureRecognizerStateEnded) {
        NSLog(@"%@",self.deviceId);
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
