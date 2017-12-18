//
//  FloorViewController.m
//  BluetoothTest
//
//  Created by hua on 9/2/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "FloorViewController.h"
#import "PureLayout.h"
#import "ControlMaskView.h"
#import "Floor.h"
#import "ImageDropButton.h"
#import "ImproveTouchingExperience.h"
#import "FloorViewCell.h"

#import "CSRmeshDevice.h"
#import "CSRDevicesManager.h"
#import "CSRAppStateManager.h"
#import "VisualFloorDetailViewController.h"
#import "CSRDeviceEntity.h"
#import "DeviceModel.h"
#import "CSRBluetoothLE.h"

@interface FloorViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,FloorViewCellDelegate,DetailViewDelegate,CSRBluetoothLEDelegate>
@property (nonatomic,strong) UICollectionView *house;
@property (nonatomic,strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic,strong) NSMutableArray *gallery;
@property (nonatomic,strong) ControlMaskView *maskLayer;
@property (nonatomic,assign) NSInteger originalBrightness;
//flow layout
@property (nonatomic,strong) UIPinchGestureRecognizer *scaleDetect;
@property (nonatomic,assign) BOOL allowEdit;
@property (nonatomic,strong) NSMutableDictionary *primaryLayoutSize;
@property (nonatomic,assign) CGFloat sectionH;
@property (nonatomic,assign) BOOL isChanged;
//
@property (nonatomic,assign) CGPoint originalContentOffset;
@property (nonatomic,strong) ImproveTouchingExperience *improver;

@property (nonatomic,strong) NSMutableDictionary *intervalMap;
@property (nonatomic,strong) NSMutableArray *devices;

@end

@implementation FloorViewController

static NSString * const reuseIdentifier = @"FloorViewCell";

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgImage"]];
    imageView.frame = [UIScreen mainScreen].bounds;
    [self.view addSubview:imageView];
    self.improver = [[ImproveTouchingExperience alloc] init];
    [self loadVisualControlProfile];
    [self configureCollectionView];
    [self prepareGestureRecognizer];
    [self prepareAllDeviceState];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getAllDeviceState:) name:@"getAllDeviceState" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceState:) name:@"setPowerStateSuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(physicalButtonActionCall:) name:@"physicalButtonActionCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(quanguanquankai:) name:@"quanguanquankai" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [self endAdjustingFlowLayout];

}

- (void)configureCollectionView {
    self.flowLayout = [[UICollectionViewFlowLayout alloc]init];
    self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    self.house = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 64, WIDTH, HEIGHT-64-50) collectionViewLayout:self.flowLayout];
    self.house.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.house];
    
    [self.house registerNib:[UINib nibWithNibName:reuseIdentifier bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    self.house.delegate = self;
    self.house.dataSource = self;
}

- (void)prepareGestureRecognizer {
    self.scaleDetect = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(changeCellSize:)];
    [self.view addGestureRecognizer:self.scaleDetect];
    
}

//获取所有设备的状态
- (void)prepareAllDeviceState {
    NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
    if (mutableArray != nil || [mutableArray count] != 0) {
        for (CSRDeviceEntity *deviceEntity in mutableArray) {
            DeviceModel *deviceModel = [[DeviceModel alloc] init];
            deviceModel.deviceId = deviceEntity.deviceId;
            deviceModel.name = deviceEntity.name;
            deviceModel.shortName = deviceEntity.shortName;
            [self.devices addObject:deviceModel];
        }
    }
    
    [[LightModelApi sharedInstance] getState:@(0) success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
        
    } failure:^(NSError * _Nullable error) {
        
    }];
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
            [self updateDeviceStatus:deviceModel];
            *stop = YES;
        }
    }];
}
//开光灯后的状态
- (void)updateDeviceState:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *state = userInfo[@"state"];
    NSNumber *deviceId = userInfo[@"deviceId"];
    [self.devices enumerateObjectsUsingBlock:^(DeviceModel *deviceModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([deviceModel.deviceId isEqualToNumber:deviceId]) {
            deviceModel.powerState = state;
            [self updateDeviceStatus:deviceModel];
            *stop = YES;
        }
    }];
}

//实物按钮控制后的反馈
- (void)physicalButtonActionCall: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *state = userInfo[@"powerState"];
    NSNumber *deviceId = userInfo[@"deviceId"];
    NSNumber *level = userInfo[@"level"];
    if ([deviceId isEqualToNumber:@(32770)]) {
        NSLog(@"powerState >> %@",state);
    }
    [self.devices enumerateObjectsUsingBlock:^(DeviceModel *deviceModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([deviceModel.deviceId isEqualToNumber:deviceId]) {
            deviceModel.powerState = @([state boolValue]);
            deviceModel.level = level;
            [self updateDeviceStatus:deviceModel];
            *stop = YES;
        }
    }];
}

//全关全开后的反馈
- (void)quanguanquankai:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *state = userInfo[@"allPowerState"];
    [self.devices enumerateObjectsUsingBlock:^(DeviceModel *deviceModel, NSUInteger idx, BOOL * _Nonnull stop) {
        deviceModel.powerState = state;
        [self updateDeviceStatus:deviceModel];
    }];
}

//获取数据
- (void)loadVisualControlProfile {
    
    NSDictionary *list = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"com.actec.bluetooth.visualControlKey"];
    
    for (NSString *key in list.allKeys) {
        Floor *floor = [Floor unArchiveData:[list objectForKey:key]];  //model
        VisualControlContentView *content = [[VisualControlContentView alloc] initWithFrame:CGRectMake(0, 0, floor.layoutSize.width, floor.layoutSize.height)];
        content.layoutSize = floor.layoutSize;
        content.visualControlIndex = key;
        content.image = floor.floorImage;
        
        for (ImageDropButton *button in floor.light) {
            [content addLightRepresentation:button];
            [content adjustLightRepresentationPosition];
        }
        
        [self.gallery addObject:content];
    }
}

#pragma mark - Virtual

- (void)popVirtualFloor {
    [self.gallery removeAllObjects];
    [self loadVisualControlProfile];
    [self.house reloadData];
}

- (void)prepareVirtualFloor {
    [self.gallery removeAllObjects];
    [self.house reloadData];
}

#pragma mark - Public

- (void)insertVisualControlGallery:(VisualControlContentView*)gallery {
    [self.gallery addObject:gallery];
    [self.house reloadData];
}

- (void)replaceVisualControlGallery {
    [self.gallery removeAllObjects];
    [self loadVisualControlProfile];
    [self.house reloadData];
}

//开始编辑
- (void)beginAdjustingFlowLayout {
    self.allowEdit = YES;
    self.isChanged = NO;
    
    [self.house.visibleCells enumerateObjectsUsingBlock:^(FloorViewCell *cell,NSUInteger idx,BOOL *stop){
        [cell showDeleteButton:YES];
    }];
}

//结束编辑
- (void)endAdjustingFlowLayout {
    self.allowEdit = NO;
    
    [self.house.visibleCells enumerateObjectsUsingBlock:^(FloorViewCell *cell,NSUInteger idx,BOOL *stop){
        [cell showDeleteButton:NO];
    }];
    
    //update profile
    if (self.isChanged) {
        for (VisualControlContentView *content in self.gallery) {
            Floor *floor = [[Floor alloc] init];
            floor.floorImage = content.image;
            floor.layoutSize = content.layoutSize;
            
            [content.subviews enumerateObjectsUsingBlock:^(UIView *subview,NSUInteger idx,BOOL *stop){
                if ([subview isKindOfClass:[ImageDropButton class]]) {
                    [floor.light addObject:(ImageDropButton*)subview];
                }
            }];
            [self addVisualControlData:[floor archive] withIndex:content.visualControlIndex];
        }
    }
}

- (void)addVisualControlData:(NSData*)data withIndex:(nonnull NSString *)index {
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    NSDictionary *record = [center dictionaryForKey:@"com.actec.bluetooth.visualControlKey"];
    
    if (record) {
        NSMutableDictionary *updated = [[NSMutableDictionary alloc] initWithDictionary:record];
        [updated setObject:data forKey:index];
        
        [center setObject:updated forKey:@"com.actec.bluetooth.visualControlKey"];
        return;
    }
    [center setObject:@{index:data} forKey:@"com.actec.bluetooth.visualControlKey"];
}

- (void)terminateAdjustingFlowLayout {
    self.allowEdit = NO;
    
    [self.house.visibleCells enumerateObjectsUsingBlock:^(FloorViewCell *cell,NSUInteger idx,BOOL *stop){
        [cell showDeleteButton:NO];
    }];
}

#pragma mark - Adjust Flow Layout

//编辑状态下改变首页照片大小
- (void)changeCellSize:(UIPinchGestureRecognizer*)sender {
    
    if (self.allowEdit) {
        //
        switch (sender.state) {
            case UIGestureRecognizerStateBegan:
            {
                [self.primaryLayoutSize removeAllObjects];
                CGRect pinchRegion = [self regionOfPinch:sender];
                __block FloorViewCell *pinchedCell = nil;
                
                [self.house.visibleCells enumerateObjectsUsingBlock:^(FloorViewCell *cell,NSUInteger idx,BOOL *stop){
                    if (CGRectContainsPoint(pinchRegion, cell.center)) {
                        pinchedCell = cell;
                        *stop = YES;
                    }
                }];
                
                if (pinchedCell) {
                    self.sectionH = pinchedCell.center.y;
                    
                    for (NSIndexPath *path in [self indexPathOfCellInSameRow:pinchedCell.center.y]) {
                        VisualControlContentView *content = self.gallery[path.row];
                        [self.primaryLayoutSize setObject:[NSValue valueWithCGSize:content.layoutSize] forKey:path];
                    }
                }
                break;
            }
            case UIGestureRecognizerStateChanged:
            {
                if (self.primaryLayoutSize.count>0) {
                    self.isChanged = YES;
                    
                    for (NSIndexPath *path in self.primaryLayoutSize.allKeys) {
                        NSValue *sizeValue = [self.primaryLayoutSize objectForKey:path];
                        
                        VisualControlContentView *content = self.gallery[path.row];
                        CGSize originSize = [sizeValue CGSizeValue];
                        CGFloat originRatio = originSize.height/originSize.width;
                        //constrain size
                        CGFloat limitW = self.house.bounds.size.width-74;    //magic number
                        CGFloat fixW = MIN(originSize.width*sender.scale, limitW);
                        content.layoutSize = CGSizeMake(fixW, fixW*originRatio);
                    }
                    
                    [self.house reloadData];
                }
                break;
            }
            default:
                [self.primaryLayoutSize removeAllObjects];
                break;
        }
    }
}

- (CGRect)regionOfPinch:(UIPinchGestureRecognizer*)sender {
    if ([sender numberOfTouches] == 2) {
        CGPoint pointA = [sender locationOfTouch:0 inView:self.view];
        CGPoint pointB = [sender locationOfTouch:1 inView:self.view];
        
        return CGRectMake(MIN(pointA.x, pointB.x), MIN(pointA.y, pointB.y), ABS(pointB.x-pointA.x), ABS(pointB.y-pointA.y));
    }
    return CGRectZero;
}

- (NSArray*)indexPathOfCellInSameRow:(CGFloat)y {
    __block NSMutableArray *set = [[NSMutableArray alloc] init];
    
    [self.house.visibleCells enumerateObjectsUsingBlock:^(FloorViewCell *cell,NSUInteger idx,BOOL *stop){
        if (ABS(cell.center.y-y)<cell.bounds.size.height*0.25) {
            [set addObject:cell.myIndexPath];
        }
    }];
    
    return set;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.gallery.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FloorViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    if (cell) {
        VisualControlContentView *panel = self.gallery[indexPath.row];
        [cell addVisualControlPanel:panel withFixBounds:cell.bounds];
        cell.delegate = self;
        cell.myIndexPath = indexPath;
        [cell showDeleteButton:self.allowEdit];
        [self.devices enumerateObjectsUsingBlock:^(DeviceModel *deviceModel, NSUInteger idx, BOOL * _Nonnull stop) {
            [cell updateLightPresentationWithMeshStatus:deviceModel];
        }];
    }

    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    VisualControlContentView *panel = self.gallery[indexPath.item];
    return panel.layoutSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 36;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 36;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    NSInteger total = self.gallery.count;
    CGFloat lineSpace = 36.0;
    CGFloat margin = 36.0;
    
    if (section<total-1) {
        if (section==0) {
            return UIEdgeInsetsMake(lineSpace, margin, lineSpace, margin);
        }
        return UIEdgeInsetsMake(0, margin, lineSpace, margin);
    }
    else {
        if (section==0) {
            return UIEdgeInsetsMake(lineSpace, margin, lineSpace, margin);
        }
        return UIEdgeInsetsMake(0, margin, lineSpace, margin);
    }
}

//for floor detail view
#pragma mark - VisualControlContentViewDelegate

//- (void)visualControlContentViewDidClickOnNoneLightRect {
//    NSLog(@"nianbao>>dian");
//    FloorDetailView *detailView = [self presentedFloorDetailView];
//    
//    if (detailView) {
//        [detailView fadeAway];
//    }
//}


- (void)visualControlContentViewSendBrightnessControlTouching:(CGPoint)touchAt referencePoint:(CGPoint)origin toLight:(NSNumber *)deviceId controlState:(UIGestureRecognizerState)state {
    //deliver to local
    [self.devices enumerateObjectsUsingBlock:^(DeviceModel *deviceModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([deviceModel.deviceId isEqualToNumber:deviceId] && [deviceModel.shortName isEqualToString:@"D350BT"]) {
            [self floorViewCellSendBrightnessControlTouching:touchAt referencePoint:origin toLight:deviceId controlState:state];
        }
    }];
    
}

#pragma mark - FloorViewCell Delegate

- (void)floorViewCellDidClickOnLight:(NSNumber *)deviceId {
    
    [self.devices enumerateObjectsUsingBlock:^(DeviceModel *deviceModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([deviceModel.deviceId isEqualToNumber:deviceId]) {
            BOOL state = ![deviceModel.powerState boolValue];
            [[CSRDevicesManager sharedInstance] setPowerState:deviceId state:[NSNumber numberWithBool:state]];
        }
    }];
    
}

- (void)floorViewCellDidClickOnNoneLightRectWithIndexPath:(NSIndexPath *)indexPath {
    
    VisualFloorDetailViewController *vfdvc = [[VisualFloorDetailViewController alloc] init];
    __block VisualControlContentView *cellContent = nil;
    
    [self.house.visibleCells enumerateObjectsUsingBlock:^(FloorViewCell *cell,NSUInteger idx,BOOL *stop){
        if (cell.myIndexPath==indexPath) {
            cellContent = (VisualControlContentView*)[cell visualContentView];
            *stop = YES;
        }
    }];
    
    vfdvc.content = [cellContent copy];
    vfdvc.isEdit = YES;
    vfdvc.delegate =self;
    vfdvc.devices = self.devices;
    [vfdvc setOrganizingHandle:^(VisualControlContentView *panel) {
        [self replaceVisualControlGallery];//////////////////////////////////////
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vfdvc];
    
    nav.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)floorViewCellRecognizerDidTranslationInLocation:(CGPoint)touchAt recognizerState:(UIGestureRecognizerState)state {
    if (self.house.contentSize.height<=self.house.bounds.size.height) {
        return;
    }
    
    CGFloat limit = ABS(self.house.contentSize.height-self.house.bounds.size.height);   // < ?
    CGFloat flexibleSpace = 36.0;
    
    if (state == UIGestureRecognizerStateBegan) {
        self.originalContentOffset = self.house.contentOffset;
    }
    else if (state == UIGestureRecognizerStateChanged) {
        CGFloat hOffset = touchAt.y;
        CGFloat symbol = hOffset==0 ? 0 : hOffset/ABS(hOffset);
        CGFloat updateY = ABS(hOffset)+flexibleSpace;
        CGFloat controlVelocity = 0.8;
        
        [self.house setContentOffset:CGPointMake(0, self.originalContentOffset.y-controlVelocity*updateY*symbol)];
    }
    else {
        //relaxation
        if (self.house.contentOffset.y<0) {
            [UIView animateWithDuration:0.3
                                  delay:0.0
                 usingSpringWithDamping:0.9
                  initialSpringVelocity:5.0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 self.house.contentOffset = CGPointMake(0, 0);
                             }
                             completion:nil
             ];
        }
        else if (self.house.contentOffset.y>limit) {
            [UIView animateWithDuration:0.3
                                  delay:0.0
                 usingSpringWithDamping:0.9
                  initialSpringVelocity:5.0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 self.house.contentOffset = CGPointMake(0, limit);
                             }
                             completion:nil
             ];
        }
    }
}

//点击删除按钮
- (void)floorViewCellSendDeleteActionFromIndexPath:(NSIndexPath *)indexPath {
    //warning - use the myIndexPath shoul keep in mind that : reload the whole collection view or table !!!
    if (self.allowEdit) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Are you sure to remove this visual control view?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            VisualControlContentView *target = self.gallery[indexPath.row];
            [self.gallery removeObjectAtIndex:indexPath.row];
            [self.house reloadData];
            [self removeVisualControl:target.visualControlIndex];
        }];
        [alert addAction:cancel];
        [alert addAction:confirm];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)removeVisualControl:(NSString *)index {
    NSDictionary *dic = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"com.actec.bluetooth.visualControlKey"];;
    
    if (dic) {
        if ([dic.allKeys containsObject:index]) {
            NSMutableDictionary *updated = [[NSMutableDictionary alloc] initWithDictionary:dic];
            [updated removeObjectForKey:index];
            
            NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
            [center setObject:updated forKey:@"com.actec.bluetooth.visualControlKey"];
        }
    }
}

- (void)floorViewCellSendBrightnessControlTouching:(CGPoint)touchAt referencePoint:(CGPoint)origin toLight:(NSNumber *)deviceId controlState:(UIGestureRecognizerState)state {
    [self.devices enumerateObjectsUsingBlock:^(DeviceModel *deviceModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([deviceModel.deviceId isEqualToNumber:deviceId]&&[deviceModel.shortName isEqualToString:@"D350BT"]) {
            CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:deviceId];
            if (!device) {
                return;
            }
            if (state == UIGestureRecognizerStateBegan) {
                self.originalBrightness = [device getLevel];
                [self.improver beginImproving];
                return;
            }
            if (state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateEnded) {
                NSInteger updateBrightness = [self.improver improveTouching:touchAt referencePoint:origin primaryBrightness:self.originalBrightness];
                long percentage = ((float)updateBrightness)*100/255.0;
                
                [self showControlMaskLayerWithAlpha:updateBrightness/255.0 text:[NSString stringWithFormat:@"%li",percentage]];
                
                BOOL permit = [self registerInterval:0.37 signal:@"com.actec.visualControlInterval"];
                if (state==UIGestureRecognizerStateEnded) {
                    permit = YES;
                }
                if (permit) {
                    [device setLevel:updateBrightness];
                }
            }
            
            
            if (state!=UIGestureRecognizerStateBegan && state!=UIGestureRecognizerStateChanged) {
                [self hideControlMaskLayer];
            }
            *stop = YES;
        }
    }];
    
    
    /*
    BleSupportManager *manager = [BleSupportManager shareInstance];
    LightBringer *target = [[manager lightBringerWithAddress:@[lightMAC]] firstObject];
    
    if (!target) {
        return;
    }
    
    if (state == UIGestureRecognizerStateBegan) {
        self.originalBrightness = target.isOpen;
        [self.improver beginImproving];
        return;
    }
    
    if (state==UIGestureRecognizerStateChanged || state==UIGestureRecognizerStateEnded) {
        
        NSInteger updateBrightness = [self.improver improveTouching:touchAt referencePoint:origin primaryBrightness:self.originalBrightness];
        
//        CGFloat alphaRespond = 0.15+(0.75-0.15)*updateBrightness/255.0;
        long percentage = ((float)updateBrightness)*100/255.0;
        
        [self showControlMaskLayerWithAlpha:updateBrightness/255.0 text:[NSString stringWithFormat:@"%li",percentage]];
        
        BOOL permit = [[BlockCenter defaultCenter] registerInterval:0.37 signal:@"com.actec.visualControlInterval"];
        if (state==UIGestureRecognizerStateEnded) {
            permit = YES;
        }
        if (permit) {
     
            // virtual system
     
            VirtualDeviceSystem *system = [VirtualDeviceSystem shareSystem];
            if (system.isLoaded) {
                [system controlVirtualLight:target.lightAddress brightness:updateBrightness];
            }
            else {
                [manager controlLight:target.lightAddress forBrightness:updateBrightness colorTemperature:0];
            }
        }
    }
    
    if (state!=UIGestureRecognizerStateBegan && state!=UIGestureRecognizerStateChanged) {
        [self hideControlMaskLayer];
    }
*/
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

- (BOOL)registerInterval:(NSTimeInterval)expect signal:(NSString*)signal {
    BOOL permission = NO;
    
    if (![self.intervalMap.allKeys containsObject:signal]) {
        [self.intervalMap setObject:[NSDate date] forKey:signal];
        permission = YES;
    }
    else {
        NSDate *last = [self.intervalMap objectForKey:signal];
        NSDate *current = [NSDate date];
        NSTimeInterval interval = [current timeIntervalSinceDate:last];
        
        if (interval>=expect) {
            [self.intervalMap setObject:current forKey:signal];
            permission = YES;
        }
    }
    return permission;
}


#pragma mark - BLE Notify

- (void)bleSupportManagerDidUpdateSomePeripheralStatus {

//    [self updateDeviceStatus];
}

- (void)updateDeviceStatus:(DeviceModel *)deviceModel {
    //use the visible cells but the data source should has update mechanism
    [self.house.visibleCells enumerateObjectsUsingBlock:^(FloorViewCell *cell,NSUInteger idx,BOOL *stop){
        [cell updateLightPresentationWithMeshStatus:deviceModel];
    }];
}

#pragma mark - Lazy

- (NSMutableArray*)gallery {
    if (!_gallery) {
        _gallery = [[NSMutableArray alloc]init];
    }
    return _gallery;
}

- (ControlMaskView*)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [[ControlMaskView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _maskLayer;
}

- (NSMutableDictionary*)primaryLayoutSize {
    if (!_primaryLayoutSize) {
        _primaryLayoutSize = [[NSMutableDictionary alloc] init];
    }
    
    return _primaryLayoutSize;
}

- (NSMutableDictionary*)intervalMap {
    if (!_intervalMap) {
        _intervalMap = [[NSMutableDictionary alloc]init];
    }
    return _intervalMap;
}

- (NSMutableArray *)devices {
    if (!_devices) {
        _devices = [[NSMutableArray alloc] init];
    }
    return _devices;
}

#pragma mark - Layout

- (void)updateViewConstraints {
    [super updateViewConstraints];
    [self.house autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(64, 0, 50, 0)];
}

@end
