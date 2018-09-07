//
//  RGBSceneCollectionViewCell.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/8/31.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "RGBSceneCollectionViewCell.h"
#import "CSRConstants.h"

@implementation RGBSceneCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(RGBSceneCellTapGestureAction:)];
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(RGBSceneCellLongPressGestureAction:)];
    [self addGestureRecognizer:tapGesture];
    [self addGestureRecognizer:longPressGesture];
}

- (void)configureCellWithInfo:(id)info index:(NSInteger)index {
    _index = index;
    if ([info isKindOfClass:[RGBSceneEntity class]]) {
        RGBSceneEntity *rgbSceneEntity = (RGBSceneEntity *)info;
        _RGBSceneNameLabel.text = rgbSceneEntity.name;
        if ([rgbSceneEntity.isDefaultImg boolValue]) {
            NSArray *names = kRGBSceneDefaultName;
            NSInteger num = [rgbSceneEntity.rgbSceneID integerValue];
            _RGBSceneImageView.image = [UIImage imageNamed:names[num]];
        }else {
            _RGBSceneImageView.image = [UIImage imageWithData:rgbSceneEntity.rgbSceneImage];
        }
        if ([rgbSceneEntity.eventType boolValue]) {
            _colorfulRingImageView.image = [UIImage imageNamed:@"colorfulRing"];
        }else {
            _colorfulRingImageView.image = nil;
        }
        return;
    }
    if ([info isKindOfClass:[NSNumber class]]) {
        _RGBSceneNameLabel.text = @"Custom colors";
        _RGBSceneImageView.image = [UIImage imageNamed:@"addRing"];
        return;
    }
    
}

- (void)RGBSceneCellTapGestureAction:(UITapGestureRecognizer *)gesture {
    if (self.cellDelegate && [self.cellDelegate respondsToSelector:@selector(RGBSceneCellDelegateTapAction:)]) {
        [self.cellDelegate RGBSceneCellDelegateTapAction:_index];
    }
}

- (void)RGBSceneCellLongPressGestureAction:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (self.cellDelegate && [self.cellDelegate respondsToSelector:@selector(RGBSceneCellDelegateLongPressAction:)]) {
            [self.cellDelegate RGBSceneCellDelegateLongPressAction:_index];
        }
    }
    
}

@end
