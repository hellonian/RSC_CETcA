//
//  VisualControlContentView.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/23.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "VisualControlContentView.h"
#import "ImageDropButton.h"
#import "LightBringer.h"
#import "CSRDeviceEntity.h"
#import "CSRmeshDevice.h"
#import "CSRDevicesManager.h"

@interface VisualControlContentView ()
@property (nonatomic,strong) UITapGestureRecognizer *tapDetect;
@property (nonatomic,strong) UIPanGestureRecognizer *panDetect;
@property (nonatomic,strong) UIPinchGestureRecognizer *pinchDetect;
@property (nonatomic,strong) UILongPressGestureRecognizer *longDetect;
@property (nonatomic,weak) UIView *closestButton;
@property (nonatomic,assign) CGRect originRect;
@property (nonatomic,assign) CGPoint originCenter;
@property (nonatomic,assign) BOOL enableBrightnessControl;
@property (nonatomic,strong) ImageDropButton *controlTarget;
@property (nonatomic,assign) BOOL editable;
@end

@implementation VisualControlContentView

#pragma mark - private

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.userInteractionEnabled = YES;
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.clipsToBounds = YES;
        _editable = NO;
        _enableBrightnessControl = NO;
        _controlVelocity = 2.6;
        
        
        _tapDetect = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchContentInside:)];
        _panDetect = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(touchMoveInside:)];
        _pinchDetect = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchSubview:)];
        _longDetect = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(removeDevice:)];
        
        [self addGestureRecognizer:_tapDetect];
        [self addGestureRecognizer:_panDetect];
        [self addGestureRecognizer:_pinchDetect];
        [self addGestureRecognizer:_longDetect];
    }
    
    return self;
}

- (void)touchContentInside:(UITapGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint touchAt = [sender locationInView:self];
        UIView *hitObj = [self hitTest:touchAt withEvent:nil];
        if ([hitObj isKindOfClass:[ImageDropButton class]]) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(visualControlContentViewDidClickOnLight:)]) {
                ImageDropButton *button = (ImageDropButton*)hitObj;
                [self.delegate visualControlContentViewDidClickOnLight:button.deviceId];
            }
        }
        else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(visualControlContentViewDidClickOnNoneLightRect)]) {
                [self.delegate visualControlContentViewDidClickOnNoneLightRect];
            }
        }
    }
}

- (void)touchMoveInside:(UIPanGestureRecognizer*)sender {
    CGPoint touchAt = [sender locationInView:self];
    UIView *hitObj = [self hitTest:touchAt withEvent:nil];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            self.enableBrightnessControl = [hitObj isKindOfClass:[ImageDropButton class]];
            
            if (self.enableBrightnessControl) {
                ImageDropButton *button = (ImageDropButton*)hitObj;
                self.controlTarget = button;
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(visualControlContentViewSendBrightnessControlTouching:referencePoint:toLight:controlState:)]) {
                    [self.delegate visualControlContentViewSendBrightnessControlTouching:touchAt referencePoint:button.center toLight:self.controlTarget.deviceId controlState:sender.state];
                }
            }
            else {
                //deliver the touch
                if (self.delegate && [self.delegate respondsToSelector:@selector(visualControlContentViewRecognizerDidTranslationInLocation:recognizerState:)]) {
                    [self.delegate visualControlContentViewRecognizerDidTranslationInLocation:CGPointZero recognizerState:UIGestureRecognizerStateBegan];
                }
            }
            
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            if (self.editable) {
                if ([hitObj isKindOfClass:[ImageDropButton class]]) {
                    hitObj.center = touchAt;
                }
                return;
            }
            //control brightness
            if (self.enableBrightnessControl) {
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(visualControlContentViewSendBrightnessControlTouching:referencePoint:toLight:controlState:)]) {
                    [self.delegate visualControlContentViewSendBrightnessControlTouching:touchAt referencePoint:self.controlTarget.center toLight:self.controlTarget.deviceId controlState:sender.state];
                }
            }
            else {
                //scroll view
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(visualControlContentViewRecognizerDidTranslationInLocation:recognizerState:)]) {
                    [self.delegate visualControlContentViewRecognizerDidTranslationInLocation:[sender translationInView:self] recognizerState:UIGestureRecognizerStateChanged];
                }
            }
            
            break;
        }
        default:
        {
            if (self.enableBrightnessControl) {
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(visualControlContentViewSendBrightnessControlTouching:referencePoint:toLight:controlState:)]) {
                    [self.delegate visualControlContentViewSendBrightnessControlTouching:touchAt referencePoint:self.controlTarget.center toLight:self.controlTarget.deviceId controlState:sender.state];
                }
            }
            else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(visualControlContentViewRecognizerDidTranslationInLocation:recognizerState:)]) {
                    [self.delegate visualControlContentViewRecognizerDidTranslationInLocation:CGPointZero recognizerState:sender.state];
                }
            }
            
            self.enableBrightnessControl = NO;
            break;
        }
    }
}

- (void)pinchSubview:(UIPinchGestureRecognizer*)sender {
    if (!self.editable) {
        return;
    }
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            self.closestButton = [self subviewClosestToCenter:[sender locationInView:self] inRegion:[self regionOfPinch:sender]];
            //store
            if (self.closestButton) {
                self.originRect = self.closestButton.frame;
                self.originCenter = self.closestButton.center;
            }
            break;
        case UIGestureRecognizerStateChanged:
            if (self.closestButton) {
                CGFloat scale = sender.scale;
                CGFloat updateW = self.originRect.size.width*scale;
                CGFloat updateH = self.originRect.size.height*scale;
                
                self.closestButton.frame = CGRectMake(self.originCenter.x-updateW/2, self.originCenter.y-updateH/2, updateW, updateH);
                self.closestButton.layer.cornerRadius = MIN(updateW/2, updateH/2);
            }
            break;
        default:
            self.closestButton = nil;
            self.originRect = CGRectZero;
            self.originCenter = CGPointZero;
            break;
    }
}

- (void)removeDevice:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint touchAt = [sender locationInView:self];
        UIView *hitObj = [self hitTest:touchAt withEvent:nil];
        if ([hitObj isKindOfClass:[ImageDropButton class]] && self.delegate && [self.delegate respondsToSelector:@selector(visualControlContentViewRequireDeletingLightRepresentation:)]) {
            [self.delegate visualControlContentViewRequireDeletingLightRepresentation:hitObj];
        }
    }
}

#pragma mark - public

- (void)addLightRepresentation:(UIView*)representation {
    [self addSubview:representation];
    representation.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

- (void)removeLightRepresentation:(UIView *)representation {
    if ([representation isDescendantOfView:self]) {
        [representation removeFromSuperview];
    }
}

- (void)adjustLightRepresentationPosition {
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[ImageDropButton class]]) {
            ImageDropButton *representation = (ImageDropButton*)subview;
            [representation fixToParentView:self];
        }
    }
}

- (id)copyWithZone:(NSZone *)zone {
    VisualControlContentView *copy = [[VisualControlContentView alloc] initWithFrame:self.bounds];
    
    if (copy) {
        copy.image = self.image;
        copy.layoutSize = self.layoutSize;
        copy.visualControlIndex = [self.visualControlIndex copyWithZone:zone];
        copy.controlVelocity = self.controlVelocity;
        
        [self.subviews enumerateObjectsUsingBlock:^(UIView *subview,NSUInteger idx,BOOL *stop){
            if ([subview isKindOfClass:[ImageDropButton class]]) {
                ImageDropButton *parent = (ImageDropButton*)subview;
                ImageDropButton *copySubview = [parent copy];
                [copy addSubview:copySubview];
            }
        }];
    }
    
    return copy;
}

- (void)updateLightPresentationWithMeshStatus:(DeviceModel *)deviceModel {
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[ImageDropButton class]]) {
            ImageDropButton *button = (ImageDropButton *)obj;
            if ([button.deviceId isEqualToNumber:deviceModel.deviceId]) {
                [button updateLightPresentationWithBrightness:deviceModel];
            }
        }
    }];
    
//    [self.subviews enumerateObjectsUsingBlock:^(UIView *subview,NSUInteger idx,BOOL *stop){
//
//        if ([subview isKindOfClass:[ImageDropButton class]]) {
//            [status enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity,NSUInteger idx,BOOL *stop){
//                ImageDropButton *button = (ImageDropButton*)subview;
//
//                if ([button.deviceId isEqualToNumber:deviceEntity.deviceId]) {
//                    CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:deviceEntity.deviceId];
//                    CGFloat brightness = [device getLevel];
//                    NSLog(@"updateDeviceStatus  %f",brightness);
//                    [button updateLightPresentationWithBrightness:brightness];
//
//                }
//            }];
//        }
//    }];
}

- (void)enableEdit {
    self.editable = YES;
    self.pinchDetect.enabled = YES;
}

- (void)disableEdit {
    self.editable = NO;
    self.pinchDetect.enabled = NO;
}

#pragma mark - help

- (UIView*)subviewClosestToCenter:(CGPoint)center inRegion:(CGRect)region {
    if (self.subviews.count==0) {
        return nil;
    }
    
    __block UIView *choosen = nil;
    __block CGFloat shortestDistance = -1;
    
    [self.subviews enumerateObjectsUsingBlock:^(UIView *subview,NSUInteger idx,BOOL *stop){
        if ([subview isKindOfClass:[ImageDropButton class]] && [self isThePoint:subview.center insideRegion:region]) {
            CGFloat myDistance = [self distanceFromPoint:subview.center toPoint:center];
            
            if (shortestDistance < 0) {
                shortestDistance = myDistance;
                choosen = subview;
            }
            else {
                if (myDistance<shortestDistance) {
                    shortestDistance = myDistance;
                    choosen = subview;
                }
            }
        }
    }];
    
    return choosen;
}

- (CGFloat)distanceFromPoint:(CGPoint)start toPoint:(CGPoint)end {
    CGFloat deltaX = start.x - end.x;
    CGFloat deltaY = start.y - end.y;
    
    return sqrtf(deltaX*deltaX + deltaY*deltaY);
}

- (CGRect)regionOfPinch:(UIPinchGestureRecognizer*)sender {
    if ([sender numberOfTouches] == 2) {
        CGPoint pointA = [sender locationOfTouch:0 inView:self];
        CGPoint pointB = [sender locationOfTouch:1 inView:self];
        
        return CGRectMake(MIN(pointA.x, pointB.x), MAX(pointA.x, pointB.x), MIN(pointA.y, pointB.y), MAX(pointA.y, pointB.y));
    }
    return CGRectZero;
}

- (BOOL)isThePoint:(CGPoint)point insideRegion:(CGRect)region {
    return (point.x>=region.origin.x && point.x<=region.origin.y && point.y>=region.size.width && point.y<=region.size.height);
}
-(BOOL)isDimmer:(NSString *)lightMAC{
//    BleSupportManager *manager = [BleSupportManager shareInstance];
//    for (LightBringer *profile in manager.meshSet) {
//        if ([profile.macAddress isEqualToString:lightMAC]) {
//            return !profile.isSwitch;
//        }
//    }
    return YES;
}

@end
