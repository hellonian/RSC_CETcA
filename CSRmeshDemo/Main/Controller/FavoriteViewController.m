//
//  FavoriteViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/8/30.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "FavoriteViewController.h"
#import "PureLayout.h"
#import "CSRDatabaseManager.h"
#import "RGBSceneCollectionViewCell.h"
#import "SRGBSceneDetailViewController.h"
#import "MRGBSceneDetailViewController.h"
#import <CSRmesh/LightModelApi.h>
#import "DeviceModelManager.h"
#import "CSRUtilities.h"
#import "SoundListenTool.h"

@interface FavoriteViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,RGBSceneCellDelegate>

@property (nonatomic,strong) UICollectionView *collectionView;
@property (nonatomic,strong) NSMutableArray *dataMutableArray;

@end

@implementation FavoriteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = 12;
    flowLayout.minimumInteritemSpacing = 12;
    flowLayout.itemSize = CGSizeMake(90, 114);
    flowLayout.sectionInset = UIEdgeInsetsMake(24, 12, 34, 12);
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor clearColor];
    [_collectionView registerNib:[UINib nibWithNibName:@"RGBSceneCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"RGBSceneCell"];
    [self.view addSubview:_collectionView];
    [_collectionView autoPinEdgesToSuperviewEdges];
    
    [self getData];
    
}

- (void)getData {
    if ([_deviceId integerValue] > 32768/*单设备*/) {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:_deviceId];
        _dataMutableArray = [[deviceEntity.rgbScenes allObjects] mutableCopy];
    }else {
        CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:_deviceId];
        _dataMutableArray = [[areaEntity.rgbScenes allObjects] mutableCopy];
    }
    if ([_dataMutableArray count]>0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sortID" ascending:YES];
        [_dataMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    }
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_dataMutableArray count];
}

- (RGBSceneCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    RGBSceneCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RGBSceneCell" forIndexPath:indexPath];
    if (cell) {
        cell.cellDelegate = self;
        RGBSceneEntity *rgbSceneTntity = _dataMutableArray[indexPath.row];
        [cell configureCellWithInfo:rgbSceneTntity index:indexPath.row];
    }
    return cell;
}

- (void)RGBSceneCellDelegateLongPressAction:(NSInteger)index {
    id info = _dataMutableArray[index];
    if ([info isKindOfClass:[RGBSceneEntity class]]) {
        RGBSceneEntity *rgbSceneEntity = (RGBSceneEntity *)info;
        if ([rgbSceneEntity.eventType boolValue]) {
            MRGBSceneDetailViewController *mvc = [[MRGBSceneDetailViewController alloc] init];
            mvc.deviceId = _deviceId;
            mvc.rgbSceneEntity = rgbSceneEntity;
            __weak FavoriteViewController *weakself = self;
            mvc.reloadDataHandle = ^{
                [weakself getData];
                [_collectionView reloadData];
            };
            [self.navigationController pushViewController:mvc animated:YES];
        }else {
            SRGBSceneDetailViewController *svc = [[SRGBSceneDetailViewController alloc] init];
            svc.deviceId = _deviceId;
            svc.rgbSceneEntity = rgbSceneEntity;
            __weak FavoriteViewController *weakself = self;
            svc.reloadDataHandle = ^{
                [weakself getData];
                [_collectionView reloadData];
            };
            [self.navigationController pushViewController:svc animated:YES];
        }
    }
}

- (void)RGBSceneCellDelegateTapAction:(NSInteger)index {
    id info = _dataMutableArray[index];
    if ([info isKindOfClass:[RGBSceneEntity class]]) {
        RGBSceneEntity *rgbSceneEntity = (RGBSceneEntity *)info;
        
        if ([SoundListenTool sharedInstance].audioRecorder.recording) {
            [[SoundListenTool sharedInstance] stopRecord:_deviceId];
        }
        
        [[LightModelApi sharedInstance] setLevel:_deviceId level:rgbSceneEntity.level success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
            
        } failure:^(NSError * _Nullable error) {
            DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
            model.isleave = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":_deviceId}];
        }];
        
        if ([rgbSceneEntity.eventType boolValue]) {
           
            [[DeviceModelManager sharedInstance] colorfulAction:_deviceId timeInterval:[rgbSceneEntity.changeSpeed floatValue] hues:@[rgbSceneEntity.hueA,rgbSceneEntity.hueB,rgbSceneEntity.hueC,rgbSceneEntity.hueD,rgbSceneEntity.hueE,rgbSceneEntity.hueF] colorSaturation:rgbSceneEntity.colorSat rgbSceneId:rgbSceneEntity.rgbSceneID];
            
            
        }else {
            
            [[DeviceModelManager sharedInstance] invalidateColofulTimerWithDeviceId:_deviceId];
            
            UIColor *color = [UIColor colorWithHue:[rgbSceneEntity.hueA floatValue] saturation:[rgbSceneEntity.colorSat floatValue] brightness:1.0 alpha:1.0];
            [[LightModelApi sharedInstance] setColor:_deviceId color:color duration:@0 success:^(NSNumber * _Nullable deviceId, UIColor * _Nullable color, NSNumber * _Nullable powerState, NSNumber * _Nullable colorTemperature, NSNumber * _Nullable supports) {
                
            } failure:^(NSError * _Nullable error) {
                DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:_deviceId];
                model.isleave = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"setPowerStateSuccess" object:self userInfo:@{@"deviceId":_deviceId}];
            }];
            
        }
    }
    
}

@end
