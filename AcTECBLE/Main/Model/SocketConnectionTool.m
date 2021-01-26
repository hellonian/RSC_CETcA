//
//  SocketConnectionTool.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/10/23.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "SocketConnectionTool.h"
#import "CSRUtilities.h"
#import "CSRDatabaseManager.h"
#import "DeviceModelManager.h"

@implementation SocketConnectionTool

- (void)connentHost:(NSString *)host prot:(uint16_t)port {
    if (host==nil || host.length <= 0) {
        NSAssert(host != nil, @"host must be not nil");
    }
    
    if (self.tcpSocketManager == nil) {
        self.tcpSocketManager = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    BOOL isConnected = [self.tcpSocketManager isConnected];
    NSLog(@"isConnected: %d",isConnected);
    if (!isConnected) {
        _hasConnected = NO;
        _sHost = host;
        _sPort = port;
        NSError *connectError = nil;
        [self.tcpSocketManager connectToHost:host onPort:port withTimeout:5 error:&connectError];
    }else {
        _hasConnected = YES;
        [self getDeviceList];
        
        [self.tcpSocketManager readDataWithTimeout:-1 tag:0];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    if (!_hasConnected) {
        _hasConnected = YES;
        NSInteger frameNumber = 0;
        Byte b[] = {0xa5, frameNumber, 0x0e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00};
        NSData *d = [[NSData alloc] initWithBytes:b length:12];
        int sum = [CSRUtilities atFromData:d];
        Byte byte[] = {0xa5, frameNumber, 0x0e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, sum, 0xfe};
        NSData *data = [[NSData alloc] initWithBytes:byte length:14];
        [self writeData:data];
    }
    [self.tcpSocketManager readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if (!_hasConnected) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(socketConnectFail:)]) {
            [self.delegate socketConnectFail:_deviceID];
        }
    }else {
        NSError *connectError = nil;
        [self.tcpSocketManager connectToHost:_sHost onPort:_sPort withTimeout:5 error:&connectError];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"readData长度： %ld", [data length]);
    NSInteger n = [data length]/24+1;
    if ([data length]%24 == 0 && n > 1) {
        n = n-1;
    }
    for (int i = 0; i<[data length]/24; i++) {
        NSInteger l = [data length] - 24*i;
        l = l > 24 ? 24 : l;
        NSLog(@"readData: %@",[data subdataWithRange:NSMakeRange(24*i, l)]);
    }
    Byte headByte[1];
    [data getBytes:headByte range:NSMakeRange(0, 1)];
    if (headByte[0] == 0xa5) {
        Byte cmdByte[2];
        [data getBytes:cmdByte range:NSMakeRange(10, 2)];
        if ((cmdByte[0] == 0x01 && cmdByte[1] == 0x80)
            || (cmdByte[0] == 0x01 && cmdByte[1] == 0x90)
            || (cmdByte[0] == 0x02 && cmdByte[1] == 0x90)
            || (cmdByte[0] == 0x03 && cmdByte[1] == 0x10)
            || (cmdByte[0] == 0x03 && cmdByte[1] == 0x80)) {
            Byte frameNumberByte[1];
            [data getBytes:frameNumberByte range:NSMakeRange(1, 1)];
            if (frameNumberByte[0] == self.frameNumber) {
                self.receiveData = [[NSMutableData alloc] initWithData:data];
            }else {
                [self.receiveData appendData:data];
            }
        }else if (cmdByte[0] == 0x04 && cmdByte[1] == 0x00) {
            self.receiveData = [[NSMutableData alloc] initWithData:data];
        }else {
            [self.receiveData appendData:data];
        }
    }else {
        [self.receiveData appendData:data];
    }
    
    Byte endByte[1];
    [self.receiveData getBytes:endByte range:NSMakeRange([self.receiveData length]-1, 1)];
    if (endByte[0] == 0xfe) {
        Byte checkByte[1];
        [self.receiveData getBytes:checkByte range:NSMakeRange([self.receiveData length]-2, 1)];
        int check = [CSRUtilities atFromData:[self.receiveData subdataWithRange:NSMakeRange(0, [self.receiveData length]-2)]];
        if (checkByte[0] == check) {
            NSLog(@"%@",[[NSString alloc] initWithData:[self.receiveData subdataWithRange:NSMakeRange(12, [self.receiveData length] - 14)] encoding:NSUTF8StringEncoding]);
            
            Byte cmdByte[2];
            [self.receiveData getBytes:cmdByte range:NSMakeRange(10, 2)];
            
            if (cmdByte[0] == 0x01 && cmdByte[1] == 0x80) {
                Byte sourceByte[2];
                [self.receiveData getBytes:sourceByte range:NSMakeRange(8, 2)];
                self.sourceAddress = sourceByte[0] + sourceByte[1]*256;
                [self getDeviceList];
                
            }else if (cmdByte[0] == 0x01 && cmdByte[1] == 0x90) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(enableMCUUpdateBtn)]) {
                    [self.delegate enableMCUUpdateBtn];
                }
                NSString *json = [[NSString alloc] initWithData:[self.receiveData subdataWithRange:NSMakeRange(12, [self.receiveData length] - 14)] encoding:NSUTF8StringEncoding];
                NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:json];
                if ([jsonDictionary count] > 0) {
                    BOOL success = [jsonDictionary[@"success"] boolValue];
                    if (success) {
                        NSInteger version = [jsonDictionary[@"version"] integerValue];
                        NSArray *devices = jsonDictionary[@"device"];
                        if ([devices count] > 0) {
                            [[CSRDatabaseManager sharedInstance] cleanSonos:_deviceID];
                            for (NSDictionary *device in devices) {
                                NSInteger channel = [device[@"channel"] integerValue];
                                NSInteger model = [device[@"model"] integerValue];
                                NSInteger type = model >> 7;
                                NSInteger number = model & 0x7F;
                                NSString *room = device[@"room"];
                                DeviceModel *m = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceID];
                                BOOL alive = NO;
                                if (m.mcLiveChannels & (1 << channel)) {
                                    alive = YES;
                                }
                                [[CSRDatabaseManager sharedInstance] saveNewSonos:_deviceID channel:@(channel) infoVersion:@(version) modelType:@(type) modelNumber:@(number) name:room alive:@(alive)];
                            }
                            if (self.delegate && [self.delegate respondsToSelector:@selector(saveSonosInfo:)]) {
                                [self.delegate saveSonosInfo:_deviceID];
                            }
                            
                            Byte sByte[2];
                            sByte[0] = (self.sourceAddress & 0xFF00) >> 8;
                            sByte[1] = self.sourceAddress & 0x00FF;
                            NSInteger frameNumber = [self getFrameNumber];
                            Byte b[] = {0xa5, frameNumber, 0x0e, 0x00, 0x00, 0x00, sByte[1], sByte[0], 0x01, 0x00, 0x02, 0x10};
                            NSData *d = [[NSData alloc] initWithBytes:b length:12];
                            int sum = [CSRUtilities atFromData:d];
                            Byte byte[] = {0xa5, frameNumber, 0x0e, 0x00, 0x00, 0x00, sByte[1], sByte[0], 0x01, 0x00, 0x02, 0x10, sum, 0xfe};
                            NSData *data = [[NSData alloc] initWithBytes:byte length:14];
                            [self writeData:data];
                            
                        }
                    }
                }
            }else if (cmdByte[0] == 0x02 && cmdByte[1] == 0x90) {
                NSString *json = [[NSString alloc] initWithData:[self.receiveData subdataWithRange:NSMakeRange(12, [self.receiveData length] - 14)] encoding:NSUTF8StringEncoding];
                
                NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:json];
                if ([jsonDictionary count] > 0) {
                    BOOL success = [jsonDictionary[@"success"] boolValue];
                    if (success) {
                        [[DeviceModelManager sharedInstance] refreshSongList:_deviceID songs:json];
                    }
                }
            }else if (cmdByte[0] == 0x03 && cmdByte[1] == 0x10) {
                NSString *json = [[NSString alloc] initWithData:[self.receiveData subdataWithRange:NSMakeRange(12, [self.receiveData length] - 14)] encoding:NSUTF8StringEncoding];
                NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:json];
                if ([jsonDictionary count] > 0) {
                    NSInteger version = [jsonDictionary[@"version"] integerValue];
                    CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceID];
                    if ([d.mcSonosInfoVersion integerValue] < version) {
                        Byte sByte[2];
                        sByte[0] = (self.sourceAddress & 0xFF00) >> 8;
                        sByte[1] = self.sourceAddress & 0x00FF;
                        NSInteger frameNumber = [self getFrameNumber];
                        Byte b[] = {0xa5, frameNumber, 0x0e, 0x00, 0x00, 0x00, sByte[1], sByte[0], 0x01, 0x00, 0x02, 0x10};
                        NSData *d = [[NSData alloc] initWithBytes:b length:12];
                        int sum = [CSRUtilities atFromData:d];
                        Byte byte[] = {0xa5, frameNumber, 0x0e, 0x00, 0x00, 0x00, sByte[1], sByte[0], 0x01, 0x00, 0x02, 0x10, sum, 0xfe};
                        NSData *data = [[NSData alloc] initWithBytes:byte length:14];
                        [self writeData:data];
                    }
                }
            }else if (cmdByte[0] == 0x04 && cmdByte[1] == 0x00) {
                NSString *json = [[NSString alloc] initWithData:[self.receiveData subdataWithRange:NSMakeRange(12, [self.receiveData length] - 14)] encoding:NSUTF8StringEncoding];
                
                NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:json];
                if ([jsonDictionary count] > 0) {
                    BOOL success = [jsonDictionary[@"success"] boolValue];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(updateMCUResult:)]) {
                        [self.delegate updateMCUResult:success];
                    }
                }
            }else if (cmdByte[0] == 0x03 && cmdByte[1] == 0x80) {
                NSString *json = [[NSString alloc] initWithData:[self.receiveData subdataWithRange:NSMakeRange(12, [self.receiveData length] - 14)] encoding:NSUTF8StringEncoding];
                
                NSDictionary *jsonDictionary = [CSRUtilities dictionaryWithJsonString:json];
                if ([jsonDictionary count] > 0) {
                    BOOL success = [jsonDictionary[@"success"] boolValue];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(sendedDownloadAddress:)]) {
                        [self.delegate sendedDownloadAddress:success];
                    }
                }
            }
            
        }
    }
    
    [self.tcpSocketManager readDataWithTimeout:-1 tag:0];
}

- (NSInteger)getFrameNumber {
    self.frameNumber ++ ;
    if (self.frameNumber > 255) {
        self.frameNumber = 0;
    }
    return self.frameNumber;
}

- (void)writeData:(NSData *)data {
    NSLog(@"sendData: %@",data);
    [self.tcpSocketManager writeData:data withTimeout:-1 tag:0];
}

- (void)updateMCU:(NSData *)jsData {
    NSInteger s0 = (self.sourceAddress & 0xFF00) >> 8;
    NSInteger s1 = self.sourceAddress & 0x00FF;
    NSInteger frameNumber = [self getFrameNumber];
    NSInteger length = [jsData length] + 14;
    NSInteger l0 = (length & 0xFF000000) >> 24;
    NSInteger l1 = (length & 0x00FF0000) >> 16;
    NSInteger l2 = (length & 0x0000FF00) >> 8;
    NSInteger l3 = length & 0x000000FF;
    Byte b[] = {0xa5, frameNumber, l3, l2, l1, l0, s1, s0, 0x01, 0x00, 0x03, 0x00};
    NSMutableData *mData = [[NSMutableData alloc] initWithBytes:b length:12];
    [mData appendData:jsData];
    int sum = [CSRUtilities atFromData:mData];
    Byte w[] = {sum, 0xfe};
    NSData *wData = [[NSData alloc] initWithBytes:w length:2];
    [mData appendData:wData];
    [self writeData:mData];
}

- (void)getDeviceList {
    Byte sByte[2];
    sByte[0] = (self.sourceAddress & 0xFF00) >> 8;
    sByte[1] = self.sourceAddress & 0x00FF;
    NSInteger frameNumber = [self getFrameNumber];
    Byte b[] = {0xa5, frameNumber, 0x0e, 0x00, 0x00, 0x00, sByte[1], sByte[0], 0x01, 0x00, 0x01, 0x10};
    NSData *d = [[NSData alloc] initWithBytes:b length:12];
    int sum = [CSRUtilities atFromData:d];
    Byte byte[] = {0xa5, frameNumber, 0x0e, 0x00, 0x00, 0x00, sByte[1], sByte[0], 0x01, 0x00, 0x01, 0x10, sum, 0xfe};
    NSData *data = [[NSData alloc] initWithBytes:byte length:14];
    [self writeData:data];
}

@end
