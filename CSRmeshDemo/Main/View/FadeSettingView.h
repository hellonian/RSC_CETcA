//
//  FadeSettingView.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/7/16.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FadeSettingViewDelegate <NSObject>

- (void)cancelFadeSetting;
- (void)saveFadeInTime:(NSInteger)fadeInTime fadeInUnit:(NSInteger)fadeInUnit FadeOutTime:(NSInteger)fadeOutTime fadeOutUnit:(NSInteger)fadeOutUnit channel:(NSInteger) channel;

@end

NS_ASSUME_NONNULL_BEGIN

@interface FadeSettingView : UIView<UITextFieldDelegate>

@property (nonatomic, strong) UILabel *fadeInUnitLabel;
@property (nonatomic, strong) UILabel *fadeOutUnitLabel;
@property (nonatomic, strong) UITextField *fadeInTime;
@property (nonatomic, strong) UITextField *fadeOutTime;
@property (nonatomic, strong) UILabel *channelLabel;
@property (nonatomic, weak) id <FadeSettingViewDelegate> delegate;
@property (nonatomic, strong) NSString *shortName;

@end

NS_ASSUME_NONNULL_END
