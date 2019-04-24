//
//  SoundListenTool.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/4/24.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface SoundListenTool : NSObject

@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) NSTimer *recordTimer;
@property (nonatomic, strong) NSNumber *deviceId;

+ (instancetype)sharedInstance;
- (void)record:(NSNumber *)deviceId;
- (void)stopRecord;

@end

