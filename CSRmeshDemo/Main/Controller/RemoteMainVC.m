//
//  RemoteMainVC.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/12/16.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "RemoteMainVC.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import "PureLayout.h"
#import "SelectModel.h"
#import "DeviceListViewController.h"
#import <CSRmesh/DataModelApi.h>

#define pi 3.14159265358979323846

typedef NS_ENUM(NSInteger,MainRemoteType)
{
    MainRemoteType_RGB = 0,
    MainRemoteType_RGBCW,
    MainRemoteType_CW,
    MainRemoteType_Scene
};

@interface RemoteMainVC ()<UITextFieldDelegate>
{
    BOOL editing;
    NSInteger currentAngle;
    UIGestureRecognizerState currentState;
    NSTimer *timer;
}

@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (nonatomic, copy) NSString *originalName;
@property (nonatomic, assign) MainRemoteType mType;
@property (strong, nonatomic) IBOutlet UIView *nameView;
@property (strong, nonatomic) IBOutlet UIView *sceneView1;
@property (strong, nonatomic) IBOutlet UIView *sceneView2;
@property (weak, nonatomic) IBOutlet UIImageView *circleImageView;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn11;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn12;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn13;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn14;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn15;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn16;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn17;
@property (nonatomic, strong) NSMutableArray *settingSelectMutArray;
@property (nonatomic, strong) UIView *translucentBgView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn18;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn19;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn20;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn21;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn22;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn23;
@property (nonatomic, strong) NSMutableArray *beganLongpressGestures;

@end

@implementation RemoteMainVC

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
    
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(editAction)];
    self.navigationItem.rightBarButtonItem = edit;
    
    if (_deviceId) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlRemoteButtonCall:) name:@"controlRemoteButtonCall" object:nil];
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        self.navigationItem.title = deviceEntity.name;
        self.nameTf.delegate = self;
        self.nameTf.text = deviceEntity.name;
        self.originalName = deviceEntity.name;
        NSString *macAddr = [deviceEntity.uuid substringFromIndex:24];
        NSString *doneTitle = @"";
        int count = 0;
        for (int i = 0; i<macAddr.length; i++) {
            count ++;
            doneTitle = [doneTitle stringByAppendingString:[macAddr substringWithRange:NSMakeRange(i, 1)]];
            if (count == 2 && i<macAddr.length-1) {
                doneTitle = [NSString stringWithFormat:@"%@:", doneTitle];
                count = 0;
            }
        }
        self.macAddressLabel.text = doneTitle;
        
        if ([CSRUtilities belongToRGBCWRemote:deviceEntity.shortName]) {
            _mType = MainRemoteType_RGBCW;
            [self prepare1:deviceEntity];
            _circleImageView.image = [UIImage imageNamed:@"remotecirclergb"];
            [_remoteBtn11 setImage:[UIImage imageNamed:@"remotebtn0_default"] forState:UIControlStateNormal];
            [_remoteBtn11 setImage:[UIImage imageNamed:@"remotebtn0_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn12 setImage:[UIImage imageNamed:@"remotebtn1_default"] forState:UIControlStateNormal];
            [_remoteBtn12 setImage:[UIImage imageNamed:@"remotebtn1_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn13 setImage:[UIImage imageNamed:@"remotebtn2_default"] forState:UIControlStateNormal];
            [_remoteBtn13 setImage:[UIImage imageNamed:@"remotebtn2_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn14 setImage:[UIImage imageNamed:@"remotebtn3_default"] forState:UIControlStateNormal];
            [_remoteBtn14 setImage:[UIImage imageNamed:@"remotebtn3_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn15 setImage:[UIImage imageNamed:@"remotebtn4_default"] forState:UIControlStateNormal];
            [_remoteBtn15 setImage:[UIImage imageNamed:@"remotebtn4_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn16 setImage:[UIImage imageNamed:@"remotebtn6_default"] forState:UIControlStateNormal];
            [_remoteBtn16 setImage:[UIImage imageNamed:@"remotebtn6_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn17 setImage:[UIImage imageNamed:@"remotebtn5_default"] forState:UIControlStateNormal];
            [_remoteBtn17 setImage:[UIImage imageNamed:@"remotebtn5_highlighted"] forState:UIControlStateHighlighted];
            UILongPressGestureRecognizer *gesture11 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn11 addGestureRecognizer:gesture11];
            UILongPressGestureRecognizer *gesture12 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn12 addGestureRecognizer:gesture12];
            UILongPressGestureRecognizer *gesture13 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn13 addGestureRecognizer:gesture13];
            UILongPressGestureRecognizer *gesture14 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn14 addGestureRecognizer:gesture14];
        }else if ([CSRUtilities belongToRGBRemote:deviceEntity.shortName]) {
            _mType = MainRemoteType_RGB;
            [self prepare1:deviceEntity];
            _circleImageView.image = [UIImage imageNamed:@"remotecirclergb"];
            [_remoteBtn11 setImage:[UIImage imageNamed:@"remotebtn11_default"] forState:UIControlStateNormal];
            [_remoteBtn11 setImage:[UIImage imageNamed:@"remotebtn11_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn12 setImage:[UIImage imageNamed:@"remotebtn12_default"] forState:UIControlStateNormal];
            [_remoteBtn12 setImage:[UIImage imageNamed:@"remotebtn12_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn13 setImage:[UIImage imageNamed:@"remotebtn13_default"] forState:UIControlStateNormal];
            [_remoteBtn13 setImage:[UIImage imageNamed:@"remotebtn13_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn14 setImage:[UIImage imageNamed:@"remotebtn1_default"] forState:UIControlStateNormal];
            [_remoteBtn14 setImage:[UIImage imageNamed:@"remotebtn1_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn15 setImage:[UIImage imageNamed:@"remotebtn2_default"] forState:UIControlStateNormal];
            [_remoteBtn15 setImage:[UIImage imageNamed:@"remotebtn2_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn16 setImage:[UIImage imageNamed:@"remotebtn0_default"] forState:UIControlStateNormal];
            [_remoteBtn16 setImage:[UIImage imageNamed:@"remotebtn0_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn17 setImage:[UIImage imageNamed:@"remotebtn5_default"] forState:UIControlStateNormal];
            [_remoteBtn17 setImage:[UIImage imageNamed:@"remotebtn5_highlighted"] forState:UIControlStateHighlighted];
            UILongPressGestureRecognizer *gesture14 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn14 addGestureRecognizer:gesture14];
            UILongPressGestureRecognizer *gesture15 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn15 addGestureRecognizer:gesture15];
            UILongPressGestureRecognizer *gesture16 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn16 addGestureRecognizer:gesture16];
        }else if ([CSRUtilities belongToCWRemote:deviceEntity.shortName]) {
            _mType = MainRemoteType_CW;
            [self prepare1:deviceEntity];
            _circleImageView.image = [UIImage imageNamed:@"remotecirclecw"];
            [_remoteBtn11 setImage:[UIImage imageNamed:@"remotebtn5_default"] forState:UIControlStateNormal];
            [_remoteBtn11 setImage:[UIImage imageNamed:@"remotebtn5_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn12 setImage:[UIImage imageNamed:@"remotebtn14_default"] forState:UIControlStateNormal];
            [_remoteBtn12 setImage:[UIImage imageNamed:@"remotebtn14_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn13 setImage:[UIImage imageNamed:@"remotebtn1_default"] forState:UIControlStateNormal];
            [_remoteBtn13 setImage:[UIImage imageNamed:@"remotebtn1_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn14 setImage:[UIImage imageNamed:@"remotebtn6_default"] forState:UIControlStateNormal];
            [_remoteBtn14 setImage:[UIImage imageNamed:@"remotebtn6_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn15 setImage:[UIImage imageNamed:@"remotebtn15_default"] forState:UIControlStateNormal];
            [_remoteBtn15 setImage:[UIImage imageNamed:@"remotebtn15_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn16 setImage:[UIImage imageNamed:@"remotebtn2_default"] forState:UIControlStateNormal];
            [_remoteBtn16 setImage:[UIImage imageNamed:@"remotebtn2_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn17 removeFromSuperview];
            UILongPressGestureRecognizer *gesture12 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn12 addGestureRecognizer:gesture12];
            UILongPressGestureRecognizer *gesture13 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn13 addGestureRecognizer:gesture13];
            UILongPressGestureRecognizer *gesture15 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn15 addGestureRecognizer:gesture15];
            UILongPressGestureRecognizer *gesture16 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn16 addGestureRecognizer:gesture16];
        }else if ([CSRUtilities belongToSceneRemote:deviceEntity.shortName]) {
            _mType = MainRemoteType_Scene;
            [self prepare2:deviceEntity];
            [_remoteBtn18 setImage:[UIImage imageNamed:@"remotebtn16_default"] forState:UIControlStateNormal];
            [_remoteBtn18 setImage:[UIImage imageNamed:@"remotebtn16_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn19 setImage:[UIImage imageNamed:@"remotebtn17_default"] forState:UIControlStateNormal];
            [_remoteBtn19 setImage:[UIImage imageNamed:@"remotebtn17_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn20 setImage:[UIImage imageNamed:@"remotebtn18_default"] forState:UIControlStateNormal];
            [_remoteBtn20 setImage:[UIImage imageNamed:@"remotebtn18_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn21 setImage:[UIImage imageNamed:@"remotebtn19_default"] forState:UIControlStateNormal];
            [_remoteBtn21 setImage:[UIImage imageNamed:@"remotebtn19_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn22 setImage:[UIImage imageNamed:@"remotebtn20_default"] forState:UIControlStateNormal];
            [_remoteBtn22 setImage:[UIImage imageNamed:@"remotebtn20_highlighted"] forState:UIControlStateHighlighted];
            [_remoteBtn23 setImage:[UIImage imageNamed:@"remotebtn21_default"] forState:UIControlStateNormal];
            [_remoteBtn23 setImage:[UIImage imageNamed:@"remotebtn21_highlighted"] forState:UIControlStateHighlighted];
        }
    }
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

- (void)prepare1:(CSRDeviceEntity *)deviceEntity {
    _settingSelectMutArray = [[NSMutableArray alloc] initWithCapacity:4];
    if ([deviceEntity.remoteBranch length] >= 46) {
        for (int i=0; i<4; i++) {
            NSString *str = [deviceEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
            SelectModel *mod = [[SelectModel alloc] init];
            mod.sourceID = @([CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]]);
            mod.channel = @([self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]]);
            mod.deviceID = @([self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]]);
            [_settingSelectMutArray insertObject:mod atIndex:i];
        }
    }else {
        for (int i=0; i<4; i++) {
            SelectModel *mod = [[SelectModel alloc] init];
            mod.sourceID = @(i+7);
            mod.channel = @(0);
            mod.deviceID = @(0);
            [_settingSelectMutArray insertObject:mod atIndex:i];
        }
    }
    
    [self.view addSubview:self.sceneView1];
    [self.sceneView1 autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.sceneView1 autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.sceneView1 autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameView withOffset:44.0];
    [self.sceneView1 autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.sceneView1 withMultiplier:376/320.0];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    [self.circleImageView addGestureRecognizer:panGesture];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [self.circleImageView addGestureRecognizer:tapGesture];
}

- (void)prepare2:(CSRDeviceEntity *)deviceEntity {
    _settingSelectMutArray = [[NSMutableArray alloc] initWithCapacity:6];
    if ([deviceEntity.remoteBranch length] >= 66) {
        for (int i=0; i<6; i++) {
            NSString *str = [deviceEntity.remoteBranch substringWithRange:NSMakeRange(10*i+6, 10)];
            SelectModel *mod = [[SelectModel alloc] init];
            mod.sourceID = @([CSRUtilities numberWithHexString:[str substringWithRange:NSMakeRange(0, 2)]]);
            mod.channel = @([self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(2, 4)]]);
            mod.deviceID = @([self exchangePositionOfDeviceIdString:[str substringWithRange:NSMakeRange(6, 4)]]);
            [_settingSelectMutArray insertObject:mod atIndex:i];
        }
    }else {
        for (int i=0; i<6; i++) {
            SelectModel *mod = [[SelectModel alloc] init];
            mod.sourceID = @(i+1);
            mod.channel = @(0);
            mod.deviceID = @(0);
            [_settingSelectMutArray insertObject:mod atIndex:i];
        }
    }
    
    [self.view addSubview:self.sceneView2];
    [self.sceneView2 autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.sceneView2 autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.sceneView2 autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameView withOffset:44.0];
    [self.sceneView2 autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.sceneView2 withMultiplier:376/320.0];
}

- (NSInteger)exchangePositionOfDeviceIdString:(NSString *)deviceIdString {
    NSString *str11 = [deviceIdString substringToIndex:2];
    NSString *str22 = [deviceIdString substringFromIndex:2];
    NSString *deviceIdStr = [NSString stringWithFormat:@"%@%@",str22,str11];
    NSInteger deviceIdInt = [CSRUtilities numberWithHexString:deviceIdStr];
    return deviceIdInt;
}

- (void)editAction {
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = done;
    editing = YES;
}

- (void)doneAction {
    if (!_activityIndicator) {
        [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [[UIApplication sharedApplication].keyWindow addSubview:_activityIndicator];
        [_activityIndicator autoCenterInSuperview];
        [_activityIndicator startAnimating];
    }
    
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(editAction)];
    self.navigationItem.rightBarButtonItem = edit;
    editing = NO;
    
    NSString *cmd;
    if (_mType == MainRemoteType_RGBCW
        || _mType == MainRemoteType_RGB
        || _mType == MainRemoteType_CW) {
        cmd = @"9b1504";
    }else if (_mType == MainRemoteType_Scene) {
        cmd = @"9b1f06";
    }
    for (SelectModel *mod in _settingSelectMutArray) {
        NSString *sw = [CSRUtilities stringWithHexNumber:[mod.sourceID integerValue]];
        NSString *rc = [CSRUtilities exchangePositionOfDeviceId:[mod.channel integerValue]];
        NSString *dst = [CSRUtilities exchangePositionOfDeviceId:[mod.deviceID integerValue]];
        cmd = [NSString stringWithFormat:@"%@%@%@%@",cmd,sw,rc,dst];
    }
    
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:cmd] success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        deviceEntity.remoteBranch = cmd;
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        if (_activityIndicator) {
            [_activityIndicator stopAnimating];
            [_activityIndicator removeFromSuperview];
            _activityIndicator = nil;
            [self.translucentBgView removeFromSuperview];
            self.translucentBgView = nil;
        }
    } failure:^(NSError * _Nonnull error) {
        if (_activityIndicator) {
            [_activityIndicator stopAnimating];
            [_activityIndicator removeFromSuperview];
            _activityIndicator = nil;
            [self.translucentBgView removeFromSuperview];
            self.translucentBgView = nil;
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"%@: %@",AcTECLocalizedStringFromTable(@"Error", @"Localizable"),AcTECLocalizedStringFromTable(@"notRespond", @"Localizable")] preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (IBAction)btnTouchUpInside:(UIButton *)sender {
    if (editing) {
        if (sender.tag == 7 || sender.tag == 8 || sender.tag == 9 || sender.tag == 10) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                    [alert.view setTintColor:DARKORAGE];
                    UIAlertAction *device = [UIAlertAction actionWithTitle:@"Select Device" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self selectDevice:sender];
                    }];
                    UIAlertAction *clear = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Clear", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self cleanRemoteButton:sender];
                    }];
                    UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        
                    }];
                    [alert addAction:device];
                    [alert addAction:clear];
                    [alert addAction:cancel];
                    
                    alert.popoverPresentationController.sourceRect = sender.bounds;
                    alert.popoverPresentationController.sourceView = sender;
                    
                    [self presentViewController:alert animated:YES completion:nil];
        }else if (sender.tag == 1 || sender.tag == 2 || sender.tag == 3 || sender.tag == 4 || sender.tag == 5 || sender.tag == 6) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [alert.view setTintColor:DARKORAGE];
            UIAlertAction *lamp = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ControlLamp", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                [self selectDevice:sender deviceListSelectMode:DeviceListSelectMode_Single];
                
            }];
            UIAlertAction *group = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ControlGroup", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                [self selectDevice:sender deviceListSelectMode:DeviceListSelectMode_SelectGroup];
                
            }];
            UIAlertAction *scene = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"ControlScene", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                [self selectDevice:sender deviceListSelectMode:DeviceListSelectMode_SelectScene];
                
            }];
            UIAlertAction *clear = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Clear", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                [self cleanRemoteButton:sender];
                
            }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alert addAction:lamp];
            [alert addAction:group];
            [alert addAction:scene];
            [alert addAction:clear];
            [alert addAction:cancel];
            
            alert.popoverPresentationController.sourceRect = sender.bounds;
            alert.popoverPresentationController.sourceView = sender;
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }else {
        NSString *sw;
        switch (sender.tag) {
            case 7:
                sw = @"07";
                break;
            case 8:
                sw = @"08";
                break;
            case 9:
                sw = @"09";
                break;
            case 10:
                sw = @"0a";
                break;
            case 11:
                sw = @"00";
                break;
            case 12:
                sw = @"01";
                break;
            case 13:
                sw = @"02";
                break;
            case 14:
                sw = @"03";
                break;
            case 15:
                sw = @"04";
                break;
            case 16:
                sw = @"06";
                break;
            case 17:
                sw = @"05";
                break;
            case 1:
                sw = @"01";
                break;
            case 2:
                sw = @"02";
                break;
            case 3:
                sw = @"03";
                break;
            case 4:
                sw = @"04";
                break;
            case 5:
                sw = @"05";
                break;
            case 6:
                sw = @"06";
                break;
            default:
                break;
        }
        if (sw) {
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"b60512%@000100",sw]] success:nil failure:nil];
        }
    }
}

- (void)selectDevice:(UIButton *)sender {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    if (_mType == MainRemoteType_RGBCW) {
        list.selectMode = DeviceListSelectMode_SelectRGBCWDevice;
    }else if (_mType == MainRemoteType_RGB) {
        list.selectMode = DeviceListSelectMode_SelectRGBDevice;
    }else if (_mType == MainRemoteType_CW) {
        list.selectMode = DeviceListSelectMode_SelectCWDevice;
    }
    list.sourceID = @(sender.tag);
    list.originalMembers = [NSMutableArray arrayWithObject:[_settingSelectMutArray objectAtIndex:sender.tag-7]];
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count]>0) {
            SelectModel *mod = devices[0];
            [_settingSelectMutArray replaceObjectAtIndex:([mod.sourceID integerValue]-7) withObject:mod];
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)selectDevice:(UIButton *)sender deviceListSelectMode:(DeviceListSelectMode)selectMode {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = selectMode;
    list.sourceID = @(sender.tag);
    list.originalMembers = [NSArray arrayWithObject:[_settingSelectMutArray objectAtIndex:sender.tag-1]];
    [list getSelectedDevices:^(NSArray *devices) {
        if ([devices count]>0) {
            SelectModel *mod = devices[0];
            [_settingSelectMutArray replaceObjectAtIndex:([mod.sourceID integerValue]-1) withObject:mod];
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)cleanRemoteButton:(UIButton *)sender {
    if (_mType == MainRemoteType_RGBCW
        || _mType == MainRemoteType_RGB
        || _mType == MainRemoteType_CW) {
        SelectModel *mod = [_settingSelectMutArray objectAtIndex:sender.tag-7];
        mod.deviceID = @(0);
        mod.channel = @(0);
    }else if (_mType == MainRemoteType_Scene) {
        SelectModel *mod = [_settingSelectMutArray objectAtIndex:sender.tag-1];
        mod.deviceID = @(0);
        mod.channel = @(0);
    }
}

- (UIView *)translucentBgView {
    if (!_translucentBgView) {
        _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _translucentBgView.backgroundColor = [UIColor blackColor];
        _translucentBgView.alpha = 0.4;
    }
    return _translucentBgView;
}

- (NSMutableArray *)beganLongpressGestures {
    if (!_beganLongpressGestures) {
        _beganLongpressGestures = [[NSMutableArray alloc] init];
    }
    return _beganLongpressGestures;
}

- (void)longpressAction:(UILongPressGestureRecognizer *)gesture {
    NSString *sw;
    UIView *view = gesture.view;
    switch (view.tag) {
        case 11:
            sw = @"00";
            break;
        case 12:
            sw = @"01";
            break;
        case 13:
            sw = @"02";
            break;
        case 14:
            sw = @"03";
            break;
        case 15:
            sw = @"04";
            break;
        case 16:
            sw = @"06";
            break;
        default:
            break;
    }
    if (sw) {
        switch (gesture.state) {
            case UIGestureRecognizerStateBegan:
                [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"b60512%@010000",sw]] success:nil failure:nil];
                [self.beganLongpressGestures addObject:sw];
                break;
            case UIGestureRecognizerStateEnded:
                [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"b60512%@020000",sw]] success:nil failure:nil];
                static int i=0;
                [self checkeStopLongPressGesture:sw num:i];
                break;
            default:
                break;
        }
    }
}

- (void)checkeStopLongPressGesture:(NSString *)sw num:(int)i {
    i++;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.beganLongpressGestures containsObject:sw] && i<11) {
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"b60512%@020000",sw]] success:nil failure:nil];
            [self checkeStopLongPressGesture:sw num:i];
        }
    });
}

- (void)controlRemoteButtonCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        NSString *swtype = dic[@"swtype"];
        if ([swtype isEqualToString:@"02"]) {
            NSString *swidx = dic[@"swidx"];
            if ([self.beganLongpressGestures containsObject:swidx]) {
                [self.beganLongpressGestures removeObject:swidx];
            }
        }
    }
}

- (void)panGestureAction:(UIPanGestureRecognizer *)gesture {
    CGPoint touchPoint = [gesture locationInView:self.sceneView1];
    CGPoint center = self.circleImageView.center;
    if (!editing) {
        CGFloat a = touchPoint.x-center.x;
        CGFloat b = touchPoint.y-center.y;
        CGFloat d = -center.y;
        CGFloat rads = acos((b*d) / ((sqrt(a*a + b*b)) * (sqrt(d*d))));
        if (touchPoint.x<center.x) {
            rads = 2*pi-rads;
        }
        NSInteger ang = 180*rads/pi;
        currentAngle = ang;
        currentState = gesture.state;
        if (gesture.state == UIGestureRecognizerStateBegan) {
            timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(timerMethord:) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        }
    }
}

- (void)timerMethord:(NSTimer *)mTimer {
    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"b605120b03%@",[CSRUtilities exchangePositionOfDeviceId:currentAngle]]] success:nil failure:nil];
    if (currentState == UIGestureRecognizerStateEnded) {
        if (timer) {
            [timer invalidate];
            timer = nil;
        }
    }
}

- (void)tapGestureAction:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGPoint touchPoint = [gesture locationInView:self.sceneView1];
        CGPoint center = self.circleImageView.center;
        if (!editing) {
            CGFloat a = touchPoint.x-center.x;
            CGFloat b = touchPoint.y-center.y;
            CGFloat d = -center.y;
            CGFloat rads = acos((b*d) / ((sqrt(a*a + b*b)) * (sqrt(d*d))));
            if (touchPoint.x<center.x) {
                rads = 2*pi-rads;
            }
            NSInteger ang = 180*rads/pi;
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"b605120b03%@",[CSRUtilities exchangePositionOfDeviceId:ang]]] success:nil failure:nil];
        }
    }
}

@end
