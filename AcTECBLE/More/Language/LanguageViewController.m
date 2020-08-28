//
//  LanguageViewController.m
//  AcTECBLE
//
//  Created by AcTEC on 2018/2/27.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
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
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Setting", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(backSetting) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
    }
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = right;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    /*
    self.languageAry = @[@"English",
                         @"简体中文",
                         @"Norsk bokmål",
                         @"Svenska",
                         @"Deutsch",
                         @"Polski",
                         @"Русский",
                         @"Português(Portugal)",
                         @"Español",
                         @"română",
                         @"Čeština",
                         @"Lietuviškai"];
    self.detailLanguageAry = @[AcTECLocalizedStringFromTable(@"English", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"ChineseS", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Norwegian", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Swedish", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"German", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Polish", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Russian", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Portuguese", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Spanish", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Romanian", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Czech", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Lithuanian", @"Localizable")];
     */
    self.languageAry = @[@"English",
                         @"简体中文",
                         @"Deutsch",
                         @"Norsk bokmål",
                         @"Svenska",
                         @"Español",
                         @"Dansk",
                         @"Italiano",
                         @"Nederlands",
                         @"Français",
                         @"Português (Portugal)",
                         @"Suomi"];
    self.detailLanguageAry = @[AcTECLocalizedStringFromTable(@"English", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"ChineseS", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"German", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Norwegian", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Swedish", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Spanish", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Danish", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Italian", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Dutch", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"French", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Portuguese", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Finnish", @"Localizable")];
    
    NSString *nowLanguageType = [[NSUserDefaults standardUserDefaults] objectForKey:AppLanguageSwitchKey];
    if ([nowLanguageType isEqualToString:@"en"]) {
        self.newSelectedRow = 0;
    }else if ([nowLanguageType isEqualToString:@"zh-Hans"]) {
        self.newSelectedRow = 1;
    }else if ([nowLanguageType isEqualToString:@"de"]) {
        self.newSelectedRow = 2;
    }else if ([nowLanguageType isEqualToString:@"nb"]) {
        self.newSelectedRow = 3;
    }else if ([nowLanguageType isEqualToString:@"sv"]) {
        self.newSelectedRow = 4;
    }else if ([nowLanguageType isEqualToString:@"es"]) {
        self.newSelectedRow = 5;
    }else if ([nowLanguageType isEqualToString:@"da"]) {
        self.newSelectedRow = 6;
    }else if ([nowLanguageType isEqualToString:@"it"]) {
        self.newSelectedRow = 7;
    }else if ([nowLanguageType isEqualToString:@"nl"]) {
        self.newSelectedRow = 8;
    }else if ([nowLanguageType isEqualToString:@"fr"]) {
        self.newSelectedRow = 9;
    }else if ([nowLanguageType isEqualToString:@"pt-PT"]) {
        self.newSelectedRow = 10;
    }else if ([nowLanguageType isEqualToString:@"fi-FI"]) {
        self.newSelectedRow = 11;
    }
    /*
    else if ([nowLanguageType isEqualToString:@"nb"]) {
        self.newSelectedRow = 2;
    }else if ([nowLanguageType isEqualToString:@"sv"]) {
        self.newSelectedRow = 3;
    }else if ([nowLanguageType isEqualToString:@"de"]) {
        self.newSelectedRow = 4;
    }else if ([nowLanguageType isEqualToString:@"pl"]) {
        self.newSelectedRow = 5;
    }else if ([nowLanguageType isEqualToString:@"ru"]) {
        self.newSelectedRow = 6;
    }else if ([nowLanguageType isEqualToString:@"pt-PT"]) {
        self.newSelectedRow = 7;
    }else if ([nowLanguageType isEqualToString:@"es"]) {
        self.newSelectedRow = 8;
    }else if ([nowLanguageType isEqualToString:@"ro"]) {
        self.newSelectedRow = 9;
    }else if ([nowLanguageType isEqualToString:@"cs"]) {
        self.newSelectedRow = 10;
    }else if ([nowLanguageType isEqualToString:@"lt"]) {
        self.newSelectedRow = 11;
    }
     */
    
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
//    [[NSUserDefaults standardUserDefaults] setObject:self.selectLanguage forKey:AcTECLanguage];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    
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
    
    [self languageChange];
    
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
    NSString *languageType = [[NSUserDefaults standardUserDefaults] objectForKey:AppLanguageSwitchKey];
    NSString *typeString = self.languageAry[indexPath.row];
    
    if ([typeString isEqualToString:@"English"]) {
        self.selectLanguage = @"en";
    }else if ([typeString isEqualToString:@"简体中文"]) {
        self.selectLanguage = @"zh-Hans";
    }else if ([typeString isEqualToString:@"Deutsch"]) {
        self.selectLanguage = @"de";
    }else if ([typeString isEqualToString:@"Norsk bokmål"]) {
        self.selectLanguage = @"nb";
    }else if ([typeString isEqualToString:@"Svenska"]) {
        self.selectLanguage = @"sv";
    }else if ([typeString isEqualToString:@"Español"]) {
        self.selectLanguage = @"es";
    }else if ([typeString isEqualToString:@"Dansk"]) {
        self.selectLanguage = @"da";
    }else if ([typeString isEqualToString:@"Italiano"]) {
        self.selectLanguage = @"it";
    }else if ([typeString isEqualToString:@"Nederlands"]) {
        self.selectLanguage = @"nl";
    }else if ([typeString isEqualToString:@"Français"]) {
        self.selectLanguage = @"fr";
    }else if ([typeString isEqualToString:@"Português (Portugal)"]) {
        self.selectLanguage = @"pt-PT";
    }else if ([typeString isEqualToString:@"Suomi"]) {
        self.selectLanguage = @"fi-FI";
    }
    /*
    else if ([typeString isEqualToString:@"Norsk bokmål"]) {
        self.selectLanguage = @"nb";
    }else if ([typeString isEqualToString:@"Svenska"]) {
        self.selectLanguage = @"sv";
    }else if ([typeString isEqualToString:@"Deutsch"]) {
        self.selectLanguage = @"de";
    }else if ([typeString isEqualToString:@"Polski"]) {
        self.selectLanguage = @"pl";
    }else if ([typeString isEqualToString:@"Русский"]) {
        self.selectLanguage = @"ru";
    }else if ([typeString isEqualToString:@"Português(Portugal)"]) {
        self.selectLanguage = @"pt-PT";
    }else if ([typeString isEqualToString:@"Español"]) {
        self.selectLanguage = @"es";
    }else if ([typeString isEqualToString:@"română"]) {
        self.selectLanguage = @"ro";
    }else if ([typeString isEqualToString:@"Čeština"]) {
        self.selectLanguage = @"cs";
    }else if ([typeString isEqualToString:@"Lietuviškai"]) {
        self.selectLanguage = @"lt";
    }
     */
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
        UIButton *btn = [[UIButton alloc] init];
        [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
        [btn setTitle:AcTECLocalizedStringFromTable(@"Setting", @"Localizable") forState:UIControlStateNormal];
        [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(backSetting) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = back;
    }
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = right;
    
    /*
    self.detailLanguageAry = @[AcTECLocalizedStringFromTable(@"English", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"ChineseS", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Norwegian", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Swedish", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"German", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Polish", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Russian", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Portuguese", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Spanish", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Romanian", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Czech", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Lithuanian", @"Localizable")];
     */
    self.detailLanguageAry = @[AcTECLocalizedStringFromTable(@"English", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"ChineseS", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"German", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Norwegian", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Swedish", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Spanish", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Danish", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Italian", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Dutch", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"French", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Portuguese", @"Localizable"),
                               AcTECLocalizedStringFromTable(@"Finnish", @"Localizable")];
    
    [self.tableView reloadData];
}


@end
