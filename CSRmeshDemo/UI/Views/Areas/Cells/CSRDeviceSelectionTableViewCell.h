//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>

extern NSString * const CSRDeviceSelectionTableViewCellIdentifier;

@interface CSRDeviceSelectionTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *deviceIcon;

@end
