//
//  DropView.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/1/3.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
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
                    || [CSRUtilities belongToTwoChannelDimmer:_kindName]
                    || [CSRUtilities belongToThreeChannelDimmer:_kindName]) {
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
                    || [CSRUtilities belongToTwoChannelDimmer:_kindName]
                    || [CSRUtilities belongToThreeChannelDimmer:_kindName]) {
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
                    || [CSRUtilities belongToTwoChannelDimmer:_kindName]
                    || [CSRUtilities belongToThreeChannelDimmer:_kindName]) {
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
        if ([CSRUtilities belongToOneChannelCurtainController:model.shortName]
            || [CSRUtilities belongToHOneChannelCurtainController:model.shortName]) {
            if (model.channel1Level == 0) {
                Byte byte[] = {0x79, 0x02, 0x01, 0x01};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                model.cDirection1 = 1;
            }else if (model.channel1Level == 255) {
                Byte byte[] = {0x79, 0x02, 0x02, 0x01};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                model.cDirection1 = 2;
            }else {
                if (model.cDirection1 == 0) {
                    Byte byte[] = {0x79, 0x02, 0x01, 0x01};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    model.cDirection1 = 1;
                }else if (model.cDirection1 == 1) {
                    Byte byte[] = {0x79, 0x02, 0x00, 0x01};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    model.cDirection1 = 2;
                }else if (model.cDirection1 == 2) {
                    Byte byte[] = {0x79, 0x02, 0x02, 0x01};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    model.cDirection1 = 3;
                }else if (model.cDirection1 == 3) {
                    Byte byte[] = {0x79, 0x02, 0x00, 0x01};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    model.cDirection1 = 0;
                }else {
                    Byte byte[] = {0x79, 0x02, 0x01, 0x01};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    model.cDirection1 = 1;
                }
            }
        }else if ([CSRUtilities belongToTwoChannelCurtainController:model.shortName]) {
            if ([self.channel integerValue] == 2) {
                if (model.channel1Level == 0) {
                    Byte byte[] = {0x79, 0x02, 0x01, 0x01};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    model.cDirection1 = 1;
                }else if (model.channel1Level == 255) {
                    Byte byte[] = {0x79, 0x02, 0x02, 0x01};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    model.cDirection1 = 3;
                }else {
                    if (model.cDirection1 == 0) {
                        Byte byte[] = {0x79, 0x02, 0x01, 0x01};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection1 = 1;
                    }else if (model.cDirection1 == 1) {
                        Byte byte[] = {0x79, 0x02, 0x00, 0x01};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection1 = 2;
                    }else if (model.cDirection1 == 2) {
                        Byte byte[] = {0x79, 0x02, 0x02, 0x01};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection1 = 3;
                    }else if (model.cDirection1 == 3) {
                        Byte byte[] = {0x79, 0x02, 0x00, 0x01};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection1 = 0;
                    }else {
                        Byte byte[] = {0x79, 0x02, 0x01, 0x01};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection1 = 1;
                    }
                }
            }else if ([self.channel integerValue] == 3) {
                if (model.channel2Level == 0) {
                    Byte byte[] = {0x79, 0x02, 0x01, 0x02};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    model.cDirection2 = 1;
                }else if (model.channel2Level == 255) {
                    Byte byte[] = {0x79, 0x02, 0x02, 0x02};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    model.cDirection2 = 3;
                }else {
                    if (model.cDirection2 == 0) {
                        Byte byte[] = {0x79, 0x02, 0x01, 0x02};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection2 = 1;
                    }else if (model.cDirection2 == 1) {
                        Byte byte[] = {0x79, 0x02, 0x00, 0x02};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection2 = 2;
                    }else if (model.cDirection2 == 2) {
                        Byte byte[] = {0x79, 0x02, 0x02, 0x02};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection2 = 3;
                    }else if (model.cDirection2 == 3) {
                        Byte byte[] = {0x79, 0x02, 0x00, 0x02};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection2 = 0;
                    }else {
                        Byte byte[] = {0x79, 0x02, 0x01, 0x02};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection2 = 1;
                    }
                }
            }else if ([self.channel integerValue] == 4) {
                if ([model.level integerValue] == 0) {
                    Byte byte[] = {0x79, 0x02, 0x01, 0x03};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    model.cDirection1 = 1;
                    model.cDirection2 = 1;
                }else if ([model.level integerValue] == 255) {
                    Byte byte[] = {0x79, 0x02, 0x02, 0x03};
                    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                    model.cDirection1 = 3;
                    model.cDirection2 = 3;
                }else {
                    if (model.cDirection1 == 0 && model.cDirection2 == 0) {
                        Byte byte[] = {0x79, 0x02, 0x01, 0x03};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection1 = 1;
                        model.cDirection2 = 1;
                    }else if (model.cDirection1 == 1 && model.cDirection2 == 1) {
                        Byte byte[] = {0x79, 0x02, 0x00, 0x03};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection1 = 2;
                        model.cDirection2 = 2;
                    }else if (model.cDirection1 == 2 && model.cDirection2 == 2) {
                        Byte byte[] = {0x79, 0x02, 0x02, 0x03};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection1 = 3;
                        model.cDirection2 = 3;
                    }else if (model.cDirection1 == 3 && model.cDirection2 == 3) {
                        Byte byte[] = {0x79, 0x02, 0x00, 0x03};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection1 = 0;
                        model.cDirection2 = 0;
                    }else {
                        Byte byte[] = {0x79, 0x02, 0x01, 0x03};
                        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
                        model.cDirection1 = 1;
                        model.cDirection2 = 1;
                    }
                }
            }
        }else {
            if ([self.channel integerValue] == 1) {
                [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId channel:@1 withPowerState:![model.powerState boolValue]];
            }else if ([self.channel integerValue] == 2) {
                [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId channel:@2 withPowerState:!model.channel1PowerState];
            }else if ([self.channel integerValue] == 3) {
                [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId channel:@3 withPowerState:!model.channel2PowerState];
            }else if ([self.channel integerValue] == 5) {
                [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId channel:@5 withPowerState:!model.channel3PowerState];
            }else if ([self.channel integerValue] == 4) {
                BOOL powerState = model.channel1PowerState && model.channel2PowerState;
                [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId channel:@4 withPowerState:!powerState];
            }else if ([self.channel integerValue] == 7) {
                BOOL powerState = model.channel2PowerState && model.channel3PowerState;
                [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId channel:@7 withPowerState:!powerState];
            }else if ([self.channel integerValue] == 6) {
                BOOL powerState = model.channel1PowerState && model.channel3PowerState;
                [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId channel:@6 withPowerState:!powerState];
            }else if ([self.channel integerValue] == 8) {
                BOOL powerState = model.channel1PowerState && model.channel2PowerState && model.channel3PowerState;
                [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId channel:@8 withPowerState:!powerState];
            }
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
    }else if ([CSRUtilities belongToDimmer:self.kindName]
              || [CSRUtilities belongToCWDevice:self.kindName]
              || [CSRUtilities belongToRGBDevice:self.kindName]
              || [CSRUtilities belongToRGBCWDevice:self.kindName]) {
        self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:[model.level floatValue]/255.0*0.9];
        self.layer.borderColor = DARKORAGE.CGColor;
    }else if ([CSRUtilities belongToTwoChannelSwitch:_kindName]
              || [CSRUtilities belongToSocketTwoChannel:_kindName]
              || [CSRUtilities belongToThreeChannelSwitch:_kindName]) {
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
        }else if ([_channel integerValue] == 5) {
            if (model.channel3PowerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }else if ([_channel integerValue] == 4) {
            BOOL powerState = model.channel1PowerState || model.channel2PowerState;
            if (powerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }else if ([_channel integerValue] == 7) {
            BOOL powerState = model.channel2PowerState || model.channel3PowerState;
            if (powerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }else if ([_channel integerValue] == 6) {
            BOOL powerState = model.channel1PowerState || model.channel3PowerState;
            if (powerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }else if ([_channel integerValue] == 8) {
            BOOL powerState = model.channel1PowerState || model.channel2PowerState || model.channel3PowerState;
            if (powerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }
    }else if ([CSRUtilities belongToTwoChannelDimmer:_kindName]
              || [CSRUtilities belongToThreeChannelDimmer:_kindName]) {
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
        }else if ([_channel integerValue] == 5) {
            if (model.channel3PowerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:model.channel2Level/255.0*0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }else if ([_channel integerValue] == 4) {
            BOOL powerState = model.channel1PowerState || model.channel2PowerState;
            NSInteger level = model.channel1Level > model.channel2Level ? model.channel1Level : model.channel2Level;
            if (powerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:level/255.0*0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }else if ([_channel integerValue] == 7) {
            BOOL powerState = model.channel2PowerState || model.channel3PowerState;
            NSInteger level = model.channel2Level > model.channel3Level ? model.channel2Level : model.channel3Level;
            if (powerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:level/255.0*0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }else if ([_channel integerValue] == 6) {
            BOOL powerState = model.channel1PowerState || model.channel3PowerState;
            NSInteger level = model.channel1Level > model.channel3Level ? model.channel1Level : model.channel3Level;
            if (powerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:level/255.0*0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }else if ([_channel integerValue] == 8) {
            BOOL powerState = model.channel1PowerState || model.channel2PowerState || model.channel3PowerState;
            NSInteger level = (model.channel1Level > model.channel2Level ? model.channel1Level : model.channel2Level) > model.channel3Level ? (model.channel1Level > model.channel2Level ? model.channel1Level : model.channel2Level) : model.channel3Level;
            if (powerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:level/255.0*0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }
    }else if ([CSRUtilities belongToOneChannelCurtainController:_kindName]
              || [CSRUtilities belongToHOneChannelCurtainController:_kindName]) {
        self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:(255 - [model.level floatValue])/255.0*0.9];
        self.layer.borderColor = DARKORAGE.CGColor;
    }else if ([CSRUtilities belongToTwoChannelCurtainController:_kindName]) {
        if ([self.channel integerValue] == 2) {
            if (model.channel1PowerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:(255 - model.channel1Level)/255.0*0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }else if ([self.channel integerValue] == 3) {
            if (model.channel2PowerState) {
                self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:(255 - model.channel2Level)/255.0*0.9];
                self.layer.borderColor = DARKORAGE.CGColor;
            }else {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor darkGrayColor].CGColor;
            }
        }else if ([self.channel integerValue] == 4) {
            self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:(255 - [model.level floatValue])/255.0*0.9];
            self.layer.borderColor = DARKORAGE.CGColor;
        }
    }
}

@end
