//
//  MusicViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/8/30.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MusicViewController.h"
#import "MusicListTableViewController.h"
#import "MusicPlayTools.h"

@interface MusicViewController ()

@property (weak, nonatomic) IBOutlet UIButton *chooseMusicBtn;
@property (weak, nonatomic) IBOutlet UILabel *musicTitle;

@end

@implementation MusicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [_chooseMusicBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -_chooseMusicBtn.imageView.frame.size.width, 0, _chooseMusicBtn.imageView.frame.size.width)];
    [_chooseMusicBtn setImageEdgeInsets:UIEdgeInsetsMake(0, _chooseMusicBtn.titleLabel.bounds.size.width, 0, -_chooseMusicBtn.titleLabel.bounds.size.width)];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([MusicPlayTools shareMusicPlay].mediaItem) {
        _musicTitle.text = [[MusicPlayTools shareMusicPlay].mediaItem valueForProperty:MPMediaItemPropertyTitle];
    }
}

- (IBAction)chooseMusic:(UIButton *)sender {
    MusicListTableViewController *mlvc = [[MusicListTableViewController alloc] init];
    mlvc.deviceId = _deviceId;
    [self.navigationController pushViewController:mlvc animated:YES];
}

- (IBAction)playPause:(UIButton *)sender {
    if ([MusicPlayTools shareMusicPlay].mediaItem) {
        [MusicPlayTools shareMusicPlay].deviceId = _deviceId;
        if ([MusicPlayTools shareMusicPlay].audioPlayer.playing) {
            [[MusicPlayTools shareMusicPlay] musicPause];
        }else {
            [[MusicPlayTools shareMusicPlay] musicPlay];
        }
    }
}


@end
