//
//  RGBSceneCollectionViewCell.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/8/31.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RGBSceneEntity.h"

@protocol RGBSceneCellDelegate <NSObject>

- (void)RGBSceneCellDelegateLongPressAction:(NSInteger)index;
- (void)RGBSceneCellDelegateTapAction:(NSInteger)index;

@end

@interface RGBSceneCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *RGBSceneImageView;
@property (weak, nonatomic) IBOutlet UILabel *RGBSceneNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *colorfulRingImageView;
@property (nonatomic,assign) NSInteger index;
@property (nonatomic,weak) id<RGBSceneCellDelegate> cellDelegate;

- (void)configureCellWithInfo:(RGBSceneEntity *)rgbSceneEntity index:(NSInteger)index;

@end
