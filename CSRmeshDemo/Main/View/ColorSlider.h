//
//  ColorSlider.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/8/8.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ColorSliderDelegate <NSObject>

- (void)colorSliderValueChanged:(CGFloat)myValue  withState:(UIGestureRecognizerState)state;

@end
@interface ColorSlider : UIControl

@property (nonatomic,strong) UIImageView *sliderImageView;
@property (nonatomic,strong) UIButton *thumbButton;
@property (nonatomic,assign) CGFloat myValue;
@property (nonatomic,weak) id<ColorSliderDelegate> delegate;

- (void)sliderMyValue:(CGFloat)hue;

@end
