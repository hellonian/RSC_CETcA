//
//  MusicViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/8/30.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MusicViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CSRmesh/LightModelApi.h>
//#import "MusicListTableViewController.h"
//#import "MusicPlayTools.h"

@interface MusicViewController ()

//@property (weak, nonatomic) IBOutlet UIButton *chooseMusicBtn;
//@property (weak, nonatomic) IBOutlet UILabel *musicTitle;
@property (weak, nonatomic) IBOutlet UIImageView *musicImageView;
@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic,strong) NSTimer * recordTimer;
@property (nonatomic,strong) AVAudioRecorder *audioRecorder;

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
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat: 44100.0], AVSampleRateKey,
                              [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                              [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                              [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
                              nil];
    NSError *error;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
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
    
    if (self.audioRecorder) {
        if (self.audioRecorder.recording) {
            [_musicImageView stopAnimating];
            [sender setBackgroundImage:[UIImage imageNamed:@"music"] forState:UIControlStateNormal];
            [self.audioRecorder stop];
            [self.recordTimer invalidate];
            self.recordTimer = nil;
        }else {
            [sender setBackgroundImage:[UIImage imageNamed:@"musicHighlight"] forState:UIControlStateNormal];
            [_musicImageView startAnimating];
            [self.audioRecorder prepareToRecord];
            self.audioRecorder.meteringEnabled = YES;
            [self.audioRecorder record];
            self.recordTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector: @selector(recordTimerAction:) userInfo: nil repeats: YES];
        }
    }
}

- (void)recordTimerAction:(NSTimer *)sender {
    [self.audioRecorder updateMeters];
    float hue;
    float minDecibels = -80.0f;
    float decibels = [self.audioRecorder averagePowerForChannel:0];
    
    if (decibels < minDecibels)
    {
        hue = 0.0f;
    }
    else if (decibels >= 0.0f)
    {
        hue = 1.0f;
    }
    else
    {
        float   root            = 2.0f;
        float   minAmp          = powf(10.0f, 0.05f * minDecibels);
        float   inverseAmpRange = 1.0f / (1.0f - minAmp);
        float   amp             = powf(10.0f, 0.05f * decibels);
        float   adjAmp          = (amp - minAmp) * inverseAmpRange;
        
        hue = powf(adjAmp, 1.0f / root);
    }
//    NSLog(@"~~~~~~> %f",hue);
    UIColor *color = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
    [[LightModelApi sharedInstance] setColor:_deviceId color:color duration:@0 success:nil failure:nil];
}


@end
