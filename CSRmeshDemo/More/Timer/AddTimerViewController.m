//
//  AddTimerViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/12.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "AddTimerViewController.h"
#import "PureLayout.h"
#import <objc/runtime.h>
#import "ConfiguredDeviceListController.h"
#import "CSRmeshDevice.h"
#import "CSRDevicesManager.h"
#import "DataModelManager.h"
#import "EveTypeViewController.h"
#import "TimerTool.h"
#import <MBProgressHUD.h>
#import "DeviceListViewController.h"

@interface AddTimerViewController ()<MBProgressHUDDelegate>

@property (nonatomic,strong) UISegmentedControl *segment;
@property (nonatomic,strong) UIDatePicker *datePicker;
@property (nonatomic,strong) UIDatePicker *timePicker;
@property (strong, nonatomic) IBOutlet UIView *weekView;
@property (nonatomic,strong) NSNumber *deviceId;//
@property (nonatomic,strong) CSRmeshDevice *device;
@property (nonatomic,copy) NSString *eveType;
@property (nonatomic,assign) NSInteger level;
@property (nonatomic,assign) AlarmRepeatType repeatType;//

@property (nonatomic,strong) MBProgressHUD *hud;

@end

@implementation AddTimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationItem.title = @"Add Timer";
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveClick)];
    self.navigationItem.rightBarButtonItem = save;
    
    [self.view addSubview:self.timePicker];
    [_timePicker autoSetDimension:ALDimensionHeight toSize:150];
    [_timePicker autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:155];
    [_timePicker autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [_timePicker autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20];
    
    [self.view addSubview:self.segment];
    [_segment autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_segment autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.timePicker];
    
    [self.view addSubview:self.weekView];
    [self.weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.segment withOffset:60];
    [self.weekView autoSetDimension:ALDimensionHeight toSize:WIDTH/8];
    [self.weekView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.weekView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideHudAndShowText:) name:@"addAlarmCall" object:nil];
}

- (void)enanledRightItem {
    if (self.deviceId && self.eveType) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

- (void)hideHudAndShowText:(NSNotification *)result {
    [_hud hideAnimated:YES];
    NSDictionary *resultDic = result.userInfo;
    NSString *resultStr = [resultDic objectForKey:@"addAlarmCall"];
    if ([resultStr boolValue]) {
        [self showTextHud:@"SUCCESS"];
    }else {
        [self showTextHud:@"ERROR"];
    }
}

- (void)showTextHud:(NSString *)text {
    MBProgressHUD *successHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    successHud.mode = MBProgressHUDModeText;
    successHud.label.text = text;
    successHud.label.numberOfLines = 0;
    successHud.delegate = self;
    [successHud hideAnimated:YES afterDelay:1.5f];
}

//发送添加命令
- (void)saveClick {
    NSInteger timerIndex = [TimerTool newTimerIndexForDevice:self.deviceId];
//    if (timerIndex == 99) {
//        [self showTextHud:@"The device most timers now"];
//        return;
//    }
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.delegate = self;
    
    NSString *repeatStr = @"";
    if (self.repeatType == Week) {
        for (UIButton *btn in self.weekView.subviews) {
            repeatStr = [NSString stringWithFormat:@"%d%@",btn.selected,repeatStr];
        }
    }else{
        repeatStr = @"0";
    }
    
    NSDateFormatter *dateFormate = [[NSDateFormatter alloc] init];
    [dateFormate setDateFormat:@"yyyyMMddHHmmss"];
    NSString *dateStr = [dateFormate stringFromDate:_timePicker.date];
    NSString *newStr = [dateStr stringByReplacingCharactersInRange:NSMakeRange(12, 2) withString:@"00"];
    NSDate *time = [dateFormate dateFromString:newStr];
    
    [[DataModelManager shareInstance] addAlarmForDevice:self.deviceId alarmIndex:timerIndex fireDate:self.datePicker.date fireTime:time repeat:repeatStr eveType:self.eveType level:self.level];
}

- (IBAction)choosEveType:(UIButton *)sender {
    if (self.device) {
        EveTypeViewController *evc = [[EveTypeViewController alloc] init];
        evc.deviceShortName = self.device.shortName;
        evc.setEveType = ^(NSString *eveType, CGFloat level) {
            self.eveType = eveType;
            if ([eveType isEqualToString:@"12"]) {
                [sender setTitle:[NSString stringWithFormat:@"Turn ON,brightness:%.f%% >",level/255*100] forState:UIControlStateNormal];
                self.level = level;
            }else if ([eveType isEqualToString:@"10"]) {
                [sender setTitle:@"Turn ON >" forState:UIControlStateNormal];
                self.level = 0;
            }else {
                [sender setTitle:@"Turn OFF >" forState:UIControlStateNormal];
                self.level = 0;
            }
            [self enanledRightItem];
        };
        [self.navigationController pushViewController:evc animated:YES];
    }
    
}

- (IBAction)chooseDevices:(UIButton *)sender {
    
//    ConfiguredDeviceListController *list = [[ConfiguredDeviceListController alloc] initWithItemPerSection:3 cellIdentifier:@"LightClusterCell"];
//    [list setSelectMode:Single];
//    [list setSelectDeviceHandle:^(NSArray *selectedDevice) {
//        NSNumber *deviceId = selectedDevice[0];
//        self.deviceId = deviceId;
//        self.device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:deviceId];
//        [sender setTitle:[NSString stringWithFormat:@"%@ >",self.device.name] forState:UIControlStateNormal];
//        [self enanledRightItem];
//    }];
//    [self.navigationController pushViewController:list animated:YES];
    
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_Single;
    [list getSelectedDevices:^(NSArray *devices) {
        if (devices.count > 0) {
            NSNumber *deviceId = devices[0];
            self.deviceId = deviceId;
            self.device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:deviceId];
            [sender setTitle:[NSString stringWithFormat:@"%@ >",self.device.name] forState:UIControlStateNormal];
            [self enanledRightItem];
        }
    }];
    [self.navigationController pushViewController:list animated:YES];
    
}

- (void)repeatClick:(UISegmentedControl *)segment {
    if (segment.selectedSegmentIndex == 0) {
        self.repeatType = Week;
        [UIView animateWithDuration:1 animations:^{
            [self.datePicker removeFromSuperview];
            [self.view addSubview:self.weekView];
            [self.weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.segment withOffset:60];
            [self.weekView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
            [self.weekView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        } completion:nil];
        
    }else {
        self.repeatType = Day;
        [UIView animateWithDuration:1 animations:^{
            [self.weekView removeFromSuperview];
            [self.view addSubview:self.datePicker];
            [self.datePicker autoSetDimension:ALDimensionHeight toSize:150];
            [self.datePicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.segment];
            [self.datePicker autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
            [self.datePicker autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20];
        } completion:nil];
    }
    [self enanledRightItem];
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

#pragma mark - Lazy

- (UISegmentedControl *)segment {
    if (!_segment) {
        NSArray *ary = @[@"Week",@"Day"];
        _segment = [[UISegmentedControl alloc] initWithItems:ary];
        _segment.bounds = CGRectMake(0, 0, 121, 29);
        _segment.tintColor = DARKORAGE;
        _segment.selectedSegmentIndex = 0;
        [_segment addTarget:self action:@selector(repeatClick:) forControlEvents:UIControlEventValueChanged];
    }
    return _segment;
}

- (UIDatePicker *)timePicker {
    if (!_timePicker) {
        _timePicker = [[UIDatePicker alloc] init];
        _timePicker.datePickerMode = UIDatePickerModeTime;
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"NL"];
        [_timePicker setLocale:locale];
        [self setDatePickerTextColor:_timePicker];
    }
    return _timePicker;
}

- (UIDatePicker *)datePicker {
    if (!_datePicker) {
        _datePicker = [[UIDatePicker alloc] init];
        _datePicker.datePickerMode = UIDatePickerModeDate;
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale currentLocale] localeIdentifier]];
        [_datePicker setLocale:locale];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDate *dt = [NSDate date];
        unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
        NSDateComponents *comp = [gregorian components:unitFlags fromDate:dt];
        NSDateFormatter  * formatter = [[ NSDateFormatter   alloc ] init ];
        [formatter  setDateFormat : @"yyyy-MM-dd HH:mm:ss" ];
        NSString  * mindateStr =  [NSString stringWithFormat:@"%ld-%ld-%ld 00:00:00",(long)comp.year,(long)comp.month,(long)comp.day];
        NSDate  * mindate = [formatter  dateFromString :mindateStr];
        _datePicker . minimumDate = mindate;
        [self setDatePickerTextColor:_datePicker];
    }
    return _datePicker;
}

#pragma mark - weekButton

- (IBAction)btnClick:(UIButton *)sender {
    int i=0;
    for (UIButton *btn in self.weekView.subviews) {
        if (btn.selected == 0) {
            i++;
        }
    }
    if (!(i>=6 && sender.selected)) {
        sender.selected = !sender.selected;
        if (sender.selected) {
            [sender setBackgroundImage:[UIImage imageNamed:@"btnbg"] forState:UIControlStateNormal];
        }else {
            [sender setBackgroundImage:[UIImage imageNamed:@"blackbg"] forState:UIControlStateNormal];
        }
    }
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    
    [hud removeFromSuperview];
    
    hud = nil;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
