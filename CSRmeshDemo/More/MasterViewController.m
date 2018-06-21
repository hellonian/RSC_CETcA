//
//  MasterViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/8/31.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MasterViewController.h"
#import "PureLayout.h"

@interface MasterViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    NSArray *imageArray;
    NSArray *titleArray;
}

@property (nonatomic,strong) UITableView *tableView;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange) name:ZZAppLanguageDidChangeNotification object:nil];
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Setting", @"Localizable");
    self.view.backgroundColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1];
    
    imageArray =@[@[@"Setting_places"],
                  @[@"Setting_timer",
                    @"Setting_remote",
                    @"Setting_sensor",
                    @"Setting_FWupgrade"],
                  @[@"Setting_language",
                    @"Setting_help",
                    @"Setting_about"]];
    titleArray = @[@[AcTECLocalizedStringFromTable(@"Place", @"Localizable")],
                   @[AcTECLocalizedStringFromTable(@"Timer", @"Localizable"),
                     AcTECLocalizedStringFromTable(@"Remote", @"Localizable"),
                     AcTECLocalizedStringFromTable(@"LightSensor", @"Localizable"),
                     AcTECLocalizedStringFromTable(@"BTVersion", @"Localizable")],
                   @[AcTECLocalizedStringFromTable(@"Language", @"Localizable"),
                     AcTECLocalizedStringFromTable(@"Help", @"Localizable"),
                     AcTECLocalizedStringFromTable(@"About", @"Localizable")]];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.view addSubview:self.tableView];
    
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [titleArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *array = titleArray[section];
    return [array count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
    }
    cell.textLabel.text = titleArray[indexPath.section][indexPath.row];
    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@",imageArray[indexPath.section][indexPath.row]]];
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 42.0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    [self.delegate didSelectRowAtMaster:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - AutoLayout

- (void)updateViewConstraints {
    [super updateViewConstraints];
    [self.tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(64, 0, 0, 0)];
}

- (void)languageChange {
    self.navigationItem.title = AcTECLocalizedStringFromTable(@"Setting", @"Localizable");
    titleArray = @[@[AcTECLocalizedStringFromTable(@"Place", @"Localizable")],
                   @[AcTECLocalizedStringFromTable(@"Timer", @"Localizable"),
                     AcTECLocalizedStringFromTable(@"Remote", @"Localizable"),
                     AcTECLocalizedStringFromTable(@"LightSensor", @"Localizable"),
                     AcTECLocalizedStringFromTable(@"BTVersion", @"Localizable")],
                   @[AcTECLocalizedStringFromTable(@"Language", @"Localizable"),
                     AcTECLocalizedStringFromTable(@"Help", @"Localizable"),
                     AcTECLocalizedStringFromTable(@"About", @"Localizable")]];
    [self.tableView reloadData];
}

@end
