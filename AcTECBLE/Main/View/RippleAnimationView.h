//
//  RippleAnimationView.h
//  AcTECBLE
//
//  Created by AcTEC on 2020/8/27.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#define ColorWithAlpha(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AnimationType) {
    AnimationTypeWithBackground,
    AnimationTypeWithoutBackground
};

NS_ASSUME_NONNULL_BEGIN

@interface RippleAnimationView : UIView

@property (nonatomic, assign) CGFloat multiple;
- (instancetype)initWithFrame:(CGRect)frame animationType:(AnimationType)animationType;
- (void)startAnimation;
- (void)stopAnimation;

@end

NS_ASSUME_NONNULL_END
