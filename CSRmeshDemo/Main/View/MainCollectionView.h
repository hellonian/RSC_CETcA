//
//  MainCollectionView.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SuperCollectionViewCell.h"

@protocol MainCollectionViewDelegate <NSObject>

@optional
- (void)mainCollectionViewTapCellAction:(NSNumber *)cellDeviceId cellIndexPath:(NSIndexPath *)indexPath;
- (void)mainCollectionViewDelegatePanBrightnessWithTouchPoint:(CGPoint)touchPoint withOrigin:(CGPoint)origin toLight:(NSNumber *)deviceId groupId:(NSNumber *)groupId withPanState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction;
- (void)mainCollectionViewDelegateSceneMenuAction:(NSNumber *)sceneId actionName:(NSString *)actionName;
- (void)mainCollectionViewDelegateLongPressAction:(id)cell;
- (void)mainCollectionViewDelegateDeleteDeviceAction:(NSNumber *)cellDeviceId cellGroupId:(NSNumber *)cellGroupId;
- (void)mainCollectionViewDelegateSelectAction:(NSNumber *)cellDeviceId;
- (void)mainCollectionViewDelegateClickEmptyGroupCellAction:(NSIndexPath *)cellIndexPath;
- (void)mainCollectionViewCellDelegateSceneCellTapAction:(NSNumber *)sceneId;

@end

@interface MainCollectionView : UICollectionView

@property (nonatomic,strong) NSMutableArray *dataArray;
@property (nonatomic,weak) id<MainCollectionViewDelegate> mainDelegate;
@property (nonatomic,assign) BOOL isLocationChanged;

- (id)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout cellIdentifier:(NSString *)identifier;

@end
