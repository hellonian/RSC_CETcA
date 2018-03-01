//
//  PlaceIconCollectionViewCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/12/26.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const PlaceIconCellIdentifier;

@interface PlaceIconCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *placeIcon;

@end
