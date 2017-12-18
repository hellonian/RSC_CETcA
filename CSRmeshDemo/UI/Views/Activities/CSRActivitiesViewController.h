//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRMainViewController.h"

@interface CSRActivitiesViewController : CSRMainViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) NSMutableArray *activitiesArray;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end
