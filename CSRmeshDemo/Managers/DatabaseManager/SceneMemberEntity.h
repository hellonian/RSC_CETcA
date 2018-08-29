//
//  SceneMemberEntity.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/24.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SceneMemberEntity : NSManagedObject

@property (nonatomic, retain) NSNumber *deviceID;
@property (nonatomic, retain) NSNumber *powerState;
@property (nonatomic, retain) NSNumber *level;
@property (nonatomic, retain) NSString *kindString;
@property (nonatomic, retain) NSNumber *sceneID;
@property (nonatomic, retain) NSNumber *colorRed;
@property (nonatomic, retain) NSNumber *colorGreen;
@property (nonatomic, retain) NSNumber *colorBlue;
@property (nonatomic, retain) NSNumber *colorTemperature;
@property (nonatomic, retain) NSNumber *eveType;
@property (nonatomic, retain) NSNumber *sortID;

@end
