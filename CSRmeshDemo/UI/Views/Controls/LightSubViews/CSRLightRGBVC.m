//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSRLightRGBVC.h"
#import "CSRDevicesManager.h"
#import "CSRUtilities.h"

@interface CSRLightRGBVC ()

@end

@implementation CSRLightRGBVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _redTextField.delegate = self;
    _greenTextField.delegate = self;
    _blueTextField.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)doneAction:(id)sender {
    
    //TODO: also add the logic, so that the user can enter RGB values in float and Hex...:)
    
    NSString *fullHexString = [NSString stringWithFormat:@"%@%@%@", _redTextField.text, _greenTextField.text, _blueTextField.text];
    UIColor *hexColor = [CSRUtilities colorFromHex:fullHexString];
    
//    CGFloat redFloat = (CGFloat)[_redTextField.text floatValue];
//    CGFloat greenFloat = (CGFloat)[_greenTextField.text floatValue];
//    CGFloat blueFloat = (CGFloat)[_blueTextField.text floatValue];
    
    //update in superview
//    UIColor *inputValuesColor = [UIColor colorWithRed:redFloat green:greenFloat blue:blueFloat alpha:1.];
    [_lightDelegate selectedColor:hexColor];
    
    //call the API
    [[CSRDevicesManager sharedInstance] setColor:_deviceId color:hexColor duration:@0];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
