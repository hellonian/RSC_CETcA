//
//  GroupListSModel.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/6/26.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GroupListSModel : NSObject

@property (nonatomic, strong) NSNumber *areaIconNum;
@property (nonatomic, strong) NSNumber * areaID;
@property (nonatomic, strong) NSString * areaName;
@property (nonatomic, strong) NSData *areaImage;
@property (nonatomic, strong) NSNumber * sortId;
@property (nonatomic, strong) NSSet *devices;
@property (nonatomic, assign) BOOL isForList;
@property (nonatomic, assign) BOOL isSelected;

@end
