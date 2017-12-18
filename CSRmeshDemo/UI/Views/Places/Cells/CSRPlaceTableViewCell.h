//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>

extern NSString * const CSRPlaceTableViewCellIdentifier;

@interface CSRPlaceTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *placeIcon;
@property (weak, nonatomic) IBOutlet UIImageView *currentPlaceIndicator;
@property (weak, nonatomic) IBOutlet UILabel *placeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *placeOwnerNameLabel;

@end
