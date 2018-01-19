//
//  TopImageView.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "TopImageView.h"

@implementation TopImageView

+ (TopImageView *)sharedInstance {
    static dispatch_once_t onceToken;
    static TopImageView *shared = nil;
    dispatch_once(&onceToken, ^{
        shared = [[TopImageView alloc] init];
    });
    return shared;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
