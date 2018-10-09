//
//  CurtainViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/9/19.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "CurtainViewController.h"
#import "CSRDatabaseManager.h"
#import <CSRmesh/DataModelApi.h>
#import "CSRUtilities.h"

@interface CurtainViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (weak, nonatomic) IBOutlet UIImageView *curtainTypeImageView;
@property (weak, nonatomic) IBOutlet UIButton *openBtn;
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;
@property (nonatomic,copy) NSString *originalName;

@end

@implementation CurtainViewController

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
    if (_deviceId) {
        CSRDeviceEntity *curtainEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        self.navigationItem.title = curtainEntity.name;
        self.nameTf.delegate = self;
        self.nameTf.text = curtainEntity.name;
        self.originalName = curtainEntity.name;
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
        if ([curtainEntity.remoteBranch isEqualToString:@"ch"]) {
            self.curtainTypeImageView.image = [UIImage imageNamed:@"curtainHImage"];
            [self.openBtn setImage:[UIImage imageNamed:@"curtainHOpen"] forState:UIControlStateNormal];
            [self.closeBtn setImage:[UIImage imageNamed:@"curtainHClose"] forState:UIControlStateNormal];
        }else if ([curtainEntity.remoteBranch isEqualToString:@"cv"]) {
            self.curtainTypeImageView.image = [UIImage imageNamed:@"curtainVImage"];
            [self.openBtn setImage:[UIImage imageNamed:@"curtainVOpen"] forState:UIControlStateNormal];
            [self.closeBtn setImage:[UIImage imageNamed:@"curtainVClose"] forState:UIControlStateNormal];
        }
    }
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    [self saveNickName];
}

#pragma mark - 保存修改后的灯名

- (void)saveNickName {
    if (![_nameTf.text isEqualToString:_originalName] && _nameTf.text.length > 0) {
        self.navigationItem.title = _nameTf.text;
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:self.deviceId];
        deviceEntity.name = _nameTf.text;
        [[CSRDatabaseManager sharedInstance] saveContext];
        _originalName = _nameTf.text;
        if (self.reloadDataHandle) {
            self.reloadDataHandle();
        }
    }
    
}

#pragma mark - 控制

- (IBAction)curtainOpenAction:(UIButton *)sender {
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"790102"] success:nil failure:nil];
}
- (IBAction)curtainPauseAction:(UIButton *)sender {
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"790100"] success:nil failure:nil];
}
- (IBAction)crutainClose:(UIButton *)sender {
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:@"790101"] success:nil failure:nil];
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
