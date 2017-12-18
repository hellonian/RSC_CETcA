//
//  LightDot.h
//  BluetoothAcTEC
//
//  Created by hua on 10/17/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LightDot : UILabel
@property (nonatomic,strong) UIColor *highlightColor;
@property (nonatomic,copy) NSString *lightMAC;

- (void)darker;
- (void)recoverToNormal;
@end
