//
//  SonosSceneSettingCell.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/12/7.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "SonosSceneSettingCell.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import "CSRConstants.h"

@implementation SonosSceneSettingCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureCellWithSonosSelectModel:(SonosSelectModel *)model indexPath:(nonnull NSIndexPath *)indexPath {
    _cellIndexPath = indexPath;
    _nameLabel.text = model.name;
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:model.deviceID];
    if ([CSRUtilities belongToSonosMusicController:device.shortName]) {
        _selecttitle.text = @"Select Music";
    }else if ([CSRUtilities belongToMusicController:device.shortName]) {
        _selecttitle.text = @"Select Source";
    }
    if (model.play) {
        _playLabel.text = @"Play";
        _voicetitle.textColor = ColorWithAlpha(77, 77, 77, 1);
        _selecttitle.textColor = ColorWithAlpha(77, 77, 77, 1);
        _voiceLabel.text = [NSString stringWithFormat:@"%ld", model.voice];
        if ([CSRUtilities belongToSonosMusicController:device.shortName] && model.songNumber != -1) {
            if ([device.remoteBranch length]>0) {
                NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:device.remoteBranch];
                if ([jsonDictionary count]>0) {
                    NSArray *songs = jsonDictionary[@"song"];
                    for (NSDictionary *dic in songs) {
                        NSInteger n = [dic[@"id"] integerValue];
                        if (n == model.songNumber) {
                            _selectLabel.text = dic[@"name"];
                            break;
                        }
                    }
                }
            }
        }else if ([CSRUtilities belongToMusicController:device.shortName] && model.source != -1) {
            _selectLabel.text = [AUDIOSOURCES objectAtIndex:model.source];
        }
        _voiceBtn.enabled = YES;
        _selectBtn.enabled = YES;
    }else {
        _playLabel.text = @"Stop";
        _voicetitle.textColor = ColorWithAlpha(200, 200, 200, 1);
        _selecttitle.textColor = ColorWithAlpha(200, 200, 200, 1);
        _voiceLabel.text = @"";
        _selectLabel.text = @"";
        _voiceBtn.enabled = NO;
        _selectBtn.enabled = NO;
    }
    if (model.reSetting) {
        _channelSelectBtn.hidden = YES;
    }else {
        _channelSelectBtn.hidden = NO;
    }
}

- (IBAction)unSelectClick:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(unSelectAction:)]) {
        [self.delegate unSelectAction:_cellIndexPath];
    }
}

- (IBAction)setPlayClick:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(setPlayAction:)]) {
        [self.delegate setPlayAction:_cellIndexPath];
    }
}

- (IBAction)setVoiceClick:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(setVoiceAction:)]) {
        [self.delegate setVoiceAction:_cellIndexPath];
    }
}

- (IBAction)setSelectClick:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(setSelectAction:)]) {
        [self.delegate setSelectAction:_cellIndexPath];
    }
}

@end
