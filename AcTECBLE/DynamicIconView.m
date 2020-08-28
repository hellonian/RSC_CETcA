//
//  DynamicIconView.m
//  BluetoothAcTEC
//
//  Created by hua on 10/13/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "DynamicIconView.h"
#import "LightClusterCell.h"
#import "LightBringer.h"

@interface DynamicIconView ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
@property (nonatomic,copy) NSString *cellReuseIdentifier;
@property (nonatomic,assign) CGSize fitSize;
@property (nonatomic,assign) NSInteger controlSection;
@property (nonatomic,assign) NSInteger itemPerSection;
@property (nonatomic,strong) NSMutableArray *sectionArray;
@end

@implementation DynamicIconView

- (void)configureWithItemPerSection:(NSInteger)count cellIdentifier:(NSString*)identifier {
    self.itemPerSection = count;
    self.cellReuseIdentifier = identifier;
    self.delegate = self;
    self.dataSource = self;
    [self registerNib:[UINib nibWithNibName:identifier bundle:nil] forCellWithReuseIdentifier:identifier];
}

- (void)prepareRoundFlowLayoutParameter {
    [self.sectionArray removeAllObjects];
    //
    NSInteger total = self.itemCluster.count;
    
    if (total<=4) {
        self.itemPerSection = MAX(2, total);
        [self.sectionArray addObject:[NSNumber numberWithInteger:total]];
    }
    else if (total<=10 && total>4) {
        self.itemPerSection = 4;
        [self.sectionArray addObjectsFromArray:[self autoAlignItems:total primaryNumber:4]];
    }
    else if (total>10) {
        self.itemPerSection = [self primaryNumberForAlignItems:total];
        [self.sectionArray addObjectsFromArray:[self autoAlignItems:total primaryNumber:self.itemPerSection]];
    }
    //
    self.controlSection = self.sectionArray.count;
    self.fitSize = [self adjustItemSize];
}

- (void)addLightWithAddress:(NSArray*)list {
    //in main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.itemCluster removeAllObjects];
        [self.itemCluster addObjectsFromArray:list];
        [self prepareRoundFlowLayoutParameter];
        [self reloadData];
    });
}

#pragma mark - Layout Calculator

- (CGFloat)calculateInterspaceForSectionWithRows:(NSInteger)rows {
    CGFloat span = self.bounds.size.width;
    return (span-rows*self.fitSize.width)/(rows+1);
}

- (CGSize)adjustItemSize {
    CGFloat span = self.bounds.size.width;
    CGFloat minSpace = 8.0;
    CGFloat tryWidth = (span-(self.itemPerSection+1)*minSpace)/self.itemPerSection;
    //
    CGFloat verticalSpan = self.bounds.size.height;
    CGFloat minLineSpace = 8.0;
    CGFloat tryHeight = (verticalSpan-minLineSpace*(1+self.controlSection))/self.controlSection;
    
    CGFloat fitUnit = MIN(tryWidth, tryHeight);
    CGFloat fitWidth = MIN(160, fitUnit);
    //
    return CGSizeMake(fitWidth, fitWidth+5);
}

- (NSArray*)autoAlignItems:(NSInteger)count primaryNumber:(NSInteger)primary {
    NSInteger total = count;
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    do {
        NSInteger process = result.count;
        
        if (process==0) {  //middle section
            NSInteger remain = total-primary;
            
            if (remain<=0) {
                [result addObject:[NSNumber numberWithInteger:total]];
                total = 0;
            }
            else if (remain==1) {
                [result addObject:[NSNumber numberWithInteger:total-2]];
                total = 2;
            }
            else if (remain>=2) {
                [result addObject:[NSNumber numberWithInteger:primary]];
                total -= primary;
            }
        }
        else {  //top and down
            NSInteger stepNumber = primary-(1+(process-1)/2);
            NSInteger left = total - stepNumber;
            
            if (left<=0) {
                if (total>=2) {
                    NSInteger top = total/2;
                    [result insertObject:[NSNumber numberWithInteger:top] atIndex:0];
                    [result addObject:[NSNumber numberWithInteger:total-top]];
                }
                else {
                    [result insertObject:[NSNumber numberWithInteger:total] atIndex:0];
                }
                
                total=0;
            }
            else {
                [result insertObject:[NSNumber numberWithInteger:stepNumber] atIndex:0];
                total -= stepNumber;
                
                NSInteger right = total - stepNumber;
                
                if (right<=0) {
                    [result addObject:[NSNumber numberWithInteger:total]];
                    total=0;
                }
                else {
                    total -= stepNumber;
                    
                    if (total==1 && stepNumber>2) {
                        total = 2;
                        [result addObject:[NSNumber numberWithInteger:stepNumber-1]];
                    }
                    else {
                        [result addObject:[NSNumber numberWithInteger:stepNumber]];
                    }
                }
            }
        }
    } while (total>0);
    
    return result;
}

- (NSInteger)primaryNumberForAlignItems:(CGFloat)total {
    /*
        **
       ***
      ****     n^2 - 2 = X
       ***
        **
    */
    CGFloat try = ceilf(sqrtf(total+2));
    return try;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.sectionArray.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[self.sectionArray objectAtIndex:section] integerValue];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LightClusterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.cellReuseIdentifier forIndexPath:indexPath];
    
    if (cell) {
        NSInteger itemsOfPreSection = [self itemsOfPreSection:indexPath.section];
        NSInteger infoIndex = itemsOfPreSection + indexPath.row;
        id info = self.itemCluster[infoIndex];
        
        [cell setRoundCorner:self.fitSize.width*0.5];
        [cell configureCellWithInfo:info adjustSize:self.fitSize];
    }
    
    return cell;
}

- (NSInteger)itemsOfPreSection:(NSInteger)section {
    NSInteger count = 0;
    
    if (section==0) {
        return count;
    }
    
    for (NSInteger index=0;index<section;index++) {
        count += [[self.sectionArray objectAtIndex:index] integerValue];
    }
    
    return count;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.fitSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat verticalSpan = self.bounds.size.height;
    CGFloat verticalMargin = (verticalSpan-self.controlSection*self.fitSize.height)/(self.controlSection+1);
    CGFloat interSpace = [self calculateInterspaceForSectionWithRows:[[self.sectionArray objectAtIndex:section] integerValue]];
    
    if (section < self.controlSection-1) {
        if (section==0) {
            return UIEdgeInsetsMake(verticalMargin, interSpace, verticalMargin, interSpace);
        }
        return UIEdgeInsetsMake(0, interSpace, verticalMargin, interSpace);
    }
    else {
        if (section==0) {
            return UIEdgeInsetsMake(verticalMargin, interSpace, verticalMargin, interSpace);
        }
        return UIEdgeInsetsMake(0, interSpace, verticalMargin, interSpace);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 2;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    
    return [self calculateInterspaceForSectionWithRows:[[self.sectionArray objectAtIndex:section] integerValue]];
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - Lazy

- (NSMutableArray*)sectionArray {
    if (!_sectionArray) {
        _sectionArray = [[NSMutableArray alloc] init];
    }
    
    return _sectionArray;
}

- (NSMutableArray *)itemCluster {
    if (!_itemCluster) {
        _itemCluster = [[NSMutableArray alloc] init];
    }
    
    return _itemCluster;
}

@end
