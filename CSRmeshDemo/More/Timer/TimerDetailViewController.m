//
//  TimerDetailViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/2.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "TimerDetailViewController.h"
#import <objc/runtime.h>
#import "PureLayout.h"
#import "DeviceListViewController.h"
#import "DeviceModelManager.h"
#import "CSRDatabaseManager.h"
#import "TimerEntity.h"
#import "CSRUtilities.h"
#import "TimerDeviceEntity.h"
#import "DataModelManager.h"

@interface TimerDetailViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIDatePicker *timerPicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UIView *weekView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *repeatChooseSegment;
@property (weak, nonatomic) IBOutlet UILabel *devicesListLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameTF;
@property (weak, nonatomic) IBOutlet UISwitch *enabledSwitch;
@property (nonatomic,strong) NSArray *deviceIds;


@end

@implementation TimerDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = done;
    
    [self setDatePickerTextColor:self.timerPicker];
    [self setDatePickerTextColor:self.datePicker];
    self.nameTF.delegate = self;
    
    if (self.timerEntity) {
        self.navigationItem.title = self.timerEntity.name;
        self.nameTF.text = self.timerEntity.name;
        [self.enabledSwitch setOn:[self.timerEntity.enabled boolValue]];
        NSString *devciesList = @"";
        for (TimerDeviceEntity *timerDevice in self.timerEntity.timerDevices) {
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:timerDevice.deviceID];
            devciesList = [NSString stringWithFormat:@"%@  %@",devciesList,deviceEntity.name];
        }
        self.devicesListLabel.text = devciesList;
        [self.timerPicker setDate:self.timerEntity.fireTime];
        if ([self.timerEntity.repeat integerValue] == 0) {
            [self.view addSubview:self.datePicker];
            [self.datePicker autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.datePicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:8.0];
            [self.datePicker autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
            [self.datePicker autoSetDimension:ALDimensionHeight toSize:100.0];
            
            [self.datePicker setDate:self.timerEntity.fireDate];
            
        }else {
            [self.view addSubview:self.weekView];
            [self.weekView autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:43.0];
            [self.weekView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
            [self.weekView autoSetDimension:ALDimensionHeight toSize:29.0];
            
            NSString *repeat = [self.timerEntity.repeat substringFromIndex:1];
            [self.weekView.subviews enumerateObjectsUsingBlock:^(UIButton * btn, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *str = [repeat substringWithRange:NSMakeRange(idx, 1)];
                if ([str boolValue]) {
                    btn.selected = YES;
                    [btn setBackgroundImage:[UIImage imageNamed:@"weekBtnSelected"] forState:UIControlStateNormal];
                }else {
                    btn.selected = NO;
                    [btn setBackgroundImage:[UIImage imageNamed:@"weekBtnSelect"] forState:UIControlStateNormal];
                }
            }]; 
        }
    }else {
        [self.view addSubview:self.weekView];
        [self.weekView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:43.0];
        [self.weekView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.weekView autoSetDimension:ALDimensionHeight toSize:29.0];
    }
    
}

#pragma mark - 修改日期选择器的字体颜色

- (void)setDatePickerTextColor:(UIDatePicker *)picker {
    unsigned int outCount;
    int i;
    objc_property_t *pProperty = class_copyPropertyList([UIDatePicker class], &outCount);
    for (i = outCount -1; i >= 0; i--)
    {
        //         循环获取属性的名字   property_getName函数返回一个属性的名称
        NSString *getPropertyName = [NSString stringWithCString:property_getName(pProperty[i]) encoding:NSUTF8StringEncoding];
        if([getPropertyName isEqualToString:@"textColor"])
        {
            [picker setValue:DARKORAGE forKey:@"textColor"];
        }
        
        
    }
    //通过NSSelectorFromString获取setHighlightsToday方法
    SEL selector = NSSelectorFromString(@"setHighlightsToday:");
    //创建NSInvocation
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDatePicker instanceMethodSignatureForSelector:selector]];
    BOOL no = NO;
    [invocation setSelector:selector];
    //setArgument中第一个参数的类picker，第二个参数是SEL，
    [invocation setArgument:&no atIndex:2];
    //让invocation执行setHighlightsToday方法
    [invocation invokeWithTarget:picker];
}

- (IBAction)repeatClick:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        [self.datePicker removeFromSuperview];
        [self.view addSubview:self.weekView];
        [self.weekView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:43.0];
        [self.weekView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.weekView autoSetDimension:ALDimensionHeight toSize:29.0];
        
    }else {
        [self.weekView removeFromSuperview];
        [self.view addSubview:self.datePicker];
        [self.datePicker autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.datePicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:8.0];
        [self.datePicker autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
        [self.datePicker autoSetDimension:ALDimensionHeight toSize:100.0];
        
    }
}

- (IBAction)chooseDevice:(UIButton *)sender {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_Multiple;
    [list getSelectedDevices:^(NSArray *devices) {
        if (devices.count > 0) {
            __block NSString *string = @"";
            [devices enumerateObjectsUsingBlock:^(NSNumber *deviceId, NSUInteger idx, BOOL * _Nonnull stop) {
                DeviceModel *device = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
                string = [NSString stringWithFormat:@"%@ %@",string,device.name];
            }];
            self.devicesListLabel.text = string;
            self.deviceIds = devices;
        }
    }];
    [self.navigationController pushViewController:list animated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    textField.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    textField.backgroundColor = [UIColor whiteColor];
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
//    [self saveNickName];
}

#pragma mark - weekButton

- (IBAction)weekButtonClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    UIImage *bgImage = sender.selected? [UIImage imageNamed:@"weekBtnSelected"]:[UIImage imageNamed:@"weekBtnSelect"];
    [sender setBackgroundImage:bgImage forState:UIControlStateNormal];
}

- (void)doneAction {
    
    NSNumber *timerIdNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"TimerEntity"];
    
    NSString *name;
    if (![CSRUtilities isStringEmpty:_nameTF.text]) {
        name = _nameTF.text;
    }else {
        name = [NSString stringWithFormat:@"timer %@",timerIdNumber];
    }
    
    NSNumber *enabled = @(_enabledSwitch.on);
    
    NSDateFormatter *dateFormate = [[NSDateFormatter alloc] init];
    [dateFormate setDateFormat:@"yyyyMMddHHmmss"];
    NSString *dateStr = [dateFormate stringFromDate:_timerPicker.date];
    NSString *newStr = [dateStr stringByReplacingCharactersInRange:NSMakeRange(12, 2) withString:@"00"];
    NSDate *time = [dateFormate dateFromString:newStr];
    
    NSString *repeatStr = @"";
    if (_repeatChooseSegment.selectedSegmentIndex == 0) {
        for (UIButton *btn in self.weekView.subviews) {
            repeatStr = [NSString stringWithFormat:@"%d%@",btn.selected,repeatStr];
        }
        repeatStr = [NSString stringWithFormat:@"0%@",repeatStr];
    }else {
        repeatStr = @"0";
    }
    NSLog(@"str>> %@",repeatStr);
    
    TimerEntity *timerEntity = [[CSRDatabaseManager sharedInstance] saveNewTimer:timerIdNumber timerName:name enabled:enabled fireTime:time fireDate:_datePicker.date repeatStr:repeatStr];
    
    for (NSNumber *deviceId in self.deviceIds) {
        NSNumber *timerIndex = [[CSRDatabaseManager sharedInstance] getNextFreeTimerIDOfDeivice:deviceId];
        NSLog(@"><><><><><> %@",timerIndex);
        
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
        NSString *eveType;
        if ([model.shortName isEqualToString:@"S350BT"]) {
            if ([model.powerState boolValue]) {
                eveType = @"10";
            }else {
                eveType = @"11";
            }
        }else if ([model.shortName isEqualToString:@"D350BT"]) {
            if ([model.powerState boolValue]) {
                eveType = @"12";
            }else {
                eveType = @"11";
            }
        }
        [[DataModelManager shareInstance] addAlarmForDevice:deviceId alarmIndex:[timerIndex integerValue] enabled:[enabled boolValue] fireDate:_datePicker.date fireTime:time repeat:repeatStr eveType:eveType level:[model.level integerValue]];
        
    }
    
    
    
    if (self.handle) {
        self.handle();
    }
}

- (IBAction)deleteTimerAction:(UIButton *)sender {
    
    
    
}

@end
