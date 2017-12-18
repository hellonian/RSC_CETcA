//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>

extern NSString * const CSREventsTableViewCellIdentifier;

@interface CSREventsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *eventImageView;
@property (weak, nonatomic) IBOutlet UILabel *eventNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventDetailLabel;
@property (weak, nonatomic) IBOutlet UISwitch *onOffSwitch;

- (IBAction)switchAction:(id)sender;

@end
