//
//  SpecialFlowLayoutCollectionViewSuperCell.m
//  BluetoothAcTEC
//
//  Created by hua on 10/11/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "SpecialFlowLayoutCollectionViewSuperCell.h"

@implementation SpecialFlowLayoutCollectionViewSuperCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)configureCellWithInfo:(id)info adjustSize:(CGSize)size {
    //override in subclass
}

- (void)showDeleteButton:(BOOL)show {
    //override in subclass
}

@end
