//
//  SuperCollectionViewCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SuperCollectionViewCellDelegate <NSObject>

//@optional
- (void)superCollectionViewCellDelegateAddDeviceAction:(NSNumber *)cellDeviceId;

@end

@interface SuperCollectionViewCell : UICollectionViewCell

@property (nonatomic,weak) id<SuperCollectionViewCellDelegate> superCellDelegate;

- (void)configureCellWithiInfo:(id)info;

@end
