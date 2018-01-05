//
//  GallaryEntity.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/2.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DropEntity;

@interface GalleryEntity : NSManagedObject

@property (nonatomic,retain) NSNumber *galleryID;
@property (nonatomic,retain) NSData *galleryImage;
@property (nonatomic,retain) NSNumber *boundWidth;
@property (nonatomic,retain) NSNumber *boundHeight;
@property (nonatomic,retain) NSSet *drops;

@end

@interface GalleryEntity (CoreDataGeneratedAccessors)

- (void)addDropsObject:(DropEntity *)value;
- (void)removeDropsObject:(DropEntity *)value;
- (void)addDevices:(NSSet *)values;
- (void)removeDrops:(NSSet *)values;

@end
