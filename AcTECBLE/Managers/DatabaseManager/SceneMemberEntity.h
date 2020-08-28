//
//  SceneMemberEntity.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/1/24.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SceneMemberEntity : NSManagedObject

@property (nonatomic, retain) NSNumber *deviceID;
@property (nonatomic, retain) NSString *kindString;
@property (nonatomic, retain) NSNumber *sceneID;
@property (nonatomic, retain) NSNumber *editing;
@property (nonatomic, retain) NSNumber *eveType;
@property (nonatomic, retain) NSNumber *sortID;
@property (nonatomic, retain) NSNumber *channel;
@property (nonatomic, retain) NSNumber *eveD0;
@property (nonatomic, retain) NSNumber *eveD1;
@property (nonatomic, retain) NSNumber *eveD2;
@property (nonatomic, retain) NSNumber *eveD3;

@end
