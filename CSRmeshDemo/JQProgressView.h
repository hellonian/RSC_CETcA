//
//  JQProgressView.h
//  Bluetooth
//
//  Created by Evan on 2016/12/7.
//  Copyright © 2016年 Evan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JQProgressView : UIView

@property (assign, nonatomic) CGFloat progress;

@property(nonatomic, strong, nullable) UIColor* progressTintColor;
@property(nonatomic, strong, nullable) UIColor* trackTintColor;

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;
- (void)setProgress:(CGFloat)progress duration:(CGFloat)duration;

@end
