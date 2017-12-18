//
//  AreaViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/26.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "LightClusterViewController.h"
#import "CSRAreaEntity.h"

@interface AreaViewController : LightClusterViewController

@property (nonatomic,copy)NSArray *areaMembers;
@property (nonatomic,strong) NSNumber *areaId;
@property (nonatomic,copy) void(^block)();

@end
