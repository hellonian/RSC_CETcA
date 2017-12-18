//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSREventControlVC.h"
#import "CSRTemperatureViewController.h"

@interface CSREventControlVC ()

@end

@implementation CSREventControlVC

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Loading the control View based on the type selected (which we get from previous view).
    if (_typeOfEvent == 1) {
        
        [self loadRequestedTypeView:@"LightViewController"];
        
    } else if (_typeOfEvent == 2) {
        
        UIStoryboard *eventsStoryBoard = [UIStoryboard storyboardWithName:@"Events" bundle:nil];
        UIViewController *controlViewController = (UIViewController *)[eventsStoryBoard instantiateViewControllerWithIdentifier:@"LightsOnOffViewController"];
        [self addChildViewController:controlViewController];
        controlViewController.view.frame = CGRectMake(0, 0, _containerView.frame.size.width, _containerView.frame.size.height);
        [_containerView addSubview:controlViewController.view];
        [controlViewController didMoveToParentViewController:self];
        
    } else if (_typeOfEvent == 3) {
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        CSRTemperatureViewController *controlViewController = (CSRTemperatureViewController *)[mainStoryBoard instantiateViewControllerWithIdentifier:@"TemperatureViewController"];
        controlViewController.actualTemperatureLabel.hidden = YES;
        [self addChildViewController:controlViewController];
        controlViewController.view.frame = CGRectMake(0, 0, _containerView.frame.size.width, _containerView.frame.size.height);
        [_containerView addSubview:controlViewController.view];
        [controlViewController didMoveToParentViewController:self];
        
    }
}

- (void) loadRequestedTypeView:(NSString*)viewControllerIdentifier
{
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *controlViewController = (UIViewController *)[mainStoryBoard instantiateViewControllerWithIdentifier:viewControllerIdentifier];
    [self addChildViewController:controlViewController];
    controlViewController.view.frame = CGRectMake(0, 0, _containerView.frame.size.width, _containerView.frame.size.height);
    [_containerView addSubview:controlViewController.view];
    [controlViewController didMoveToParentViewController:self];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
