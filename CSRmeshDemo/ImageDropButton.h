//
//  ImageDropButton.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/23.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceModel.h"

@interface ImageDropButton : UIView<NSCopying,NSCoding>
@property (nonatomic,copy) NSNumber *deviceId;

- (void)markPosition:(CGFloat)relativeLeft relativeTop:(CGFloat)relativeTop sizeRatio:(CGFloat)rSize;
- (void)fixToParentView:(UIView*)parent;
- (void)updateLightPresentationWithBrightness:(DeviceModel *)deviceModel;
@end
