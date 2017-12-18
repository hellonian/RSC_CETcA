//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRMainViewController.h"
#import "CSRGatewayEntity.h"

@interface CSRGatewayDetailsViewController : CSRMainViewController

@property (weak, nonatomic) IBOutlet UIImageView *gatewayIcon;
@property (weak, nonatomic) IBOutlet UITextField *titleLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *stateIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UIButton *enableLocalGatewayButton;
@property (weak, nonatomic) IBOutlet UIButton *enableCloudButton;
@property (nonatomic) UIBarButtonItem *backButton;
@property (nonatomic) CSRGatewayEntity *gatewayEntity;

- (IBAction)deleteButtonTapped:(id)sender;
- (IBAction)enableLocalConnection:(id)sender;
- (IBAction)enableCloudConnection:(id)sender;


@end
