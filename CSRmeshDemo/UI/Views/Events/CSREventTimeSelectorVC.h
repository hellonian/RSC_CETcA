//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRMainViewController.h"

@protocol CSREventTimesDelegate <NSObject>

- (void) repeatEverySeconds:(NSNumber *)seconds ofDays:(NSData *)data;

@end


@interface CSREventTimeSelectorVC : CSRMainViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate>

@property (assign, nonatomic) id<CSREventTimesDelegate> eventsDelegate;

@property (weak, nonatomic) IBOutlet UIView *hourlyView;
@property (weak, nonatomic) IBOutlet UIView *dailyView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *hourlyDailySegmentControl;

@property (weak, nonatomic) IBOutlet UICollectionView *weekDaysCollectionView;
@property (weak, nonatomic) IBOutlet UITextField *hourlyTextField;

- (IBAction)segmentValueChanged:(id)sender;

- (IBAction)cancelAction:(id)sender;
- (IBAction)doneAction:(id)sender;

@end
