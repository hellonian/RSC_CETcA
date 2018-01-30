//
//  MainCollectionView.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
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

//- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//    if ([_cellIdentifier isEqualToString:@"MainCollectionViewCell"]) {
//        id cell = [self.dataArray objectAtIndex:indexPath.row];
//        if ([cell isKindOfClass:[NSNumber class]]) {
//            NSLog(@"tapppp");
//        }
//    }
//}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_cellIdentifier isEqualToString:@"MainCollectionViewCell"]) {
        return YES;
    }
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    id objec = [self.dataArray objectAtIndex:sourceIndexPath.item];
    [self.dataArray removeObject:objec];
    [self.dataArray insertObject:objec atIndex:destinationIndexPath.item];
}


#pragma mark - SuperCollectionViewCellDelegate

- (void)superCollectionViewCellDelegateAddDeviceAction:(NSNumber *)cellDeviceId cellIndexPath:(NSIndexPath *)cellIndexPath {
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewTapCellAction:cellIndexPath:)]) {
        [self.mainDelegate mainCollectionViewTapCellAction:cellDeviceId cellIndexPath:cellIndexPath];
    }
}

- (void)superCollectionViewCellDelegatePanBrightnessWithTouchPoint:(CGPoint)touchPoint withOrigin:(CGPoint)origin toLight:(NSNumber *)deviceId withPanState:(UIGestureRecognizerState)state {
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewDelegatePanBrightnessWithTouchPoint:withOrigin:toLight:withPanState:)]) {
        [self.mainDelegate mainCollectionViewDelegatePanBrightnessWithTouchPoint:touchPoint withOrigin:origin toLight:deviceId withPanState:state];
    }
}

- (void)superCollectionViewCellDelegateSceneMenuAction:(NSNumber *)sceneId actionName:(NSString *)actionName {
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewDelegateSceneMenuAction:actionName:)]) {
        [self.mainDelegate mainCollectionViewDelegateSceneMenuAction:sceneId actionName:actionName];
    }
}

- (void)superCollectionViewCellDelegateLongPressAction:(id)cell {
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewDelegateLongPressAction:)]) {
        [self.mainDelegate mainCollectionViewDelegateLongPressAction:cell];
    }
}

- (void)superCollectionViewCellDelegateDeleteDeviceAction:(NSNumber *)cellDeviceId {
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewDelegateDeleteDeviceAction:)]) {
        [self.mainDelegate mainCollectionViewDelegateDeleteDeviceAction:cellDeviceId];
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

#pragma mark - lazy

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [NSMutableArray new];
    }
    return _dataArray;
}

@end
