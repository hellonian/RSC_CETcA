//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>

extern NSString * const CSRActivitiesTableViewCellIdentifier;
@interface CSRActivitiesTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *activityImageView;
@property (nonatomic, weak) IBOutlet UILabel *activityNameLabel;

@end
