//
//  SelectModel.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/12/9.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SelectModel : NSObject

@property (nonatomic,strong)NSNumber *deviceID;
@property (nonatomic,strong)NSNumber *channel;
@property (nonatomic,strong)NSNumber *sourceID;

@end

NS_ASSUME_NONNULL_END
