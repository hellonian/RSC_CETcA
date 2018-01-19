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
        
        [cell configureCellWithiInfo:info];
        
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

- (void)superCollectionViewCellDelegateAddDeviceAction:(NSNumber *)cellDeviceId {
    if (self.mainDelegate && [self.mainDelegate respondsToSelector:@selector(mainCollectionViewAddDeviceAction:)]) {
        [self.mainDelegate mainCollectionViewAddDeviceAction:cellDeviceId];
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
