//
//  SingleBtnCell.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/11/25.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SingleBtnCell.h"
#import "CSRmeshDevice.h"
#import "CSRDevicesManager.h"
#import "DataModelManager.h"

@interface SingleBtnCell ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (weak, nonatomic) IBOutlet UIButton *doneBtn;
@property (weak, nonatomic) IBOutlet UIImageView *dashImage;
@property (weak, nonatomic) IBOutlet UIButton *selectBtn;
@property (nonatomic,strong) NSNumber *seletDeviceId;
@property (nonatomic,strong) NSString *originalName;

@end

@implementation SingleBtnCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _remoteName.delegate = self;
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.preservesSuperviewLayoutMargins = NO;
        self.separatorInset = UIEdgeInsetsZero;
        self.layoutMargins = UIEdgeInsetsZero;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 100, 30)];
        label.backgroundColor = [UIColor redColor];
        [self.contentView addSubview:label];
    }
    return self;
}

- (IBAction)infoBtn:(UIButton *)sender {
    _dashImage.hidden = !_dashImage.hidden;
    _selectBtn.hidden = _dashImage.hidden;
    if (_selectBtn.hidden) {
        _selectBtn.enabled = YES;
    }else {
        _selectBtn.enabled = NO;
    }
}

- (IBAction)settingBtn:(UIButton *)sender {
    _dashImage.hidden = !_dashImage.hidden;
    _selectBtn.hidden = _dashImage.hidden;
    _deleteBtn.hidden = _dashImage.hidden;
    _doneBtn.hidden = _dashImage.hidden;
    _remoteName.enabled = !_dashImage.hidden;
    if (_remoteName.enabled) {
        _remoteName.backgroundColor = [UIColor lightGrayColor];
    }else {
        _remoteName.backgroundColor = [UIColor clearColor];
    }
}

- (IBAction)selectDevice:(UIButton *)sender {
    ConfiguredDeviceListController *list = [[ConfiguredDeviceListController alloc] initWithItemPerSection:3 cellIdentifier:@"LightClusterCell"];
    list.fromStr = @"remote";
    [list setSelectMode:Single];
    [list setSelectDeviceHandle:^(NSArray *selectedDevice) {
        _seletDeviceId = selectedDevice[0];
        CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:_seletDeviceId];
        [sender setTitle:[NSString stringWithFormat:@"%@",device.name] forState:UIControlStateNormal];
    }];
    if (self.delegate && [self.delegate respondsToSelector:@selector(pushToDeviceListSingle:)]) {
        [self.delegate pushToDeviceListSingle:list];
    }
}

- (IBAction)deleteBtn:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(deleteRemoteTappedSingle:)]) {
        [self.delegate deleteRemoteTappedSingle:_myDeviceId];
    }
}

- (IBAction)doneBtn:(UIButton *)sender {
    _dashImage.hidden = YES;
    _selectBtn.hidden = YES;
    _deleteBtn.hidden = YES;
    _doneBtn.hidden = YES;
    _remoteName.enabled = NO;
    _remoteName.backgroundColor = [UIColor clearColor];
    
    NSString *str = [self exchangePositionOfDeviceId:_seletDeviceId];
    NSString *cmdStr = [NSString stringWithFormat:@"700b010000%@ffffffffffff",str];
    [[DataModelManager shareInstance] sendCmdData:cmdStr toDeviceId:_myDeviceId];
    if (self.delegate && [self.delegate respondsToSelector:@selector(showHudSingle)]) {
        [self.delegate showHudSingle];
    }
}

- (NSString *)exchangePositionOfDeviceId:(NSNumber *)deviceId {
    NSInteger devicedIdInteger = [deviceId integerValue];
    NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1lx",(long)devicedIdInteger]];
    NSLog(@"%@ >>>>> %@",deviceId,hexString);
    NSString *str11 = [hexString substringToIndex:2];
    NSString *str22 = [hexString substringFromIndex:2];
    NSString *deviceIdStr = [NSString stringWithFormat:@"%@%@",str22,str11];
    NSLog(@">>>>> %@",deviceIdStr);
    return deviceIdStr;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self saveNickName];
}

#pragma mark - 保存修改后的灯名

- (void)saveNickName {
    if (![_remoteName.text isEqualToString:_originalName] && _remoteName.text.length > 0) {
        //        self.navigationItem.title = _remoteName.text;
        //        _deviceEntity.name = _remoteName.text;
        //        _lightDevice = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:_deviceEntity.deviceId];
        //        _lightDevice.name = _remoteName.text;
        //        [[CSRDatabaseManager sharedInstance] saveContext];
        //        if (self.handle) {
        //            self.handle();
        //        }
    }
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
