//
//  SuperCollectionViewCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SuperCollectionViewCellDelegate <NSObject>

//@optional
- (void)superCollectionViewCellDelegateAddDeviceAction:(NSNumber *)cellDeviceId cellIndexPath:(NSIndexPath *)cellIndexPath;
- (void)superCollectionViewCellDelegatePanBrightnessWithTouchPoint:(CGPoint)touchPoint withOrigin:(CGPoint)origin toLight:(NSNumber *)deviceId withPanState:(UIGestureRecognizerState)state;

@end

@interface SuperCollectionViewCell : UICollectionViewCell

@property (nonatomic,weak) id<SuperCollectionViewCellDelegate> superCellDelegate;
@property (nonatomic,strong) NSIndexPath *cellIndexPath;

- (void)configureCellWithiInfo:(id)info withCellIndexPath:(NSIndexPath *)indexPath;

@end
