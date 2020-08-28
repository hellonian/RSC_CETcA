//
//  MCUUpdateTool.m
//  AcTECBLE
//
//  Created by AcTEC on 2019/4/25.
//  Copyright © 2019 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "MCUUpdateTool.h"
#import "AFHTTPSessionManager.h"
#import "DataModelManager.h"
#import "CSRUtilities.h"
#import "CSRDatabaseManager.h"

@interface MCUUpdateTool ()
{
    dispatch_semaphore_t _semaphore;
    NSMutableDictionary *_updateEveDataDic;
    NSMutableDictionary *_updateSuccessDic;
    BOOL _isLastPage;
    NSInteger _resendQueryNumber;
    NSInteger _pageNum;
    NSString *_downloadAddress;
    NSInteger _latestMCUSVersion;
    BOOL _startedUpdate;
    NSNumber *_deviceId;
    BOOL eb32Back;
    NSInteger resendea32Num;
    BOOL eb35Back;
    NSInteger resendea35Num;
}

@end

@implementation MCUUpdateTool

+ (instancetype)sharedInstace {
    static MCUUpdateTool *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[MCUUpdateTool alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MCUUpdateDataCall:) name:@"MCUUpdateDataCall" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedMCUVersionData:) name:@"receivedMCUVersionData" object:nil];
    }
    return self;
}

- (void)askUpdateMCU:(NSNumber *)deviceId downloadAddress:(NSString *)downloadAddress latestMCUSVersion:(NSInteger)latestMCUSVersion {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    _deviceId = deviceId;
    _downloadAddress = downloadAddress;
    _latestMCUSVersion = latestMCUSVersion;
    [self sendAskUpdateCmd];
}

- (void)sendAskUpdateCmd {
    [[DataModelManager shareInstance] sendCmdData:@"ea30" toDeviceId:_deviceId];
    __weak MCUUpdateTool *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!_startedUpdate) {
            [weakSelf sendAskUpdateCmd];
        }
    });
}


- (void)MCUUpdateDataCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *mucDeviceId = dic[@"deviceId"];
    NSString *mcuString = dic[@"MCUUpdateDataCall"];
    if ([mucDeviceId isEqualToNumber:_deviceId]) {
        if ([mcuString hasPrefix:@"30"]) {
            if ([[mcuString substringWithRange:NSMakeRange(2, 2)] boolValue]) {
                _startedUpdate = YES;
                
                if (self.toolDelegate && [self.toolDelegate respondsToSelector:@selector(starteUpdateHud)]) {
                    [self.toolDelegate starteUpdateHud];
                }
                
                [self downloadPin];
            }
        }else if ([mcuString hasPrefix:@"33"]) {
            NSInteger backBinPage = [CSRUtilities numberWithHexString:[mcuString substringWithRange:NSMakeRange(2, 2)]];
            
            if ([[_updateSuccessDic allKeys] containsObject:@(backBinPage)] && ![[_updateSuccessDic objectForKey:@(backBinPage)] boolValue]) {
                NSInteger count = [[_updateEveDataDic objectForKey:@(backBinPage)] count];
                NSString *countBinString = @"";
                for (int i=0; i<count; i++) {
                    countBinString = [NSString stringWithFormat:@"%@1",countBinString];
                }
                
                NSString *str0 = [mcuString substringWithRange:NSMakeRange(4, 2)];
                NSString *str1 = [mcuString substringWithRange:NSMakeRange(6, 2)];
                NSString *str2 = [mcuString substringWithRange:NSMakeRange(8, 2)];
                NSString *resultHexStr = [NSString stringWithFormat:@"%@%@%@",str2,str1,str0];
                NSString *resultBinStr = [[CSRUtilities getBinaryByhex:resultHexStr] substringWithRange:NSMakeRange(24-count, count)];
                
                NSLog(@"%@  %@  %@",mcuString,resultHexStr,resultBinStr);
                if ([countBinString isEqualToString:resultBinStr]) {
                    
                    dispatch_semaphore_signal(_semaphore);
                    
                    [_updateSuccessDic setObject:@(![[_updateSuccessDic objectForKey:@(backBinPage)] boolValue]) forKey:@(backBinPage)];
                    if (_isLastPage) {
                        NSLog(@"最后一页成功");
                        eb32Back = NO;
                        resendea32Num = 0;
                        [[DataModelManager shareInstance] sendCmdData:@"ea32" toDeviceId:_deviceId];
                        [self resendea32];
                    }
                    if (self.toolDelegate && [self.toolDelegate respondsToSelector:@selector(updateHudProgress:)]) {
                        [self.toolDelegate updateHudProgress:(backBinPage+1)/(CGFloat)_pageNum];
                    }
                }else {
                    
                    for (NSInteger i=0; i<[resultBinStr length]; i++) {
                        NSString *resultStr = [resultBinStr substringWithRange:NSMakeRange([resultBinStr length]-1-i, 1)];
                        NSLog(@"%@",resultStr);
                        if (![resultStr boolValue]) {
                            NSString *binResendString = [[_updateEveDataDic objectForKey:@(backBinPage)] objectAtIndex:i];
                            [[DataModelManager shareInstance] sendCmdData:binResendString toDeviceId:_deviceId];
                            [NSThread sleepForTimeInterval:0.02];
                        }
                    }
                    
                }
            }
        }else if ([mcuString hasPrefix:@"32"]) {
            
            eb32Back = YES;
            
            eb35Back = NO;
            resendea35Num = 0;
            [self sendReadMCUVersionCmd];

            [UIApplication sharedApplication].idleTimerDisabled = NO;
            _startedUpdate = NO;
//            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
//            deviceEntity.mcuSVersion = [NSNumber numberWithInteger:_latestMCUSVersion];
//            [[CSRDatabaseManager sharedInstance] saveContext];
        }
    }
}

- (void)resendea32 {
    if (!eb32Back) {
        if (resendea32Num<3) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                resendea32Num++;
                [[DataModelManager shareInstance] sendCmdData:@"ea32" toDeviceId:_deviceId];
                [self resendea32];
            });
        }else {
            eb35Back = NO;
            resendea35Num = 0;
            [self sendReadMCUVersionCmd];
        }
    }
}

- (void)sendReadMCUVersionCmd {
    if (!eb35Back) {
        if (resendea35Num<3) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                resendea35Num++;
                [[DataModelManager shareInstance] sendCmdData:@"ea35" toDeviceId:_deviceId];
                [self sendReadMCUVersionCmd];
            });
        }else {
            if (self.toolDelegate && [self.toolDelegate respondsToSelector:@selector(updateSuccess:)]) {
                [self.toolDelegate updateSuccess:NO];
            }
        }
    }
    
}

- (void)receivedMCUVersionData:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *sourceDeviceId = dic[@"deviceId"];
    BOOL higher = [dic[@"higher"] boolValue];
    if ([sourceDeviceId isEqualToNumber:_deviceId]) {
        eb35Back = YES;
        if (self.toolDelegate && [self.toolDelegate respondsToSelector:@selector(updateSuccess:)]) {
            [self.toolDelegate updateSuccess:higher];
        }
    }
}

- (void)downloadPin {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:_downloadAddress]];
    NSString *fileName = [_downloadAddress lastPathComponent];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = nil;
    manager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    NSProgress *progress = nil;
    __block MCUUpdateTool *weakSelf = self;
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:&progress destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@",fileName]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path]) {
            [fileManager removeItemAtPath:path error:nil];
        }
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        [weakSelf startMCUUpdate:filePath];
        
    }];
    [task resume];
}


- (void)startMCUUpdate:(NSURL *)path {
    NSData *data = [[NSData alloc] initWithContentsOfURL:path];
    NSLog(@"data length>> %lu",(unsigned long)[data length]);
    _semaphore = dispatch_semaphore_create(1);
    _updateEveDataDic = [[NSMutableDictionary alloc] init];
    _updateSuccessDic = [[NSMutableDictionary alloc] init];
    _isLastPage = NO;
    if (data) {
        _pageNum = [data length]/128+1;
        dispatch_queue_t queue = dispatch_queue_create("串行", NULL);
        for (NSInteger binPage=0; binPage<([data length]/128+1); binPage++) {
            dispatch_async(queue, ^{
                dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_updateSuccessDic setObject:@(0) forKey:@(binPage)];
                    NSLog(@"xunfan %ld",(long)binPage);
                    NSInteger binPageLength = 128;
                    if (binPage == [data length]/128) {
                        binPageLength = [data length]%128;
                        _isLastPage = YES;
                    }
                    NSData *binPageData = [data subdataWithRange:NSMakeRange(binPage*128, binPageLength)];
                    NSMutableArray *eveDataArray = [[NSMutableArray alloc] init];
                    for (NSInteger binRow=0; binRow<([binPageData length]/6+1); binRow++) {
                        NSInteger binRowLenth = 6;
                        if (binRow == [binPageData length]/6) {
                            binRowLenth = [binPageData length]%6;
                        }
                        NSData *binRowData = [binPageData subdataWithRange:NSMakeRange(binRow*6, binRowLenth)];
                        NSString *binSendString = [NSString stringWithFormat:@"ea31%@%@%@",[CSRUtilities stringWithHexNumber:binPage],[CSRUtilities stringWithHexNumber:binRow],[CSRUtilities hexStringForData:binRowData]];
                        [eveDataArray insertObject:binSendString atIndex:binRow];
                        [[DataModelManager shareInstance] sendCmdData:binSendString toDeviceId:_deviceId];
                        [NSThread sleepForTimeInterval:0.02];
                    }
                    [_updateEveDataDic setObject:eveDataArray forKey:@(binPage)];
                    
                    _resendQueryNumber = 0;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        NSLog(@"首次查询~~ %ld | %d",(long)binPage,[[_updateSuccessDic objectForKey:@(binPage)] boolValue]);
                        if (![[_updateSuccessDic objectForKey:@(binPage)] boolValue] && _resendQueryNumber<6) {
                            _resendQueryNumber++;
                            [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"ea33%@",[CSRUtilities stringWithHexNumber:binPage]] toDeviceId:_deviceId];
                            [self resendData:binPage];
                        }
                    });
                });
            });
        }
        NSLog(@"循环结束");
    }
}

- (void)resendData:(NSInteger)binPage {
    if (_resendQueryNumber < 6) {
        __block typeof(self)weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (![[_updateSuccessDic objectForKey:@(binPage)] boolValue]) {
                [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"ea33%@",[CSRUtilities stringWithHexNumber:binPage]] toDeviceId:_deviceId];
                _resendQueryNumber++;
                [weakSelf resendData:binPage];
            }
        });
    }else {
        if (self.toolDelegate && [self.toolDelegate respondsToSelector:@selector(updateSuccess:)]) {
            [self.toolDelegate updateSuccess:NO];
        }
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        _startedUpdate = NO;
    }
}

@end
