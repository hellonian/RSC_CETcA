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
@property (nonatomic, retain) NSNumber *channel;
@property (nonatomic, retain) NSNumber *powerState2;
@property (nonatomic, retain) NSNumber *powerState3;
@property (nonatomic, retain) NSNumber *level2;
@property (nonatomic, retain) NSNumber *level3;
@property (nonatomic, retain) NSNumber *eveType2;
@property (nonatomic, retain) NSNumber *eveType3;
@property (nonatomic, retain) NSNumber *eveD0;
@property (nonatomic, retain) NSNumber *eveD1;
@property (nonatomic, retain) NSNumber *eveD2;
@property (nonatomic, retain) NSNumber *eveD3;

@end
