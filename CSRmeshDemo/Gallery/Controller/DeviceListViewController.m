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
#import "DeviceModelManager.h"
#import "ImproveTouchingExperience.h"
#import "ControlMaskView.h"
//#import <CSRmesh/LightModelApi.h>

@interface DeviceListViewController ()<MainCollectionViewDelegate>

@property (nonatomic,strong) MainCollectionView *devicesCollectionView;
@property (nonatomic,strong) NSMutableArray *selectedDevices;
@property (nonatomic,copy) DeviceListSelectedHandle handle;
@property (nonatomic,strong) NSNumber *originalLevel;
@property (nonatomic,strong) ImproveTouchingExperience *improver;
@property (nonatomic,strong) ControlMaskView *maskLayer;

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
    
    self.improver = [[ImproveTouchingExperience alloc] init];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
            cell.seleteButton.hidden = NO;
            [self.originalMembers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stoppp) {
                if ([obj isKindOfClass:[SingleDeviceModel class]]) {
                    SingleDeviceModel *deviceEntity = (SingleDeviceModel *)obj;
                    if ([cell.deviceId isEqualToNumber:deviceEntity.deviceId]) {
                        cell.seleteButton.selected = YES;
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

#pragma mark - MainCollectionViewDelegate

- (void)mainCollectionViewDelegatePanBrightnessWithTouchPoint:(CGPoint)touchPoint withOrigin:(CGPoint)origin toLight:(NSNumber *)deviceId groupId:(NSNumber *)groupId withPanState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction {
    DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
    if (state == UIGestureRecognizerStateBegan) {
        self.originalLevel = model.level;
        [self.improver beginImproving];
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:deviceId withLevel:self.originalLevel withState:state direction:direction];
        return;
    }
    if (state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateEnded) {
        NSInteger updateLevel = [self.improver improveTouching:touchPoint referencePoint:origin primaryBrightness:[self.originalLevel integerValue]];

        CGFloat percentage = updateLevel/255.0*100;
        [self showControlMaskLayerWithAlpha:updateLevel/255.0 text:[NSString stringWithFormat:@"%.f",percentage]];
//        if (updateLevel == 0) {
//            [[LightModelApi sharedInstance] setLevel:deviceId level:@1 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
//
//            } failure:^(NSError * _Nullable error) {
//
//            }];
//        }
        [[DeviceModelManager sharedInstance] setLevelWithDeviceId:deviceId withLevel:@(updateLevel) withState:state direction:direction];
        
        if (state == UIGestureRecognizerStateEnded) {
            [self hideControlMaskLayer];
        }
        return;
    }
}

- (void)hideControlMaskLayer {
    if (_maskLayer && _maskLayer.superview) {
        [self.maskLayer removeFromSuperview];
    }
}

- (void)showControlMaskLayerWithAlpha:(CGFloat)percentage text:(NSString*)text {
    if (!_maskLayer.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:self.maskLayer];
    }
    [self.maskLayer updateProgress:percentage withText:text];
}

#pragma mark - lazy

- (ControlMaskView*)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [[ControlMaskView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _maskLayer;
}

@end
