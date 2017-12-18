//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRMainViewController.h"
#import "CSREventTimeSelectorVC.h"
#import "CSRmesh/ActionModelApi.h"

@interface CSRNewEventCreationViewController : CSRMainViewController <UIScrollViewDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIPopoverPresentationControllerDelegate, CSREventTimesDelegate> {
    int pageNumber;
}

@property (nonatomic) NSMutableArray *selectedIndexes;

@property (weak, nonatomic) IBOutlet UIScrollView *eventCreationScrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *eventPageControl;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButon;

@property (strong, nonatomic) IBOutlet UIView *firstView;
@property (strong, nonatomic) IBOutlet UIView *secondView;
@property (strong, nonatomic) IBOutlet UIView *thirdView;
@property (strong, nonatomic) IBOutlet UIView *fourthView;

@property (weak, nonatomic) IBOutlet UITextField *eventNameTextField;
@property (weak, nonatomic) IBOutlet UIImageView *colorWheelView;
@property (weak, nonatomic) IBOutlet UIImageView *colorIndicatorView;
@property (weak, nonatomic) IBOutlet UITableView *devicesListTableView;
@property (weak, nonatomic) IBOutlet UITableView *timeTableView;

@property (weak, nonatomic) IBOutlet UIView *controlView;

@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *panGesture;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGesture;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *textFieldOutsideTap;

//Property values we get from other view controllers
@property (nonatomic) NSUInteger typeOfEvent;


- (IBAction)eventPageControlAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)backAction:(id)sender;
- (IBAction)nextAction:(id)sender;

- (IBAction)textFieldOutsideTapAction:(id)sender;

- (IBAction)panAction:(id)sender;
- (IBAction)tapAction:(id)sender;

@end
