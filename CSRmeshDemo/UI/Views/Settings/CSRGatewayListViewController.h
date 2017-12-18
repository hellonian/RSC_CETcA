//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRMainViewController.h"
#import <CSRmesh/CSRNetServiceBrowser.h>
#import "CSRGatewayConnectionViewController.h"

@interface CSRGatewayListViewController : CSRMainViewController <UITableViewDataSource, UITableViewDelegate, CSRNetServiceBrowserDelegate, UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectButton;

@property (nonatomic) BOOL isRecovery;

@end
