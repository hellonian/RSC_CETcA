//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import <CSRmesh/DataModelApi.h>

@interface CSRShareDatabaseVC : UIViewController <DataModelApiDelegate>

@property (nonatomic) UIViewController *parentVC;

@property (weak, nonatomic) IBOutlet UIView *sharingOptionPickerView;
@property (weak, nonatomic) IBOutlet UIView *dataTransferView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *dataModelTransferAcctivityIndicatorView;
@property (weak, nonatomic) IBOutlet UIButton *thirdPartyButton;

//Controller Device Id
@property (nonatomic) NSNumber *deviceID;

- (IBAction)shareUsingThirdParty:(id)sender;

- (IBAction)cancelTransferOfData:(id)sender;

@end
