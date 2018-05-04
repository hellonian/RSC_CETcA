//
//  AddDevcieViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/19.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "AddDevcieViewController.h"
#import "MainCollectionView.h"
#import <MBProgressHUD.h>
#import "CSRBluetoothLE.h"
#import "CSRDevicesManager.h"
#import "CSRConstants.h"

@interface AddDevcieViewController ()<MBProgressHUDDelegate,MainCollectionViewDelegate>
{
    NSTimer *timer;
    NSInteger num;
}

@property (nonatomic,strong) MainCollectionView *mainCollectionView;
@property (nonatomic,strong) MBProgressHUD *searchHud;
@property (nonatomic,strong) MBProgressHUD *associateHud;
@property (nonatomic,strong) MBProgressHUD *noneNewHud;
@property (nonatomic,strong) CSRmeshDevice *selectedDevice;

@end

@implementation AddDevcieViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor colorWithRed:195/255.0 green:195/255.0 blue:195/255.0 alpha:1];
    self.navigationItem.title = @"Search New Devices";
    
    UIButton *letfButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *btnImage = [UIImage imageNamed:@"Btn_back"];
    [letfButton setImage:btnImage forState:UIControlStateNormal];
    NSString *btnTitle = @" Back";
    [letfButton setTitle:btnTitle forState:UIControlStateNormal];
    [letfButton setTitleColor:DARKORAGE forState:UIControlStateNormal];
    CGSize buttonTitleLabelSize = [btnTitle sizeWithAttributes:@{NSFontAttributeName:letfButton.titleLabel.font}]; //文本尺寸
    CGSize buttonImageSize = btnImage.size;   //图片尺寸
    letfButton.frame = CGRectMake(0,0,
                              buttonImageSize.width + buttonTitleLabelSize.width,
                              buttonImageSize.height);
    [letfButton addTarget:self action:@selector(addVCBackAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithCustomView:letfButton];
    self.navigationItem.leftBarButtonItem = left;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = WIDTH*8.0/640.0;
    flowLayout.minimumInteritemSpacing = WIDTH*8.0/640.0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, floor(WIDTH*3/160.0));
    flowLayout.itemSize = CGSizeMake(WIDTH*5/16.0, WIDTH*9/32.0);
    
    _mainCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectMake(WIDTH*3/160.0, WIDTH*12/640.0+64, WIDTH*157/160.0, HEIGHT-64-WIDTH*3/160.0) collectionViewLayout:flowLayout cellIdentifier:@"MainCollectionViewCell"];
    _mainCollectionView.mainDelegate = self;
    
    [self.view addSubview:_mainCollectionView];
    
}

- (void)addVCBackAction {
    if (self.handle) {
        self.handle();
    }
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDiscoverDeviceNotification:) name:kCSRmeshManagerDidDiscoverDeviceNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateAppearanceNotification:)
                                                 name:kCSRmeshManagerDidUpdateAppearanceNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displayAssociationProgress:)
                                                 name:kCSRmeshManagerDeviceAssociationProgressNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceAssociationFailed:)
                                                 name:kCSRmeshManagerDeviceAssociationFailedNotification
                                               object:nil];
    
    _searchHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _searchHud.mode = MBProgressHUDModeIndeterminate;
    _searchHud.delegate = self;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerMethd:) userInfo:nil repeats:YES];
    num = 0;
    
    [[CSRBluetoothLE sharedInstance] setScanner:YES source:self];
    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:YES];
    [self getDataArray];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDidDiscoverDeviceNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDidUpdateAppearanceNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDeviceAssociationProgressNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDeviceAssociationFailedNotification
                                                  object:nil];
    
    [[CSRDevicesManager sharedInstance] deleteDevicesInArray];
    [[CSRBluetoothLE sharedInstance] setScanner:NO source:self];
    [[CSRDevicesManager sharedInstance] setDeviceDiscoveryFilter:self mode:NO];
}

- (void)timerMethd:(id)userInfo {
    num++;
    if (num == 20) {
        [_searchHud hideAnimated:YES];
        _noneNewHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _noneNewHud.mode = MBProgressHUDModeText;
        _noneNewHud.delegate = self;
        _noneNewHud.label.text = @"No new device was found.";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (_noneNewHud) {
                [_noneNewHud hideAnimated:YES];
            }
            CATransition *animation = [CATransition animation];
            [animation setDuration:0.3];
            [animation setType:kCATransitionMoveIn];
            [animation setSubtype:kCATransitionFromLeft];
            [self.view.window.layer addAnimation:animation forKey:nil];
            [self dismissViewControllerAnimated:NO completion:nil];
        });
        [timer invalidate];
        timer = nil;
    }
}

- (void)getDataArray {
    
    for (CSRmeshDevice *device in [[CSRDevicesManager sharedInstance] unassociatedMeshDevices]) {
        if (![_mainCollectionView.dataArray containsObject:device]) {
            [_mainCollectionView.dataArray addObject:device];
        }
        
    }
    if ([_mainCollectionView.dataArray count]>0) {
        [_searchHud hideAnimated:YES];
        [timer invalidate];
        timer = nil;
        if (_noneNewHud) {
            [_noneNewHud hideAnimated:YES];
        }
    }
    [_mainCollectionView reloadData];
}

#pragma mark - Notification

-(void)didDiscoverDeviceNotification:(NSNotification *)notification{
    if (![self alreadyDiscoveredDeviceFilteringWithDeviceUUID:(NSUUID *)notification.userInfo[kDeviceUuidString]]) {
        [[CSRDevicesManager sharedInstance] addDeviceWithUUID:notification.userInfo[kDeviceUuidString] andRSSI:notification.userInfo[kDeviceRssiString]];
    }
}

-(BOOL)alreadyDiscoveredDeviceFilteringWithDeviceUUID:(NSUUID *)uuid{
    for (id value in [[CSRDevicesManager sharedInstance] unassociatedMeshDevices]) {
        if ([value isKindOfClass:[CSRmeshDevice class]]) {
            CSRmeshDevice *device = value;
            if ([device.uuid.UUIDString isEqualToString:uuid.UUIDString]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)didUpdateAppearanceNotification:(NSNotification *)notification
{
    NSData *updatedDeviceHash = notification.userInfo [kDeviceHashString];
    NSNumber *appearanceValue = notification.userInfo [kAppearanceValueString];
    NSData *shortName = notification.userInfo [kShortNameString];
    if (![self alreadyDiscoveredDeviceFilteringWithDeviceHash:notification.userInfo[kDeviceHashString]]) {
        [[CSRDevicesManager sharedInstance] updateAppearance:updatedDeviceHash appearanceValue:appearanceValue shortName:shortName];
        [self getDataArray];
    }
}

- (BOOL)alreadyDiscoveredDeviceFilteringWithDeviceHash:(NSData *)data
{
    for (id value in [[CSRDevicesManager sharedInstance] unassociatedMeshDevices]) {
        if ([value isKindOfClass:[CSRmeshDevice class]]) {
            CSRmeshDevice *device = value;
            if ([device.deviceHash isEqualToData:data]) {
                return YES;
            }
        }
    }
    return NO;
}

//入网过程进度条
- (void)displayAssociationProgress:(NSNotification *)notification {
    NSNumber *completedSteps = notification.userInfo[@"stepsCompleted"];
    NSNumber *totalSteps = notification.userInfo[@"totalSteps"];

    if ([completedSteps floatValue] <= [totalSteps floatValue] && [completedSteps floatValue] > 0) {
        CGFloat completed = [completedSteps floatValue]/[totalSteps floatValue];
        _associateHud.label.text = [NSString stringWithFormat:@"Associating: %.0f%%", (completed * 100)];
        _associateHud.progress = completed;
        if (completed >= 1) {
            if ([_mainCollectionView.dataArray count] == 0) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [_associateHud hideAnimated:YES];
                    [self addVCBackAction];
                });
                
            }else {
                [_associateHud hideAnimated:YES];
            }
        }
        [_mainCollectionView.dataArray removeObject:_selectedDevice];
        [_mainCollectionView reloadData];
    } else {
        NSLog(@"ERROR: There was and issue with device association");
    }
}

- (void)deviceAssociationFailed:(NSNotification *)notification
{
    _associateHud.label.text = [NSString stringWithFormat:@"Association error: %@", notification.userInfo[@"error"]];
}

#pragma mark - MainCollectionViewDelegate

- (void)mainCollectionViewTapCellAction:(NSNumber *)cellDeviceId cellIndexPath:(NSIndexPath *)indexPath {
    
    if ([cellDeviceId isEqualToNumber:@3000]) {
        _selectedDevice = [_mainCollectionView.dataArray objectAtIndex:indexPath.row];
        
        if (_selectedDevice) {
            [[CSRDevicesManager sharedInstance] setAttentionPreAssociation:_selectedDevice.deviceHash attentionState:@(1) withDuration:@(6000)];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Are you sure to add the selected device？" message:nil preferredStyle:UIAlertControllerStyleAlert];
            
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:@"Are you sure to add the selected device?"];
            [attributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedTitle string] length])];
            [alert setValue:attributedTitle forKey:@"attributedTitle"];
            
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [cancel setValue:DARKORAGE forKey:@"titleTextColor"];
            UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self associateDevice];
            }];
            [confirm setValue:DARKORAGE forKey:@"titleTextColor"];
            [alert addAction:cancel];
            [alert addAction:confirm];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void)associateDevice {
    [[CSRDevicesManager sharedInstance].unassociatedMeshDevices removeAllObjects];
    if (_selectedDevice.appearanceShortname) {
        [[CSRDevicesManager sharedInstance] associateDeviceFromCSRDeviceManager:_selectedDevice.deviceHash authorisationCode:nil];
        
        _associateHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _associateHud.mode = MBProgressHUDModeDeterminateHorizontalBar;
        _associateHud.delegate = self;
        _associateHud.label.font = [UIFont systemFontOfSize:13];
        _associateHud.label.numberOfLines = 0;
        _associateHud.label.text = @"Associating: 0%";
    }
}



#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

@end
