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
#import "CSRDatabaseManager.h"

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
        
        hue = powf(adjAmp, 1.0f / root);//分贝值，范围0~1
//        NSLog(@"%f",hue);
    }
    if (hue > 0.3) {
        /*
        CGFloat colorHue = (hue-0.3)/0.5,colorBrightness = (hue-0.3)/0.5;
        if (colorHue < 0) {
            colorHue = 0;
        }else if (colorHue > 1) {
            colorHue = 1.0;
        }
        if (colorBrightness < 0) {
            colorBrightness = 0;
        }else if (colorBrightness > 1.0) {
            colorBrightness = 1.0;
        }
        static float i=0, minus;
        if (i==0) {
            i=0.5;
        }else if (i==0.5) {
            i=0;
        }
        colorHue = colorHue - i;
        if (colorHue < 0) {
            colorHue = colorHue + 1;
        }
        UIColor *color = [UIColor colorWithHue:colorHue saturation:1.0 brightness:colorBrightness alpha:1.0];
        CGFloat red,green,blue,alpha;
        if ([color getRed:&red green:&green blue:&blue alpha:&alpha]) {
            [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"640600%@%@%@0000",[CSRUtilities stringWithHexNumber:red*255],[CSRUtilities stringWithHexNumber:green*255],[CSRUtilities stringWithHexNumber:blue*255]] toDeviceId:self.deviceId];
        }
        NSLog(@">> %f",minus-hue);
        minus = hue;
         */
        /*
        static float i=0, minus,lastHue,offsetValue,colorBrightness,colorHue;
        
        colorHue = hue;
        minus = hue - lastHue;
        
        offsetValue = hue * minus * (hue*20);
        if (offsetValue>0.5) {
            offsetValue=0.5;
        }else if (offsetValue<-0.5) {
            offsetValue=-0.5;
        }
        
        if (i==0) {
            i=1.0;
        }else if (i==1) {
            i=0;
            colorHue = fabsf(lastHue + offsetValue);
            if (colorHue > 1.0) {
                colorHue = colorHue - 1.0;
            }
        }
        
        colorBrightness = hue + minus;
        if (colorBrightness < 0.03) {
            colorBrightness = 0.03;
        }else if (colorBrightness > 1.0) {
            colorBrightness = 1.0;
        }
        
        UIColor *color = [UIColor colorWithHue:colorHue saturation:1.0 brightness:colorBrightness alpha:1.0];
        CGFloat red,green,blue,alpha;
        if ([color getRed:&red green:&green blue:&blue alpha:&alpha]) {
            [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"640600%@%@%@0000",[CSRUtilities stringWithHexNumber:red*255],[CSRUtilities stringWithHexNumber:green*255],[CSRUtilities stringWithHexNumber:blue*255]] toDeviceId:self.deviceId];
        }
        
        lastHue = hue;
        
        NSLog(@"%f  ||%f  》%f  >%f  ~%f",hue,colorHue,minus,offsetValue,colorBrightness);
//        NSLog(@">> %f",hue);
        */
        
        static float minus,lastHue,offsetValue,colorBrightness,colorHue,lastColorHue;
        
        minus = hue - lastHue;
        
        offsetValue = hue * minus * (hue*20);
        if (offsetValue>0.5) {
            offsetValue=0.5;
        }else if (offsetValue<-0.5) {
            offsetValue=-0.5;
        }
        
        colorHue = lastColorHue + offsetValue;
        if (colorHue<0) {
            colorHue = fabsf(colorHue);
        }else if (colorHue>1.0) {
            colorHue = colorHue - 1.0;
        }
        
        colorBrightness = hue + minus;
        if (colorBrightness < 0.03) {
            colorBrightness = 0.03;
        }else if (colorBrightness > 1.0) {
            colorBrightness = 1.0;
        }
        
        UIColor *color = [UIColor colorWithHue:colorHue saturation:1.0 brightness:colorBrightness alpha:1.0];
        CGFloat red,green,blue,alpha;
        if ([color getRed:&red green:&green blue:&blue alpha:&alpha]) {
            [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"640600%@%@%@0000",[CSRUtilities stringWithHexNumber:red*255],[CSRUtilities stringWithHexNumber:green*255],[CSRUtilities stringWithHexNumber:blue*255]] toDeviceId:self.deviceId];
        }
        
        lastHue = hue;
        lastColorHue = colorHue;
        
//        NSLog(@"%f  ||%f  》%f  >%f  ~%f",hue,colorHue,minus,offsetValue,colorBrightness);
//        NSLog(@"~%f  >%f",colorHue,offsetValue);
        
    }
}

- (void)stopRecord:(NSNumber *)deviceId {
    
    BOOL exist = NO;
    
    if ([deviceId isEqualToNumber:_deviceId]) {
        
        exist = YES;
        
    }else {
        
        if ([deviceId integerValue]<65521 && [deviceId integerValue]>32768) {
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
            if (device && [device.areas count]>0) {
                for (CSRAreaEntity *area in device.areas) {
                    if ([area.areaID isEqualToNumber:_deviceId]) {
                        exist = YES;
                        break;
                    }
                }
            }
        }else if ([deviceId integerValue]<32768 && [deviceId integerValue]>9) {
            CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:deviceId];
            if (area && [area.devices count]>0 ) {
                for (CSRDeviceEntity *device in area.devices) {
                    if ([device.deviceId isEqualToNumber:_deviceId]) {
                        exist = YES;
                        break;
                    }
                }
            }
        }
    }
    
    if (exist) {
        [self.audioRecorder stop];
        [self.recordTimer invalidate];
        self.recordTimer = nil;
        self.deviceId = nil;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(stopPlayButtonAnimation:)]) {
            [self.delegate stopPlayButtonAnimation:deviceId];
        }
    }
}

@end
