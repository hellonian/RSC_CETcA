//
//  TimerTableViewCell.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/2.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "TimerTableViewCell.h"
#import "TimerDeviceEntity.h"
#import "DataModelManager.h"
#import "CSRDatabaseManager.h"

@implementation TimerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)configureCellWithInfo:(TimerEntity *)timerEntity row:(NSInteger)row{
    self.timerEntity = timerEntity;
    _row = row;
    self.nameLabel.text = timerEntity.name;
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"HH:mm"];
    NSString *timeStr = [timeFormatter stringFromDate:timerEntity.fireTime];
    self.fireTimeLabel.text = timeStr;
    
    NSString *repeatStr = timerEntity.repeat;
    if ([repeatStr isEqualToString:@"01111111"]) {
        self.repeatLabel.text = AcTECLocalizedStringFromTable(@"Everyday", @"Localizable");
    }else if ([repeatStr isEqualToString:@"01000001"]) {
        self.repeatLabel.text = AcTECLocalizedStringFromTable(@"EveryWeekend", @"Localizable");
    }else if ([repeatStr isEqualToString:@"00111110"]) {
        self.repeatLabel.text = AcTECLocalizedStringFromTable(@"EveryWeekday", @"Localizable");
    }else if ([repeatStr integerValue] == 0) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy/MM/dd"];
        NSString *dateStr = [dateFormatter stringFromDate:timerEntity.fireDate];
        self.repeatLabel.text = dateStr;
    }else {
        NSArray *weekArr = @[AcTECLocalizedStringFromTable(@"Sun", @"Localizable"),
                             AcTECLocalizedStringFromTable(@"Mon", @"Localizable"),
                             AcTECLocalizedStringFromTable(@"Tue", @"Localizable"),
                             AcTECLocalizedStringFromTable(@"Wed", @"Localizable"),
                             AcTECLocalizedStringFromTable(@"Thu", @"Localizable"),
                             AcTECLocalizedStringFromTable(@"Fri", @"Localizable"),
                             AcTECLocalizedStringFromTable(@"Sat", @"Localizable")];
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
    [_enableSwitch setOn:enabled];
    if (enabled) {
        self.nameLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        self.fireTimeLabel.textColor = [UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1];
        self.repeatLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
    }else {
        self.nameLabel.textColor = [UIColor colorWithRed:180/255.0 green:180/255.0 blue:180/255.0 alpha:1];
        self.fireTimeLabel.textColor = [UIColor colorWithRed:140/255.0 green:140/255.0 blue:140/255.0 alpha:1];
        self.repeatLabel.textColor = [UIColor colorWithRed:180/255.0 green:180/255.0 blue:180/255.0 alpha:1];
    }
    
}

- (IBAction)changeEnabled:(UISwitch *)sender {
    if (self.cellDelegate && [self.cellDelegate respondsToSelector:@selector(timercellChangeEnabled:row:)]) {
        [self.cellDelegate timercellChangeEnabled:sender.on row:_row];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
