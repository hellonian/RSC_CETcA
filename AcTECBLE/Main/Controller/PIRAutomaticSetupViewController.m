//
//  PIRAutomaticSetupViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2021/3/3.
//  Copyright © 2021 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "PIRAutomaticSetupViewController.h"
#import "PIRDaylightSensorViewController.h"
#import "PIRAutomaticDetailViewController.h"

@interface PIRAutomaticSetupViewController ()

@end

@implementation PIRAutomaticSetupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"automation", @"Localizable");
}

- (IBAction)motionSensor:(id)sender {
    PIRAutomaticDetailViewController *dvc = [[PIRAutomaticDetailViewController alloc] init];
    dvc.deviceId = _deviceId;
    dvc.sourseNumber = 1;
    [self.navigationController pushViewController:dvc animated:YES];
}

- (IBAction)daylightSensor:(id)sender {
    PIRDaylightSensorViewController *dsvc = [[PIRDaylightSensorViewController alloc] init];
    dsvc.deviceId = _deviceId;
    [self.navigationController pushViewController:dsvc animated:YES];
}

- (IBAction)temperatureSensor:(id)sender {
    PIRAutomaticDetailViewController *dvc = [[PIRAutomaticDetailViewController alloc] init];
    dvc.deviceId = _deviceId;
    dvc.sourseNumber = 2;
    [self.navigationController pushViewController:dvc animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
