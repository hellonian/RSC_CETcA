//
//  TimerCell.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/6.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "TimerCell.h"
#import "DataModelManager.h"

@implementation TimerCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
}

- (void)configureCellWithInfo:(TimeSchedule *)schedule {
    self.deviceId = schedule.deviceId;
    self.index = schedule.timerIndex;
    
    if ([schedule.eveType isEqualToString:@"10"]) {
        self.onoffLabel.text = @"ON";
        self.levelLabel.hidden = YES;
    }else if ([schedule.eveType isEqualToString:@"11"]){
        self.onoffLabel.text = @"OFF";
        self.levelLabel.hidden = YES;
    }else {
        self.onoffLabel.text = @"ON";
        self.levelLabel.hidden = NO;
        self.levelLabel.text = [NSString stringWithFormat:@"%.f%%",schedule.level/255.0*100];
    }
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"HH:mm"];
    NSString *timeStr = [timeFormatter stringFromDate:schedule.fireDate];
    self.fireDateLabel.text = timeStr;
    
    NSString *repeatStr = schedule.repeat;
    if ([repeatStr isEqualToString:@"01111111"]) {
        self.repeatLabel.text = @"everyday";
    }else if ([repeatStr isEqualToString:@"01000001"]) {
        self.repeatLabel.text = @"every weekend";
    }else if ([repeatStr isEqualToString:@"00111110"]) {
        self.repeatLabel.text = @"every weekday";
    }else if ([repeatStr isEqualToString:@"00000000"]) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy/MM/dd"];
        NSString *dateStr = [dateFormatter stringFromDate:schedule.fireDate];
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
    
    if (schedule.state) {
        [self.enSwitch setOn:YES];
        self.fireDateLabel.textColor = [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1];
    }else {
        [self.enSwitch setOn:NO];
        self.fireDateLabel.textColor = [UIColor lightGrayColor];
    }
    
}
- (IBAction)changeAlarmState:(UISwitch *)sender {
    self.fireDateLabel.textColor = sender.on? [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1]:[UIColor lightGrayColor];
    [[DataModelManager shareInstance] enAlarmForDevice:self.deviceId stata:sender.on index:self.index];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
