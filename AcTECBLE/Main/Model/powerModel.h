//
//  PowerModel.h
//  AcTECBLE
//
//  Created by AcTEC on 2019/1/10.
//  Copyright © 2019 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PowerModel : NSObject

@property (nonatomic,strong) NSDate *powerDate;
@property (nonatomic,assign) CGFloat power;
@property (nonatomic,assign) BOOL selected;
@property (nonatomic,assign) NSInteger kindInt;

@end

NS_ASSUME_NONNULL_END
