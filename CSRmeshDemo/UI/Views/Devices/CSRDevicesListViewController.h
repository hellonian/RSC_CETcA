//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRMainViewController.h"
#import "CSRWizardPopoverViewController.h"
#import "CSRDeviceEntity.h"

@interface CSRDevicesListViewController : CSRMainViewController <UITableViewDelegate, UITableViewDataSource, CSRDeviceAssociated>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addDeviceButton;
@property (nonatomic) NSMutableArray *devices;
@property (nonatomic) UIRefreshControl *refreshControl;

@property (nonatomic) CSRDeviceEntity *deviceEntity;

- (void)displayLightControl;

@end
