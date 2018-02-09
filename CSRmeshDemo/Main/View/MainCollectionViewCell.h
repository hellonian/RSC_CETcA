//
//  MainCollectionViewCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/18.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SuperCollectionViewCell.h"

@interface MainCollectionViewCell : SuperCollectionViewCell

@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,strong) NSNumber *groupId;
@property (nonatomic,strong) NSArray *groupMembers;
@property (weak, nonatomic) IBOutlet UIButton *seleteButton;

- (void)showDeleteBtnAndMoveImageView:(BOOL)value;

@end
