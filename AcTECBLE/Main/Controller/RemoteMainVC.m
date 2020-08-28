//
//  RemoteMainVC.m
//  AcTECBLE
//
//  Created by AcTEC on 2019/12/16.
//  Copyright © 2019 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "RemoteMainVC.h"
#import "CSRDatabaseManager.h"
#import "CSRUtilities.h"
#import "PureLayout.h"
#import "SelectModel.h"
#import "DeviceListViewController.h"
#import <CSRmesh/DataModelApi.h>
#import "SceneViewController.h"
#import "DataModelManager.h"

#define pi 3.14159265358979323846

typedef NS_ENUM(NSInteger,MainRemoteType)
{
    MainRemoteType_RGB = 0,
    MainRemoteType_RGBCW,
    MainRemoteType_CW,
    MainRemoteType_SceneSix,
    MainRemoteType_SceneFour,
    MainRemoteType_SceneThree,
    MainRemoteType_SceneTwo,
    MainRemoteType_SceneOne
};

@interface RemoteMainVC ()<UITextFieldDelegate>
{
    BOOL editing;
    NSInteger currentAngle;
    UIGestureRecognizerState currentState;
    NSTimer *timer;
    int tapCount;
    NSInteger tapTag;
    NSData *applyCmd;
    NSInteger retryCount;
}

@property (weak, nonatomic) IBOutlet UITextField *nameTf;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (nonatomic, copy) NSString *originalName;
@property (nonatomic, assign) MainRemoteType mType;
@property (strong, nonatomic) IBOutlet UIView *nameView;
@property (strong, nonatomic) IBOutlet UIView *sceneView1;
@property (strong, nonatomic) IBOutlet UIView *sceneView2;
@property (weak, nonatomic) IBOutlet UIImageView *mainRemoteBgImageView;
@property (weak, nonatomic) IBOutlet UIImageView *sceneRemoteBgImageView;
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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyOneTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyOneLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyTwoTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyTwoRightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyThreeTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyThreeLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyFourTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyFourRightConstraint;

@property (strong, nonatomic) IBOutlet UIView *mcrView;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn24;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn25;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn26;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn27;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn28;
@property (weak, nonatomic) IBOutlet UIButton *remoteBtn29;
@property (weak, nonatomic) IBOutlet UIImageView *musicRemoteBgImageView;

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
            _remoteBtn11.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn11.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn12.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn12.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn13.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn13.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn14.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn14.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn15.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn15.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn16.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn16.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn17.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn17.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
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
            _remoteBtn11.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn11.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn12.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn12.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn13.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn13.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn14.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn14.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn15.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn15.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn16.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn16.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn17.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn17.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
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
            [_remoteBtn11 setImage:[UIImage imageNamed:@"remotebtn16_default"] forState:UIControlStateNormal];
            [_remoteBtn11 setImage:[UIImage imageNamed:@"remotebtn16_highlighted"] forState:UIControlStateHighlighted];
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
            _remoteBtn11.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn11.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn12.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn12.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn13.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn13.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn14.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn14.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn15.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn15.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn16.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn16.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            UILongPressGestureRecognizer *gesture12 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn12 addGestureRecognizer:gesture12];
            UILongPressGestureRecognizer *gesture13 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn13 addGestureRecognizer:gesture13];
            UILongPressGestureRecognizer *gesture15 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn15 addGestureRecognizer:gesture15];
            UILongPressGestureRecognizer *gesture16 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn16 addGestureRecognizer:gesture16];
        }else if ([CSRUtilities belongToSceneRemoteSixKeys:deviceEntity.shortName]) {
            _mType = MainRemoteType_SceneSix;
            if ([deviceEntity.remoteBranch length] != 36) {
                deviceEntity.remoteBranch = @"010000020000030000040000050000060000";
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            [self.view addSubview:self.sceneView2];
            [self.sceneView2 autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameView withOffset:44.0];
            [self.sceneView2 autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.sceneView2 autoSetDimensionsToSize:CGSizeMake(320, 320)];
            
            _remoteBtn18.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn18.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn19.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn19.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn20.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn20.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn21.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn21.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn22.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn22.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn23.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn23.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            
            UILongPressGestureRecognizer *gesture17 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn18 addGestureRecognizer:gesture17];
            UILongPressGestureRecognizer *gesture18 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn19 addGestureRecognizer:gesture18];
            UILongPressGestureRecognizer *gesture19 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn20 addGestureRecognizer:gesture19];
            UILongPressGestureRecognizer *gesture20 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn21 addGestureRecognizer:gesture20];
            UILongPressGestureRecognizer *gesture21 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn22 addGestureRecognizer:gesture21];
            UILongPressGestureRecognizer *gesture22 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn23 addGestureRecognizer:gesture22];
            
            
        }else if ([CSRUtilities belongToSceneRemoteFourKeys:deviceEntity.shortName]) {
            _mType = MainRemoteType_SceneFour;
            if ([deviceEntity.remoteBranch length] != 24) {
                deviceEntity.remoteBranch = @"010000020000030000040000";
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            [self.view addSubview:self.sceneView2];
            [self.sceneView2 autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameView withOffset:44.0];
            [self.sceneView2 autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.sceneView2 autoSetDimensionsToSize:CGSizeMake(320, 320)];
            
            _remoteBtn18.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn18.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn19.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn19.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn20.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn20.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn21.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn21.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            
            UILongPressGestureRecognizer *gesture17 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn18 addGestureRecognizer:gesture17];
            UILongPressGestureRecognizer *gesture18 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn19 addGestureRecognizer:gesture18];
            UILongPressGestureRecognizer *gesture19 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn20 addGestureRecognizer:gesture19];
            UILongPressGestureRecognizer *gesture20 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn21 addGestureRecognizer:gesture20];
            
            _remoteBtn22.hidden = YES;
            _remoteBtn23.hidden = YES;
            _keyThreeTopConstraint.constant = 212;
            _keyFourTopConstraint.constant = 212;
        }else if ([CSRUtilities belongToSceneRemoteThreeKeys:deviceEntity.shortName]) {
            _mType = MainRemoteType_SceneThree;
            if ([deviceEntity.remoteBranch length] != 18) {
                deviceEntity.remoteBranch = @"010000020000030000";
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            [self.view addSubview:self.sceneView2];
            [self.sceneView2 autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameView withOffset:44.0];
            [self.sceneView2 autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.sceneView2 autoSetDimensionsToSize:CGSizeMake(320, 320)];
            
            _remoteBtn18.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn18.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn19.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn19.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn20.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn20.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            
            UILongPressGestureRecognizer *gesture17 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn18 addGestureRecognizer:gesture17];
            UILongPressGestureRecognizer *gesture18 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn19 addGestureRecognizer:gesture18];
            UILongPressGestureRecognizer *gesture19 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn20 addGestureRecognizer:gesture19];
            
            _remoteBtn21.hidden = YES;
            _remoteBtn22.hidden = YES;
            _remoteBtn23.hidden = YES;
            _keyOneLeftConstraint.constant = 127;
            _keyTwoTopConstraint.constant = 133;
            _keyTwoRightConstraint.constant = 127;
            _keyThreeTopConstraint.constant = 212;
            _keyThreeLeftConstraint.constant = 127;
        }else if ([CSRUtilities belongToSceneRemoteTwoKeys:deviceEntity.shortName]) {
            _mType = MainRemoteType_SceneTwo;
            if ([deviceEntity.remoteBranch length] != 12) {
                deviceEntity.remoteBranch = @"010000020000";
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            [self.view addSubview:self.sceneView2];
            [self.sceneView2 autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameView withOffset:44.0];
            [self.sceneView2 autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.sceneView2 autoSetDimensionsToSize:CGSizeMake(320, 320)];
            
            _remoteBtn18.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn18.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn19.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn19.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            
            UILongPressGestureRecognizer *gesture17 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn18 addGestureRecognizer:gesture17];
            UILongPressGestureRecognizer *gesture18 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn19 addGestureRecognizer:gesture18];
            
            _remoteBtn20.hidden = YES;
            _remoteBtn21.hidden = YES;
            _remoteBtn22.hidden = YES;
            _remoteBtn23.hidden = YES;
            _keyOneLeftConstraint.constant = 127;
            _keyTwoTopConstraint.constant = 212;
            _keyTwoRightConstraint.constant = 127;
        }else if ([CSRUtilities belongToSceneRemoteOneKey:deviceEntity.shortName]) {
            _mType = MainRemoteType_SceneOne;
            if ([deviceEntity.remoteBranch length] != 6) {
                deviceEntity.remoteBranch = @"010000";
                [[CSRDatabaseManager sharedInstance] saveContext];
            }
            [self.view addSubview:self.sceneView2];
            [self.sceneView2 autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameView withOffset:44.0];
            [self.sceneView2 autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.sceneView2 autoSetDimensionsToSize:CGSizeMake(320, 320)];
            
            _remoteBtn18.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn18.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            
            UILongPressGestureRecognizer *gesture17 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn18 addGestureRecognizer:gesture17];
            
            _remoteBtn19.hidden = YES;
            _remoteBtn20.hidden = YES;
            _remoteBtn21.hidden = YES;
            _remoteBtn22.hidden = YES;
            _remoteBtn23.hidden = YES;
            _keyOneTopConstraint.constant = 133;
            _keyOneLeftConstraint.constant = 127;
        }else if ([CSRUtilities belongToMusicControlRemote:deviceEntity.shortName]) {
            [self.view addSubview:self.mcrView];
            [self.mcrView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameView withOffset:44.0];
            [self.mcrView autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.mcrView autoSetDimensionsToSize:CGSizeMake(320, 320)];
            _remoteBtn24.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn24.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn25.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn25.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn26.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn26.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn27.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn27.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn28.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn28.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            _remoteBtn29.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            _remoteBtn29.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            
            UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn26 addGestureRecognizer:longPressGesture];
            UILongPressGestureRecognizer *longPressGesture1 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
            [_remoteBtn27 addGestureRecognizer:longPressGesture1];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureMusicRemoteCall:) name:@"configureMusicRemoteCall" object:nil];
            
            _settingSelectMutArray = [[NSMutableArray alloc] initWithCapacity:1];
            if ([deviceEntity.remoteBranch length] == 8) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @(1);
                mod.channel = @([CSRUtilities numberWithHexString:[deviceEntity.remoteBranch substringWithRange:NSMakeRange(4, 4)]]);
                mod.deviceID = @([self exchangePositionOfDeviceIdString:[deviceEntity.remoteBranch substringWithRange:NSMakeRange(0, 4)]]);
                [_settingSelectMutArray addObject:mod];
            }else {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.channel = @(0);
                mod.deviceID = @(0);
                [_settingSelectMutArray addObject:mod];
            }
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
    if ([deviceEntity.remoteBranch length] == 40) {
        for (int i=0; i<4; i++) {
            NSString *str = [deviceEntity.remoteBranch substringWithRange:NSMakeRange(10*i, 10)];
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
        deviceEntity.remoteBranch = @"0700000000080000000009000000000a00000000";
        [[CSRDatabaseManager sharedInstance] saveContext];
    }
    
    [self.view addSubview:self.sceneView1];
    [self.sceneView1 autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameView withOffset:44.0];
    [self.sceneView1 autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.sceneView1 autoSetDimensionsToSize:CGSizeMake(320, 320)];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    [self.circleImageView addGestureRecognizer:panGesture];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [self.circleImageView addGestureRecognizer:tapGesture];
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
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if ([CSRUtilities belongToSceneRemoteSixKeys:deviceEntity.shortName]
        || [CSRUtilities belongToSceneRemoteFourKeys:deviceEntity.shortName]
        || [CSRUtilities belongToSceneRemoteThreeKeys:deviceEntity.shortName]
        || [CSRUtilities belongToSceneRemoteTwoKeys:deviceEntity.shortName]
        || [CSRUtilities belongToSceneRemoteOneKey:deviceEntity.shortName]) {
        _sceneRemoteBgImageView.image = [UIImage imageNamed:@"remotesceneeditbg"];
    }else if ([CSRUtilities belongToRGBRemote:deviceEntity.shortName]
              || [CSRUtilities belongToCWRemote:deviceEntity.shortName]
              || [CSRUtilities belongToRGBCWRemote:deviceEntity.shortName]) {
        _mainRemoteBgImageView.image = [UIImage imageNamed:@"remotemaineditbg"];
    }else if ([CSRUtilities belongToMusicControlRemote:deviceEntity.shortName]) {
        _musicRemoteBgImageView.image = [UIImage imageNamed:@"remotesceneeditbg"];
    }
}

- (void)doneAction {
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Edit", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(editAction)];
    self.navigationItem.rightBarButtonItem = edit;
    editing = NO;
    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
    if ([CSRUtilities belongToSceneRemoteSixKeys:deviceEntity.shortName]
        || [CSRUtilities belongToSceneRemoteFourKeys:deviceEntity.shortName]
        || [CSRUtilities belongToSceneRemoteThreeKeys:deviceEntity.shortName]
        || [CSRUtilities belongToSceneRemoteTwoKeys:deviceEntity.shortName]
        || [CSRUtilities belongToSceneRemoteOneKey:deviceEntity.shortName]) {
        _sceneRemoteBgImageView.image = [UIImage imageNamed:@"remotescenebg"];
    }else if ([CSRUtilities belongToRGBRemote:deviceEntity.shortName]
              || [CSRUtilities belongToCWRemote:deviceEntity.shortName]
              || [CSRUtilities belongToRGBCWRemote:deviceEntity.shortName]) {
        _mainRemoteBgImageView.image = [UIImage imageNamed:@"remotemainbg"];
    }else if ([CSRUtilities belongToMusicControlRemote:deviceEntity.shortName]) {
        _musicRemoteBgImageView.image = [UIImage imageNamed:@"remotescenebg"];
    }
}

- (IBAction)btnTouchUpInside:(UIButton *)sender {
    if (editing) {
        if (sender.tag == 7 || sender.tag == 8 || sender.tag == 9 || sender.tag == 10) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                    [alert.view setTintColor:DARKORAGE];
                    UIAlertAction *device = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Select", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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
            SceneViewController *svc = [[SceneViewController alloc] init];
            svc.forSceneRemote = YES;
            svc.keyNumber = sender.tag;
            svc.srDeviceId = _deviceId;
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
            if (deviceEntity.remoteBranch > 0) {
                svc.sceneIndex = @([self exchangePositionOfDeviceIdString:[deviceEntity.remoteBranch substringWithRange:NSMakeRange((sender.tag-1)*6+2, 4)]]);
            }else {
                svc.sceneIndex = @0;
            }
            
            svc.sceneRemoteHandle = ^(NSInteger keyNumber, NSInteger sceneIndex) {
                if (!_activityIndicator) {
                    [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
                    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                    [[UIApplication sharedApplication].keyWindow addSubview:_activityIndicator];
                    [_activityIndicator autoCenterInSuperview];
                    [_activityIndicator startAnimating];
                }
                
                Byte b[] = {};
                b[0] = (Byte)((sceneIndex & 0xFF00) >> 8);
                b[1] = (Byte)(sceneIndex & 0x00FF);
                Byte byte[] = {0x9b, 0x06, 0x01, keyNumber, b[1], b[0], 0x00, 0x00};
                NSData *cmd = [[NSData alloc] initWithBytes:byte length:8];
                [[DataModelApi sharedInstance] sendData:_deviceId data:cmd success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                    NSString *br = [CSRUtilities hexStringForData:[data subdataWithRange:NSMakeRange(3, 3)]];
                    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                    if ([deviceEntity.remoteBranch length] > 0) {
                        deviceEntity.remoteBranch = [deviceEntity.remoteBranch stringByReplacingCharactersInRange:NSMakeRange(6*(keyNumber-1), 6) withString:br];
                        [[CSRDatabaseManager sharedInstance] saveContext];
                    }
                    
                    if (_activityIndicator) {
                        [_activityIndicator stopAnimating];
                        [_activityIndicator removeFromSuperview];
                        _activityIndicator = nil;
                        [self.translucentBgView removeFromSuperview];
                        self.translucentBgView = nil;
                    }
                } failure:^(NSError * _Nonnull error) {
                    [[DataModelApi sharedInstance] sendData:_deviceId data:cmd success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                        NSString *br = [CSRUtilities hexStringForData:[data subdataWithRange:NSMakeRange(3, 3)]];
                        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                        if ([deviceEntity.remoteBranch length] > 0) {
                            deviceEntity.remoteBranch = [deviceEntity.remoteBranch stringByReplacingCharactersInRange:NSMakeRange(6*(keyNumber-1), 6) withString:br];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                        }
                        
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
                }];
            };
            [self.navigationController pushViewController:svc animated:YES];
        }else if (sender.tag == 18 || sender.tag == 19 || sender.tag == 20 || sender.tag == 21 || sender.tag == 22 || sender.tag == 23) {
            DeviceListViewController *list = [[DeviceListViewController alloc] init];
            list.selectMode = DeviceListSelectMode_MusicController;
            list.originalMembers = [NSMutableArray arrayWithObject:[_settingSelectMutArray firstObject]];
            [list getSelectedDevices:^(NSArray *devices) {
                if (!_activityIndicator) {
                    [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
                    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                    [[UIApplication sharedApplication].keyWindow addSubview:_activityIndicator];
                    [_activityIndicator autoCenterInSuperview];
                    [_activityIndicator startAnimating];
                }
                [self performSelector:@selector(configureMusicRemoteTimeOut) withObject:nil afterDelay:10.0f];
                retryCount = 0;
                if ([devices count] > 0) {
                    SelectModel *mod = devices[0];
                    
                    [_settingSelectMutArray addObject:mod];
                    
                    NSInteger sDeviceID = [mod.deviceID integerValue];
                    NSInteger d0 = (sDeviceID & 0xFF00) >> 8;
                    NSInteger d1 = sDeviceID & 0x00FF;
                    
                    NSInteger sChannel = [mod.channel integerValue];
                    
                    Byte byte[] = {0xb6, 0x07, 0x1c, 0x00, 0x01, d1, d0, sChannel/256, sChannel%256};
                    applyCmd = [[NSData alloc] initWithBytes:byte length:9];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:applyCmd];
                }else {
                    Byte byte[] = {0xb6, 0x07, 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
                    applyCmd = [[NSData alloc] initWithBytes:byte length:9];
                    [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:applyCmd];
                }
                
                
            }];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
            [self presentViewController:nav animated:YES completion:nil];
        }
    }else {
        if (tapTag == sender.tag || tapTag == 0) {
            if (tapTag==0) {
                tapTag = sender.tag;
            }
            tapCount++;
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [self performSelector:@selector(detalyTapAction) withObject:nil afterDelay:0.6f];
        }
    }
}

- (void)detalyTapAction {
    NSInteger sw = -1;
    switch (tapTag) {
        case 7:
            sw = 7;
            break;
        case 8:
            sw = 8;
            break;
        case 9:
            sw = 9;
            break;
        case 10:
            sw = 10;
            break;
        case 11:
            sw = 0;
            break;
        case 12:
            sw = 1;
            break;
        case 13:
            sw = 2;
            break;
        case 14:
            sw = 3;
            break;
        case 15:
            sw = 4;
            break;
        case 16:
            sw = 6;
            break;
        case 17:
            sw = 5;
            break;
        case 1:
            sw = 1;
            break;
        case 2:
            sw = 2;
            break;
        case 3:
            sw = 3;
            break;
        case 4:
            sw = 4;
            break;
        case 5:
            sw = 5;
            break;
        case 6:
            sw = 6;
            break;
        case 18:
            sw = 1;
            break;
        case 19:
            sw = 2;
            break;
        case 20:
            sw = 3;
            break;
        case 21:
            sw = 4;
            break;
        case 22:
            sw = 5;
            break;
        case 23:
            sw = 6;
            break;
        default:
            break;
    }
    if (sw != -1) {
        NSInteger h = (tapCount & 0xFF00) >> 8;
        NSInteger l = tapCount & 0x00FF;
        Byte byte[] = {0xb6, 0x05, 0x12, sw, 0x00, l, h};
        NSData *cmd = [[NSData alloc] initWithBytes:byte length:7];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
    }
    tapCount = 0;
    tapTag = 0;
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
            if (!_activityIndicator) {
                [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
                _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                [[UIApplication sharedApplication].keyWindow addSubview:_activityIndicator];
                [_activityIndicator autoCenterInSuperview];
                [_activityIndicator startAnimating];
            }
            SelectModel *mod = devices[0];
            [_settingSelectMutArray replaceObjectAtIndex:([mod.sourceID integerValue]-7) withObject:mod];

            NSInteger channel = [mod.channel integerValue];
            NSInteger c0 = (channel & 0xFF00) >> 8;
            NSInteger c1 = channel & 0x00FF;
            
            NSInteger sDeviceId = [mod.deviceID integerValue];
            NSInteger d0 = (sDeviceId & 0xFF00) >> 8;
            NSInteger d1 = sDeviceId & 0x00FF;
            Byte byte[] = {0x9b, 0x06, 0x01, [mod.sourceID integerValue], c1, c0, d1, d0};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:8];
            [[DataModelApi sharedInstance] sendData:_deviceId data:cmd success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                NSString *br = [CSRUtilities hexStringForData:[data subdataWithRange:NSMakeRange(3, 5)]];
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                if ([deviceEntity.remoteBranch length] == 40) {
                    deviceEntity.remoteBranch = [deviceEntity.remoteBranch stringByReplacingCharactersInRange:NSMakeRange(([mod.sourceID integerValue]-7)*10, 10) withString:br];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }

                if (_activityIndicator) {
                    [_activityIndicator stopAnimating];
                    [_activityIndicator removeFromSuperview];
                    _activityIndicator = nil;
                    [self.translucentBgView removeFromSuperview];
                    self.translucentBgView = nil;
                }
            } failure:^(NSError * _Nonnull error) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[DataModelApi sharedInstance] sendData:_deviceId data:cmd success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                        NSString *br = [CSRUtilities hexStringForData:[data subdataWithRange:NSMakeRange(3, 5)]];
                        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                        if ([deviceEntity.remoteBranch length] == 40) {
                            deviceEntity.remoteBranch = [deviceEntity.remoteBranch stringByReplacingCharactersInRange:NSMakeRange(([mod.sourceID integerValue]-1)*5, 5) withString:br];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                        }

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
                });
            }];
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
        [self cleanRemote:mod];
    }
}

- (void)cleanRemote:(SelectModel *)mod {
    Byte byte[] = {0x9b, 0x06, 0x01, [mod.sourceID integerValue], 0x00, 0x00, 0x00, 0x00};
    NSData *cmd = [[NSData alloc] initWithBytes:byte length:8];
    
    [[DataModelApi sharedInstance] sendData:_deviceId data:cmd success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
        NSString *br = [CSRUtilities hexStringForData:[data subdataWithRange:NSMakeRange(3, 5)]];
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        if ([deviceEntity.remoteBranch length] == 40) {
            deviceEntity.remoteBranch = [deviceEntity.remoteBranch stringByReplacingCharactersInRange:NSMakeRange(([mod.sourceID integerValue]-7)*10, 10) withString:br];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }

        if (_activityIndicator) {
            [_activityIndicator stopAnimating];
            [_activityIndicator removeFromSuperview];
            _activityIndicator = nil;
            [self.translucentBgView removeFromSuperview];
            self.translucentBgView = nil;
        }
    } failure:^(NSError * _Nonnull error) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[DataModelApi sharedInstance] sendData:_deviceId data:cmd success:^(NSNumber * _Nonnull deviceId, NSData * _Nonnull data) {
                NSString *br = [CSRUtilities hexStringForData:[data subdataWithRange:NSMakeRange(3, 5)]];
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
                if ([deviceEntity.remoteBranch length] == 40) {
                    deviceEntity.remoteBranch = [deviceEntity.remoteBranch stringByReplacingCharactersInRange:NSMakeRange(([mod.sourceID integerValue]-1)*10, 10) withString:br];
                    [[CSRDatabaseManager sharedInstance] saveContext];
                }

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
        });
    }];
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
    NSInteger sw = -1;
    UIView *view = gesture.view;
    switch (view.tag) {
        case 11:
            sw = 0;
            break;
        case 12:
            sw = 1;
            break;
        case 13:
            sw = 2;
            break;
        case 14:
            sw = 3;
            break;
        case 15:
            sw = 4;
            break;
        case 16:
            sw = 6;
            break;
        case 1:
            sw = 1;
            break;
        case 2:
            sw = 2;
            break;
        case 3:
            sw = 3;
            break;
        case 4:
            sw = 4;
            break;
        case 5:
            sw = 5;
            break;
        case 6:
            sw = 6;
            break;
        case 20:
            sw = 3;
            break;
        case 21:
            sw = 4;
            break;
        default:
            break;
    }
    if (sw != -1) {
        if (gesture.state == UIGestureRecognizerStateBegan) {
            Byte byte[] = {0xb6, 0x05, 0x12, sw, 0x01, 0x00, 0x00};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:7];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            [self.beganLongpressGestures addObject:@(sw)];
        }else {
            Byte byte[] = {0xb6, 0x05, 0x12, sw, 0x02, 0x00, 0x00};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:7];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
            static int i=0;
            [self checkeStopLongPressGesture:@(sw) num:i];
        }
    }
}

- (void)checkeStopLongPressGesture:(NSNumber *)sw num:(int)i {
    i++;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.beganLongpressGestures containsObject:sw] && i>10) {
            Byte byte[] = {0xb6, 0x05, 0x12, [sw integerValue], 0x02, 0x00, 0x00};
            NSData *cmd = [[NSData alloc] initWithBytes:byte length:7];
            [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:cmd];
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
            NSInteger swidx = [CSRUtilities numberWithHexString:dic[@"swidx"]];
            if ([self.beganLongpressGestures containsObject:@(swidx)]) {
                [self.beganLongpressGestures removeObject:@(swidx)];
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

- (void)configureMusicRemoteCall:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *sourceDeviceID = dic[@"deviceId"];
    if ([sourceDeviceID isEqualToNumber:_deviceId]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(configureMusicRemoteTimeOut) object:nil];
        if (_activityIndicator) {
            [_activityIndicator stopAnimating];
            [_activityIndicator removeFromSuperview];
            _activityIndicator = nil;
        }
        if (_translucentBgView) {
            [_translucentBgView removeFromSuperview];
            _translucentBgView = nil;
        }
        
        if (![dic[@"state"] boolValue]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"fail", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
            [alert.view setTintColor:DARKORAGE];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:cancel];
            [self presentViewController:alert animated:YES completion:nil];
        }else {
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
            deviceEntity.remoteBranch = [CSRUtilities hexStringForData:[applyCmd subdataWithRange:NSMakeRange(5, 4)]];
            [[CSRDatabaseManager sharedInstance] saveContext];
            NSInteger type = [[CSRUtilities hexStringForData:[applyCmd subdataWithRange:NSMakeRange(4, 1)]] integerValue];
            if (type == 0) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.channel = @(0);
                mod.deviceID = @(0);
                [_settingSelectMutArray replaceObjectAtIndex:0 withObject:mod];
            }else if (type == 1) {
                SelectModel *mod = [[SelectModel alloc] init];
                mod.sourceID = @(1);
                mod.channel = @([CSRUtilities numberWithHexString:[deviceEntity.remoteBranch substringWithRange:NSMakeRange(4, 4)]]);
                mod.deviceID = @([self exchangePositionOfDeviceIdString:[deviceEntity.remoteBranch substringWithRange:NSMakeRange(0, 4)]]);
                [_settingSelectMutArray replaceObjectAtIndex:0 withObject:mod];
            }
        }
    }
}

- (void)configureMusicRemoteTimeOut {
    if (retryCount < 1) {
        retryCount ++;
        [self performSelector:@selector(configureMusicRemoteTimeOut) withObject:nil afterDelay:10.0f];
        [[DataModelManager shareInstance] sendDataByBlockDataTransfer:_deviceId data:applyCmd];
    }else {
        if (_activityIndicator) {
            [_activityIndicator stopAnimating];
            [_activityIndicator removeFromSuperview];
            _activityIndicator = nil;
        }
        if (_translucentBgView) {
            [_translucentBgView removeFromSuperview];
            _translucentBgView = nil;
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:AcTECLocalizedStringFromTable(@"TimeOut", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setTintColor:DARKORAGE];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"OK", @"Localizable") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end