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
#import "CSRAppStateManager.h"
#import <MBProgressHUD.h>

@interface TimerDetailViewController ()<UITextFieldDelegate,MBProgressHUDDelegate>

@property (weak, nonatomic) IBOutlet UIDatePicker *timerPicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UIView *weekView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *repeatChooseSegment;
@property (weak, nonatomic) IBOutlet UILabel *devicesListLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameTF;
@property (weak, nonatomic) IBOutlet UISwitch *enabledSwitch;
@property (nonatomic,strong) NSMutableArray *deviceIds;
@property (nonatomic,strong) NSMutableDictionary *deviceIdsAndIndexs;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (nonatomic,strong) NSMutableArray *deleteTimers;
@property (nonatomic,strong) NSMutableArray *backs;
@property (nonatomic,strong) MBProgressHUD *hud;


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
    
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) {
        [self.deleteButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:50.0];
    }
    
    if (!self.newadd && self.timerEntity) {
        self.navigationItem.title = self.timerEntity.name;
        self.nameTF.text = self.timerEntity.name;
        [self.enabledSwitch setOn:[self.timerEntity.enabled boolValue]];
        NSString *devciesList = @"";
        for (TimerDeviceEntity *timerDevice in self.timerEntity.timerDevices) {
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:timerDevice.deviceID];
            devciesList = [NSString stringWithFormat:@"%@  %@",devciesList,deviceEntity.name];
//            NSMutableAttributedString *hintString=[[NSMutableAttributedString alloc]initWithString:devciesList];
//            if (![timerDevice.alive boolValue]&&deviceEntity.name) {
//                NSRange range=[[hintString string]rangeOfString:deviceEntity.name];
//                [hintString addAttribute:NSForegroundColorAttributeName value:DARKORAGE range:range];
//            }
//            self.devicesListLabel.attributedText = hintString;
            self.devicesListLabel.text = devciesList;
            [self.deviceIds addObject:timerDevice.deviceID];
        }
        
        [self.timerPicker setDate:self.timerEntity.fireTime];
        if ([self.timerEntity.repeat isEqualToString:@"00000000"]) {
            [self.repeatChooseSegment setSelectedSegmentIndex:1];
            [self.view addSubview:self.datePicker];
            [self.datePicker autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.datePicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:8.0];
            [self.datePicker autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
            [self.datePicker autoSetDimension:ALDimensionHeight toSize:100.0];
            
            [self.datePicker setDate:self.timerEntity.fireDate];
            
        }else {
            [self.repeatChooseSegment setSelectedSegmentIndex:0];
            [self.view addSubview:self.weekView];
            [self.weekView autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:43.0];
            [self.weekView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
            [self.weekView autoSetDimension:ALDimensionHeight toSize:29.0];
            
            NSString *repeat = [self.timerEntity.repeat substringFromIndex:1];
            [self.weekView.subviews enumerateObjectsUsingBlock:^(UIButton * btn, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *str = [repeat substringWithRange:NSMakeRange(6-idx, 1)];
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
        [self.deleteButton removeFromSuperview];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addTimerToDeviceCall:) name:@"addAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteTimerCall:) name:@"deleteAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeAlarmEnabledCall:) name:@"changeAlarmEnabledCall" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"deleteAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeAlarmEnabledCall" object:nil];
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
            self.deviceIds = [NSMutableArray arrayWithArray:devices];
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

#pragma mark - weekButton

- (IBAction)weekButtonClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    UIImage *bgImage = sender.selected? [UIImage imageNamed:@"weekBtnSelected"]:[UIImage imageNamed:@"weekBtnSelect"];
    [sender setBackgroundImage:bgImage forState:UIControlStateNormal];
}

- (void)doneAction {
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.mode = MBProgressHUDModeIndeterminate;
    _hud.delegate = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_hud hideAnimated:YES];
        [self showTextHud:@"ERROR"];
    });
    [self.backs removeAllObjects];
    
    NSNumber *timerIdNumber;
    if (_newadd) {
        if (!_timerEntity) {
            timerIdNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"TimerEntity"];
        }
    }else {
        if (_timerEntity) {
            timerIdNumber = _timerEntity.timerID;
        }
    }
    
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
    newStr = [newStr stringByReplacingCharactersInRange:NSMakeRange(0, 8) withString:@"20180101"];
    NSDate *time = [dateFormate dateFromString:newStr];
    NSLog(@"timer >>> %@ \n newStr >>> %@",time,newStr);
    NSDate *date;
    
    NSString *repeatStr = @"";
    if (_repeatChooseSegment.selectedSegmentIndex == 0) {
        for (UIButton *btn in self.weekView.subviews) {
            repeatStr = [NSString stringWithFormat:@"%d%@",btn.selected,repeatStr];
        }
        repeatStr = [NSString stringWithFormat:@"0%@",repeatStr];
        
        date = [dateFormate dateFromString:@"20180101000000"];
    }else {
        repeatStr = @"00000000";
        
        NSString *dateString = [dateFormate stringFromDate:_datePicker.date];
        NSString *newString = [dateString stringByReplacingCharactersInRange:NSMakeRange(8, 6) withString:@"000000"];
        date = [dateFormate dateFromString:newString];
        
    }
    
    if (!_newadd) {
        [_timerEntity.timerDevices enumerateObjectsUsingBlock:^(TimerDeviceEntity *timerDevice, BOOL * _Nonnull stop) {
            
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:timerDevice];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }];
    }
    
    _timerEntity = [[CSRDatabaseManager sharedInstance] saveNewTimer:timerIdNumber timerName:name enabled:enabled fireTime:time fireDate:date repeatStr:repeatStr];

    for (NSNumber *deviceId in self.deviceIds) {
        
        NSNumber *timerIndex = [[CSRDatabaseManager sharedInstance] getNextFreeTimerIDOfDeivice:deviceId];
        NSLog(@"timerIndex--> %@",timerIndex);

        [self.deviceIdsAndIndexs setObject:timerIndex forKey:[NSString stringWithFormat:@"%@",deviceId]];

        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
        NSString *eveType;
        if ([CSRUtilities belongToSwitch:model.shortName]) {
            if ([model.powerState boolValue]) {
                eveType = @"10";
            }else {
                eveType = @"11";
            }
        }else if ([CSRUtilities belongToDimmer:model.shortName]) {
            if ([model.powerState boolValue]) {
                eveType = @"12";
            }else {
                eveType = @"11";
            }
        }
        [[DataModelManager shareInstance] addAlarmForDevice:deviceId alarmIndex:[timerIndex integerValue] enabled:[enabled boolValue] fireDate:date fireTime:time repeat:repeatStr eveType:eveType level:[model.level integerValue]];
        
    }
}

- (void)addTimerToDeviceCall:(NSNotification *)result {
    NSDictionary *resultDic = result.userInfo;
    NSString *resultStr = [resultDic objectForKey:@"addAlarmCall"];
    NSNumber *deviceId = [resultDic objectForKey:@"deviceId"];
    NSLog(@"---->> %@ ::: %@",deviceId,resultStr);
    
    if ([resultStr boolValue]) {
        NSNumber *index = [self.deviceIdsAndIndexs objectForKey:[NSString stringWithFormat:@"%@",deviceId]];
        __block TimerDeviceEntity *newTimerDeviceEntity;
        [_timerEntity.timerDevices enumerateObjectsUsingBlock:^(TimerDeviceEntity *timerDevice, BOOL * _Nonnull stop) {
            if ([timerDevice.deviceID isEqualToNumber:deviceId] && [timerDevice.timerIndex isEqualToNumber:index]) {
                newTimerDeviceEntity = timerDevice;
                *stop = YES;
            }
        }];
        if (!newTimerDeviceEntity) {
            newTimerDeviceEntity = [NSEntityDescription insertNewObjectForEntityForName:@"TimerDeviceEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
        }
        newTimerDeviceEntity.timerID = _timerEntity.timerID;
        newTimerDeviceEntity.deviceID = deviceId;
        newTimerDeviceEntity.timerIndex = index;
        [_timerEntity addTimerDevicesObject:newTimerDeviceEntity];
        [[CSRDatabaseManager sharedInstance] saveContext];

        [self.backs addObject:deviceId];
        if ([self.backs count] == [self.deviceIds count]) {
            if (self.handle) {
                self.handle();
            }
            [_hud hideAnimated:YES];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }else {
        [_hud hideAnimated:YES];
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        [self showTextHud:[NSString stringWithFormat:@"ERROR:%@ set timer fail.",deviceEntity.name]];
    }
}

- (void)deleteTimerCall:(NSNotification *)result {
    NSDictionary *resultDic = result.userInfo;
    NSString *state = [resultDic objectForKey:@"deleteAlarmCall"];
    NSNumber *deviceId = [resultDic objectForKey:@"deviceId"];
    if ([state boolValue]) {
        [self.deleteTimers enumerateObjectsUsingBlock:^(TimerDeviceEntity *timeDevice, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([timeDevice.deviceID isEqualToNumber:deviceId]) {
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:timeDevice];
                [[CSRDatabaseManager sharedInstance] saveContext];
                if (self.handle) {
                    self.handle();
                }
                [_hud hideAnimated:YES];
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
    }else {
        [_hud hideAnimated:YES];
        [self showTextHud:@"ERROR"];
    }
    
}

- (void)changeAlarmEnabledCall:(NSNotification *)result {
    NSDictionary *resultDic = result.userInfo;
    NSString *state = [resultDic objectForKey:@"changeAlarmEnabledCall"];
//    NSNumber *deviceId = [resultDic objectForKey:@"deviceId"];
    if ([state boolValue]) {
        [self showTextHud:@"SUCCESS"];
        if (self.handle) {
            self.handle();
        }
    }else {
        [self showTextHud:@"ERROR"];
    }
}

- (IBAction)deleteTimerAction:(UIButton *)sender {
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.mode = MBProgressHUDModeIndeterminate;
    _hud.delegate = self;
    
    [_timerEntity.timerDevices enumerateObjectsUsingBlock:^(TimerDeviceEntity *timeDevice, BOOL * _Nonnull stop) {
        if (timeDevice) {
            [[DataModelManager shareInstance] deleteAlarmForDevice:timeDevice.deviceID index:[timeDevice.timerIndex integerValue]];
            [self.deleteTimers addObject:timeDevice];
        }
    }];
    
    [[CSRAppStateManager sharedInstance].selectedPlace removeTimersObject:self.timerEntity];
    [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:self.timerEntity];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
}

- (IBAction)changeEnabled:(UISwitch *)sender {
    if (!_newadd && _timerEntity) {
        [_timerEntity.timerDevices enumerateObjectsUsingBlock:^(TimerDeviceEntity *timerDevice, BOOL * _Nonnull stop) {
            [[DataModelManager shareInstance] enAlarmForDevice:timerDevice.deviceID stata:sender.on index:[timerDevice.timerIndex integerValue]];
        }];
        
        _timerEntity.enabled = @(sender.on);
        [[CSRDatabaseManager sharedInstance] saveContext];
    }
}

- (NSMutableDictionary *)deviceIdsAndIndexs {
    if (!_deviceIdsAndIndexs) {
        _deviceIdsAndIndexs = [NSMutableDictionary new];
    }
    return _deviceIdsAndIndexs;
}

- (NSMutableArray *)deleteTimers {
    if (!_deleteTimers) {
        _deleteTimers = [NSMutableArray new];
    }
    return _deleteTimers;
}

- (NSMutableArray *)backs {
    if (!_backs) {
        _backs = [NSMutableArray new];
    }
    return _backs;
}

- (NSMutableArray *)deviceIds {
    if (!_deviceIds) {
        _deviceIds = [NSMutableArray new];
    }
    return _deviceIds;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

- (void)showTextHud:(NSString *)text {
    MBProgressHUD *successHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    successHud.mode = MBProgressHUDModeText;
    successHud.label.text = text;
    successHud.label.numberOfLines = 0;
    successHud.delegate = self;
    [successHud hideAnimated:YES afterDelay:1.5f];
}

@end
