//
//  SonosSceneSettingCell.h
//  AcTECBLE
//
//  Created by AcTEC on 2020/12/7.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SonosSelectModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SonosSceneSettingCellDelegate <NSObject>

- (void)unSelectAction:(NSIndexPath *)indexPath;
- (void)setPlayAction:(NSIndexPath *)indexPath;
- (void)setVoiceAction:(NSIndexPath *)indexPath;
- (void)setSelectAction:(NSIndexPath *)indexPath;

@end

@interface SonosSceneSettingCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *selecttitle;
@property (weak, nonatomic) IBOutlet UILabel *playLabel;
@property (weak, nonatomic) IBOutlet UILabel *voiceLabel;
@property (weak, nonatomic) IBOutlet UILabel *selectLabel;
@property (weak, nonatomic) IBOutlet UILabel *playtitle;
@property (weak, nonatomic) IBOutlet UILabel *voicetitle;
@property (weak, nonatomic) IBOutlet UIButton *voiceBtn;
@property (weak, nonatomic) IBOutlet UIButton *selectBtn;
@property (nonatomic, weak) id <SonosSceneSettingCellDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *cellIndexPath;

- (void)configureCellWithSonosSelectModel:(SonosSelectModel *)model indexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
