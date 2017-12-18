//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRLightViewController.h"

@interface CSRLightWhiteVC : CSRLightViewController

@property (nonatomic, strong) NSNumber *deviceId;
@property (weak, nonatomic) IBOutlet UISlider *intenSlider;

- (IBAction)doneAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
