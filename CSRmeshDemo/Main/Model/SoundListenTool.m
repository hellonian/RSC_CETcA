//
//  SoundListenTool.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/4/24.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SoundListenTool.h"
#import "DataModelManager.h"
#import "CSRUtilities.h"

@implementation SoundListenTool

+ (instancetype)sharedInstance {
    static SoundListenTool *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[SoundListenTool alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
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
    return self;
}

- (void)record:(NSNumber *)deviceId {
    self.deviceId = deviceId;
    [self.audioRecorder prepareToRecord];
    self.audioRecorder.meteringEnabled = YES;
    [self.audioRecorder record];
    self.recordTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector: @selector(recordTimerAction:) userInfo: nil repeats: YES];
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
    CGFloat red,green,blue,alpha;
    if ([color getRed:&red green:&green blue:&blue alpha:&alpha]) {
        [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"640600%@%@%@0000",[CSRUtilities stringWithHexNumber:red*255],[CSRUtilities stringWithHexNumber:green*255],[CSRUtilities stringWithHexNumber:blue*255]] toDeviceId:self.deviceId];
    }
}

- (void)stopRecord {
    [self.audioRecorder stop];
    [self.recordTimer invalidate];
    self.recordTimer = nil;
    self.deviceId = nil;
}

@end
