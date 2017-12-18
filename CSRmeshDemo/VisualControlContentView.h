//
//  VisualControlContentView.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/23.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceModel.h"

@protocol VisualControlContentViewDelegate <NSObject>
@optional
- (void)visualControlContentViewDidClickOnLight:(NSNumber *)deviceId;
- (void)visualControlContentViewRequireDeletingLightRepresentation:(UIView*)representation;
- (void)visualControlContentViewSendBrightnessControlTouching:(CGPoint)touchAt referencePoint:(CGPoint)origin toLight:(NSNumber *)deviceId controlState:(UIGestureRecognizerState)state;
- (void)visualControlContentViewRecognizerDidTranslationInLocation:(CGPoint)touchAt recognizerState:(UIGestureRecognizerState)state;
- (void)visualControlContentViewDidClickOnNoneLightRect;
@end

@interface VisualControlContentView : UIImageView<NSCopying>
@property (nonatomic,weak) id<VisualControlContentViewDelegate> delegate;
@property (nonatomic,assign) CGSize layoutSize;
@property (nonatomic,copy) NSString *visualControlIndex;
@property (nonatomic,assign) CGFloat controlVelocity;

- (void)addLightRepresentation:(UIView*)representation;
- (void)removeLightRepresentation:(UIView*)representation;
- (void)adjustLightRepresentationPosition;
- (void)updateLightPresentationWithMeshStatus:(DeviceModel *)deviceModel;

//edit
- (void)enableEdit;
- (void)disableEdit;
@end
