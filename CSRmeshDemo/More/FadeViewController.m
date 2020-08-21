//
//  FadeViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/8/11.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "FadeViewController.h"
#import "DataModelManager.h"

@interface FadeViewController ()

@property (weak, nonatomic) IBOutlet UILabel *fadeTimeSwitchLabel;
@property (weak, nonatomic) IBOutlet UILabel *fadeTimeDimmingLabel;
@property (weak, nonatomic) IBOutlet UISlider *fadeTimeSwitchSlider;
@property (weak, nonatomic) IBOutlet UISlider *fadeTimeDimmingSlider;

@end

@implementation FadeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"controlOptions", @"Localizable");
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction)];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
    self.navigationItem.leftBarButtonItem = cancel;
    self.navigationItem.rightBarButtonItem = done;
    
    NSNumber *fadeTimeSwitch = [[NSUserDefaults standardUserDefaults] objectForKey:FadeTimeSwitch];
    if (fadeTimeSwitch) {
        [_fadeTimeSwitchSlider setValue:[fadeTimeSwitch integerValue]];
        [_fadeTimeSwitchLabel setText:[NSString stringWithFormat:@"%.1f s", [fadeTimeSwitch integerValue] * 0.1]];
    }
    NSNumber *fadeTimeDimming = [[NSUserDefaults standardUserDefaults] objectForKey:FadeTimeDimming];
    if (fadeTimeDimming) {
        [_fadeTimeDimmingSlider setValue:[fadeTimeDimming integerValue]];
        [_fadeTimeDimmingLabel setText:[NSString stringWithFormat:@"%.1f s", [fadeTimeDimming integerValue] * 0.1]];
    }
    
    
}

- (void)cancelAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doneAction {
    NSInteger fadeTimeSwitch = (NSInteger)(_fadeTimeSwitchSlider.value);
    [[NSUserDefaults standardUserDefaults] setObject:@(fadeTimeSwitch) forKey:FadeTimeSwitch];
    NSInteger fadeTimeDimming = (NSInteger)(_fadeTimeDimmingSlider.value);
    [[NSUserDefaults standardUserDefaults] setObject:@(fadeTimeDimming) forKey:FadeTimeDimming];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    Byte sbyte[] = {0xea, 0x55, 0xff, fadeTimeSwitch};
    NSData *scmd = [[NSData alloc] initWithBytes:sbyte length:4];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:@0 data:scmd];
    [NSThread sleepForTimeInterval:0.3];
    Byte bbyte[] = {0xea, 0x57, 0xff, fadeTimeDimming};
    NSData *dcmd = [[NSData alloc] initWithBytes:bbyte length:4];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:@0 data:dcmd];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)fadeTimeSwitchValueChanged:(UISlider *)sender {
    NSInteger v = sender.value;
    [_fadeTimeSwitchLabel setText:[NSString stringWithFormat:@"%.1f s", v * 0.1]];
}

- (IBAction)fadeTimeDimmingValueChanged:(UISlider *)sender {
    NSInteger v = sender.value;
    [_fadeTimeDimmingLabel setText:[NSString stringWithFormat:@"%.1f s", v * 0.1]];
}

- (IBAction)fadeTimeAdjust:(UIButton *)sender {
    if (sender.tag == 1) {
        NSInteger v = _fadeTimeSwitchSlider.value;
        if (v > 5) {
            [_fadeTimeSwitchSlider setValue:(v - 1)];
            [_fadeTimeSwitchLabel setText:[NSString stringWithFormat:@"%.1f s", (v - 1) * 0.1]];
        }
    }else if (sender.tag == 2) {
        NSInteger v = _fadeTimeSwitchSlider.value;
        if (v < 30) {
            [_fadeTimeSwitchSlider setValue:(v + 1)];
            [_fadeTimeSwitchLabel setText:[NSString stringWithFormat:@"%.1f s", (v + 1) * 0.1]];
        }
    }else if (sender.tag == 3) {
        NSInteger v = _fadeTimeDimmingSlider.value;
        if (v > 30) {
            [_fadeTimeDimmingSlider setValue:(v - 1)];
            [_fadeTimeDimmingLabel setText:[NSString stringWithFormat:@"%.1f s", (v - 1) * 0.1]];
        }
    }else if (sender.tag == 4) {
        NSInteger v = _fadeTimeDimmingSlider.value;
        if (v < 200) {
            [_fadeTimeDimmingSlider setValue:(v + 1)];
            [_fadeTimeDimmingLabel setText:[NSString stringWithFormat:@"%.1f s", (v + 1) * 0.1]];
        }
    }
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
