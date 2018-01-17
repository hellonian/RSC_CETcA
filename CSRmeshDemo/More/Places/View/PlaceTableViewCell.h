//
//  PlaceTableViewCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/12/22.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const PlaceTableViewCellIdentifier;

@interface PlaceTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *placeIcon;
@property (weak, nonatomic) IBOutlet UIImageView *currentPlaceIndicator;
@property (weak, nonatomic) IBOutlet UILabel *placeNameLabel;

@end
