//
//  ImproveTouchingExperience.h
//  BluetoothAcTEC
//
//  Created by hua on 11/17/16.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImproveTouchingExperience : NSObject

- (void)beginImproving;
- (NSInteger)improveTouching:(CGPoint)touchAt referencePoint:(CGPoint)origin primaryBrightness:(NSInteger)primaryBrightness;
@end
