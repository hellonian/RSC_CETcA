//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSRLightWhiteVC.h"
#import "CSRDevicesManager.h"

@interface CSRLightWhiteVC ()

@end

@implementation CSRLightWhiteVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)doneAction:(id)sender {
    
//   CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:_deviceId];
    
    [[CSRDevicesManager sharedInstance] setWhite:_deviceId level:@(_intenSlider.value * 255) duration:@0];
    NSLog(@"value :%f", _intenSlider.value * 255);
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
