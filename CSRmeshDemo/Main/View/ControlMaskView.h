//
//  ControlMaskView.h
//  BluetoothAcTEC
//
//  Created by hua on 10/10/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ControlMaskView : UIView
- (void)updateProgress:(CGFloat)percentage withText:(NSString*)text;
@end
