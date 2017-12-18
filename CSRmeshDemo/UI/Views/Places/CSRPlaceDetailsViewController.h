//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRMainViewController.h"
#import "CSRPlacesColorIconPickerViewController.h"
#import "CSRCheckbox.h"
#import "CSRPlaceEntity.h"

@interface CSRPlaceDetailsViewController : UIViewController <UIPopoverPresentationControllerDelegate, CSRPlacesColorIconPickerDelegate, UITextFieldDelegate, CSRCheckboxDelegate, UIAlertViewDelegate>

@property (nonatomic) CSRPlaceEntity *placeEntity;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *placeNameTF;
@property (weak, nonatomic) IBOutlet UITextField *placeNetworkKeyTF;
@property (weak, nonatomic) IBOutlet UIButton *placeIconSelectionButton;
@property (weak, nonatomic) IBOutlet UIButton *placeColorSelectionButton;
@property (weak, nonatomic) IBOutlet CSRCheckbox *showPasswordCheckbox;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *cloudBacupButton;

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UILabel *networkKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *showPasswordLabel;
@property (weak, nonatomic) IBOutlet UIView *passwordLineView;

//Share Database
@property (nonatomic, retain) NSURL *importedURL;

- (IBAction)openPicker:(id)sender;
- (IBAction)backbuttonTapped:(id)sender;
- (IBAction)savePlace:(id)sender;
- (IBAction)deletePlace:(id)sender;
- (IBAction)backupToCloud:(id)sender;
- (IBAction)exportPlace:(id)sender;


@end
