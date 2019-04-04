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
#import "TwoChannelDimmerVC.h"

//#import <CoreLocation/CoreLocation.h>
//#import "AFHTTPSessionManager.h"
//#import <SDWebImage/UIImageView+WebCache.h>

#import <CSRmesh/DataModelApi.h>

#import "GroupControlView.h"

@interface MainViewController ()<MainCollectionViewDelegate,PlaceColorIconPickerViewDelegate,MBProgressHUDDelegate>
{
    NSNumber *selectedSceneId;
    PlaceColorIconPickerView *pickerView;
    NSUInteger sceneIconId;
    CSRmeshDevice *meshDevice;
    CSRDeviceEntity *deleteDeviceEntity;
    
//    CLLocationManager *locationManager;
//    NSString *currentCity;
//    NSString *strlatitude;
//    NSString *strlongitude;
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
@property (nonatomic,strong) NSNumber *selectedCurtainDeviceId;

//@property (weak, nonatomic) IBOutlet UIImageView *weatherImageView;
//@property (weak, nonatomic) IBOutlet UILabel *tempLabel;
//@property (weak, nonatomic) IBOutlet UILabel *tempRangeLabel;
//@property (weak, nonatomic) IBOutlet UILabel *weekLabel;
//@property (weak, nonatomic) IBOutlet UILabel *tempUnit;
//@property (weak, nonatomic) IBOutlet UILabel *dayLabel;

@property (nonatomic,strong) MBProgressHUD *sceneSettingHud;
@property (nonatomic,strong) UIAlertController *sceneSetfailureAlert;

@property (nonatomic,strong) NSMutableDictionary *semaphores;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settedSceneFailure:) name:@"settedSceneFailure" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(multichannelSceneAddedSuccessCall:) name:@"multichannelSceneAddedSuccessCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(multichannelDeleteSceneCall:) name:@"multichannelDeleteSceneCall" object:nil];
    
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
//    [self getLocation];
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
            NSLog(@"~~~~~> %@  %@  %@  %@",deviceEntity.name,deviceEntity.cvVersion,deviceEntity.deviceId,deviceEntity.uuid);
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
        [sceneMutableArray enumerateObjectsUsingBlock:^(SceneEntity *sceneEntity, NSUInteger idx, BOOL * _Nonnull stop) {
            [_sceneCollectionView.dataArray addObject:sceneEntity];
        }];
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
//    __weak MainViewController *weakSelf = self;
//    addVC.handle = ^{
//        [weakSelf getMainDataArray];
//    };
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
            [[DeviceModelManager sharedInstance] setLevelWithDeviceId:groupId withLevel:self.originalLevel withState:state direction:direction];
        }else {
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
            self.originalLevel = model.level;
            [[DeviceModelManager sharedInstance] setLevelWithDeviceId:deviceId withLevel:self.originalLevel withState:state direction:direction];
        }
        
        [self.improver beginImproving];
        
        return;
    }
    if (state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateEnded) {
        NSInteger updateLevel = [self.improver improveTouching:touchPoint referencePoint:origin primaryBrightness:[self.originalLevel integerValue]];

        CGFloat percentage = updateLevel/255.0*100;
        [self showControlMaskLayerWithAlpha:updateLevel/255.0 text:[NSString stringWithFormat:@"%.f",percentage]];
        
        if ([deviceId isEqualToNumber:@2000]) {
            [[DeviceModelManager sharedInstance] setLevelWithDeviceId:groupId withLevel:@(updateLevel) withState:state direction:direction];
        }else {
            [[DeviceModelManager sharedInstance] setLevelWithDeviceId:deviceId withLevel:@(updateLevel) withState:state direction:direction];
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
        NSLog(@"Edit");
        
        [self editScene];
        
        return;
    }
    if ([actionName isEqualToString:@"Icon"]) {
        NSLog(@"Icon");
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
        NSLog(@"Rename");
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
    BOOL threeColorTemperature = NO;
    BOOL colorTemperature = NO;
    BOOL RGB = NO;
    for (CSRDeviceEntity *deviceEntity in areaEntity.devices) {
        if ([CSRUtilities belongToThreeSpeedColorTemperatureDevice:deviceEntity.shortName]) {
            threeColorTemperature = YES;
        }else if ([CSRUtilities belongToCWDevice:deviceEntity.shortName] || [CSRUtilities belongToCWNoLevelDevice:deviceEntity.shortName]) {
            colorTemperature = YES;
        }else if ([CSRUtilities belongToRGBDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBNoLevelDevice:deviceEntity.shortName]) {
            RGB = YES;
        }else if ([CSRUtilities belongToRGBCWDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBCWNoLevelDevice:deviceEntity.shortName]) {
            colorTemperature = YES;
            RGB = YES;
        }
    }
    if (threeColorTemperature || colorTemperature || RGB) {
        GroupControlView *groupControlView = [[GroupControlView alloc] initWithFrame:self.view.frame threeColorTemperature:threeColorTemperature colorTemperature:colorTemperature RGB:RGB];
        groupControlView.groupID = groupId;
        [[UIApplication sharedApplication].keyWindow addSubview:groupControlView];
        [groupControlView autoPinEdgesToSuperviewEdges];
    }
}

- (void)settedSceneFailure:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
    if (_sceneSetfailureAlert) {
        NSString *str = _sceneSetfailureAlert.message;
        _sceneSetfailureAlert.message = [NSString stringWithFormat:@"%@,%@",str,device.name];
    }else {
        _sceneSetfailureAlert = [UIAlertController alertControllerWithTitle:@"Failure" message:device.name preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [_sceneSetfailureAlert addAction:okAction];
        [self presentViewController:_sceneSetfailureAlert animated:YES completion:nil];
    }
    
}

- (void)multichannelSceneAddedSuccessCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    NSNumber *channel = dic[@"channel"];
    NSNumber *index = dic[@"index"];
    NSNumber *state = dic[@"state"];
    if ([state boolValue]) {
        NSDictionary *semaphoresdic = [self.semaphores objectForKey:deviceId];
        if (semaphoresdic) {
            if ([channel isEqualToNumber:semaphoresdic[@"channel"]] && [index isEqualToNumber:semaphoresdic[@"index"]]) {
                dispatch_semaphore_t semaphore = semaphoresdic[@"semaphore"];
                dispatch_semaphore_signal(semaphore);
            }
        }
    }else {
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        if (_sceneSetfailureAlert) {
            NSString *str = _sceneSetfailureAlert.message;
            _sceneSetfailureAlert.message = [NSString stringWithFormat:@"%@,%@ channel:%@",str,device.name,channel];
        }else {
            _sceneSetfailureAlert = [UIAlertController alertControllerWithTitle:@"Failure" message:device.name preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [_sceneSetfailureAlert addAction:okAction];
            [self presentViewController:_sceneSetfailureAlert animated:YES completion:nil];
        }
    }
}

- (void)multichannelDeleteSceneCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
//    NSNumber *channel = dic[@"channel"];
    NSNumber *index = dic[@"index"];
//    NSNumber *state = dic[@"state"];
//    if ([state boolValue]) {
        NSMutableDictionary *semaphoresdic = [self.semaphores objectForKey:deviceId];
        if (semaphoresdic) {
//            NSInteger deleteNum = [semaphoresdic[@"deleteNum"] integerValue];
//            deleteNum ++;
//            [semaphoresdic setValue:@(deleteNum) forKey:@"deleteNum"];
//            if (deleteNum == 2) {
                if ([index isEqualToNumber:semaphoresdic[@"index"]]) {
                    NSLog(@"dddddd");
                    dispatch_semaphore_t semaphore = semaphoresdic[@"semaphore"];
                    dispatch_semaphore_signal(semaphore);
                }
//            }
        }
//    }
}

- (void)editScene {
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:selectedSceneId];
    if ([sceneEntity.members count]>0) {
        [self mainCollectionViewCellDelegateSceneCellTapAction:selectedSceneId];
    }
    
    if ([[CSRAppStateManager sharedInstance].selectedPlace.color boolValue]) {
        sceneEntity.enumMethod = @(YES);
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        DeviceListViewController *list = [[DeviceListViewController alloc] init];
        list.selectMode = DeviceListSelectMode_Multiple;
        
        NSArray *members = [sceneEntity.members allObjects];
        __block NSMutableArray *singleDevices = [[NSMutableArray alloc] init];
        [members enumerateObjectsUsingBlock:^(SceneMemberEntity *sceneMember, NSUInteger idx, BOOL * _Nonnull stop) {
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:sceneMember.deviceID];
            if (deviceEntity) {
                SingleDeviceModel *deviceModel = [[SingleDeviceModel alloc] init];
                deviceModel.deviceId = deviceEntity.deviceId;
                deviceModel.deviceName = deviceEntity.name;
                deviceModel.deviceShortName = deviceEntity.shortName;
                [singleDevices addObject:deviceModel];
            }
            
        }];
        list.originalMembers = singleDevices;
        
        [list getSelectedDevices:^(NSArray *devices) {
            
            [members enumerateObjectsUsingBlock:^(SceneMemberEntity *sceneMember, NSUInteger idx, BOOL * _Nonnull stop) {
                [sceneEntity removeMembers:sceneEntity.members];
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:sceneMember];
                [[CSRDatabaseManager sharedInstance] saveContext];
            }];
            [devices enumerateObjectsUsingBlock:^(NSNumber *deviceId, NSUInteger idx, BOOL * _Nonnull stop) {
                DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
                SceneMemberEntity *sceneMember = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                sceneMember.sceneID = sceneEntity.sceneID;
                sceneMember.deviceID = deviceId;
                sceneMember.kindString = deviceModel.shortName;
                sceneMember.powerState = deviceModel.powerState;
                if ([CSRUtilities belongToFanController:deviceModel.shortName]) {
                    sceneMember.level = [NSNumber numberWithBool:deviceModel.fanState];
                    sceneMember.colorRed = [NSNumber numberWithInt:deviceModel.fansSpeed];
                    sceneMember.colorGreen = [NSNumber numberWithBool:deviceModel.lampState];
                    sceneMember.colorBlue = @(255);
                }else if ([CSRUtilities belongToSocket:deviceModel.shortName]||[CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]){
                    //colorTemperature:两路设备中的第二路事件类型；colorRed：两路设备中的第二路power状态；colorGreen：两路设备中的第二路亮度值
                    sceneMember.powerState = [NSNumber numberWithBool:deviceModel.channel1PowerState];
                    sceneMember.level = [NSNumber numberWithInteger:deviceModel.channel1Level];
                    sceneMember.colorRed = [NSNumber numberWithBool:deviceModel.channel2PowerState];
                    sceneMember.colorGreen = [NSNumber numberWithInteger:deviceModel.channel2Level];
                }
                else {
                    sceneMember.level = [deviceModel.powerState boolValue]? deviceModel.level:@0;
                    sceneMember.colorRed = deviceModel.red;
                    sceneMember.colorGreen = deviceModel.green;
                    sceneMember.colorBlue = deviceModel.blue;
                }
                sceneMember.sortID = deviceEntity.sortId;
                sceneMember.colorTemperature = deviceModel.colorTemperature;
                if (![deviceModel.powerState boolValue] && ![CSRUtilities belongToFanController:deviceModel.shortName] && ![CSRUtilities belongToSocket:deviceModel.shortName] && ![CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
                    sceneMember.eveType = @(11);
                }else if ([CSRUtilities belongToSwitch:deviceModel.shortName]) {
                    sceneMember.eveType = @(10);
                }else if ([CSRUtilities belongToDimmer:deviceModel.shortName]) {
                    sceneMember.eveType = @(12);
                }else if ([CSRUtilities belongToCWDevice:deviceModel.shortName]) {
                    sceneMember.eveType = @(19);
                }else if ([CSRUtilities belongToRGBDevice:deviceModel.shortName]) {
                    sceneMember.eveType = @(14);
                }else if ([CSRUtilities belongToRGBCWDevice:deviceModel.shortName]) {
                    if ([deviceModel.supports integerValue] == 0) {
                        sceneMember.eveType = @(14);
                    }else if ([deviceModel.supports integerValue] == 1) {
                        sceneMember.eveType = @(19);
                        NSString *temStr = [CSRUtilities stringWithHexNumber:[deviceModel.colorTemperature integerValue]];
                        sceneMember.colorRed = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[temStr substringFromIndex:2]]];
                        sceneMember.colorGreen = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[temStr substringToIndex:2]]];
                        sceneMember.colorBlue = @(255);
                    }
                }else if ([CSRUtilities belongToCWNoLevelDevice:deviceModel.shortName]) {
                    sceneMember.eveType = @(18);
                }else if ([CSRUtilities belongToRGBNoLevelDevice:deviceModel.shortName]) {
                    sceneMember.eveType = @(13);
                }else if ([CSRUtilities belongToRGBCWNoLevelDevice:deviceModel.shortName]) {
                    if ([deviceModel.supports integerValue] ==0) {
                        sceneMember.eveType = @(13);
                    }else if ([deviceModel.supports integerValue] ==1) {
                        sceneMember.eveType = @(18);
                        NSString *temStr = [CSRUtilities stringWithHexNumber:[deviceModel.colorTemperature integerValue]];
                        sceneMember.colorRed = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[temStr substringFromIndex:2]]];
                        sceneMember.colorGreen = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[temStr substringToIndex:2]]];
                        sceneMember.colorBlue = @(255);
                    }
                }else if ([CSRUtilities belongToFanController:deviceModel.shortName]) {
                    sceneMember.eveType = @(20);
                }else if ([CSRUtilities belongToSocket:deviceModel.shortName]) {
                    if (deviceModel.channel1Selected) {
                        if (deviceModel.channel1PowerState) {
                            sceneMember.eveType = @(10);
                        }else {
                            sceneMember.eveType = @(11);
                        }
                    }
                    if (deviceModel.channel2Selected) {
                        if (deviceModel.channel2PowerState) {
                            sceneMember.colorTemperature = @(10);
                        }else {
                            sceneMember.colorTemperature = @(11);
                        }
                    }
                }else if ([CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
                    if (deviceModel.channel1Selected) {
                        if (deviceModel.channel1PowerState) {
                            sceneMember.eveType = @(12);
                        }else {
                            sceneMember.eveType = @(11);
                        }
                        if (deviceModel.channel2PowerState) {
                            sceneMember.colorTemperature = @(12);
                        }else {
                            sceneMember.colorTemperature = @(11);
                        }
                    }
                }
                
                [sceneEntity addMembersObject:sceneMember];
                [[CSRDatabaseManager sharedInstance] saveContext];
            }];
            
            
        }];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
        
        [self presentViewController:nav animated:YES completion:nil];
    }else {
        sceneEntity.enumMethod = @(NO);
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        DeviceListViewController *list = [[DeviceListViewController alloc] init];
        list.selectMode = DeviceListSelectMode_Multiple;
        
        NSString *cmdString = [NSString stringWithFormat:@"950300%@",[CSRUtilities exchangePositionOfDeviceId:[sceneEntity.rcIndex integerValue]]];
        [[DataModelApi sharedInstance] sendData:@0 data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
        
        NSArray *members = [sceneEntity.members allObjects];
        __block NSMutableArray *singleDevices = [[NSMutableArray alloc] init];
        [members enumerateObjectsUsingBlock:^(SceneMemberEntity *sceneMember, NSUInteger idx, BOOL * _Nonnull stop) {
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:sceneMember.deviceID];
            if (deviceEntity) {
                SingleDeviceModel *deviceModel = [[SingleDeviceModel alloc] init];
                deviceModel.deviceId = deviceEntity.deviceId;
                deviceModel.deviceName = deviceEntity.name;
                deviceModel.deviceShortName = deviceEntity.shortName;
                [singleDevices addObject:deviceModel];
            }
            
        }];
        list.originalMembers = singleDevices;
        
        __block MainViewController *weakSelf = self;
        [list getSelectedDevices:^(NSArray *devices) {
            
            if (!weakSelf.sceneSettingHud) {
                weakSelf.sceneSettingHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                weakSelf.sceneSettingHud.mode = MBProgressHUDModeIndeterminate;
                weakSelf.sceneSettingHud.delegate = self;
            }
            [self.semaphores removeAllObjects];
            for (SceneMemberEntity *sceneMember in members) {
                if ([CSRUtilities belongToSocket:sceneMember.kindString] || [CSRUtilities belongToTwoChannelDimmer:sceneMember.kindString]) {
                    NSString *cmdString = [NSString stringWithFormat:@"5d0303%@",[CSRUtilities exchangePositionOfDeviceId:[sceneEntity.rcIndex integerValue]]];
                    [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
                    
                    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:semaphore, @"semaphore", @1, @"channel", sceneEntity.rcIndex, @"index", nil];
                    [self.semaphores setObject:dic forKey:sceneMember.deviceID];
                    
                }else if (![devices containsObject:sceneMember.deviceID]) {
                    NSString *cmdString = [NSString stringWithFormat:@"9802%@",[CSRUtilities exchangePositionOfDeviceId:[sceneEntity.rcIndex integerValue]]];
                    [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
                }
            }
            
            for (SceneMemberEntity *sceneMember in members) {
                [sceneEntity removeMembersObject:sceneMember];
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:sceneMember];
            }
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            [devices enumerateObjectsUsingBlock:^(NSNumber *deviceId, NSUInteger idx, BOOL * _Nonnull stop) {
                DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
                SceneMemberEntity *sceneMember = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                sceneMember.sceneID = sceneEntity.sceneID;
                sceneMember.deviceID = deviceId;
                sceneMember.kindString = deviceModel.shortName;
                sceneMember.powerState = deviceModel.powerState;
                if ([CSRUtilities belongToFanController:deviceModel.shortName]) {
                    sceneMember.level = [NSNumber numberWithBool:deviceModel.fanState];
                    sceneMember.colorRed = [NSNumber numberWithInt:deviceModel.fansSpeed];
                    sceneMember.colorGreen = [NSNumber numberWithBool:deviceModel.lampState];
                    sceneMember.colorBlue = @(255);
                }else if ([CSRUtilities belongToSocket:deviceModel.shortName]||[CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]){
                    //colorTemperature:两路设备中的第二路事件类型；colorRed：两路设备中的第二路power状态；colorGreen：两路设备中的第二路亮度值
                    sceneMember.powerState = [NSNumber numberWithBool:deviceModel.channel1PowerState];
                    sceneMember.level = [NSNumber numberWithInteger:deviceModel.channel1Level];
                    sceneMember.colorRed = [NSNumber numberWithBool:deviceModel.channel2PowerState];
                    sceneMember.colorGreen = [NSNumber numberWithInteger:deviceModel.channel2Level];
                }
                else {
                    sceneMember.level = [deviceModel.powerState boolValue]? deviceModel.level:@0;
                    sceneMember.colorRed = deviceModel.red;
                    sceneMember.colorGreen = deviceModel.green;
                    sceneMember.colorBlue = deviceModel.blue;
                }
                sceneMember.sortID = deviceEntity.sortId;
                sceneMember.colorTemperature = deviceModel.colorTemperature;
                if (![deviceModel.powerState boolValue] && ![CSRUtilities belongToFanController:deviceModel.shortName] && ![CSRUtilities belongToSocket:deviceModel.shortName] && ![CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
                    sceneMember.eveType = @(11);
                }else if ([CSRUtilities belongToSwitch:deviceModel.shortName]) {
                    sceneMember.eveType = @(10);
                }else if ([CSRUtilities belongToDimmer:deviceModel.shortName]) {
                    sceneMember.eveType = @(12);
                }else if ([CSRUtilities belongToCWDevice:deviceModel.shortName]) {
                    sceneMember.eveType = @(19);
                }else if ([CSRUtilities belongToRGBDevice:deviceModel.shortName]) {
                    sceneMember.eveType = @(14);
                }else if ([CSRUtilities belongToRGBCWDevice:deviceModel.shortName]) {
                    if ([deviceModel.supports integerValue] == 0) {
                        sceneMember.eveType = @(14);
                    }else if ([deviceModel.supports integerValue] == 1) {
                        sceneMember.eveType = @(19);
                        NSString *temStr = [CSRUtilities stringWithHexNumber:[deviceModel.colorTemperature integerValue]];
                        sceneMember.colorRed = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[temStr substringFromIndex:2]]];
                        sceneMember.colorGreen = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[temStr substringToIndex:2]]];
                        sceneMember.colorBlue = @(255);
                    }
                }else if ([CSRUtilities belongToCWNoLevelDevice:deviceModel.shortName]) {
                    sceneMember.eveType = @(18);
                }else if ([CSRUtilities belongToRGBNoLevelDevice:deviceModel.shortName]) {
                    sceneMember.eveType = @(13);
                }else if ([CSRUtilities belongToRGBCWNoLevelDevice:deviceModel.shortName]) {
                    if ([deviceModel.supports integerValue] ==0) {
                        sceneMember.eveType = @(13);
                    }else if ([deviceModel.supports integerValue] ==1) {
                        sceneMember.eveType = @(18);
                        NSString *temStr = [CSRUtilities stringWithHexNumber:[deviceModel.colorTemperature integerValue]];
                        sceneMember.colorRed = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[temStr substringFromIndex:2]]];
                        sceneMember.colorGreen = [NSNumber numberWithInteger:[CSRUtilities numberWithHexString:[temStr substringToIndex:2]]];
                        sceneMember.colorBlue = @(255);
                    }
                }else if ([CSRUtilities belongToFanController:deviceModel.shortName]) {
                    sceneMember.eveType = @(20);
                }else if ([CSRUtilities belongToSocket:deviceModel.shortName]) {
                    if (deviceModel.channel1Selected) {
                        if (deviceModel.channel1PowerState) {
                            sceneMember.eveType = @(10);
                        }else {
                            sceneMember.eveType = @(11);
                        }
                    }
                    if (deviceModel.channel2Selected) {
                        if (deviceModel.channel2PowerState) {
                            sceneMember.colorTemperature = @(10);
                        }else {
                            sceneMember.colorTemperature = @(11);
                        }
                    }
                }else if ([CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
                    if (deviceModel.channel1Selected) {
                        if (deviceModel.channel1PowerState) {
                            sceneMember.eveType = @(12);
                        }else {
                            sceneMember.eveType = @(11);
                        }
                    }
                    if (deviceModel.channel2Selected) { 
                        if (deviceModel.channel2PowerState) {
                            sceneMember.colorTemperature = @(12);
                        }else {
                            sceneMember.colorTemperature = @(11);
                        }
                    }
                }
                
                [sceneEntity addMembersObject:sceneMember];
                [[CSRDatabaseManager sharedInstance] saveContext];
                
                NSString *rcIndexString = [CSRUtilities exchangePositionOfDeviceId:[sceneEntity.rcIndex integerValue]];
                if ([CSRUtilities belongToSocket:deviceModel.shortName] || [CSRUtilities belongToTwoChannelDimmer:deviceModel.shortName]) {
                    
                    dispatch_queue_t queue = dispatch_queue_create("串行", NULL);
                    if (deviceModel.channel1Selected && deviceModel.channel2Selected) {
                        NSMutableDictionary *semaphoresdic = [self.semaphores objectForKey:deviceModel.deviceId];
                        __block dispatch_semaphore_t semaphore;
                        if (semaphoresdic) {
                            dispatch_async(queue, ^{
                                semaphore = semaphoresdic[@"semaphore"];
                                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSString *cmdString = [NSString stringWithFormat:@"590801%@%@%@000000",rcIndexString,sceneMember.eveType,[CSRUtilities stringWithHexNumber:[sceneMember.level integerValue]]];
                                    [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
                                });
                            });
                        }else {
                            NSString *cmdString = [NSString stringWithFormat:@"590801%@%@%@000000",rcIndexString,sceneMember.eveType,[CSRUtilities stringWithHexNumber:[sceneMember.level integerValue]]];
                            [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
                            semaphore = dispatch_semaphore_create(0);
                            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:semaphore, @"semaphore", @(1), @"channel", sceneEntity.rcIndex, @"index", @(0), @"deleteNum", nil];
                            [self.semaphores setObject:dic forKey:sceneMember.deviceID];
                        }
                        
                        dispatch_async(queue, ^{
                            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSString *cmdString = [NSString stringWithFormat:@"590802%@%@%@000000",rcIndexString,sceneMember.colorTemperature,[CSRUtilities stringWithHexNumber:[sceneMember.colorGreen integerValue]]];
                                [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
                            });
                        });
                    }else {
                        NSMutableDictionary *semaphoresdic = [self.semaphores objectForKey:deviceModel.deviceId];
                        if (semaphoresdic) {
                            dispatch_async(queue, ^{
                                dispatch_semaphore_t semaphore = semaphoresdic[@"semaphore"];
                                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (deviceModel.channel1Selected) {
                                        NSString *cmdString = [NSString stringWithFormat:@"590801%@%@%@000000",rcIndexString,sceneMember.eveType,[CSRUtilities stringWithHexNumber:[sceneMember.level integerValue]]];
                                        [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
                                    }
                                    if (deviceModel.channel2Selected) {
                                        NSString *cmdString = [NSString stringWithFormat:@"590802%@%@%@000000",rcIndexString,sceneMember.colorTemperature,[CSRUtilities stringWithHexNumber:[sceneMember.colorGreen integerValue]]];
                                        [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
                                    }
                                });
                            });
                        }else {
                            if (deviceModel.channel1Selected) {
                                NSString *cmdString = [NSString stringWithFormat:@"590801%@%@%@000000",rcIndexString,sceneMember.eveType,[CSRUtilities stringWithHexNumber:[sceneMember.level integerValue]]];
                                [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
                            }
                            if (deviceModel.channel2Selected) {
                                NSString *cmdString = [NSString stringWithFormat:@"590802%@%@%@000000",rcIndexString,sceneMember.colorTemperature,[CSRUtilities stringWithHexNumber:[sceneMember.colorGreen integerValue]]];
                                [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
                            }
                        }
                    }
                }else {
                    NSString *ddd = [NSString stringWithFormat:@"%@%@%@",[CSRUtilities stringWithHexNumber:[sceneMember.colorRed integerValue]],[CSRUtilities stringWithHexNumber:[sceneMember.colorGreen integerValue]],[CSRUtilities stringWithHexNumber:[sceneMember.colorBlue integerValue]]];
                    NSString *cmdString = [NSString stringWithFormat:@"9307%@%@%@%@",rcIndexString,sceneMember.eveType,[CSRUtilities stringWithHexNumber:[sceneMember.level integerValue]],ddd];
                    [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
                }
                
                [NSThread sleepForTimeInterval:0.1f];
                
            }];
            
            [weakSelf.sceneSettingHud hideAnimated:YES];
            weakSelf.sceneSettingHud = nil;
            
        }];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
        
        [self presentViewController:nav animated:YES completion:nil];
    }
}

//点击场景单元
- (void)mainCollectionViewCellDelegateSceneCellTapAction:(NSNumber *)sceneId {
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:sceneId];
    NSMutableArray *members = [[sceneEntity.members allObjects] mutableCopy];
    if ([members count] != 0) {
        if ([sceneEntity.enumMethod boolValue]) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortID" ascending:YES];
            [members sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [members enumerateObjectsUsingBlock:^(SceneMemberEntity *sceneMember, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if ([CSRUtilities belongToSocket:sceneMember.kindString]) {
                    if (sceneMember.eveType && sceneMember.colorTemperature && [sceneMember.eveType isEqualToNumber:@(11)] && [sceneMember.colorTemperature isEqualToNumber:@(11)]) {
                        [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:sceneMember.deviceID withPowerState:@(0)];
                    }else if (sceneMember.eveType && sceneMember.colorTemperature && [sceneMember.eveType isEqualToNumber:@(10)] && [sceneMember.colorTemperature isEqualToNumber:@(10)]) {
                        [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:sceneMember.deviceID withPowerState:@(1)];
                    }else {
                        if ([sceneMember.eveType isEqualToNumber:@(11)]) {
                            [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:@"51050100010000"] success:nil failure:nil];
                            [NSThread sleepForTimeInterval:0.05];
                        }else if ([sceneMember.eveType isEqualToNumber:@(10)]) {
                            [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:@"510501000101ff"] success:nil failure:nil];
                            [NSThread sleepForTimeInterval:0.05];
                        }
                        if ([sceneMember.colorTemperature isEqualToNumber:@(11)]) {
                            [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:@"51050200010000"] success:nil failure:nil];
                        }else if ([sceneMember.colorTemperature isEqualToNumber:@(10)]) {
                            [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:@"510502000101ff"] success:nil failure:nil];
                        }
                    }
                }else if ([CSRUtilities belongToTwoChannelDimmer:sceneMember.kindString]) {
                    if (sceneMember.eveType && sceneMember.colorTemperature && [sceneMember.eveType isEqualToNumber:@(11)] && [sceneMember.colorTemperature isEqualToNumber:@(11)]) {
                        [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:sceneMember.deviceID withPowerState:@(0)];
                    }else if (sceneMember.eveType && sceneMember.colorTemperature && [sceneMember.eveType isEqualToNumber:@(12)] && [sceneMember.colorTemperature isEqualToNumber:@(12)] && sceneMember.level && sceneMember.colorGreen && [sceneMember.level isEqualToNumber:sceneMember.colorGreen]) {
                        [[LightModelApi sharedInstance] setLevel:sceneMember.deviceID level:sceneMember.level success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                            
                        } failure:^(NSError * _Nullable error) {
                            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:sceneMember.deviceID];
                            model.isleave = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":sceneMember.deviceID}];
                        }];

                    }else {
                        if ([sceneMember.eveType isEqualToNumber:@(11)]) {
                            [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:@"51050100010000"] success:nil failure:nil];
                            [NSThread sleepForTimeInterval:0.05];
                        }else if ([sceneMember.eveType isEqualToNumber:@(12)]) {
                            [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"510501000301%@",[CSRUtilities stringWithHexNumber:[sceneMember.level integerValue]]]] success:nil failure:nil];
                            [NSThread sleepForTimeInterval:0.05];
                        }
                        if ([sceneMember.colorTemperature isEqualToNumber:@(11)]) {
                            [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:@"51050200010000"] success:nil failure:nil];
                        }else if ([sceneMember.colorTemperature isEqualToNumber:@(12)]) {
                            [[DataModelApi sharedInstance] sendData:sceneMember.deviceID data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"510502000301%@",[CSRUtilities stringWithHexNumber:[sceneMember.colorGreen integerValue]]]] success:nil failure:nil];
                        }
                    }
                }else {
                    if ([sceneMember.eveType isEqualToNumber:@(11)]) {
                        [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:sceneMember.deviceID withPowerState:@(0)];
                    }else if ([sceneMember.eveType isEqualToNumber:@(10)]) {
                        [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:sceneMember.deviceID withPowerState:@(1)];
                    }else if ([sceneMember.eveType isEqualToNumber:@(12)]) {
                        [[LightModelApi sharedInstance] setLevel:sceneMember.deviceID level:sceneMember.level success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                            
                        } failure:^(NSError * _Nullable error) {
                            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:sceneMember.deviceID];
                            model.isleave = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":sceneMember.deviceID}];
                        }];
                    }else if ([sceneMember.eveType isEqualToNumber:@(19)]) {
                        [[LightModelApi sharedInstance] setLevel:sceneMember.deviceID level:sceneMember.level success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                            
                        } failure:^(NSError * _Nullable error) {
                            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:sceneMember.deviceID];
                            model.isleave = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":sceneMember.deviceID}];
                        }];
                        [[LightModelApi sharedInstance] setColorTemperature:sceneMember.deviceID temperature:sceneMember.colorTemperature duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                            
                        } failure:^(NSError * _Nullable error) {
                            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:sceneMember.deviceID];
                            model.isleave = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":sceneMember.deviceID}];
                        }];
                    }else if ([sceneMember.eveType isEqualToNumber:@(14)]) {
                        [[LightModelApi sharedInstance] setLevel:sceneMember.deviceID level:sceneMember.level success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                            
                        } failure:^(NSError * _Nullable error) {
                            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:sceneMember.deviceID];
                            model.isleave = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":sceneMember.deviceID}];
                        }];
                        UIColor *color = [UIColor colorWithRed:[sceneMember.colorRed integerValue]/255.0 green:[sceneMember.colorGreen integerValue]/255.0 blue:[sceneMember.colorBlue integerValue]/255.0 alpha:1.0];
                        [[LightModelApi sharedInstance] setColor:sceneMember.deviceID color:color duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                            
                        } failure:^(NSError * _Nullable error) {
                            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:sceneMember.deviceID];
                            model.isleave = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":sceneMember.deviceID}];
                        }];
                        
                    }else if ([sceneMember.eveType isEqualToNumber:@(18)]) {
                        [[LightModelApi sharedInstance] setColorTemperature:sceneMember.deviceID temperature:sceneMember.colorTemperature duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                            
                        } failure:^(NSError * _Nullable error) {
                            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:sceneMember.deviceID];
                            model.isleave = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":sceneMember.deviceID}];
                        }];
                    }else if ([sceneMember.eveType isEqualToNumber:@(13)]) {
                        UIColor *color = [UIColor colorWithRed:[sceneMember.colorRed integerValue]/255.0 green:[sceneMember.colorGreen integerValue]/255.0 blue:[sceneMember.colorBlue integerValue]/255.0 alpha:1.0];
                        [[LightModelApi sharedInstance] setColor:sceneMember.deviceID color:color duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                            
                        } failure:^(NSError * _Nullable error) {
                            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:sceneMember.deviceID];
                            model.isleave = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":sceneMember.deviceID}];
                        }];
                    }
                }
                
                [NSThread sleepForTimeInterval:0.03];
            }];
        }else {
            NSString *cmdString = [NSString stringWithFormat:@"9a02%@",[CSRUtilities exchangePositionOfDeviceId:[sceneEntity.rcIndex integerValue]]];
            [[DataModelApi sharedInstance] sendData:@0 data:[CSRUtilities dataForHexString:cmdString] success:nil failure:nil];
        }
        
    }else {
        if ([self determineDeviceHasBeenAdded]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
            NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:AcTECLocalizedStringFromTable(@"SceneNoDevice", @"Localizable")];
            [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
            [alertController setValue:attributedMessage forKey:@"attributedMessage"];
            [alertController.view setTintColor:DARKORAGE];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                selectedSceneId = sceneId;
                [self editScene];
                
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
        if ([CSRUtilities belongToRGBDevice:deviceEntity.shortName]||[CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]||[CSRUtilities belongToRGBNoLevelDevice:deviceEntity.shortName]||[CSRUtilities belongToRGBCWNoLevelDevice:deviceEntity.shortName]) {
            
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
                _selectedCurtainDeviceId = mainCell.deviceId;
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
            
        }else if ([CSRUtilities belongToSocket:deviceEntity.shortName]) {
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
        }else if ([CSRUtilities belongToTwoChannelDimmer:deviceEntity.shortName]) {
            TwoChannelDimmerVC *tdvc = [[TwoChannelDimmerVC alloc] init];
            tdvc.deviceId = mainCell.deviceId;
            __weak MainViewController *weakSelf = self;
            tdvc.reloadDataHandle = ^{
                [weakSelf getMainDataArray];
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:tdvc];
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
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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

- (void)mainCollectionViewCellDelegateCurtainTapAction:(NSNumber *)deviceId {

    _selectedCurtainDeviceId = deviceId;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
        [[UIApplication sharedApplication].keyWindow addSubview:self.curtainKindView];
        [self.curtainKindView autoCenterInSuperview];
        [self.curtainKindView autoSetDimensionsToSize:CGSizeMake(271, 166)];
    });
}

- (void)selectTypeOfCurtain:(UIButton *)sender {
    
    CSRDeviceEntity *curtainEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_selectedCurtainDeviceId];
    if (sender.tag == 11) {
        curtainEntity.remoteBranch = @"ch";
    }else if (sender.tag == 22) {
        curtainEntity.remoteBranch = @"cv";
    }
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [self getMainDataArray];
    
    _selectedCurtainDeviceId = nil;
    
    [self.curtainKindView removeFromSuperview];
    self.curtainKindView = nil;
    [self.translucentBgView removeFromSuperview];
    self.translucentBgView = nil;
}

#pragma mark - notification

-(void)deleteStatus:(NSNotification *)notification
{
    NSNumber *num = notification.userInfo[@"boolFlag"];
    if ([num boolValue] == NO) {
        [self showForceAlert];
    } else {
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
        if (_hud) {
            [_hud hideAnimated:YES];
            _hud = nil;
        }
    }
}

- (void) showForceAlert
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
                                                             
                                                             [[CSRDatabaseManager sharedInstance] saveContext];
                                                             
                                                             [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteDeviceEntity" object:nil];
                                                         }
                                                         NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
                                                         [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
                                                         [self getMainDataArray];
                                                         [self mainCollectionViewEditlayoutView];
                                                         if (_hud) {
                                                             [_hud hideAnimated:YES];
                                                             _hud = nil;
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
        horizontalBtn.tag = 11;
        [horizontalBtn setImage:[UIImage imageNamed:@"curtainHImage"] forState:UIControlStateNormal];
        [horizontalBtn addTarget:self action:@selector(selectTypeOfCurtain:) forControlEvents:UIControlEventTouchUpInside];
        [_curtainKindView addSubview:horizontalBtn];
        
        UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(135, 31, 1, 135)];
        line1.backgroundColor = [UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1];
        [_curtainKindView addSubview:line1];
        
        UIButton *verticalBtn = [[UIButton alloc] initWithFrame:CGRectMake(136, 31, 135, 135)];
        verticalBtn.tag = 22;
        [verticalBtn setImage:[UIImage imageNamed:@"curtainVImage"] forState:UIControlStateNormal];
        [verticalBtn addTarget:self action:@selector(selectTypeOfCurtain:) forControlEvents:UIControlEventTouchUpInside];
        [_curtainKindView addSubview:verticalBtn];
        
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

/*
#pragma mark - 获取位置

- (void)getLocation {
    if ([CLLocationManager locationServicesEnabled]) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        [locationManager requestAlwaysAuthorization];
        [locationManager requestWhenInUseAuthorization];
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.distanceFilter = 1000.0;
        [locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"定位关闭，提醒用户打开定位");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [locationManager stopUpdatingHeading];
    
    CLLocation *currentLocation = [locations lastObject];
    
    NSTimeInterval locationAge = -[currentLocation.timestamp timeIntervalSinceNow];

    if (locationAge > 1.0) {
        return;
    }
    
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    
    [geoCoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (placemarks.count>0) {
            CLPlacemark *placeMark = placemarks[0];
            currentCity = placeMark.locality;
            if (!currentCity) {
                NSLog(@"无法定位当前城市");
            }else {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    NSString *urlStr = [NSString stringWithFormat:@"https://query.yahooapis.com/v1/public/yql?q=select * from weather.forecast where woeid in (select woeid from geo.places(1) where text='%@')&format=json&env=store://datatables.org/alltableswithkeys",currentCity];
                    NSLog(@"%@",urlStr);
                    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
                    sessionManager.responseSerializer.acceptableContentTypes = nil;
                    [sessionManager GET:[urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                        NSDictionary *dic = (NSDictionary *)responseObject;
//                        NSLog(@"%@",dic);
                        NSDictionary *condition = dic[@"query"][@"results"][@"channel"][@"item"][@"condition"];
                        
                        NSInteger temp = [condition[@"temp"] integerValue];
                        _tempLabel.text = [NSString stringWithFormat:@"%ld",(temp-32)*5/9];
                        
                        NSString *date = condition[@"date"];
                        if (date) {
                            NSString *week = [date substringToIndex:3];
                            if ([week isEqualToString:@"Mon"]) {
                                _weekLabel.text = @"Monday";
                            }else if ([week isEqualToString:@"Tue"]) {
                                _weekLabel.text = @"Tuesday";
                            }else if ([week isEqualToString:@"Wed"]) {
                                _weekLabel.text = @"Wednesday";
                            }else if ([week isEqualToString:@"Thu"]) {
                                _weekLabel.text = @"Thursday";
                            }else if ([week isEqualToString:@"Fri"]) {
                                _weekLabel.text = @"Friday";
                            }else if ([week isEqualToString:@"Sat"]) {
                                _weekLabel.text = @"Saturday";
                            }else if ([week isEqualToString:@"Sun"]) {
                                _weekLabel.text = @"Sunday";
                            }
                            
                            NSString *day = [date substringWithRange:NSMakeRange(5, 11)];
                            _dayLabel.text = day;
                            
                        }
                        
                        NSNumber *code = [NSNumber numberWithInteger:[condition[@"code"] integerValue]];
                        NSString *urlString = kWeatherImageDic[code];
                        if (urlStr) {
                            [_weatherImageView sd_setImageWithURL:[NSURL URLWithString:urlString]];
                        }
                        
                        NSArray *forecast = dic[@"query"][@"results"][@"channel"][@"item"][@"forecast"];
                        NSInteger low = [forecast[0][@"low"] integerValue];
                        NSInteger high = [forecast[0][@"high"] integerValue];
                        _tempRangeLabel.text = [NSString stringWithFormat:@"%ld~%ld",(low-32)*5/9,(high-32)*5/9];
                        _tempUnit.text = @"℃";
                    } failure:^(NSURLSessionDataTask *task, NSError *error) {
                        NSLog(@"%@",error);
                    }];
                    
                });
            }
            
        }
        
    }];
     
}

- (IBAction)refreshWeatherUI:(id)sender {
    [self getLocation];
}
*/

@end
