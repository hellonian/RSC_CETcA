//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRMainViewController.h"
#import "CSRmeshDevice.h"
#import "CSRDeviceEntity.h"

typedef NS_ENUM(NSUInteger, CSRWizardPopoverMode) {
    CSRWizardPopoverMode_ShortCode = 0,
    CSRWizardPopoverMode_SecurityCode = 1,
    CSRWizardPopoverMode_AssociationFromDeviceList = 2,
    CSRWizardPopoverMode_AssociationFromQRScan = 3
};

typedef NS_ENUM(NSUInteger, CSRWizardPopoverValidationMode) {
    CSRWizardPopoverValidationMode_Security = 0,
    CSRWizardPopoverValidationMode_ShortCode = 1
};

@protocol CSRWizardPopoverDelegate <NSObject>

- (void)setMode:(CSRWizardPopoverMode)mode;

@end

@protocol CSRDeviceAssociated <NSObject>

- (void) dismissAndPush:(CSRDeviceEntity *)dvcEnt;

@end

@interface CSRWizardPopoverViewController : CSRMainViewController

@property (assign, nonatomic) id<CSRDeviceAssociated> deviceDelegate;

@property (nonatomic) CSRWizardPopoverMode mode;

@property (nonatomic) CSRDeviceEntity *deviceEntity;
@property (nonatomic) CSRmeshDevice *meshDevice;
@property (nonatomic) NSData *deviceHash;
@property (nonatomic) NSData *authCode;

@property (weak, nonatomic) IBOutlet UIView *shortCodeView;
@property (weak, nonatomic) IBOutlet UIView *securityCodeView;
@property (weak, nonatomic) IBOutlet UIView *associationView;

//Short code
@property (weak, nonatomic) IBOutlet UITextField *shortCodeTextField;
@property (weak, nonatomic) IBOutlet UIButton *shortCodeCancel;
@property (weak, nonatomic) IBOutlet UIButton *shortCodeNext;

//Security
@property (weak, nonatomic) IBOutlet UITextField *authorisationCodeSecurityTextField;
@property (weak, nonatomic) IBOutlet UIButton *securityCancel;
@property (weak, nonatomic) IBOutlet UIButton *securityNext;

//Association
@property (weak, nonatomic) IBOutlet UIProgressView *associationProgressView;
@property (weak, nonatomic) IBOutlet UILabel *associationStepsInfoLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *associationCancel;



@end
