//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>

extern NSString * const CSRGatewayDetailsTableCellIdentifier;

@interface CSRGatewayDetailsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *detailName;
@property (weak, nonatomic) IBOutlet UILabel *detailValue;

@end
