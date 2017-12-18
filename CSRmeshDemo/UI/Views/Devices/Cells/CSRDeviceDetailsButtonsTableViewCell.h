//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>

extern NSString * const CSRDeviceDetailsButtonsTableViewCellIdentifier;

@interface CSRDeviceDetailsButtonsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *favouriteButton;
@property (weak, nonatomic) IBOutlet UIButton *attentionButton;
//@property (weak, nonatomic) IBOutlet UIButton *otauButton;

@property (weak, nonatomic) IBOutlet UILabel *attentionLabel;
//@property (weak, nonatomic) IBOutlet UILabel *otauLabel;


@end
