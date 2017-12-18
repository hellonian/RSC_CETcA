//
//  MusicListTableViewCell.m
//  MusicPlayerByAVPlayer
//
//  Created by AcTEC on 2017/11/30.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import "MusicListTableViewCell.h"

@implementation MusicListTableViewCell

- (void)setMediaItem:(MPMediaItem *)mediaItem {
//    NSURL *url = [mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
    MPMediaItemArtwork *artwork = [mediaItem valueForProperty:MPMediaItemPropertyArtwork];
    UIImage *image = [artwork imageWithSize:self.headImageView.bounds.size];
    NSString *name = [mediaItem valueForProperty:MPMediaItemPropertyTitle];
    NSString *artist = [mediaItem valueForProperty:MPMediaItemPropertyArtist];
    
    if (image) {
        self.headImageView.image = image;
    }else{
        self.headImageView.image = [UIImage imageNamed:@"music.jpg"];
    }
    
    self.songNameLable.text = name;
    self.authorNameLabel.text = artist;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
