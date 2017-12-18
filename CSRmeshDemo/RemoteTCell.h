//
//  RemoteTCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/10/7.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConfiguredDeviceListController.h"

@protocol RemoteTCellDelegate <NSObject>
- (void)pushToDeviceList:(ConfiguredDeviceListController *)list;
- (void)showHud;
- (void)deleteRemoteTapped:(NSNumber *)deviceId;
@end

@interface RemoteTCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *remoteName;
@property (nonatomic,strong) NSNumber *myDeviceId;
@property (nonatomic,weak) id<RemoteTCellDelegate> delegate;

@end
