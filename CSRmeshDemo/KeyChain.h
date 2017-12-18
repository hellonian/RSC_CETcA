//
//  KeyChain.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/10/12.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyChain : NSObject

+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service;

+ (void)save:(NSString *)service data:(id)data;

+ (id)load:(NSString *)service;

+ (void)delete:(NSString *)service;

@end
