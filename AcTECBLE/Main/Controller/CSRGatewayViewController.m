//
//  CSRGatewayViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2021/5/25.
//  Copyright © 2021 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "CSRGatewayViewController.h"
#import "CSRDatabaseManager.h"
#import "NetworkSettingVC.h"

#define sectionOneKeys @[@"名称", @"MAC", @"设备数", @"网络设置"]

@interface CSRGatewayViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) CSRDeviceEntity *device;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation CSRGatewayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = ColorWithAlpha(238, 238, 243, 1);
    UIButton *btn = [[UIButton alloc] init];
    [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
    [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
    [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = back;
    if (_deviceId) {
        _device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        self.title = _device.name;
        _dataArray = [[NSMutableArray alloc] initWithObjects:_device.name, [self macStringConcatenate], @0, @0, nil];
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 0.001)];
        [self.view addSubview:_tableView];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 11.0, *)) {
            NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view.safeAreaLayoutGuide attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
            NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view.safeAreaLayoutGuide attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
            NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
            NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_tableView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view.safeAreaLayoutGuide attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
            [NSLayoutConstraint activateConstraints:@[top, left, bottom, right]];
        } else {
            // Fallback on earlier versions
        }
    }
    
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)macStringConcatenate {
    NSString *macAddr = [_device.uuid substringFromIndex:24];
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
    return doneTitle;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CSRGATEWAYCELL"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CSRGATEWAYCELL"];
    }
    cell.textLabel.text = [sectionOneKeys objectAtIndex:indexPath.row];
    switch (indexPath.row) {
        case 0:
        case 1:
            cell.detailTextLabel.text = [_dataArray objectAtIndex:indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        case 2:
            cell.detailTextLabel.text = [[_dataArray objectAtIndex:indexPath.row] stringValue];
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        case 3:
            cell.detailTextLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case 0:
            [self rename];
            break;
        case 3:
            [self network];
            break;
        default:
            break;
    }
}

- (void)rename {
    UIAlertController *renameAlert = [UIAlertController alertControllerWithTitle:@"输入新名称" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [renameAlert.view setTintColor:DARKORAGE];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = renameAlert.textFields.firstObject;
        if ([textField.text length] > 0 && ![textField.text isEqualToString:_device.name]) {
            _device.name = textField.text;
            [[CSRDatabaseManager sharedInstance] saveContext];
            self.title = textField.text;
            [_dataArray replaceObjectAtIndex:0 withObject:textField.text];
            [_tableView reloadData];
            if (self.renameBlock) {
                self.renameBlock();
            }
        }
    }];
    [renameAlert addAction:cancel];
    [renameAlert addAction:confirm];
    [renameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textAlignment = NSTextAlignmentCenter;
    }];
    [self presentViewController:renameAlert animated:YES completion:nil];
}

- (void)network {
    NetworkSettingVC *nsvc = [[NetworkSettingVC alloc] init];
    nsvc.deviceId = _deviceId;
    [self.navigationController pushViewController:nsvc animated:YES];
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
