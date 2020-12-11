//
//  MyUncaughtExceptionHandler.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/7/22.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "MyUncaughtExceptionHandler.h"

NSString * applicationDocumentsDirectory() {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

// 崩溃时的回调函数
void uncaughtExceptionHandler(NSException * exception) {
    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *crashTime = [formatter stringFromDate:[NSDate date]];
    NSArray * arr = [exception callStackSymbols];
    NSString * reason = [exception reason]; // // 崩溃的原因  可以有崩溃的原因(数组越界,字典nil,调用未知方法...) 崩溃的控制器以及方法
    NSString * name = [exception name];
    NSString * url = [NSString stringWithFormat:@"========异常错误报告========\nCrashTime:%@\nname:%@\nreason:\n%@\ncallStackSymbols:\n%@",crashTime,name,reason,[arr componentsJoinedByString:@"\n"]];
    NSString * path = [applicationDocumentsDirectory() stringByAppendingPathComponent:@"Exception.txt"];
    // 将一个txt文件写入沙盒
    [url writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@implementation MyUncaughtExceptionHandler

+ (void)setDefaultHandler {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
}

@end
