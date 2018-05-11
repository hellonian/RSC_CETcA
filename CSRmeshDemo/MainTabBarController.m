//
//  MainTabBarController.m
//  ActecBluetoothNorDic
//
//  Created by AcTEC on 2017/4/13.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import "MainTabBarController.h"

@interface MainTabBarController ()<TabBarDelegate>

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
    
}
-(void)didSelectedAtIndex:(NSInteger)index{
    self.selectedIndex = index;
}

@end
