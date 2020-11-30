//
//  UpdataMCUTool.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/11/20.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "UpdataMCUTool.h"
#import "DataModelManager.h"
#import "AFHTTPSessionManager.h"
#import "CSRUtilities.h"

@implementation UpdataMCUTool

+ (instancetype)sharedInstace {
    static UpdataMCUTool *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[UpdataMCUTool alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MCUUpdateDataCall:) name:@"MCUUpdateDataCall" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedMCUVersionData:) name:@"receivedMCUVersionData" object:nil];
    }
    return self;
}

- (void)askUpdateMCU:(NSNumber *)deviceId downloadAddress:(NSString *)downloadAddress latestMCUSVersion:(NSInteger)latestMCUSVersion {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    _deviceID = deviceId;
    _downloadAddress = downloadAddress;
    _latestMCUVersion = latestMCUSVersion;
    [self sendAskUpdateCmd];
}

- (void)sendAskUpdateCmd {
    _sendCount = 0;
    [self performSelector:@selector(askUpdateCmdTimeOutMethod) withObject:nil afterDelay:3.0];
    Byte byte[] = {0xea, 0x30};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
}

- (void)askUpdateCmdTimeOutMethod {
    if (_sendCount < 3) {
        [self performSelector:@selector(askUpdateCmdTimeOutMethod) withObject:nil afterDelay:3.0];
        Byte byte[] = {0xea, 0x30};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
        _sendCount ++;
    }else {
        //提示升级失败——无法进入升级
        [self toolDelegateUpdateConclusion:@"设备未响应升级开始命令"];
    }
}

- (void)MCUUpdateDataCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *mucDeviceId = dic[@"deviceId"];
    if ([mucDeviceId isEqualToNumber:_deviceID]) {
        NSData *data = dic[@"MCUUpdateDataCall"];
        Byte *byte = (Byte *)[data bytes];
        if (byte[1] == 0x30) {
            if (byte[2] == 0x01) {
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(askUpdateCmdTimeOutMethod) object:nil];
                if (self.toolDelegate && [self.toolDelegate respondsToSelector:@selector(starteUpdateHud)]) {
                    [self.toolDelegate starteUpdateHud];
                }
                [self downloadPin];
            }
        }else if (byte[1] == 0x33) {
            if (byte[2] == _currentPage) {
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(nextPageOperationTimeOutMethod) object:nil];
                NSInteger value = byte[3] + byte[4] * 256 + byte[5] * 256 * 256;
                [self checkPage:value];
            }
        }else if (byte[1] == 0x32) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(endOperationTimeOutMethod) object:nil];
            if (byte[2] == 0x01) {
                //升级成功
                [self toolDelegateUpdateConclusion:@"升级成功"];
            }else {
                //升级失败
                [self toolDelegateUpdateConclusion:@"升级失败"];
            }
            _sendCount = 0;
            [self performSelector:@selector(readVersionTimeOutMethod) withObject:nil afterDelay:3.0];
            Byte byte[] = {0xea, 0x35};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
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
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:&progress destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@",fileName]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path]) {
            [fileManager removeItemAtPath:path error:nil];
        }
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        [self startMCUUpdate:filePath];
        
    }];
    [task resume];
}

- (void)startMCUUpdate:(NSURL *)path {
    NSData *data = [[NSData alloc] initWithContentsOfURL:path];
    if (data) {
        NSLog(@">>>>> %ld", [data length]);
        _binData = data;
        _pageCount = [data length] / 128 + 1;
        if (_pageCount > 256) {
            //提示升级失败——包长度超出
            [self toolDelegateUpdateConclusion:@"下载的升级包长度超出"];
            return;
        }
        _currentPage = 0;
        [self nextPageOperation];
    }
}

- (void)nextPageOperation {
    _sendCount = 0;
    [self performSelector:@selector(nextPageOperationTimeOutMethod) withObject:nil afterDelay:2.0];
    _retryCount = 0;
    NSInteger rest = [_binData length] - 128 * _currentPage;
    NSInteger cpLenth = 128;
    if (rest <= 128) {
        cpLenth = rest;
    }
    NSData *pageData = [_binData subdataWithRange:NSMakeRange(128 * _currentPage, cpLenth)];
    
    for (int i = 0; i <= [pageData length] / 6; i ++) {
        NSInteger bagRest = [pageData length] - 6 * i;
        NSInteger cbLenth = 6;
        if (bagRest <= 6) {
            cbLenth = bagRest;
        }
        NSData *bagData = [pageData subdataWithRange:NSMakeRange(6 * i, cbLenth)];
        Byte byte[] = {0xea, 0x31, _currentPage, i};
        NSData *head = [[NSData alloc] initWithBytes:byte length:4];
        NSMutableData *bagCmd = [[NSMutableData alloc] initWithData:head];
        [bagCmd appendData:bagData];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:bagCmd];
        
        [NSThread sleepForTimeInterval:0.05];
    }
}

- (void)nextPageOperationTimeOutMethod {
    if (_sendCount < 3) {
        [self performSelector:@selector(nextPageOperationTimeOutMethod) withObject:nil afterDelay:3.0];
        Byte byte[] = {0xea, 0x33, _currentPage};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
        _sendCount ++;
    }else {
        //提示升级失败——无法查询当前页结果
        [self toolDelegateUpdateConclusion:@"设备未响应查询当前页是否成功的命令"];
    }
}

- (void)checkPage:(NSInteger)value {
    NSInteger rest = [_binData length] - 128 * _currentPage;
    NSInteger cpLenth = 128;
    if (rest <= 128) {
        cpLenth = rest;
    }
    NSData *pageData = [_binData subdataWithRange:NSMakeRange(128 * _currentPage, cpLenth)];
    
    BOOL exit = NO;
    for (int i = 0; i <= [pageData length] / 6; i ++) {
        if (!((value & (NSInteger)pow(2, i)) >> i)) {
            exit = YES;
            break;
        }
    }
    if (exit) {
        //页内有重发
        if (_retryCount < 20) {
            _sendCount = 0;
            [self performSelector:@selector(nextPageOperationTimeOutMethod) withObject:nil afterDelay:2.0];
            
            for (int i = 0; i <= [pageData length] / 6; i ++) {
                if (!((value & (NSInteger)pow(2, i)) >> i)) {
                    NSInteger bagRest = [pageData length] - 6 * i;
                    NSInteger cbLenth = 6;
                    if (bagRest <= 6) {
                        cbLenth = bagRest;
                    }
                    NSData *bagData = [pageData subdataWithRange:NSMakeRange(6 * i, cbLenth)];
                    Byte byte[] = {0xea, 0x31, _currentPage, i};
                    NSData *head = [[NSData alloc] initWithBytes:byte length:4];
                    NSMutableData *bagCmd = [[NSMutableData alloc] initWithData:head];
                    [bagCmd appendData:bagData];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:bagCmd];
                    
                    [NSThread sleepForTimeInterval:0.05];
                }
            }
            
            _retryCount ++;
        }else {
            //提示升级失败——单页重发次数已达20次
            [self toolDelegateUpdateConclusion:@"当前页重复次数已达20次仍然未成功"];
        }
    }else {
        //下一页
        if (_currentPage == _pageCount-1) {
            //数据发送完毕
            _sendCount = 0;
            [self performSelector:@selector(endOperationTimeOutMethod) withObject:nil afterDelay:3.0];
            Byte byte[] = {0xea, 0x32};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
        }else {
            if (self.toolDelegate && [self.toolDelegate respondsToSelector:@selector(updateHudProgress:)]) {
                [self.toolDelegate updateHudProgress:(_currentPage+1)/(CGFloat)_pageCount];
            }
            _currentPage ++;
            [self nextPageOperation];
        }
    }
    
}

- (void)endOperationTimeOutMethod {
    if (_sendCount < 3) {
        [self performSelector:@selector(endOperationTimeOutMethod) withObject:nil afterDelay:3.0];
        Byte byte[] = {0xea, 0x32};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
        _sendCount ++;
    }else {
        //提示升级失败——最后发送结束命令未得到设备相应
        [self toolDelegateUpdateConclusion:@"设备未响应退出升级的命令"];
        _sendCount = 0;
        [self performSelector:@selector(readVersionTimeOutMethod) withObject:nil afterDelay:3.0];
        Byte byte[] = {0xea, 0x35};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
    }
}

- (void)readVersionTimeOutMethod {
    if (_sendCount < 3) {
        [self performSelector:@selector(readVersionTimeOutMethod) withObject:nil afterDelay:3.0];
        Byte byte[] = {0xea, 0x35};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
    }else {
        //读取版本超时
        [self toolDelegateUpdateConclusion:@"设备未响应读取版本的命令"];
    }
}

- (void)receivedMCUVersionData:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *sourceDeviceId = dic[@"deviceId"];
    BOOL higher = [dic[@"higher"] boolValue];
    if ([sourceDeviceId isEqualToNumber:_deviceID]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readVersionTimeOutMethod) object:nil];
        if (higher) {
            //版本更新
            [self toolDelegateUpdateConclusion:@"MCU版本号已更新"];
        }else {
            //版本一样或更旧
            [self toolDelegateUpdateConclusion:@"MCU版本号小于或等于升级之前"];
        }
    }
}

- (void)toolDelegateUpdateConclusion:(NSString *)conclusion {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    if (self.toolDelegate && [self.toolDelegate respondsToSelector:@selector(updateSuccess:)]) {
        [self.toolDelegate updateSuccess:conclusion];
    }
}

@end
