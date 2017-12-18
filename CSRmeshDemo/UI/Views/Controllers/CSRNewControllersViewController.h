//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRControllerAssociationVC.h"

@interface CSRNewControllersViewController : UIViewController <UIPopoverPresentationControllerDelegate, UITableViewDelegate, UITableViewDataSource, CSRControllerAssociated>

@property (strong, nonatomic) IBOutlet UIView *associationDoneView;
@property (weak, nonatomic) IBOutlet UITableView *addControllersTableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *associateBarButtonItem;

- (IBAction)backAction:(id)sender;
- (IBAction)associateControllerAction:(id)sender;

@end
