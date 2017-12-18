//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>

extern NSString * const CSRAreaTableViewCellIdentifier;
@interface CSRAreaTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *areaNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfAreasLabel;


@end
