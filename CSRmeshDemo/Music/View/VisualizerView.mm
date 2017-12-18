//
//  VisualizerView.m
//  iPodVisualizer
//
//  Created by AcTEC on 2017/11/29.
//  Copyright © 2017年 Xinrong Guo. All rights reserved.
//

#import "VisualizerView.h"
#import <QuartzCore/QuartzCore.h>
#import "MeterTable.h"
#import "MusicPlayTools.h"
#import <CSRmesh/LightModelApi.h>

@implementation VisualizerView {
    CAEmitterLayer *emitterLayer;
    MeterTable meterTable;
}

// 1
+ (Class)layerClass {
    return [CAEmitterLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor blackColor]];
        emitterLayer = (CAEmitterLayer *)self.layer;
        
        // 2
//        CGFloat width = MAX(frame.size.width, frame.size.height);
//        CGFloat height = MIN(frame.size.width, frame.size.height);
        emitterLayer.emitterPosition = CGPointMake(WIDTH/2, HEIGHT/2);
        emitterLayer.emitterSize = CGSizeMake(WIDTH, HEIGHT);
        emitterLayer.emitterShape = kCAEmitterLayerRectangle;
        emitterLayer.renderMode = kCAEmitterLayerAdditive;
        
        // 3
        CAEmitterCell *cell = [CAEmitterCell emitterCell];
        cell.name = @"cell";
        CAEmitterCell *childCell = [CAEmitterCell emitterCell];
        childCell.name = @"childCell";
        childCell.lifetime = 1.0f / 60.0f;
        childCell.birthRate = 60.0f;
        childCell.velocity = 0.0f;
        
        childCell.contents = (id)[[UIImage imageNamed:@"particleTexture.png"] CGImage];
        
        cell.emitterCells = @[childCell];
        
        // 4
        cell.color = [[UIColor colorWithRed:1.0f green:0.53f blue:0.0f alpha:0.8f] CGColor];
        cell.redRange = 0.46f;
        cell.greenRange = 0.49f;
        cell.blueRange = 0.67f;
        cell.alphaRange = 0.55f;
        
        // 5
        cell.redSpeed = 0.11f;
        cell.greenSpeed = 0.07f;
        cell.blueSpeed = -0.25f;
        cell.alphaSpeed = 0.15f;
        
        // 6
        cell.scale = 0.5f;
        cell.scaleRange = 0.5f;
        
        // 7
        cell.lifetime = 1.0f;
        cell.lifetimeRange = .25f;
        cell.birthRate = 80;
        
        // 8
        cell.velocity = 100.0f;
        cell.velocityRange = 300.0f;
        cell.emissionRange = M_PI * 2;
        
        // 9
        emitterLayer.emitterCells = @[cell];
        
        CADisplayLink *dpLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        [dpLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)update
{
    AVAudioPlayer *audioPlayer = [MusicPlayTools shareMusicPlay].audioPlayer;
    // 1
    float scale = 0.5;
    float lightLevel = 255.0;
    if (audioPlayer.playing )
    {
        // 2
        [audioPlayer updateMeters];
        
        // 3
        float power = 0.0f;
        for (int i = 0; i < [audioPlayer numberOfChannels]; i++) {
            power += [audioPlayer averagePowerForChannel:i];
        }
        power /= [audioPlayer numberOfChannels];
        
        // 4
        float level = meterTable.ValueAt(power);
        scale = level * 5;
        lightLevel = 318.75*level - 63.75;
        if (lightLevel < 5) {
            lightLevel = 5;
        }

        for (NSNumber *deviceId in self.deviceIds) {
            [[LightModelApi sharedInstance] setLevel:deviceId level:@(lightLevel) success:nil failure:nil];
        }
    }
    
    // 5
    [emitterLayer setValue:@(scale) forKeyPath:@"emitterCells.cell.emitterCells.childCell.scale"];
    
    
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
