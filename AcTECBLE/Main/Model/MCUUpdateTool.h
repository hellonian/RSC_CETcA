//
//  MCUUpdateTool.h
//  AcTECBLE
//
//  Created by AcTEC on 2019/4/25.
//  Copyright © 2019 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MCUUpdateToolDelegate <NSObject>

- (void)starteUpdateHud;
- (void)updateHudProgress:(CGFloat)progress;
- (void)updateSuccess:(BOOL)value;

@end

@interface MCUUpdateTool : NSObject

@property (nonatomic, weak) id<MCUUpdateToolDelegate> toolDelegate;

+ (instancetype)sharedInstace;
- (void)askUpdateMCU:(NSNumber *)deviceId downloadAddress:(NSString *)downloadAddress latestMCUSVersion:(NSInteger)latestMCUSVersion;

@end

NS_ASSUME_NONNULL_END
