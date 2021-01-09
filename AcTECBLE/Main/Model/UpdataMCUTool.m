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
    }
    return self;
}

- (void)askUpdateMCU:(NSNumber *)deviceId downloadAddress:(NSString *)downloadAddress latestMCUSVersion:(NSInteger)latestMCUSVersion {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    _deviceID = deviceId;
    _downloadAddress = downloadAddress;
    _latestMCUVersion = latestMCUSVersion;
    [self sendPageLengthCmd];
}

- (void)sendPageLengthCmd {
    _sendCount = 0;
    [self performSelector:@selector(pageLengthCmdTimeOutMethod) withObject:nil afterDelay:3.0];
    Byte byte[] = {0xea, 0x36, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
}

- (void)pageLengthCmdTimeOutMethod {
    if (_sendCount < 3) {
        [self performSelector:@selector(pageLengthCmdTimeOutMethod) withObject:nil afterDelay:3.0];
        Byte byte[] = {0xea, 0x36, 0x00};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
        _sendCount ++;
    }else {
        _pageLength = 128;
        [self sendAskUpdateCmd];
    }
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
        [self toolDelegateUpdateConclusion:AcTECLocalizedStringFromTable(@"mcu_not_respond_request", @"Localizable")];
    }
}

- (void)MCUUpdateDataCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *mucDeviceId = dic[@"deviceId"];
    NSData *data = dic[@"MCUUpdateDataCall"];
    
    if ([mucDeviceId isEqualToNumber:_deviceID]) {
        
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
                NSInteger lValue = byte[3] + byte[4] * 256 + byte[5] * 256 * 256 + byte[6] * 256 * 256 * 256;
                NSInteger hValue =  byte[7] + byte[8] * 256 + byte[9] * 256 * 256;
                [self checkPage:lValue :hValue];
            }
        }else if (byte[1] == 0x32) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(endOperationTimeOutMethod) object:nil];
            if (byte[2] == 0x01) {
                //升级成功
                [self toolDelegateUpdateConclusion:AcTECLocalizedStringFromTable(@"mcu_update_success", @"Localizable")];
            }else {
                //升级失败
                [self toolDelegateUpdateConclusion:AcTECLocalizedStringFromTable(@"mcu_update_failed", @"Localizable")];
            }
            _sendCount = 0;
            [self performSelector:@selector(readVersionTimeOutMethod) withObject:nil afterDelay:3.0];
            Byte byte[] = {0xea, 0x35};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
        }else if (byte[1] == 0x36) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pageLengthCmdTimeOutMethod) object:nil];
            _pageLength = byte[2]*256+byte[3];
            [self sendAskUpdateCmd];
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
        _pageCount = [data length] / _pageLength + 1;
        if (_pageCount > 256) {
            //提示升级失败——包长度超出
            [self toolDelegateUpdateConclusion:AcTECLocalizedStringFromTable(@"mcu_length_exceeded", @"Localizable")];
            return;
        }
        _currentPage = 0;
        [self nextPageOperation];
    }
}

- (void)nextPageOperation {
    
    _retryCount = 0;
    NSInteger rest = [_binData length] - _pageLength * _currentPage;
    NSInteger cpLenth = _pageLength;
    if (rest <= _pageLength) {
        cpLenth = rest;
    }
    NSData *pageData = [_binData subdataWithRange:NSMakeRange(_pageLength * _currentPage, cpLenth)];
    
    NSInteger n = cpLenth%6 != 0 ? cpLenth/6 : cpLenth/6-1;
    for (int i = 0; i <= n; i ++) {
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
    _sendCount = 0;
    [self performSelector:@selector(nextPageOperationTimeOutMethod) withObject:nil afterDelay:2.0];
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
        [self toolDelegateUpdateConclusion:AcTECLocalizedStringFromTable(@"mcu_not_respond_query", @"Localizable")];
    }
}

- (void)checkPage:(NSInteger)lValue :(NSInteger)hValue{
    
    NSInteger rest = [_binData length] - _pageLength * _currentPage;
    NSInteger cpLenth = _pageLength;
    if (rest <= _pageLength) {
        cpLenth = rest;
    }
    NSData *pageData = [_binData subdataWithRange:NSMakeRange(_pageLength * _currentPage, cpLenth)];
    
    BOOL exit = NO;
    
    if (cpLenth <= 192) {
        NSInteger n = cpLenth%6 != 0 ? cpLenth/6 : cpLenth/6-1;
        for (int i=0; i<=n; i++) {
            if (!(lValue & (NSInteger)pow(2, i)) >> i) {
                exit = YES;
                break;
            }
        }
    }else {
        for (int i=0; i<32; i++) {
            if (!(lValue & (NSInteger)pow(2, i)) >> i) {
                exit = YES;
                break;
            }
        }
        if (!exit) {
            NSInteger n = cpLenth%6 != 0 ? cpLenth/6-32 : cpLenth/6-32-1;
            for (int i=0; i<=n; i++) {
                if (!(hValue & (NSInteger)pow(2, i)) >> i) {
                    exit = YES;
                    break;
                }
            }
        }
    }
    
    if (exit) {
        //页内有重发
        if (_retryCount < 20) {
            
            if (cpLenth <= 192) {
                NSInteger n = cpLenth%6 != 0 ? cpLenth/6 : cpLenth/6-1;
                for (int i=0; i<=n; i++) {
                    if (!(lValue & (NSInteger)pow(2, i)) >> i) {
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
            }else {
                for (int i=0; i<32; i++) {
                    if (!(lValue & (NSInteger)pow(2, i)) >> i) {
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
                NSInteger n = cpLenth%6 != 0 ? cpLenth/6-32 : cpLenth/6-32-1;
                for (int i=0; i<=n; i++) {
                    if (!(hValue & (NSInteger)pow(2, i)) >> i) {
                        NSInteger bagRest = [pageData length] - 6 * (i+32);
                        NSInteger cbLenth = 6;
                        if (bagRest <= 6) {
                            cbLenth = bagRest;
                        }
                        NSData *bagData = [pageData subdataWithRange:NSMakeRange(6 * (i+32), cbLenth)];
                        Byte byte[] = {0xea, 0x31, _currentPage, (i+32)};
                        NSData *head = [[NSData alloc] initWithBytes:byte length:4];
                        NSMutableData *bagCmd = [[NSMutableData alloc] initWithData:head];
                        [bagCmd appendData:bagData];
                        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:bagCmd];
                        
                        [NSThread sleepForTimeInterval:0.05];
                    }
                }
            }
            
            _sendCount = 0;
            [self performSelector:@selector(nextPageOperationTimeOutMethod) withObject:nil afterDelay:2.0];
            _retryCount ++;
        }else {
            //提示升级失败——单页重发次数已达20次
            [self toolDelegateUpdateConclusion:AcTECLocalizedStringFromTable(@"mcu_resends_fail", @"Localizable")];
        }
    }else {
        //下一页
        if (_currentPage == _pageCount-1) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedMCUVersionData:) name:@"receivedMCUVersionData" object:nil];
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
        [self toolDelegateUpdateConclusion:AcTECLocalizedStringFromTable(@"mcu_end_fail", @"Localizable")];
        _sendCount = 0;
        [self performSelector:@selector(readVersionTimeOutMethod) withObject:nil afterDelay:3.0];
        Byte byte[] = {0xea, 0x35};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
    }
}

- (void)readVersionTimeOutMethod {
    if (_sendCount < 3) {
        _sendCount ++;
        [self performSelector:@selector(readVersionTimeOutMethod) withObject:nil afterDelay:3.0];
        Byte byte[] = {0xea, 0x35};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:2];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceID data:cmd];
    }else {
        //读取版本超时
        [self toolDelegateUpdateConclusion:AcTECLocalizedStringFromTable(@"mcu_read_version_fail", @"Localizable")];
    }
}

- (void)receivedMCUVersionData:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *sourceDeviceId = dic[@"deviceId"];
    BOOL higher = [dic[@"higher"] boolValue];
    if ([sourceDeviceId isEqualToNumber:_deviceID]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"receivedMCUVersionData" object:nil];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readVersionTimeOutMethod) object:nil];
        if (higher) {
            //版本更新
            [self toolDelegateUpdateConclusion:AcTECLocalizedStringFromTable(@"mcu_update_success", @"Localizable")];
        }else {
            //版本一样或更旧
            [self toolDelegateUpdateConclusion:AcTECLocalizedStringFromTable(@"mcu_version_less", @"Localizable")];
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
