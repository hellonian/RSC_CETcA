//
//  SuperCollectionViewCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    PanGestureMoveDirectionNone,
    PanGestureMoveDirectionVertical,
    PanGestureMoveDirectionHorizontal,
} PanGestureMoveDirection;

@protocol SuperCollectionViewCellDelegate <NSObject>

//@optional
- (void)superCollectionViewCellDelegateAddDeviceAction:(NSNumber *)cellDeviceId cellIndexPath:(NSIndexPath *)cellIndexPath;
- (void)superCollectionViewCellDelegatePanBrightnessWithTouchPoint:(CGPoint)touchPoint withOrigin:(CGPoint)origin toLight:(NSNumber *)deviceId groupId:(NSNumber *)groupId withPanState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction;
- (void)superCollectionViewCellDelegateSceneMenuAction:(NSNumber *)sceneId actionName:(NSString *)actionName;
- (void)superCollectionViewCellDelegateLongPressAction:(id)cell;
- (void)superCollectionViewCellDelegateDeleteDeviceAction:(NSNumber *)cellDeviceId cellGroupId:(NSNumber *)cellGroupId;
- (void)superCollectionViewCellDelegateMoveCellPanAction:(UIGestureRecognizerState)state touchPoint:(CGPoint)touchPoint;
//- (void)superCollectionViewCellDelegateSelectAction:(NSNumber *)cellDeviceId cellGroupId:(NSNumber *)cellGroupId cellSceneId:(NSNumber *)cellSceneId;
- (void)superCollectionViewCellDelegateSelectAction:(id)cell;
- (void)superCollectionViewCellDelegateClickEmptyGroupCellAction:(NSIndexPath *)cellIndexPath;
- (void)superCollectionViewCellDelegateSceneCellTapAction:(NSNumber *)sceneId;
- (void)superCollectionViewCellDelegateCurtainTapAction:(NSNumber *)deviceId;

@end

@interface SuperCollectionViewCell : UICollectionViewCell

@property (nonatomic,weak) id<SuperCollectionViewCellDelegate> superCellDelegate;
@property (nonatomic,strong) NSIndexPath *cellIndexPath;

- (void)configureCellWithiInfo:(id)info withCellIndexPath:(NSIndexPath *)indexPath;

@end
