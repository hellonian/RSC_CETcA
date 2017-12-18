//
//  UIView+DarkEffect.m
//  BluetoothAcTEC
//
//  Created by hua on 10/13/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "UIView+DarkEffect.h"

@implementation UIView (DarkEffect)

- (void)darkerInDuration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.alpha = 0.4;
                         self.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
                     }
                     completion:nil
     ];
}

- (void)recoverFormDarkerInDuration:(NSTimeInterval)duration {
        [UIView animateWithDuration:duration
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.alpha = 1.0;
                             self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1];
                         }
                         completion:nil
     ];
}

@end
