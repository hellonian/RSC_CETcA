//
//  SceneMemberCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/6/10.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SceneMemberEntity.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SceneMemberCellDelegate <NSObject>

- (void)removeSceneMember:(SceneMemberEntity *)mSceneMember;

@end

@interface SceneMemberCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *channelLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imgv1;
@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UIImageView *imgv2;
@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (weak, nonatomic) IBOutlet UIImageView *imgv3;
@property (weak, nonatomic) IBOutlet UILabel *label3;
@property (weak, nonatomic) IBOutlet UIButton *removeBtn;
@property (nonatomic, strong) SceneMemberEntity *mSceneMember;
@property (nonatomic, weak) id<SceneMemberCellDelegate> cellDelegate;

- (void)configureCellWithSceneMember:(SceneMemberEntity *)member;

@end

NS_ASSUME_NONNULL_END
