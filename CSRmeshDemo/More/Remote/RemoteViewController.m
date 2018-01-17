//
//  RemoteViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/30.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "RemoteViewController.h"
#import "RemoteTCell.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceEntity.h"
#import "PrimaryDeviceListController.h"
#import <CSRmesh/MeshServiceApi.h>
#import "CSRBluetoothLE.h"
#import "CSRDevicesManager.h"
#import <MBProgressHUD.h>
#import "CSRDatabaseManager.h"
#import "PureLayout.h"
#import "SingleBtnCell.h"


@interface RemoteViewController ()<UITableViewDelegate,UITableViewDataSource,RemoteTCellDelegate,MBProgressHUDDelegate,SingleRemoteCellDelegate>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *dataArray;
@property (nonatomic,strong) MBProgressHUD *hub;
@property (nonatomic,strong) CSRmeshDevice *deleteDevice;
@property (nonatomic,strong) UIActivityIndicatorView *spinner;
@property (nonatomic,strong) UIView *noneDataView;
@property (nonatomic,assign) BOOL setSuccess;

@end

@implementation RemoteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgImage"]];
    imageView.frame = [UIScreen mainScreen].bounds;
    [self.view addSubview:imageView];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.title = @"Remotes";
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editClick)];
    self.navigationItem.rightBarButtonItem = edit;
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backClick)];
    self.navigationItem.leftBarButtonItem = close;
    
    [self getData];
    if (self.dataArray.count > 0) {
        [self.view addSubview:self.tableView];
        [_tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(64, 0, 50, 0)];
    }else {
        [self.view addSubview:self.noneDataView];
        [_noneDataView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(100, 50, 100, 50)];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reGetData) name:@"reGetData" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingRemoteCall:) name:@"settingRemoteCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deleteStatus:)
                                                 name:kCSRDeviceManagerDeviceFoundForReset
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"settingRemoteCall" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRDeviceManagerDeviceFoundForReset
                                                  object:nil];
}

- (void)editClick {
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneClick)];
    self.navigationItem.rightBarButtonItem = done;
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addClick)];
    self.navigationItem.leftBarButtonItem = add;
}

- (void)backClick {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) doneClick {
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editClick)];
    self.navigationItem.rightBarButtonItem = edit;
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backClick)];
    self.navigationItem.leftBarButtonItem = close;
}

- (void) addClick {
    if ([[MeshServiceApi sharedInstance] getActiveBearer] == 0) {
        [[CSRBluetoothLE sharedInstance] setScanner:YES source:self];
        [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:YES];
        PrimaryDeviceListController *pdlvc = [[PrimaryDeviceListController alloc] initWithItemPerSection:3 cellIdentifier:@"PrimaryItemCell"];
        [self.navigationController pushViewController:pdlvc animated:YES];
    }
}

- (void)reGetData {
    [self getData];
    
    [self updateTableView];
    
}

- (void)getData {
    [self.dataArray removeAllObjects];
    NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
    if (mutableArray != nil || [mutableArray count] != 0) {
        for (CSRDeviceEntity *deviceEntity in mutableArray) {
            if ([deviceEntity.shortName isEqualToString:@"RC350"] || [deviceEntity.shortName isEqualToString:@"RC351"]) {
                [self.dataArray addObject:deviceEntity];
            }
        }
    }
}

-(void)updateTableView {
    
    if ([self.dataArray count] == 0) {
        [self.view addSubview:self.noneDataView];
        [_noneDataView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(100, 50, 100, 50)];
        [self.tableView removeFromSuperview];
    }else {
        [self.view addSubview:self.tableView];
        [_tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(64, 0, 50, 0)];
        [self.noneDataView removeFromSuperview];
        [self.tableView reloadData];
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CSRDeviceEntity *deviceEntity = [_dataArray objectAtIndex:indexPath.row];
    if ([deviceEntity.shortName isEqualToString:@"RC350"]) {
        RemoteTCell *remoteCell= [tableView dequeueReusableCellWithIdentifier:@"RemoteTCell" forIndexPath:indexPath];
        if (remoteCell) {
            remoteCell.backgroundColor = [UIColor clearColor];
            remoteCell.selectionStyle = UITableViewCellSelectionStyleNone;
            remoteCell.preservesSuperviewLayoutMargins = NO;
            remoteCell.separatorInset = UIEdgeInsetsZero;
            remoteCell.layoutMargins = UIEdgeInsetsZero;
            remoteCell.remoteName.text = deviceEntity.name;
            remoteCell.myDeviceId = deviceEntity.deviceId;
            remoteCell.delegate = self;
        }

        return remoteCell;
    }else {
        SingleBtnCell *singleBtnRemoteCell = [tableView dequeueReusableCellWithIdentifier:@"SingleBtnCell" forIndexPath:indexPath];
        if (singleBtnRemoteCell) {
            singleBtnRemoteCell.backgroundColor = [UIColor clearColor];
            singleBtnRemoteCell.selectionStyle = UITableViewCellSelectionStyleNone;
            singleBtnRemoteCell.preservesSuperviewLayoutMargins = NO;
            singleBtnRemoteCell.separatorInset = UIEdgeInsetsZero;
            singleBtnRemoteCell.layoutMargins = UIEdgeInsetsZero;
            singleBtnRemoteCell.remoteName.text = deviceEntity.name;
            singleBtnRemoteCell.myDeviceId = deviceEntity.deviceId;
            singleBtnRemoteCell.delegate =self;
        }
        
        return singleBtnRemoteCell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 300;
}

#pragma mark - RemoteTCellDelegate

- (void)pushToDeviceList:(ConfiguredDeviceListController *)list {
    [self.navigationController pushViewController:list animated:YES];
}

- (void)pushToDeviceListSingle:(ConfiguredDeviceListController *)list {
    [self.navigationController pushViewController:list animated:YES];
}

- (void)deleteRemoteTapped:(NSNumber *)deviceId {
    [self deleteRemote:deviceId];
}

- (void)deleteRemoteTappedSingle:(NSNumber *)deviceId {
    [self deleteRemote:deviceId];
}

- (void)deleteRemote:(NSNumber *)deviceId {
    _deleteDevice = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:deviceId];
    CSRPlaceEntity *placeEntity = [CSRAppStateManager sharedInstance].selectedPlace;
    
    if (![CSRUtilities isStringEmpty:placeEntity.passPhrase]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Device" message:[NSString stringWithFormat:@"Are you sure that you want to delete this device :%@?",_deleteDevice.name] preferredStyle:UIAlertControllerStyleAlert];
        [alertController.view setTintColor:DARKORAGE];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (_deleteDevice) {
                [[CSRDevicesManager sharedInstance] initiateRemoveDevice:_deleteDevice];
            }
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [_spinner stopAnimating];
            [_spinner setHidden:YES];
        }];
        [alertController addAction:okAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.view addSubview:_spinner];
        _spinner.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        [_spinner startAnimating];
    }
    else
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert!!"
                                                                                 message:@"You should be place owner to associate a device"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             
                                                         }];
        
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

-(void)deleteStatus:(NSNotification *)notification
{
    [_spinner stopAnimating];
    
    NSNumber *num = notification.userInfo[@"boolFlag"];
    if ([num boolValue] == NO) {
        [self showForceAlert];
    } else {
        for (CSRDeviceEntity *deviceEntity in self.dataArray) {
            if ([deviceEntity.deviceId isEqualToNumber:_deleteDevice.deviceId]) {
                [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:deviceEntity];
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:deviceEntity];
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
        }
        
        NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
        //        [[MeshServiceApi sharedInstance] setNextDeviceId:deviceNumber];
        [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
        
        [self reGetData];
    }
}

- (void) showForceAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Device Device"
                                                                             message:[NSString stringWithFormat:@"Device wasn't found. Do you want to delete %@ anyway?", _deleteDevice.name]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [_spinner stopAnimating];
                                                             [_spinner setHidden:YES];
                                                         }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Yes"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         
                                                         for (CSRDeviceEntity *deviceEntity in self.dataArray) {
                                                             if ([deviceEntity.deviceId isEqualToNumber:_deleteDevice.deviceId]) {
                                                                 [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:deviceEntity];
                                                                 [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:deviceEntity];
                                                                 [[CSRDatabaseManager sharedInstance] saveContext];
                                                             }
                                                         }
                                                         NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
                                                         //                                                         [[MeshServiceApi sharedInstance] setNextDeviceId:deviceNumber];
                                                         [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
                                                         [self reGetData];
                                                     }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)showHud {
    [self showHudTogether];
}

-(void)showHudSingle {
    [self showHudTogether];
}

- (void)showHudTogether {
    _hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hub.mode = MBProgressHUDModeDeterminateHorizontalBar;
    _hub.delegate = self;
    _hub.label.text = @"Please press the button in the middle of the remote five times continuously";
    _hub.label.font = [UIFont systemFontOfSize:13];
    _hub.label.numberOfLines = 0;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        float progress = 0.0f;
        while (progress < 1.0f) {
            progress +=0.01f;
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD HUDForView:self.view].progress = progress;
            });
            usleep(100000);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_hub hideAnimated:YES];
            if (_setSuccess == NO) {
                [self showTextHud:@"Time out"];
            }
        });
        
    });
}

- (void)settingRemoteCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSString *state = dic[@"settingRemoteCall"];
    [_hub hideAnimated:YES];
    if ([state boolValue]) {
        _setSuccess = YES;
        [self showTextHud:@"SUCCESS"];
    }else {
        _setSuccess = NO;
        [self showTextHud:@"ERROR"];
    }
    
}
- (void)showTextHud:(NSString *)text {
    MBProgressHUD *successHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    successHud.mode = MBProgressHUDModeText;
    successHud.label.text = text;
    successHud.delegate = self;
    [successHud hideAnimated:YES afterDelay:1.5f];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        [_tableView registerNib:[UINib nibWithNibName:@"RemoteTCell" bundle:nil] forCellReuseIdentifier:@"RemoteTCell"];
        [_tableView registerNib:[UINib nibWithNibName:@"SingleBtnCell" bundle:nil] forCellReuseIdentifier:@"SingleBtnCell"];
    }
    return _tableView;
}

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc] init];
    }
    return _dataArray;
}

- (UIView *)noneDataView {
    if (!_noneDataView) {
        _noneDataView = [[UIView alloc] init];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImage imageNamed:@"remotebg"];
        [_noneDataView addSubview:imageView];
        
        UILabel *label = [[UILabel alloc] init];
        label.text = @"You can add your bluetooth remotes and assign lights to the buttons of the remotes.";
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor lightGrayColor];
        label.numberOfLines = 0;
        [_noneDataView addSubview:label];
        
        UIButton *btn = [[UIButton alloc] init];
        [btn setTitle:@"Add a remote" forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(addClick) forControlEvents:UIControlEventTouchUpInside];
        [_noneDataView addSubview:btn];
        
        [imageView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:_noneDataView];
        [imageView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:_noneDataView];
        [imageView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:_noneDataView];
        [imageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:imageView];
        [label autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:imageView];
        [label autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:_noneDataView];
        [label autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [label autoSetDimension:ALDimensionHeight toSize:60];
        [btn autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:label withOffset:40];
        [btn autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [btn autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:_noneDataView withMultiplier:0.5];
        [btn autoSetDimension:ALDimensionHeight toSize:40];
        
    }
    return _noneDataView;
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
