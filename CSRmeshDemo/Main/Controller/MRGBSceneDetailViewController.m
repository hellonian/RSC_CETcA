//
//  MRGBSceneDetailViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/9/3.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MRGBSceneDetailViewController.h"
#import "PureLayout.h"
#import "CSRConstants.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import "ColorSlider.h"
#import "DeviceModelManager.h"
#import <CSRmesh/LightModelApi.h>
#import "CSRUtilities.h"

@interface MRGBSceneDetailViewController ()<ColorSliderDelegate,UITextFieldDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
{
    UIAlertController *customAlert;
    UIButton *selectedBtn;
}

@property (weak, nonatomic) IBOutlet UIButton *rgbSceneImageBtn;
@property (weak, nonatomic) IBOutlet UITextField *rgbSceneNameTF;
@property (weak, nonatomic) IBOutlet UIButton *hueABtn;
@property (weak, nonatomic) IBOutlet UIButton *hueBBtn;
@property (weak, nonatomic) IBOutlet UIButton *hueCBtn;
@property (weak, nonatomic) IBOutlet UIButton *hueDBtn;
@property (weak, nonatomic) IBOutlet UIButton *hueEBtn;
@property (weak, nonatomic) IBOutlet UIButton *hueFBtn;
@property (weak, nonatomic) IBOutlet UIView *colorSettingView;
@property (strong, nonatomic) IBOutlet UILabel *levelTitleLabel;
@property (strong, nonatomic) IBOutlet UIView *levelView;
@property (weak, nonatomic) IBOutlet UISlider *levelSlider;
@property (weak, nonatomic) IBOutlet UILabel *levelLabel;
@property (strong, nonatomic) IBOutlet UILabel *colorSaturationTilteLabel;
@property (strong, nonatomic) IBOutlet UIView *colorSaturationView;
@property (weak, nonatomic) IBOutlet UISlider *colorSaturationSlider;
@property (weak, nonatomic) IBOutlet UILabel *colorSaturationLabel;
@property (strong, nonatomic) IBOutlet UILabel *changeSpeedTitleLabel;
@property (strong, nonatomic) IBOutlet UIView *changeSpeedView;
@property (weak, nonatomic) IBOutlet UISlider *changeSpeedSlider;
@property (weak, nonatomic) IBOutlet UILabel *changSpeedLabel;
@property (strong, nonatomic) IBOutlet UIButton *restoreBtn;

@end

@implementation MRGBSceneDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSArray *names = kRGBSceneDefaultName;
    if ([_rgbSceneEntity.isDefaultImg boolValue]) {
        NSArray *names = kRGBSceneDefaultName;
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
    
    float colorSaturation = [_rgbSceneEntity.colorSat floatValue];
    UIColor *colorA = [UIColor colorWithHue:[_rgbSceneEntity.hueA floatValue] saturation:colorSaturation brightness:1.0 alpha:1.0];
    _hueABtn.backgroundColor = colorA;
    UIColor *colorB = [UIColor colorWithHue:[_rgbSceneEntity.hueB floatValue] saturation:colorSaturation brightness:1.0 alpha:1.0];
    _hueBBtn.backgroundColor = colorB;
    UIColor *colorC = [UIColor colorWithHue:[_rgbSceneEntity.hueC floatValue] saturation:colorSaturation brightness:1.0 alpha:1.0];
    _hueCBtn.backgroundColor = colorC;
    UIColor *colorD = [UIColor colorWithHue:[_rgbSceneEntity.hueD floatValue] saturation:colorSaturation brightness:1.0 alpha:1.0];
    _hueDBtn.backgroundColor = colorD;
    UIColor *colorE = [UIColor colorWithHue:[_rgbSceneEntity.hueE floatValue] saturation:colorSaturation brightness:1.0 alpha:1.0];
    _hueEBtn.backgroundColor = colorE;
    UIColor *colorF = [UIColor colorWithHue:[_rgbSceneEntity.hueF floatValue] saturation:colorSaturation brightness:1.0 alpha:1.0];
    _hueFBtn.backgroundColor = colorF;
    
    [_levelSlider setValue:[_rgbSceneEntity.level floatValue]];
    _levelLabel.text = [NSString stringWithFormat:@"%.f%%",[_rgbSceneEntity.level floatValue]/255.0*100];
    
    [_colorSaturationSlider setValue:[_rgbSceneEntity.colorSat floatValue]];
    _colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",[_rgbSceneEntity.colorSat floatValue]*100];
    
    [_changeSpeedSlider setValue:(6-[_rgbSceneEntity.changeSpeed floatValue])];
    _changSpeedLabel.text = [NSString stringWithFormat:@"%.f%%",(5-[_rgbSceneEntity.changeSpeed floatValue])/4*100];
    
    [self.view addSubview:_colorSaturationTilteLabel];
    NSLayoutConstraint *constraint = [_colorSaturationTilteLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorSettingView withOffset:5.0];
    [_colorSaturationTilteLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
    [_colorSaturationTilteLabel autoSetDimension:ALDimensionHeight toSize:20.0];
    [_colorSaturationTilteLabel autoSetDimension:ALDimensionWidth toSize:120];
    
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if ([CSRUtilities belongToRGBDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
        constraint.constant = 79.0;
        [self.view addSubview:_levelTitleLabel];
        [_levelTitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorSettingView withOffset:5.0];
        [_levelTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
        [_levelTitleLabel autoSetDimension:ALDimensionHeight toSize:20.0];
        [_levelTitleLabel autoSetDimension:ALDimensionWidth toSize:120];
        
        [self.view addSubview:_levelView];
        [_levelView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_levelTitleLabel withOffset:5.0];
        [_levelView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_levelView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [_levelView autoSetDimension:ALDimensionHeight toSize:44.0];
    }
    
    [self.view addSubview:_colorSaturationView];
    [_colorSaturationView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorSaturationTilteLabel withOffset:5.0];
    [_colorSaturationView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_colorSaturationView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [_colorSaturationView autoSetDimension:ALDimensionHeight toSize:44.0];
    
    [self.view addSubview:_changeSpeedTitleLabel];
    [_changeSpeedTitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_colorSaturationView withOffset:5.0];
    [_changeSpeedTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [_changeSpeedTitleLabel autoSetDimension:ALDimensionHeight toSize:20.0];
    [_changeSpeedTitleLabel autoSetDimension:ALDimensionWidth toSize:120];
    
    [self.view addSubview:_changeSpeedView];
    [_changeSpeedView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_changeSpeedTitleLabel withOffset:5.0];
    [_changeSpeedView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_changeSpeedView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [_changeSpeedView autoSetDimension:ALDimensionHeight toSize:44.0];
    
    [self.view addSubview:_restoreBtn];
    [_restoreBtn autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_restoreBtn autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_changeSpeedView withOffset:10.0];
    [_restoreBtn autoSetDimension:ALDimensionHeight toSize:30.0];
    [_restoreBtn autoSetDimension:ALDimensionWidth toSize:200.0];
}

#pragma mark - 修改颜色

- (IBAction)selectColor:(UIButton *)sender {
    selectedBtn = sender;
    
    customAlert = [UIAlertController alertControllerWithTitle:nil message:@"\n\n\n\n" preferredStyle:UIAlertControllerStyleActionSheet];
    customAlert.popoverPresentationController.sourceRect = sender.bounds;
    customAlert.popoverPresentationController.sourceView = sender;
    
    UIButton *confirm = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirm setTitle:@"OK" forState:UIControlStateNormal];
    [confirm setTitleColor:DARKORAGE forState:UIControlStateNormal];
    [confirm addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    [customAlert.view addSubview:confirm];
    [confirm autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [confirm autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [confirm autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [confirm autoSetDimension:ALDimensionHeight toSize:44.0];
    
    ColorSlider *colorSlider = [[ColorSlider alloc] initWithFrame:CGRectZero];
    colorSlider.delegate = self;
    [customAlert.view addSubview:colorSlider];
    [colorSlider autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [colorSlider autoSetDimension:ALDimensionWidth toSize:customAlert.view.bounds.size.width-40.0];
    [colorSlider autoSetDimension:ALDimensionHeight toSize:31.0];
    [colorSlider autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:22.0];
    
    [self presentViewController:customAlert animated:YES completion:nil];
    CGFloat hue = 0.0;
    switch (sender.tag) {
        case 0:
            hue = [_rgbSceneEntity.hueA floatValue];
            break;
        case 1:
            hue = [_rgbSceneEntity.hueB floatValue];
            break;
        case 2:
            hue = [_rgbSceneEntity.hueC floatValue];
            break;
        case 3:
            hue = [_rgbSceneEntity.hueD floatValue];
            break;
        case 4:
            hue = [_rgbSceneEntity.hueE floatValue];
            break;
        case 5:
            hue = [_rgbSceneEntity.hueF floatValue];
            break;
        default:
            break;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [colorSlider sliderMyValue:hue];
    });
}

- (void)btnAction:(UIButton *)sender {
    [customAlert dismissViewControllerAnimated:YES completion:nil];
}

- (void)colorSliderValueChanged:(CGFloat)myValue withState:(UIGestureRecognizerState)state {
    
    if (state == UIGestureRecognizerStateEnded) {
        UIColor *color = [UIColor colorWithHue:myValue saturation:[_rgbSceneEntity.colorSat floatValue] brightness:1.0 alpha:1.0];
        selectedBtn.backgroundColor = color;
        switch (selectedBtn.tag) {
            case 0:
                _rgbSceneEntity.hueA = [NSNumber numberWithFloat:myValue];
                break;
            case 1:
                _rgbSceneEntity.hueB = [NSNumber numberWithFloat:myValue];
                break;
            case 2:
                _rgbSceneEntity.hueC = [NSNumber numberWithFloat:myValue];
                break;
            case 3:
                _rgbSceneEntity.hueD = [NSNumber numberWithFloat:myValue];
                break;
            case 4:
                _rgbSceneEntity.hueE = [NSNumber numberWithFloat:myValue];
                break;
            case 5:
                _rgbSceneEntity.hueF = [NSNumber numberWithFloat:myValue];
                break;
            default:
                break;
        }
        [[CSRDatabaseManager sharedInstance] saveContext];
        if (self.reloadDataHandle) {
            self.reloadDataHandle();
        }
        
        [[DeviceModelManager sharedInstance] regetHues:@[_rgbSceneEntity.hueA,_rgbSceneEntity.hueB,_rgbSceneEntity.hueC,_rgbSceneEntity.hueD,_rgbSceneEntity.hueE,_rgbSceneEntity.hueF] deviceId:_deviceId sceneId:_rgbSceneEntity.rgbSceneID];
    }
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

#pragma mark - 修改饱和度

- (IBAction)changeColorSaturation:(UISlider *)sender {
    _colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",sender.value*100];
    _rgbSceneEntity.colorSat = [NSNumber numberWithFloat:sender.value];
    [[CSRDatabaseManager sharedInstance] saveContext];
    if (self.reloadDataHandle) {
        self.reloadDataHandle();
    }
    [[DeviceModelManager sharedInstance] regetColorSaturation:sender.value deviceId:_deviceId sceneId:_rgbSceneEntity.rgbSceneID];
}

#pragma mark - 修改速度

- (IBAction)changeSpeed:(UISlider *)sender {
    _changSpeedLabel.text = [NSString stringWithFormat:@"%.f%%",(sender.value-1)/4*100];
    _rgbSceneEntity.changeSpeed = [NSNumber numberWithFloat:6-sender.value];
    [[CSRDatabaseManager sharedInstance] saveContext];
    if (self.reloadDataHandle) {
        self.reloadDataHandle();
    }
    [[DeviceModelManager sharedInstance] regetColofulTimerInterval:6-sender.value deviceId:_deviceId sceneId:_rgbSceneEntity.rgbSceneID];
}

#pragma mark - 恢复默认值

- (IBAction)restoreDefault:(UIButton *)sender {
    NSArray *names = kRGBSceneDefaultName;
    NSArray *levels = kRGBSceneDefaultLevel;
    NSArray *sats = kRGBSceneDefaultColorSat;
    NSArray *hues = kRGBSceneDefaultHue;
    NSInteger i = [_rgbSceneEntity.rgbSceneID integerValue];
    _rgbSceneEntity.name = names[i];
    _rgbSceneNameTF.text = names[i];
    _rgbSceneEntity.isDefaultImg = @1;
    [_rgbSceneImageBtn setBackgroundImage:[UIImage imageNamed:names[i]] forState:UIControlStateNormal];
    _rgbSceneEntity.rgbSceneImage = nil;
    _rgbSceneEntity.level = levels[i];
    _levelLabel.text = [NSString stringWithFormat:@"%.f%%",[levels[i] floatValue]/255.0*100];
    [_levelSlider setValue:[levels[i] floatValue]];
    _rgbSceneEntity.colorSat = sats[i];
    _colorSaturationLabel.text = [NSString stringWithFormat:@"%.f%%",[sats[i] floatValue]*100];
    [_colorSaturationSlider setValue:[sats[i] floatValue]];
    _rgbSceneEntity.changeSpeed = @(1.0);
    _changSpeedLabel.text = [NSString stringWithFormat:@"%.f%%",(1.0-0.5)/3.5*100];
    [_changeSpeedSlider setValue:1.0];
    NSArray *colorfulHues = hues[i];
    _rgbSceneEntity.hueA = colorfulHues[0];
    _rgbSceneEntity.hueB = colorfulHues[1];
    _rgbSceneEntity.hueC = colorfulHues[2];
    _rgbSceneEntity.hueD = colorfulHues[3];
    _rgbSceneEntity.hueE = colorfulHues[4];
    _rgbSceneEntity.hueF = colorfulHues[5];
    float colorSaturation = [sats[i] floatValue];
    UIColor *colorA = [UIColor colorWithHue:[colorfulHues[0] floatValue] saturation:colorSaturation brightness:1.0 alpha:1.0];
    _hueABtn.backgroundColor = colorA;
    UIColor *colorB = [UIColor colorWithHue:[colorfulHues[1] floatValue] saturation:colorSaturation brightness:1.0 alpha:1.0];
    _hueBBtn.backgroundColor = colorB;
    UIColor *colorC = [UIColor colorWithHue:[colorfulHues[2] floatValue] saturation:colorSaturation brightness:1.0 alpha:1.0];
    _hueCBtn.backgroundColor = colorC;
    UIColor *colorD = [UIColor colorWithHue:[colorfulHues[3] floatValue] saturation:colorSaturation brightness:1.0 alpha:1.0];
    _hueDBtn.backgroundColor = colorD;
    UIColor *colorE = [UIColor colorWithHue:[colorfulHues[4] floatValue] saturation:colorSaturation brightness:1.0 alpha:1.0];
    _hueEBtn.backgroundColor = colorE;
    UIColor *colorF = [UIColor colorWithHue:[colorfulHues[5] floatValue] saturation:colorSaturation brightness:1.0 alpha:1.0];
    _hueFBtn.backgroundColor = colorF;
    
    [[DeviceModelManager sharedInstance] invalidateColofulTimerWithDeviceId:_deviceId];
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if ([CSRUtilities belongToRGBDevice:deviceEntity.shortName] || [CSRUtilities belongToRGBCWDevice:deviceEntity.shortName]) {
        [[LightModelApi sharedInstance] setLevel:_deviceId level:levels[i] success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
            
        } failure:^(NSError * _Nullable error) {
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
            model.isleave = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":_deviceId}];
        }];
    }
    [[DeviceModelManager sharedInstance] colorfulAction:_deviceId timeInterval:5.0 hues:@[colorfulHues[0],colorfulHues[1],colorfulHues[2],colorfulHues[3],colorfulHues[4],colorfulHues[5]] colorSaturation:sats[i] rgbSceneId:_rgbSceneEntity.rgbSceneID];
}

#pragma mark - 修改图片

- (IBAction)changeImage:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert.view setTintColor:DARKORAGE];
    __weak MRGBSceneDetailViewController *weakself = self;
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
