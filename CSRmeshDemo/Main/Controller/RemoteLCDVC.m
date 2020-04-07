//
//  RemoteLCDVC.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/1/2.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "RemoteLCDVC.h"
#import "CSRDatabaseManager.h"
#import "LCDRemoteMemberCell.h"
#import "LCDSelectModel.h"
#import "DeviceListViewController.h"
#import "CSRUtilities.h"
#import <AVFoundation/AVFoundation.h>
#import "DataModelManager.h"
#import <MBProgressHUD.h>

@interface RemoteLCDVC ()<UITextFieldDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UINavigationControllerDelegate,UIImagePickerControllerDelegate,LCDRemoteMemberCellDelgate>

@property (weak, nonatomic) IBOutlet UIImageView *wallpaper;
@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (nonatomic, copy) NSString *originalName;
@property (weak, nonatomic) IBOutlet UICollectionView *memberList;
@property (nonatomic, strong) NSMutableArray *dataAry;

@end

@implementation RemoteLCDVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        if (@available(iOS 13.0, *)) {
            
        }else {
            UIButton *btn = [[UIButton alloc] init];
            [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
            [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
            [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
            UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
            self.navigationItem.leftBarButtonItem = back;
        }
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(wallpaperTapAction:)];
    [_wallpaper addGestureRecognizer:tap];
    
    _memberList.dataSource = self;
    _memberList.delegate = self;
    [_memberList registerNib:[UINib nibWithNibName:@"LCDRemoteMemberCell" bundle:nil] forCellWithReuseIdentifier:@"lcdcell"];
    
    if (_deviceId) {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        self.navigationItem.title = deviceEntity.name;
        self.nameTf.delegate = self;
        self.nameTf.text = deviceEntity.name;
        self.originalName = deviceEntity.name;
        
        _dataAry = [[NSMutableArray alloc] init];
        [_dataAry addObject:@0];
        if ([deviceEntity.remoteBranch length]>=14) {
            NSInteger num = [deviceEntity.remoteBranch length]/12;
            for (int i=0; i<num; i++) {
                NSString *str = [deviceEntity.remoteBranch substringWithRange:NSMakeRange(14*i, 14)];
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @([CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]]);
                mod.channel = @([self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(4, 4)]]);
                mod.deviceID = @([self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(8, 4)]]);
                LCDSelectModel *lMod = [self configLCDSelectModelFromSelectModel:mod];
                [_dataAry insertObject:lMod atIndex:i];
            }
            [_memberList reloadData];
        }
    }
    
    
    
}


- (NSInteger)exchangePositionOfDeviceIdString:(NSString *)deviceIdString {
    NSString *str11 = [deviceIdString substringToIndex:2];
    NSString *str22 = [deviceIdString substringFromIndex:2];
    NSString *deviceIdStr = [NSString stringWithFormat:@"%@%@",str22,str11];
    NSInteger deviceIdInt = [CSRUtilities numberWithHexString:deviceIdStr];
    return deviceIdInt;
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    textField.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    textField.backgroundColor = [UIColor whiteColor];
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self saveNickName];
}

- (void)saveNickName {
    if (![_nameTf.text isEqualToString:_originalName] && _nameTf.text.length > 0) {
        self.navigationItem.title = _nameTf.text;
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:self.deviceId];
        deviceEntity.name = _nameTf.text;
        [[CSRDatabaseManager sharedInstance] saveContext];
        _originalName = _nameTf.text;
        if (self.reloadDataHandle) {
            self.reloadDataHandle();
        }
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_dataAry count];
}

-(LCDRemoteMemberCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LCDRemoteMemberCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"lcdcell" forIndexPath:indexPath];
    if (cell) {
        cell.cellDelgate = self;
        [cell configureCellWithInfo:_dataAry[indexPath.row] indexPath:indexPath];
    }
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat parentWidth = self.view.bounds.size.width;
    CGSize size = CGSizeMake(54.0*parentWidth/320.0, 100.0*parentWidth/320.0);
    return size;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat parentWidth = self.view.bounds.size.width;
    UIEdgeInsets insets = UIEdgeInsetsMake(13.0*parentWidth/320.0, floorf(13.0*parentWidth/320.0), 13.0*parentWidth/320.0,floorf(13.0*parentWidth/320.0));;
    return insets;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    CGFloat parentWidth = self.view.bounds.size.width;
    return floorf(6.0*parentWidth/320.0);
}

-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    CGFloat parentWidth = self.view.bounds.size.width;
    return floorf(6.0*parentWidth/320.0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id item = [_dataAry objectAtIndex:indexPath.row];
    if ([item isKindOfClass:[NSNumber class]]) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *lamp = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [self selectMember:DeviceListSelectMode_Single];
            
        }];
        UIAlertAction *group = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [self selectMember:DeviceListSelectMode_SelectGroup];
            
        }];
        UIAlertAction *scene = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [self selectMember:DeviceListSelectMode_SelectScene];
            
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:lamp];
        [alert addAction:group];
        [alert addAction:scene];
        [alert addAction:cancel];
        
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        alert.popoverPresentationController.sourceRect = cell.bounds;
        alert.popoverPresentationController.sourceView = cell;
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }else if ([item isKindOfClass:[LCDSelectModel class]]) {
        
    }
}

- (void)LCDRemoteMemberCellLongPressItemAtIndexPath:(NSIndexPath *)indexPath {
    id item = [_dataAry objectAtIndex:indexPath.row];
    if ([item isKindOfClass:[LCDSelectModel class]]) {
        [_dataAry removeObjectAtIndex:indexPath.row];
        [_memberList reloadData];
        
        LCDSelectModel *lMod = (LCDSelectModel *)item;
        
        [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"b6020e%@",[CSRUtilities stringWithHexNumber:[lMod.sourceID integerValue]]] toDeviceId:_deviceId];
        
        NSString *infoStr = [NSString stringWithFormat:@"%@%@%@%@%@",[CSRUtilities stringWithHexNumber:[lMod.sourceID integerValue]],[CSRUtilities stringWithHexNumber:[lMod.typeID integerValue]],[CSRUtilities exchangePositionOfDeviceId:[lMod.channel integerValue]],[CSRUtilities exchangePositionOfDeviceId:[lMod.deviceID integerValue]],[CSRUtilities stringWithHexNumber:[lMod.iconID integerValue]]];
        
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        if ([deviceEntity.remoteBranch containsString:infoStr]) {
            NSMutableString *s = [NSMutableString stringWithString:deviceEntity.remoteBranch];
            NSRange r = [s rangeOfString:infoStr];
            [s deleteCharactersInRange:r];
            deviceEntity.remoteBranch = s;
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
    }
}

- (void)selectMember:(DeviceListSelectMode)selectMode {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = selectMode;
    list.sourceID = [self findNextSourceID];
    
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count] > 0) {
            SelectModel *mod = devices[0];
            LCDSelectModel *lMod = [self configLCDSelectModelFromSelectModel:mod];
            [_dataAry insertObject:lMod atIndex:[_dataAry count]-1];
            [_memberList reloadData];
            
            
            NSString *infoStr = [NSString stringWithFormat:@"%@%@%@%@%@",[CSRUtilities stringWithHexNumber:[lMod.sourceID integerValue]],[CSRUtilities stringWithHexNumber:[lMod.typeID integerValue]],[CSRUtilities exchangePositionOfDeviceId:[lMod.channel integerValue]],[CSRUtilities exchangePositionOfDeviceId:[lMod.deviceID integerValue]],[CSRUtilities stringWithHexNumber:[lMod.iconID integerValue]]];
            [[DataModelManager shareInstance] sendCmdData:[NSString stringWithFormat:@"b6070c%@",infoStr] toDeviceId:_deviceId];
            
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
            NSString *a = [deviceEntity.remoteBranch length]>0? deviceEntity.remoteBranch:@"";
            deviceEntity.remoteBranch = [NSString stringWithFormat:@"%@%@",a,infoStr];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    [self presentViewController:nav animated:YES completion:nil];
    
}

- (NSNumber *)findNextSourceID {
    NSInteger nextSourceID = 0;
    NSMutableArray *mutableAry = [_dataAry mutableCopy];
    if ([mutableAry count]>1) {
        [mutableAry removeLastObject];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sourceID" ascending:YES];
        [mutableAry sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        for (int i=0; i<[mutableAry count]; i++) {
            SelectModel *mod = mutableAry[i];
            NSInteger source = [mod.sourceID integerValue];
            NSInteger preSource;
            if (i==0) {
                preSource = -1;
            }else {
                SelectModel *preMod = mutableAry[i-1];
                preSource = [preMod.sourceID integerValue];
            }
            if (source-preSource>1) {
                nextSourceID = preSource+1;
                break;
            }
            if (i == [mutableAry count]-1) {
                nextSourceID = source+1;
            }
        }
    }
    return @(nextSourceID);
}

- (LCDSelectModel *)configLCDSelectModelFromSelectModel:(SelectModel *)mod {
    LCDSelectModel *lMod = [[LCDSelectModel alloc] init];
    lMod.sourceID = mod.sourceID;
    lMod.channel = mod.channel;
    lMod.deviceID = mod.deviceID;
    NSInteger channelInt = [mod.channel integerValue];
    if (channelInt >= 1 && channelInt <= 9) {
        CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:mod.deviceID];
        if (device) {
            lMod.name = device.name;
            if ([CSRUtilities belongToDimmer:device.shortName]) {
                lMod.typeID = @(2);
                if ([device.shortName isEqualToString:@"SD350"]||[device.shortName isEqualToString:@"SSD150"]) {
                    lMod.iconID = @(3);
                }else {
                    lMod.iconID = @(1);
                }
            }else if ([CSRUtilities belongToTwoChannelDimmer:device.shortName]) {
                lMod.typeID = @(2);
                lMod.iconID = @(2);
            }else if ([CSRUtilities belongToSwitch:device.shortName]) {
                lMod.typeID = @(1);
                lMod.iconID = @(1);
            }else if ([CSRUtilities belongToTwoChannelSwitch:device.shortName]) {
                lMod.typeID = @(1);
                lMod.iconID = @(2);
            }else if ([CSRUtilities belongToOneChannelCurtainController:device.shortName]) {
                lMod.typeID = @(4);
                if ([device.remoteBranch isEqualToString:@"cv"]) {
                    lMod.iconID = @(2);
                }else {
                    lMod.iconID = @(1);
                }
            }else if ([CSRUtilities belongToTwoChannelCurtainController:device.shortName]) {
                lMod.typeID = @(4);
                if ([device.remoteBranch isEqualToString:@"cvv"]) {
                    lMod.iconID = @(4);
                }else {
                    lMod.iconID = @(3);
                }
            }else if ([CSRUtilities belongToRGBDevice:device.shortName]) {
                lMod.typeID = @(16);
                lMod.iconID = @(1);
            }else if ([CSRUtilities belongToCWDevice:device.shortName]) {
                lMod.typeID = @(17);
                lMod.iconID = @(1);
            }else if ([CSRUtilities belongToRGBCWDevice:device.shortName]) {
                lMod.typeID = @(7);
                lMod.iconID = @(1);
            }else if ([CSRUtilities belongToFanController:device.shortName]) {
                lMod.typeID = @(8);
                lMod.iconID = @(1);
            }else if ([CSRUtilities belongToSocketTwoChannel:device.shortName]) {
                lMod.typeID = @(10);
                lMod.iconID = @(1);
            }else if ([CSRUtilities belongToSocketOneChannel:device.shortName]) {
                lMod.typeID = @(10);
                lMod.iconID = @(2);
            }
        }
    }else if (channelInt >= 32 && channelInt <= 35) {
        CSRAreaEntity *area = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:mod.deviceID];
        if (area) {
            lMod.name = area.areaName;
            lMod.typeID = @(129);
            lMod.iconID = @([area.areaIconNum intValue]+1);
        }
    }else if (channelInt >= 64 && channelInt <= 65535) {
        SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithRcIndexId:mod.channel];
        if (scene) {
            lMod.name = scene.sceneName;
            lMod.typeID = @(130);
            lMod.iconID = @([scene.iconID integerValue]+1);
        }
    }
    return lMod;
}

- (void)wallpaperTapAction:(UITapGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (device) {
            AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            switch (status) {
                case AVAuthorizationStatusNotDetermined:
                {
                    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                        if (granted) {
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                [self presentSheetAlert];
                            });
                            NSLog(@"用户第一次同意了访问相机权限 - - %@", [NSThread currentThread]);
                        } else {
                            NSLog(@"用户第一次拒绝了访问相机权限 - - %@", [NSThread currentThread]);
                        }
                    }];
                    break;
                }
                case AVAuthorizationStatusAuthorized:
                {
                    [self presentSheetAlert];
                    break;
                }
                case AVAuthorizationStatusDenied:
                {
                    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"openCamera", @"Localizable") preferredStyle:(UIAlertControllerStyleAlert)];
                    [alertC.view setTintColor:DARKORAGE];
                    UIAlertAction *alertA = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                        
                    }];
                    
                    [alertC addAction:alertA];
                    [self presentViewController:alertC animated:YES completion:nil];
                    break;
                }
                case AVAuthorizationStatusRestricted:
                    NSLog(@"因为系统原因, 无法访问相册");
                    break;
                default:
                    break;
            }
        }
    }
}

- (void)presentSheetAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Set Wallpaper" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert.view setTintColor:DARKORAGE];
    UIAlertAction *camera = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Camera", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self alertAction:0];
        
    }];
    UIAlertAction *album = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ChooseFromAlbum", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self alertAction:1];
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:camera];
    [alert addAction:album];
    [alert addAction:cancel];
    
    alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    _wallpaper.image = [info objectForKey:UIImagePickerControllerOriginalImage];
}


@end
