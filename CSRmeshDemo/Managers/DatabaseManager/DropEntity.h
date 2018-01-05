//
//  DropEntity.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/2.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CSRDeviceEntity;

@interface DropEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * boundRatio;
@property (nonatomic, retain) NSNumber * centerXRatio;
@property (nonatomic, retain) NSNumber * centerYRatio;
@property (nonatomic, retain) CSRDeviceEntity * device;
@property (nonatomic, retain) NSNumber * dropID;

@end
