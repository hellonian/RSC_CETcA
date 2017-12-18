//
//  VisualFloorDetailViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/4.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "VisualFloorDetailViewController.h"
#import "PureLayout.h"
#import "CSRDevicesManager.h"
#import "CSRBluetoothLE.h"

@interface VisualFloorDetailViewController ()<VisualControlContentViewDelegate,CSRBluetoothLEDelegate>

@end

@implementation VisualFloorDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceState:) name:@"setPowerStateSuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getAllDeviceState:) name:@"getAllDeviceState" object:nil];
}
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutView {
    [self.content disableEdit];
    self.content.delegate = self;
    self.content.controlVelocity = 1.8;
    CGSize reference = [UIScreen mainScreen].bounds.size;
    CGSize originalSize = self.content.layoutSize;
    CGFloat scale = MIN(reference.width/originalSize.width, reference.height/originalSize.height);
    self.content.bounds = CGRectMake(0, 0, originalSize.width*scale, originalSize.height*scale);
    self.content.layoutSize = self.content.bounds.size;
    [self.content adjustLightRepresentationPosition];
    
    [self.view addSubview:self.content];
    self.content.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    
    self.photoGeometry = self.content.bounds.size.width/self.content.bounds.size.height;
    if (self.photoGeometry > 1) {
        CGFloat fixH = self.view.bounds.size.height - self.view.bounds.size.width/self.photoGeometry-64;
        [self.content autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(fixH/2.0+64, 0, fixH/2.0, 0)];
    }
    else{
        [self.content autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(64, 0, 0, 0)];
    }
    
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closeClick)];
    self.navigationItem.leftBarButtonItem = close;
    
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
    self.navigationItem.rightBarButtonItem = edit;
    
}


-(void) edit {
    [self.content enableEdit];
    UIBarButtonItem *listItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(openDeviceList)];
    UIBarButtonItem *connectItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"link"] style:UIBarButtonItemStylePlain target:self action:@selector(connectLightToImageButton)];
    NSArray *items = @[connectItem,listItem];
    self.navigationItem.rightBarButtonItems = items;

}

- (void)connectLightToImageButton {
    if (self.handle) {
        __weak VisualFloorOrganizeController *weakSelf = self;
        [self fixPositionOfRepresentation];
        
        CGSize origin = self.content.bounds.size;
        if (origin.width<origin.height) {
            self.floorDelegate.layoutSize = CGSizeMake(origin.width*0.5, origin.height*0.5);
        }
        else {
            CGSize fixSize = CGSizeMake(origin.width-36*2, (origin.width-36*2)/self.photoGeometry);
            self.floorDelegate.layoutSize = fixSize;
        }
        self.floorDelegate.floorIndex = self.content.visualControlIndex;
        self.floorDelegate.floorImage = self.content.image;
        
        [self.content.subviews enumerateObjectsUsingBlock:^(UIView *subview,NSUInteger idx,BOOL *stop){
            if ([subview isKindOfClass:[ImageDropButton class]]) {
                ImageDropButton *button = (ImageDropButton *)subview;
                [self.floorDelegate.light addObject:button];
            }
        }];
        
        [self addVisualControlData:[self.floorDelegate archive] withIndex:self.content.visualControlIndex];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.handle(weakSelf.content);
        [self.content disableEdit];
        UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
        self.navigationItem.rightBarButtonItems = @[edit];

    }
}

-(void)closeClick{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - VisualControlContentView Delegate

- (void)visualControlContentViewDidClickOnLight:(NSNumber *)deviceId {

    [self.devices enumerateObjectsUsingBlock:^(DeviceModel *deviceModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([deviceModel.deviceId isEqualToNumber:deviceId]) {
            BOOL state = ![deviceModel.powerState boolValue];
            [[CSRDevicesManager sharedInstance] setPowerState:deviceId state:[NSNumber numberWithBool:state]];
        }
    }];
    
}
- (void)visualControlContentViewSendBrightnessControlTouching:(CGPoint)touchAt referencePoint:(CGPoint)origin toLight:(NSNumber *)deviceId controlState:(UIGestureRecognizerState)state {
    if (self.delegate && [self.delegate respondsToSelector:@selector(floorViewCellSendBrightnessControlTouching:referencePoint:toLight:controlState:)]) {
        [self.delegate floorViewCellSendBrightnessControlTouching:touchAt referencePoint:origin toLight:deviceId controlState:state];
    }
    
}

//获取设备状态后的回调通知
- (void)getAllDeviceState:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSNumber *deviceId = dic[@"deviceId"];
    NSNumber *level = dic[@"level"];
    NSNumber *powerState = dic[@"powerState"];
    [self.devices enumerateObjectsUsingBlock:^(DeviceModel *deviceModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([deviceModel.deviceId isEqualToNumber:deviceId]) {
            deviceModel.powerState = powerState;
            deviceModel.level = level;
            [self updateDeviceStatusss:deviceModel];
            *stop = YES;
        }
    }];
}

- (void)updateDeviceState:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *state = userInfo[@"state"];
    NSNumber *deviceId = userInfo[@"deviceId"];
    [self.devices enumerateObjectsUsingBlock:^(DeviceModel *deviceModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([deviceModel.deviceId isEqualToNumber:deviceId]) {
            deviceModel.powerState = state;
            [self updateDeviceStatusss:deviceModel];
            *stop = YES;
        }
    }];
}
- (void)updateDeviceStatusss:(DeviceModel *)deviceModel {
    [self.content updateLightPresentationWithMeshStatus:deviceModel];
}

@end
