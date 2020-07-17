//
//  FadeSettingView.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/7/16.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "FadeSettingView.h"
#import "CSRUtilities.h"

#define NUM @"0123456789"

@implementation FadeSettingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:246/255.0 green:246/255.0 blue:246/255.0 alpha:246/255.0];
        self.alpha = 0.9;
        self.layer.cornerRadius = 14;
        self.layer.masksToBounds = YES;
        
        UILabel *fadeInTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, 100, 20)];
        fadeInTitle.text = AcTECLocalizedStringFromTable(@"fadeintime", @"Localizable");
        fadeInTitle.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        fadeInTitle.font = [UIFont systemFontOfSize:16.0];
        [self addSubview:fadeInTitle];
        UIButton *fadeInUnit = [[UIButton alloc] initWithFrame:CGRectMake(181, 30, 80, 20)];
        [fadeInUnit setBackgroundColor:[UIColor whiteColor]];
        [fadeInUnit setImage:[UIImage imageNamed:@"Indicator"] forState:UIControlStateNormal];
        fadeInUnit.imageEdgeInsets = UIEdgeInsetsMake(0, 35, 0, -35);
        [fadeInUnit addTarget:self action:@selector(changeUnit:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:fadeInUnit];
        _fadeInUnitLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 50, 20)];
        _fadeInUnitLabel.tag = 1;
        _fadeInUnitLabel.text = @"100ms";
        _fadeInUnitLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        _fadeInUnitLabel.font = [UIFont systemFontOfSize:14.0];
        _fadeInUnitLabel.textAlignment = NSTextAlignmentCenter;
        [fadeInUnit addSubview:_fadeInUnitLabel];
        UILabel *fadeInX = [[UILabel alloc] initWithFrame:CGRectMake(151, 30, 30, 20)];
        fadeInX.text = @"×";
        fadeInX.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        fadeInX.textAlignment = NSTextAlignmentCenter;
        fadeInX.font = [UIFont systemFontOfSize:14.0];
        [self addSubview:fadeInX];
        _fadeInTime = [[UITextField alloc] initWithFrame:CGRectMake(101, 30, 50, 20)];
        _fadeInTime.tag = 2;
        [_fadeInTime setBackgroundColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1]];
        _fadeInTime.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        _fadeInTime.font = [UIFont systemFontOfSize:14.0];
        _fadeInTime.textAlignment = NSTextAlignmentRight;
        _fadeInTime.delegate = self;
        [self addSubview:_fadeInTime];
        
        UILabel *fadeOutTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 80, 100, 20)];
        fadeOutTitle.text = AcTECLocalizedStringFromTable(@"fadetime", @"Localizable");
        fadeOutTitle.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        fadeOutTitle.font = [UIFont systemFontOfSize:16.0];
        [self addSubview:fadeOutTitle];
        UIButton *fadeOutUnit = [[UIButton alloc] initWithFrame:CGRectMake(181, 80, 80, 20)];
        [fadeOutUnit setBackgroundColor:[UIColor whiteColor]];
        [fadeOutUnit setImage:[UIImage imageNamed:@"Indicator"] forState:UIControlStateNormal];
        fadeOutUnit.imageEdgeInsets = UIEdgeInsetsMake(0, 35, 0, -35);
        [fadeOutUnit addTarget:self action:@selector(changeUnit:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:fadeOutUnit];
        _fadeOutUnitLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 50, 20)];
        _fadeOutUnitLabel.tag = 1;
        _fadeOutUnitLabel.text = @"100ms";
        _fadeOutUnitLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        _fadeOutUnitLabel.font = [UIFont systemFontOfSize:14.0];
        _fadeOutUnitLabel.textAlignment = NSTextAlignmentCenter;
        [fadeOutUnit addSubview:_fadeOutUnitLabel];
        UILabel *fadeOutX = [[UILabel alloc] initWithFrame:CGRectMake(151, 80, 30, 20)];
        fadeOutX.text = @"×";
        fadeOutX.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        fadeOutX.textAlignment = NSTextAlignmentCenter;
        fadeOutX.font = [UIFont systemFontOfSize:14.0];
        [self addSubview:fadeOutX];
        _fadeOutTime = [[UITextField alloc] initWithFrame:CGRectMake(101, 80, 50, 20)];
        _fadeOutTime.tag = 3;
        [_fadeOutTime setBackgroundColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1]];
        _fadeOutTime.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        _fadeOutTime.font = [UIFont systemFontOfSize:14.0];
        _fadeOutTime.textAlignment = NSTextAlignmentRight;
        _fadeOutTime.delegate = self;
        [self addSubview:_fadeOutTime];
        
        UILabel *channelTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 130, 100, 20)];
        channelTitle.text = AcTECLocalizedStringFromTable(@"channel", @"Localizable");
        channelTitle.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        channelTitle.font = [UIFont systemFontOfSize:16.0];
        [self addSubview:channelTitle];
        UIButton *channelBtn = [[UIButton alloc] initWithFrame:CGRectMake(101, 130, 160, 20)];
        [channelBtn setBackgroundColor:[UIColor whiteColor]];
        [channelBtn setImage:[UIImage imageNamed:@"Indicator"] forState:UIControlStateNormal];
        channelBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 70, 0, -70);
        [channelBtn addTarget:self action:@selector(channelAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:channelBtn];
        _channelLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 0, 50, 20)];
        _channelLabel.tag = 1;
        _channelLabel.text = @"1";
        _channelLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        _channelLabel.font = [UIFont systemFontOfSize:14.0];
        _channelLabel.textAlignment = NSTextAlignmentCenter;
        [channelBtn addSubview:_channelLabel];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 180, 271, 1)];
        line.backgroundColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1];
        [self addSubview:line];
        UIButton *cancel = [[UIButton alloc] initWithFrame:CGRectMake(0, 181, 135, 44)];
        [cancel setTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") forState:UIControlStateNormal];
        [cancel setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [cancel addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:cancel];
        UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(135, 181, 1, 44)];
        line2.backgroundColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1];
        [self addSubview:line2];
        UIButton *save = [[UIButton alloc] initWithFrame:CGRectMake(136, 181, 135, 44)];
        [save setTitle:AcTECLocalizedStringFromTable(@"Save", @"Localizable") forState:UIControlStateNormal];
        [save setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [save addTarget:self action:@selector(saveAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:save];
        
        
    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self endEditing:YES];
}

- (void)changeUnit:(UIButton *)button {
    UILabel *label = [button viewWithTag:1];
    if ([label.text isEqualToString:@"100ms"]) {
        label.text = @"1s";
    }else if ([label.text isEqualToString:@"1s"]) {
        label.text = @"10s";
    }else if ([label.text isEqualToString:@"10s"]) {
        label.text = @"100ms";
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:NUM] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    if ([string isEqualToString:filtered]) {
        if (range.length == 1 && string.length == 0) {
            return YES;
        }else {
            NSString *txt = [textField.text stringByReplacingCharactersInRange:range withString:string];
            if ([txt integerValue] >= 1 && [txt integerValue] <= 16) {
                return YES;
            }
            return NO;
        }
    }else {
        return NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField.tag == 2) {
        if ([_fadeInUnitLabel.text isEqualToString:@"100ms"]) {
            if ([textField.text integerValue] < 8) {
                textField.text = @"8";
            }
        }
    }else if (textField.tag == 3) {
        if ([_fadeOutUnitLabel.text isEqualToString:@"100ms"]) {
            if ([textField.text integerValue] < 8) {
                textField.text = @"8";
            }
        }
    }
}

- (void)cancelAction:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancelFadeSetting)]) {
        [self.delegate cancelFadeSetting];
    }
}

- (void)saveAction:(UIButton *)sender {
    if ([_fadeInTime.text length]>0 && [_fadeOutTime.text length]>0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(saveFadeInTime:fadeInUnit:FadeOutTime:fadeOutUnit:channel:)]) {
            NSInteger channel = 1;
            if ([_channelLabel.text isEqualToString:@"1"]) {
                channel = 1;
            }else if ([_channelLabel.text isEqualToString:@"2"]) {
                channel = 2;
            }else if ([_channelLabel.text isEqualToString:@"both"]) {
                channel = 3;
            }else if ([_channelLabel.text isEqualToString:@"3"]) {
                channel = 4;
            }else if ([_channelLabel.text isEqualToString:@"all"]) {
                channel = 7;
            }
            NSInteger fadeInUnit = 0;
            if ([_fadeInUnitLabel.text isEqualToString:@"100ms"]) {
                fadeInUnit = 0;
            }else if ([_fadeInUnitLabel.text isEqualToString:@"1s"]) {
                fadeInUnit = 1;
            }else if ([_fadeInUnitLabel.text isEqualToString:@"10s"]) {
                fadeInUnit = 2;
            }
            NSInteger fadeOutUnit = 0;
            if ([_fadeOutUnitLabel.text isEqualToString:@"100ms"]) {
                fadeOutUnit = 0;
            }else if ([_fadeOutUnitLabel.text isEqualToString:@"1s"]) {
                fadeOutUnit = 1;
            }else if ([_fadeOutUnitLabel.text isEqualToString:@"10s"]) {
                fadeOutUnit = 2;
            }
            [self.delegate saveFadeInTime:[_fadeInTime.text integerValue] fadeInUnit:fadeInUnit FadeOutTime:[_fadeOutTime.text integerValue] fadeOutUnit:fadeOutUnit channel:channel];
        }
    }
}

- (void)channelAction:(UIButton *)sender {
    UILabel *label = [sender viewWithTag:1];
    if ([CSRUtilities belongToTwoChannelDimmer:_shortName]) {
        if ([label.text isEqualToString:@"1"]) {
            label.text = @"2";
        }else if ([label.text isEqualToString:@"2"]) {
            label.text = @"both";
        }else if ([label.text isEqualToString:@"both"]) {
            label.text = @"1";
        }
    }else if ([CSRUtilities belongToThreeChannelDimmer:_shortName]) {
        if ([label.text isEqualToString:@"1"]) {
            label.text = @"2";
        }else if ([label.text isEqualToString:@"2"]) {
            label.text = @"3";
        }else if ([label.text isEqualToString:@"2"]) {
            label.text = @"all";
        }else if ([label.text isEqualToString:@"all"]) {
            label.text = @"1";
        }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
