//
//  MusicViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/8/30.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MusicViewController.h"
#import <AVFoundation/AVFoundation.h>
//#import "MusicListTableViewController.h"
//#import "MusicPlayTools.h"
#import "SoundListenTool.h"

@interface MusicViewController ()<SoundListenToolDelegate>

//@property (weak, nonatomic) IBOutlet UIButton *chooseMusicBtn;
//@property (weak, nonatomic) IBOutlet UILabel *musicTitle;
@property (weak, nonatomic) IBOutlet UIImageView *musicImageView;
@property (nonatomic, strong) NSMutableArray *images;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

@end

@implementation MusicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
//    [_chooseMusicBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -_chooseMusicBtn.imageView.frame.size.width, 0, _chooseMusicBtn.imageView.frame.size.width)];
//    [_chooseMusicBtn setImageEdgeInsets:UIEdgeInsetsMake(0, _chooseMusicBtn.titleLabel.bounds.size.width, 0, -_chooseMusicBtn.titleLabel.bounds.size.width)];
    _images = [[NSMutableArray alloc] init];
    for (int i=0; i<7; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"music_%d",i]];
        [_images addObject:image];
    }
    _musicImageView.animationDuration = 1;
    _musicImageView.animationImages = _images;
    
    [SoundListenTool sharedInstance].delegate = self;
    if ([SoundListenTool sharedInstance].audioRecorder.recording) {
        [_playBtn setBackgroundImage:[UIImage imageNamed:@"musicHighlight"] forState:UIControlStateNormal];
        [_musicImageView startAnimating];
    }else {
        [_musicImageView stopAnimating];
        [_playBtn setBackgroundImage:[UIImage imageNamed:@"music"] forState:UIControlStateNormal];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    if ([MusicPlayTools shareMusicPlay].mediaItem) {
//        _musicTitle.text = [[MusicPlayTools shareMusicPlay].mediaItem valueForProperty:MPMediaItemPropertyTitle];
//    }
}

//- (IBAction)chooseMusic:(UIButton *)sender {
//    MusicListTableViewController *mlvc = [[MusicListTableViewController alloc] init];
//    mlvc.deviceId = _deviceId;
//    [self.navigationController pushViewController:mlvc animated:YES];
//}

- (IBAction)playPause:(UIButton *)sender {
//    if ([MusicPlayTools shareMusicPlay].mediaItem) {
//        [MusicPlayTools shareMusicPlay].deviceId = _deviceId;
//        if ([MusicPlayTools shareMusicPlay].audioPlayer.playing) {
//            [[MusicPlayTools shareMusicPlay] musicPause];
//        }else {
//            [[MusicPlayTools shareMusicPlay] musicPlay];
//        }
//    }
    
//    if ([MusicPlayTools shareMusicPlay].audioRecorder.recording) {
//        [[MusicPlayTools shareMusicPlay] recordStop];
//        [_musicImageView stopAnimating];
//        [sender setBackgroundImage:[UIImage imageNamed:@"music"] forState:UIControlStateNormal];
//    }else {
//        [MusicPlayTools shareMusicPlay].deviceId = _deviceId;
//        [[MusicPlayTools shareMusicPlay] startRecording];
//        [sender setBackgroundImage:[UIImage imageNamed:@"musicHighlight"] forState:UIControlStateNormal];
//        [_musicImageView startAnimating];
//    }
    
    if ([SoundListenTool sharedInstance].audioRecorder.recording) {
        [[SoundListenTool sharedInstance] stopRecord:_deviceId];
    }else {
        [[SoundListenTool sharedInstance] record:_deviceId];
        [sender setBackgroundImage:[UIImage imageNamed:@"musicHighlight"] forState:UIControlStateNormal];
        [_musicImageView startAnimating];
    }
}

- (void)stopPlayButtonAnimation:(NSNumber *)deviceId {
    if ([deviceId isEqualToNumber:_deviceId]) {
        [_musicImageView stopAnimating];
        [_playBtn setBackgroundImage:[UIImage imageNamed:@"music"] forState:UIControlStateNormal];
    }
}


@end
