//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
//#import <CSRmesh/MeshServiceApi.h>
#import <CSRmesh/DataModelApi.h>

@interface CSRJoinPlaceVC : UIViewController <UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *pinLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *placefoundLabel;
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;
@property (weak, nonatomic) IBOutlet UIButton *okButton;
@property (weak, nonatomic) IBOutlet UITextView *successTextView;
@property (weak, nonatomic) IBOutlet UIImageView *okImageView;

- (IBAction)okAction:(id)sender;
- (IBAction)backAction:(id)sender;

@end
