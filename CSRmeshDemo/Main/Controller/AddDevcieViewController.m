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

@property (nonatomic,strong) MainCollectionView *mainCollectionView;
@property (nonatomic,strong) MBProgressHUD *searchHud;
@property (nonatomic,strong) MBProgressHUD *associateHud;
@property (nonatomic,strong) CSRmeshDevice *selectedDevice;

@end

@implementation AddDevcieViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor colorWithRed:195/255.0 green:195/255.0 blue:195/255.0 alpha:1];
    self.navigationItem.title = @"Search New Devices";
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(addVCBackAction)];
    self.navigationItem.leftBarButtonItem = left;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = WIDTH*8.0/640.0;
    flowLayout.minimumInteritemSpacing = WIDTH*8.0/640.0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, WIDTH*3/160.0);
    flowLayout.itemSize = CGSizeMake(WIDTH*5/16.0, WIDTH*9/32.0);
    
    _mainCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectMake(WIDTH*3/160.0, WIDTH*12/640.0+64, WIDTH*157/160.0, HEIGHT-64-WIDTH*3/160.0) collectionViewLayout:flowLayout cellIdentifier:@"MainCollectionViewCell"];
    _mainCollectionView.mainDelegate = self;
    
    _mainCollectionView.dataArray = [NSMutableArray arrayWithObjects:@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss", nil];
    
    [self.view addSubview:_mainCollectionView];
    
}

- (void)addVCBackAction {
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

- (void)getDataArray {
    [_mainCollectionView.dataArray removeAllObjects];
    
    for (CSRmeshDevice *device in [[CSRDevicesManager sharedInstance] unassociatedMeshDevices]) {
        [_mainCollectionView.dataArray addObject:device];
    }
    if ([_mainCollectionView.dataArray count]>0) {
        [_searchHud hideAnimated:YES];
    }
    [_mainCollectionView reloadData];
}

#pragma mark - Notification

-(void)didDiscoverDeviceNotification:(NSNotification *)notification{
    if (![self alreadyDiscoveredDeviceFilteringWithDeviceUUID:(NSUUID *)notification.userInfo[kDeviceUuidString]]) {
        NSLog(@"uuid>>notification>> %@",notification.userInfo[kDeviceUuidString]);
        [[CSRDevicesManager sharedInstance] addDeviceWithUUID:notification.userInfo[kDeviceUuidString] andRSSI:notification.userInfo[kDeviceRssiString]];
        [self getDataArray];
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

////入网过程进度条
//- (void)displayAssociationProgress:(NSNotification *)notification {
//    NSNumber *completedSteps = notification.userInfo[@"stepsCompleted"];
//    NSNumber *totalSteps = notification.userInfo[@"totalSteps"];
//
//    if ([completedSteps floatValue] <= [totalSteps floatValue] && [completedSteps floatValue] > 0) {
//        CGFloat completed = [completedSteps floatValue]/[totalSteps floatValue];
//        _hud.label.text = [NSString stringWithFormat:@"Associating device: %.0f%%", (completed * 100)];
//        _hud.progress = completed;
//        if (completed >= 1) {
//            [self.hud hideAnimated:YES];
//        }
//        [_mainCollectionView.dataArray removeObject:_selectedDevice];
//        [_mainCollectionView reloadData];
//    } else {
//        NSLog(@"ERROR: There was and issue with device association");
//    }
//}
//
//- (void)deviceAssociationFailed:(NSNotification *)notification
//{
//    _hud.label.text = [NSString stringWithFormat:@"Association error: %@", notification.userInfo[@"error"]];
//}

- (void)mainCollectionViewAddDeviceAction:(NSNumber *)cellDeviceId {
    if ([cellDeviceId isEqualToNumber:@3000]) {
        NSLog(@"sdsdadadfa");
        
        
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
