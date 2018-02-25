//
//  DeviceListViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/31.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "DeviceListViewController.h"
#import "MainCollectionView.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceEntity.h"
#import "MainCollectionViewCell.h"
#import "SingleDeviceModel.h"

@interface DeviceListViewController ()<MainCollectionViewDelegate>

@property (nonatomic,strong) MainCollectionView *devicesCollectionView;
@property (nonatomic,strong) NSMutableArray *selectedDevices;
@property (nonatomic,copy) DeviceListSelectedHandle handle;

@end

@implementation DeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.hidden = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.title = @"Choose device";
    self.view.backgroundColor = [UIColor colorWithRed:195/255.0 green:195/255.0 blue:195/255.0 alpha:1];
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finishSelectingDevice)];
    self.navigationItem.rightBarButtonItem = done;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = WIDTH*8.0/640.0;
    flowLayout.minimumInteritemSpacing = WIDTH*8.0/640.0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, WIDTH*3/160.0);
    flowLayout.itemSize = CGSizeMake(WIDTH*5/16.0, WIDTH*9/32.0);
    
    _devicesCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectMake(WIDTH*3/160.0, WIDTH*12/640.0+64, WIDTH*157/160.0, HEIGHT-64-WIDTH*3/160.0) collectionViewLayout:flowLayout cellIdentifier:@"MainCollectionViewCell"];
    _devicesCollectionView.mainDelegate = self;
    
    NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
    if (mutableArray != nil || [mutableArray count] != 0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([deviceEntity.shortName isEqualToString:@"D350BT"] || [deviceEntity.shortName isEqualToString:@"S350BT"]) {
                SingleDeviceModel *singleDevice = [[SingleDeviceModel alloc] init];
                singleDevice.deviceId = deviceEntity.deviceId;
                singleDevice.deviceName = deviceEntity.name;
                singleDevice.deviceShortName = deviceEntity.shortName;
                [_devicesCollectionView.dataArray addObject:singleDevice];
            }
        }];
    }
    
    [self.view addSubview:_devicesCollectionView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
            cell.seleteButton.hidden = NO;
            [self.originalMembers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stoppp) {
                if ([obj isKindOfClass:[SingleDeviceModel class]]) {
                    SingleDeviceModel *deviceEntity = (SingleDeviceModel *)obj;
                    if ([cell.deviceId isEqualToNumber:deviceEntity.deviceId]) {
                        cell.seleteButton.selected = YES;
                        NSLog(@">><<>><<");
                        [cell.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
                        [self.selectedDevices addObject:cell.deviceId];
                        *stoppp = YES;
                    }
                }
            }];
        }];
    });
    
    
}

- (void)mainCollectionViewDelegateSelectAction:(NSNumber *)cellDeviceId {

    if (self.selectMode == DeviceListSelectMode_Single) {
        [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (cell.seleteButton.selected && ![cell.deviceId isEqualToNumber:cellDeviceId]) {
                cell.seleteButton.selected = NO;
                [cell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                if ([self.selectedDevices containsObject:cell.deviceId]) {
                    [self.selectedDevices removeObject:cell.deviceId];
                }
            }else if ([cell.deviceId isEqualToNumber:cellDeviceId]) {
                cell.seleteButton.selected = YES;
                [cell.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
                [self.selectedDevices addObject:cellDeviceId];
            }
        }];
    }else {
        [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([cell.deviceId isEqualToNumber:cellDeviceId]) {
                if (cell.seleteButton.selected) {
                    cell.seleteButton.selected = NO;
                    [cell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                    if ([self.selectedDevices containsObject:cellDeviceId]) {
                        [self.selectedDevices removeObject:cellDeviceId];
                    }
                }else {
                    cell.seleteButton.selected = YES;
                    [cell.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
                    [self.selectedDevices addObject:cellDeviceId];
                }
            }
        }];
    }
    
    
    if ([self.selectedDevices count]>0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)finishSelectingDevice {
    if (self.handle) {
        self.handle(self.selectedDevices);
        self.handle = nil;
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}

- (void)getSelectedDevices:(DeviceListSelectedHandle)handle {
    self.handle = nil;
    self.handle = handle;
}

- (NSMutableArray *)selectedDevices {
    if (!_selectedDevices) {
        _selectedDevices = [[NSMutableArray alloc] init];
    }
    return _selectedDevices;
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
