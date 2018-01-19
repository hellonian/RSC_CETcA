//
//  MainTabBarController.m
//  ActecBluetoothNorDic
//
//  Created by AcTEC on 2017/4/13.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import "MainTabBarController.h"
#import "LightClusterViewController.h"
#import "SceneCollectionController.h"
#import "ConfiguredDeviceListController.h"

@interface MainTabBarController ()<TabBarDelegate,LightClusterControllerDelegate,SceneCollectionControllerDelegate>

@property (nonatomic,strong) LightClusterViewController *lcvc;
@property (nonatomic,strong) SceneCollectionController *svc;

@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor blackColor];
    self.tabBarView = [[TabBarView alloc]initWithFrame:CGRectMake(0, HEIGHT-50, WIDTH, 50)];
    self.tabBarView.delegate = self;
    [self.view addSubview:self.tabBarView];
    
//    [self didSelectedAtIndex:0];
    
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
-(void)didSelectedAtIndex:(NSInteger)index{
    self.selectedIndex = index;
//    if (index == 0) {
////        self.navigationController.navigationBarHidden = NO;
////        self.title = @"Lamps";
////        UIBarButtonItem *group = [[UIBarButtonItem alloc]initWithTitle:@"Group" style:UIBarButtonItemStylePlain target:self action:@selector(beginOrganizingGroup)];
////        self.navigationItem.leftBarButtonItem = group;
////        self.navigationItem.rightBarButtonItem = nil;
////        self.navigationController.navigationBarHidden = YES;
//    }
//    else if (index == 1) {
////        self.navigationController.navigationBarHidden = NO;
////        self.title = @"Gallery";
////        UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(firstRightBarButtonAction:)];
////        self.navigationItem.rightBarButtonItem = edit;
////        self.navigationItem.leftBarButtonItem = nil;
//        self.navigationController.navigationBarHidden = YES;
//    }
//    else if (index == 2){
//        self.title = @"Scenes";
//        UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(sceneBeginEdit)];
//        self.navigationItem.rightBarButtonItem = edit;
////        UIBarButtonItem *scene = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(beginOrganizingScene)];
//        self.navigationItem.leftBarButtonItem = nil;
//    }
//    else
//    {
//        self.navigationController.navigationBarHidden = YES;
////        self.title = @"More";
////        self.navigationItem.rightBarButtonItem = nil;
////        self.navigationItem.leftBarButtonItem = nil;
//    }
}
-(void)beginOrganizingGroup{
    
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelOrganizingGroup)];
    self.navigationItem.leftBarButtonItem = done;
    
    UIBarButtonItem *organize = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(finishOrganizingGroup)];
    self.navigationItem.rightBarButtonItem = organize;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[LightClusterViewController class]]) {
            _lcvc = (LightClusterViewController *)obj;
            _lcvc.delegate = self;
            [_lcvc beginGroupOrganizing];
            *stop = YES;
        }
    }];
    
}

- (void)finishOrganizingGroup {
    [_lcvc groupOrganizingFinalStep];
    
    UIBarButtonItem *group = [[UIBarButtonItem alloc]initWithTitle:@"Group" style:UIBarButtonItemStylePlain target:self action:@selector(beginOrganizingGroup)];
    self.navigationItem.leftBarButtonItem = group;
    self.navigationItem.rightBarButtonItem = nil;
    [_lcvc endGroupOrganizing];
}

- (void)cancelOrganizingGroup {
    
//    [self didSelectedAtIndex:0];
    [_lcvc endGroupOrganizing];
}

- (void)lightClusterControllerUpdateNumberOfSelectedLight:(NSInteger)number {
    if (self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem.enabled = (number>0);
    }
}


- (void)chooseSelectIndex: (NSInteger)inndex {
    [self setSelectedIndex:inndex];
}

- (void)sceneBeginEdit {
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(sceneEndEdit)];
    self.navigationItem.rightBarButtonItem = done;
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewScene)];
    self.navigationItem.leftBarButtonItem = add;
    [self.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[SceneCollectionController class]]) {
            _svc = (SceneCollectionController *)obj;
            [_svc beginEdit];
            *stop = YES;
        }
    }];
}

- (void)sceneEndEdit {
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(sceneBeginEdit)];
    self.navigationItem.rightBarButtonItem = edit;
    self.navigationItem.leftBarButtonItem = nil;
    [_svc endEdit];
}

- (void)addNewScene {
    [_svc endEdit];
    ConfiguredDeviceListController *list = [[ConfiguredDeviceListController alloc] initWithItemPerSection:3 cellIdentifier:@"LightClusterCell"];
    list.isnewadd = YES;
    [list setSelectMode:Multiple];
    [self.navigationController pushViewController:list animated:YES];
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
