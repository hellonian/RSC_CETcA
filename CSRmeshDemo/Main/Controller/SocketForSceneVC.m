//
//  SocketForSceneVC.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/1/2.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SocketForSceneVC.h"
#import "CSRDatabaseManager.h"
#import "DeviceModelManager.h"
#import "CSRUtilities.h"
#import <CSRmesh/DataModelApi.h>

@interface SocketForSceneVC ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (weak, nonatomic) IBOutlet UISwitch *channel1Switch;
@property (weak, nonatomic) IBOutlet UISwitch *channel2Switch;
@property (weak, nonatomic) IBOutlet UIImageView *channelSelected1ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *channelSelected2ImageView;

@end

@implementation SocketForSceneVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setSocketSuccess:)
                                                 name:@"setPowerStateSuccess"
                                               object:nil];
    if (_deviceId) {
        CSRDeviceEntity *curtainEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        self.navigationItem.title = curtainEntity.name;
        self.nameLabel.text = curtainEntity.name;
        NSString *macAddr = [curtainEntity.uuid substringFromIndex:24];
        NSString *doneTitle = @"";
        int count = 0;
        for (int i = 0; i<macAddr.length; i++) {
            count ++;
            doneTitle = [doneTitle stringByAppendingString:[macAddr substringWithRange:NSMakeRange(i, 1)]];
            if (count == 2 && i<macAddr.length-1) {
                doneTitle = [NSString stringWithFormat:@"%@:", doneTitle];
                count = 0;
            }
        }
        self.macAddressLabel.text = doneTitle;
        [self changeUI:_deviceId];
    }
    
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)channelSeleteBtn:(UIButton *)sender {
    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance]getDeviceModelByDeviceId:_deviceId];
    if ((deviceModel.channel1Selected && !deviceModel.channel2Selected && sender.tag == 1) || (!deviceModel.channel1Selected && deviceModel.channel2Selected && sender.tag == 2)) {
        return;
    }
    sender.selected = !sender.selected;
    UIImage *image = sender.selected? [UIImage imageNamed:@"Be_selected"]:[UIImage imageNamed:@"To_select"];
    switch (sender.tag) {
        case 1:
            _channelSelected1ImageView.image = image;
            deviceModel.channel1Selected = sender.selected;
            if (_buttonNum) {
                NSNumber *obj = [deviceModel.buttonnumAndChannel objectForKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                if (sender.selected) {
                    if (obj && [obj isEqualToNumber:@3]) {
                        [deviceModel addValue:@1 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }else {
                        [deviceModel addValue:@2 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }
                }else {
                    if (obj && [obj isEqualToNumber:@1]) {
                        [deviceModel addValue:@3 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }
                }
            }
            break;
        case 2:
            _channelSelected2ImageView.image = image;
            deviceModel.channel2Selected = sender.selected;
            if (_buttonNum) {
                NSNumber *obj = [deviceModel.buttonnumAndChannel objectForKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                if (sender.selected) {
                    if (obj && [obj isEqualToNumber:@2]) {
                        [deviceModel addValue:@1 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }else {
                        [deviceModel addValue:@3 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }
                }else {
                    if (obj && [obj isEqualToNumber:@1]) {
                        [deviceModel addValue:@2 forKey:[NSString stringWithFormat:@"%@",_buttonNum]];
                    }
                }
            }
            break;
        default:
            break;
    }
}

- (IBAction)turnOnOFF:(UISwitch *)sender {
    NSString *cmdString;
    switch (sender.tag) {
        case 1:
            cmdString = [NSString stringWithFormat:@"51050100010%d%@",sender.on,[CSRUtilities stringWithHexNumber:sender.on*255]];
            break;
        case 2:
            cmdString = [NSString stringWithFormat:@"51050200010%d%@",sender.on,[CSRUtilities stringWithHexNumber:sender.on*255]];
            break;
        default:
            break;
    }
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
}

- (void)setSocketSuccess: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        [self changeUI:deviceId];
    }
}

- (void)changeUI:(NSNumber *)deviceId {
    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance]getDeviceModelByDeviceId:deviceId];
    if (deviceModel) {
        [_channel1Switch setOn:deviceModel.channel1PowerState];
        [_channel2Switch setOn:deviceModel.channel2PowerState];
        _channelSelected1ImageView.image = deviceModel.channel1Selected? [UIImage imageNamed:@"Be_selected"]:[UIImage imageNamed:@"To_select"];
        _channelSelected2ImageView.image = deviceModel.channel2Selected? [UIImage imageNamed:@"Be_selected"]:[UIImage imageNamed:@"To_select"];
    }
}

@end
