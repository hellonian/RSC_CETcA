//
//  SingleBtnCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/11/25.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConfiguredDeviceListController.h"


@protocol SingleRemoteCellDelegate <NSObject>
- (void)pushToDeviceListSingle:(ConfiguredDeviceListController *)list;
- (void)showHudSingle;
- (void)deleteRemoteTappedSingle:(NSNumber *)deviceId;
@end

@interface SingleBtnCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *remoteName;
@property (nonatomic,strong) NSNumber *myDeviceId;
@property (nonatomic,weak) id<SingleRemoteCellDelegate> delegate;

@end
