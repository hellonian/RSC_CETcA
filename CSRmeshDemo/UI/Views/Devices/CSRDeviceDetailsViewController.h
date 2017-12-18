//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CSRMainViewController.h"
#import "CSRmeshDevice.h"
#import "CSRDeviceEntity.h"
#import "CSRDeviceDetailsButtonsTableViewCell.h"

@interface CSRDeviceDetailsViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *topSectionView;
@property (weak, nonatomic) IBOutlet UIImageView *deviceIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *deviceTitleTextField;
@property (weak, nonatomic) IBOutlet UIView *underlineView;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
//@property (nonatomic) UIBarButtonItem *backButton;

//@property (weak, nonatomic) UIButton *favButton;
//@property (weak, nonatomic) UIButton *attButton;
//@property (weak, nonatomic) UIButton *srtButton;

@property (weak, nonatomic) IBOutlet UITableView *deviceDetailsTableView;
//@property (strong, nonatomic) CSRDeviceDetailsButtonsTableViewCell *buttonsCell;

@property (nonatomic) CSRmeshDevice *device;
@property (nonatomic) CSRDeviceEntity *deviceEntity;

//- (IBAction)saveDeviceConfiguration:(id)sender;
//- (IBAction)toggleFavouriteState:(id)sender;
- (IBAction)editAreas:(id)sender;
- (IBAction)deleteButtonTapped:(id)sender;

- (IBAction)favouriteAction:(UIButton *)sender;
- (IBAction)attentionAction:(UIButton *)sender;
- (IBAction)startModeAction:(UIButton *)sender;

- (IBAction)backAction:(id)sender;
- (IBAction)saveAction:(id)sender;

@end
