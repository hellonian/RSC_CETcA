//
//  RemoteLCDVC.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/1/2.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
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
#import <CSRmesh/DataModelApi.h>
#import <CoreLocation/CLLocationManager.h>
#import "GCDAsyncSocket.h"

@interface RemoteLCDVC ()<UITextFieldDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UINavigationControllerDelegate,UIImagePickerControllerDelegate,LCDRemoteMemberCellDelgate,CLLocationManagerDelegate,GCDAsyncSocketDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *wallpaper;
@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (nonatomic, copy) NSString *originalName;
@property (weak, nonatomic) IBOutlet UICollectionView *memberList;
@property (nonatomic, strong) NSMutableArray *dataAry;
@property (nonatomic, strong) NSString *applyName;
@property (nonatomic, assign) NSInteger applySourceID;
@property (nonatomic, assign) NSInteger applyIndex;
@property (nonatomic, strong) NSData *applyData;
@property (nonatomic, strong) NSString *wifiPassword;
@property (nonatomic, strong) NSString *IPAdress;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, strong) GCDAsyncSocket *tcpSocketManager;
@property (weak, nonatomic) IBOutlet UIButton *uConfigBtn;
@property (weak, nonatomic) IBOutlet UIButton *uIconBtn;
@property (weak, nonatomic) IBOutlet UIButton *uWallBtn;
@property (nonatomic, assign) NSInteger applyCmdType;

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
    
    UIButton *wifiBtn = [[UIButton alloc] init];
    [wifiBtn setTitle:@"WIFI" forState:UIControlStateNormal];
    [wifiBtn setTitleColor:DARKORAGE forState:UIControlStateNormal];
    [wifiBtn addTarget:self action:@selector(wifiAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithCustomView:wifiBtn];
    self.navigationItem.rightBarButtonItem = right;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(LCDRemoteAddCall:)
                                                 name:@"LCDRemoteAddCall"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(LCDRemoteNameCall:)
                                                 name:@"LCDRemoteNameCall"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(LCDRemoteSSIDCall:)
                                                 name:@"LCDRemoteSSIDCall"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(LCDRemoteIPAdressCall:)
                                                 name:@"LCDRemoteIPAdressCall"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(LCDRemotePortCall:)
                                                 name:@"LCDRemotePortCall"
                                               object:nil];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(wallpaperTapAction:)];
    [_wallpaper addGestureRecognizer:tap];
    
    _memberList.dataSource = self;
    _memberList.delegate = self;
    [_memberList registerNib:[UINib nibWithNibName:@"LCDRemoteMemberCell" bundle:nil] forCellWithReuseIdentifier:@"lcdcell"];
    
//    UIPanGestureRecognizer *movePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(movePanGestureAction:)];
//    [_memberList addGestureRecognizer:movePanGesture];
    
    if (_deviceId) {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        self.navigationItem.title = deviceEntity.name;
        self.nameTf.delegate = self;
        self.nameTf.text = deviceEntity.name;
        self.originalName = deviceEntity.name;
        
        _dataAry = [[NSMutableArray alloc] init];
        [_dataAry addObject:@0];
        if ([deviceEntity.remoteBranch length] >= 14) {
            NSInteger num = [deviceEntity.remoteBranch length]/14;
            for (int i=0; i<num; i++) {
                NSString *str = [deviceEntity.remoteBranch substringWithRange:NSMakeRange(14*i, 14)];
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @([CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]]);
                mod.channel = @([self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(4, 4)]]);
                mod.deviceID = @([self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(8, 4)]]);
                LCDSelectModel *lMod = [self configLCDSelectModelFromSelectModel:mod];
                lMod.sortID = @(i+1);
                [_dataAry insertObject:lMod atIndex:i];
            }
            [_memberList reloadData];
        }
        
        if ([deviceEntity.wallPaper length]>0) {
            _wallpaper.image = [UIImage imageWithData:deviceEntity.wallPaper];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(LCDRemoteKeyIndexCall:)
                                                     name:@"LCDRemoteKeyIndexCall"
                                                   object:nil];
        
        Byte byte[3] = {0xea, 0x7f, 0x00};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:3];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
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
            
            [self selectMember:DeviceListSelectMode_SingleRegardlessChannel];
            
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
            lMod.sortID = @([_dataAry count]);
            [_dataAry insertObject:lMod atIndex:[_dataAry count]-1];
            [_memberList reloadData];
            NSInteger s = [lMod.sourceID integerValue];
            NSInteger t = [lMod.typeID integerValue];
            NSInteger r = [lMod.channel integerValue];
            NSInteger r1 = (r & 0xFF00) >> 8;
            NSInteger r0 = r & 0x00FF;
            NSInteger a = [lMod.deviceID integerValue];
            NSInteger a1 = (a & 0xFF00) >> 8;
            NSInteger a0 = a & 0x00FF;
            NSInteger i = [lMod.iconID integerValue];
            Byte byte[] = {0xb6, 0x08, 0x0c, s, t, r0, r1, a0, a1, i};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:10];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            
            CSRDeviceEntity *device = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
            NSString *rb = [device.remoteBranch length]>0? device.remoteBranch:@"";
            device.remoteBranch = [NSString stringWithFormat:@"%@%@",rb,[CSRUtilities hexStringForData:[cmd subdataWithRange:NSMakeRange(3, 7)]]];
            [[CSRDatabaseManager sharedInstance] saveContext];
            
            if ([mod.deviceID integerValue] < 32768) {
                CSRAreaEntity *a = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:mod.deviceID];
                _applyName = a.areaName;
            }else {
                CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:mod.deviceID];
                _applyName = d.name;
            }
            _applySourceID = [lMod.sourceID intValue];
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    [self presentViewController:nav animated:YES completion:nil];
    
}

- (NSNumber *)findNextSourceID {
    NSInteger nextSourceID = 1;
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
                preSource = 0;
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
            }else if ([CSRUtilities belongToThreeChannelSwitch:device.shortName]) {
                lMod.typeID = @(1);
                lMod.iconID = @(3);
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
    UIImage *img = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imgData = UIImagePNGRepresentation(img);
    CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    d.wallPaper = imgData;
    [[CSRDatabaseManager sharedInstance] saveContext];
}

- (void)LCDRemoteAddCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSInteger sourceID = [CSRUtilities numberWithHexString:userInfo[@"sourceID"]];
    if ([deviceId isEqualToNumber:_deviceId] && sourceID == _applySourceID) {
        BOOL state = [userInfo[@"state"] boolValue];
        if (state) {
            NSData *nameData = [_applyName dataUsingEncoding:NSUTF8StringEncoding];
            NSInteger packet = nameData.length / 5 + 1;
            if (nameData.length % 5 == 0) {
                packet = nameData.length / 5;
            }
            if (nameData.length >= 5) {
                _applyIndex = 1;
                NSData *data_0 = [nameData subdataWithRange:NSMakeRange(0, 5)];
                Byte byte[] = {0xea, 0x7d, sourceID, packet, 0x01};
                NSData *head = [[NSData alloc] initWithBytes:byte length:5];
                NSMutableData *cmd = [[NSMutableData alloc] init];
                [cmd appendData:head];
                [cmd appendData:data_0];
                [[DataModelApi sharedInstance] sendData:_deviceId data:cmd success:nil failure:nil];
            }
        }
    }
}

- (void)LCDRemoteNameCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSInteger sourceID = [CSRUtilities numberWithHexString:userInfo[@"sourceID"]];
    NSInteger index = [CSRUtilities numberWithHexString:userInfo[@"index"]];
    if ([deviceId isEqualToNumber:_deviceId] && sourceID == _applySourceID && index == _applyIndex) {
        NSData *nameData = [_applyName dataUsingEncoding:NSUTF8StringEncoding];
        NSInteger packet = nameData.length / 5 + 1;
        if (nameData.length % 5 == 0) {
            packet = nameData.length / 5;
        }
        
        if (index == packet) {
            
        }else if (index == (packet -1)) {
            _applyIndex = index + 1;
            NSData *data_0 = [nameData subdataWithRange:NSMakeRange(5*index, nameData.length-5*index)];
            Byte byte[] = {0xea, 0x7d, sourceID, packet, _applyIndex};
            NSData *head = [[NSData alloc] initWithBytes:byte length:5];
            NSMutableData *cmd = [[NSMutableData alloc] init];
            [cmd appendData:head];
            [cmd appendData:data_0];
            [[DataModelApi sharedInstance] sendData:_deviceId data:cmd success:nil failure:nil];
        }else {
            _applyIndex = index + 1;
            NSData *data_0 = [nameData subdataWithRange:NSMakeRange(5*index, 5)];
            Byte byte[] = {0xea, 0x7d, sourceID, packet, _applyIndex};
            NSData *head = [[NSData alloc] initWithBytes:byte length:5];
            NSMutableData *cmd = [[NSMutableData alloc] init];
            [cmd appendData:head];
            [cmd appendData:data_0];
            [[DataModelApi sharedInstance] sendData:_deviceId data:cmd success:nil failure:nil];
        }
    }
}

- (void)LCDRemoteMemberCellMoveItem:(UIPanGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            NSIndexPath *indexPath = [_memberList indexPathForItemAtPoint:[gesture locationInView:_memberList]];
            if (indexPath == nil) {
                break;
            }
            
            if (indexPath.row == _dataAry.count - 1) {
                break;
            }
            
            [_memberList beginInteractiveMovementForItemAtIndexPath:indexPath];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            [_memberList updateInteractiveMovementTargetPosition:[gesture locationInView:_memberList]];
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            NSIndexPath *indexPath = [_memberList indexPathForItemAtPoint:[gesture locationInView:_memberList]];
            if (indexPath.row == _dataAry.count - 1) {
               [_memberList cancelInteractiveMovement];
            }else {
                [_memberList endInteractiveMovement];
            }
        }
            break;
        default:
            [_memberList cancelInteractiveMovement];
            break;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < [_dataAry count]-1) {
        return YES;
    }
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    
    Byte byte[] = {0xea, 0x7e, sourceIndexPath.row + 1, destinationIndexPath.row + 1};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:4];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    
    id obj = [_dataAry objectAtIndex:sourceIndexPath.row];
    [_dataAry removeObjectAtIndex:sourceIndexPath.row];
    [_dataAry insertObject:obj atIndex:destinationIndexPath.row];
    
    [_dataAry removeObject:@0];
    for (int i = 0; i < [_dataAry count]; i ++) {
        LCDSelectModel *m = [_dataAry objectAtIndex:i];
        m.sortID = @(i+1);
    }
    
    [self reorderStoreData];
    [_dataAry addObject:@0];
}

- (void)LCDRemoteKeyIndexCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        NSData *data = userInfo[@"keyIndex"];
        Byte *bytes = (Byte *)[data bytes];
        NSInteger offset = bytes[0];
        [_dataAry removeObject:@0];
        if ([_dataAry count] > 0) {
            for (int i=0; i<[data length]-1; i++) {
                NSInteger sourceID = bytes[i+1];
                for (LCDSelectModel *m in _dataAry) {
                    if ([m.sourceID integerValue] == sourceID) {
                        m.sortID = @(offset+i);
                        break;
                    }
                }
            }
            
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortID" ascending:YES];
            [_dataAry sortUsingDescriptors:[NSArray arrayWithObject:sort]];
            [_memberList reloadData];
            
            [self reorderStoreData];
        }
        [_dataAry addObject:@0];
    }
}

- (void)reorderStoreData {
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    NSMutableArray *a = [[NSMutableArray alloc] init];
    for (int i=0; i<[deviceEntity.remoteBranch length]/14; i++) {
        NSString *s = [deviceEntity.remoteBranch substringWithRange:NSMakeRange(14*i, 14)];
        [a addObject:s];
    }
    
    NSString *n = @"";
    for (NSObject *obj in _dataAry) {
        if ([obj isKindOfClass:[LCDSelectModel class]]) {
            LCDSelectModel *m = (LCDSelectModel *)obj;
            for (NSString *t in a) {
                NSInteger souceid = [CSRUtilities numberWithHexString:[t substringWithRange:NSMakeRange(0, 2)]];
                if (souceid == [m.sourceID integerValue]) {
                    n = [NSString stringWithFormat:@"%@%@",n,t];
                }
            }
        }
    }
    deviceEntity.remoteBranch = n;
    [[CSRDatabaseManager sharedInstance] saveContext];
}

- (void)wifiAction {
    if (@available(iOS 13.0, *)) {
        [self getcurrentLocation];
    }else {
        [self getWifiInfo];
    }
}

- (void)getcurrentLocation {
    if (@available(iOS 13.0, *)) {
        //用户明确拒绝，可以弹窗提示用户到设置中手动打开权限
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            //使用下面接口可以打开当前应用的设置页面
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
        
        CLLocationManager *locManager = [[CLLocationManager alloc] init];
        locManager.delegate = self;
        if(![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            //弹框提示用户是否开启位置权限
            [locManager requestWhenInUseAuthorization];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self getWifiInfo];
}

- (void)getWifiInfo {
    NSString *name = [CSRUtilities getWifiName];
    if (name) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:AcTECLocalizedStringFromTable(@"set_lcdremote_wifi", @"Localizable") message:name preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
        
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"send", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UITextField *textField = alert.textFields.firstObject;
            
            [self sendWifiName:name wifiPassword:textField.text];
            
        }];
        [alert addAction:cancel];
        [alert addAction:confirm];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = AcTECLocalizedStringFromTable(@"enter_wifi_password", @"Localizable");
        }];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)sendWifiName:(NSString *)name wifiPassword:(NSString *)password {
    _wifiPassword = password;
    _applyData = [name dataUsingEncoding:NSUTF8StringEncoding];
    NSInteger packet = _applyData.length / 6 + 1;
    if (_applyData.length % 6 == 0) {
        packet = _applyData.length / 6;
    }
    NSInteger l = 6;
    if (_applyData.length < 6) {
        l = _applyData.length;
    }
    _applyIndex = 1;
    NSData *data_0 = [_applyData subdataWithRange:NSMakeRange(0, l)];
    Byte byte[4] = {0xea, 0x78, packet, 0x01};
    NSData *head = [[NSData alloc] initWithBytes:byte length:4];
    NSMutableData *cmd = [[NSMutableData alloc] init];
    [cmd appendData:head];
    [cmd appendData:data_0];
    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
}

- (void)LCDRemoteSSIDCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSInteger index = [CSRUtilities numberWithHexString:userInfo[@"index"]];
    NSInteger sort = [CSRUtilities numberWithHexString:userInfo[@"sort"]];
    
    if ([deviceId isEqualToNumber:_deviceId] && index == _applyIndex) {
        NSInteger packet = _applyData.length / 6 + 1;
        if (_applyData.length % 6 == 0) {
            packet = _applyData.length / 6;
        }
        
        if (index == packet) {
            
            if (sort == 120) {
                _applyData = [_wifiPassword dataUsingEncoding:NSUTF8StringEncoding];
                NSInteger packet = _applyData.length / 6 + 1;
                if (_applyData.length % 6 == 0) {
                    packet = _applyData.length / 6;
                }
                NSInteger l = 6;
                if (_applyData.length < 6) {
                    l = _applyData.length;
                }
                _applyIndex = 1;
                NSData *data_0 = [_applyData subdataWithRange:NSMakeRange(0, l)];
                Byte byte[4] = {0xea, 0x79, packet, 0x01};
                NSData *head = [[NSData alloc] initWithBytes:byte length:4];
                NSMutableData *cmd = [[NSMutableData alloc] init];
                [cmd appendData:head];
                [cmd appendData:data_0];
                [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            }
            
        }else if (index == (packet - 1)) {
            _applyIndex = index + 1;
            NSData *data_0 = [_applyData subdataWithRange:NSMakeRange(6*index, _applyData.length - 6*index)];
            Byte byte[4] = {0xea, sort, packet, _applyIndex};
            NSData *head = [[NSData alloc] initWithBytes:byte length:4];
            NSMutableData *cmd = [[NSMutableData alloc] init];
            [cmd appendData:head];
            [cmd appendData:data_0];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }else {
            _applyIndex = index + 1;
            NSData *data_0 = [_applyData subdataWithRange:NSMakeRange(6*index, 6)];
            Byte byte[4] = {0xea, sort, packet, _applyIndex};
            NSData *head = [[NSData alloc] initWithBytes:byte length:4];
            NSMutableData *cmd = [[NSMutableData alloc] init];
            [cmd appendData:head];
            [cmd appendData:data_0];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
        }
    }
}

- (void)LCDRemoteIPAdressCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        NSString *s = userInfo[@"IPAdress"];
        for (int i = 0; i < s.length/2; i ++) {
            NSInteger a = [CSRUtilities numberWithHexString:[s substringWithRange:NSMakeRange(2*i, 2)]];
            if (i == 0) {
                _IPAdress = [NSString stringWithFormat:@"%ld",(long)a];
            }else {
                _IPAdress = [NSString stringWithFormat:@"%@.%ld",_IPAdress,(long)a];
            }
        }
        if (_port != -1) {
            [self connentHost:_IPAdress prot:_port];
        }
    }
}

- (void)LCDRemotePortCall:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        NSString *p = userInfo[@"port"];
        _port = [CSRUtilities numberWithHexString:p];
        if ([_IPAdress length]>0) {
            [self connentHost:_IPAdress prot:_port];
        }
    }
}

- (void)connentHost:(NSString *)host prot:(uint16_t)port{
    if (host==nil || host.length <= 0) {
        NSAssert(host != nil, @"host must be not nil");
    }
    
    [self.tcpSocketManager disconnect];
    if (self.tcpSocketManager == nil) {
        self.tcpSocketManager = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    NSError *connectError = nil;
    BOOL isConnected = [self.tcpSocketManager isConnected];
    NSLog(@"isConnected: %d",isConnected);
    if (!isConnected) {
        if (![self.tcpSocketManager connectToHost:host onPort:port error:&connectError]) {
            NSLog(@"Connect Error: %@", connectError);
        }else {
            NSLog(@"Connect success!");
            
            self.uConfigBtn.hidden = NO;
            self.uIconBtn.hidden = NO;
            self.uWallBtn.hidden = NO;
            
            /*
            //测试
            NSDictionary *dic = @{@"libVersion":@3,@"imgCount":@3,@"imgList":@[@{@"imgAppType":@145,@"imgIndex":@1,@"imgName":@"面板主页",@"imgSize":@500}]};
            NSString *json = [CSRUtilities convertToJsonData:dic];
            NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
            
            NSInteger l = data.length;
            
            NSInteger packet = l/2000 + 1;
            if (l%2000 == 0) {
                packet = l/2000;
            }
            
            Byte byte_p[4] = {};
            byte_p[0] = (Byte)((packet & 0xFF000000)>>24);
            byte_p[1] = (Byte)((packet & 0x00FF0000)>>16);
            byte_p[2] = (Byte)((packet & 0x0000FF00)>>8);
            byte_p[3] = (Byte)((packet & 0x000000FF));
            
            NSInteger lp = 2000;
            if (l < 2000) {
                 lp = l;
            }
            
            Byte byte_lp[4] = {};
            byte_lp[0] = (Byte)((lp & 0xFF000000)>>24);
            byte_lp[1] = (Byte)((lp & 0x00FF0000)>>16);
            byte_lp[2] = (Byte)((lp & 0x0000FF00)>>8);
            byte_lp[3] = (Byte)((lp & 0x000000FF));
            
            Byte byte[] = {0xA5, 0xA6, 0xA7, 0xA8, byte_p[0], byte_p[1], byte_p[2], byte_p[3], 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, byte_lp[0], byte_lp[1], byte_lp[2], byte_lp[3]};
            NSData *head = [[NSData alloc] initWithBytes:byte length:20];
            NSMutableData *mutableData = [[NSMutableData alloc] init];
            [mutableData appendData:head];
            [mutableData appendData:data];
            
            int lm = (int)mutableData.length;
            Byte *bytes = (unsigned char *)[mutableData bytes];
            
            int sumT = 0;
            int sumC = 0;
            for (int i = 0; i < lm; i++) {
                sumT += bytes[i];
                sumC ^= bytes[i];
            }
            int at = sumT%256;
            printf("校验和：%d\n",at);
            printf("累加和：%d\n",sumT);
            printf("异或和：%d\n",sumC);
            
            Byte bytesum[] = {at, sumC};
            NSData *end = [[NSData alloc] initWithBytes:bytesum length:2];
            [mutableData appendData:end];
            
            NSLog(@"DATA2：%@ \n",mutableData);
            
            [self.tcpSocketManager writeData:mutableData withTimeout:-1 tag:0];
            */
            [self.tcpSocketManager readDataWithTimeout:-1 tag:0];
        }
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"DATA3：%@ \n",data);
    /*
    NSData *data_a = [data subdataWithRange:NSMakeRange(0, data.length-2)];
//    NSData *data_b = [data subdataWithRange:NSMakeRange(data.length-2, 1)];
//    NSData *data_c = [data subdataWithRange:NSMakeRange(data.length-1, 1)];
    
    int lm = (int)data_a.length;
    Byte *bytes = (unsigned char *)[data_a bytes];
    
    int sumT = 0;
    int sumC = 0;
    for (int i = 0; i < lm; i++) {
        sumT += bytes[i];
        sumC ^= bytes[i];
    }
    int at = sumT%256;
    printf("校验和>：%d\n",at);
    printf("累加和>：%d\n",sumT);
    printf("异或和>：%d\n",sumC);
    
    Byte byte_b[] = {at};
    NSData *b = [[NSData alloc] initWithBytes:byte_b length:1];
    
    Byte byte_c[] = {sumC};
    NSData *c = [[NSData alloc] initWithBytes:byte_c length:1];
    
    NSLog(@"b: %@ \n c: %@",b,c);
     */
    
    if (data.length >= 22) {
        NSData *data_a = [data subdataWithRange:NSMakeRange(0, data.length-2)];
        int at = [self atFromData:data_a];
        int sumC = [self sumCFromData:data_a];
        NSLog(@"2> at:%d  sumC:%d",at,sumC);
        Byte *bytes = (unsigned char *)[data bytes];
        if (at == bytes[20] && sumC == bytes[21]) {
            NSData *d_k = [data subdataWithRange:NSMakeRange(12, 2)];
            Byte *bytes_k = (Byte *)[d_k bytes];
            int k = bytes_k[0] * 256 + bytes_k[1];
            
            NSData *d_t = [data subdataWithRange:NSMakeRange(14, 2)];
            Byte *bytes_t = (Byte *)[d_t bytes];
            int t = bytes_t[0] * 256 + bytes_t[1];
        
            NSData *d_p = [data subdataWithRange:NSMakeRange(8, 4)];
            Byte *bytes_p = (Byte *)[d_p bytes];
            int p = bytes_p[0] * 256 * 256 * 256 +  bytes_p[1] * 256 * 256 + bytes_p[2] * 256 + bytes_p[3];
            
//            NBSLog(@"%d  %d  %d  %ld  %ld",k,t,p,_applyCmdType,_applyIndex);
            if (k == 1 && t == _applyCmdType && p == _applyIndex) {
                
                NSInteger l = _applyData.length;
                
                NSInteger l_packet = l/2000 + 1;
                if (l%2000 == 0) {
                    l_packet = l/2000;
                }
                
                if (_applyIndex == l_packet) {
                    
                }else if (_applyIndex < l_packet) {
                    Byte byte_packet[4] = {};
                    byte_packet[0] = (Byte)((l_packet & 0xFF000000)>>24);
                    byte_packet[1] = (Byte)((l_packet & 0x00FF0000)>>16);
                    byte_packet[2] = (Byte)((l_packet & 0x0000FF00)>>8);
                    byte_packet[3] = (Byte)((l_packet & 0x000000FF));
                    
                    NSInteger l_per = 2000;
                    if (l-(2000*_applyIndex) < 2000) {
                        l_per = l-(2000*_applyIndex);
                    }
                    Byte byte_per[4] = {};
                    byte_per[0] = (Byte)((l_per & 0xFF000000)>>24);
                    byte_per[1] = (Byte)((l_per & 0x00FF0000)>>16);
                    byte_per[2] = (Byte)((l_per & 0x0000FF00)>>8);
                    byte_per[3] = (Byte)((l_per & 0x000000FF));
                    
                    _applyIndex ++;
                    Byte byte_index[4] = {};
                    byte_index[0] = (Byte)((_applyIndex & 0xFF000000)>>24);
                    byte_index[1] = (Byte)((_applyIndex & 0x00FF0000)>>16);
                    byte_index[2] = (Byte)((_applyIndex & 0x0000FF00)>>8);
                    byte_index[3] = (Byte)((_applyIndex & 0x000000FF));
                    
                    Byte byte_cmdtype[] = {};
                    byte_cmdtype[0] = (Byte)((_applyCmdType & 0xFF00)>>8);
                    byte_cmdtype[1] = (Byte)(_applyCmdType & 0x00FF);
                    
                    Byte byte[] = {0xA5, 0xA6, 0xA7, 0xA8, byte_packet[0], byte_packet[1], byte_packet[2], byte_packet[3], byte_index[0], byte_index[1], byte_index[2], byte_index[3], 0x00, 0x00, byte_cmdtype[0] , byte_cmdtype[1], byte_per[0], byte_per[1], byte_per[2], byte_per[3]};
                    NSData *head = [[NSData alloc] initWithBytes:byte length:20];
                    NSMutableData *mutableData = [[NSMutableData alloc] init];
                    [mutableData appendData:head];
                    [mutableData appendData:[_applyData subdataWithRange:NSMakeRange(2000*(_applyIndex-1), l_per)]];
                    
                    Byte bytesum[] = {[self atFromData:mutableData], [self sumCFromData:mutableData]};
                    NSData *end = [[NSData alloc] initWithBytes:bytesum length:2];
                    [mutableData appendData:end];
                    [sock writeData:mutableData withTimeout:-1 tag:0];
                }
                
            }
        }
    }
    
    
    [sock readDataWithTimeout:-1 tag:0];
}

- (IBAction)updateConfiguration:(UIButton *)sender {
    
    NSMutableArray *a = [[NSMutableArray alloc] init];
    for (NSObject *obj in _dataAry) {
        if ([obj isKindOfClass:[LCDSelectModel class]]) {
            LCDSelectModel *m = (LCDSelectModel *)obj;
            NSDictionary *d = @{@"displayName":m.name,@"arrangeIndex":m.sortID,@"keyIndex":m.sourceID,@"imgIndex":m.iconID,@"bindType":m.typeID,@"bindBtAddress":m.deviceID,@"channelSet":m.channel};
            [a addObject:d];
        }
    }
    NSDictionary *jd = @{@"buttonCount":[NSNumber numberWithInteger:[a count]],@"buttonList":a};
    NSString *j = [CSRUtilities convertToJsonData2:jd];
//    NBSLog(@"%@",j);
    _applyData = [j dataUsingEncoding:NSUTF8StringEncoding];
    
    _applyIndex = 1;
    _applyCmdType = 1;
    
    NSInteger l = _applyData.length;
    
    NSInteger l_packet = l/2000 + 1;
    if (l%2000 == 0) {
        l_packet = l/2000;
    }
    Byte byte_packet[4] = {};
    byte_packet[0] = (Byte)((l_packet & 0xFF000000)>>24);
    byte_packet[1] = (Byte)((l_packet & 0x00FF0000)>>16);
    byte_packet[2] = (Byte)((l_packet & 0x0000FF00)>>8);
    byte_packet[3] = (Byte)((l_packet & 0x000000FF));
    
    NSInteger l_per = 2000;
    if (l < 2000) {
        l_per = l;
    }
    Byte byte_per[4] = {};
    byte_per[0] = (Byte)((l_per & 0xFF000000)>>24);
    byte_per[1] = (Byte)((l_per & 0x00FF0000)>>16);
    byte_per[2] = (Byte)((l_per & 0x0000FF00)>>8);
    byte_per[3] = (Byte)((l_per & 0x000000FF));
    
    Byte byte[] = {0xA5, 0xA6, 0xA7, 0xA8, byte_packet[0], byte_packet[1], byte_packet[2], byte_packet[3], 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00 ,0x01, byte_per[0], byte_per[1], byte_per[2], byte_per[3]};
    NSData *head = [[NSData alloc] initWithBytes:byte length:20];
    NSMutableData *mutableData = [[NSMutableData alloc] init];
    [mutableData appendData:head];
    [mutableData appendData:[_applyData subdataWithRange:NSMakeRange(0, l_per)]];
    
    Byte bytesum[] = {[self atFromData:mutableData], [self sumCFromData:mutableData]};
    NSData *end = [[NSData alloc] initWithBytes:bytesum length:2];
    [mutableData appendData:end];
//    NBSLog(@"%@",mutableData);
    [self.tcpSocketManager writeData:mutableData withTimeout:-1 tag:0];
    
    [self.tcpSocketManager readDataWithTimeout:-1 tag:0];
}

- (IBAction)updateIconLibrary:(UIButton *)sender {
    
}

- (IBAction)synchronizeWallpaper:(UIButton *)sender {
    CSRDeviceEntity *d = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if ([d.wallPaper length] > 0) {
        UIImage *img = [self originalImage:[UIImage imageWithData:d.wallPaper]];
        NSData *imgData = UIImagePNGRepresentation(img);
        
        NSDictionary *jd = @{@"imgCount":@1,@"imgList":@[@{@"imgAppType":@145,@"imgIndex":@51,@"imgName":@"wallPaper",@"imgSize":@([imgData length]),@"imgCRC32":@([self crc32:imgData]),@"imgData":[CSRUtilities hexStringFromData:imgData]}]};
        
        NSString *j = [CSRUtilities convertToJsonData2:jd];
        _applyData = [j dataUsingEncoding:NSUTF8StringEncoding];
        _applyIndex = 1;
        _applyCmdType = 4;
        NSInteger l = _applyData.length;
        
        NSInteger l_packet = l/2000 + 1;
        if (l%2000 == 0) {
            l_packet = l/2000;
        }
        Byte byte_packet[4] = {};
        byte_packet[0] = (Byte)((l_packet & 0xFF000000)>>24);
        byte_packet[1] = (Byte)((l_packet & 0x00FF0000)>>16);
        byte_packet[2] = (Byte)((l_packet & 0x0000FF00)>>8);
        byte_packet[3] = (Byte)((l_packet & 0x000000FF));
        
        NSInteger l_per = 2000;
        if (l < 2000) {
            l_per = l;
        }
        Byte byte_per[4] = {};
        byte_per[0] = (Byte)((l_per & 0xFF000000)>>24);
        byte_per[1] = (Byte)((l_per & 0x00FF0000)>>16);
        byte_per[2] = (Byte)((l_per & 0x0000FF00)>>8);
        byte_per[3] = (Byte)((l_per & 0x000000FF));
        
        Byte byte[] = {0xA5, 0xA6, 0xA7, 0xA8, byte_packet[0], byte_packet[1], byte_packet[2], byte_packet[3], 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00 ,0x04, byte_per[0], byte_per[1], byte_per[2], byte_per[3]};
        NSData *head = [[NSData alloc] initWithBytes:byte length:20];
        NSMutableData *mutableData = [[NSMutableData alloc] init];
        [mutableData appendData:head];
        [mutableData appendData:[_applyData subdataWithRange:NSMakeRange(0, l_per)]];
        
        Byte bytesum[] = {[self atFromData:mutableData], [self sumCFromData:mutableData]};
        NSData *end = [[NSData alloc] initWithBytes:bytesum length:2];
        [mutableData appendData:end];
//        NSLog(@"wallpaper> %@",[mutableData subdataWithRange:NSMakeRange(0, 20)]);
//        NBSLog(@"%@",mutableData);
        [self.tcpSocketManager writeData:mutableData withTimeout:-1 tag:0];
    }
}

- (int32_t)crc32:(NSData *)data {
    uint32_t *table = malloc(sizeof(uint32_t) * 256);
    uint32_t crc = 0xffffffff;
    uint8_t *bytes = (uint8_t *)[data bytes];
    
    for (uint32_t i=0; i<256; i++) {
        table[i] = i;
        for (int j=0; j<8; j++) {
            if (table[i] & 1) {
                table[i] = (table[i] >>= 1) ^ 0xedb88320;
            } else {
                table[i] >>= 1;
            }
        }
    }
    
    for (int i=0; i<data.length; i++) {
        crc = (crc >> 8) ^ table[(crc & 0xff) ^ bytes[i]];
    }
    crc ^= 0xffffffff;
    
    free(table);
    return crc;
}

- (int)atFromData:(NSData *)data {
    int lm = (int)data.length;
    Byte *bytes = (unsigned char *)[data bytes];
    int sumT = 0;
    for (int i = 0; i < lm; i++) {
        sumT += bytes[i];
    }
    int at = sumT % 256;
    return at;
}

- (int)sumCFromData:(NSData *)data {
    int lm = (int)data.length;
    Byte *bytes = (unsigned char *)[data bytes];
    int sumC = 0;
    for (int i = 0; i < lm; i++) {
        sumC ^= bytes[i];
    }
    return sumC;
}

- (UIImage *)originalImage:(UIImage *)originalImage {
    CGFloat w = originalImage.size.width;
    CGFloat h = originalImage.size.height;
    CGRect r;
    if (w >= h) {
        r = CGRectMake(w/2-h/2, 0, h, h);
    }else {
        r = CGRectMake(0, h/2-w/2, w, w);
    }
    CGImageRef subImageRef = CGImageCreateWithImageInRect(originalImage.CGImage, r);
    CGRect smallRect = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
    UIGraphicsBeginImageContext(smallRect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, smallRect, subImageRef);
    UIImage *image = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    CGImageRelease(subImageRef);
    
    if (r.size.width > 720) {
        CGSize s = CGSizeMake(720, 720);
        UIGraphicsBeginImageContext(s);
        [image drawInRect:CGRectMake(0, 0, s.width, s.height)];
        UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return smallImage;
    }else {
        return image;
    }
}

@end
