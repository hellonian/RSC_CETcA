//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRMainViewController.h"
#import "CSRLightViewController.h"
#import "CSRTemperatureViewController.h"
#import "CSRLockViewController.h"
#import "CSRAreaEntity.h"
#import "CSRDeviceEntity.h"

@interface CSRSegmentDevicesViewController : CSRMainViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentSwitch;

@property (nonatomic, retain) CSRAreaEntity *areaEntity;
@property (nonatomic, retain) CSRDeviceEntity *deviceEntity;

@property (nonatomic, retain) NSMutableArray *devicesMutableArray;

@property (weak, nonatomic) IBOutlet UIView *controlView;
@property (nonatomic) CSRLightViewController *lightViewController;
@property (nonatomic) CSRTemperatureViewController *temperatureViewController;
@property (nonatomic) CSRLockViewController *lockViewController;

- (IBAction)segmentSwitchAction:(UISegmentedControl*)sender;
- (IBAction)backForSelf:(id)sender;

@end
