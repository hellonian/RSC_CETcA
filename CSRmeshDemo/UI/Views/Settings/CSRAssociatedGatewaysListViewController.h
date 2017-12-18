//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRMainViewController.h"
//#import "CSRBearerPickerViewController.h"

typedef NS_ENUM(NSUInteger, CSRGatewayListMode) {
    
    CSRGatewayListMode_GatewayDetails = 0,
    CSRGatewayListMode_SelectionList
};

@interface CSRAssociatedGatewaysListViewController : CSRMainViewController 

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addGatewayButton;
@property (nonatomic) UIBarButtonItem *backButton;

@property (nonatomic) CSRGatewayListMode mode;

@property (nonatomic) UIViewController *parentVC;

- (IBAction)addGateway:(id)sender;

@end
