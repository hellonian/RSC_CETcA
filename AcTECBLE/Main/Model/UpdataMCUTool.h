//
//  UpdataMCUTool.h
//  AcTECBLE
//
//  Created by AcTEC on 2020/11/20.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol UpdataMCUToolDelegate <NSObject>

- (void)starteUpdateHud;
- (void)updateHudProgress:(CGFloat)progress;
- (void)updateSuccess:(NSString *)value;

@end

@interface UpdataMCUTool : NSObject

@property (nonatomic, weak) id<UpdataMCUToolDelegate> toolDelegate;
@property (nonatomic, strong) NSNumber *deviceID;
@property (nonatomic, strong) NSString *downloadAddress;
@property (nonatomic, assign) NSInteger latestMCUVersion;
@property (nonatomic, assign) NSInteger sendCount;
@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, strong) NSData *binData;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) NSInteger retryCount;

+ (instancetype)sharedInstace;
- (void)askUpdateMCU:(NSNumber *)deviceId downloadAddress:(NSString *)downloadAddress latestMCUSVersion:(NSInteger)latestMCUSVersion;

@end

NS_ASSUME_NONNULL_END
