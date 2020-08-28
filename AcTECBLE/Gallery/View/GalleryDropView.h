//
//  DropView.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/1/3.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol GalleryDropViewDelegate <NSObject>

@optional
- (void)galleryDropViewPanLocationAction:(NSNumber *)value;
- (void)galleryDropViewPanBrightnessWithTouchPoint:(CGPoint)touchPoint withOrigin:(CGPoint)origin toLight:(NSNumber *)deviceId channel:(NSNumber *)channel withPanState:(UIGestureRecognizerState)state;

@end

@interface GalleryDropView : UIView

@property (nonatomic, strong) NSNumber *deviceId;
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, strong) NSNumber *dropId;
@property (nonatomic, retain) NSNumber * boundRatio;
@property (nonatomic, retain) NSNumber * centerXRatio;
@property (nonatomic, retain) NSNumber * centerYRatio;
@property (nonatomic, weak) id<GalleryDropViewDelegate> delegate;
@property (nonatomic, strong) NSString * kindName;
@property (nonatomic, strong) NSNumber *channel;

- (void)adjustDropViewBgcolorWithdeviceId:(NSNumber *)deviceId;

@end
