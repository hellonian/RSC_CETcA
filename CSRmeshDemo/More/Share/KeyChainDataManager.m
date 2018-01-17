//
//  KeyChainDataManager.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/10/12.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "KeyChainDataManager.h"
#import "KeyChain.h"

@implementation KeyChainDataManager

static NSString * const KEY_IN_KEYCHAIN_UUID = @"唯一识别的KEY——UUID";
static NSString * const KEY_UUID = @"唯一识别的key_uuid";

+ (void)saveUUID:(NSString *)UUID {
    NSMutableDictionary *usernamepasswordKVPairs = [NSMutableDictionary dictionary];
    [usernamepasswordKVPairs setObject:UUID forKey:KEY_UUID];
    [KeyChain save:KEY_IN_KEYCHAIN_UUID data:usernamepasswordKVPairs];
}

+(NSString *)readUUID{
    
    NSMutableDictionary *usernamepasswordKVPair = (NSMutableDictionary *)[KeyChain load:KEY_IN_KEYCHAIN_UUID];
    
    return [usernamepasswordKVPair objectForKey:KEY_UUID];
    
}

+(void)deleteUUID{
    
    [KeyChain delete:KEY_IN_KEYCHAIN_UUID];
    
}

@end
