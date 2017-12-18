//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRDeviceEntity.h"

@protocol SetAreaIDArray <NSObject>

@optional
- (void)saveAreaIDArray:(NSNumber*)areaID;

@end

@interface CSRAreaSelectionSearchTableViewController : UITableViewController

@property (strong, nonatomic) id<SetAreaIDArray> setAreaIDArray;

@property (nonatomic) NSMutableArray *filteredGroupsArray;
@property (nonatomic, retain) NSMutableArray *areaIdArray;

@property (nonatomic, retain) CSRDeviceEntity *deviceEntity;
@property (nonatomic, retain) NSMutableArray *listOfLocalAreas;

@end