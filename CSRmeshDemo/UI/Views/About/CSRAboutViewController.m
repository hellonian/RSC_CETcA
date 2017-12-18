//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRAboutViewController.h"
#import "CSRmeshStyleKit.h"

@interface CSRAboutViewController ()

@end

@implementation CSRAboutViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set image on back button
    _backButton.backgroundColor = [UIColor clearColor];
    [_backButton setBackgroundImage:[CSRmeshStyleKit imageOfBack_arrow] forState:UIControlStateNormal];
    [_backButton addTarget:self action:(@selector(back:)) forControlEvents:UIControlEventTouchUpInside];
    
    //Set app version
    _appVersionLabel.text = [NSString stringWithFormat:@"App version %@ (%@)", [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"], [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"]];
    _buildNumber.text = [NSString stringWithFormat:@"Build Number :%@", [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
