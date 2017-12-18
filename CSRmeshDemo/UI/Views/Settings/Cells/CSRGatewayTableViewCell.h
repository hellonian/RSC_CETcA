//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>

extern NSString * const CSRGatewayTableViewCellIdentifier;

@interface CSRGatewayTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *gatewayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *gatewayIPLabel;



@end
