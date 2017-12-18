//
//  LightDot.m
//  BluetoothAcTEC
//
//  Created by hua on 10/17/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "LightDot.h"

@implementation LightDot

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)darker {
    UIColor *primaryColor = self.highlightColor ? self.highlightColor : self.backgroundColor;

    if (CGColorGetNumberOfComponents(primaryColor.CGColor)==4) {
        const CGFloat *cmp = CGColorGetComponents(primaryColor.CGColor);
        CGFloat red = cmp[0];
        CGFloat green = cmp[1];
        CGFloat blue = cmp[2];
        CGFloat alpha = cmp[3];
        
        UIColor *darkerColor = [UIColor colorWithRed:red*0.618 green:green*0.618 blue:blue*0.618 alpha:alpha];
        self.backgroundColor = darkerColor;
    }
}

- (void)recoverToNormal {
    if (self.highlightColor) {
        self.backgroundColor = self.highlightColor;
    }
}

@end
