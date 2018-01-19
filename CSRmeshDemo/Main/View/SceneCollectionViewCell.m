//
//  SceneCollectionViewCell.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SceneCollectionViewCell.h"

@interface SceneCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;


@end

@implementation SceneCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}


- (void)configureCellWithiInfo:(id)info {
    if ([info isKindOfClass:[NSString class]]) {
        self.nameLabel.text = @"Home";

    }
    
    
}

@end
