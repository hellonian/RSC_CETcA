//
//  MainViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/17.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MainViewController.h"
#import "MainCollectionView.h"
#import "CSRAppStateManager.h"
#import "CSRAreaEntity.h"
#import "AreaModel.h"
#import "CSRDeviceEntity.h"
#import "DeviceModel.h"
#import "AddDevcieViewController.h"

@interface MainViewController ()<MainCollectionViewDelegate>

@property (nonatomic,strong) MainCollectionView *mainCollectionView;
@property (nonatomic,strong) MainCollectionView *sceneCollectionView;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"Main";
    UIBarButtonItem *group = [[UIBarButtonItem alloc]initWithTitle:@"Group" style:UIBarButtonItemStylePlain target:self action:@selector(beginOrganizingGroup)];
    self.navigationItem.rightBarButtonItem = group;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = WIDTH*8.0/640.0;
    flowLayout.minimumInteritemSpacing = WIDTH*8.0/640.0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, WIDTH*3/160.0);
    flowLayout.itemSize = CGSizeMake(WIDTH*3/8.0, WIDTH*9/32.0);
    
    _mainCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectMake(WIDTH*7/32.0, WIDTH*151/320.0+64, WIDTH*25/32.0, HEIGHT-114-WIDTH*157/320.0) collectionViewLayout:flowLayout cellIdentifier:@"MainCollectionViewCell"];
    _mainCollectionView.mainDelegate = self;
    
    [self.view addSubview:_mainCollectionView];
    
    UICollectionViewFlowLayout *sceneFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    sceneFlowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    sceneFlowLayout.minimumLineSpacing = 0;
    sceneFlowLayout.minimumInteritemSpacing = 0;
    sceneFlowLayout.itemSize = CGSizeMake(WIDTH*3/16.0, WIDTH*9/40.0);

    _sceneCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectMake(WIDTH*3/160.0, WIDTH*151/320.0+64, WIDTH*3/16.0, HEIGHT-114-WIDTH*157/320.0) collectionViewLayout:sceneFlowLayout cellIdentifier:@"SceneCollectionViewCell"];
    
    _sceneCollectionView.dataArray = [NSMutableArray arrayWithObjects:@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss",@"ssss", nil];

    [self.view addSubview:_sceneCollectionView];
    
    [self getDataArray];
    
    
}

- (void)getDataArray {
    [_mainCollectionView.dataArray removeAllObjects];
    
    NSMutableArray *deviceIdWasInAreaArray =[[NSMutableArray alloc] init];
    NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
    if (areaMutableArray != nil || [areaMutableArray count] != 0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"areaName" ascending:YES]; //@"name"
        [areaMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        [areaMutableArray enumerateObjectsUsingBlock:^(CSRAreaEntity *area, NSUInteger idx, BOOL * _Nonnull stop) {
            
            for (CSRDeviceEntity *deviceEntity in area.devices) {
                [deviceIdWasInAreaArray addObject:deviceEntity.deviceId];
            }
            [_mainCollectionView.dataArray addObject:area];
            
        }];
    }
    
    NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
    if (mutableArray != nil || [mutableArray count] != 0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        [mutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        [mutableArray enumerateObjectsUsingBlock:^(CSRDeviceEntity *deviceEntity, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([deviceEntity.shortName isEqualToString:@"D350BT"] || [deviceEntity.shortName isEqualToString:@"S350BT"]) {
                if (![deviceIdWasInAreaArray containsObject:deviceEntity.deviceId]) {
                    [_mainCollectionView.dataArray addObject:deviceEntity];
                }
            }
        }];
    }
    
    [_mainCollectionView.dataArray addObject:@0];
    
    [_mainCollectionView reloadData];
    
}

#pragma mark - MainCollectionViewDelegate

- (void)mainCollectionViewAddDeviceAction:(NSNumber *)cellDeviceId {
    NSLog(@"mainvcadd");
    if ([cellDeviceId isEqualToNumber:@1000]) {
        AddDevcieViewController *addVC = [[AddDevcieViewController alloc] init];
        CATransition *animation = [CATransition animation];
        [animation setDuration:0.3];
        [animation setType:kCATransitionMoveIn];
        [animation setSubtype:kCATransitionFromRight];
        [self.view.window.layer addAnimation:animation forKey:nil];
        UINavigationController *nav= [[UINavigationController alloc] initWithRootViewController:addVC];
        [self presentViewController:nav animated:NO completion:nil];
    }
}

- (void)beginOrganizingGroup {
    
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
