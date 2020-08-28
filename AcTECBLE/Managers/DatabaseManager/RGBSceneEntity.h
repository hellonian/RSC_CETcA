//
//  RGBSceneEntity.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/8/31.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface RGBSceneEntity : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * isDefaultImg;
@property (nonatomic, retain) NSData * rgbSceneImage;
@property (nonatomic, retain) NSNumber * rgbSceneID;
@property (nonatomic, strong) NSNumber * level;
@property (nonatomic, retain) NSNumber * colorSat;
@property (nonatomic, retain) NSNumber * eventType;
@property (nonatomic, retain) NSNumber * hueA;
@property (nonatomic, retain) NSNumber * hueB;
@property (nonatomic, retain) NSNumber * hueC;
@property (nonatomic, retain) NSNumber * hueD;
@property (nonatomic, retain) NSNumber * hueE;
@property (nonatomic, retain) NSNumber * hueF;
@property (nonatomic, retain) NSNumber * changeSpeed;
@property (nonatomic, retain) NSNumber * sortID;
@property (nonatomic, retain) NSNumber * deviceID;

@end
