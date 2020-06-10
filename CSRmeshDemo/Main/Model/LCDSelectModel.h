//
//  LCDSelectModel.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/1/4.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SelectModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LCDSelectModel : SelectModel

@property (nonatomic, strong)NSNumber *typeID;
@property (nonatomic, strong)NSNumber *iconID;
@property (nonatomic, strong)NSString *name;
@property (nonatomic, strong)NSNumber *sortID;

@end

NS_ASSUME_NONNULL_END
