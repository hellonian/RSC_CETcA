//
//  TimerTableViewCell.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/2.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimerEntity.h"

@protocol TimerTableViewCellDelegate <NSObject>

- (void)timercellChangeEnabled:(BOOL)enabled row:(NSInteger)row;

@end

@interface TimerTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *fireTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *repeatLabel;
@property (weak, nonatomic) IBOutlet UISwitch *enableSwitch;
@property (nonatomic,strong) TimerEntity *timerEntity;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, weak) id <TimerTableViewCellDelegate> cellDelegate;

- (void)configureCellWithInfo:(TimerEntity *)timerEntity row:(NSInteger)row;

@end
