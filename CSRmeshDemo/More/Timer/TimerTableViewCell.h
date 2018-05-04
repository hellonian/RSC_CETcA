//
//  TimerTableViewCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/2.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimerEntity.h"

@interface TimerTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *fireTimeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *enabledSwitch;
@property (weak, nonatomic) IBOutlet UILabel *repeatLabel;
@property (nonatomic,strong) TimerEntity *timerEntity;

- (void)configureCellWithInfo:(TimerEntity *)timerEntity;

@end
