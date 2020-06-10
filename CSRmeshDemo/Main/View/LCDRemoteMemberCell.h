//
//  LCDRemoteMemberCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/1/2.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LCDRemoteMemberCellDelgate <NSObject>

- (void)LCDRemoteMemberCellLongPressItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)LCDRemoteMemberCellMoveItem:(UIPanGestureRecognizer *)gesture;

@end

@interface LCDRemoteMemberCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *add;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (nonatomic, strong) NSIndexPath *cellIndexPath;
@property (nonatomic, weak) id<LCDRemoteMemberCellDelgate> cellDelgate;

- (void)configureCellWithInfo:(id)info indexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
