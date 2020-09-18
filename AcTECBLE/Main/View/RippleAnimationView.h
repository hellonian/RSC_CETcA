//
//  RippleAnimationView.h
//  AcTECBLE
//
//  Created by AcTEC on 2020/8/27.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

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
