//
//  MainViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/17.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "MainViewController.h"
#import "MainCollectionView.h"
#import "CSRAppStateManager.h"
#import "CSRAreaEntity.h" 
#import "CSRDeviceEntity.h"
#import "AddDevcieViewController.h"
#import "DeviceModelManager.h"
#import "ImproveTouchingExperience.h"
#import "SceneEntity.h"
#import "PlaceColorIconPickerView.h"
#import "PureLayout.h"
#import "MainCollectionViewCell.h"
#import "DeviceViewController.h"

#import "CSRmeshDevice.h"
#import "CSRDevicesManager.h"
#import "CSRUtilities.h"
#import "CSRDatabaseManager.h"

#import "GroupViewController.h"
#import <CSRmesh/GroupModelApi.h>
#import "DeviceListViewController.h"
#import "SingleDeviceModel.h"
#import "SceneMemberEntity.h"
#import "DataModelManager.h"
#import <MBProgressHUD.h>
#import "CBPeripheral+Info.h"
#import "TopImageView.h"
#import "RGBDeviceViewController.h"
#import "RGBSceneEntity.h"
#import "CurtainViewController.h"
#import "FanViewController.h"
#import "SocketViewController.h"
#import "RemoteMainVC.h"
#import "RemoteLCDVC.h"

#import <CSRmesh/DataModelApi.h>

#import "SoundListenTool.h"
#import "SelectModel.h"
#import "SceneViewController.h"
#import "MusicControllerVC.h"

@interface MainViewController ()<MainCollectionViewDelegate,PlaceColorIconPickerViewDelegate,MBProgressHUDDelegate>
{
    NSNumber *selectedSceneId;
    PlaceColorIconPickerView *pickerView;
    NSUInteger sceneIconId;
    CSRmeshDevice *meshDevice;
    CSRDeviceEntity *deleteDeviceEntity;
    BOOL sceneCtrLimit;
    
    NSInteger retryCount;
    NSData *retryCmd;
    NSNumber *retryDeviceId;
}

@property (nonatomic,strong) MainCollectionView *mainCollectionView;
@property (nonatomic,strong) MainCollectionView *sceneCollectionView;
@property (nonatomic,strong) NSNumber *originalLevel;
@property (nonatomic,strong) ImproveTouchingExperience *improver;
@property (nonatomic,assign) BOOL mainCVEditting;
@property (nonatomic,strong) CSRAreaEntity *areaEntity;
@property (nonatomic,strong) UIView *translucentBgView;
@property (nonatomic,strong) MBProgressHUD *hud;

@property (weak, nonatomic) IBOutlet TopImageView *topImageView;

@property (nonatomic,strong) UIView *curtainKindView;
@property (nonatomic,strong) CSRDeviceEntity *selectedCurtainDeviceEntity;

@property (nonatomic,strong) MBProgressHUD *sceneSettingHud;
@property (nonatomic,strong) UIAlertController *sceneSetfailureAlert;

@property (nonatomic,strong) NSMutableDictionary *semaphores;
@property (weak, nonatomic) IBOutlet UILabel *connectedPLable;

@property (nonatomic, strong) NSMutableArray *selects;
@property (nonatomic, strong) NSMutableArray *srScenes;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange) name:ZZAppLanguageDidChangeNotification object:nil];
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Main", @"Localizable");
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(editMainView)];
    self.navigationItem.rightBarButtonItem = edit;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reGetDataForPlaceChanged) name:@"reGetDataForPlaceChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bridgeConnectedNotification:) name:@"BridgeConnectedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bridgeDisconnectedNotification:) name:@"BridgeDisconnectedNotification" object:nil];
    
    self.improver = [[ImproveTouchingExperience alloc] init];
    
    if (@available(iOS 11.0,*)) {
    }else {
        [self.topImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64.0f];
    }
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = WIDTH*8.0/640.0;
    flowLayout.minimumInteritemSpacing = WIDTH*8.0/640.0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, floor(WIDTH*3/160.0));
    flowLayout.itemSize = CGSizeMake(WIDTH*3/8.0, WIDTH*9/32.0);
    _mainCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout cellIdentifier:@"MainCollectionViewCell"];
    _mainCollectionView.mainDelegate = self;
    [self.view addSubview:_mainCollectionView];
    
    [_mainCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint * main_top = [NSLayoutConstraint constraintWithItem:_mainCollectionView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.topImageView
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1.0
                                                                  constant:WIDTH*3/160.0];
    NSLayoutConstraint * main_left = [NSLayoutConstraint constraintWithItem:_mainCollectionView
                                                                  attribute:NSLayoutAttributeLeft
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeLeft
                                                                 multiplier:1.0
                                                                   constant:WIDTH*7/32.0];
    NSLayoutConstraint * main_right = [NSLayoutConstraint constraintWithItem:_mainCollectionView
                                                                   attribute:NSLayoutAttributeRight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeRight
                                                                  multiplier:1.0
                                                                    constant:0];
    NSLayoutConstraint * main_bottom;
    if (@available(iOS 11.0, *)) {
        main_bottom = [NSLayoutConstraint constraintWithItem:_mainCollectionView
                                                   attribute:NSLayoutAttributeBottom
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self.view.safeAreaLayoutGuide
                                                   attribute:NSLayoutAttributeBottom
                                                  multiplier:1.0
                                                    constant:-WIDTH*3/160.0];
    } else {
        main_bottom = [NSLayoutConstraint constraintWithItem:_mainCollectionView
                                                   attribute:NSLayoutAttributeBottom
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self.view
                                                   attribute:NSLayoutAttributeBottom
                                                  multiplier:1.0
                                                    constant:-WIDTH*3/160.0-49];
    }
    [NSLayoutConstraint  activateConstraints:@[main_top,main_left,main_bottom,main_right]];
    
    UICollectionViewFlowLayout *sceneFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    sceneFlowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    sceneFlowLayout.minimumLineSpacing = 0;
    sceneFlowLayout.minimumInteritemSpacing = 0;
    
    sceneFlowLayout.itemSize = CGSizeZero;

    _sceneCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:sceneFlowLayout cellIdentifier:@"SceneCollectionViewCell"];
    
    _sceneCollectionView.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1];
    _sceneCollectionView.mainDelegate = self;
    [self.view addSubview:_sceneCollectionView];
    [_sceneCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *scene_top = [NSLayoutConstraint constraintWithItem:_sceneCollectionView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.topImageView
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1.0
                                                                  constant:WIDTH*3/160.0];
    NSLayoutConstraint *scene_left = [NSLayoutConstraint constraintWithItem:_sceneCollectionView
                                                                  attribute:NSLayoutAttributeLeft
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeLeft
                                                                 multiplier:1.0
                                                                   constant:WIDTH*3/160.0];
    NSLayoutConstraint *scene_right = [NSLayoutConstraint constraintWithItem:_sceneCollectionView
                                                                  attribute:NSLayoutAttributeRight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:_mainCollectionView
                                                                  attribute:NSLayoutAttributeLeft
                                                                 multiplier:1.0
                                                                   constant:-WIDTH/80.0];
    NSLayoutConstraint *scene_bottom;
    if (@available(iOS 11.0, *)) {
        scene_bottom = [NSLayoutConstraint constraintWithItem:_sceneCollectionView
                                                   attribute:NSLayoutAttributeBottom
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self.view.safeAreaLayoutGuide
                                                   attribute:NSLayoutAttributeBottom
                                                  multiplier:1.0
                                                    constant:-WIDTH*3/160.0];
    } else {
        scene_bottom = [NSLayoutConstraint constraintWithItem:_sceneCollectionView
                                                    attribute:NSLayoutAttributeBottom
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:self.view
                                                    attribute:NSLayoutAttributeBottom
                                                   multiplier:1.0
                                                     constant:-WIDTH*3/160.0-49];
    }
    [NSLayoutConstraint  activateConstraints:@[scene_top,scene_left,scene_right,scene_bottom]];

    [self getMainDataArray];
    [self getSceneDataArray];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deleteStatus:)
                                                 name:kCSRDeviceManagerDeviceFoundForReset
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRDeviceManagerDeviceFoundForReset
                                                  object:nil];
}

- (void)getMainDataArray {
    [_mainCollectionView.dataArray removeAllObjects];
    __block NSMutableArray *deviceIdWasInAreaArray =[[NSMutableArray alloc] init];
    NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
    if (areaMutableArray != nil || [areaMutableArray count] != 0) {
        [areaMutableArray enumerateObjectsUsingBlock:^(CSRAreaEntity *area, NSUInteger idx, BOOL * _Nonnull stop) {
            for (CSRDeviceEntity *deviceEntity in area.devices) {
                [deviceIdWasInAreaArray addObject:deviceEntity.deviceId];
            }
            area.isEditting = @(_mainCVEditting);
            [_mainCollectionView.dataArray addObject:area];
        }];
    }
    
    NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
    if (mutableArray != nil || [mutableArray count] != 0) {
        __block BOOL isOldCVesion = NO;
        [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"~~~~~> %@  %@  %@  %@ %@",deviceEntity.name,deviceEntity.cvVersion,deviceEntity.deviceId,deviceEntity.uuid,deviceEntity.firVersion);
            if ([CSRUtilities belongToMainVCDevice: deviceEntity.shortName]) {
                if (![deviceIdWasInAreaArray containsObject:deviceEntity.deviceId]) {
                    deviceEntity.isEditting = @(_mainCVEditting);
                    [_mainCollectionView.dataArray addObject:deviceEntity];
                }
                
                if ([deviceEntity.cvVersion integerValue]<18) {
                    isOldCVesion = YES;
                }
            }else if ([deviceEntity.shortName isEqualToString:@"RB01"]) {
                if ([deviceEntity.cvVersion integerValue]<18) {
                    isOldCVesion = YES;
                }
            }
        }];
        
        [CSRAppStateManager sharedInstance].selectedPlace.color = @(isOldCVesion);
        [[CSRDatabaseManager sharedInstance] saveContext];
    }
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
    [_mainCollectionView.dataArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    if (_mainCVEditting) {
        //在编辑状态下添加分组时避免重复生成加号
        __block BOOL exit=0;
        [self.mainCollectionView.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSNumber class]]) {
                exit = YES;
                *stop = YES;
            }
        }];
        if (!exit) {
            [self.mainCollectionView.dataArray addObject:@0];
        }
    }
    
    [_mainCollectionView reloadData];
}

- (void)mainCollectionViewEditlayoutView {
    [self.mainCollectionView.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[CSRAreaEntity class]]) {
            CSRAreaEntity *areaEntity = (CSRAreaEntity *)obj;
            areaEntity.isEditting = @(_mainCVEditting);
        }
        if ([obj isKindOfClass:[CSRDeviceEntity class]]) {
            CSRDeviceEntity *deviceEntity = (CSRDeviceEntity *)obj;
            deviceEntity.isEditting = @(_mainCVEditting);
        }
        if ([obj isKindOfClass:[NSNumber class]]) {
            if (!_mainCVEditting) {
                [self.mainCollectionView.dataArray removeObject:obj];
            }
        }
    }];
    if (_mainCVEditting) {
        __block BOOL exit=0;
        [self.mainCollectionView.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSNumber class]]) {
                exit = YES;
                *stop = YES;
            }
        }];
        if (!exit) {
            [self.mainCollectionView.dataArray addObject:@0];
        }
    }
    [self.mainCollectionView reloadData];
}

- (void)getSceneDataArray {
    [_sceneCollectionView.dataArray removeAllObjects];
    NSMutableArray *sceneMutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.scenes allObjects] mutableCopy];
    if (sceneMutableArray != nil || [sceneMutableArray count] !=0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sceneID" ascending:YES];
        [sceneMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        for (SceneEntity *sceneEntity in sceneMutableArray) {
            if ([sceneEntity.srDeviceId isEqualToNumber:@(-1)] || !sceneEntity.srDeviceId) {
                [_sceneCollectionView.dataArray addObject:sceneEntity];
            }
        }
    }
    
    [_sceneCollectionView reloadData];
}

- (void)editMainView {
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneItemAction)];
    self.navigationItem.rightBarButtonItem = done;
    _mainCVEditting = YES;
    [self mainCollectionViewEditlayoutView];
}

- (void)doneItemAction {
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(editMainView)];
    self.navigationItem.rightBarButtonItem = edit;
    _mainCVEditting = NO;
    [self mainCollectionViewEditlayoutView];
    
    if (self.mainCollectionView.isLocationChanged) {
        self.mainCollectionView.isLocationChanged = NO;
        
        [self.mainCollectionView.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[CSRAreaEntity class]]) {
                CSRAreaEntity *area = (CSRAreaEntity *)obj;
                
                __block CSRAreaEntity *foundAreaEntity = nil;
                
                [[CSRAppStateManager sharedInstance].selectedPlace.areas enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
                    
                    CSRAreaEntity *areaEntity = (CSRAreaEntity *)obj;
                    
                    if ([areaEntity.areaID isEqualToNumber:area.areaID]) {
                        
                        foundAreaEntity = areaEntity;
                        *stop = YES;
                    }
                    
                }];
                if (foundAreaEntity) {
                    foundAreaEntity.sortId = @(idx);
                    [[CSRAppStateManager sharedInstance].selectedPlace addAreasObject:foundAreaEntity];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }
                
            }else if ([obj isKindOfClass:[CSRDeviceEntity class]]) {
                CSRDeviceEntity *device = (CSRDeviceEntity *)obj;

                __block CSRDeviceEntity *foundDeviceEntity = nil;
                
                [[CSRAppStateManager sharedInstance].selectedPlace.devices enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
                    
                    CSRDeviceEntity *deviceEntity = (CSRDeviceEntity *)obj;
                    
                    if ([deviceEntity.deviceId isEqualToNumber:device.deviceId]) {
                        
                        foundDeviceEntity = device;
                        *stop = YES;
                    }
                    
                }];
                
                
                if (foundDeviceEntity) {
                    foundDeviceEntity.sortId = @(idx);
                    
                    if (foundDeviceEntity.areas) {
                        for (CSRAreaEntity *areaEntity in foundDeviceEntity.areas) {
                            [areaEntity addDevicesObject:foundDeviceEntity];
                        }
                    }
                    
                    [[CSRAppStateManager sharedInstance].selectedPlace addDevicesObject:foundDeviceEntity];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }
                
            }
        }];
        
    }
    
    
}

#pragma mark - MainCollectionViewDelegate

- (void)mainCollectionViewTapCellAction:(NSNumber *)cellDeviceId cellIndexPath:(NSIndexPath *)indexPath {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *camera = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"CreatNewGroup", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        GroupViewController *gvc = [[GroupViewController alloc] init];
        __weak MainViewController *weakSelf = self;
        gvc.handle = ^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf getMainDataArray];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf getMainDataArray];
            });
        };
        gvc.isCreateNewArea = YES;
        gvc.isFromEmptyGroup = NO;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:gvc];
        CATransition *animation = [CATransition animation];
        [animation setDuration:0.3];
        [animation setType:kCATransitionMoveIn];
        [animation setSubtype:kCATransitionFromRight];
        [self.view.window.layer addAnimation:animation forKey:nil];
        [self presentViewController:nav animated:NO completion:nil];
        
    }];
    UIAlertAction *album = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"SearchNewDevices", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if ([cellDeviceId isEqualToNumber:@1000]) {
            [self presentToAddViewController];
        }
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:camera];
    [alert addAction:album];
    [alert addAction:cancel];
    
    [self.mainCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([cell.deviceId isEqualToNumber:@1000]) {
            alert.popoverPresentationController.sourceRect = cell.bounds;
            alert.popoverPresentationController.sourceView = cell;
            *stop = YES;
        }
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentToAddViewController {
    AddDevcieViewController *addVC = [[AddDevcieViewController alloc] init];
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromRight];
    [self.view.window.layer addAnimation:animation forKey:nil];
    UINavigationController *nav= [[UINavigationController alloc] initWithRootViewController:addVC];
    [self presentViewController:nav animated:NO completion:nil];
}

- (void)mainCollectionViewDelegatePanBrightnessWithTouchPoint:(CGPoint)touchPoint withOrigin:(CGPoint)origin toLight:(NSNumber *)deviceId groupId:(NSNumber *)groupId withPanState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction{
    
    if (state == UIGestureRecognizerStateBegan) {
        if ([deviceId isEqualToNumber:@2000]) {
            [_mainCollectionView.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[CSRAreaEntity class]]) {
                    CSRAreaEntity *MyAreaEntity = (CSRAreaEntity *)obj;
                    if ([MyAreaEntity.areaID isEqualToNumber:groupId]) {
                        NSInteger evenBrightness = 0;
                        for (CSRDeviceEntity *deviceEntity in MyAreaEntity.devices) {
                            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceEntity.deviceId];
                            if ([model.powerState boolValue]) {
                                NSInteger fixStatus = [model.level integerValue]? [model.level integerValue]:0;
                                evenBrightness += fixStatus;
                            }
                        }
                        
                        self.originalLevel = @(evenBrightness/MyAreaEntity.devices.count);
                    }
                }
            }];
            if ([SoundListenTool sharedInstance].audioRecorder.recording) {
                [[SoundListenTool sharedInstance] stopRecord:groupId];
            }
            [[DeviceModelManager sharedInstance] setLevelWithDeviceId:groupId channel:@1 withLevel:self.originalLevel withState:state direction:direction];
        }else {
            if ([SoundListenTool sharedInstance].audioRecorder.recording) {
                [[SoundListenTool sharedInstance] stopRecord:deviceId];
            }
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
            self.originalLevel = model.level;
            [[DeviceModelManager sharedInstance] setLevelWithDeviceId:deviceId channel:@1 withLevel:self.originalLevel withState:state direction:direction];
        }
        
        [self.improver beginImproving];
        
        return;
    }
    if (state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateEnded) {
        NSInteger updateLevel = [self.improver improveTouching:touchPoint referencePoint:origin primaryBrightness:[self.originalLevel integerValue]];

        CGFloat percentage = updateLevel/255.0*100;
        [self showControlMaskLayerWithAlpha:updateLevel/255.0 text:[NSString stringWithFormat:@"%.f",percentage]];
        
        if ([deviceId isEqualToNumber:@2000]) {
            [[DeviceModelManager sharedInstance] setLevelWithDeviceId:groupId channel:@1 withLevel:@(updateLevel) withState:state direction:direction];
        }else {
            [[DeviceModelManager sharedInstance] setLevelWithDeviceId:deviceId channel:@1 withLevel:@(updateLevel) withState:state direction:direction];
        }
        
        if (state == UIGestureRecognizerStateEnded) {
            [self hideControlMaskLayer];
        }
        return;
    }
}
- (void)showControlMaskLayerWithAlpha:(CGFloat)percentage text:(NSString*)text {
    if (!_maskLayer.superview) {
        [[UIApplication sharedApplication].keyWindow addSubview:self.maskLayer];
    }
    [self.maskLayer updateProgress:percentage withText:text];
}

- (void)hideControlMaskLayer {
    if (_maskLayer && _maskLayer.superview) {
        [self.maskLayer removeFromSuperview];
    }
}

- (void)mainCollectionViewDelegateSceneMenuAction:(NSNumber *)sceneId actionName:(NSString *)actionName {
    selectedSceneId = sceneId;
    if ([actionName isEqualToString:@"Edit"]) {
        SceneViewController *svc = [[SceneViewController alloc] init];
        SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:sceneId];
        svc.sceneIndex = s.rcIndex;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:svc];
        [self presentViewController:nav animated:YES completion:nil];
        return;
    }
    if ([actionName isEqualToString:@"Icon"]) {
        if (!pickerView) {
            pickerView = [[PlaceColorIconPickerView alloc] initWithFrame:CGRectMake((WIDTH-270)/2, (HEIGHT-190)/2, 270, 190) withMode:CollectionViewPickerMode_SceneIconPicker];
            pickerView.delegate = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
                [[UIApplication sharedApplication].keyWindow addSubview:pickerView];
                [pickerView autoCenterInSuperview];
                [pickerView autoSetDimensionsToSize:CGSizeMake(270, 190)];
            });
        }
        return;
    }
    if ([actionName isEqualToString:@"Rename"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        NSMutableAttributedString *hogan = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"Rename", @"Localizable")];
        [hogan addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1] range:NSMakeRange(0, [[hogan string] length])];
        [alert setValue:hogan forKey:@"attributedTitle"];
        NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"EnterSceneName", @"Localizable")];
        [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
        [alert setValue:attributedMessage forKey:@"attributedMessage"];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Save", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UITextField *renameTextField = alert.textFields.firstObject;
            if (![CSRUtilities isStringEmpty:renameTextField.text]){
                
                SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:sceneId];
                sceneEntity.sceneName = renameTextField.text;
                [[CSRDatabaseManager sharedInstance] saveContext];
                [self getSceneDataArray];
            }
            
        }];
        [alert addAction:cancel];
        [alert addAction:confirm];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {

        }];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
}

- (void)mainCollectionViewCellDelegateTwoFingersTapAction:(NSNumber *)groupId {
    CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:groupId];
    __block BOOL unRGBExist = NO;
    __block BOOL unCWExist = NO;
    [areaEntity.devices enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, BOOL * _Nonnull stop) {
        if (![CSRUtilities belongToRGBCWDevice:deviceEntity.shortName] && ![CSRUtilities belongToRGBDevice:deviceEntity.shortName]) {
            unRGBExist = YES;
        }
        if (![CSRUtilities belongToRGBCWDevice:deviceEntity.shortName] && ![CSRUtilities belongToCWDevice:deviceEntity.shortName]) {
            unCWExist = YES;
        }
    }];
    if (!unRGBExist) {
        
        if ([areaEntity.rgbScenes count] == 0) {
            NSArray *names = kRGBSceneDefaultName;
            NSArray *levels = kRGBSceneDefaultLevel;
            NSArray *hues = kRGBSceneDefaultHue;
            NSArray *sats = kRGBSceneDefaultColorSat;
            for (int i = 0; i<12; i++) {
                RGBSceneEntity *rgbScenetity = [NSEntityDescription insertNewObjectForEntityForName:@"RGBSceneEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                rgbScenetity.deviceID = groupId;
                rgbScenetity.name = names[i];
                rgbScenetity.isDefaultImg = @1;
                rgbScenetity.rgbSceneID = @(i);
                rgbScenetity.sortID = @(i);
                
                if (i<9) {
                    rgbScenetity.eventType = @(0);
                    rgbScenetity.hueA = hues[i];
                    rgbScenetity.level = levels[i];
                    rgbScenetity.colorSat = sats[i];
                }else {
                    rgbScenetity.eventType = @(1);
                    rgbScenetity.changeSpeed = @(1);
                    NSArray *colorfulHues = hues[i];
                    rgbScenetity.hueA = colorfulHues[0];
                    rgbScenetity.hueB = colorfulHues[1];
                    rgbScenetity.hueC = colorfulHues[2];
                    rgbScenetity.hueD = colorfulHues[3];
                    rgbScenetity.hueE = colorfulHues[4];
                    rgbScenetity.hueF = colorfulHues[5];
                    rgbScenetity.level = @(255);
                    rgbScenetity.colorSat = @(1);
                }
                [areaEntity addRgbScenesObject:rgbScenetity];
            }
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
        
        RGBDeviceViewController *rgbgroupVC = [[RGBDeviceViewController alloc] init];
        rgbgroupVC.deviceId = groupId;
        rgbgroupVC.RGBDVCReloadDataHandle = ^{
            [self getMainDataArray];
        };
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rgbgroupVC];
        nav.modalPresentationStyle = UIModalPresentationPopover;
        [self presentViewController:nav animated:YES completion:nil];
        [self.mainCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([cell.groupId isEqualToNumber:groupId]) {
                nav.popoverPresentationController.sourceRect = cell.bounds;
                nav.popoverPresentationController.sourceView = cell;
                *stop = YES;
            }
        }];
    }else if (!unCWExist) {
        DeviceViewController *dvc = [[DeviceViewController alloc] init];
        dvc.deviceId = groupId;
        dvc.reloadDataHandle = ^{
            [self getMainDataArray];
        };
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:dvc];
        nav.modalPresentationStyle = UIModalPresentationPopover;
        [self presentViewController:nav animated:YES completion:nil];
        [self.mainCollectionView.visibleCells enumerateObjectsUsingBlock:^(MainCollectionViewCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([cell.groupId isEqualToNumber:groupId]) {
                nav.popoverPresentationController.sourceRect = cell.bounds;
                nav.popoverPresentationController.sourceView = cell;
                *stop = YES;
            }
        }];
    }
}

//点击场景单元
- (void)mainCollectionViewCellDelegateSceneCellTapAction:(NSNumber *)sceneId {
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:sceneId];
    NSMutableArray *members = [[sceneEntity.members allObjects] mutableCopy];
    if ([members count] != 0) {
        if (sceneCtrLimit) {
            return;
        }
        sceneCtrLimit = YES;
        
        NSInteger s = [sceneEntity.rcIndex integerValue];
        Byte b[] = {};
        b[0] = (Byte)((s & 0xFF00)>>8);
        b[1] = (Byte)(s & 0x00FF);
        Byte byte[] = {0x9a, 0x02, b[1], b[0]};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:@0 data:cmd];
        
        [[DeviceModelManager sharedInstance] controlScene:sceneId];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            sceneCtrLimit = NO;
        });
    }else {
        if ([self determineDeviceHasBeenAdded]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
            NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"SceneNoDevice", @"Localizable")];
            [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
            [alertController setValue:attributedMessage forKey:@"attributedMessage"];
            [alertController.view setTintColor:DARKORAGE];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                selectedSceneId = sceneId;
                SceneViewController *svc = [[SceneViewController alloc] init];
                SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:sceneId];
                svc.sceneIndex = s.rcIndex;
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:svc];
                [self presentViewController:nav animated:YES completion:nil];
                
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alertController addAction:okAction];
            [alertController addAction:cancelAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }else {
            [self noDevicHasBeenAddedAlert];
        }
    }
}

- (void)mainCollectionViewDelegateLongPressAction:(id)cell {
    NSLog(@"longpress");
    MainCollectionViewCell *mainCell = (MainCollectionViewCell *)cell;
    if ([mainCell.groupId isEqualToNumber:@1000]) {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:mainCell.deviceId];
        if ([CSRUtilities belongToRGBDevice:deviceEntity.shortName]||[CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
            
            RGBDeviceViewController *RGBDVC = [[RGBDeviceViewController alloc] init];
            RGBDVC.deviceId = mainCell.deviceId;
            __weak MainViewController *weakSelf = self;
            RGBDVC.RGBDVCReloadDataHandle = ^{
                [weakSelf getMainDataArray];
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:RGBDVC];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
            
        }else if ([CSRUtilities belongToCurtainController:deviceEntity.shortName]) {
            
            if (!deviceEntity.remoteBranch || deviceEntity.remoteBranch.length == 0) {
                _selectedCurtainDeviceEntity = deviceEntity;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
                    [[UIApplication sharedApplication].keyWindow addSubview:self.curtainKindView];
                    [self.curtainKindView autoCenterInSuperview];
                    [self.curtainKindView autoSetDimensionsToSize:CGSizeMake(271, 166)];
                });
            }else {
                CurtainViewController *curtainVC = [[CurtainViewController alloc] init];
                curtainVC.deviceId = mainCell.deviceId;
                __weak MainViewController *weakSelf = self;
                curtainVC.reloadDataHandle = ^{
                    [weakSelf getMainDataArray];
                };
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:curtainVC];
                nav.modalPresentationStyle = UIModalPresentationPopover;
                [self presentViewController:nav animated:YES completion:nil];
                nav.popoverPresentationController.sourceRect = mainCell.bounds;
                nav.popoverPresentationController.sourceView = mainCell;
            }
            
        }else if ([CSRUtilities belongToFanController:deviceEntity.shortName]) {
            FanViewController *fanVC = [[FanViewController alloc] init];
            fanVC.deviceId = mainCell.deviceId;
            __weak MainViewController *weakSelf = self;
            fanVC.reloadDataHandle = ^{
                [weakSelf getMainDataArray];
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:fanVC];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
            
        }else if ([CSRUtilities belongToSocketOneChannel:deviceEntity.shortName]
                  || [CSRUtilities belongToSocketTwoChannel:deviceEntity.shortName]) {
            SocketViewController *socketVC = [[SocketViewController alloc] init];
            socketVC.deviceId = mainCell.deviceId;
            __weak MainViewController *weakSelf = self;
            socketVC.reloadDataHandle = ^{
                [weakSelf getMainDataArray];
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:socketVC];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
        }else if ([CSRUtilities belongToRGBCWRemote:deviceEntity.shortName]
                  || [CSRUtilities belongToCWRemote:deviceEntity.shortName]
                  || [CSRUtilities belongToRGBRemote:deviceEntity.shortName]
                  || [CSRUtilities belongToSceneRemoteSixKeys:deviceEntity.shortName]
                  || [CSRUtilities belongToSceneRemoteFourKeys:deviceEntity.shortName]
                  || [CSRUtilities belongToSceneRemoteThreeKeys:deviceEntity.shortName]
                  || [CSRUtilities belongToSceneRemoteTwoKeys:deviceEntity.shortName]
                  || [CSRUtilities belongToSceneRemoteOneKey:deviceEntity.shortName]) {
            RemoteMainVC *rmvc = [[RemoteMainVC alloc] init];
            rmvc.deviceId = mainCell.deviceId;
            rmvc.reloadDataHandle = ^{
                [self getMainDataArray];
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rmvc];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
        }else if ([CSRUtilities belongToLCDRemote:deviceEntity.shortName]) {
            RemoteLCDVC *lcdvc = [[RemoteLCDVC alloc] init];
            lcdvc.deviceId = mainCell.deviceId;
            lcdvc.reloadDataHandle = ^{
                [self getMainDataArray];
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:lcdvc];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
        }else if ([CSRUtilities belongToMusicController:deviceEntity.shortName]) {
            MusicControllerVC *mcvc = [[MusicControllerVC alloc] init];
            mcvc.deviceId = mainCell.deviceId;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mcvc];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
        }else{
            DeviceViewController *dvc = [[DeviceViewController alloc] init];
            dvc.deviceId = mainCell.deviceId;
            __weak MainViewController *weakSelf = self;
            dvc.reloadDataHandle = ^{
                [weakSelf getMainDataArray];
            };
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:dvc];
            nav.modalPresentationStyle = UIModalPresentationPopover;
            [self presentViewController:nav animated:YES completion:nil];
            nav.popoverPresentationController.sourceRect = mainCell.bounds;
            nav.popoverPresentationController.sourceView = mainCell;
        }
    }else if ([mainCell.deviceId isEqualToNumber:@2000]) {
        GroupViewController *gvc = [[GroupViewController alloc] init];
        __weak MainViewController *weakSelf = self;
        gvc.handle = ^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf getMainDataArray];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf getMainDataArray];
            });
        };
        gvc.isCreateNewArea = NO;
        gvc.isFromEmptyGroup = NO;
        gvc.areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:mainCell.groupId];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:gvc];
        CATransition *animation = [CATransition animation];
        [animation setDuration:0.3];
        [animation setType:kCATransitionMoveIn];
        [animation setSubtype:kCATransitionFromRight];
        [self.view.window.layer addAnimation:animation forKey:nil];
        [self presentViewController:nav animated:NO completion:nil];
    }
}

- (void)mainCollectionViewDelegateDeleteDeviceAction:(NSNumber *)cellDeviceId cellGroupId:(NSNumber *)cellGroupId{
    
    if ([cellDeviceId isEqualToNumber:@2000]) {
        _areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:cellGroupId];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AcTECLocalizedStringFromTable(@"DeleteGroup", @"Localizable") message:[NSString stringWithFormat:@"%@ :%@?",AcTECLocalizedStringFromTable(@"DeleteGroupAlert", @"Localizable"),_areaEntity.areaName] preferredStyle:UIAlertControllerStyleAlert];
        [alertController.view setTintColor:DARKORAGE];
        __weak MainViewController *weakSelf = self;
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            for (CSRDeviceEntity *deviceEntity in _areaEntity.devices) {
                NSNumber *groupIndex = [weakSelf getValueByIndex:deviceEntity];
                [[GroupModelApi sharedInstance] setModelGroupId:deviceEntity.deviceId
                                                        modelNo:@(0xff)
                                                     groupIndex:groupIndex
                                                       instance:@(0)
                                                        groupId:@(0)
                                                        success:^(NSNumber * _Nullable deviceId,
                                                                  NSNumber * _Nullable modelNo,
                                                                  NSNumber * _Nullable groupIndex,
                                                                  NSNumber * _Nullable instance,
                                                                  NSNumber * _Nullable groupId) {
                                                            NSData *groups = [CSRUtilities dataForHexString:deviceEntity.groups];
                                                            uint16_t *dataToModify = (uint16_t*)groups.bytes;
                                                            NSMutableArray *desiredGroups = [NSMutableArray new];
                                                            for (int count=0; count < deviceEntity.groups.length/2; count++, dataToModify++) {
                                                                NSNumber *groupValue = @(*dataToModify);
                                                                [desiredGroups addObject:groupValue];
                                                            }
                                                            
                                                            if (groupIndex && [groupIndex integerValue]<desiredGroups.count) {
                                                                
                                                                NSNumber *areaValue = [desiredGroups objectAtIndex:[groupIndex integerValue]];
                                                                
                                                                CSRAreaEntity *areaEntity = [[[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"CSRAreaEntity" withPredicate:@"areaID == %@", areaValue] firstObject];
                                                                
                                                                if (areaEntity) {
                                                                    
                                                                    [_areaEntity removeDevicesObject:deviceEntity];
                                                                }
                                                                
                                                                
                                                                NSMutableData *myData = (NSMutableData*)[CSRUtilities dataForHexString:deviceEntity.groups];
                                                                uint16_t desiredValue = [groupId unsignedShortValue];
                                                                int groupIndexInt = [groupIndex intValue];
                                                                if (groupIndexInt>-1) {
                                                                    uint16_t *groups = (uint16_t *) myData.mutableBytes;
                                                                    *(groups + groupIndexInt) = desiredValue;
                                                                }
                                                                deviceEntity.groups = [CSRUtilities hexStringFromData:(NSData*)myData];
                                                                [[CSRDatabaseManager sharedInstance] saveContext];
                                                            }
                                                        }
                                                        failure:^(NSError * _Nullable error) {
                                                            NSLog(@"mesh timeout");
                                                        }];
                [NSThread sleepForTimeInterval:0.3];
                
            }
            
            [[CSRDatabaseManager sharedInstance] removeAreaFromDatabaseWithAreaId:cellGroupId];
            [self getMainDataArray];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf mainCollectionViewEditlayoutView];
                if (_hud) {
                    [_hud hideAnimated:YES];
                    _hud = nil;
                }
            });
            
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (_hud) {
                [_hud hideAnimated:YES];
                _hud = nil;
            }
            
        }];
        [alertController addAction:okAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
        if (!_hud) {
            _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            _hud.mode = MBProgressHUDModeIndeterminate;
            _hud.delegate = self;
        }
    }else{
        meshDevice = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:cellDeviceId];
        CSRPlaceEntity *placeEntity = [CSRAppStateManager sharedInstance].selectedPlace;
        deleteDeviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:cellDeviceId];
        
        if (![CSRUtilities isStringEmpty:placeEntity.passPhrase]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AcTECLocalizedStringFromTable(@"DeleteDevice", @"Localizable") message:[NSString stringWithFormat:@"%@ : %@?",AcTECLocalizedStringFromTable(@"DeleteDeviceAlert", @"Localizable"),meshDevice.name] preferredStyle:UIAlertControllerStyleAlert];
            [alertController.view setTintColor:DARKORAGE];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (meshDevice) {
                    [[CSRDevicesManager sharedInstance] initiateRemoveDevice:meshDevice];
                }
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                if (_hud) {
                    [_hud hideAnimated:YES];
                    _hud = nil;
                }
            }];
            [alertController addAction:okAction];
            [alertController addAction:cancelAction];
            [self presentViewController:alertController animated:YES completion:nil];
            if (!_hud) {
                _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                _hud.mode = MBProgressHUDModeIndeterminate;
                _hud.delegate = self;
            }
        }
    }
}

//method to getIndexByValue
- (NSNumber *) getValueByIndex:(CSRDeviceEntity*)deviceEntity
{
    NSData *groups = [CSRUtilities dataForHexString:deviceEntity.groups];
    uint16_t *dataToModify = (uint16_t*)groups.bytes;
    
    for (int count=0; count < deviceEntity.groups.length/2; count++, dataToModify++) {
        if (*dataToModify == [_areaEntity.areaID unsignedShortValue]) {
            return @(count);
            
        } else if (*dataToModify == 0){
            return @(count);
        }
    }
    
    return @(-1);
}

- (void)mainCollectionViewDelegateClickEmptyGroupCellAction:(NSIndexPath *)cellIndexPath {
    
    if ([self determineDeviceHasBeenAdded]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"" preferredStyle:UIAlertControllerStyleAlert];
        NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"GroupNoDevice", @"Localizable")];
        [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
        [alertController setValue:attributedMessage forKey:@"attributedMessage"];
        [alertController.view setTintColor:DARKORAGE];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            GroupViewController *gvc = [[GroupViewController alloc] init];
            __weak MainViewController *weakSelf = self;
            gvc.handle = ^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf getMainDataArray];
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf getMainDataArray];
                });
            };
            gvc.isCreateNewArea = NO;
            gvc.isFromEmptyGroup = YES;
            gvc.areaEntity = [_mainCollectionView.dataArray objectAtIndex:cellIndexPath.row];
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:gvc];
            [self presentViewController:nav animated:NO completion:nil];
            
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:okAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }else {
        [self noDevicHasBeenAddedAlert];
    }
}

- (BOOL)determineDeviceHasBeenAdded{
    NSArray *devices = [[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects];
    __block BOOL exist=0;
    [devices enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([CSRUtilities belongToMainVCDevice:deviceEntity.shortName]) {
            exist = YES;
            *stop = YES;
        }
    }];
    return exist;
}

- (void)noDevicHasBeenAddedAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"" preferredStyle:UIAlertControllerStyleAlert];
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"NoDevicePlace", @"Localizable")];
    [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
    [alertController setValue:attributedMessage forKey:@"attributedMessage"];
    [alertController.view setTintColor:DARKORAGE];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self presentToAddViewController];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)mainCollectionViewCellDelegateCurtainTapAction:(CSRDeviceEntity *)deviceEntity {

    _selectedCurtainDeviceEntity = deviceEntity;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
        [[UIApplication sharedApplication].keyWindow addSubview:self.curtainKindView];
        [self.curtainKindView autoCenterInSuperview];
        [self.curtainKindView autoSetDimensionsToSize:CGSizeMake(271, 166)];
    });
}

- (void)selectTypeOfCurtain:(UIButton *)sender {
    
    if (sender.tag == 11) {
        _selectedCurtainDeviceEntity.remoteBranch = @"ch";
    }else if (sender.tag == 22) {
        _selectedCurtainDeviceEntity.remoteBranch = @"cv";
    }else if (sender.tag == 33) {
        _selectedCurtainDeviceEntity.remoteBranch = @"chh";
    }else if (sender.tag == 44) {
        _selectedCurtainDeviceEntity.remoteBranch = @"cvv";
    }
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self getMainDataArray];
    
    _selectedCurtainDeviceEntity = nil;
    
    [self.curtainKindView removeFromSuperview];
    self.curtainKindView = nil;
    [self.translucentBgView removeFromSuperview];
    self.translucentBgView = nil;
}

#pragma mark - notification

- (void)deleteStatus:(NSNotification *)notification
{
    NSNumber *num = notification.userInfo[@"boolFlag"];
    if ([num boolValue] == NO) {
        [self showForceAlert];
    } else {
        NSString *deleteDeviceShortName;
        if(deleteDeviceEntity) {
            deleteDeviceShortName = [deleteDeviceEntity.shortName copy];
            if (deleteDeviceEntity.rgbScenes && [deleteDeviceEntity.rgbScenes count]>0) {
                for (RGBSceneEntity *deleteRgbSceneEntity in deleteDeviceEntity.rgbScenes) {
                    [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:deleteRgbSceneEntity];
                }
            }
            [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:deleteDeviceEntity];
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:deleteDeviceEntity];
            
            [[CSRDatabaseManager sharedInstance] dropEntityDeleteWhenDeleteDeviceEntity:deleteDeviceEntity.deviceId];
            [[CSRDatabaseManager sharedInstance] sceneMemberEntityDeleteWhenDeleteDeviceEntity:deleteDeviceEntity.deviceId];
            [[CSRDatabaseManager sharedInstance] timerDeviceEntityDeleteWhenDeleteDeviceEntity:deleteDeviceEntity.deviceId];
            if ([CSRUtilities belongToSceneRemoteSixKeys:deleteDeviceEntity.shortName]
                || [CSRUtilities belongToSceneRemoteFourKeys:deleteDeviceEntity.shortName]
                || [CSRUtilities belongToSceneRemoteThreeKeys:deleteDeviceEntity.shortName]
                || [CSRUtilities belongToSceneRemoteTwoKeys:deleteDeviceEntity.shortName]
                || [CSRUtilities belongToSceneRemoteOneKey:deleteDeviceEntity.shortName]) {
                [self removeSceneAfterSceneRemoteDelete:deleteDeviceEntity.deviceId];
            }
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteDeviceEntity" object:nil];
        }
        NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
        [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
        
        [self getMainDataArray];
        __weak MainViewController *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf mainCollectionViewEditlayoutView];
        });
        if (!([CSRUtilities belongToSceneRemoteSixKeys:deleteDeviceShortName]
            || [CSRUtilities belongToSceneRemoteFourKeys:deleteDeviceShortName]
            || [CSRUtilities belongToSceneRemoteThreeKeys:deleteDeviceShortName]
            || [CSRUtilities belongToSceneRemoteTwoKeys:deleteDeviceShortName]
            || [CSRUtilities belongToSceneRemoteOneKey:deleteDeviceShortName])) {
            if (_hud) {
                [_hud hideAnimated:YES];
                _hud = nil;
            }
        }
    }
}

- (void)showForceAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AcTECLocalizedStringFromTable(@"DeleteDevice", @"Localizable")
                                                                             message:[NSString stringWithFormat:@"%@ %@ ？",AcTECLocalizedStringFromTable(@"DeleteDeviceOffLine", @"Localizable"), meshDevice.name]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController.view setTintColor:DARKORAGE];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             if (_hud) {
                                                                 [_hud hideAnimated:YES];
                                                                 _hud = nil;
                                                             }
                                                         }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         
                                                         if(deleteDeviceEntity) {
                                                             if (deleteDeviceEntity.rgbScenes && [deleteDeviceEntity.rgbScenes count]>0) {
                                                                 for (RGBSceneEntity *deleteRgbSceneEntity in deleteDeviceEntity.rgbScenes) {
                                                                     [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:deleteRgbSceneEntity];
                                                                 }
                                                             }
                                                             [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:deleteDeviceEntity];
                                                             [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:deleteDeviceEntity];
                                                             
                                                             [[CSRDatabaseManager sharedInstance] dropEntityDeleteWhenDeleteDeviceEntity:deleteDeviceEntity.deviceId];
                                                             [[CSRDatabaseManager sharedInstance] sceneMemberEntityDeleteWhenDeleteDeviceEntity:deleteDeviceEntity.deviceId];
                                                             [[CSRDatabaseManager sharedInstance] timerDeviceEntityDeleteWhenDeleteDeviceEntity:deleteDeviceEntity.deviceId];
                                                             if ([CSRUtilities belongToSceneRemoteSixKeys:deleteDeviceEntity.shortName]
                                                                 || [CSRUtilities belongToSceneRemoteFourKeys:deleteDeviceEntity.shortName]
                                                                 || [CSRUtilities belongToSceneRemoteThreeKeys:deleteDeviceEntity.shortName]
                                                                 || [CSRUtilities belongToSceneRemoteTwoKeys:deleteDeviceEntity.shortName]
                                                                 || [CSRUtilities belongToSceneRemoteOneKey:deleteDeviceEntity.shortName]) {
                                                                 [self removeSceneAfterSceneRemoteDelete:deleteDeviceEntity.deviceId];
                                                             }
                                                             
                                                             [[CSRDatabaseManager sharedInstance] saveContext];
                                                             
                                                             [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteDeviceEntity" object:nil];
                                                         }
                                                         NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
                                                         [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
                                                         [self getMainDataArray];
                                                         [self mainCollectionViewEditlayoutView];
                                                         if (!([CSRUtilities belongToSceneRemoteSixKeys:deleteDeviceEntity.shortName]
                                                             || [CSRUtilities belongToSceneRemoteFourKeys:deleteDeviceEntity.shortName]
                                                             || [CSRUtilities belongToSceneRemoteThreeKeys:deleteDeviceEntity.shortName]
                                                             || [CSRUtilities belongToSceneRemoteTwoKeys:deleteDeviceEntity.shortName]
                                                             || [CSRUtilities belongToSceneRemoteOneKey:deleteDeviceEntity.shortName])) {
                                                             if (_hud) {
                                                                 [_hud hideAnimated:YES];
                                                                 _hud = nil;
                                                             }
                                                         }
                                                     }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)reGetDataForPlaceChanged {
    [self getMainDataArray];
    [self getSceneDataArray];
    [[DeviceModelManager sharedInstance] getAllDevicesState];
}


#pragma mark - PlaceColorIconPickerViewDelegate

- (id)selectedItem:(id)item {
    NSString *imageString = (NSString *)item;
    
    NSArray *iconArray = kSceneIcons;
    __block NSNumber *iconNum = nil;
    [iconArray enumerateObjectsUsingBlock:^(NSString *iconString, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([iconString isEqualToString:imageString]) {
            iconNum = @(idx);
            *stop = YES;
        }
    }];
    if (iconNum) {
        SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:selectedSceneId];
        sceneEntity.iconID = iconNum;
        [[CSRDatabaseManager sharedInstance] saveContext];
        [self getSceneDataArray];
    }
    return nil;
}

- (void)cancel:(UIButton *)sender {
    if (pickerView) {
        [pickerView removeFromSuperview];
        pickerView = nil;
        [self.translucentBgView removeFromSuperview];
    }
}

#pragma mark - lazy

- (ControlMaskView*)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [[ControlMaskView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _maskLayer;
}

- (UIView *)translucentBgView {
    if (!_translucentBgView) {
        _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _translucentBgView.backgroundColor = [UIColor blackColor];
        _translucentBgView.alpha = 0.4;
    }
    return _translucentBgView;
}

- (UIView *)curtainKindView {
    if (!_curtainKindView) {
        _curtainKindView = [[UIView alloc] initWithFrame:CGRectZero];
        _curtainKindView.backgroundColor = [UIColor whiteColor];
        _curtainKindView.alpha = 0.9;
        _curtainKindView.layer.cornerRadius = 14;
        _curtainKindView.layer.masksToBounds = YES;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 271, 30)];
        titleLabel.text = AcTECLocalizedStringFromTable(@"ChooseTypeOfCurtain", @"Localizable");
        titleLabel.textColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [_curtainKindView addSubview:titleLabel];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 271, 1)];
        line.backgroundColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        [_curtainKindView addSubview:line];
        
        UIButton *horizontalBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 31, 135, 135)];
        [horizontalBtn addTarget:self action:@selector(selectTypeOfCurtain:) forControlEvents:UIControlEventTouchUpInside];
        [_curtainKindView addSubview:horizontalBtn];
        
        UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(135, 31, 1, 135)];
        line1.backgroundColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        [_curtainKindView addSubview:line1];
        
        UIButton *verticalBtn = [[UIButton alloc] initWithFrame:CGRectMake(136, 31, 135, 135)];
        [verticalBtn addTarget:self action:@selector(selectTypeOfCurtain:) forControlEvents:UIControlEventTouchUpInside];
        [_curtainKindView addSubview:verticalBtn];
        
        if ([CSRUtilities belongToOneChannelCurtainController:_selectedCurtainDeviceEntity.shortName]) {
            horizontalBtn.tag = 11;
            [horizontalBtn setImage:[UIImage imageNamed:@"curtainHImage"] forState:UIControlStateNormal];
            verticalBtn.tag = 22;
            [verticalBtn setImage:[UIImage imageNamed:@"curtainVImage"] forState:UIControlStateNormal];
        }else if ([CSRUtilities belongToTwoChannelCurtainController:_selectedCurtainDeviceEntity.shortName]) {
            horizontalBtn.tag = 33;
            [horizontalBtn setImage:[UIImage imageNamed:@"curtainHHImage"] forState:UIControlStateNormal];
            verticalBtn.tag = 44;
            [verticalBtn setImage:[UIImage imageNamed:@"curtainVVImage"] forState:UIControlStateNormal];
        }
    }
    return _curtainKindView;
}

- (NSMutableDictionary *)semaphores {
    if (!_semaphores) {
        _semaphores = [[NSMutableDictionary alloc] init];
    }
    return _semaphores;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

- (void)languageChange {
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Main", @"Localizable");
    
    UIBarButtonItem *right;
    if (_mainCVEditting) {
        right = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneItemAction)];
    }else {
        right = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(editMainView)];
    }
    self.navigationItem.rightBarButtonItem = right;
    
    [self.sceneCollectionView reloadData];
    [self.mainCollectionView reloadData];
}

- (void)viewDidLayoutSubviews {
    UICollectionViewFlowLayout *sceneFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    sceneFlowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    sceneFlowLayout.minimumLineSpacing = 0;
    sceneFlowLayout.minimumInteritemSpacing = 0;
    sceneFlowLayout.itemSize = CGSizeMake(WIDTH*3/16.0, (_mainCollectionView.bounds.size.height)/4.0);
    _sceneCollectionView.collectionViewLayout = sceneFlowLayout;
}

- (void)bridgeConnectedNotification:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    CBPeripheral *per = dic[@"peripheral"];
    _connectedPLable.text = [NSString stringWithFormat:@"%@ %@",per.name,per.uuidString];
    _connectedPLable.textColor = [UIColor whiteColor];
    [DeviceModelManager sharedInstance].bleDisconnected = NO;
    [_mainCollectionView reloadData];
}

- (void)bridgeDisconnectedNotification:(NSNotification *)notification {
    _connectedPLable.text = @"Bluetooth is not connected! ";
    _connectedPLable.textColor = DARKORAGE;
    [DeviceModelManager sharedInstance].bleDisconnected = YES;
    [_mainCollectionView reloadData];
}

- (NSMutableArray *)selects {
    if (!_selects) {
        _selects = [[NSMutableArray alloc] init];
    }
    return _selects;
}

- (NSMutableArray *)srScenes {
    if (!_srScenes) {
        _srScenes = [[NSMutableArray alloc] init];
    }
    return _srScenes;
}

- (void)removeSceneAfterSceneRemoteDelete:(NSNumber *)srDeviceId {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeSceneCall:)
                                                 name:@"RemoveSceneCall"
                                               object:nil];
    [self.selects removeAllObjects];
    for (SceneEntity *scene in [CSRAppStateManager sharedInstance].selectedPlace.scenes) {
        if ([scene.srDeviceId isEqualToNumber:srDeviceId]) {
            [self.srScenes addObject:scene];
            if ([scene.members count] > 0) {
                for (SceneMemberEntity *member in scene.members) {
                    [self.selects addObject:member];
                }
            }
        }
    }
    if ([self.selects count] > 0) {
        [self nextOperation];
    }else {
        if (_hud) {
            [_hud hideAnimated:YES];
            _hud = nil;
        }
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RemoveSceneCall" object:nil];
    }
}

- (BOOL)nextOperation {
    if ([self.selects count] > 0) {
        SceneMemberEntity *m = [self.selects firstObject];
        CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:m.deviceID];
        if (d == nil) {
            [self.selects removeObject:m];
            return [self nextOperation];
        }else {
            
            [self performSelector:@selector(removeSceneIDTimeOut) withObject:nil afterDelay:10];
            
            NSInteger s = [m.sceneID integerValue];
            Byte b[] = {};
            b[0] = (Byte)((s & 0xFF00)>>8);
            b[1] = (Byte)(s & 0x00FF);
            
            if ([CSRUtilities belongToTwoChannelSwitch:m.kindString]
                || [CSRUtilities belongToThreeChannelSwitch:m.kindString]
                || [CSRUtilities belongToTwoChannelDimmer:m.kindString]
                || [CSRUtilities belongToSocketTwoChannel:m.kindString]
                || [CSRUtilities belongToTwoChannelCurtainController:m.kindString]) {
                Byte byte[] = {0x5d, 0x03, [m.channel integerValue], b[1], b[0]};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:5];
                retryCount = 0;
                retryCmd = cmd;
                retryDeviceId = m.deviceID;
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:m.deviceID data:cmd];
            }else {
                Byte byte[] = {0x98, 0x02, b[1], b[0]};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
                retryCount = 0;
                retryCmd = cmd;
                retryDeviceId = m.deviceID;
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:m.deviceID data:cmd];
            }
            return YES;
        }
    }
    return NO;
}

- (void)removeSceneIDTimeOut {
    if (retryCount < 1) {
        [self performSelector:@selector(removeSceneIDTimeOut) withObject:nil afterDelay:10];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:retryDeviceId data:retryCmd];
        retryCount ++;
    }else {
        SceneMemberEntity *m = [self.selects firstObject];
        [self.selects removeObject:m];
        SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:m.sceneID];
        [s removeMembersObject:m];
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:m];
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        if (![self nextOperation]) {
            for (SceneEntity *srs in self.srScenes) {
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:srs];
            }
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            if (_hud) {
                [_hud hideAnimated:YES];
                _hud = nil;
            }
            
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RemoveSceneCall" object:nil];
        }
    }
}

- (void)removeSceneCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceID = userInfo[@"deviceId"];
    NSNumber *sceneID = userInfo[@"index"];
    SceneMemberEntity *m = [self.selects firstObject];
    if ([deviceID isEqualToNumber:m.deviceID] && [sceneID isEqualToNumber:m.sceneID]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeSceneIDTimeOut) object:nil];
        
        [self.selects removeObject:m];
        SceneEntity *s = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:m.sceneID];
        [s removeMembersObject:m];
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:m];
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        if (![self nextOperation]) {
            for (SceneEntity *srs in self.srScenes) {
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:srs];
            }
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            if (_hud) {
                [_hud hideAnimated:YES];
                _hud = nil;
            }
            
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RemoveSceneCall" object:nil];
        }
    }
}

@end
