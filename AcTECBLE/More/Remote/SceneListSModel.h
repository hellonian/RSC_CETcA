//
//  SceneListSModel.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/6/25.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SceneListSModel : NSObject

@property (nonatomic,strong) NSNumber *sceneId;
@property (nonatomic,strong) NSNumber *iconId;
@property (nonatomic,strong) NSString *sceneName;
@property (nonatomic,strong) NSSet *memnbers;
@property (nonatomic,strong) NSNumber *rcIndex;
@property (nonatomic,assign) BOOL isSelected;

@end
