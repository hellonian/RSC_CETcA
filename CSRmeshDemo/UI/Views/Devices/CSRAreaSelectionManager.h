//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <Foundation/Foundation.h>
#import "CSRDeviceEntity.h"

@interface CSRAreaSelectionManager : NSObject

+ (CSRAreaSelectionManager*)sharedInstance;

- (BOOL) writeAreaForDevice:(CSRDeviceEntity*)deviceEntity withAreaID:(NSNumber *)areaID;
- (void) deleteAreaForDevice:(CSRDeviceEntity*)deviceEntity withAreaID:(NSNumber *)areaID;

@end
