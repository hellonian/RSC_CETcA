//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRAreasSearchMainViewController.h"
#import "CSRAreaTableViewCell.h"
#import "CSRAreasDetailViewController.h"
#import "CSRmeshStyleKit.h"
#import "CSRAreaEntity.h"
#import "CSRDevicesManager.h"

@interface CSRAreasSearchMainViewController ()
{
    NSUInteger selectedIndex;
}

@end

@implementation CSRAreasSearchMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
//    [self.tableView registerNib:[UINib nibWithNibName:@"CSRAreaTableViewCell" bundle:nil] forCellReuseIdentifier:CSRAreaTableViewCellIdentifier];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _filteredAreasArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"areaTableViewCellIdentifier"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"areaTableViewCellIdentifier"];
    }
    
    CSRAreaEntity *areaEntity =  [_filteredAreasArray objectAtIndex:indexPath.row];
//    CSRmeshArea *meshArea = [[CSRDevicesManager sharedInstance] getAreaFromId:areaEntity.areaID];
    
    if (areaEntity.areaName != nil) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", areaEntity.areaName];
//        cell.imageView.image = [CSRmeshStyleKit imageOfAreaDevice];
    }

    
//    if (_filteredAreasArray && [_filteredAreasArray count] > 0) {
//        
//        NSDictionary *areasDict = [_filteredAreasArray objectAtIndex:indexPath.row];
//        
//        NSLog(@"filtered item: %@", areasDict);
//        
//        if ([[areasDict allKeys] count] > 0) {
//            
//            if ([areasDict[@"type"] isEqualToString:@"light"]) {
//                
//                cell.textLabel.text = areasDict[@"name"];
//
//            } else if ([areasDict[@"type"] isEqualToString:@"temperature"]) {
//                
//                cell.textLabel.text = areasDict[@"name"];
//                
//            } else if ([areasDict[@"type"] isEqualToString:@"lock"]) {
//                
//                cell.textLabel.text = areasDict[@"name"];
//                
//            }
//        }
    
//    }
    
    //Create accessory view for each cell
    UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(0., 0., 30., 30.)];
    [accessoryButton setBackgroundImage:[CSRmeshStyleKit imageOfGear] forState:UIControlStateNormal];
    [accessoryButton addTarget:self action:(@selector(accessoryButtonTapped:)) forControlEvents:UIControlEventTouchUpInside];
    accessoryButton.tag = indexPath.row;
    
    cell.accessoryView = accessoryButton;
    
    return cell;
}
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedIndex = indexPath.row;
    
//    [_delegate selectedItemIndex:indexPath.row];
    
//    [self displayLightControl];
    
//    [self performSegueWithIdentifier:@"searchedAreaConfigurationSegue" sender:nil];
    
    return indexPath;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"searchedAreaConfigurationSegue"]) {
        CSRAreasDetailViewController *vc = segue.destinationViewController;
        
        CSRAreaEntity *areaEntity =  [_filteredAreasArray objectAtIndex:selectedIndex];
        CSRmeshArea *meshArea = [[CSRDevicesManager sharedInstance] getAreaFromId:areaEntity.areaID];
        vc.area = meshArea;
    }
}

#pragma mark - Accessory type action

- (void)accessoryButtonTapped:(id)sender
{
    UIButton *accessoryButton = (UIButton *)sender;
    NSLog(@"Acessory button tapped at index: %li", (long)accessoryButton.tag);
    selectedIndex = accessoryButton.tag;
    [self performSegueWithIdentifier:@"searchedAreaConfigurationSegue" sender:self];
}

@end
