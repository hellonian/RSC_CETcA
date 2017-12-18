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
    self.navigationItem.title = @"More";
    self.view.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    
    imageArray = @[@"share",
                   @"time.png",
                   @"update.png",
                   @"remoteImage",
                   @"musicIcon",
                   @"about"];
    titleArray = @[@"Share",@"Timer",@"Update",@"Remote",@"Music",@"About"];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 6;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.text = titleArray[indexPath.row];
    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@",imageArray[indexPath.row]]];
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 54.0;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    [self.delegate didSelectRowAtMaster:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - AutoLayout

- (void)updateViewConstraints {
    [super updateViewConstraints];
//    NSLog(@"updateViewConstraints>>>master");
    [self.tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(64, 0, 0, 0)];
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
