//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRmeshDevice.h"
#import <CSRmesh/DataModelApi.h>
#import <CSRmesh/MeshServiceApi.h>
#import "CSRControllerEntity.h"

@protocol CSRControllerAssociated <NSObject>

- (void) dismissAndPush:(CSRControllerEntity *)ctrlEnt;

@end

@interface CSRControllerAssociationVC : UIViewController <UIPopoverPresentationControllerDelegate, UITextFieldDelegate>

@property (assign, nonatomic) id<CSRControllerAssociated> controllerDelegate;

@property (weak, nonatomic) IBOutlet UIView *pinView;
@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UIView *successView;
@property (weak, nonatomic) IBOutlet UIView *failureView;
//@property (weak, nonatomic) IBOutlet UIView *databaseSharingView;


@property (nonatomic) CSRmeshDevice *meshDevice;
@property (nonatomic) UIViewController *parent;

//pin view
@property (weak, nonatomic) IBOutlet UITextField *pinTextField;
- (IBAction)cancelAssociationAction:(id)sender;
- (IBAction)associateAction:(id)sender;

//progress view
@property (weak, nonatomic) IBOutlet UIProgressView *associationProgressView;
@property (weak, nonatomic) IBOutlet UILabel *associationStepsInfoLabel;
- (IBAction)cancelAssociationInProgressView:(id)sender;
//- (IBAction)nextTestAction:(id)sender;

//failure view
@property (weak, nonatomic) IBOutlet UIImageView *failureImageView;
- (IBAction)cancelFailureView:(id)sender;
- (IBAction)tryAgainForAssociationAction:(id)sender;

//success view
@property (weak, nonatomic) IBOutlet UIImageView *successImageView;
- (IBAction)doneAssociationAction:(id)sender;

//Database Sharing view
//@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *databaseSharingActivity;
//- (IBAction)StartDatabaseTransfer:(id)sender;


//Sharing method Picker
//@property (weak, nonatomic) IBOutlet UIView *datbaseSharingPickerView;
//- (IBAction)dataModelApiMethod:(id)sender;
//- (IBAction)chooseAppMethod:(id)sender;


@end
