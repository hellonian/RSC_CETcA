//
//  SocketPowerCell.h
//  AcTECBLE
//
//  Created by AcTEC on 2019/1/7.
//  Copyright © 2019 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SocketPowerCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *histogramView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hisViewHeight;

- (void)configureCellWithiInfo:(id)info maxPowerValue:(CGFloat)maxPowerValue;

@end

NS_ASSUME_NONNULL_END
