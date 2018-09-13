//
//  GetDataTools.h
//  MusicPlayerByAVPlayer
//
//  Created by AcTEC on 2017/11/30.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

// 定义block
typedef void (^PassValue)(NSArray * array);

@interface GetDataTools : NSObject

// 作为单例的属性,这个数组可以在任何位置,任何时间被访问.
@property(nonatomic,strong)NSArray * dataArray;

// 单例方法
+(instancetype)shareGetData;

// 根据传入的URL,通过Block返回一个数组.
-(void)getDataAndPassValue:(PassValue)passValue;

// 根据传入的Index,返回一个"歌曲信息的模型",这个模型来自上面的属性数组.
-(MPMediaItem *)getModelWithIndex:(NSInteger)index;

@end
