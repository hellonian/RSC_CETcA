//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>

extern NSString * const CSRNewDeviceTableViewCellIdentifier;

@interface CSRNewDeviceTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceUUIDLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *deviceActivityIndicator;

@end
