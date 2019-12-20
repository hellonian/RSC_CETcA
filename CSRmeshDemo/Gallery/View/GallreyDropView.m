//
//  DropView.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/3.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "GalleryDropView.h"
#import "DeviceModelManager.h"
#import "CSRUtilities.h"
#import "DataModelManager.h"

@implementation GalleryDropView

- (id)initWithFrame:(CGRect)frame {
    CGFloat unit = MIN(frame.size.width, frame.size.height);
    CGRect fixFrame = CGRectMake(frame.origin.x, frame.origin.y, unit, unit);
    
    self = [super initWithFrame:fixFrame];
    
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
        self.layer.cornerRadius = unit/2;
        self.layer.borderWidth =1;
        self.layer.borderColor = [UIColor darkGrayColor].CGColor;
        
        self.userInteractionEnabled = YES;
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
        
        [self addGestureRecognizer:panGesture];
        [self addGestureRecognizer:tapGesture];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setPowerStateSuccess:) name:@"setPowerStateSuccess" object:nil];
        
    }
    return self;
}

#pragma mark - gestureAction

- (void)panGestureAction:(UIPanGestureRecognizer *)sender {
    
    CGPoint touchPoint = [sender locationInView:self.superview];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            if (!_isEditing && self.delegate && [self.delegate respondsToSelector:@selector(galleryDropViewPanBrightnessWithTouchPoint:withOrigin:toLight:channel:withPanState:)]) {
                if ([CSRUtilities belongToDimmer:self.kindName]
                    || [CSRUtilities belongToCWDevice:self.kindName]
                    || [CSRUtilities belongToRGBDevice:self.kindName]
                    || [CSRUtilities belongToRGBCWDevice:self.kindName]
                    || [CSRUtilities belongToTwoChannelDimmer:_kindName]) {
                    [self.delegate galleryDropViewPanBrightnessWithTouchPoint:touchPoint withOrigin:self.center toLight:self.deviceId channel:_channel withPanState:sender.state];
                }
            }
            
            break;
        case UIGestureRecognizerStateChanged:
            
            if (_isEditing) {
                if (touchPoint.x < self.frame.size.width/2.0f) {
                    touchPoint.x = self.frame.size.width/2.0f;
                }
                if (touchPoint.x > self.superview.frame.size.width - self.frame.size.width/2.0f) {
                    touchPoint.x = self.superview.frame.size.width - self.frame.size.width/2.0f;
                }
                if (touchPoint.y < self.frame.size.height/2.0f) {
                    touchPoint.y = self.frame.size.height/2.0f;
                }
                if (touchPoint.y > self.superview.frame.size.height - self.frame.size.height/2.0f) {
                    touchPoint.y = self.superview.frame.size.height - self.frame.size.height/2.0f;
                }
                
                self.center = touchPoint;
            }
            
            if (!_isEditing && self.delegate && [self.delegate respondsToSelector:@selector(galleryDropViewPanBrightnessWithTouchPoint:withOrigin:toLight:channel:withPanState:)]) {
                if ([CSRUtilities belongToDimmer:self.kindName]
                    || [CSRUtilities belongToCWDevice:self.kindName]
                    || [CSRUtilities belongToRGBDevice:self.kindName]
                    || [CSRUtilities belongToRGBCWDevice:self.kindName]
                    || [CSRUtilities belongToTwoChannelDimmer:_kindName]) {
                    [self.delegate galleryDropViewPanBrightnessWithTouchPoint:touchPoint withOrigin:self.center toLight:self.deviceId channel:_channel withPanState:sender.state];
                }
            }
            
            break;
        case UIGestureRecognizerStateEnded:
            if (_isEditing && self.delegate && [self.delegate respondsToSelector:@selector(galleryDropViewPanLocationAction:)]) {
                [self.delegate galleryDropViewPanLocationAction:@(YES)];
            }
            if (!_isEditing && self.delegate && [self.delegate respondsToSelector:@selector(galleryDropViewPanBrightnessWithTouchPoint:withOrigin:toLight:channel:withPanState:)]) {
                if ([CSRUtilities belongToDimmer:self.kindName]
                    || [CSRUtilities belongToCWDevice:self.kindName]
                    || [CSRUtilities belongToRGBDevice:self.kindName]
                    || [CSRUtilities belongToRGBCWDevice:self.kindName]
                    || [CSRUtilities belongToTwoChannelDimmer:_kindName]) {
                    [self.delegate galleryDropViewPanBrightnessWithTouchPoint:touchPoint withOrigin:self.center toLight:self.deviceId channel:_channel withPanState:sender.state];
                }
            }
            
            break;
            
        default:
            break;
    }
    
}

- (void)tapGestureAction:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        if ([self.channel integerValue] == 1) {
            [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId withPowerState:@(![model.powerState boolValue])];
        }else if ([self.channel integerValue] == 2) {
            [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"51050100010%d00",!model.channel1PowerState] toDeviceId:_deviceId];
        }else if ([self.channel integerValue] == 3) {
            [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"51050200010%d00",!model.channel2PowerState] toDeviceId:_deviceId];
        }
    }
}

- (void)setPowerStateSuccess:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    
    if (_deviceId && [deviceId isEqualToNumber:_deviceId]) {
        [self adjustDropViewBgcolorWithdeviceId:deviceId];
    }
}

- (void)adjustDropViewBgcolorWithdeviceId:(NSNumber *)deviceId {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
    if (![model.powerState boolValue]) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.borderColor = [UIColor darkGrayColor].CGColor;
    }else if ([CSRUtilities belongToSwitch:_kindName] || [CSRUtilities belongToSocketOneChannel:_kindName]) {
        self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
        self.layer.borderColor = DARKORAGE.CGColor;
    }else if ([CSRUtilities belongToDimmer:self.kindName] || [CSRUtilities belongToCWDevice:self.kindName] || [CSRUtilities belongToRGBDevice:self.kindName] || [CSRUtilities belongToRGBCWDevice:self.kindName]){
        self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:[model.level floatValue]/255.0*0.9];
        self.layer.borderColor = DARKORAGE.CGColor;
    }else if ([CSRUtilities belongToTwoChannelSwitch:_kindName] || [CSRUtilities belongToSocketTwoChannel:_kindName]) {
        if ([_channel integerValue] == 1) {
            self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
            self.layer.borderColor = DARKORAGE.CGColor;
        }else if ([_channel integerValue] == 2) {
            if (model.channel1PowerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }else if ([_channel integerValue] == 3) {
            if (model.channel2PowerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }
    }else if ([CSRUtilities belongToTwoChannelDimmer:_kindName]) {
        if ([_channel integerValue] == 1) {
            self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:[model.level floatValue]/255.0*0.9];
            self.layer.borderColor = DARKORAGE.CGColor;
        }else if ([_channel integerValue] == 2) {
            if (model.channel1PowerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:model.channel1Level/255.0*0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }else if ([_channel integerValue] == 3) {
            if (model.channel2PowerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:model.channel2Level/255.0*0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }
    }
}

@end
