//
//  ColorSquare.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/8/15.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ColorSquareDelegate <NSObject>
- (void)tapColorChangeWithHue:(CGFloat)hue colorSaturation:(CGFloat)colorSatutation;
- (void)panColorChangeWithHue:(CGFloat)hue colorSaturation:(CGFloat)colorSatutation state:(UIGestureRecognizerState)state;
@end

@interface ColorSquare : UIControl

@property (nonatomic,strong) UIImageView *colorImageView;
@property (nonatomic,strong) UIView *pickView;
@property (nonatomic,weak) id<ColorSquareDelegate> delegate;

- (void)locationPickView:(CGFloat)hue colorSaturation:(CGFloat)colorSaturation;

@end
