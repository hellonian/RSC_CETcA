//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSREventsOnOffVC.h"

@interface CSREventsOnOffVC ()

@end

@implementation CSREventsOnOffVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)eventOffAction:(id)sender {
    
    NSDictionary* userInfo = @{@"eventStatus": @(NO)};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventActivation" object:self userInfo:userInfo];

}

- (IBAction)eventOnAction:(id)sender {
    
    NSDictionary* userInfo = @{@"eventStatus": @(YES)};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventActivation" object:self userInfo:userInfo];

}
@end
