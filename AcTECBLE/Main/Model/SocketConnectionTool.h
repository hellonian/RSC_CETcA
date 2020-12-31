//
//  SocketConnectionTool.h
//  AcTECBLE
//
//  Created by AcTEC on 2020/10/23.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@protocol SocketConnectionToolDelegate <NSObject>

@optional
- (void)saveSonosInfo:(NSNumber *_Nullable)deviceID;
- (void)socketConnectFail:(NSNumber *_Nullable)deviceID;
- (void)updateMCUResult:(BOOL)result;
- (void)enableMCUUpdateBtn;
- (void)sendedDownloadAddress:(BOOL)result;
@end

NS_ASSUME_NONNULL_BEGIN

@interface SocketConnectionTool : NSObject<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *tcpSocketManager;
@property (nonatomic, assign) NSInteger frameNumber;
@property (nonatomic, assign) NSInteger sourceAddress;
@property (nonatomic, strong) NSMutableData *receiveData;
@property (nonatomic, strong) NSNumber *deviceID;
@property (nonatomic, weak) id<SocketConnectionToolDelegate> delegate;
@property (nonatomic, assign) BOOL hasConnected;
@property (nonatomic, strong) NSString *sHost;
@property (nonatomic, assign) uint16_t sPort;

- (void)connentHost:(NSString *)host prot:(uint16_t)port;
- (NSInteger)getFrameNumber;
- (void)writeData:(NSData *)data;
- (void)updateMCU:(NSData *)jsData;
- (void)getDeviceList;

@end

NS_ASSUME_NONNULL_END
