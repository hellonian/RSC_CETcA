//
//  MoreViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/15.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MoreViewController.h"
#import "TimerViewController.h"
#import "DiscoverViewController.h"
#import "AboutViewController.h"
#import "MasterViewController.h"
#import "PureLayout.h"
#import "RemoteViewController.h"
#import "ShareViewController.h"
#import "MusicListTableViewController.h"
#import "PlacesViewController.h"
#import "LanguageViewController.h"
#import "HelpViewController.h"

@interface MoreViewController ()<UISplitViewControllerDelegate,masterDelegate>

@property (nonatomic,strong) UISplitViewController *panel;
@property (nonatomic,strong) RemoteViewController *remoteVC;
@property (nonatomic,strong) TimerViewController *timerVC;
@property (nonatomic,strong) DiscoverViewController *updateVC;
@property (nonatomic,strong) AboutViewController *aboutVC;
@property (nonatomic,strong) ShareViewController *shareVC;
@property (nonatomic,strong) MasterViewController *masterVC;
@property (nonatomic,strong) PlacesViewController *placesVC;
@property (nonatomic,strong) UINavigationController *masterViewManager;
@property (nonatomic,strong) UINavigationController *detailViewManger;
@property (nonatomic,strong) MusicListTableViewController *musicVC;
@property (nonatomic,strong) LanguageViewController *languageVC;
@property (nonatomic,strong) HelpViewController *helpVC;

@end

@implementation MoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
    self.updateVC = [[DiscoverViewController alloc] init];
    self.aboutVC = [[AboutViewController alloc] init];
    self.shareVC = [[ShareViewController alloc] init];
    self.musicVC = [[MusicListTableViewController alloc] init];
    self.placesVC = [[PlacesViewController alloc] init];
    self.masterVC = [[MasterViewController alloc] init];
    self.languageVC = [[LanguageViewController alloc] init];
    self.helpVC = [[HelpViewController alloc] init];
    
    self.masterVC.delegate = self;
    
    self.masterViewManager = [[UINavigationController alloc] initWithRootViewController:self.masterVC];
    self.masterViewManager.navigationBarHidden = NO;
    self.detailViewManger = [[UINavigationController alloc] initWithRootViewController:self.placesVC];
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

- (void) didSelectRowAtMaster:(NSIndexPath *)indexPath {
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        [self pushViewConrollerWithRow:indexPath];
        return;
    }
    
    NSMutableArray *vcs = [NSMutableArray arrayWithArray:self.detailViewManger.childViewControllers];
    [vcs removeAllObjects];
    switch (indexPath.section) {
        case 0:
        {
            switch (indexPath.row) {
                case 0:
                    [vcs addObject:self.placesVC];
                    break;
                case 1:
                    [vcs addObject:self.shareVC];
                    break;
                default:
                    break;
            }
            break;
        }
        case 1:
        {
            switch (indexPath.row) {
                case 0:
                    [vcs addObject:self.timerVC];
                    break;
                case 1:
                    [vcs addObject:self.remoteVC];
                    break;
                case 2:
                    [vcs addObject:self.updateVC];
                    break;
                default:
                    break;
            }
            break;
        }
        case 2:
        {
            switch (indexPath.row) {
                case 0:
                    [vcs addObject:self.languageVC];
                    break;
                case 1:
                    [vcs addObject:self.helpVC];
                    break;
                case 2:
                    [vcs addObject:self.aboutVC];
                    break;
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
    [self.detailViewManger setViewControllers:vcs];
}

- (void)pushViewConrollerWithRow: (NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
        {
            switch (indexPath.row) {
                case 0:
                    [self pushViewConrollerW:self.placesVC];
                    break;
                case 1:
                    [self pushViewConrollerW:self.shareVC];
                    break;
                default:
                    break;
            }
            break;
        }
        case 1:
        {
            switch (indexPath.row) {
                case 0:
                    [self pushViewConrollerW:self.timerVC];
                    break;
                case 1:
                    [self pushViewConrollerW:self.remoteVC];
                    break;
                case 2:
                    [self pushViewConrollerW:self.updateVC];
                    break;
                default:
                    break;
            }
            break;
        }
        case 2:
        {
            switch (indexPath.row) {
                case 0:
                    [self pushViewConrollerW:self.languageVC];
                    break;
                case 1:
                    [self pushViewConrollerW:self.helpVC];
                    break;
                case 2:
                    [self pushViewConrollerW:self.aboutVC];
                    break;
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

- (void)pushViewConrollerW:(UIViewController *)vc {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromRight];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self presentViewController:nav animated:NO completion:nil];
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
