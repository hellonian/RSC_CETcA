//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRMainViewController.h"
#import "CSRBearerPickerViewController.h"

@interface CSRApplicationSettingsViewController : CSRMainViewController <UITableViewDelegate, UITableViewDataSource, CSRBearerPickerDelegate, UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UISwitch *bearerSwitch;

@end
