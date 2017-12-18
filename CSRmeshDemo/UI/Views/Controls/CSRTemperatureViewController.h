//
// Copyright 2014 - 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRmeshDevice.h"
#import "CSRmeshArea.h"
#import "CSRMainViewController.h"

@interface CSRTemperatureViewController : CSRMainViewController

@property (weak, atomic) CSRmeshDevice *selectedDevice;
@property (weak, atomic) CSRmeshArea *selectedArea;

@property (weak, nonatomic) IBOutlet UILabel *actualTemperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *desiredTemperatureLabel;

@property (weak, nonatomic) IBOutlet UILabel *desiredTemperatureText;

@property (weak, nonatomic) IBOutlet UIView *circleView;
@property (weak, nonatomic) IBOutlet UIButton *upButton;
@property (weak, nonatomic) IBOutlet UIButton *downButton;
@property (weak, nonatomic) IBOutlet UISwitch *onOffSwitch;

@property (nonatomic) UIBarButtonItem *backButton;

- (IBAction)increaseTemperature:(id)sender;
- (IBAction)decreaseTemperature:(id)sender;
//- (IBAction)getSensorValueAction:(id)sender;

@end