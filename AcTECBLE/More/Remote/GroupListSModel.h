//
//  GroupListSModel.h
//  AcTECBLE
//
//  Created by AcTEC on 2018/6/26.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GroupListSModel : NSObject

@property (nonatomic, strong) NSNumber *areaIconNum;
@property (nonatomic, strong) NSNumber *areaID;
@property (nonatomic, strong) NSString *areaName;
@property (nonatomic, strong) NSData *areaImage;
@property (nonatomic, strong) NSNumber *sortId;
@property (nonatomic, strong) NSSet *devices;
@property (nonatomic, assign) BOOL isForList;
@property (nonatomic, assign) BOOL isSelected;

@end
