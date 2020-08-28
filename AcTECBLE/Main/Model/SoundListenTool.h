//
//  SoundListenTool.h
//  AcTECBLE
//
//  Created by AcTEC on 2019/4/24.
//  Copyright © 2019 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol SoundListenToolDelegate <NSObject>

- (void)stopPlayButtonAnimation:(NSNumber *)deviceId;

@end

@interface SoundListenTool : NSObject

@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) NSTimer *recordTimer;
@property (nonatomic, strong) NSNumber *deviceId;
@property (nonatomic, weak) id<SoundListenToolDelegate> delegate;

+ (instancetype)sharedInstance;
- (void)record:(NSNumber *)deviceId;
- (void)stopRecord:(NSNumber *)deviceId;

@end

