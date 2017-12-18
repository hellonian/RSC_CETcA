//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRMainViewController.h"

@interface CSRDeveloperOptionsViewController : CSRMainViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *cloudHostTF;
@property (weak, nonatomic) IBOutlet UITextField *networkIdTF;
@property (weak, nonatomic) IBOutlet UITextField *placeIdTF;
@property (weak, nonatomic) IBOutlet UITextField *tenantIdTF;
@property (weak, nonatomic) IBOutlet UITextField *meshIdTF;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

- (IBAction)testingApis:(id)sender;
//- (IBAction)testingRestApis:(id)sender;

@end
