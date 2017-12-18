//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <Foundation/Foundation.h>
#import "CSREventEntity.h"

@interface CSREventsManager : NSOperation

- (instancetype)initWithData:(CSREventEntity *)eEntity withTimeInMills:(double )time secondsData:(NSNumber*)secondsField weekData:(NSData *)weekField;

@end
