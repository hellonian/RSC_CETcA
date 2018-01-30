//
//  DeviceViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/25.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "DeviceViewController.h"
#import "DeviceModelManager.h"

@interface DeviceViewController ()

@property (weak, nonatomic) IBOutlet UITextField *nameTF;
@property (weak, nonatomic) IBOutlet UISwitch *powerStateSwitch;
@property (weak, nonatomic) IBOutlet UISlider *levelSlider;
@property (weak, nonatomic) IBOutlet UILabel *levelLabel;
@property (nonatomic,assign) BOOL sliderIsMoving;
@property (nonatomic,strong) DeviceModel *device;

@end

@implementation DeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeAction)];
        self.navigationItem.rightBarButtonItem = done;
    }
    
    if (_deviceId) {
        _device = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        if ([_device.shortName isEqualToString:@"S350BT"]) {
            [self.levelSlider setEnabled:NO];
        }
        
        self.navigationItem.title = _device.name;
        self.nameTF.text = _device.name;
        self.powerStateSwitch.on = [_device.powerState boolValue];
        self.sliderIsMoving = NO;
        [self powerSwitchAndLevelSlider:_device.shortName powerState:_device.powerState level:_device.level];
        
        
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setPowerStateSuccess:)
                                                 name:@"setPowerStateSuccess"
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"setPowerStateSuccess"
                                                  object:nil];
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)powerSwitchAndLevelSlider:(NSString *)kindString powerState:(NSNumber *)power level:(NSNumber *)level {
    if ([kindString isEqualToString:@"S350BT"]) {
        if ([power boolValue]) {
            [self.powerStateSwitch setOn:YES];
            [self.levelSlider setValue:255];
            self.levelLabel.text = @"100%";
        }else {
            [self.powerStateSwitch setOn:NO];
            [self.levelSlider setValue:0];
            self.levelLabel.text = @"0%";
        }
    }
    else {
        if ([power boolValue]) {
            [self.powerStateSwitch setOn:YES];
            if (!_sliderIsMoving) {
                [self.levelSlider setValue:[level integerValue]];
            }
            self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",[level integerValue]/255.0*100];
        }else {
            [self.powerStateSwitch setOn:NO];
            [self.levelSlider setValue:0];
            self.levelLabel.text = @"0%";
        }
    }
    
}

- (void)setPowerStateSuccess:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        [self powerSwitchAndLevelSlider:_device.shortName powerState:_device.powerState level:_device.level];
    }
}

- (IBAction)powerStateSwitch:(UISwitch *)sender {
    _sliderIsMoving = NO;
    [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:_deviceId withPowerState:@(sender.on)];
}

- (IBAction)levelSliderTouchUpInSide:(UISlider *)sender {
    [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId withLevel:@(sender.value) withState:UIGestureRecognizerStateEnded];
}

- (IBAction)leveSliderValueChanged:(UISlider *)sender {
    [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId withLevel:@(sender.value) withState:UIGestureRecognizerStateChanged];
}

- (IBAction)levelSliderTouchDown:(UISlider *)sender {
    _sliderIsMoving = YES;
    [[DeviceModelManager sharedInstance] setLevelWithDeviceId:_deviceId withLevel:@(sender.value) withState:UIGestureRecognizerStateBegan];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
