//
//  SocketPowerCell.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/1/7.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SocketPowerCell.h"
#import "powerModel.h"
#import "PureLayout.h"

@implementation SocketPowerCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)configureCellWithiInfo:(id)info maxPowerValue:(CGFloat)maxPowerValue {
    if ([info isKindOfClass:[NSNumber class]]) {
        self.histogramView.hidden = YES;
        self.dateLabel.text = @"";
        return;
    }
    if ([info isKindOfClass:[PowerModel class]]) {
        self.histogramView.hidden = NO;
        PowerModel *p = (PowerModel  *)info;
        if (p.selected) {
            self.histogramView.backgroundColor = [UIColor whiteColor];
            self.dateLabel.textColor = DARKORAGE;
        }else {
            self.histogramView.backgroundColor = [UIColor colorWithRed:234/255.0 green:143/255.0 blue:94/255.0 alpha:1];
            self.dateLabel.textColor = [UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1];
        }
        if (maxPowerValue*p.power) {
            self.hisViewHeight.constant = self.bounds.size.height/maxPowerValue*p.power;
        }else {
            self.hisViewHeight.constant = 0;
        }
        
        switch (p.kindInt) {
            case 4:
            {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"dd/MM"];
                if ([[formatter stringFromDate:p.powerDate] isEqualToString:[formatter stringFromDate:[NSDate date]]]) {
                    self.dateLabel.text = AcTECLocalizedStringFromTable(@"today", @"Localizable");
                }else {
                    self.dateLabel.text = [formatter stringFromDate:p.powerDate];
                }
            }
                break;
            case 3:
            {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"dd/MM"];
                if ([[formatter stringFromDate:p.powerDate] isEqualToString:[formatter stringFromDate:[NSDate date]]]) {
                    self.dateLabel.text = AcTECLocalizedStringFromTable(@"thisWeek", @"Localizable");
                }else {
                    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *weekdayComponents = [gregorian components:NSCalendarUnitWeekday fromDate:p.powerDate];
                    NSInteger week = [weekdayComponents weekday];
                    NSDateComponents *sDateComponents = [[NSDateComponents alloc] init];
                    [sDateComponents setDay:-(week-1)];
                    NSDate *startDate = [gregorian dateByAddingComponents:sDateComponents toDate:p.powerDate options:0];
                    NSDateComponents *eDateComponents = [[NSDateComponents alloc] init];
                    [eDateComponents setDay:7-week];
                    NSDate *endDate = [gregorian dateByAddingComponents:eDateComponents toDate:p.powerDate options:0];
                    self.dateLabel.text = [NSString stringWithFormat:@"%@-%@",[formatter stringFromDate:startDate],[formatter stringFromDate:endDate]];
                }
            }
                break;
            case 2:
            {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"MMM"];
                if ([[formatter stringFromDate:p.powerDate] isEqualToString:[formatter stringFromDate:[NSDate date]]]) {
                    self.dateLabel.text = AcTECLocalizedStringFromTable(@"thisMonth", @"Localizable");
                }else {
                    self.dateLabel.text = [formatter stringFromDate:p.powerDate];
                }
            }
                break;
            case 5:
            {
                NSDateFormatter *hourFormatter = [[NSDateFormatter alloc] init];
                [hourFormatter setDateFormat:@"HH"];
                if ([[hourFormatter stringFromDate:p.powerDate] isEqualToString:[hourFormatter stringFromDate:[NSDate date]]]) {
                    self.dateLabel.text = @"Now";
                }else {
                    self.dateLabel.text = [hourFormatter stringFromDate:p.powerDate];
                }
            }
                break;
            default:
                break;
        }
        
    }
}

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    [self setNeedsLayout];
    [self layoutIfNeeded];
    CGSize size = [self.contentView systemLayoutSizeFittingSize:layoutAttributes.size];
    CGRect cellFrame = layoutAttributes.frame;
    cellFrame.size.height= size.height;
    layoutAttributes.frame= cellFrame;
    return layoutAttributes;
}



@end
