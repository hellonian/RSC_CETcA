//
//  MusicPlayTools.m
//  MusicPlayerByAVPlayer
//
//  Created by AcTEC on 2017/11/30.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import "MusicPlayTools.h"
#import "MeterTable.h"
#import <CSRmesh/LightModelApi.h>

static MusicPlayTools * mp = nil;

@interface MusicPlayTools ()<AVAudioPlayerDelegate>
{
    MeterTable meterTable;
}
@property(nonatomic,strong)NSTimer * timer;
@end

@implementation MusicPlayTools

// 单例方法
+(instancetype)shareMusicPlay
{
    if (mp == nil) {
        static dispatch_once_t once_token;
        dispatch_once(&once_token, ^{
            mp = [[MusicPlayTools alloc] init];
        });
    }
    return mp;
}

//代理AVAudioPlayerDelegate，每一首结束的时候调用
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (flag) {
        [self.delegate endOfPlayAction];
    } 
}

// 开始播放
- (void)preparePlay {
    if (_audioPlayer) {
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
    
    NSURL *url = [self.mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [_audioPlayer setMeteringEnabled:YES];
    [_audioPlayer setDelegate:self];
    [self musicPlay];
}

// 播放
-(void)musicPlay
{
    // 如果计时器已经存在了,说明已经在播放中,直接返回.
    // 对于已经存在的计时器,只有musicPause方法才会使之停止和注销.
    if (self.timer != nil) {
        return;
    }
    
    // 播放后,我们开启一个计时器.
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
    
    [self.audioPlayer play];
    
}

-(void)timerAction:(NSTimer * )sender
{
    // !! 计时器的处理方法中,不断的调用代理方法,将播放进度返回出去.
    // 一定要掌握这种形式.
//    [self.delegate getCurTiem:[self valueToString:self.audioPlayer.currentTime] Totle:[self valueToString:self.audioPlayer.duration] Progress:(CGFloat)self.audioPlayer.currentTime/self.audioPlayer.duration];
    if (_audioPlayer.playing) {
        [_audioPlayer updateMeters];
        
        float power = 0.0f;
        for (int i = 0; i<[_audioPlayer numberOfChannels]; i++) {
            power += [_audioPlayer averagePowerForChannel:i];
        }
        power /= [_audioPlayer numberOfChannels];
        
        float hue = meterTable.ValueAt(power);
        UIColor *color = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
        [[LightModelApi sharedInstance] setColor:_deviceId color:color duration:@0 success:nil failure:nil];
    }
}

// 暂停方法
-(void)musicPause
{
    [self.timer invalidate];
    self.timer = nil;
    [self.audioPlayer pause];
}

// 跳转方法
-(void)seekToTimeWithValue:(CGFloat)value
{
    // 先暂停
    [self musicPause];
    
    // 跳转
    [self.audioPlayer setCurrentTime:value*self.audioPlayer.duration];
    
    [self musicPlay];
}

// 将整数秒转换为 00:00 格式的字符串
-(NSString *)valueToString:(NSInteger)value
{
    return [NSString stringWithFormat:@"%.2ld:%.2ld",value/60,value%60];
}

//停止
- (void)musicStop {
    [self.timer invalidate];
    self.timer = nil;
    [self.audioPlayer stop];
}

@end
