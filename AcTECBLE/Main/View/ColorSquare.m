//
//  ColorSquare.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/8/15.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "ColorSquare.h"
#import "PureLayout.h"

@implementation ColorSquare

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.borderWidth = 1;
        self.layer.borderColor = [UIColor darkGrayColor].CGColor;
        _colorImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"colorSquare"]];
        [self addSubview:_colorImageView];
        [_colorImageView autoPinEdgesToSuperviewEdges];
        
        _pickView = [[UIView alloc] init];
        _pickView.frame = CGRectMake(0, 0, 30, 30);
        _pickView.backgroundColor = [UIColor clearColor];
        UIView *smallRound = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 10, 10)];
        smallRound.backgroundColor = [UIColor clearColor];
        smallRound.layer.borderWidth = 1;
        smallRound.layer.borderColor = [UIColor darkGrayColor].CGColor;
        smallRound.layer.masksToBounds = YES;
        smallRound.layer.cornerRadius = 5;
        [_pickView addSubview:smallRound];
        [self addSubview:_pickView];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSelectAction:)];
        [self addGestureRecognizer:tapGesture];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panSelectAction:)];
        [_pickView addGestureRecognizer:panGesture];
        
    }
    
    
    return self;
}


- (void)tapSelectAction:(UITapGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:self];
    _pickView.center = point;
    
    CGFloat hue = point.x/self.bounds.size.width;
    CGFloat colorStaturation = point.y/self.bounds.size.height;
    if (self.delegate && [self.delegate respondsToSelector:@selector(tapColorChangeWithHue:colorSaturation:)]) {
        [self.delegate tapColorChangeWithHue:hue colorSaturation:colorStaturation];
    }
}

- (void)panSelectAction:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:self];
    if (point.x < 0) {
        point.x = 0;
    }
    if (point.y < 0) {
        point.y = 0;
    }
    if (point.x > self.bounds.size.width) {
        point.x = self.bounds.size.width;
    }
    if (point.y > self.bounds.size.height) {
        point.y = self.bounds.size.height;
    }
    _pickView.center = point;
    
    CGFloat hue = point.x/(self.bounds.size.width+0.2);
    CGFloat colorStaturation = point.y/self.bounds.size.height;
    if (self.delegate && [self.delegate respondsToSelector:@selector(panColorChangeWithHue:colorSaturation:state:)]) {
        [self.delegate panColorChangeWithHue:hue colorSaturation:colorStaturation state:sender.state];
    }
}

- (void)locationPickView:(CGFloat)hue colorSaturation:(CGFloat)colorSaturation {
    CGFloat x = hue * self.bounds.size.width;
    CGFloat y = colorSaturation * self.bounds.size.height;
    [UIView animateWithDuration:0.2 animations:^{
        _pickView.center = CGPointMake(x, y);
    }];
}



@end
