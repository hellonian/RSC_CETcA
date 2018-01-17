//
//  SceneCollectionController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/26.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SpecialFlowLayoutCollectionController.h"

@protocol SceneCollectionControllerDelegate <NSObject>
@optional
- (void)sceneCollectionControllerRequireEditingSceneProfile:(NSString*)sceneName sceneMemberInfo:(NSDictionary*)memberInfo isNewAdd:(BOOL)isnewadd;
@end

@interface SceneCollectionController : SpecialFlowLayoutCollectionController
@property (nonatomic,weak) id<SceneCollectionControllerDelegate> delegate;


@end
