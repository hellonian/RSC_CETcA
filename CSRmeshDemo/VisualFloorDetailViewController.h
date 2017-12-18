//
//  VisualFloorDetailViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/4.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "VisualFloorOrganizeController.h"

@protocol DetailViewDelegate <NSObject>

- (void)floorViewCellSendBrightnessControlTouching:(CGPoint)touchAt referencePoint:(CGPoint)origin toLight:(NSNumber *)deviceId controlState:(UIGestureRecognizerState)state;

@end

@interface VisualFloorDetailViewController : VisualFloorOrganizeController

@property (nonatomic,weak) id <DetailViewDelegate> delegate;
@property (nonatomic,copy) NSMutableArray *devices;

@end
