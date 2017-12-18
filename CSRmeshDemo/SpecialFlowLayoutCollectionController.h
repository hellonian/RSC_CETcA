//
//  SpecialFlowLayoutCollectionController.h
//  BluetoothAcTEC
//
//  Created by hua on 10/11/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpecialFlowLayoutCollectionViewSuperCell.h"
#import "HitTestAlrightCollectionView.h"

@interface SpecialFlowLayoutCollectionController : UIViewController<UICollectionViewDelegate,SpecialFlowLayoutCollectionViewSuperCellDelegate>
@property (nonatomic,strong) NSMutableArray *itemCluster;
@property (nonatomic,strong) HitTestAlrightCollectionView *lightPanel;
@property (nonatomic,assign) BOOL allowEdit;
- (instancetype)initWithItemPerSection:(NSInteger)count cellIdentifier:(NSString*)identifier;
- (void)updateCollectionView;
- (void)fixLayout;

- (void)beginEdit;
- (void)endEdit;
- (void)terminateEdit;

- (NSInteger)dataIndexOfCellAtIndexPath:(NSIndexPath*)indexPath;

@end
