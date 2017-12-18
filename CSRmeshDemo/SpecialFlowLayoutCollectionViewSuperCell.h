//
//  SpecialFlowLayoutCollectionViewSuperCell.h
//  BluetoothAcTEC
//
//  Created by hua on 10/11/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SpecialFlowLayoutCollectionViewSuperCellDelegate <NSObject>
@optional
- (void)specialFlowLayoutCollectionViewSuperCell:(UICollectionViewCell*)cell didClickOnDeleteButton:(UIButton*)sender;
- (void)specialFlowLayoutCollectionViewSuperCell:(UICollectionViewCell *)cell requireMenuAction:(NSString*)actionName;
@end

@interface SpecialFlowLayoutCollectionViewSuperCell : UICollectionViewCell
@property (nonatomic,strong) NSIndexPath *myIndexpath;
@property (nonatomic,weak) id<SpecialFlowLayoutCollectionViewSuperCellDelegate> delegate;
- (void)configureCellWithInfo:(id)info adjustSize:(CGSize)size;
- (void)showDeleteButton:(BOOL)show;
@end
