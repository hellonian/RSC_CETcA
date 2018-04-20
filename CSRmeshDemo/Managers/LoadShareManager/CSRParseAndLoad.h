//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <Foundation/Foundation.h>
#import "CSRPlaceEntity.h"

@interface CSRParseAndLoad : NSObject

- (void) deleteEntitiesInSelectedPlace:(CSRPlaceEntity *)placeEntity;

- (CSRPlaceEntity *) parseIncomingDictionary:(NSDictionary*)parsingDictionary;
- (NSData *) composeDatabase;


@end
