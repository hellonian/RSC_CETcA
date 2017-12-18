//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRAreaSelectionManager.h"

@implementation CSRAreaSelectionManager


+ (CSRAreaSelectionManager*)sharedInstance
{
    static dispatch_once_t token;
    static CSRAreaSelectionManager *shared = nil;
    
    dispatch_once(&token, ^{
        shared = [[CSRAreaSelectionManager alloc] init];
    });
    
    return shared;
}


- (BOOL) writeAreaForDevice:(CSRDeviceEntity *)deviceEntity withAreaID:(NSNumber *)areaID
{
    NSMutableData *areasData = (NSMutableData*)deviceEntity.groups;
    uint16_t *rover = (uint16_t*)areasData.mutableBytes;
    int count;
    for (count =0; count < areasData.length/2; count++, rover++) {
        if (*rover == 0) {
            *rover = [areaID unsignedShortValue];
            return YES;
        }
    }
    return NO;
}

- (void) deleteAreaForDevice:(CSRDeviceEntity *)deviceEntity withAreaID:(NSNumber *)areaID
{
    NSMutableData *areasData = (NSMutableData*)deviceEntity.groups;
    uint16_t *rover = (uint16_t*)areasData.mutableBytes;
    uint16_t areaIDValue = [areaID intValue];
    int count;
    for (count =0; count < areasData.length/2; count++, rover++) {
        if (*rover == areaIDValue) {
            *rover = 0;
            return;
        }
    }
    
}


@end
