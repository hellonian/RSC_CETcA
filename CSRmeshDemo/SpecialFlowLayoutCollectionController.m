//
//  SpecialFlowLayoutCollectionController.m
//  BluetoothAcTEC
//
//  Created by hua on 10/11/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "SpecialFlowLayoutCollectionController.h"
#import "PureLayout.h"


@interface SpecialFlowLayoutCollectionController () <UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
@property (nonatomic,copy) NSString *cellReuseIdentifier;
//flow layout control
@property (nonatomic,assign) CGSize fitSize;
@property (nonatomic,assign) NSInteger controlSection;
@property (nonatomic,assign) NSInteger lastSectionRow;
@property (nonatomic,assign) NSInteger itemPerSection;
@property (nonatomic,strong) NSLayoutConstraint *topLayoutControl;
@end

@implementation SpecialFlowLayoutCollectionController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgImage"]];
    imageView.frame = [UIScreen mainScreen].bounds;
    [self.view addSubview:imageView];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.allowEdit = NO;
    [self prepareFlowLayoutParameter];
    [self layoutView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)layoutView {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    self.lightPanel = [[HitTestAlrightCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    self.lightPanel.delegate = self;
    self.lightPanel.dataSource = self;
    self.lightPanel.backgroundColor = [UIColor clearColor];
    self.lightPanel.scrollEnabled = YES;
    
    [self.lightPanel registerNib:[UINib nibWithNibName:self.cellReuseIdentifier bundle:nil] forCellWithReuseIdentifier:self.cellReuseIdentifier];
    
    [self.view addSubview:self.lightPanel];
    self.topLayoutControl = [self.lightPanel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.view withOffset:64];
//    [self.lightPanel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.view withOffset:0];
    [self.lightPanel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withOffset:-114];
    [self.lightPanel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view];
    [self.lightPanel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view];
}

- (void)prepareFlowLayoutParameter {
    self.fitSize = [self adjustItemSize];
    //
    NSInteger remain = self.itemCluster.count%self.itemPerSection;
    self.lastSectionRow = remain==0 ? self.itemPerSection : remain;
    self.controlSection = self.itemCluster.count/self.itemPerSection + ceilf(((CGFloat)remain)/self.itemPerSection);
}

- (instancetype)initWithItemPerSection:(NSInteger)count cellIdentifier:(NSString*)identifier {
    self = [super init];
    
    if (self) {
        _itemPerSection = count;
        _cellReuseIdentifier = identifier;
    }
    
    return self;
}

#pragma mark - Public

- (void)updateCollectionView {
    NSLog(@"nnnnnnnnnnnnnnbao");
    [self updateControlSection];
    [self.lightPanel reloadData];
}

- (void)fixLayout {
    self.topLayoutControl.constant = 64.0;
}

- (void)beginEdit {
    self.allowEdit = YES;

    [self.lightPanel.visibleCells enumerateObjectsUsingBlock:^(SpecialFlowLayoutCollectionViewSuperCell *cell,NSUInteger idx,BOOL *stop){
        [cell showDeleteButton:YES];
    }];
}

- (void)endEdit {
    self.allowEdit = NO;

    [self.lightPanel.visibleCells enumerateObjectsUsingBlock:^(SpecialFlowLayoutCollectionViewSuperCell *cell,NSUInteger idx,BOOL *stop){
        [cell showDeleteButton:NO];
    }];
}

- (void)terminateEdit {
    
}

- (NSInteger)dataIndexOfCellAtIndexPath:(NSIndexPath*)indexPath {
    return indexPath.section*self.itemPerSection + indexPath.row;
}



#pragma mark - Layout Calculator

- (CGFloat)calculateInterspaceForSectionWithRows:(NSInteger)rows {
    CGFloat span = [UIScreen mainScreen].bounds.size.width;
    return (span-rows*self.fitSize.width)/(rows+1);
}

- (CGSize)adjustItemSize {
    CGFloat span = [UIScreen mainScreen].bounds.size.width;
    CGFloat minSpace = 16;
    CGFloat tryWidth = (span-(self.itemPerSection+1)*minSpace)/self.itemPerSection;
    CGFloat fixWidth = MIN(160.0, tryWidth);
    return CGSizeMake(fixWidth, fixWidth+30.0);
}

- (void)updateControlSection {
    NSInteger remain = self.itemCluster.count%self.itemPerSection;
    self.lastSectionRow = remain==0 ? self.itemPerSection : remain;
    self.controlSection = self.itemCluster.count/self.itemPerSection + ceilf(((CGFloat)remain)/self.itemPerSection);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.controlSection;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section < self.controlSection-1) {
        return self.itemPerSection;
    }
    else {
        return self.lastSectionRow;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SpecialFlowLayoutCollectionViewSuperCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.cellReuseIdentifier forIndexPath:indexPath];
    
    if (cell) {
        NSInteger infoIndex = indexPath.section*self.itemPerSection + indexPath.row;
        id info = self.itemCluster[infoIndex];
        
        cell.delegate = self;
        cell.myIndexpath = indexPath;
        [cell configureCellWithInfo:info adjustSize:self.fitSize];

    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.fitSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    CGFloat minSpace = 16.0;
    CGFloat verticalSpan = [UIScreen mainScreen].bounds.size.height-64-50;
    CGFloat tryVerticalMargin = (verticalSpan-self.controlSection*self.fitSize.height-(self.controlSection-1)*minSpace)/2;
    CGFloat verticalMargin = MAX(minSpace, tryVerticalMargin);
    
    if (section < self.controlSection-1) {
        CGFloat interSpace = [self calculateInterspaceForSectionWithRows:self.itemPerSection];
        
        if (section==0) {
            return UIEdgeInsetsMake(verticalMargin, interSpace, minSpace, interSpace);
        }
        return UIEdgeInsetsMake(0, interSpace, minSpace, interSpace);
    }
    else {
        CGFloat interSpace = [self calculateInterspaceForSectionWithRows:self.lastSectionRow];
        
        if (section==0) {
            return UIEdgeInsetsMake(verticalMargin, interSpace, verticalMargin, interSpace);
        }
        return UIEdgeInsetsMake(0, interSpace, verticalMargin, interSpace);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 16.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    
    if (section < self.controlSection-1) {
        return [self calculateInterspaceForSectionWithRows:self.itemPerSection];
    }
    else {
        return [self calculateInterspaceForSectionWithRows:self.lastSectionRow];
    }
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

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}
 
- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}
 
- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
}



#pragma mark - Lazy

- (NSMutableArray *)itemCluster {
    if (!_itemCluster) {
        _itemCluster = [[NSMutableArray alloc] init];
    }
    
    return _itemCluster;
}


@end
