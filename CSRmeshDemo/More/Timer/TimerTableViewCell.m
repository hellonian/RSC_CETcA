//
//  TimerTableViewCell.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/2.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "TimerTableViewCell.h"

@implementation TimerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)configureCellWithInfo:(TimerEntity *)timerEntity {
    self.nameLabel.text = timerEntity.name;
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"HH:mm"];
    NSString *timeStr = [timeFormatter stringFromDate:timerEntity.fireTime];
    self.fireTimeLabel.text = timeStr;
    
    NSString *repeatStr = timerEntity.repeat;
    NSLog(@"repeat %@",repeatStr);
    if ([repeatStr isEqualToString:@"01111111"]) {
        self.repeatLabel.text = @"everyday";
    }else if ([repeatStr isEqualToString:@"01000001"]) {
        self.repeatLabel.text = @"every weekend";
    }else if ([repeatStr isEqualToString:@"00111110"]) {
        self.repeatLabel.text = @"every weekday";
    }else if ([repeatStr integerValue] == 0) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy/MM/dd"];
        NSString *dateStr = [dateFormatter stringFromDate:timerEntity.fireDate];
        self.repeatLabel.text = dateStr;
    }else {
        NSArray *weekArr = @[@"Sun",@"Mon",@"Tue",@"Wed",@"Thu",@"Fri",@"Sat"];
        NSString *weekStr = @"";
        for (int i=7; i>0; i--) {
            NSString *perStr = [repeatStr substringWithRange:NSMakeRange(i, 1)];
            if ([perStr isEqualToString:@"1"]) {
                weekStr = [NSString stringWithFormat:@"%@ %@",weekStr,weekArr[7-i]];
            }
        }
        self.repeatLabel.text = weekStr;
    }
    
    BOOL enabled = [timerEntity.enabled boolValue]? YES:NO;
    [self.enabledSwitch setOn:enabled];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
