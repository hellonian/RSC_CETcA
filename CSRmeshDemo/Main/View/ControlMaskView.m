//
//  ControlMaskView.m
//  BluetoothAcTEC
//
//  Created by hua on 10/10/16.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "ControlMaskView.h"
#import "PureLayout.h"

#import "JQProgressView.h"

#define kProgressWidth 300

@interface ControlMaskView ()

@property (nonatomic,strong) UILabel *hint;

@property (strong, nonatomic) JQProgressView *progressView;

@end

@implementation ControlMaskView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        _progressView = [[JQProgressView alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-kProgressWidth)*0.5, 65, kProgressWidth, 10)];
        _progressView.progressTintColor = [UIColor whiteColor];
        _progressView.trackTintColor = [UIColor grayColor];
        [self addSubview:_progressView];
        
        _hint = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 82, 82)];
        _hint.backgroundColor = [UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0];
        _hint.layer.cornerRadius = 41.0;
        _hint.layer.masksToBounds = YES;
        _hint.textAlignment = NSTextAlignmentCenter;
        _hint.font = [UIFont systemFontOfSize:32];
        _hint.textColor = [UIColor colorWithRed:234.0/255.0 green:94.0/255.0 blue:18.0/255.0 alpha:1.0];
        [self addSubview:self.hint];
        
        [self.hint autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.hint autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self withOffset:80];
        [self.hint autoSetDimensionsToSize:CGSizeMake(82, 82)];
    }
    
    return self;
}

- (void)updateProgress:(CGFloat)percentage withText:(NSString *)text {
    
    self.hint.text = text;
    self.progressView.progress = percentage;
    
    if (percentage < 0.15) {
        percentage = 0.15;
    }
    if (percentage > 0.75) {
        percentage = 0.75;
    }
    CGFloat updateCmp = 0.4 + 0.6*percentage;
    self.backgroundColor = [UIColor colorWithRed:updateCmp green:updateCmp blue:updateCmp alpha:0.8];
}

@end
