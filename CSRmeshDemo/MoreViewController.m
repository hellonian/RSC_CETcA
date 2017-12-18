//
//  MoreViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/15.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MoreViewController.h"
#import "TimerViewController.h"
#import "UpdateViewController.h"
#import "AboutViewController.h"
#import "MasterViewController.h"
#import "PureLayout.h"
#import "RemoteViewController.h"
#import "ShareViewController.h"
#import "MusicListTableViewController.h"

@interface MoreViewController ()<UISplitViewControllerDelegate,masterDelegate>

@property (nonatomic,strong) UISplitViewController *panel;
@property (nonatomic,strong) RemoteViewController *remoteVC;
@property (nonatomic,strong) TimerViewController *timerVC;
@property (nonatomic,strong) UpdateViewController *updateVC;
@property (nonatomic,strong) AboutViewController *aboutVC;
@property (nonatomic,strong) ShareViewController *shareVC;
@property (nonatomic,strong) MasterViewController *masterVC;
@property (nonatomic,strong) UINavigationController *masterViewManager;
@property (nonatomic,strong) UINavigationController *detailViewManger;
@property (nonatomic,strong) MusicListTableViewController *musicVC;

@end

@implementation MoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgImage"]];
    imageView.frame = [UIScreen mainScreen].bounds;
    [self.view addSubview:imageView];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self layoutView];
    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.masterVC updateViewConstraints];
}

- (void)layoutView {
    self.panel = [[UISplitViewController alloc] init];
    self.remoteVC = [[RemoteViewController alloc] init];
    self.timerVC = [[TimerViewController alloc] init];
    self.updateVC = [[UpdateViewController alloc] init];
    self.aboutVC = [[AboutViewController alloc] init];
    self.shareVC = [[ShareViewController alloc] init];
    self.musicVC = [[MusicListTableViewController alloc] init];
    self.masterVC = [[MasterViewController alloc] init];
    self.masterVC.delegate = self;
    
    self.masterViewManager = [[UINavigationController alloc] initWithRootViewController:self.masterVC];
    self.masterViewManager.navigationBarHidden = NO;
    self.detailViewManger = [[UINavigationController alloc] initWithRootViewController:self.shareVC];
    self.detailViewManger.navigationBarHidden = NO;
    self.panel.viewControllers = @[self.masterViewManager,self.detailViewManger];
    self.panel.delegate = self;
    self.panel.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    
    [self addChildViewController:self.panel];
    [self.view addSubview:self.panel.view];
    
}

#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)splitViewController showViewController:(UIViewController *)vc sender:(id)sender {
    return NO;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    return YES;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController showDetailViewController:(UIViewController *)vc sender:(id)sender {
    return YES;
}

- (UIViewController*)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {
    return nil;
}

#pragma mark - masterDelegate

- (void) didSelectRowAtMaster:(NSInteger)row {
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        [self pushViewConrollerWithRow:row];
        return;
    }
    
    NSMutableArray *vcs = [NSMutableArray arrayWithArray:self.detailViewManger.childViewControllers];
    [vcs removeAllObjects];
    switch (row) {
        case 0:
            [vcs addObject:self.shareVC];
            break;
        case 1:
            [vcs addObject:self.timerVC];
            break;
        case 2:
            [vcs addObject:self.updateVC];
            break;
        case 3:
            [vcs addObject:self.remoteVC];
            break;
        case 4:
            [vcs addObject:self.musicVC];
            break;
        case 5:
            [vcs addObject:self.aboutVC];
            break;
        default:
            break;
    }
    [self.detailViewManger setViewControllers:vcs];
}

- (void)pushViewConrollerWithRow: (NSInteger)row {
    switch (row) {
        case 0:
            [self.masterViewManager pushViewController:self.shareVC animated:YES];
            break;
        case 1:
            [self.masterViewManager pushViewController:self.timerVC animated:YES];
            break;
        case 2:
            [self.masterViewManager pushViewController:self.updateVC animated:YES];
            break;
        case 3:
            [self.masterViewManager pushViewController:self.remoteVC animated:YES];
            break;
        case 4:
            [self.masterViewManager pushViewController:self.musicVC animated:YES];
            break;
        case 5:
            [self.masterViewManager pushViewController:self.aboutVC animated:YES];
        default:
            break;
    }
}

#pragma mark - AutoLayout

- (void)updateViewConstraints {
    [super updateViewConstraints];
    NSLog(@"updateViewConstraints>>>more");
    [self.panel.view autoPinEdgesToSuperviewEdges];
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
