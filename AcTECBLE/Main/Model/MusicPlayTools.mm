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
@property(nonatomic,strong)NSTimer * playTimer;
@property(nonatomic,strong)NSTimer * recordTimer;
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
    if (self.audioRecorder.recording) {
        [self recordStop];
    }
    // 如果计时器已经存在了,说明已经在播放中,直接返回.
    // 对于已经存在的计时器,只有musicPause方法才会使之停止和注销.
    if (self.playTimer != nil) {
        return;
    }
    
    // 播放后,我们开启一个计时器.
    self.playTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(playTimerAction:) userInfo:nil repeats:YES];
    
    [self.audioPlayer play];
    
}

-(void)playTimerAction:(NSTimer * )sender
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
    [self.playTimer invalidate];
    self.playTimer = nil;
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
    [self.playTimer invalidate];
    self.playTimer = nil;
    [self.audioPlayer stop];
}

- (void)startRecording {
    if (self.audioPlayer.playing) {
        [self musicStop];
    }
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    NSDictionary *setting = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithFloat:44100.0],AVSampleRateKey,
                             [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                             [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                             [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
                             nil];
    NSError *error;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:setting error:&error];
    if (self.audioRecorder)
    {
        [self.audioRecorder prepareToRecord];
        self.audioRecorder.meteringEnabled = YES;
        [self.audioRecorder record];
        self.recordTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector: @selector(recordTimerAction:) userInfo: nil repeats: YES];
    }
    else
    {
        NSLog(@"%@", [error description]);
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
    UIColor *color = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
    [[LightModelApi sharedInstance] setColor:_deviceId color:color duration:@0 success:nil failure:nil];
}

- (void)recordStop {
    [self.recordTimer invalidate];
    self.recordTimer = nil;
    [self.audioRecorder stop];
}

@end
