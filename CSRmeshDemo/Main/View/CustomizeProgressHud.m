//
//  CustomizeProgressHud.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/9/19.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "CustomizeProgressHud.h"
#import "JQProgressView.h"

@interface CustomizeProgressHud ()

@property (strong, nonatomic) JQProgressView *progressView;
@property (nonatomic,strong) UILabel *hint;
@property (nonatomic,strong) UILabel *progressNum;

@end

@implementation CustomizeProgressHud

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
//        self.backgroundColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor colorWithRed:246/255.0 green:246/255.0 blue:246/255.0 alpha:1];
        self.layer.cornerRadius = 14.0;
        self.layer.masksToBounds = YES;
        
        _progressView = [[JQProgressView alloc] initWithFrame:CGRectMake(5.0, 60, 260, 10)];
        _progressView.progressTintColor = DARKORAGE;
        _progressView.trackTintColor = [UIColor darkGrayColor];
        [self addSubview:_progressView];
        
        _hint = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 270, 60)];
        _hint.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        _hint.textAlignment = NSTextAlignmentCenter;
        _hint.numberOfLines = 0;
        [self addSubview:_hint];
        
        _progressNum = [[UILabel alloc] initWithFrame:CGRectMake(0, 70, 270, 60)];
        _progressNum.textColor = DARKORAGE;
        _progressNum.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_progressNum];
        
    }
    return self;
}

- (void)setText:(NSString *)text {
    _text = text;
    _hint.text = text;
}

- (void)updateProgress:(CGFloat)percentage {
    _progressNum.text =[NSString stringWithFormat:@"%.f%%",percentage*100];
    self.progressView.progress = percentage;
}

@end
