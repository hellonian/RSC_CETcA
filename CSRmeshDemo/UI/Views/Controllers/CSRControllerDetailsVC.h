//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRControllerEntity.h"

@interface CSRControllerDetailsVC : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *controllerDetailsTableView;
@property (weak, nonatomic) IBOutlet UITextField *controllerNameTF;
@property (weak, nonatomic) IBOutlet UIImageView *controllerImageView;


@property (nonatomic, retain) CSRControllerEntity *controllerEntity;

- (IBAction)deleteController:(id)sender;
- (IBAction)backAction:(id)sender;
- (IBAction)saveControllerAction:(id)sender;

@end
