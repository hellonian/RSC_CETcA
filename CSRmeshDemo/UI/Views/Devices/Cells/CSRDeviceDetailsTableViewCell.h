//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>

extern NSString * const CSRDeviceDetailTableViewCellIdentifier;

@interface CSRDeviceDetailsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *batteryStaticLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryDynamicLabel;


@property (weak, nonatomic) IBOutlet UILabel *firmwareStaticLabel;
@property (weak, nonatomic) IBOutlet UILabel *firmwareDynamicLabel;




@end
