//
//  TabBarButton.m
//  ActecBluetoothNorDic
//
//  Created by AcTEC on 2017/4/13.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import "TabBarButton.h"

@implementation TabBarButton

- (instancetype)initWithImage:(UIImage*)icon title:(NSString*)title
{
    self = [super init];
    if (self) {
        [self setImage:icon forState:UIControlStateNormal];
        [self setTitle:title forState:UIControlStateNormal];
        [self setAdjustsImageWhenHighlighted:NO];
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.titleLabel.font = [UIFont systemFontOfSize:10];    //10 is just fit
    
    CGFloat offsetImage = (self.bounds.size.height-self.imageView.bounds.size.height)*0.5;
    CGFloat offsetTitle = (self.bounds.size.height-self.titleLabel.bounds.size.height)*0.3;
    
    self.imageEdgeInsets = UIEdgeInsetsMake(-offsetImage, 0, offsetImage, -self.titleLabel.bounds.size.width);
    self.titleEdgeInsets = UIEdgeInsetsMake(offsetTitle, -self.imageView.bounds.size.width, -offsetTitle, 0);
}

@end
