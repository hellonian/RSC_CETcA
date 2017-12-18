//
//  RemoteTCell.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/10/7.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "RemoteTCell.h"
#import "CSRmeshDevice.h"
#import "CSRDevicesManager.h"
#import "DataModelManager.h"

@interface RemoteTCell ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *remote0;
@property (weak, nonatomic) IBOutlet UIImageView *remote1;
@property (weak, nonatomic) IBOutlet UIImageView *remote2;
@property (weak, nonatomic) IBOutlet UIImageView *remote3;
@property (weak, nonatomic) IBOutlet UIImageView *remote4;
@property (weak, nonatomic) IBOutlet UIImageView *dashImage;
@property (weak, nonatomic) IBOutlet UIButton *btn1;
@property (weak, nonatomic) IBOutlet UIButton *btn2;
@property (weak, nonatomic) IBOutlet UIButton *btn3;
@property (weak, nonatomic) IBOutlet UIButton *btn4;
@property (nonatomic,strong) NSString *originalName;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (weak, nonatomic) IBOutlet UIButton *doneBtn;


@end

@implementation RemoteTCell

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
        label.backgroundColor = [UIColor greenColor];
        [self.contentView addSubview:label];
    }
    return self;
}

- (IBAction)touchDown:(UIButton *)sender {
    switch (sender.tag) {
        case 100:
            _remote0.hidden = NO;
            break;
        case 101:
            _remote1.hidden = NO;
            break;
        case 102:
            _remote2.hidden = NO;
            break;
        case 103:
            _remote3.hidden = NO;
            break;
        case 104:
            _remote4.hidden = NO;
            break;
        default:
            break;
    }
}
- (IBAction)touchUpInside:(UIButton *)sender {
    switch (sender.tag) {
        case 100:
            _remote0.hidden = YES;
            break;
        case 101:
            _remote1.hidden = YES;
            [self control:_btn1.tag];
            break;
        case 102:
            _remote2.hidden = YES;
            [self control:_btn2.tag];
            break;
        case 103:
            _remote3.hidden = YES;
            [self control:_btn3.tag];
            break;
        case 104:
            _remote4.hidden = YES;
            [self control:_btn4.tag];
            break;
        case 200:
            _remoteName.enabled = _dashImage.hidden;
            if (_remoteName.enabled) {
                _remoteName.backgroundColor = [UIColor lightGrayColor];
            }else {
                _remoteName.backgroundColor = [UIColor clearColor];
            }
            [self showOrHiddenDashs];
            _deleteBtn.hidden = _dashImage.hidden;
            _doneBtn.hidden = _dashImage.hidden;
            break;
        case 300:
            [self showOrHiddenDashs];
            if (_dashImage.hidden) {
                _btn1.enabled = YES;
                _btn2.enabled = YES;
                _btn3.enabled = YES;
                _btn4.enabled = YES;
            }else {
                _btn1.enabled = NO;
                _btn2.enabled = NO;
                _btn3.enabled = NO;
                _btn4.enabled = NO;
            }
            break;
        case 400:
            [self endSetRemote];
            _remoteName.enabled = !_remoteName.enabled;
            if (_remoteName.enabled) {
                _remoteName.backgroundColor = [UIColor lightGrayColor];
            }else {
                _remoteName.backgroundColor = [UIColor clearColor];
            }
            [self showOrHiddenDashs];
            _deleteBtn.hidden = !_deleteBtn.hidden;
            _doneBtn.hidden = !_doneBtn.hidden;
            break;
        case 500:
            if (self.delegate && [self.delegate respondsToSelector:@selector(deleteRemoteTapped:)]) {
                [self.delegate deleteRemoteTapped:_myDeviceId];
            }
            break;
        default:
            break;
    }
}

- (void)control:(NSInteger)btntag {
    if (btntag != 0) {
        CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:[NSNumber numberWithInteger:btntag]];
        BOOL state = [device getPower];
        [device setPower:!state];
    }
}

- (IBAction)selectDevice:(UIButton *)sender {
    ConfiguredDeviceListController *list = [[ConfiguredDeviceListController alloc] initWithItemPerSection:3 cellIdentifier:@"LightClusterCell"];
    list.fromStr = @"remote";
    [list setSelectMode:Single];
    [list setSelectDeviceHandle:^(NSArray *selectedDevice) {
        NSNumber *deviceId = selectedDevice[0];
        sender.tag = [deviceId integerValue];
        CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:deviceId];
        [sender setTitle:[NSString stringWithFormat:@"%@",device.name] forState:UIControlStateNormal];
    }];
    if (self.delegate && [self.delegate respondsToSelector:@selector(pushToDeviceList:)]) {
        [self.delegate pushToDeviceList:list];
    }
}

- (void)showOrHiddenDashs {
    _dashImage.hidden = !_dashImage.hidden;
    _btn1.hidden = _dashImage.hidden;
    _btn2.hidden = _dashImage.hidden;
    _btn3.hidden = _dashImage.hidden;
    _btn4.hidden = _dashImage.hidden;
}

- (void)endSetRemote {
    NSString *str1;
    NSString *str2;
    NSString *str3;
    NSString *str4;
    if (_btn1.tag == 0) {
        str1 = @"ffff";
    }else{
        str1 = [self exchangePositionOfDeviceId:_btn1.tag];
    }
    if (_btn2.tag == 0) {
        str2 = @"ffff";
    }else{
        str2 = [self exchangePositionOfDeviceId:_btn2.tag];
    }
    if (_btn3.tag == 0) {
        str3 = @"ffff";
    }else{
        str3 = [self exchangePositionOfDeviceId:_btn3.tag];
    }
    if (_btn4.tag == 0) {
        str4 = @"ffff";
    }else{
        str4 = [self exchangePositionOfDeviceId:_btn4.tag];
    }
    NSString *cmdStr = [NSString stringWithFormat:@"700b010000%@%@%@%@",str1,str2,str3,str4];
    [[DataModelManager shareInstance] sendCmdData:cmdStr toDeviceId:_myDeviceId];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(showHud)]) {
        [self.delegate showHud];
    }
    
}
- (NSString *)exchangePositionOfDeviceId:(NSInteger)deviceId {
    NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1lx",(long)deviceId]];
    NSString *str11 = [hexString substringToIndex:2];
    NSString *str22 = [hexString substringFromIndex:2];
    NSString *deviceIdStr = [NSString stringWithFormat:@"%@%@",str22,str11];
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
