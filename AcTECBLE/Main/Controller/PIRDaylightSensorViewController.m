//
//  PIRDaylightSensorViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2021/3/4.
//  Copyright © 2021 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "PIRDaylightSensorViewController.h"
#import "DataModelManager.h"

@interface PIRDaylightSensorViewController ()

@property (weak, nonatomic) IBOutlet UILabel *calibrateLabel;
@property (weak, nonatomic) IBOutlet UILabel *sensitivityLabel;
@property (weak, nonatomic) IBOutlet UILabel *toleranceLabel;

@end

@implementation PIRDaylightSensorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"daylight_sensor", @"Localizable");
}

- (IBAction)calibration:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    NSMutableAttributedString *hogan = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"calibration", @"Localizable")];
    [hogan addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1] range:NSMakeRange(0, [[hogan string] length])];
    [alert setValue:hogan forKey:@"attributedTitle"];
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"enter_lux", @"Localizable")];
    [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
    [attributedMessage addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12] range:NSMakeRange(0, [[attributedMessage string] length])];
    [alert setValue:attributedMessage forKey:@"attributedMessage"];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"calibrate", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alert.textFields.firstObject;
        if ([textField.text length] > 0 && [textField.text integerValue] >= 0 && [textField.text integerValue] <= 2000) {
            _calibrateLabel.text = [NSString stringWithFormat:@"%@ LUX",textField.text];
            NSInteger lux = [textField.text integerValue];
            NSInteger h = (lux & 0xFF00) >> 8;
            NSInteger l = lux & 0x00FF;
            Byte byte[] = {0xea, 0x88, 0x08, 0x02, l, h};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }
    }];
    [alert addAction:cancel];
    [alert addAction:confirm];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textAlignment = NSTextAlignmentCenter;
        textField.placeholder = AcTECLocalizedStringFromTable(@"enter_number_0_2000", @"Localizable");
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)sensitivitySet:(UISlider *)sender {
    NSInteger sen = sender.value;
    _sensitivityLabel.text = [NSString stringWithFormat:@"%ld %%", (long)sen];
    Byte byte[] = {0xea, 0x88, 0x03, 0x02, sen, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}
- (IBAction)sensitivityValueChanged:(UISlider *)sender {
    NSInteger sen = sender.value;
    _sensitivityLabel.text = [NSString stringWithFormat:@"%ld %%", (long)sen];
}

- (IBAction)toleranceSet:(UISlider *)sender {
    NSInteger sen = sender.value;
    _toleranceLabel.text = [NSString stringWithFormat:@"%ld %%", (long)sen];
    Byte byte[] = {0xea, 0x88, 0x04, 0x02, sen, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:6];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}
- (IBAction)toleranceValueChanged:(UISlider *)sender {
    NSInteger sen = sender.value;
    _toleranceLabel.text = [NSString stringWithFormat:@"%ld %%", (long)sen];
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
