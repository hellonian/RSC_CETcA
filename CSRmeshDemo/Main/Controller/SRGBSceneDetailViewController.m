//
//  SRGBSceneDetailViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/9/3.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "SRGBSceneDetailViewController.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import "PureLayout.h"
#import "CSRConstants.h"
#import "ColorSlider.h"
#import <CSRmesh/LightModelApi.h>
#import "DeviceModelManager.h"

@interface SRGBSceneDetailViewController ()<ColorSliderDelegate,UITextFieldDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIButton *rgbSceneImageBtn;
@property (weak, nonatomic) IBOutlet UITextField *rgbSceneNameTF;
@property (strong, nonatomic) IBOutlet UILabel *levelTitleLabel;
@property (strong, nonatomic) IBOutlet UIView *levelView;
@property (weak, nonatomic) IBOutlet UISlider *levelSlider;
@property (weak, nonatomic) IBOutlet UILabel *levelLabel;
@property (strong, nonatomic) IBOutlet UILabel *colorTilteLabel;
@property (strong, nonatomic) IBOutlet UIView *colorView;
@property (nonatomic,strong) ColorSlider *colorSlider;
@property (weak, nonatomic) IBOutlet UILabel *colorLabel;
@property (strong, nonatomic) IBOutlet UILabel *colorSaturationTilteLabel;
@property (strong, nonatomic) IBOutlet UIView *colorSaturationView;
@property (weak, nonatomic) IBOutlet UISlider *colorSaturationSlider;
@property (weak, nonatomic) IBOutlet UILabel *colorSaturationLabel;
@property (strong, nonatomic) IBOutlet UIButton *restoreBtn;

@end

@implementation SRGBSceneDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSArray *names = kRGBSceneDefaultName;
    if ([_rgbSceneEntity.isDefaultImg boolValue]) {
        NSInteger num = [_rgbSceneEntity.rgbSceneID integerValue];
        [_rgbSceneImageBtn setBackgroundImage:[UIImage imageNamed:names[num]] forState:UIControlStateNormal];
    }else {
        [_rgbSceneImageBtn setBackgroundImage:[UIImage imageWithData:_rgbSceneEntity.rgbSceneImage] forState:UIControlStateNormal];
    }
    if ([names containsObject:_rgbSceneEntity.name]) {
        _rgbSceneNameTF.text = AcTECLocalizedStringFromTable(_rgbSceneEntity.name, @"Localizable");
    }else {
        _rgbSceneNameTF.text = _rgbSceneEntity.name;
    }
    _rgbSceneNameTF.delegate = self;
    
    [self.view addSubview:_colorTilteLabel];
    NSLayoutConstraint *constraint = [_colorTilteLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_topView withOffset:5.0];
    [_colorTilteLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
    [_colorTilteLabel autoSetDimension:ALDimensionHeight toSize:20.0];
    [_colorTilteLabel autoSetDimension:ALDimensionWidth toSize:80.0];
    
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if ([CSRUtilities belongToRGBDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
        
        constraint.constant = 79.0;
        
        [self.view addSubview:_levelTitleLabel];
        [_levelTitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_topView withOffset:5.0];
        [_levelTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
        [_levelTitleLabel autoSetDimension:ALDimensionHeight toSize:20.0];
        [_levelTitleLabel autoSetDimension:ALDimensionWidth toSize:80.0];
        
        [self.view addSubview:_levelView];
        [_levelView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_levelTitleLabel withOffset:5.0];
        [_levelView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_levelView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [_levelView autoSetDimension:ALDimensionHeight toSize:44.0];
        
    }
    
    [self.view addSubview:_colorView];
    [_colorView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorTilteLabel withOffset:5.0];
    [_colorView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_colorView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [_colorView autoSetDimension:ALDimensionHeight toSize:44.0];
    
    _colorSlider = [[ColorSlider alloc] initWithFrame:CGRectZero];
    _colorSlider.delegate = self;
    [_colorView addSubview:_colorSlider];
    [_colorSlider autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [_colorSlider autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:44.0];
    [_colorSlider autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:_colorLabel withOffset:8.0];
    [_colorSlider autoSetDimension:ALDimensionHeight toSize:31.0];
    
    [self.view addSubview:_colorSaturationTilteLabel];
    [_colorSaturationTilteLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorView withOffset:5.0];
    [_colorSaturationTilteLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
    [_colorSaturationTilteLabel autoSetDimension:ALDimensionHeight toSize:20.0];
    [_colorSaturationTilteLabel autoSetDimension:ALDimensionWidth toSize:120.0];
    
    [self.view addSubview:_colorSaturationView];
    [_colorSaturationView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorSaturationTilteLabel withOffset:5.0];
    [_colorSaturationView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_colorSaturationView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [_colorSaturationView autoSetDimension:ALDimensionHeight toSize:44.0];
    
    [self.view addSubview:_restoreBtn];
    [_restoreBtn autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_restoreBtn autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorSaturationView withOffset:30.0];
    [_restoreBtn autoSetDimension:ALDimensionHeight toSize:30.0];
    [_restoreBtn autoSetDimension:ALDimensionWidth toSize:200.0];
    
    [_levelSlider setValue:[_rgbSceneEntity.level floatValue]];
    _levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_rgbSceneEntity.level floatValue]/255.0*100];
    
    _colorLabel.text = [NSString stringWithFormat:@"%.f",[_rgbSceneEntity.hueA floatValue]*360];
    
    [_colorSaturationSlider setValue:[_rgbSceneEntity.colorSat floatValue]];
    _colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",[_rgbSceneEntity.colorSat floatValue]*100];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [_colorSlider layoutIfNeeded];
    [_colorSlider sliderMyValue:[_rgbSceneEntity.hueA floatValue]];
}

#pragma mark - 修改亮度

- (IBAction)changLevel:(UISlider *)sender {
    _levelLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value/255.0*100];
    [[LightModelApi sharedInstance] setLevel:_deviceId level:[NSNumber numberWithFloat:sender.value] success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
        
    } failure:^(NSError * _Nullable error) {
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        model.isleave = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":_deviceId}];
    }];
    _rgbSceneEntity.level = [NSNumber numberWithFloat:sender.value];
    [[CSRDatabaseManager sharedInstance] saveContext];
    if (self.reloadDataHandle) {
        self.reloadDataHandle();
    }
}

#pragma mark - 修改颜色

- (void)colorSliderValueChanged:(CGFloat)myValue withState:(UIGestureRecognizerState)state {
    if (state == UIGestureRecognizerStateEnded) {
        _colorLabel.text = [NSString stringWithFormat:@"%.f",myValue*360];
        UIColor *color = [UIColor colorWithHue:myValue saturation:[_rgbSceneEntity.colorSat floatValue] brightness:1.0 alpha:1.0];
        [[LightModelApi sharedInstance] setColor:_deviceId color:color duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
            
        } failure:^(NSError * _Nullable error) {
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
            model.isleave = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":_deviceId}];
        }];
        _rgbSceneEntity.hueA = [NSNumber numberWithFloat:myValue];
        [[CSRDatabaseManager sharedInstance] saveContext];
        if (self.reloadDataHandle) {
            self.reloadDataHandle();
        }
    }
}

#pragma mark - 修改饱和度

- (IBAction)changeColorSaturation:(UISlider *)sender {
    _colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value*100];
    UIColor *color = [UIColor colorWithHue:[_rgbSceneEntity.hueA floatValue] saturation:sender.value brightness:1.0 alpha:1.0];
    [[LightModelApi sharedInstance] setColor:_deviceId color:color duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
        
    } failure:^(NSError * _Nullable error) {
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        model.isleave = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":_deviceId}];
    }];
    _rgbSceneEntity.colorSat = [NSNumber numberWithFloat:sender.value];
    [[CSRDatabaseManager sharedInstance] saveContext];
    if (self.reloadDataHandle) {
        self.reloadDataHandle();
    }
}

#pragma mark - 恢复默认值

- (IBAction)restoreDefault:(UIButton *)sender {
    NSArray *names = kRGBSceneDefaultName;
    NSArray *levels = kRGBSceneDefaultLevel;
    NSArray *hues = kRGBSceneDefaultHue;
    NSArray *sats = kRGBSceneDefaultColorSat;
    NSInteger i = [_rgbSceneEntity.rgbSceneID integerValue];
    _rgbSceneEntity.name = names[i];
    _rgbSceneNameTF.text = names[i];
    _rgbSceneEntity.isDefaultImg = @1;
    [_rgbSceneImageBtn setBackgroundImage:[UIImage imageNamed:names[i]] forState:UIControlStateNormal];
    _rgbSceneEntity.rgbSceneImage = nil;
    _rgbSceneEntity.level = levels[i];
    _levelLabel.text = [NSString stringWithFormat:@"%.f%%",[levels[i] floatValue]/255.0*100];
    [_levelSlider setValue:[levels[i] floatValue]];
    _rgbSceneEntity.hueA = hues[i];
    _colorLabel.text = [NSString stringWithFormat:@"%.f",[hues[i] floatValue]*360];
    [_colorSlider setMyValue:[hues[i] floatValue]];
    _rgbSceneEntity.colorSat = sats[i];
    _colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",[sats[i] floatValue]*100];
    [_colorSaturationSlider setValue:[sats[i] floatValue]];
    [[CSRDatabaseManager sharedInstance] saveContext];
    if (self.reloadDataHandle) {
        self.reloadDataHandle();
    }
    
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if ([CSRUtilities belongToRGBDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
        [[LightModelApi sharedInstance] setLevel:_deviceId level:levels[i] success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
            
        } failure:^(NSError * _Nullable error) {
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
            model.isleave = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":_deviceId}];
        }];
    }
    UIColor *color = [UIColor colorWithHue:[hues[i] floatValue] saturation:[sats[i] floatValue] brightness:1.0 alpha:1.0];
    [[LightModelApi sharedInstance] setColor:_deviceId color:color duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
        
    } failure:^(NSError * _Nullable error) {
        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
        model.isleave = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":_deviceId}];
    }];
    
}

#pragma mark - 修改图片

- (IBAction)changeImage:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert.view setTintColor:DARKORAGE];
    __weak SRGBSceneDetailViewController *weakself = self;
    UIAlertAction *camera = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Camera", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [weakself alertAction:0];
        
    }];
    UIAlertAction *album = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ChooseFromAlbum", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [weakself alertAction:1];
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [CSRUtilities fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]];
    image = [CSRUtilities getSquareImage:image];
    [_rgbSceneImageBtn setBackgroundImage:image forState:UIControlStateNormal];
    _rgbSceneEntity.isDefaultImg = @0;
    _rgbSceneEntity.rgbSceneImage = UIImageJPEGRepresentation(image, 0.5);
    [[CSRDatabaseManager sharedInstance] saveContext];
    if (self.reloadDataHandle) {
        self.reloadDataHandle();
    }
}

#pragma mark - 修改名字

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
    [self saveName];
}

- (void)saveName {
    if (![_rgbSceneNameTF.text isEqualToString:_rgbSceneEntity.name] && _rgbSceneNameTF.text.length > 0) {
        _rgbSceneEntity.name = _rgbSceneNameTF.text;
        [[CSRDatabaseManager sharedInstance] saveContext];
        if (self.reloadDataHandle) {
            self.reloadDataHandle();
        }
    }
}

@end
