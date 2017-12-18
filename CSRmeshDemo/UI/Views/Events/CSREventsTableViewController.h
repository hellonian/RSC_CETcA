//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRMainViewController.h"
#import "CSREventEntity.h"

@interface CSREventsTableViewController : CSRMainViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UITableView *eventsTableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addEventButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;

- (IBAction)segmentControlAction:(id)sender;

@end
