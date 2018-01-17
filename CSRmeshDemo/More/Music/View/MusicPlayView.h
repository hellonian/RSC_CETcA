//
//  MusicPlayView.h
//  MusicPlayerByAVPlayer
//
//  Created by AcTEC on 2017/11/30.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VisualizerView.h"

@protocol MusicPlayViewDelegate <NSObject>

-(void)lastSongAction;
-(void)nextSongAction;
-(void)playPauseAction;
-(void)progressAction:(float)value;

@end

@interface MusicPlayView : UIView

@property (nonatomic,strong)VisualizerView *visualizer;
@property(nonatomic,strong)UILabel * curTimeLabel;
@property(nonatomic,strong)UISlider * progressSlider;
@property(nonatomic,strong)UILabel * totleTiemLabel;

@property(nonatomic,strong)UIButton * lastSongButton;
@property(nonatomic,strong)UIButton * playPauseButton;
@property(nonatomic,strong)UIButton * nextSongButton;
@property (nonatomic,strong) UIButton *stopButton;

@property(nonatomic,weak)id<MusicPlayViewDelegate>delegate;

@end
