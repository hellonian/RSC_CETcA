//
//  FloorViewController.h
//  BluetoothTest
//
//  Created by hua on 9/2/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VisualControlContentView.h"

@interface FloorViewController : UIViewController <VisualControlContentViewDelegate>

- (void)insertVisualControlGallery:(VisualControlContentView*)gallery;
- (void)beginAdjustingFlowLayout;
- (void)endAdjustingFlowLayout;
- (void)terminateAdjustingFlowLayout;

//virtual system
- (void)popVirtualFloor;
- (void)prepareVirtualFloor;
@end
