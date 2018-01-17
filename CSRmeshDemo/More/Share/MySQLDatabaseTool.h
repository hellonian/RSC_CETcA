//
//  MySQLDatabaseTool.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/10/13.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MySQLDatabaseTool : NSObject


- (void)insertWithUuid:(NSString *)uuid data:(NSString *)data;
//- (void)deleteSceneDataWithUuid:(NSString *)uuid;
//- (void)insertWithUuid:(NSString *)uuid sceneKey:(NSString *)sceneKey sceneData:(NSString *)sceneData;
- (NSData *)seletSceneDataWithUuid:(NSString *)uuid sceneKey:(NSString *)sceneKey;
- (NSArray *)seleteWithUuid:(NSString *)uuid;
- (void)endConnect;
- (void)singInWithName:(NSString *)name passsword:(NSString *)password data:(NSString *)data;
- (void)singUpWithName:(NSString *)name password:(NSString *)password data:(NSString *)data;
- (NSArray *)signInWithName:(NSString *)name passWord:(NSString *)password;
- (NSData *)seleteWithName:(NSString *)name password:(NSString *)password sceneKey:(NSString *)sceneKey;

@end
