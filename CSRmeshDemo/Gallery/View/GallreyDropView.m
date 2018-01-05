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
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
