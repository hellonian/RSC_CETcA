//
//  ImproveTouchingExperience.m
//  BluetoothAcTEC
//
//  Created by hua on 11/17/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "ImproveTouchingExperience.h"

@interface ImproveTouchingExperience ()
@property (nonatomic,assign) BOOL reachMaxBoundary;
@property (nonatomic,assign) BOOL reachMinBoundary;
@property (nonatomic,assign) CGFloat maxTouch;
@property (nonatomic,assign) CGFloat minTouch;
@property (nonatomic,assign) BOOL maxDomination;
@end

@implementation ImproveTouchingExperience

- (void)beginImproving {
    self.reachMaxBoundary = NO;
    self.reachMinBoundary = NO;
    self.maxDomination = YES;
    self.maxTouch = -9999;  //opposite - must "bigger"
    self.minTouch = 9999;  //opposite - must "bigger"
}

- (NSInteger)improveTouching:(CGPoint)touchAt referencePoint:(CGPoint)origin primaryBrightness:(NSInteger)primaryBrightness {
    CGFloat span = [UIScreen mainScreen].bounds.size.width;
    CGFloat controlVelocity = 2.2;
    CGFloat maxBoundary = (255-primaryBrightness)*span/(controlVelocity*255) + origin.x;
    CGFloat minBoundary = -primaryBrightness*span/(controlVelocity*255) + origin.x;
    NSInteger offset = 0;
    NSInteger updatedBrightness = 0;
    //condition
    if (touchAt.x>maxBoundary) {
        self.reachMaxBoundary = YES;
    }
    
    if (touchAt.x<minBoundary) {
        self.reachMinBoundary = YES;
    }
    //action
    if (self.maxDomination) {
        if (self.reachMaxBoundary) {
            if (touchAt.x>self.maxTouch) {
                self.maxTouch = touchAt.x;
                return 255;
            }
            updatedBrightness = (touchAt.x-self.maxTouch)*controlVelocity*255/span + 255;
            
            if (updatedBrightness<0) {
                self.maxDomination = NO;
                self.reachMinBoundary = YES;
                self.minTouch = touchAt.x;
                return 0;
            }
            return updatedBrightness;
        }
    }
    else {
        if (self.reachMinBoundary) {
            if (touchAt.x<self.minTouch) {
                self.minTouch = touchAt.x;
                return 0;
            }
            updatedBrightness = (touchAt.x-self.minTouch)*controlVelocity*255/span;
            
            if (updatedBrightness>255) {
                self.maxDomination = YES;
                self.reachMaxBoundary = YES;
                self.maxTouch = touchAt.x;
                return 255;
            }
            return updatedBrightness;
        }
    }
    
    //between max and min
    offset = (touchAt.x-origin.x)*controlVelocity*255/span;
    updatedBrightness = MIN(primaryBrightness+offset, 255);
    
    if (updatedBrightness<0) {
        self.maxDomination = NO;  //fix
        updatedBrightness = 0;
    }
    
    return updatedBrightness;
}

@end
