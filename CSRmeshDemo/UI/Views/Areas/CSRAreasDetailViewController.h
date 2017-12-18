//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRMainViewController.h"
#import "CSRmeshArea.h"
#import "CSRAreaEntity.h"

@interface CSRAreasDetailViewController : CSRMainViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topSectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *areaTitleTextField;
@property (weak, nonatomic) IBOutlet UIView *underlineView;
@property (weak, nonatomic) IBOutlet UIButton *favouritesButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIScrollView *devicesScrollView;
@property (nonatomic) CSRmeshArea *area;
@property (nonatomic, retain) CSRAreaEntity *areaEntity;

@property (nonatomic, retain) NSMutableArray *devicesArray;

- (IBAction)saveAreaConfiguration:(id)sender;
- (IBAction)cancelButtonClicked:(id)sender;
- (IBAction)toggleFavouriteState:(id)sender;
- (IBAction)editDevices:(id)sender;
- (IBAction)deleteArea:(id)sender;
- (IBAction)back:(id)sender;

@end
