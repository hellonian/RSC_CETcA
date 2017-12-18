//
//  MusicListTableViewCell.h
//  MusicPlayerByAVPlayer
//
//  Created by AcTEC on 2017/11/30.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MusicListTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *headImageView;
@property (weak, nonatomic) IBOutlet UILabel *songNameLable;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;

@property(nonatomic,strong) MPMediaItem *mediaItem;

@end
