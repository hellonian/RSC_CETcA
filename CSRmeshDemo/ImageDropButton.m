//
//  ImageDropButton.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/23.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "ImageDropButton.h"

@interface ImageDropButton()
@property (nonatomic,assign) CGFloat rLeft;
@property (nonatomic,assign) CGFloat rTop;
@property (nonatomic,assign) CGFloat rSize;
@end

@implementation ImageDropButton

- (instancetype)initWithFrame:(CGRect)frame {
    CGFloat unit = MIN(frame.size.width, frame.size.height);
    CGRect fixFrame = CGRectMake(frame.origin.x, frame.origin.y, unit, unit);
    
    self = [super initWithFrame:fixFrame];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
//        self.alpha = 0.4;
        self.layer.cornerRadius = unit/2;
        self.layer.borderWidth =1;
        self.layer.borderColor = [UIColor darkGrayColor].CGColor;
    }
    
    return self;
}

- (void)markPosition:(CGFloat)relativeLeft relativeTop:(CGFloat)relativeTop sizeRatio:(CGFloat)rSize {
    self.rLeft = relativeLeft;
    self.rTop = relativeTop;
    self.rSize = rSize;
}

- (void)fixToParentView:(UIView*)parent {
    CGSize reference = parent.bounds.size;
    CGFloat left = reference.width*self.rLeft;
    CGFloat top = reference.height*self.rTop;
    
    self.bounds = CGRectMake(0, 0, reference.width*self.rSize, reference.width*self.rSize);
    self.layer.cornerRadius = reference.width*self.rSize*0.5;
    self.center = CGPointMake(left, top);
    
    if (![self isDescendantOfView:parent]) {
        [parent addSubview:self];
    }
}

- (void)updateLightPresentationWithBrightness:(DeviceModel *)deviceModel { 
    if (![deviceModel.powerState boolValue]) {
        self.backgroundColor = [UIColor clearColor];
    }else {
        if ([deviceModel.shortName isEqualToString:@"S350BT"]) {
            self.backgroundColor = [UIColor whiteColor];
        }else {
            self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:[deviceModel.level floatValue]/255.0];
        }
    }
}

- (id)copyWithZone:(NSZone *)zone {
    ImageDropButton *copy = [[ImageDropButton alloc] initWithFrame:self.bounds];
    
    if (copy) {
        copy.backgroundColor = self.backgroundColor;  //for the floor detail view first present
        copy.deviceId = [self.deviceId copyWithZone:zone];
        copy.rLeft = self.rLeft;
        copy.rTop = self.rTop;
        copy.rSize = self.rSize;
    }
    
    return copy;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        self.deviceId = [aDecoder decodeObjectForKey:@"ImageDropButtonPrimaryKeyLightMAC"];
        self.rLeft = [aDecoder decodeFloatForKey:@"ImageDropButtonPrimaryKeyLeftRatio"];
        self.rTop = [aDecoder decodeFloatForKey:@"ImageDropButtonPrimaryKeyTopRatio"];
        self.rSize = [aDecoder decodeFloatForKey:@"ImageDropButtonPrimaryKeySizeRatio"];
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.deviceId forKey:@"ImageDropButtonPrimaryKeyLightMAC"];
    [aCoder encodeFloat:self.rLeft forKey:@"ImageDropButtonPrimaryKeyLeftRatio"];
    [aCoder encodeFloat:self.rTop forKey:@"ImageDropButtonPrimaryKeyTopRatio"];
    [aCoder encodeFloat:self.rSize forKey:@"ImageDropButtonPrimaryKeySizeRatio"];
}

@end

