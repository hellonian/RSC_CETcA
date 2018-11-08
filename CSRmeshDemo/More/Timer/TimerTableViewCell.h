//
//  TimerTableViewCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/2.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimerEntity.h"

@interface TimerTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *fireTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *repeatLabel;
@property (nonatomic,strong) TimerEntity *timerEntity;

- (void)configureCellWithInfo:(TimerEntity *)timerEntity;

@end
