//
//  MusicPlayView.m
//  MusicPlayerByAVPlayer
//
//  Created by AcTEC on 2017/11/30.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import "MusicPlayView.h"

@implementation MusicPlayView

// 初始化
-(instancetype)init{
    if (self = [super init]) {
        // 布局方法
        [self p_setup];
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

-(void)p_setup
{
    // 点流图
    self.visualizer = [[VisualizerView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT)];
    [self addSubview:self.visualizer];
    
    // 播放进度条
    self.progressSlider = [[UISlider alloc] init];
    self.progressSlider.center = CGPointMake(WIDTH/2, HEIGHT-120);
    self.progressSlider.bounds = CGRectMake(0, 0, WIDTH - 120, 30);
    [self.progressSlider setMinimumTrackTintColor:[UIColor orangeColor]];
    [self addSubview:self.progressSlider];
    [self.progressSlider addTarget:self action:@selector(progressSliderAction:) forControlEvents:UIControlEventValueChanged];
    
    // 当前播放时间
    self.curTimeLabel = [[UILabel alloc] init];
    self.curTimeLabel.center = CGPointMake(30, HEIGHT-120);
    self.curTimeLabel.bounds = CGRectMake(0, 0, 60, 30);
    self.curTimeLabel.textAlignment = NSTextAlignmentCenter;
    self.curTimeLabel.textColor = [UIColor whiteColor];
    [self addSubview:self.curTimeLabel];
    
    // 总时间
    self.totleTiemLabel = [[UILabel alloc] init];
    self.totleTiemLabel.frame = CGRectMake(CGRectGetMaxX(self.progressSlider.frame),
                                           CGRectGetMinY(self.progressSlider.frame),
                                           CGRectGetWidth(self.curTimeLabel.frame),
                                           CGRectGetHeight(self.curTimeLabel.frame));
    self.totleTiemLabel.textAlignment = NSTextAlignmentCenter;
    self.totleTiemLabel.textColor = [UIColor whiteColor];
    [self addSubview:self.totleTiemLabel];
    
    // 播放/暂停的按钮
    self.playPauseButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    self.playPauseButton.center = CGPointMake(WIDTH/2, HEIGHT-60);
    self.playPauseButton.bounds = CGRectMake(0, 0, 60, 60);
    [self addSubview:self.playPauseButton];
    [self.playPauseButton addTarget:self action:@selector(playPauseButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    // 上一首的按钮
    self.lastSongButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    self.lastSongButton.center = CGPointMake(WIDTH/2-90, HEIGHT-60);
    self.lastSongButton.bounds = CGRectMake(0, 0, 60, 60);
    [self.lastSongButton setBackgroundImage:[UIImage imageNamed:@"last"] forState:UIControlStateNormal];
    [self addSubview:self.lastSongButton];
    [self.lastSongButton addTarget:self action:@selector(lastSongButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    
    // 下一首的按钮
    self.nextSongButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    self.nextSongButton.center = CGPointMake(WIDTH/2+90, HEIGHT-60);
    self.nextSongButton.bounds = CGRectMake(0, 0, 60, 60);
    [self.nextSongButton setBackgroundImage:[UIImage imageNamed:@"next"] forState:UIControlStateNormal];
    [self addSubview:self.nextSongButton];
    [self.nextSongButton addTarget:self action:@selector(nextSongButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

// 这里采用真正的MVC设计模式, 和其他的空间比较一下, 这里将lastButton的处理事件作为代理事件被外部重新实现.
-(void)lastSongButtonAction:(UIButton *)sender
{
    [self.delegate lastSongAction];
}

- (void)nextSongButtonAction:(UIButton *)sender
{
    [self.delegate nextSongAction];
}

- (void)playPauseButtonAction:(UIButton *)sender
{
    [self.delegate playPauseAction];
}

- (void)progressSliderAction:(UISlider *)sender
{
    [self.delegate progressAction:sender.value];
}

@end
