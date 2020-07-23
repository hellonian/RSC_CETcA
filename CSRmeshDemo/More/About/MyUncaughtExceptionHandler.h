//
//  MyUncaughtExceptionHandler.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/7/22.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MyUncaughtExceptionHandler : NSObject

+ (void)setDefaultHandler;
+ (NSUncaughtExceptionHandler *)getHandler;
+ (void)TakeException:(NSException *) exception;

@end

NS_ASSUME_NONNULL_END
