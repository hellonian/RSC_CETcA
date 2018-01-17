//
//  TimerCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/6.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimeSchedule.h"

@interface TimerCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *onoffLabel;
@property (weak, nonatomic) IBOutlet UILabel *levelLabel;
@property (weak, nonatomic) IBOutlet UILabel *fireDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *repeatLabel;
@property (weak, nonatomic) IBOutlet UISwitch *enSwitch;
@property (nonatomic,strong) NSNumber *deviceId;
@property (nonatomic,assign) NSInteger index;
- (void)configureCellWithInfo:(TimeSchedule *)schedule;

@end
