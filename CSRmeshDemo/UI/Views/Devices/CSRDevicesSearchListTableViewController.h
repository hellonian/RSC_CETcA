//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRDevicesListViewController.h"

@protocol CSRDevicesSearchListDelegate <NSObject>

- (NSUInteger)selectedItemIndex:(NSUInteger)item;

@end

@interface CSRDevicesSearchListTableViewController : UITableViewController

@property (nonatomic) NSMutableArray *filteredDevicesArray;
@property (assign) id<CSRDevicesSearchListDelegate> delegate;

@end
