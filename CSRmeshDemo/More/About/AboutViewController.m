//
//  AboutViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/30.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "AboutViewController.h"

#import "DeviceModelManager.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"About";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)btn1:(id)sender {
    
    NSLog(@"%@",[DeviceModelManager sharedInstance].allDevices);
    
}
- (IBAction)btn2:(id)sender {
    NSArray *array = [DeviceModelManager sharedInstance].allDevices;
    
    [array enumerateObjectsUsingBlock:^(DeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@">>> %@ >>> %@",model.level,model.powerState);
    }];
    
}
- (IBAction)btn3:(id)sender {
    NSArray *array = [DeviceModelManager sharedInstance].allDevices;
    
    [array enumerateObjectsUsingBlock:^(DeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:model.deviceId withPowerState:@(![model.powerState boolValue])];
        
    }];
    
    
}
- (IBAction)btn4:(id)sender {
}
- (IBAction)btn5:(id)sender {
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
