//
//  GallaryEntity.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/1/2.
//  Copyright © 2018年 AcTEC ELECTRONICS Ltd. All rights reserved.
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
@property (nonatomic,retain) NSNumber *sortId;

@end

@interface GalleryEntity (CoreDataGeneratedAccessors)

- (void)addDropsObject:(DropEntity *)value;
- (void)removeDropsObject:(DropEntity *)value;
- (void)addDrops:(NSSet *)values;
- (void)removeDrops:(NSSet *)values;

@end
