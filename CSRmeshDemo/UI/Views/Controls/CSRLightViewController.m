//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import "CSRLightViewController.h"
#import "CSRmeshStyleKit.h"
#import "CSRUtilities.h"
#import "CSRConstants.h"
#import "CSRDevicesManager.h"
#import "CSRLightColorCollectionCell.h"
#import "CSRLightRGBVC.h"
#import "CSRLightWhiteVC.h"

@interface CSRLightViewController ()
{
    CGFloat intensityLevel;
    CGPoint lastPosition;
    UIColor *chosenColor;
}

@end

@implementation CSRLightViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
    [self.navigationController.interactivePopGestureRecognizer setEnabled:YES];
    
    _selectedArea = [[CSRDevicesManager sharedInstance] selectedArea];
    _lightDevice = [[CSRDevicesManager sharedInstance] selectedDevice];

    
    //Adjust navigation controller appearance
    self.showNavMenuButton = NO;
    self.showNavSearchButton = NO;
    
    [super adjustNavigationControllerAppearance];
    
    //Set navigation buttons
    _backButton = [[UIBarButtonItem alloc] init];
    _backButton.image = [CSRmeshStyleKit imageOfBack_arrow];
    _backButton.action = @selector(back:);
    _backButton.target = self;
    //Add accessibility for automation
    _backButton.isAccessibilityElement = YES;
    _backButton.accessibilityLabel = @"back";
    _backButton.accessibilityTraits = UIAccessibilityTraitImage;

    
    [super addCustomBackButtonItem:_backButton];
    
    //Set initial values
//    _tapGesture.numberOfTapsRequired = 1;
//    _tapGesture.numberOfTouchesRequired = 1;
    
    intensityLevel = 1.0;
    chosenColor = [UIColor whiteColor];
    lastPosition.x = 0;
    lastPosition.y = 0;
    
    _selectedColorButton.layer.cornerRadius = _selectedColorButton.bounds.size.width/2;
//    _selectedColorButton.backgroundColor = [UIColor lightGrayColor];
    _selectedColorButton.layer.borderWidth = 2;
    _selectedColorButton.layer.borderColor = [UIColor grayColor].CGColor;

    
    _lightCollectionView.delegate = self;
    _lightCollectionView.dataSource = self;
    
    UIImage* image = [UIImage imageNamed:@"ColourCircle"];
    CGImageRef cgimage = image.CGImage;
    NSLog(@"colorspace :%@", CGImageGetColorSpace(cgimage));
    
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];
    
//    _selectedArea = [[CSRDevicesManager sharedInstance] selectedArea];
//    _lightDevice = [[CSRDevicesManager sharedInstance] selectedDevice];
    
    //Set item titles
    if (_lightDevice) {
        self.title = _lightDevice.name;
    } else if (_selectedArea){
        self.title = _selectedArea.areaName;
    } else {
        self.title = @"CSRmesh";
    }
    
    //Get current device power status
    [_powerSwitch setOn:[_lightDevice getPower]];
    
    //Get current device color position/value
    if ([_lightDevice colorPosition] != nil) {
        
        CGPoint position = [_lightDevice.colorPosition CGPointValue];
        [self updateColorIndicatorPosition:position];
        
    }
    
    //Get current device intesinty level
    [_intensitySlider setValue:_lightDevice.getLevel animated:YES];
}

- (void)dealloc
{
    self.view = nil;
    _lightDevice = nil;
    _selectedArea = nil;
    [[CSRDevicesManager sharedInstance] setSelectedDevice:nil];
}

#pragma mark - Actions

- (IBAction)getRGBValuesButtonAction:(id)sender {
        
    [self performSegueWithIdentifier:@"setRGBSegue" sender:nil];
}

- (IBAction)whiteIntensityButtonAction:(id)sender {
    
    [self performSegueWithIdentifier:@"whiteSliderSegue" sender:nil];
}

- (IBAction)dragColor:(id)sender
{
    
    BOOL isDragAllowed = NO;
    
    if ([CSRMeshUserManager sharedInstance].bearerType == CSRBearerType_Bluetooth) {
        
        isDragAllowed = YES;
        
    }
    
    if (!isDragAllowed) {
        
        if ([(UIPanGestureRecognizer *)sender state] == UIGestureRecognizerStateBegan) {
            
            isDragAllowed = YES;
            
        } else if ([(UIPanGestureRecognizer *)sender state] == UIGestureRecognizerStateEnded) {
            
            isDragAllowed = YES;
            
        }
        
    }
    
    if (isDragAllowed) {
    
        UIPanGestureRecognizer *recogniser = sender;
        CGPoint touchPoint = [recogniser locationInView:_colorWheel.viewForBaselineLayout];
        
        float frameWidth = _colorWheel.viewForBaselineLayout.frame.size.width;
        float frameHeight = _colorWheel.viewForBaselineLayout.frame.size.height;
        
        if (touchPoint.x > frameWidth) {
            
            touchPoint.x = frameWidth;
            
        } else if (touchPoint.x < 0) {
            
            touchPoint.x = 0;
            
        }
        
        if (touchPoint.y > frameHeight) {
            
            touchPoint.y = frameHeight;
            
        } else if (touchPoint.y < 0) {
            
            touchPoint.y = 0;
            
        }
        
        
        UIColor *pixel = [CSRUtilities colorFromImageAtPoint:&touchPoint frameWidth:frameWidth frameHeight:frameHeight];
        
        CGFloat red, green, blue, alpha;
        if ([pixel getRed:&red green:&green blue:&blue alpha:&alpha] && !(red<0.4 && green<0.4 && blue<0.4)) {
            
            // Send Color to selected light
            if (_lightDevice) {
                
                [_lightDevice setColorWithRed:red green:green blue:blue];
                [_selectedColorButton setBackgroundColor:[UIColor colorWithRed:red green:green blue:blue alpha:1]];
                
            }
            
            
            chosenColor = pixel;
            
            // update position of inidicator
            touchPoint.x += _colorWheel.frame.origin.x;
            touchPoint.y += _colorWheel.frame.origin.y;
            [self updateColorIndicatorPosition:touchPoint];
            
            // Update the device's copy of the color position
            [_lightDevice setColorPosition:[NSValue valueWithCGPoint:touchPoint]];
            
            // Update power button from device
            // The device can turn on the power if the colour is set
            [_powerSwitch setOn:[_lightDevice getPower]];
        }
        
    }
    
}

- (IBAction)tapColor:(id)sender
{
    UITapGestureRecognizer *recogniser = sender;
    CGPoint touchPoint = [recogniser locationInView:_colorWheel.viewForBaselineLayout];
    
    float frameWidth = _colorWheel.viewForBaselineLayout.frame.size.width;
    float frameHeight = _colorWheel.viewForBaselineLayout.frame.size.height;
    
    UIColor *pixel = [CSRUtilities colorFromImageAtPoint:&touchPoint frameWidth:frameWidth frameHeight:frameHeight];
    
    CGFloat red, green, blue, alpha;
    if ([pixel getRed:&red green:&green blue:&blue alpha:&alpha] && !(red<0.4 && green<0.4 && blue<0.4)) {
        
        // Send Color to selected light
        if (_lightDevice) {
            [_lightDevice setColorWithRed:red green:green blue:blue];
            [_selectedColorButton setBackgroundColor:[UIColor colorWithRed:red green:green blue:blue alpha:1]];
        }
        
        chosenColor = pixel;
        
        // update position of inidicator
        touchPoint.x += _colorWheel.frame.origin.x;
        touchPoint.y += _colorWheel.frame.origin.y;
        
        [self updateColorIndicatorPosition:touchPoint];
        
        // Update the device's copy of the color position
        [_lightDevice setColorPosition:[NSValue valueWithCGPoint:touchPoint]];
        
        // Update power button from device
        // The device can turn on the power if the colour is set
        [_powerSwitch setOn:[_lightDevice getPower]];
        
        NSDictionary* userInfo = @{@"color": [UIColor colorWithRed:red green:green blue:blue alpha:1]};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"colorTapped" object:self userInfo:userInfo];
    }
    
}

- (IBAction)intensitySliderDragged:(id)sender
{
    
    BOOL isDragAllowed = NO;
    
    if ([CSRMeshUserManager sharedInstance].bearerType == CSRBearerType_Bluetooth) {
        
        isDragAllowed = YES;
        
    }
    
    if (!isDragAllowed) {
        
        if ([(UIPanGestureRecognizer *)sender state] == UIGestureRecognizerStateBegan) {
            
            isDragAllowed = YES;
            
        } else if ([(UIPanGestureRecognizer *)sender state] == UIGestureRecognizerStateEnded) {
            
            isDragAllowed = YES;
            
        }
        
    }
    
    if (isDragAllowed) {
    
        intensityLevel = _intensitySlider.value;
        
        if (_lightDevice) {
            [_lightDevice setLevel:intensityLevel];
            
            // Update power button from device
            // The device can turn on the power if the colour is set
            [_powerSwitch setOn:[_lightDevice getPower]];
        }
        
    }
    
}

- (IBAction)intensitySliderTapped:(id)sender
{
    UITapGestureRecognizer *recogniser = sender;
    CGPoint touchPoint = [recogniser locationInView:_intensitySlider.viewForBaselineLayout];
    
    intensityLevel = touchPoint.x / _intensitySlider.frame.size.width;
    
    [_intensitySlider setValue:intensityLevel animated:YES];
    
    if (_lightDevice) {
        [_lightDevice setLevel:intensityLevel];
        
        // Update power button from device
        // The device can turn on the power if the colour is set
        [_powerSwitch setOn:[_lightDevice getPower]];
    }
    NSDictionary* userInfo = @{@"intensity": @(intensityLevel)};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sliderTapped" object:self userInfo:userInfo];
}

- (IBAction)powerSwitchChanged:(id)sender
{
    if (_lightDevice) {
        [_lightDevice setPower:_powerSwitch.isOn];
    }
}

#pragma mark - Color indicator update

- (void)updateColorIndicatorPosition:(CGPoint)position
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [_colorIndicator setCenter:position];
    });
    
    [_colorIndicator setCenter:position];
    lastPosition = position;
}

#pragma mark - Pseudo Navigation Bar item menthods

- (IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"whiteSliderSegue"]) {
        CSRLightWhiteVC *vc = segue.destinationViewController;
        vc.popoverPresentationController.delegate = self;
        vc.popoverPresentationController.containerView.superview.layer.cornerRadius = 0;
        vc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20., 120.);
        
        vc.deviceId = _lightDevice.deviceId;
    }
    
    if ([segue.identifier isEqualToString:@"setRGBSegue"]) {
        
        CSRLightRGBVC *vc = segue.destinationViewController;
        vc.popoverPresentationController.delegate = self;
        vc.popoverPresentationController.containerView.superview.layer.cornerRadius = 0;
        vc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20., 200.);
        
        vc.lightDelegate = self;
        vc.deviceId = _lightDevice.deviceId;
    }
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return 5;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CSRLightColorCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CSRLightCellIdentifier forIndexPath:indexPath];
    
        cell.layer.cornerRadius = cell.bounds.size.width / 2;
        cell.layer.borderWidth = 2;
        cell.layer.borderColor = [UIColor grayColor].CGColor;
        
        //Drawing the image view on the cell for tint color
        UIImageView *brightnessImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, cell.frame.size.width - 20, cell.frame.size.height - 20)];
        brightnessImage.image= [CSRmeshStyleKit imageOfIconBrightness_full];
        [cell addSubview:brightnessImage];
    
        
        if (indexPath.row == 0) {
            brightnessImage.tintColor = [UIColor colorWithRed:255 green:0 blue:0 alpha:1];
        } else if (indexPath.row == 1) {
            brightnessImage.tintColor = [UIColor colorWithRed:255 green:255 blue:0 alpha:1];
        } else if (indexPath.row == 2) {
            brightnessImage.tintColor = [UIColor lightGrayColor];
        } else if (indexPath.row == 3) {
            brightnessImage.tintColor = [UIColor colorWithRed:0 green:255 blue:255 alpha:1];
        } else if (indexPath.row == 4) {
            brightnessImage.tintColor = [UIColor colorWithRed:0 green:0 blue:255 alpha:1];
        } else {
            brightnessImage.tintColor = [UIColor clearColor];
        }
    
    return cell;
}

#pragma mark <UICollectionViewDelegateFlowLayout>
//To make the second section move to center
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    
//        //TODO: hack to look good on iPad, need to be changed
//        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
//        {
//            return (UIEdgeInsetsMake(0, 60, 0, 60));
//        }
        return (UIEdgeInsetsMake(0, 22, 0, 22));
//    return UIEdgeInsetsZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
//    //TODO: hack to look good on iPad, need to be changed
//    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
//    {
//        return CGSizeMake(100, 100);
//    }
    
    return CGSizeMake(40, 40);
}


#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return TRUE;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        [[CSRDevicesManager sharedInstance] setColorTemperature:_lightDevice.deviceId temperature:@1 duration:@0];
    } else if (indexPath.row == 1) {
        [[CSRDevicesManager sharedInstance] setColorTemperature:_lightDevice.deviceId temperature:@1 duration:@0];
    } else if (indexPath.row == 2) {
        [[CSRDevicesManager sharedInstance] setColorTemperature:_lightDevice.deviceId temperature:@1 duration:@0];
    } else if (indexPath.row == 3) {
        [[CSRDevicesManager sharedInstance] setColorTemperature:_lightDevice.deviceId temperature:@1 duration:@0];
    } else if (indexPath.row == 4) {
        [[CSRDevicesManager sharedInstance] setColorTemperature:_lightDevice.deviceId temperature:@1 duration:@0];
    }
    
    [_powerSwitch setOn:[_lightDevice getPower]];
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // Return no adaptive presentation style, use default presentation behaviour
    return UIModalPresentationNone;
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return NO;
}

#pragma mark - <CSRLightColorDelegate>

- (void) selectedColor:(UIColor *)color {
    
    chosenColor = color;
//    [self updateColorIndicatorPosition:<#(CGPoint)#>];
    _selectedColorButton.backgroundColor = color;
}


@end
