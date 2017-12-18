//
//  MusicPlayViewController.m
//  MusicPlayerByAVPlayer
//
//  Created by AcTEC on 2017/11/30.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import "MusicPlayViewController.h"
#import "MusicPlayView.h"
#import "MusicPlayTools.h"
#import "GetDataTools.h"
#import "MusicDimmerChooseVC.h"
#import "CSRDeviceEntity.h"

@interface MusicPlayViewController ()<MusicPlayToolsDelegate,MusicPlayViewDelegate>

@property(nonatomic,strong)MusicPlayView * rv;
@property(nonatomic,strong)MusicPlayTools * playTool;
@property(nonatomic,strong)UILabel *titleLab;
@property (nonatomic,strong)NSMutableArray *deviceIds;
@property (nonatomic,strong)UILabel *devicesLabel;

@end

static MusicPlayViewController * mp = nil;

@implementation MusicPlayViewController

-(void)loadView
{
    [super loadView];
    self.rv = [[MusicPlayView alloc]init];
    self.view = _rv;
}

// 单例方法
+(instancetype)shareMusicPlay
{
    if (mp == nil) {
        static dispatch_once_t once_token;
        dispatch_once(&once_token, ^{
            mp = [[MusicPlayViewController alloc] init];
        });
    }
    return mp;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // ios7以后,原点是(0,0)点, 而我们希望是ios7之前的(0,64)处,也就是navigationController导航栏的下面作为(0,0)点. 下面的设置就是做这个的.
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.center = CGPointMake(WIDTH/2, 44);
    back.bounds = CGRectMake(0, 0, 44, 44);
    [back setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [back addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:back];
    
    _titleLab = [[UILabel alloc] init];
    _titleLab.center = CGPointMake(WIDTH/2, 100);
    _titleLab.bounds = CGRectMake(0, 0, WIDTH, 44);
    _titleLab.textAlignment = NSTextAlignmentCenter;
    _titleLab.textColor = [UIColor whiteColor];
    _titleLab.font = [UIFont boldSystemFontOfSize:20];
    [self.view addSubview:_titleLab];
    
    UIButton *chooseDimmerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    chooseDimmerBtn.center = CGPointMake(WIDTH-40, 44);
    chooseDimmerBtn.bounds = CGRectMake(0, 0, 60, 33);
    [chooseDimmerBtn setBackgroundImage:[UIImage imageNamed:@"dim"] forState:UIControlStateNormal];
    [chooseDimmerBtn addTarget:self action:@selector(chooseDimmer) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:chooseDimmerBtn];
    
    _devicesLabel = [[UILabel alloc] init];
    _devicesLabel.frame = CGRectMake(0, 122, WIDTH, HEIGHT-257);
    _devicesLabel.numberOfLines = 0;
    _devicesLabel.textAlignment = NSTextAlignmentCenter;
    _devicesLabel.textColor = [UIColor whiteColor];
    _devicesLabel.font = [UIFont boldSystemFontOfSize:17];
    [self.view addSubview:_devicesLabel];
    
    
    // 这里用一个指针指向播放器单例,以后使用这个单例的地方,可以直接使用这个指针,而不用每次都打印那么多.
    self.playTool = [MusicPlayTools shareMusicPlay];
    [MusicPlayTools shareMusicPlay].delegate = self;
    
    // 为View设置代理
    self.rv.delegate = self;

}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)chooseDimmer {
    MusicDimmerChooseVC *md = [[MusicDimmerChooseVC alloc] init];
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromRight];
    [[[[UIApplication sharedApplication] keyWindow] layer] addAnimation:animation forKey:nil];
    UINavigationController *nav= [[UINavigationController alloc] initWithRootViewController:md];
    md.hande = ^(NSMutableArray *devicesArray) {
        [self.deviceIds removeAllObjects];
        NSString *string = @"Dimmer list:\n";
        for (CSRDeviceEntity *deviceEntity in devicesArray) {
            [self.deviceIds addObject:deviceEntity.deviceId];
            string = [string stringByAppendingString:[NSString stringWithFormat:@"%@\n",deviceEntity.name]];
        }
        self.rv.visualizer.deviceIds = self.deviceIds;
        _devicesLabel.text = string;
    };
    [self presentViewController:nav animated:NO completion:nil];
}

// 单例中,viewDidLoad只走一遍.切歌之类的操作需要多次进行,所以应该写在viewAppear中.
// 每次出现一次页面都会尝试重新播放.
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self p_play];
    if ([MusicPlayTools shareMusicPlay].audioPlayer.playing) {
        [_rv.playPauseButton setBackgroundImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }else
    {
        [_rv.playPauseButton setBackgroundImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    }
}

-(void)p_play
{
    // 判断当前播放器的model 和 点击cell的index对应的model,是不是同一个.
    // 如果是同一个,说明正在播放的和我们点击的是同一个, 这个时候不需要重新播放.直接返回就行了.
    if ([[MusicPlayTools shareMusicPlay].mediaItem isEqual:[[GetDataTools shareGetData] getModelWithIndex:self.index]]) {
        return;
    }
    
    [[MusicPlayTools shareMusicPlay] musicPause];
    
    MPMediaItem *mediaItem = [[GetDataTools shareGetData] getModelWithIndex:self.index];
    _titleLab.text = [mediaItem valueForProperty:MPMediaItemPropertyTitle];
    // 如果播放中和我们点击的不是同一个,那么替换当前播放器的model.
    // 然后重新准备播放.
    [MusicPlayTools shareMusicPlay].mediaItem = mediaItem;
    
    // 注意这里准备播放 不是播放!!!
    [[MusicPlayTools shareMusicPlay] preparePlay];
    
}

// 这个协议方法是播放器单例调起的.
// 作为协议方法,播放器单例将播放进度已参数的形式传出来.
-(void)getCurTiem:(NSString *)curTime Totle:(NSString *)totleTime Progress:(CGFloat)progress
{
    self.rv.curTimeLabel.text = curTime;
    self.rv.totleTiemLabel.text = totleTime;
    self.rv.progressSlider.value = progress;
}

//上一首
-(void)lastSongAction
{
    if (self.index > 0) {
        self.index --;
    }else{
        self.index = [GetDataTools shareGetData].dataArray.count - 1;
    }
    [self p_play];
}
//下一首
-(void)nextSongAction
{
    if (self.index == [GetDataTools shareGetData].dataArray.count -1) {
        self.index = 0;
    }else
    {
        self.index ++;
    }
    [self p_play];
}

-(void)endOfPlayAction
{
    [self nextSongAction];
}
// 滑动slider
-(void)progressAction:(float)value
{
    [[MusicPlayTools shareMusicPlay] seekToTimeWithValue:value];
}

// 暂停播放方法
-(void)playPauseAction
{
    // 根据AVPlayer的rate判断.
    if ([MusicPlayTools shareMusicPlay].audioPlayer.playing) {
        [[MusicPlayTools shareMusicPlay] musicPause];
        [_rv.playPauseButton setBackgroundImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    }else
    {
        [[MusicPlayTools shareMusicPlay] musicPlay];
        [_rv.playPauseButton setBackgroundImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }
}

-(NSMutableArray *)deviceIds {
    if (!_deviceIds) {
        _deviceIds = [[NSMutableArray alloc] init];
    }
    return _deviceIds;
}

@end
