//
//  MySQLDatabaseTool.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/10/13.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MySQLDatabaseTool.h"
#import "OHMySQL.h"

@interface MySQLDatabaseTool ()
@property (nonatomic,strong) OHMySQLStoreCoordinator *coordinator;
@property (nonatomic,strong) OHMySQLQueryContext *queryContext;
@end

@implementation MySQLDatabaseTool

static NSString * const sceneListKey = @"com.actec.bluetooth.sceneListKey";

- (id)init {
    self = [super init];
    if (self) {
        OHMySQLUser *user = [[OHMySQLUser alloc] initWithUserName:@"root" password:@"Actec_123!" serverName:@"39.108.152.134" dbName:@"nianbao" port:3306 socket:@"/var/lib/mysql/mysql.sock"];
        _coordinator = [[OHMySQLStoreCoordinator alloc] initWithUser:user];
        [_coordinator connect];
        
        _queryContext = [OHMySQLQueryContext new];
        _queryContext.storeCoordinator = _coordinator;
    }
    return self;
}

//扫描二维码后获取 灯数据
- (NSArray *)seleteWithUuid:(NSString *)uuid {
    
    NSString *condition = [NSString stringWithFormat:@"UUID='%@'",uuid];
    OHMySQLQueryRequest *query = [OHMySQLQueryRequestFactory SELECT:@"actec" condition:condition];
    NSError *error = nil;
    NSArray *array = [_queryContext executeQueryRequestAndFetchResult:query error:&error];
    
    return array;
}

//生成二维码后上传 灯信息 和 场景信息
- (void)insertWithUuid:(NSString *)uuid data:(NSString *)data {
    
    NSString *deleteActecCondition = [NSString stringWithFormat:@"UUID='%@'",uuid];
    OHMySQLQueryRequest *deleteActecQuery = [OHMySQLQueryRequestFactory DELETE:@"actec" condition:deleteActecCondition];
    NSError *deleteActecError;
    [_queryContext executeQueryRequest:deleteActecQuery error:&deleteActecError];
    
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    NSArray *sceneList = [center arrayForKey:sceneListKey];
    NSString *sceneListString = [sceneList componentsJoinedByString:@"|"];
    
    OHMySQLQueryRequest *query = [OHMySQLQueryRequestFactory INSERT:@"actec" set:@{@"UUID": uuid, @"DATA": data, @"SCENELIST": sceneListString}];
    NSError *error;
    [_queryContext executeQueryRequest:query error:&error];
    
    OHMySQLQueryRequest *deleteSceneQuery = [OHMySQLQueryRequestFactory DELETE:@"scene" condition:deleteActecCondition];
    NSError *deleteSceneError;
    [_queryContext executeQueryRequest:deleteSceneQuery error:&deleteSceneError];
    
    for (NSString *sceneKey in sceneList) {
        NSData *sceneData = [center objectForKey:sceneKey];
        NSString *sceneDataStr = [self hexStringForData:sceneData];
        OHMySQLQueryRequest *insertQuery = [OHMySQLQueryRequestFactory INSERT:@"scene" set:@{@"UUID": uuid, @"SCENEKEY": sceneKey, @"SCENEDATA": sceneDataStr}];
        NSError *insertError;
        [_queryContext executeQueryRequest:insertQuery error:&insertError];
    }
  
}

//扫描二维码后获取 场景信息
- (NSData *)seletSceneDataWithUuid:(NSString *)uuid sceneKey:(NSString *)sceneKey {
    NSString *condition = [NSString stringWithFormat:@"UUID='%@' and SCENEKEY='%@'",uuid,sceneKey];
    OHMySQLQueryRequest *query = [OHMySQLQueryRequestFactory SELECT:@"scene" condition:condition];
    NSError *error ;
    NSArray *array = [_queryContext executeQueryRequestAndFetchResult:query error:&error];
    if (array.count > 0) {
        NSDictionary *dic = array[0];
        NSString *sceneDataStr = dic[@"SCENEDATA"];
        NSData *sceneData = [self dataForHexString:sceneDataStr];
        return sceneData;
    }
    return nil;
}


- (void)endConnect {
    [_coordinator disconnect];
}

//注册账号 并上传 灯信息 和 场景信息
- (void)singUpWithName:(NSString *)name password:(NSString *)password data:(NSString *)data{
    NSString *condition = [NSString stringWithFormat:@"NAME='%@'",name];
    OHMySQLQueryRequest *query = [OHMySQLQueryRequestFactory SELECT:@"bluetooth" condition:condition];
    NSError *error = nil;
    NSArray *array = [_queryContext executeQueryRequestAndFetchResult:query error:&error];
    
    if (error) {
        
        [self alert:error];
        
        return;
    }
    
    if (array.count > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showMessage" object:nil userInfo:@{@"message":@"ERROR: The login name already exists."}];
    }else {
        NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
        NSArray *sceneList = [center arrayForKey:sceneListKey];
        NSString *sceneListString = [sceneList componentsJoinedByString:@"|"];
        
        OHMySQLQueryRequest *query1 = [OHMySQLQueryRequestFactory INSERT:@"bluetooth" set:@{ @"NAME": name, @"PASSWORD": password, @"DATA":data, @"SCENELIST":sceneListString }];
        NSError *error1;
        [_queryContext executeQueryRequest:query1 error:&error1];
        
        for (NSString *sceneKey in sceneList) {
            NSData *sceneData = [center objectForKey:sceneKey];
            NSString *sceneDataStr = [self hexStringForData:sceneData];
            OHMySQLQueryRequest *sceneQuery = [OHMySQLQueryRequestFactory INSERT:@"zhscene" set:@{ @"NAME":name, @"PASSWORD":password, @"SCENEKEY":sceneKey, @"SCENEDATA":sceneDataStr}];
            NSError *sceneError = nil;
            [_queryContext executeQueryRequest:sceneQuery error:&sceneError];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showMessage" object:nil userInfo:@{@"message":@"Register and upload success."}];
    }
}

//登录账号 并上传 灯信息 和 场景信息
- (void)singInWithName:(NSString *)name passsword:(NSString *)password data:(NSString *)data {
    NSString *condition = [NSString stringWithFormat:@"NAME='%@' and PASSWORD='%@'",name,password];
    OHMySQLQueryRequest *query = [OHMySQLQueryRequestFactory SELECT:@"bluetooth" condition:condition];
    NSError *error = nil;
    NSArray *array = [_queryContext executeQueryRequestAndFetchResult:query error:&error];
    if (error) {
        
        [self alert:error];
        return;
    }
    if (array.count > 0) {
        
        NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
        NSArray *sceneList = [center arrayForKey:sceneListKey];
        NSString *sceneListString = [sceneList componentsJoinedByString:@"|"];
        
        OHMySQLQueryRequest *query = [OHMySQLQueryRequestFactory UPDATE:@"bluetooth" set:@{ @"DATA": data, @"SCENELIST": sceneListString } condition:condition];
        NSError *error;
        [_queryContext executeQueryRequest:query error:&error];
        
        OHMySQLQueryRequest *deleteQuery = [OHMySQLQueryRequestFactory DELETE:@"zhscene" condition:condition];
        NSError *deleteError = nil;
        [_queryContext executeQueryRequest:deleteQuery error:&deleteError];
        
        for (NSString *sceneKey in sceneList) {
            NSData *sceneData = [[NSUserDefaults standardUserDefaults] objectForKey:sceneKey];
            NSString *sceneDataStr = [self hexStringForData:sceneData];
            OHMySQLQueryRequest *sceneQuery = [OHMySQLQueryRequestFactory INSERT:@"zhscene" set:@{ @"NAME":name, @"PASSWORD":password, @"SCENEKEY":sceneKey, @"SCENEDATA":sceneDataStr}];
            NSError *sceneError = nil;
            [_queryContext executeQueryRequest:sceneQuery error:&sceneError];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showMessage" object:nil userInfo:@{@"message":@"Login and upload success."}];
        
    }else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showMessage" object:nil userInfo:@{@"message":@"Logon failure : unknown user name or bad password ."}];
    }
}

//登录账号 并获取 灯信息
- (NSArray *)signInWithName:(NSString *)name passWord:(NSString *)password {
    NSString *condition = [NSString stringWithFormat:@"NAME='%@' and PASSWORD='%@'",name,password];
    OHMySQLQueryRequest *query = [OHMySQLQueryRequestFactory SELECT:@"bluetooth" condition:condition];
    NSError *error = nil;
    NSArray *array = [_queryContext executeQueryRequestAndFetchResult:query error:&error];
    if (error) {
        [self alert:error];
        return nil;
    }
    if (array.count > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showMessage" object:nil userInfo:@{@"message":@"Login and download success."}];
        return array;
    }else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showMessage" object:nil userInfo:@{@"message":@"Logon failure : unknown user name or bad password ."}];
        return nil;
    }
}

//登录账号后获取 场景信息
- (NSData *)seleteWithName:(NSString *)name password:(NSString *)password sceneKey:(NSString *)sceneKey {
    NSString *condition = [NSString stringWithFormat:@"NAME='%@' and PASSWORD='%@' and SCENEKEY='%@'",name,password,sceneKey];
    OHMySQLQueryRequest *query = [OHMySQLQueryRequestFactory SELECT:@"zhscene" condition:condition];
    NSError *error = nil;
    NSArray *array = [_queryContext executeQueryRequestAndFetchResult:query error:&error];
    if (array.count > 0) {
        NSDictionary *dic = array[0];
        NSString *sceneDataStr = dic[@"SCENEDATA"];
        NSData *sceneData = [self dataForHexString:sceneDataStr];
        return sceneData;
    }
    return nil;
}

- (void)alert : (NSError *) error{
    NSDictionary *dic = [error valueForKeyPath:@"_userInfo"];
    NSString *string = [dic objectForKey:@"NSLocalizedDescription"];
    
    if ([string containsString:@"Cannot connect to DB."]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showMessage" object:nil userInfo:@{@"message":@"ERROR: Unable to connect to the network, please check your network."}];
        
    }
}

//二进制数据转十六进制字符串
- (NSString *)hexStringForData: (NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

//十六进制字符串转二进制数据
- (NSData*)dataForHexString:(NSString*)hexString
{
    if (hexString == nil) {
        return nil;
    }
    const char* ch = [[hexString lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableData* data = [NSMutableData data];
    while (*ch) {
        if (*ch == ' ') {
            continue;
        }
        char byte = 0;
        if ('0' <= *ch && *ch <= '9') {
            byte = *ch - '0';
        }
        else if ('a' <= *ch && *ch <= 'f') {
            byte = *ch - 'a' + 10;
        }
        else if ('A' <= *ch && *ch <= 'F') {
            byte = *ch - 'A' + 10;
        }
        ch++;
        byte = byte << 4;
        if (*ch) {
            if ('0' <= *ch && *ch <= '9') {
                byte += *ch - '0';
            } else if ('a' <= *ch && *ch <= 'f') {
                byte += *ch - 'a' + 10;
            }
            else if('A' <= *ch && *ch <= 'F')
            {
                byte += *ch - 'A' + 10;
            }
            ch++;
        }
        [data appendBytes:&byte length:1];
    }
    return data;
}

@end
