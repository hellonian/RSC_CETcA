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
#import "CSRUtilities.h"
#import "CSRAreaEntity.h"
#import "SceneEntity.h"

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
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Select", @"Localizable");
    self.view.backgroundColor = [UIColor colorWithRed:195/255.0 green:195/255.0 blue:195/255.0 alpha:1];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.bounds = CGRectMake(0, 0, 80, 40);
    [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
    [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
    [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [btn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = back;
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(finishSelectingDevice)];
    self.navigationItem.rightBarButtonItem = done;
    if (self.selectMode == DeviceListSelectMode_ForDrop) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = WIDTH*8.0/640.0;
    flowLayout.minimumInteritemSpacing = WIDTH*8.0/640.0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, WIDTH*3/160.0);
    flowLayout.itemSize = CGSizeMake(WIDTH*5/16.0, WIDTH*9/32.0);
    
    _devicesCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectMake(WIDTH*3/160.0, WIDTH*12/640.0+64, WIDTH*157/160.0, HEIGHT-64-WIDTH*3/160.0) collectionViewLayout:flowLayout cellIdentifier:@"MainCollectionViewCell"];
    _devicesCollectionView.mainDelegate = self;
    
    if (self.selectMode == DeviceListSelectMode_ForGroup) {
        
        if (self.originalMembers!=nil && [self.originalMembers count] != 0) {
            [_devicesCollectionView.dataArray addObjectsFromArray:self.originalMembers];
        }
        
        __block NSMutableArray *deviceIdWasInAreaArray =[[NSMutableArray alloc] init];
        NSSet *areas =  [CSRAppStateManager sharedInstance].selectedPlace.areas;
        if (areas != nil && [areas count] != 0) {
            [areas enumerateObjectsUsingBlock:^(CSRAreaEntity *area, BOOL * _Nonnull stop) {
                for (CSRDeviceEntity *deviceEntity in area.devices) {
                    [deviceIdWasInAreaArray addObject:deviceEntity.deviceId];
                }
            }];
        }
        
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if (mutableArray != nil || [mutableArray count] != 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                if (([CSRUtilities belongToDimmer:deviceEntity.shortName] || [CSRUtilities belongToSwitch:deviceEntity.shortName]) && ![deviceIdWasInAreaArray containsObject:deviceEntity.deviceId]) {
                    SingleDeviceModel *singleDevice = [[SingleDeviceModel alloc] init];
                    singleDevice.deviceId = deviceEntity.deviceId;
                    singleDevice.deviceName = deviceEntity.name;
                    singleDevice.deviceShortName = deviceEntity.shortName;
                    
                    __block BOOL exist = 0;
                    [_devicesCollectionView.dataArray enumerateObjectsUsingBlock:^(SingleDeviceModel *singleDevice, NSUInteger idx, BOOL * _Nonnull newstop) {
                        if ([singleDevice.deviceId isEqualToNumber:deviceEntity.deviceId]) {
                            exist = YES;
                            *newstop = YES;
                        }
                    }];
                    
                    if (!exist) {
                        [_devicesCollectionView.dataArray addObject:singleDevice];
                    }
                    
                }
            }];
        }
        
        
    }else if (self.selectMode == DeviceListSelectMode_SelectGroup) {
        
        NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
        if (areaMutableArray != nil || [areaMutableArray count] != 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
            [areaMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            _devicesCollectionView.dataArray = areaMutableArray;
        }
        
    }else if (self.selectMode == DeviceListSelectMode_SelectScene) {
        
        NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.scenes allObjects] mutableCopy];
        if (areaMutableArray != nil || [areaMutableArray count] != 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sceneID" ascending:YES];
            [areaMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            _devicesCollectionView.dataArray = areaMutableArray;
        }
        
    }else if (self.selectMode == DeviceListSelectMode_ForLightSensor) {
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if (mutableArray != nil || [mutableArray count] != 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([deviceEntity.shortName isEqualToString:@"D1-10IB"]) {
                    [_devicesCollectionView.dataArray addObject:deviceEntity];
                }
            }];
        }
    }else {
        NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
        if (mutableArray != nil || [mutableArray count] != 0) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
            [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([CSRUtilities belongToDimmer:deviceEntity.shortName] || [CSRUtilities belongToSwitch:deviceEntity.shortName]) {
                    SingleDeviceModel *singleDevice = [[SingleDeviceModel alloc] init];
                    singleDevice.deviceId = deviceEntity.deviceId;
                    singleDevice.deviceName = deviceEntity.name;
                    singleDevice.deviceShortName = deviceEntity.shortName;
                    [_devicesCollectionView.dataArray addObject:singleDevice];
                }
            }];
        }
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
                if ([obj isKindOfClass:[CSRAreaEntity class]]) {
                    CSRAreaEntity *area = (CSRAreaEntity *)obj;
                    if ([area.areaID isEqualToNumber:cell.groupId]) {
                        cell.seleteButton.selected = YES;
                        [cell.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
                        [self.selectedDevices addObject:cell.groupId];
                        *stoppp = YES;
                    }
                }
                
                if ([obj isKindOfClass:[SceneEntity class]]) {
                    SceneEntity *scene = (SceneEntity *)obj;
                    if ([scene.rcIndex isEqualToNumber:cell.sceneId]) {
                        cell.seleteButton.selected = YES;
                        [cell.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
                        [self.selectedDevices addObject:cell.sceneId];
                        *stoppp = YES;
                    }
                }
            }];
        }];
    });
}

- (void)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)mainCollectionViewDelegateSelectAction:(NSNumber *)cellDeviceId cellGroupId:(NSNumber *)cellGroupId cellSceneId:(NSNumber *)cellSceneId{

    if (self.selectMode == DeviceListSelectMode_ForDrop) {
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
    }else if (self.selectMode == DeviceListSelectMode_Single) {
        [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([cell.deviceId isEqualToNumber:cellDeviceId]) {
                if (cell.seleteButton.selected) {
                    cell.seleteButton.selected = NO;
                    [cell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                    if ([self.selectedDevices containsObject:cell.deviceId]) {
                        [self.selectedDevices removeObject:cell.deviceId];
                    }
                }else {
                    cell.seleteButton.selected = YES;
                    [cell.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
                    if (![self.selectedDevices containsObject:cell.deviceId]) {
                        [self.selectedDevices addObject:cell.deviceId];
                    }
                }
            }else if (cell.seleteButton.selected) {
                cell.seleteButton.selected = NO;
                [cell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                if ([self.selectedDevices containsObject:cell.deviceId]) {
                    [self.selectedDevices removeObject:cell.deviceId];
                }
            }
        }];
    }else if (self.selectMode == DeviceListSelectMode_SelectGroup) {
        [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([cell.groupId isEqualToNumber:cellGroupId]) {
                if (cell.seleteButton.selected) {
                    cell.seleteButton.selected = NO;
                    [cell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                    if ([self.selectedDevices containsObject:cell.groupId]) {
                        [self.selectedDevices removeObject:cell.groupId];
                    }
                }else {
                    cell.seleteButton.selected = YES;
                    [cell.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
                    if (![self.selectedDevices containsObject:cell.groupId]) {
                        [self.selectedDevices addObject:cell.groupId];
                    }
                }
            }else if (cell.seleteButton.selected) {
                cell.seleteButton.selected = NO;
                [cell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                if ([self.selectedDevices containsObject:cell.groupId]) {
                    [self.selectedDevices removeObject:cell.groupId];
                }
            }
        }];
    }else if (self.selectMode == DeviceListSelectMode_SelectScene) {
        [_devicesCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([cell.sceneId isEqualToNumber:cellSceneId]) {
                if (cell.seleteButton.selected) {
                    cell.seleteButton.selected = NO;
                    [cell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                    if ([self.selectedDevices containsObject:cell.sceneId]) {
                        [self.selectedDevices removeObject:cell.sceneId];
                    }
                }else {
                    cell.seleteButton.selected = YES;
                    [cell.seleteButton setImage:[UIImage imageNamed:@"Be_selected"] forState:UIControlStateNormal];
                    if (![self.selectedDevices containsObject:cell.sceneId]) {
                        [self.selectedDevices addObject:cell.sceneId];
                    }
                }
            }else if (cell.seleteButton.selected) {
                cell.seleteButton.selected = NO;
                [cell.seleteButton setImage:[UIImage imageNamed:@"To_select"] forState:UIControlStateNormal];
                if ([self.selectedDevices containsObject:cell.sceneId]) {
                    [self.selectedDevices removeObject:cell.sceneId];
                }
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
    
    if (self.selectMode == DeviceListSelectMode_ForDrop) {
        if ([self.selectedDevices count]>0) {
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }else {
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
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
