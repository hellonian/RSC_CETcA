//
//  KeyChainDataManager.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/10/12.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyChainDataManager : NSObject

+ (void)saveUUID:(NSString *)UUID;

+ (NSString *)readUUID;

+ (void)deleteUUID;

@end
