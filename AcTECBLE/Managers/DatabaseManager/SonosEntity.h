//
//  SonosEntity.h
//  AcTECBLE
//
//  Created by AcTEC on 2020/10/11.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface SonosEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * deviceID;
@property (nonatomic, retain) NSNumber * channel;
@property (nonatomic, retain) NSNumber * infoVersion;
@property (nonatomic, retain) NSNumber * modelNumber;
@property (nonatomic, retain) NSNumber * modelType;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * alive;

@end

NS_ASSUME_NONNULL_END
