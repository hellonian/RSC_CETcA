//
//  MainCollectionView.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "MainCollectionView.h"
#import "SuperCollectionViewCell.h"

@interface MainCollectionView ()<UICollectionViewDelegate,UICollectionViewDataSource,SuperCollectionViewCellDelegate>

@property (nonatomic,copy) NSString *cellIdentifier;

@end

@implementation MainCollectionView

- (id)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout cellIdentifier:(NSString *)identifier {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        _cellIdentifier = identifier;
        self.backgroundColor = [UIColor clearColor];
        self.delegate = self;
        self.dataSource = self;
        [self registerNib:[UINib nibWithNibName:identifier bundle:nil] forCellWithReuseIdentifier:identifier];
    }
    return self;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    SuperCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:_cellIdentifier forIndexPath:indexPath];
    
    if (cell) {
        cell.superCellDelegate = self;
        
        id info = self.dataArray[indexPath.row];
        
        [cell configureCellWithiInfo:info withCellIndexPath:indexPath];
        
    }
    
    
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section { 
    return [self.dataArray count];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_cellIdentifier isEqualToString:@"MainCollectionViewCell"]) {
        return YES;
    }
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    id objec = [self.dataArray objectAtIndex:sourceIndexPath.item];
    [self.dataArray removeObject:objec];
    
    self.isLocationChanged = YES;
    
    if (destinationIndexPath.item < self.dataArray.count-1) {
        [self.dataArray insertObject:objec atIndex:destinationIndexPath.item];
    }else {
        [self.dataArray insertObject:objec atIndex:destinationIndexPath.item-1];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self reloadData];
        });
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}


#pragma mark - SuperCollectionViewCellDelegate

- (void)superCollectionViewCellDelegateAddDeviceAction:(NSNumber *)cellDeviceId cellIndexPath:(NSIndexPath *)cellIndexPath {
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewTapCellAction:cellIndexPath:)]) {
        [self.mainDelegate mainCollectionViewTapCellAction:cellDeviceId cellIndexPath:cellIndexPath];
    }
}

- (void)superCollectionViewCellDelegatePanBrightnessWithTouchPoint:(CGPoint)touchPoint withOrigin:(CGPoint)origin toLight:(NSNumber *)deviceId groupId:(NSNumber *)groupId withPanState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction{
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewDelegatePanBrightnessWithTouchPoint:withOrigin:toLight:groupId:withPanState:direction:)]) {
        [self.mainDelegate mainCollectionViewDelegatePanBrightnessWithTouchPoint:touchPoint withOrigin:origin toLight:deviceId groupId:groupId withPanState:state direction:direction];
    }
}

- (void)superCollectionViewCellDelegateSceneMenuAction:(NSNumber *)sceneId actionName:(NSString *)actionName {
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewDelegateSceneMenuAction:actionName:)]) {
        [self.mainDelegate mainCollectionViewDelegateSceneMenuAction:sceneId actionName:actionName];
    }
}

- (void)superCollectionViewCellDelegateSceneCellTapAction:(NSNumber *)sceneId {
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewCellDelegateSceneCellTapAction:)]) {
        [self.mainDelegate mainCollectionViewCellDelegateSceneCellTapAction:sceneId];
    }
}

- (void)superCollectionViewCellDelegateLongPressAction:(id)cell {
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewDelegateLongPressAction:)]) {
        [self.mainDelegate mainCollectionViewDelegateLongPressAction:cell];
    }
}

- (void)superCollectionViewCellDelegateDeleteDeviceAction:(NSNumber *)cellDeviceId cellGroupId:(NSNumber *)cellGroupId{
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewDelegateDeleteDeviceAction:cellGroupId:)]) {
        [self.mainDelegate mainCollectionViewDelegateDeleteDeviceAction:cellDeviceId cellGroupId:cellGroupId];
    }
}

- (void)superCollectionViewCellDelegateMoveCellPanAction:(UIGestureRecognizerState)state touchPoint:(CGPoint)touchPoint {
    switch (state) {
        case UIGestureRecognizerStateBegan:
        {
            NSIndexPath *myIndexPath = [self indexPathForItemAtPoint:touchPoint];
            if (myIndexPath == nil) {
                break;
            }
            [self beginInteractiveMovementForItemAtIndexPath:myIndexPath];
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            [self updateInteractiveMovementTargetPosition:touchPoint];
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            [self endInteractiveMovement];
            break;
        }
        default:
        {
            [self cancelInteractiveMovement];
            break;
        }
    }
    
}

- (void)superCollectionViewCellDelegateSelectAction:(id)cell {
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewDelegateSelectAction:)]) {
        [self.mainDelegate mainCollectionViewDelegateSelectAction:cell];
    }
}
/*
- (void)superCollectionViewCellDelegateSelectAction:(NSNumber *)cellDeviceId cellGroupId:(NSNumber *)cellGroupId cellSceneId:(NSNumber *)cellSceneId{
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewDelegateSelectAction:cellGroupId:cellSceneId:)]) {
        [self.mainDelegate mainCollectionViewDelegateSelectAction:cellDeviceId cellGroupId:cellGroupId cellSceneId:cellSceneId];
    }
}
 */

- (void)superCollectionViewCellDelegateClickEmptyGroupCellAction:(NSIndexPath *)cellIndexPath {
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewDelegateClickEmptyGroupCellAction:)]) {
        [self.mainDelegate mainCollectionViewDelegateClickEmptyGroupCellAction:cellIndexPath];
    }
}

#pragma mark - lazy

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [NSMutableArray new];
    }
    return _dataArray;
}

@end
