//
//  JQProgressView.m
//  Bluetooth
//
//  Created by Evan on 2016/12/7.
//  Copyright © 2016年 Evan. All rights reserved.
//

#import "JQProgressView.h"

@interface JQProgressView ()

/**
 *  内部
 */
@property (weak, nonatomic) UIView *innerView;
/**
 *  外部
 */
@property (weak, nonatomic) UIView *externalView;

@end

@implementation JQProgressView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialize];
}

- (void)initialize {
    self.backgroundColor = [UIColor clearColor];
}

- (UIView *)innerView {
    if (!_innerView) {
        UIView *innerView = [[UIView alloc] init];
        innerView.backgroundColor = [UIColor darkGrayColor];
        [self addSubview:innerView];
        _innerView = innerView;
    }
    return _innerView;
}

- (UIView *)externalView {
    if (!_externalView) {
        UIView * externalView = [[UIView alloc] init];
        externalView.backgroundColor = [UIColor whiteColor];
        [self insertSubview:externalView aboveSubview:self.innerView];
        _externalView = externalView;
    }
    return _externalView;
}

- (void)setProgressTintColor:(UIColor *)progressTintColor {
    _progressTintColor = progressTintColor;
    
    self.externalView.backgroundColor = progressTintColor;
}

- (void)setTrackTintColor:(UIColor *)trackTintColor {
    _trackTintColor = trackTintColor;
    
    self.innerView.backgroundColor = trackTintColor;
}


/**
 *  进度改变
 *
 *  @param progress <#progess description#>
 */
- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    if (animated) {
        [self setProgress:progress duration:0.6];
    } else {
        CGRect frame = self.bounds;
        frame.size.width *= progress;
        self.externalView.frame = frame;
    }
}

- (void)setProgress:(CGFloat)progress duration:(CGFloat)duration {
    _progress = progress;
    CGRect frame = self.bounds;
    frame.size.width *= progress;
    [UIView animateWithDuration:duration animations:^{
        self.externalView.frame = frame;
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.innerView.frame = self.bounds;
    CGRect frame = self.bounds;
    frame.size.width *= self.progress;
    self.externalView.frame = frame;
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = self.frame.size.height * 0.5;
}

@end
