//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRMainViewController.h"
#import "CSRmeshDevice.h"
#import "CSRmeshArea.h"
#import "CSRmeshDevice.h"
#import "CSRLightRGBVC.h"

@interface CSRLightViewController : CSRMainViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIPopoverPresentationControllerDelegate, CSRLightColorDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *colorWheel;
@property (weak, nonatomic) IBOutlet UISlider *intensitySlider;
@property (weak, nonatomic) IBOutlet UISwitch *powerSwitch;

//@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *tapGesture;
//@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *panGesture;

@property (weak, nonatomic) IBOutlet UIImageView *colorIndicator;
@property (nonatomic) UIBarButtonItem *backButton;
@property (nonatomic) CSRmeshDevice *lightDevice;
@property (nonatomic) CSRmeshArea *selectedArea;

//Collection view and latest Layout outlets
@property (weak, nonatomic) IBOutlet UIButton *selectedColorButton;
@property (weak, nonatomic) IBOutlet UICollectionView *lightCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *rgbValuesButton;

- (IBAction)getRGBValuesButtonAction:(id)sender;
- (IBAction)whiteIntensityButtonAction:(id)sender;

- (IBAction)dragColor:(id)sender;
- (IBAction)tapColor:(id)sender;
- (IBAction)intensitySliderDragged:(id)sender;
- (IBAction)powerSwitchChanged:(id)sender;
- (void)updateColorIndicatorPosition:(CGPoint)position;

//Testing
//@property (nonatomic, strong) UIColor *chosenColor;

@end
