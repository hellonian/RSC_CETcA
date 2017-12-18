//
//  MusicPlayViewController.h
//  MusicPlayerByAVPlayer
//
//  Created by AcTEC on 2017/11/30.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MusicPlayViewController : UIViewController

// 将播放界面控制器设置成单例的方法
@property(nonatomic,assign)NSInteger index;
+(instancetype)shareMusicPlay;

@end
