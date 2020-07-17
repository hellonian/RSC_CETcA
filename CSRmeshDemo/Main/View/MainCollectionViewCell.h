//
//  MainCollectionViewCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "SuperCollectionViewCell.h"

@interface MainCollectionViewCell : SuperCollectionViewCell

@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,strong) NSNumber *groupId;
@property (nonatomic,strong) NSArray *groupMembers;
@property (weak, nonatomic) IBOutlet UIButton *seleteButton;
@property (nonatomic,strong) NSNumber *rcIndex;

- (void)showDeleteBtnAndMoveImageView:(BOOL)value;

@end
