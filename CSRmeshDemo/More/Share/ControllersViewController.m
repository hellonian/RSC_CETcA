//
//  ControllersViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/15.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "ControllersViewController.h"
#import "NewControllersViewController.h"
#import "CSRControllerEntity.h"
#import "CSRAppStateManager.h"
#import "CSRmeshStyleKit.h"
#import "ControllerDetailVC.h"

@interface ControllersViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    NSUInteger selectedIndex;
    CSRControllerEntity *controllerEntity;
}
@property (nonatomic, retain) NSArray *controllersArray;

@end

@implementation ControllersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"Controllers";
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addControllerAction)];
    self.navigationItem.rightBarButtonItem = add;
    
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _controllersArray = [NSMutableArray new];
    _controllersArray = [[[CSRAppStateManager sharedInstance].selectedPlace.controllers allObjects] mutableCopy];
    [_tableView reloadData];
    
}

- (void)addControllerAction {
    NewControllersViewController *nvc = [[NewControllersViewController alloc] init];
    
    [self.navigationController pushViewController:nvc animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [_controllersArray count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"controllersTableCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"controllersTableCell"];
        cell.detailTextLabel.numberOfLines = 0;
    }
    controllerEntity = [_controllersArray objectAtIndex:indexPath.row];
    cell.textLabel.text = controllerEntity.controllerName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", controllerEntity.updateDate];
    
    //Create accessory view for each cell
//    UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 0, 60, 60)];
//    [accessoryButton setBackgroundImage:[CSRmeshStyleKit imageOfIconExport] forState:UIControlStateNormal];
//    [accessoryButton addTarget:self action:(@selector(refreshButtonTapped:)) forControlEvents:UIControlEventTouchUpInside];
//    accessoryButton.tag = indexPath.row;
//    cell.accessoryView = accessoryButton;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedIndex = indexPath.row;
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    ControllerDetailVC *cdvc = [[ControllerDetailVC alloc] init];
    controllerEntity = [_controllersArray objectAtIndex:selectedIndex];
    cdvc.controllerEntity = controllerEntity;
    [self.navigationController pushViewController:cdvc animated:YES];
    
}


@end
