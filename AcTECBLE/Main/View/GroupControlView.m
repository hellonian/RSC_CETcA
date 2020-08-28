//
//  GroupControlView.m
//  AcTECBLE
//
//  Created by AcTEC on 2019/3/2.
//  Copyright © 2019 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "GroupControlView.h"
#import "PureLayout.h"
#import "DeviceModelManager.h"
#import "CSRDatabaseManager.h"
#import <CSRmesh/LightModelApi.h>

@implementation GroupControlView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (id)initWithFrame:(CGRect)frame threeColorTemperature:(BOOL)threeColorTemp colorTemperature:(BOOL)colorTemp RGB:(BOOL)rgb {
    self = [super initWithFrame:frame];
    if (self) {
        UIView *bgView = [[UIView alloc] init];
        bgView.backgroundColor = [UIColor blackColor];
        bgView.alpha = 0.3;
        [self addSubview:bgView];
        [bgView autoPinEdgesToSuperviewEdges];
        UIView *bottomView = [[UIView alloc] init];
        bottomView.backgroundColor = [UIColor colorWithRed:238/255.0 green:238/255.0 blue:243/255.0 alpha:1];
        [self addSubview:bottomView];
        [bottomView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [bottomView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [bottomView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [bottomView autoSetDimension:ALDimensionHeight toSize:34];
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        scrollView.backgroundColor = [UIColor colorWithRed:238/255.0 green:238/255.0 blue:243/255.0 alpha:1];
        [self addSubview:scrollView];
        [scrollView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [scrollView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [scrollView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:34.0];
        
        if (threeColorTemp) {
            _threeColorTempTitleLabel = [self drawTitleLabel:AcTECLocalizedStringFromTable(@"colorTemp", @"Localizable")];
            [scrollView addSubview:_threeColorTempTitleLabel];
            
            _threeColorTempChangeBtn = [self drawThreeColorTemperatureButton:AcTECLocalizedStringFromTable(@"change", @"Localizable")];
            [scrollView addSubview:_threeColorTempChangeBtn];
            [_threeColorTempChangeBtn autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_threeColorTempTitleLabel withOffset:5.0];
            [_threeColorTempChangeBtn autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self];
            [_threeColorTempChangeBtn autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self];
            [_threeColorTempChangeBtn autoSetDimension:ALDimensionHeight toSize:44.0];
            
            _threeColorTempResetBtn = [self drawThreeColorTemperatureButton:AcTECLocalizedStringFromTable(@"reset", @"Localizable")];
            [scrollView addSubview:_threeColorTempResetBtn];
            [_threeColorTempResetBtn autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_threeColorTempChangeBtn];
            [_threeColorTempResetBtn autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self];
            [_threeColorTempResetBtn autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self];
            [_threeColorTempResetBtn autoSetDimension:ALDimensionHeight toSize:44.0];
        }
        
        if (colorTemp) {
            _colorTempTitleLabel = [self drawTitleLabel:AcTECLocalizedStringFromTable(@"colorTemp", @"Localizable")];
            [scrollView addSubview:_colorTempTitleLabel];
            
            _colorTempIconImageView = [self drawIconImageView:@"Ico_cw"];
            [scrollView addSubview:_colorTempIconImageView];
            [self constraintIconImageView:_colorTempIconImageView topView:_colorTempTitleLabel];
            
            _colorTempLabel = [self drawValueLabel];
            _colorTempLabel.text = @"2700K";
            [scrollView addSubview:_colorTempLabel];
            [self constraintValueLabel:_colorTempLabel alignView:_colorTempIconImageView];
            
            _colorTempSlider = [self drawSlider:2700.0 :6500.0];
            [_colorTempSlider addTarget:self action:@selector(colorTemperatureSliderTouchDown:) forControlEvents:UIControlEventTouchDown];
            [_colorTempSlider addTarget:self action:@selector(colorTemperatureSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
            [_colorTempSlider addTarget:self action:@selector(colorTemperatureSliderTouchUpInSide:) forControlEvents:UIControlEventTouchUpInside];
            [_colorTempSlider addTarget:self action:@selector(colorTemperatureSliderTouchUpInSide:) forControlEvents:UIControlEventTouchUpOutside];
            [scrollView addSubview:_colorTempSlider];
            [self constraintSlider:_colorTempSlider leftView:_colorTempIconImageView rightView:_colorTempLabel];
        }
        
        if (rgb) {
            _rgbTitleLabel = [self drawTitleLabel:AcTECLocalizedStringFromTable(@"color", @"Localizable")];
            [scrollView addSubview:_rgbTitleLabel];
            
            _rgbIconImageView = [self drawIconImageView:@"Ico_color"];
            [scrollView addSubview:_rgbIconImageView];
            [self constraintIconImageView:_rgbIconImageView topView:_rgbTitleLabel];
            
            _colorLabel = [self drawValueLabel];
            _colorLabel.text = @"0";
            [scrollView addSubview:_colorLabel];
            [self constraintValueLabel:_colorLabel alignView:_rgbIconImageView];
            
            _colorSlider = [[ColorSlider alloc] initWithFrame:CGRectZero];
            _colorSlider.delegate = self;
            [scrollView addSubview:_colorSlider];
            [self constraintSlider:_colorSlider leftView:_rgbIconImageView rightView:_colorLabel];
            [_colorSlider autoSetDimension:ALDimensionHeight toSize:31.0];
            
            _colorSatTitleLabel = [self drawTitleLabel:AcTECLocalizedStringFromTable(@"colorSat", @"Localizable")];
            [scrollView addSubview:_colorSatTitleLabel];
            [self constraintTitleLabel:_colorSatTitleLabel toEdge:ALEdgeBottom topView:_rgbIconImageView withOffset:24.0];
            
            _colorSatIconImageView = [self drawIconImageView:@"Ico_cs"];
            [scrollView addSubview:_colorSatIconImageView];
            [self constraintIconImageView:_colorSatIconImageView topView:_colorSatTitleLabel];
            
            _colorSatLabel = [self drawValueLabel];
            _colorSatLabel.text = @"0%";
            [scrollView addSubview:_colorSatLabel];
            [self constraintValueLabel:_colorSatLabel alignView:_colorSatIconImageView];
            
            _colorSatSlider = [self drawSlider:0.01 :1];
            [_colorSatSlider addTarget:self action:@selector(colorSaturationSliderTouchDown:) forControlEvents:UIControlEventTouchDown];
            [_colorSatSlider addTarget:self action:@selector(colorSaturationSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
            [_colorSatSlider addTarget:self action:@selector(colorSaturationSliderTouchUpInSide:) forControlEvents:UIControlEventTouchUpInside];
            [_colorSatSlider addTarget:self action:@selector(colorSaturationSliderTouchUpInSide:) forControlEvents:UIControlEventTouchUpOutside];
            [scrollView addSubview:_colorSatSlider];
            [self constraintSlider:_colorSatSlider leftView:_colorSatIconImageView rightView:_colorSatLabel];
            
            _colorSquare = [[ColorSquare alloc] initWithFrame:CGRectZero];
            _colorSquare.delegate = self;
            [scrollView addSubview:_colorSquare];
            [self constraintColorSquareView:_colorSquare topView:_colorSatIconImageView];
            
            _musicTitleLabel = [self drawTitleLabel:AcTECLocalizedStringFromTable(@"musicFlow", @"Localizable")];
            [scrollView addSubview:_musicTitleLabel];
            [self constraintTitleLabel:_musicTitleLabel toEdge:ALEdgeBottom topView:_colorSquare withOffset:30.0];
            
            NSMutableArray *images = [[NSMutableArray alloc] init];
            for (int i=0; i<7; i++) {
                UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"music_%d",i]];
                [images addObject:image];
            }
            _musicImageView = [[UIImageView alloc] init];
            _musicImageView.animationDuration = 1;
            _musicImageView.animationImages = images;
            _musicImageView.userInteractionEnabled = YES;
            [scrollView addSubview:_musicImageView];
            
            musicBehavior = YES;
            [SoundListenTool sharedInstance].delegate = self;
            
            _musicBtn = [[UIButton alloc] init];
            if ([SoundListenTool sharedInstance].audioRecorder.recording) {
                [_musicBtn setBackgroundImage:[UIImage imageNamed:@"musicHighlight"] forState:UIControlStateNormal];
                [_musicImageView startAnimating];
            }else {
                [_musicImageView stopAnimating];
                [_musicBtn setBackgroundImage:[UIImage imageNamed:@"music"] forState:UIControlStateNormal];
            }
            [_musicBtn addTarget:self action:@selector(playPause:) forControlEvents:UIControlEventTouchUpInside];
            [_musicImageView addSubview:_musicBtn];
            [_musicBtn autoPinEdgesToSuperviewEdges];
            
            [_musicImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [_musicImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_musicTitleLabel withOffset:5.0];
            [_musicImageView autoSetDimensionsToSize:CGSizeMake(148.0, 148.0)];
            
        }
        
        if (threeColorTemp && !colorTemp && !rgb) {
            [self constraintScrollView:scrollView contentHeight:123.0];
            
            [self constraintTitleLabel:_threeColorTempTitleLabel toEdge:ALEdgeTop topView:scrollView withOffset:10.0];
        }
        
        else if (threeColorTemp && colorTemp && !rgb) {
            [self constraintScrollView:scrollView contentHeight:202.0];
            
            [self constraintTitleLabel:_threeColorTempTitleLabel toEdge:ALEdgeTop topView:scrollView withOffset:10.0];
            
            [self constraintTitleLabel:_colorTempTitleLabel toEdge:ALEdgeBottom topView:_threeColorTempResetBtn withOffset:10.0];
        }
        
        else if (threeColorTemp && colorTemp && rgb) {
            [self constraintScrollView:scrollView contentHeight:763.0];
            
            [self constraintTitleLabel:_threeColorTempTitleLabel toEdge:ALEdgeTop topView:scrollView withOffset:10.0];
            
            [self constraintTitleLabel:_colorTempTitleLabel toEdge:ALEdgeBottom topView:_threeColorTempResetBtn withOffset:10.0];
            
            [self constraintTitleLabel:_rgbTitleLabel toEdge:ALEdgeBottom topView:_colorTempIconImageView withOffset:24.0];
        }
        
        else if (!threeColorTemp && colorTemp && !rgb) {
            [self constraintScrollView:scrollView contentHeight:79.0];
            
            [self constraintTitleLabel:_colorTempTitleLabel toEdge:ALEdgeTop topView:scrollView withOffset:10.0];
        }
        
        else if (!threeColorTemp && colorTemp && rgb) {
            [self constraintScrollView:scrollView contentHeight:640.0];
            
            [self constraintTitleLabel:_colorTempTitleLabel toEdge:ALEdgeTop topView:scrollView withOffset:10.0];
            
            [self constraintTitleLabel:_rgbTitleLabel toEdge:ALEdgeBottom topView:_colorTempIconImageView withOffset:24.0];
        }
            
        else if (!threeColorTemp && !colorTemp && rgb) {
            [self constraintScrollView:scrollView contentHeight:561.0];
            
            [self constraintTitleLabel:_rgbTitleLabel toEdge:ALEdgeTop topView:scrollView withOffset:10.0];
        }
    }
    return self;
}

- (void)constraintScrollView:(UIScrollView *)scrollView contentHeight:(CGFloat)contentHeight {
    if (HEIGHT-127 > contentHeight) {
        [scrollView autoSetDimension:ALDimensionHeight toSize:contentHeight];
    }else {
        [scrollView autoSetDimension:ALDimensionHeight toSize:HEIGHT-127];
    }
    scrollView.contentSize = CGSizeMake(WIDTH, contentHeight);
}

- (void)constraintTitleLabel:(UIView *)titleLabel toEdge:(ALEdge)edge topView:(UIView *)topView withOffset:(CGFloat)offset {
    [titleLabel autoSetDimensionsToSize:CGSizeMake(200.0, 20.0)];
    [titleLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self withOffset:20.0];
    [titleLabel autoPinEdge:ALEdgeTop toEdge:edge ofView:topView withOffset:offset];
}

- (void)constraintIconImageView:(UIView *)iconImageView topView:(UIView *)topView {
    [iconImageView autoSetDimensionsToSize:CGSizeMake(16.0, 16.0)];
    [iconImageView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self withOffset:14.0];
    [iconImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:topView withOffset:19.0];
}

- (void)constraintValueLabel:(UIView *)valueLabel alignView:(UIView *)alignView {
    [valueLabel autoSetDimensionsToSize:CGSizeMake(45.0, 20.0)];
    [valueLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:alignView];
    [valueLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self withOffset:-15.0];
}

- (void)constraintSlider:(UIView *)slider leftView:(UIView *)leftView rightView:(UIView *)rightView {
    [slider autoAlignAxis:ALAxisHorizontal toSameAxisOfView:leftView];
    [slider autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:leftView withOffset:14];
    [slider autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:rightView withOffset:-8];
}

- (void)constraintColorSquareView:(UIView *)CSView topView:(UIView *)topView {
    [CSView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:topView withOffset:34.0];
    [CSView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self withOffset:20.0];
    [CSView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self withOffset:-20.0];
    [CSView autoSetDimension:ALDimensionHeight toSize:180.0];
}

- (UILabel *)drawTitleLabel:(NSString *)title {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.textColor = [UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1];
    titleLabel.font = [UIFont systemFontOfSize:14.0];
    titleLabel.text = title;
    return titleLabel;
}

- (UIImageView *)drawIconImageView:(NSString *)imageName {
    UIImageView *iconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    return iconImageView;
}

- (UISlider *)drawSlider:(CGFloat)minmum :(CGFloat)maxmum {
    UISlider *slider = [[UISlider alloc] init];
    slider.minimumValue = minmum;
    slider.maximumValue = maxmum;
    slider.minimumTrackTintColor = DARKORAGE;
    return slider;
}

- (UILabel *)drawValueLabel {
    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.textColor = [UIColor colorWithRed:85/255.0 green:85/255.0 blue:85/255.0 alpha:1];
    valueLabel.font = [UIFont systemFontOfSize:12.0];
    valueLabel.textAlignment = NSTextAlignmentRight;
    return valueLabel;
}

- (UIButton *)drawThreeColorTemperatureButton:(NSString *)title {
    UIButton *btn = [[UIButton alloc] init];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
    return btn;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self removeFromSuperview];
}

//调色温
- (void)colorTemperatureSliderTouchDown:(UISlider *)sender {
    if (musicBehavior) {
        if ([SoundListenTool sharedInstance].audioRecorder.recording) {
            [[SoundListenTool sharedInstance] stopRecord:_groupID];
        }
    }
    [[DeviceModelManager sharedInstance] setColorTemperatureWithDeviceId:_groupID withColorTemperature:@(sender.value) withState:UIGestureRecognizerStateBegan];
    _colorTempLabel.text = [NSString stringWithFormat:@"%.f K",sender.value];
}

- (void)colorTemperatureSliderValueChanged:(UISlider *)sender {
    [[DeviceModelManager sharedInstance] setColorTemperatureWithDeviceId:_groupID withColorTemperature:@(sender.value) withState:UIGestureRecognizerStateChanged];
    _colorTempLabel.text = [NSString stringWithFormat:@"%.f K",sender.value];
}

- (void)colorTemperatureSliderTouchUpInSide:(UISlider *)sender {
    [[DeviceModelManager sharedInstance] setColorTemperatureWithDeviceId:_groupID withColorTemperature:@(sender.value) withState:UIGestureRecognizerStateEnded];
    _colorTempLabel.text = [NSString stringWithFormat:@"%.f K",sender.value];
}
//颜色
- (void)colorSliderValueChanged:(CGFloat)myValue withState:(UIGestureRecognizerState)state {
    if (state == UIGestureRecognizerStateBegan) {
        if (musicBehavior) {
            if ([SoundListenTool sharedInstance].audioRecorder.recording) {
                [[SoundListenTool sharedInstance] stopRecord:_groupID];
            }
        }
    }
    UIColor *color = [UIColor colorWithHue:myValue saturation:_colorSatSlider.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_groupID withColor:color withState:state];
    _colorLabel.text = [NSString stringWithFormat:@"%.f",myValue*360];
    [_colorSquare locationPickView:myValue colorSaturation:_colorSatSlider.value];
}
//饱和度
- (void)colorSaturationSliderTouchDown:(UISlider *)sender {
    if (musicBehavior) {
        if ([SoundListenTool sharedInstance].audioRecorder.recording) {
            [[SoundListenTool sharedInstance] stopRecord:_groupID];
        }
    }
    UIColor *color = [UIColor colorWithHue:_colorSlider.myValue saturation:sender.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_groupID withColor:color withState:UIGestureRecognizerStateBegan];
    _colorSatLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value*100];
    [_colorSquare locationPickView:_colorSlider.myValue colorSaturation:sender.value];
}

- (void)colorSaturationSliderValueChanged:(UISlider *)sender {
    UIColor *color = [UIColor colorWithHue:_colorSlider.myValue saturation:sender.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_groupID withColor:color withState:UIGestureRecognizerStateChanged];
    _colorSatLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value*100];
    [_colorSquare locationPickView:_colorSlider.myValue colorSaturation:sender.value];
}

- (void)colorSaturationSliderTouchUpInSide:(UISlider *)sender {
    UIColor *color = [UIColor colorWithHue:_colorSlider.myValue saturation:sender.value brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_groupID withColor:color withState:UIGestureRecognizerStateEnded];
    _colorSatLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value*100];
    [_colorSquare locationPickView:_colorSlider.myValue colorSaturation:sender.value];
}
//色盘
- (void)tapColorChangeWithHue:(CGFloat)hue colorSaturation:(CGFloat)colorSatutation {
    if (musicBehavior) {
        if ([SoundListenTool sharedInstance].audioRecorder.recording) {
            [[SoundListenTool sharedInstance] stopRecord:_groupID];
        }
    }
    UIColor *color = [UIColor colorWithHue:hue saturation:colorSatutation brightness:1.0 alpha:1.0];
    [[LightModelApi sharedInstance] setColor:_groupID color:color duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
        
    } failure:^(NSError * _Nullable error) {
        
    }];
    _colorLabel.text = [NSString stringWithFormat:@"%.f",hue*360];
    [_colorSlider sliderMyValue:hue];
    _colorSatLabel.text = [NSString stringWithFormat:@"%.f%%",colorSatutation*100];
    [_colorSatSlider setValue:colorSatutation animated:YES];
}

- (void)panColorChangeWithHue:(CGFloat)hue colorSaturation:(CGFloat)colorSatutation state:(UIGestureRecognizerState)state {
    if (state == UIGestureRecognizerStateBegan) {
        if (musicBehavior) {
            if ([SoundListenTool sharedInstance].audioRecorder.recording) {
                [[SoundListenTool sharedInstance] stopRecord:_groupID];
            }
        }
    }
    UIColor *color = [UIColor colorWithHue:hue saturation:colorSatutation brightness:1.0 alpha:1.0];
    [[DeviceModelManager sharedInstance] setColorWithDeviceId:_groupID withColor:color withState:state];
    _colorLabel.text = [NSString stringWithFormat:@"%.f",hue*360];
    [_colorSlider sliderMyValue:hue];
    _colorSatLabel.text = [NSString stringWithFormat:@"%.f%%",colorSatutation*100];
    [_colorSatSlider setValue:colorSatutation animated:YES];
}

- (void)playPause:(UIButton *)sender {
    if ([SoundListenTool sharedInstance].audioRecorder.recording) {
        [[SoundListenTool sharedInstance] stopRecord:_groupID];
    }else {
        [[SoundListenTool sharedInstance] record:_groupID];
        [sender setBackgroundImage:[UIImage imageNamed:@"musicHighlight"] forState:UIControlStateNormal];
        [_musicImageView startAnimating];
    }
}

-(void)stopPlayButtonAnimation:(NSNumber *)deviceId {
    if ([deviceId isEqualToNumber:_groupID]) {
        [_musicImageView stopAnimating];
        [_musicBtn setBackgroundImage:[UIImage imageNamed:@"music"] forState:UIControlStateNormal];
    }
}

@end
