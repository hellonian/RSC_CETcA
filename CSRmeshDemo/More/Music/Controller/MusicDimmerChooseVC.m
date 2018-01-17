//
//  MusicDimmerChooseVC.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/12/8.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "MusicDimmerChooseVC.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceEntity.h"

@interface MusicDimmerChooseVC ()

@property (nonatomic,strong) NSMutableArray *dataArray;
@property (nonatomic,strong) NSMutableArray *boolArray;
@property (nonatomic,strong) NSMutableArray *devicesArray;

@end

@implementation MusicDimmerChooseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.title = @"Choose Dimmer";
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
    self.navigationItem.leftBarButtonItem = left;
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = right;
}

- (void)backAction {
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)doneAction {
    if (self.hande) {
        self.hande(self.devicesArray);
    }
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.dataArray removeAllObjects];
    [self.boolArray removeAllObjects];
    [self.devicesArray removeAllObjects];
    NSMutableArray *mutableArray = [[[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects] mutableCopy];
    if (mutableArray != nil || [mutableArray count] != 0) {
        for (CSRDeviceEntity *deviceEntity in mutableArray) {
            if ([deviceEntity.shortName isEqualToString:@"D350BT"]) {
                [self.dataArray addObject:deviceEntity];
            }
        }
        for (int i = 0; i<self.dataArray.count; i++) {
            BOOL isSelected = NO;
            [self.boolArray addObject:@(isSelected)];
        }
        [self.tableView reloadData];
    }
}

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc] init];
    }
    return _dataArray;
}
-(NSMutableArray *)boolArray {
    if (!_boolArray) {
        _boolArray = [[NSMutableArray alloc] init];
    }
    return _boolArray;
}
-(NSMutableArray *)devicesArray {
    if (!_devicesArray) {
        _devicesArray = [[NSMutableArray alloc] init];
    }
    return _devicesArray;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dimmercell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"dimmercell"];
        
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    CSRDeviceEntity *deviceEntity = self.dataArray[indexPath.row];
    cell.textLabel.text = deviceEntity.name;
    NSNumber *num = self.boolArray[indexPath.row];;
    BOOL isSelected = [num boolValue];
    if (isSelected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *num = self.boolArray[indexPath.row];
    BOOL isSelected = [num boolValue];
    isSelected = !isSelected;
    [self.boolArray replaceObjectAtIndex:indexPath.row withObject:@(isSelected)];
    CSRDeviceEntity *deviceEntity = self.dataArray[indexPath.row];
    if (isSelected) {
        [self.devicesArray addObject:deviceEntity];
    }else {
        if ([self.devicesArray containsObject:deviceEntity]) {
            [self.devicesArray removeObject:deviceEntity];
        }
    }
    NSArray *ary = [[NSArray alloc] initWithObjects:indexPath, nil];
    [self.tableView reloadRowsAtIndexPaths:ary withRowAnimation:UITableViewRowAnimationFade];
    
    
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
