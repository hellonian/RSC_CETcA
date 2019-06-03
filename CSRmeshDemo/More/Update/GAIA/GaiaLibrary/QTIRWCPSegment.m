//
// Copyright 2017 Qualcomm Technologies International, Ltd.
//

#import "QTIRWCPSegment.h"

@implementation QTIRWCPSegment

- (id)initWithLength:(uint8_t)length sequence:(uint8_t)sequence data:(NSData *)data {
    if (self = [super init]) {
        _length = length;
        _sequence = sequence;
        _data = data;
    }
    
    return self;
}

@end
