//
//  MusicViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/8/30.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "MusicViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "SoundListenTool.h"
#import "RippleAnimationView.h"
#import "PureLayout.h"

@interface MusicViewController ()<SoundListenToolDelegate>

@property (nonatomic, strong) NSMutableArray *images;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (nonatomic, strong) RippleAnimationView *ripple;

@end

@implementation MusicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [SoundListenTool sharedInstance].delegate = self;
    if ([SoundListenTool sharedInstance].audioRecorder.recording) {
        _playBtn.selected = YES;
        if (!_ripple) {
            _ripple = [[RippleAnimationView alloc] initWithFrame:CGRectMake(0, 0, 137, 137) animationType:AnimationTypeWithoutBackground];
            [self.view addSubview:_ripple];
            [self.view bringSubviewToFront:_playBtn];
            [_ripple autoAlignAxis:ALAxisVertical toSameAxisOfView:_playBtn];
            [_ripple autoAlignAxis:ALAxisHorizontal toSameAxisOfView:_playBtn];
            [_ripple autoSetDimension:ALDimensionWidth toSize:137];
            [_ripple autoSetDimension:ALDimensionHeight toSize:137];
        }else {
            [_ripple startAnimation];
        }
    }else {
        _playBtn.selected = NO;
        [_ripple stopAnimation];
    }
    
}

- (IBAction)playPause:(UIButton *)sender {
    if ([SoundListenTool sharedInstance].audioRecorder.recording) {
        [[SoundListenTool sharedInstance] stopRecord:_deviceId];
    }else {
        [[SoundListenTool sharedInstance] record:_deviceId];
        sender.selected = YES;
        if (!_ripple) {
            _ripple = [[RippleAnimationView alloc] initWithFrame:CGRectMake(0, 0, 137, 137) animationType:AnimationTypeWithoutBackground];
            [self.view addSubview:_ripple];
            [self.view bringSubviewToFront:_playBtn];
            [_ripple autoAlignAxis:ALAxisVertical toSameAxisOfView:_playBtn];
            [_ripple autoAlignAxis:ALAxisHorizontal toSameAxisOfView:_playBtn];
            [_ripple autoSetDimension:ALDimensionWidth toSize:137];
            [_ripple autoSetDimension:ALDimensionHeight toSize:137];
        }else {
            [_ripple startAnimation];
        }
    }
}

- (void)stopPlayButtonAnimation:(NSNumber *)deviceId {
    if ([deviceId isEqualToNumber:_deviceId]) {
        _playBtn.selected = NO;
        [_ripple stopAnimation];
    }
}


@end
