//
//  GroupViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/30.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
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

@interface GroupViewController ()<UITextFieldDelegate,PlaceColorIconPickerViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,MainCollectionViewDelegate,MBProgressHUDDelegate>
{
    PlaceColorIconPickerView *pickerView;
    NSNumber *iconNum;
    UIImage *iconImage;
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

@end

@implementation GroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.groupNameTF.delegate = self;
    if (self.isCreateNewArea) {
        [self.editItem setTitle:@"Done" forState:UIControlStateNormal];
        [self.groupNameTF becomeFirstResponder];
        self.groupNameTF.backgroundColor = [UIColor whiteColor];
        self.iconEditBtn.hidden = NO;
    }else {
        [self.editItem setTitle:@"Edit" forState:UIControlStateNormal];
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
    
    _devicesCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectMake(WIDTH*3/160.0, WIDTH*302/640.0+64, WIDTH*157/160.0, HEIGHT-64-WIDTH*302/640.0) collectionViewLayout:flowLayout cellIdentifier:@"MainCollectionViewCell"];
    _devicesCollectionView.mainDelegate = self;
    if (!self.isCreateNewArea) {
        
        [_areaEntity.devices enumerateObjectsUsingBlock:^(CSRDeviceEntity *device, BOOL * _Nonnull stop) {
            SingleDeviceModel *deviceModel = [[SingleDeviceModel alloc] init];
            deviceModel.deviceId = device.deviceId;
            deviceModel.deviceName = device.name;
            deviceModel.deviceShortName = device.shortName;
            [_devicesCollectionView.dataArray addObject:deviceModel];
        }];
        
    }else{
        [_devicesCollectionView.dataArray addObject:@1];
    }
    
    [self.view addSubview:_devicesCollectionView];
    
    if (_isFromEmptyGroup) {
        [self editItemAction:self.editItem];
        DeviceListViewController *list = [[DeviceListViewController alloc] init];
        list.selectMode = DeviceListSelectMode_Multiple;
        
        list.originalMembers = _devicesCollectionView.dataArray;
        
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
        
        [self.navigationController pushViewController:list animated:YES];
    }
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
    if ([sender.titleLabel.text isEqualToString:@"Edit"]) {
        [sender setTitle:@"Done" forState:UIControlStateNormal];
        self.iconEditBtn.hidden = NO;
        self.groupNameTF.enabled = YES;
        self.groupNameTF.backgroundColor = [UIColor whiteColor];
        [_devicesCollectionView.dataArray addObject:@1];
        [_devicesCollectionView reloadData];
    }
    else {
        
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.mode = MBProgressHUDModeIndeterminate;
        _hud.delegate = self;
        
        [self performSelector:@selector(doneAction) withObject:nil afterDelay:0.01];
    }
    
}

- (void)doneAction {
    if (_groupNameTF.text.length == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Please enter a group name." message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }else if ([_devicesCollectionView.dataArray count] < 2) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Please select devices." message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }else {
        [self.editItem setTitle:@"Edit" forState:UIControlStateNormal];
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
            [self saveArea:areaIdNumber];
        }else if (self.hasChanged) {
            areaIdNumber = _areaEntity.areaID;
            
            for (CSRDeviceEntity *deviceEntity in _areaEntity.devices) {
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
                                                            uint16_t *dataToModify = (uint16_t*)deviceEntity.groups.bytes;
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
                                                                
                                                                
                                                                NSMutableData *myData = (NSMutableData*)deviceEntity.groups;
                                                                uint16_t desiredValue = [groupId unsignedShortValue];
                                                                int groupIndexInt = [groupIndex intValue];
                                                                if (groupIndexInt>-1) {
                                                                    uint16_t *groups = (uint16_t *) myData.mutableBytes;
                                                                    *(groups + groupIndexInt) = desiredValue;
                                                                }
                                                                deviceEntity.groups = (NSData*)myData;
                                                                
                                                                [[CSRDatabaseManager sharedInstance] saveContext];
                                                            }
                                                        }
                                                        failure:^(NSError * _Nullable error) {
                                                            NSLog(@"mesh timeout");
                                                        }];
                [NSThread sleepForTimeInterval:0.3];
            }
            
            [self saveArea:areaIdNumber];
        }
        
    }
    
    [_hud hideAnimated:YES];
}

- (void)saveArea:(NSNumber *)areaIdNumber {
    _areaEntity = [[CSRDatabaseManager sharedInstance] saveNewArea:areaIdNumber areaName:_groupNameTF.text areaImage:iconImage areaIconNum:iconNum];
    __weak GroupViewController *weakSelf = self;
    [_devicesCollectionView.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[SingleDeviceModel class]]) {
            SingleDeviceModel *singleDevice = (SingleDeviceModel *)obj;
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:singleDevice.deviceId];
            NSNumber *groupIndex = [weakSelf getValueByIndex:deviceEntity];
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
                                                            NSMutableData *myData = (NSMutableData*)deviceEntity.groups;
                                                            uint16_t desiredValue = [groupId unsignedShortValue];
                                                            int groupIndexInt = [groupIndex intValue];
                                                            if (groupIndexInt>-1) {
                                                                uint16_t *groups = (uint16_t *) myData.mutableBytes;
                                                                *(groups + groupIndexInt) = desiredValue;
                                                            }
                                                            
                                                            deviceEntity.groups = (NSData*)myData;
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
            }
        }else {
            NSLog(@"Device has 4 areas or something went wrong");
        }
        [NSThread sleepForTimeInterval:0.3];
    }];
    if (self.handle) {
        self.handle();
    }
}

//method to getIndexByValue
- (NSNumber *) getValueByIndex:(CSRDeviceEntity*)deviceEntity
{
    uint16_t *dataToModify = (uint16_t*)deviceEntity.groups.bytes;
    
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
    
    UIAlertAction *icon = [UIAlertAction actionWithTitle:@"Select default iocn" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
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
    UIAlertAction *camera = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [weakSelf alertAction:0];
        
    }];
    UIAlertAction *album = [UIAlertAction actionWithTitle:@"Choose from Album" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [weakSelf alertAction:1];
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
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
        list.selectMode = DeviceListSelectMode_Multiple;
        
        list.originalMembers = _devicesCollectionView.dataArray;
        
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
        
        [self.navigationController pushViewController:list animated:YES];
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
        if (updateLevel < 13) {
            updateLevel = 13;
        }
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
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:dvc];
        nav.modalTransitionStyle = UIModalPresentationPopover;
        [self presentViewController:nav animated:YES completion:nil];
        UIPopoverPresentationController *popover = nav.popoverPresentationController;
        popover.sourceRect = mainCell.bounds;
        popover.sourceView = mainCell;
    }
}

#pragma mark - <UIImagePickerControllerDelegate>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.hasChanged = YES;
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.groupIconImageView.image = [self fixOrientation:image];
    self.groupIconImageView.alpha = 0.8;
    iconNum = @99;
    iconImage = image;
    
    
}

//相机拍的照片带有imageOrientation属性，在显示的时候会自动摆正方向，而存放的时候按统一方向存放，开发使用时需摆正方向。
- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
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
