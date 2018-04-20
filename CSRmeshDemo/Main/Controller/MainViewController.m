//
//  MainViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/17.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MainViewController.h"
#import "MainCollectionView.h"
#import "CSRAppStateManager.h"
#import "CSRAreaEntity.h"
#import "AreaModel.h"
#import "CSRDeviceEntity.h"
#import "AddDevcieViewController.h"
#import "DeviceModelManager.h"
#import "ImproveTouchingExperience.h"
#import "ControlMaskView.h"
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

@interface MainViewController ()<MainCollectionViewDelegate,PlaceColorIconPickerViewDelegate>
{
    NSNumber *selectedSceneId;
    PlaceColorIconPickerView *pickerView;
    NSUInteger sceneIconId;
    CSRmeshDevice *meshDevice;
    CSRDeviceEntity *deleteDeviceEntity;
}

@property (nonatomic,strong) MainCollectionView *mainCollectionView;
@property (nonatomic,strong) MainCollectionView *sceneCollectionView;
@property (nonatomic,strong) NSNumber *originalLevel;
@property (nonatomic,strong) ImproveTouchingExperience *improver;
@property (nonatomic,strong) ControlMaskView *maskLayer;
@property (nonatomic,assign) BOOL mainCVEditting;
@property (nonatomic,strong) UIActivityIndicatorView *spinner;
@property (nonatomic,strong) CSRAreaEntity *areaEntity;
@property (nonatomic,strong) UIView *translucentBgView;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"Main";
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editMainView)];
    self.navigationItem.rightBarButtonItem = edit;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reGetDataForPlaceChanged) name:@"reGetDataForPlaceChanged" object:nil];
    
    self.improver = [[ImproveTouchingExperience alloc] init];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = WIDTH*8.0/640.0;
    flowLayout.minimumInteritemSpacing = WIDTH*8.0/640.0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, floor(WIDTH*3/160.0));
    flowLayout.itemSize = CGSizeMake(WIDTH*3/8.0, WIDTH*9/32.0);
    _mainCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectMake(WIDTH*7/32.0, WIDTH*151/320.0+64, WIDTH*25/32.0, HEIGHT-114-WIDTH*157/320.0) collectionViewLayout:flowLayout cellIdentifier:@"MainCollectionViewCell"];
    _mainCollectionView.mainDelegate = self;
    [self.view addSubview:_mainCollectionView];
    
    UICollectionViewFlowLayout *sceneFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    sceneFlowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    sceneFlowLayout.minimumLineSpacing = 0;
    sceneFlowLayout.minimumInteritemSpacing = 0;
    sceneFlowLayout.itemSize = CGSizeMake(WIDTH*3/16.0, (HEIGHT-114-WIDTH*157/320)/4.0);
    _sceneCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectMake(WIDTH*3/160.0, WIDTH*151/320.0+64, WIDTH*3/16.0, HEIGHT-114-WIDTH*157/320.0) collectionViewLayout:sceneFlowLayout cellIdentifier:@"SceneCollectionViewCell"];
    _sceneCollectionView.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1];
    _sceneCollectionView.mainDelegate = self;
    [self.view addSubview:_sceneCollectionView];
    
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
        [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([CSRUtilities belongToDimmer:deviceEntity.shortName] || [CSRUtilities belongToSwitch:deviceEntity.shortName]) {
                if (![deviceIdWasInAreaArray containsObject:deviceEntity.deviceId]) {
                    deviceEntity.isEditting = @(_mainCVEditting);
                    [_mainCollectionView.dataArray addObject:deviceEntity];
                }
            }
        }];
    }
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortId" ascending:YES];
    [_mainCollectionView.dataArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];

    [_mainCollectionView.dataArray addObject:@0];
    
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
            if (_mainCVEditting) {
                [self.mainCollectionView.dataArray removeObject:obj];
            }
        }
    }];
    if (!_mainCVEditting) {
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
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneItemAction)];
    self.navigationItem.rightBarButtonItem = done;
    _mainCVEditting = YES;
    [self mainCollectionViewEditlayoutView];
}

- (void)doneItemAction {
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editMainView)];
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
    UIAlertAction *camera = [UIAlertAction actionWithTitle:@"Create New Group" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
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
    UIAlertAction *album = [UIAlertAction actionWithTitle:@"Search New Devices" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if ([cellDeviceId isEqualToNumber:@1000]) {
            [self presentToAddViewController];
        }
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
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
    __weak MainViewController *weakSelf = self;
    addVC.handle = ^{
        [weakSelf getMainDataArray];
    };
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
            [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
            [[UIApplication sharedApplication].keyWindow addSubview:pickerView];
            [pickerView autoCenterInSuperview];
            [pickerView autoSetDimensionsToSize:CGSizeMake(270, 190)];
        }
        return;
    }
    if ([actionName isEqualToString:@"Rename"]) {
        NSLog(@"Rename");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Rename" message:@"Enter a name for the scene." preferredStyle:UIAlertControllerStyleAlert];
        NSMutableAttributedString *hogan = [[NSMutableAttributedString alloc] initWithString:@"Rename"];
        [hogan addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1] range:NSMakeRange(0, [[hogan string] length])];
        [alert setValue:hogan forKey:@"attributedTitle"];
        NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:@"Enter a name for the scene."];
        [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
        [alert setValue:attributedMessage forKey:@"attributedMessage"];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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

- (void)editScene {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_Multiple;
    
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:selectedSceneId];
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
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:sceneMember];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }];
        [devices enumerateObjectsUsingBlock:^(NSNumber *deviceId, NSUInteger idx, BOOL * _Nonnull stop) {
            DeviceModel *deviceModel = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
            SceneMemberEntity *sceneMember = [NSEntityDescription insertNewObjectForEntityForName:@"SceneMemberEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
            sceneMember.sceneID = sceneEntity.sceneID;
            sceneMember.deviceID = deviceId;
            sceneMember.kindString = deviceModel.shortName;
            sceneMember.powerState = deviceModel.powerState;
            sceneMember.level = [deviceModel.powerState boolValue]? deviceModel.level:@0;
            [sceneEntity addMembersObject:sceneMember];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }];
        
        
    }];
    
    [self.navigationController pushViewController:list animated:YES];
}

//点击场景单元
- (void)mainCollectionViewCellDelegateSceneCellTapAction:(NSNumber *)sceneId {
    SceneEntity *sceneEntity = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:sceneId];
    NSArray *members = [sceneEntity.members allObjects];
    if ([members count]>0) {
        [members enumerateObjectsUsingBlock:^(SceneMemberEntity *sceneMember, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([CSRUtilities belongToSwitch:sceneMember.kindString]) {
                [[DeviceModelManager sharedInstance] setPowerStateWithDeviceId:sceneMember.deviceID withPowerState:sceneMember.powerState];
            }else if ([CSRUtilities belongToDimmer:sceneMember.kindString]) {
                [[LightModelApi sharedInstance] setLevel:sceneMember.deviceID level:sceneMember.level success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                    __block BOOL exist;
                    [[DeviceModelManager sharedInstance].allDevices enumerateObjectsUsingBlock:^(DeviceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([model.deviceId isEqualToNumber:deviceId]) {
                            
                            model.powerState = powerState;
                            model.level = sceneMember.level;
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":deviceId}];
                            
                            exist = YES;
                            *stop = YES;
                        }
                        
                    }];
                    if (!exist) {
                        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
                        DeviceModel *model = [[DeviceModel alloc] init];
                        model.deviceId = deviceEntity.deviceId;
                        model.shortName = deviceEntity.shortName;
                        model.name = deviceEntity.name;
                        model.powerState = powerState;
                        model.level = sceneMember.level;
                        [[DeviceModelManager sharedInstance].allDevices addObject:model];
                        [[DataModelManager shareInstance] setDeviceTime:deviceEntity.deviceId];
                    }
                } failure:^(NSError * _Nullable error) {

                }];
            }
            
        }];
    }else {
        if ([self determineDeviceHasBeenAdded]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Empty Scene" message:@"Edit scene now?" preferredStyle:UIAlertControllerStyleAlert];
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:@"Empty Scene"];
            [attributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1] range:NSMakeRange(0, [[attributedTitle string] length])];
            [alertController setValue:attributedTitle forKey:@"attributedTitle"];
            NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:@"Edit scene now?"];
            [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
            [alertController setValue:attributedMessage forKey:@"attributedMessage"];
            [alertController.view setTintColor:DARKORAGE];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                selectedSceneId = sceneId;
                [self editScene];
                
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
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
        DeviceViewController *dvc = [[DeviceViewController alloc] init];
        dvc.deviceId = mainCell.deviceId;
        __weak MainViewController *weakSelf = self;
        dvc.reloadDataHandle = ^{
            [weakSelf getMainDataArray];
        };
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:dvc];
        nav.modalPresentationStyle = UIModalPresentationPopover;
        [self presentViewController:nav animated:YES completion:nil];
        UIPopoverPresentationController *popover = nav.popoverPresentationController;
        popover.sourceRect = mainCell.bounds;
        popover.sourceView = mainCell;
    }else if ([mainCell.deviceId isEqualToNumber:@2000]) {
        GroupViewController *gvc = [[GroupViewController alloc] init];
        __weak MainViewController *weakSelf = self;
        gvc.handle = ^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Group" message:[NSString stringWithFormat:@"Are you sure that you want to delete this group :%@?",_areaEntity.areaName] preferredStyle:UIAlertControllerStyleAlert];
        [alertController.view setTintColor:DARKORAGE];
        __weak MainViewController *weakSelf = self;
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
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
                [_spinner stopAnimating];
                [_spinner setHidden:YES];
            });
            
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
        
        
    }else{
        meshDevice = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:cellDeviceId];
        CSRPlaceEntity *placeEntity = [CSRAppStateManager sharedInstance].selectedPlace;
        deleteDeviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:cellDeviceId];
        
        if (![CSRUtilities isStringEmpty:placeEntity.passPhrase]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Device" message:[NSString stringWithFormat:@"Are you sure that you want to delete this device : %@?",meshDevice.name] preferredStyle:UIAlertControllerStyleAlert];
            [alertController.view setTintColor:DARKORAGE];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (meshDevice) {
                    [[CSRDevicesManager sharedInstance] initiateRemoveDevice:meshDevice];
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
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"No device in this group,choose devices now?" preferredStyle:UIAlertControllerStyleAlert];
        NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:@"No device in this group,choose devices now?"];
        [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
        [alertController setValue:attributedMessage forKey:@"attributedMessage"];
        [alertController.view setTintColor:DARKORAGE];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
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
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
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
        if ([CSRUtilities belongToDimmer:deviceEntity.shortName]||[CSRUtilities belongToSwitch:deviceEntity.shortName]) {
            exist = YES;
            *stop = YES;
        }
    }];
    return exist;
}

- (void)noDevicHasBeenAddedAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"No bluetooth device has been added for this place,search and add devices now?" preferredStyle:UIAlertControllerStyleAlert];
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:@"No bluetooth device has been added for this place,search and add devices now?"];
    [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
    [alertController setValue:attributedMessage forKey:@"attributedMessage"];
    [alertController.view setTintColor:DARKORAGE];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self presentToAddViewController];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - notification

-(void)deleteStatus:(NSNotification *)notification
{
    NSNumber *num = notification.userInfo[@"boolFlag"];
    if ([num boolValue] == NO) {
        
        [self showForceAlert];
    } else {
        if(deleteDeviceEntity) {
            [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:deleteDeviceEntity];
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:deleteDeviceEntity];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
        NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
        [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
        
        [self getMainDataArray];
        __weak MainViewController *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf mainCollectionViewEditlayoutView];
        });
        [_spinner stopAnimating];
        [_spinner setHidden:YES];
    }
}

- (void) showForceAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Device Device"
                                                                             message:[NSString stringWithFormat:@"Device wasn't found. Do you want to delete %@ anyway?", meshDevice.name]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController.view setTintColor:DARKORAGE];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"NO"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {

                                                         }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"YES"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         
                                                         if(deleteDeviceEntity) {
                                                             [[CSRAppStateManager sharedInstance].selectedPlace removeDevicesObject:deleteDeviceEntity];
                                                             [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:deleteDeviceEntity];
                                                             [[CSRDatabaseManager sharedInstance] saveContext];
                                                         }
                                                         NSNumber *deviceNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRDeviceEntity"];
                                                         [[CSRDevicesManager sharedInstance] setDeviceIdNumber:deviceNumber];
                                                         [self getMainDataArray];
                                                         [self mainCollectionViewEditlayoutView];
                                                         [_spinner stopAnimating];
                                                         [_spinner setHidden:YES];
                                                     }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)reGetDataForPlaceChanged {
    [self getMainDataArray];
    [self getSceneDataArray];
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
