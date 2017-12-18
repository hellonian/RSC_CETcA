//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRMainViewController.h"
#import <CSRmesh/DataModelApi.h>

@interface CSRControllersViewController : CSRMainViewController <UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *controllersTableView;
- (IBAction)addControllerAction:(id)sender;

- (IBAction)unwindToMain:(UIStoryboardSegue*)sender;
@property (weak, nonatomic) IBOutlet UIView *transferDataView;

@end
