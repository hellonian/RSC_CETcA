//
//  LanguageViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/2/27.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "LanguageViewController.h"
#import "AppDelegate.h"
#import "NSBundle+AppLanguageSwitch.h"
#import "PureLayout.h"

@interface LanguageViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSArray *languageAry;
@property (nonatomic,strong) NSArray *detailLanguageAry;
@property (nonatomic,assign) NSInteger newSelectedRow;
@property (nonatomic,assign) NSInteger oldSelectedRow;
@property (nonatomic,strong) NSString *selectLanguage;

@end

@implementation LanguageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Language", @"Localizable");
    if (@available(iOS 11.0, *)) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(-35, 0, 0, 0);
    }
    
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:AcTECLocalizedStringFromTable(@"Setting_back", @"Localizable")] style:UIBarButtonItemStylePlain target:self action:@selector(backSetting)];
        self.navigationItem.leftBarButtonItem = left;
    }
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = right;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    self.languageAry = @[@"English",@"简体中文"];
    self.detailLanguageAry = @[AcTECLocalizedStringFromTable(@"English", @"Localizable"),AcTECLocalizedStringFromTable(@"ChineseS", @"Localizable")];
    NSString *nowLanguageType = [[NSUserDefaults standardUserDefaults] objectForKey:AcTECLanguage];
    if ([nowLanguageType isEqualToString:@"en"]) {
        self.newSelectedRow = 0;
    }else if ([nowLanguageType isEqualToString:@"zh-Hans"]) {
        self.newSelectedRow = 1;
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundView = [[UIView alloc] init];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        [self.tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    }else {
        [self.tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 50, 0)];
    }
}

- (void)backSetting{
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)doneAction {
    [[NSUserDefaults standardUserDefaults] setObject:self.selectLanguage forKey:AcTECLanguage];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self languageChange];
    
//    AppDelegate *appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
//    if ([appdelegate.window.rootViewController isKindOfClass:[MainTabBarController class]]) {
//        MainTabBarController *rootVC = (MainTabBarController *)appdelegate.window.rootViewController;
//        [rootVC.tabBarView changeLanguage];
//        for (UIViewController *vc in rootVC.viewControllers) {
//            if ([vc isKindOfClass:[UINavigationController class]]) {
//                UINavigationController *nav = (UINavigationController *)vc;
//                [nav.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                    if ([obj isKindOfClass:[MainViewController class]]) {
//                        MainViewController *mvc = (MainViewController *)obj;
//                        [mvc changeLanuage];
//                    }
//                }];
//
//            }
//
//
//        }
//    }
    
    [NSBundle setCusLanguage:self.selectLanguage];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.languageAry count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.textLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        cell.tintColor = DARKORAGE;
    }
    cell.textLabel.text = self.languageAry[indexPath.row];
    cell.detailTextLabel.text = self.detailLanguageAry[indexPath.row];
    if (indexPath.row == self.newSelectedRow) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *languageType = [[NSUserDefaults standardUserDefaults] objectForKey:AcTECLanguage];
    NSString *typeString = self.languageAry[indexPath.row];
    
    if ([typeString isEqualToString:@"English"]) {
        self.selectLanguage = @"en";
    }else if ([typeString isEqualToString:@"简体中文"]) {
        self.selectLanguage = @"zh-Hans";
    }
    if ([self.selectLanguage isEqualToString:languageType]) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    self.oldSelectedRow = self.newSelectedRow;
    self.newSelectedRow = indexPath.row;
    NSIndexPath *oldIndex = [NSIndexPath indexPathForRow:self.oldSelectedRow inSection:0];
    NSIndexPath *newIndex = [NSIndexPath indexPathForRow:self.newSelectedRow inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[oldIndex,newIndex] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)languageChange {
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Language", @"Localizable");
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:AcTECLocalizedStringFromTable(@"Setting_back", @"Localizable")] style:UIBarButtonItemStylePlain target:self action:@selector(backSetting)];
        self.navigationItem.leftBarButtonItem = left;
    }
    self.detailLanguageAry = @[AcTECLocalizedStringFromTable(@"English", @"Localizable"),AcTECLocalizedStringFromTable(@"ChineseS", @"Localizable")];
    [self.tableView reloadData];
}


@end
