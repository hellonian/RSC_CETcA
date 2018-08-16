//
//  GroupViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/30.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "GroupViewController.h"
#import "PlaceColorIconPickerView.h"
#import "PureLayout.h"
#import "DeviceListViewController.h"
#import "CSRDatabaseManager.h"
#import "CSRDeviceEntity.h"
#import <CSRmesh/GroupModelApi.h>
#import <MBProgressHUD.h>
#import "DeviceModelManager.h"
#import "ImproveTouchingExperience.h"
#import "ControlMaskView.h"
#import "MainCollectionViewCell.h"
#import "DeviceViewController.h"
#import "CSRConstants.h"
#import "SingleDeviceModel.h"
#import "CSRUtilities.h"
#import "NSBundle+AppLanguageSwitch.h"
#import "TopImageView.h"

@interface GroupViewController ()<UITextFieldDelegate,PlaceColorIconPickerViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,MainCollectionViewDelegate,MBProgressHUDDelegate>
{
    PlaceColorIconPickerView *pickerView;
    NSNumber *iconNum;
    UIImage *iconImage;
    UIAlertController *alertController;
}

@property (weak, nonatomic) IBOutlet UIButton *editItem;
@property (weak, nonatomic) IBOutlet UIButton *backItem;
@property (weak, nonatomic) IBOutlet UITextField *groupNameTF;
@property (weak, nonatomic) IBOutlet UIButton *iconEditBtn;
@property (weak, nonatomic) IBOutlet UIImageView *groupIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *groupNameLabel;
@property (nonatomic,strong) MBProgressHUD *hud;
@property (nonatomic,assign) BOOL hasChanged;
@property (nonatomic,copy) NSString *oldName;
@property (nonatomic,strong) NSNumber *originalLevel;
@property (nonatomic,strong) ImproveTouchingExperience *improver;
@property (nonatomic,strong) ControlMaskView *maskLayer;
@property (nonatomic,strong) UIView *translucentBgView;
@property (nonatomic,strong) NSMutableArray *groupLostDevices;
@property (nonatomic,strong) NSMutableArray *groupRemoveDevices;
@property (weak, nonatomic) IBOutlet UIView *pseudoNavView;
@property (weak, nonatomic) IBOutlet TopImageView *topBgImageView;

@end

@implementation GroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange:) name:ZZAppLanguageDidChangeNotification object:nil];
    
    if (@available(iOS 11.0, *)){
    }else {
        [_pseudoNavView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
    }
    
    self.groupNameTF.delegate = self;
    if (self.isCreateNewArea) {
        [self.editItem setTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") forState:UIControlStateNormal];
        [self.groupNameTF becomeFirstResponder];
        self.groupNameTF.backgroundColor = [UIColor whiteColor];
        self.iconEditBtn.hidden = NO;
    }else {
        [self.editItem setTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") forState:UIControlStateNormal];
        self.iconEditBtn.hidden = YES;
        self.groupNameTF.enabled = NO;
        self.groupNameTF.text = _areaEntity.areaName;
        self.groupNameLabel.text = _areaEntity.areaName;
        self.groupIconImageView.contentMode = UIViewContentModeScaleAspectFill;
        if ([_areaEntity.areaIconNum isEqualToNumber:@99]) {
            self.groupIconImageView.alpha = 0.8;
            self.groupIconImageView.image = [UIImage imageWithData:_areaEntity.areaImage];
        }else {
            self.groupIconImageView.alpha = 1;
            NSArray *iconArray = kGroupIcons;
            NSString *imageString = [iconArray objectAtIndex:[_areaEntity.areaIconNum integerValue]];
            self.groupIconImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@room_highlight",imageString]];
        }
        
        iconNum = _areaEntity.areaIconNum;
        iconImage = [UIImage imageWithData:_areaEntity.areaImage];
        
        _oldName = _areaEntity.areaName;
    }
    
    self.improver = [[ImproveTouchingExperience alloc] init];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = WIDTH*8.0/640.0;
    flowLayout.minimumInteritemSpacing = WIDTH*8.0/640.0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, floor(WIDTH*3/160.0));
    flowLayout.itemSize = CGSizeMake(WIDTH*5/16.0, WIDTH*9/32.0);
    
    _devicesCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout cellIdentifier:@"MainCollectionViewCell"];
    _devicesCollectionView.mainDelegate = self;
    if (!self.isCreateNewArea) {
        [self loadMemberData];
    }else{
        [_devicesCollectionView.dataArray addObject:@1];
    }
    
    [self.view addSubview:_devicesCollectionView];
    
    [_devicesCollectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_topBgImageView withOffset:WIDTH*3/160.0];
    [_devicesCollectionView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:WIDTH*3/160.0];
    [_devicesCollectionView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [_devicesCollectionView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    
    if (_isFromEmptyGroup) {
        [self editItemAction:self.editItem];
        DeviceListViewController *list = [[DeviceListViewController alloc] init];
        list.selectMode = DeviceListSelectMode_ForGroup;
        NSMutableArray *mutableArray = [_devicesCollectionView.dataArray mutableCopy];
        [mutableArray removeLastObject];
        list.originalMembers = mutableArray;
        
        [list getSelectedDevices:^(NSArray *devices) {
            self.hasChanged = YES;
            [_devicesCollectionView.dataArray removeAllObjects];
            
            [devices enumerateObjectsUsingBlock:^(NSNumber *deviceId, NSUInteger idx, BOOL * _Nonnull stop) {
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
                SingleDeviceModel *deviceModel = [[SingleDeviceModel alloc] init];
                deviceModel.deviceId = deviceId;
                deviceModel.deviceName = deviceEntity.name;
                deviceModel.deviceShortName = deviceEntity.shortName;
                [_devicesCollectionView.dataArray insertObject:deviceModel atIndex:0];
            }];
            
            [_devicesCollectionView.dataArray addObject:@1];
            [_devicesCollectionView reloadData];
            
        }];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

- (void)loadMemberData {
    [_devicesCollectionView.dataArray removeAllObjects];
    [_areaEntity.devices enumerateObjectsUsingBlock:^(CSRDeviceEntity *device, BOOL * _Nonnull stop) {
        SingleDeviceModel *deviceModel = [[SingleDeviceModel alloc] init];
        deviceModel.deviceId = device.deviceId;
        deviceModel.deviceName = device.name;
        deviceModel.deviceShortName = device.shortName;
        [_devicesCollectionView.dataArray addObject:deviceModel];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

#pragma mark - buttonAction

- (IBAction)backAction:(UIButton *)sender {
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)editItemAction:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:AcTECLocalizedStringFromTable(@"Edit", @"Localizable")]) {
        [sender setTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") forState:UIControlStateNormal];
        self.iconEditBtn.hidden = NO;
        self.groupNameTF.enabled = YES;
        self.groupNameTF.backgroundColor = [UIColor whiteColor];
        [_devicesCollectionView.dataArray addObject:@1];
        [_devicesCollectionView reloadData];
    }
    else {
        [self performSelector:@selector(doneAction) withObject:nil afterDelay:0.01];
    }
    
}

- (void)doneAction {
    if (_groupNameTF.text.length == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:AcTECLocalizedStringFromTable(@"EnerGroupName", @"Localizable") message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }else {
        NSLog(@"分组");
        [self.editItem setTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") forState:UIControlStateNormal];
        self.iconEditBtn.hidden = YES;
        self.groupNameTF.enabled = NO;
        self.groupNameTF.backgroundColor = [UIColor clearColor];
        self.groupNameLabel.text = self.groupNameTF.text;
        [_devicesCollectionView.dataArray removeObject:@1];
        [_devicesCollectionView reloadData];
        
        if (![_groupNameTF.text isEqualToString:_oldName]) {
            self.hasChanged = YES;
        }
        
        NSNumber *areaIdNumber;
        
        if (self.isCreateNewArea) {
            
            areaIdNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRAreaEntity"];
            NSNumber *sortId = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"SortId"];
            [self saveArea:areaIdNumber sortId:sortId];
            self.isCreateNewArea = NO;
        }else if (self.hasChanged) {
            if (!_hud) {
                _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                _hud.mode = MBProgressHUDModeIndeterminate;
                _hud.delegate = self;
            }
            
            areaIdNumber = _areaEntity.areaID;
            NSInteger removeNum = 0;
            [self.groupRemoveDevices removeAllObjects];
            for (CSRDeviceEntity *deviceEntity in _areaEntity.devices) {
                __block BOOL exist=0;
                [_devicesCollectionView.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:[SingleDeviceModel class]]) {
                        SingleDeviceModel *model = (SingleDeviceModel *)obj;
                        
                        if ([model.deviceId isEqual:deviceEntity.deviceId]) {
                            exist = YES;
                            *stop = YES;
                        }
                    }
                }];
                
                if (!exist) {
                    removeNum ++;
                    NSNumber *groupIndex = [self getValueByIndex:deviceEntity];
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
                                                                [self.groupRemoveDevices addObject:deviceEntity];
                                                            }
                                                            failure:^(NSError * _Nullable error) {
                                                                NSLog(@">>>>> mesh timeout");
                                                                
                                                                if (!alertController) {
                                                                    [self.groupLostDevices removeAllObjects];
                                                                    [self.groupLostDevices addObject:deviceEntity];
                                                                    alertController = [UIAlertController alertControllerWithTitle:AcTECLocalizedStringFromTable(@"RemoveGroupMember", @"Localizable")
                                                                                                                          message:[NSString stringWithFormat:@"%@ : %@?", AcTECLocalizedStringFromTable(@"RemoveDeviceOffLine", @"Localizable"),deviceEntity.name]
                                                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                                                                    [alertController.view setTintColor:DARKORAGE];
                                                                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable")
                                                                                                                           style:UIAlertActionStyleCancel
                                                                                                                         handler:^(UIAlertAction *action) {
                                                                                                                             for (CSRDeviceEntity *deviceEntity in self.groupLostDevices) {
                                                                                                                                 SingleDeviceModel *deviceModel = [[SingleDeviceModel alloc] init];
                                                                                                                                 deviceModel.deviceId = deviceEntity.deviceId;
                                                                                                                                 deviceModel.deviceName = deviceEntity.name;
                                                                                                                                 deviceModel.deviceShortName = deviceEntity.shortName;
                                                                                                                                 [_devicesCollectionView.dataArray insertObject:deviceModel atIndex:0];
                                                                                                                                 [_devicesCollectionView reloadData];
                                                                                                                             }
                                                                                                                             if (_hud) {
                                                                                                                                 [_hud hideAnimated:YES];
                                                                                                                                 _hud = nil;
                                                                                                                             }
                                                                                                                         }];
                                                                    
                                                                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable")
                                                                                                                       style:UIAlertActionStyleDefault
                                                                                                                     handler:^(UIAlertAction *action) {
                                                                                                                         
                                                                                                                         for (CSRDeviceEntity *deviceEntity in self.groupLostDevices) {
                                                                                                                             [_areaEntity removeDevicesObject:deviceEntity];
                                                                                                                         }
                                                                                                                         
                                                                                                                         [[CSRDatabaseManager sharedInstance] saveContext];
                                                                                                                         
                                                                                                                         if (self.handle) {
                                                                                                                             self.handle();
                                                                                                                         }
                                                                                                                         
                                                                                                                         if (_hud) {
                                                                                                                             [_hud hideAnimated:YES];
                                                                                                                             _hud = nil;
                                                                                                                         }
                                                                                                                         
                                                                                                                     }];
                                                                    [alertController addAction:okAction];
                                                                    [alertController addAction:cancelAction];
                                                                    
                                                                    [self presentViewController:alertController animated:YES completion:nil];
                                                                }else {
                                                                    [self.groupLostDevices addObject:deviceEntity];
                                                                    NSString *string= nil;
                                                                    for (CSRDeviceEntity *deviceEntity in self.groupLostDevices) {
                                                                        if (!string) {
                                                                            string = deviceEntity.name;
                                                                        }else {
                                                                            string = [NSString stringWithFormat:@"%@ and %@",string,deviceEntity.name];
                                                                        }
                                                                        
                                                                    }
                                                                    alertController.message = [NSString stringWithFormat:@"%@ : %@?", AcTECLocalizedStringFromTable(@"RemoveDeviceOffLine", @"Localizable"), string];
                                                                }
                                                            }];
                    [NSThread sleepForTimeInterval:0.3];
                }
                
                
                
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * ([_areaEntity.devices count]) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self saveArea:areaIdNumber sortId:_areaEntity.sortId];
                if (_hud && ((removeNum>0 && removeNum == [self.groupRemoveDevices count]) || removeNum==0)) {
                    [_hud hideAnimated:YES];
                    _hud = nil;
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (_hud) {
                        [_hud hideAnimated:YES];
                        _hud = nil;
                    }
                });
            });
            
            
            
        }
        
    }
}

- (void)saveArea:(NSNumber *)areaIdNumber sortId:(NSNumber *)sortId{
    
    _areaEntity = [[CSRDatabaseManager sharedInstance] saveNewArea:areaIdNumber areaName:_groupNameTF.text areaImage:iconImage areaIconNum:iconNum sortId:sortId];
    
    for (id obj in _devicesCollectionView.dataArray) {
        if ([obj isKindOfClass:[SingleDeviceModel class]]) {
            SingleDeviceModel *model = (SingleDeviceModel *)obj;
            __block BOOL exist=0;
            [_areaEntity.devices enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, BOOL * _Nonnull stop) {
                if ([deviceEntity.deviceId isEqualToNumber:model.deviceId]) {
                    exist = YES;
                    *stop = YES;
                }
            }];
            if (!exist) {
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:model.deviceId];
                NSNumber *groupIndex = [self getValueByIndex:deviceEntity];
                if (![groupIndex isEqual:@(-1)]) {
                    [[GroupModelApi sharedInstance] setModelGroupId:deviceEntity.deviceId
                                                            modelNo:@(0xff)
                                                         groupIndex:groupIndex
                                                           instance:@(0)
                                                            groupId:_areaEntity.areaID
                                                            success:^(NSNumber * _Nullable deviceId,
                                                                      NSNumber * _Nullable modelNo,
                                                                      NSNumber * _Nullable groupIndex,
                                                                      NSNumber * _Nullable instance,
                                                                      NSNumber * _Nullable groupId) {
                                                                NSMutableData *myData = (NSMutableData*)[CSRUtilities dataForHexString:deviceEntity.groups];
                                                                uint16_t desiredValue = [groupId unsignedShortValue];
                                                                int groupIndexInt = [groupIndex intValue];
                                                                if (groupIndexInt>-1) {
                                                                    uint16_t *groups = (uint16_t *) myData.mutableBytes;
                                                                    *(groups + groupIndexInt) = desiredValue;
                                                                }
                                                                
                                                                deviceEntity.groups = [CSRUtilities hexStringFromData:(NSData*)myData];
                                                                CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId: groupId];
                                                                
                                                                if (areaEntity) {
                                                                    //NSLog(@"deviceEntity2 :%@", deviceEntity);
                                                                    [_areaEntity addDevicesObject:deviceEntity];
                                                                }
                                                                [[CSRDatabaseManager sharedInstance] saveContext];
                                                            }
                                                            failure:^(NSError * _Nullable error) {
                                                                NSLog(@"mesh timeout");
                                                            }];
                    [NSThread sleepForTimeInterval:0.3];
                }
            }
        }
        
    }
    
    if (self.handle) {
        self.handle();
    }
}


//method to getIndexByValue
- (NSNumber *) getValueByIndex:(CSRDeviceEntity*)deviceEntity
{
    NSData *groups = [CSRUtilities dataForHexString:deviceEntity.groups];
    uint16_t *dataToModify = (uint16_t*)groups.bytes;
//    uint16_t *dataToModify = (uint16_t*)deviceEntity.groups.bytes;
    
    for (int count=0; count < deviceEntity.groups.length/2; count++, dataToModify++) {
        if (*dataToModify == [_areaEntity.areaID unsignedShortValue]) {
            return @(count);
            
        } else if (*dataToModify == 0){
            return @(count);
        }
    }
    
    return @(-1);
}

- (IBAction)iconEditAction:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert.view setTintColor:DARKORAGE];
    
    UIAlertAction *icon = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"SelectDefaultIcon", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if (!pickerView) {
            pickerView = [[PlaceColorIconPickerView alloc] initWithFrame:CGRectMake((WIDTH-270)/2, (HEIGHT-190)/2, 277, 190) withMode:CollectionViewPickerMode_GroupIconPicker];
            pickerView.delegate = self;
            [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
            [[UIApplication sharedApplication].keyWindow addSubview:pickerView];
            [pickerView autoCenterInSuperview];
            [pickerView autoSetDimensionsToSize:CGSizeMake(270, 190)];
        }
        
    }];
    __weak GroupViewController *weakSelf = self;
    UIAlertAction *camera = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Camera", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [weakSelf alertAction:0];
        
    }];
    UIAlertAction *album = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ChooseFromAlbum", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [weakSelf alertAction:1];
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:icon];
    [alert addAction:camera];
    [alert addAction:album];
    [alert addAction:cancel];
    
    alert.popoverPresentationController.sourceView = sender;
    alert.popoverPresentationController.sourceRect = sender.bounds;
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)alertAction:(NSInteger)tag {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePickerController.delegate = self;
        imagePickerController.allowsEditing = YES;
        if (tag == 0) {
            imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }
        if (tag == 1) {
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }
    }else {
        imagePickerController.delegate = self;
        imagePickerController.allowsEditing = YES;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

#pragma mark - MainCollectionViewDelegate

- (void)mainCollectionViewTapCellAction:(NSNumber *)cellDeviceId cellIndexPath:(NSIndexPath *)indexPath {
    if ([cellDeviceId isEqualToNumber:@4000]) {
        DeviceListViewController *list = [[DeviceListViewController alloc] init];
        list.selectMode = DeviceListSelectMode_ForGroup;
        
        NSMutableArray *mutableArray = [_devicesCollectionView.dataArray mutableCopy];
        [mutableArray removeLastObject];
        list.originalMembers = mutableArray;
        
        [list getSelectedDevices:^(NSArray *devices) {
            self.hasChanged = YES;
            [_devicesCollectionView.dataArray removeAllObjects];
            
            [devices enumerateObjectsUsingBlock:^(NSNumber *deviceId, NSUInteger idx, BOOL * _Nonnull stop) {
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
                SingleDeviceModel *deviceModel = [[SingleDeviceModel alloc] init];
                deviceModel.deviceId = deviceId;
                deviceModel.deviceName = deviceEntity.name;
                deviceModel.deviceShortName = deviceEntity.shortName;
                [_devicesCollectionView.dataArray insertObject:deviceModel atIndex:0];
            }];
            
            [_devicesCollectionView.dataArray addObject:@1];
            [_devicesCollectionView reloadData];
            
        }];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

- (void)mainCollectionViewDelegatePanBrightnessWithTouchPoint:(CGPoint)touchPoint withOrigin:(CGPoint)origin toLight:(NSNumber *)deviceId groupId:(NSNumber *)groupId withPanState:(UIGestureRecognizerState)state direction:(PanGestureMoveDirection)direction{
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

- (void)mainCollectionViewDelegateLongPressAction:(id)cell {
    MainCollectionViewCell *mainCell = (MainCollectionViewCell *)cell;
    if ([mainCell.groupId isEqualToNumber:@2000]) {
        
        DeviceViewController *dvc = [[DeviceViewController alloc] init];
        dvc.deviceId = mainCell.deviceId;
        __weak GroupViewController *weakSelf = self;
        dvc.reloadDataHandle = ^{
            [weakSelf loadMemberData];
            [_devicesCollectionView reloadData];
        };
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:dvc];
        nav.modalPresentationStyle = UIModalPresentationPopover;
        nav.popoverPresentationController.sourceRect = mainCell.bounds;
        nav.popoverPresentationController.sourceView = mainCell;

        [self presentViewController:nav animated:YES completion:nil];

    }
}

#pragma mark - <UIImagePickerControllerDelegate>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.hasChanged = YES;
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.groupIconImageView.image = [CSRUtilities fixOrientation:image];
    self.groupIconImageView.alpha = 0.8;
    iconNum = @99;
    iconImage = image;
}

#pragma mark - PlaceColorIconPickerViewDelegate

- (id)selectedItem:(id)item {
    NSString *imageString = (NSString *)item;
    
    self.hasChanged = YES;
    self.groupIconImageView.alpha = 1;
    self.groupIconImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@room_highlight",imageString]];
    NSArray *iconArray = kGroupIcons;
    [iconArray enumerateObjectsUsingBlock:^(NSString *iconString, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([iconString isEqualToString:imageString]) {
            iconNum = @(idx);
            iconImage = nil;
            *stop = YES;
        }
    }];
    
    return nil;
}

- (void)cancel:(UIButton *)sender {
    if (pickerView) {
        [pickerView removeFromSuperview];
        pickerView = nil;
        [self.translucentBgView removeFromSuperview];
    }
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    self.groupNameLabel.text = self.groupNameTF.text;
    return NO;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
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

- (NSMutableArray *)groupLostDevices {
    if (!_groupLostDevices) {
        _groupLostDevices = [NSMutableArray new];
    }
    return _groupLostDevices;
}

- (NSMutableArray *)groupRemoveDevices {
    if (!_groupRemoveDevices) {
        _groupRemoveDevices = [NSMutableArray new];
    }
    return _groupRemoveDevices;
}

- (void)languageChange:(id)sender {
    if (self.isViewLoaded && !self.view.window) {
        self.view = nil;
    }
}

@end
