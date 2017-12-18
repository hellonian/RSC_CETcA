//
//  PrimaryItemCell.h
//  BluetoothAcTEC
//
//  Created by hua on 10/11/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "SpecialFlowLayoutCollectionViewSuperCell.h"

@interface PrimaryItemCell : SpecialFlowLayoutCollectionViewSuperCell

@property (weak, nonatomic) IBOutlet UIImageView *itemPresentation;
@property (weak, nonatomic) IBOutlet UILabel *lightAddressLabel;

@end
