//
//  AreaModel.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/23.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AreaModel : NSObject

@property (nonatomic,strong) NSNumber *areaID;
@property (nonatomic,strong) NSString *areaName;
@property (nonatomic,copy) NSArray *devices;
@property (nonatomic,assign) BOOL isShowDeleteBtn;

@end
