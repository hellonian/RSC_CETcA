//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CSRMainViewController.h"
#import "CSRmeshDevice.h"
#import "CSRDeviceEntity.h"
#import "CSRWizardPopoverViewController.h"

@interface CSRQRScanViewController : CSRMainViewController <AVCaptureMetadataOutputObjectsDelegate, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate, CSRDeviceAssociated>


@property (nonatomic) CSRDeviceEntity *deviceEntity;
@property (nonatomic) CSRmeshDevice *selectedDevice;

@property (weak, nonatomic) IBOutlet UIView *scanQRview;

//QR
@property (weak, nonatomic) IBOutlet UIView *qrPreview;
@property (weak, nonatomic) IBOutlet UILabel *qrStatus;
@property (weak, nonatomic) IBOutlet UIView *scanSuccessView;
@property (weak, nonatomic) IBOutlet UIImageView *successTickboxImageView;
@property (weak, nonatomic) IBOutlet UIButton *qrTriggerButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *associateQRButton;

//@property (nonatomic) UIBarButtonItem *backButton;

//Need to make scan results global to use it for Segue and Database Operations
@property (nonatomic, strong) NSString *uuidStringFromQRScan;
@property (nonatomic, strong) NSString *acStringFromQRScan;


- (IBAction)toggleQRScan:(id)sender;
- (IBAction)back:(id)sender;

@end
