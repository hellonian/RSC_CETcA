//
//  SceneEntity.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/24.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SceneMemberEntity;

@interface SceneEntity : NSManagedObject

@property (nonatomic,retain) NSNumber *sceneID;
@property (nonatomic,retain) NSNumber *iconID;
@property (nonatomic,retain) NSString *sceneName;
@property (nonatomic,retain) NSSet *members;
@property (nonatomic,retain) NSNumber *rcIndex;
@property (nonatomic,retain) NSNumber *enumMethod;
@property (nonatomic,retain) NSNumber *srDeviceId;

@end

@interface SceneEntity (CoreDataGeneratedAccessors)

- (void)addMembersObject:(SceneMemberEntity *)value;
- (void)removeMembersObject:(SceneMemberEntity *)value;
- (void)addMembers:(NSSet *)values;
- (void)removeMembers:(NSSet *)values;

@end
