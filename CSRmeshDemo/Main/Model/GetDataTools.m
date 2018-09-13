//
//  GetDataTools.m
//  MusicPlayerByAVPlayer
//
//  Created by AcTEC on 2017/11/30.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import "GetDataTools.h"

static GetDataTools * gd = nil;

@interface GetDataTools ()
{
    NSTimer *_timer;
    dispatch_semaphore_t _semaphore;
    MPMediaQuery *_musicQuery;
}
@end

@implementation GetDataTools

// 单例方法, 这个单例方法是不完全的, 如果C层开发者使用了[alloc init]的方式创建对象, 仍不为单例, 正确的封闭其他所有init方法, 或者重写调用我们当前的方法返回对象.
+(instancetype)shareGetData
{
    if (gd == nil) {
        static dispatch_once_t once_token;
        dispatch_once(&once_token, ^{
            gd = [[GetDataTools alloc] init];
        });
    }
    return gd;
}

- (void)getDataAndPassValue:(PassValue)passValue {
    
    _musicQuery = [[MPMediaQuery alloc] init];
    //创建初始信号量为0
    _semaphore = dispatch_semaphore_create(0);
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_3
    if ([MPMediaLibrary authorizationStatus] == MPMediaLibraryAuthorizationStatusAuthorized) {
        //信号量加1
        dispatch_semaphore_signal(_semaphore);
    }else {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(selectorobserveAuthrizationStatusChange) userInfo:nil repeats:YES];
    }
    
    //创建串行队列
    dispatch_queue_t queue = dispatch_queue_create("串行", NULL);
    dispatch_async(queue, ^{
        
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        self.dataArray = [_musicQuery items];
        // !!!Block回传值
        passValue(self.dataArray);
    });
    
#endif
}

-(void)selectorobserveAuthrizationStatusChange {
    if ([MPMediaLibrary authorizationStatus] == MPMediaLibraryAuthorizationStatusAuthorized) {
        [_timer invalidate];
        _timer = nil;
        //不延时获取到的[_musicQuery items]个数为0；
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //重新获取媒体列表
            _musicQuery = [[MPMediaQuery alloc] init];
            //信号量加1
            dispatch_semaphore_signal(_semaphore);
        });
        
    }
}

// 根据传入的index返回一个"歌曲信息模型"
-(MPMediaItem *)getModelWithIndex:(NSInteger)index
{
    return self.dataArray[index];
}

@end
