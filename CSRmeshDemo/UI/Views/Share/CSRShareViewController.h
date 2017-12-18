//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import <CSRmesh/DataModelApi.h>
#import <CSRmesh/MeshServiceApi.h>
#import "CSRMainViewController.h"

@interface CSRShareViewController : CSRMainViewController <DataModelApiDelegate>

@property (weak, nonatomic) IBOutlet UIButton *getFileFromGatwayOrCloud;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *importStatusIndicator;

- (IBAction)getFileFromGateway:(id)sender;
//- (IBAction)importUsingMesh:(id)sender;

@end
