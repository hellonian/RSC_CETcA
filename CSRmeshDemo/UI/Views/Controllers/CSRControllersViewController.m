//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSRControllersViewController.h"
#import "CSRNewControllersViewController.h"
#import "CSRAppStateManager.h"
#import "CSRUtilities.h"
#import "CSRControllerEntity.h"
#import "CSRControllerDetailsVC.h"
#import "CSRParseAndLoad.h"
#import "CSRmeshStyleKit.h"
#import "CSRShareDatabaseVC.h"

@interface CSRControllersViewController () {
    NSUInteger selectedIndex;
    CSRControllerEntity *controllerEntity;
}

@property (nonatomic, retain) NSArray *controllersArray;
//@property (nonatomic, retain) NSMutableArray *styleArray;

@end

@implementation CSRControllersViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _transferDataView.hidden = YES;
    _controllersArray = [NSMutableArray new];
    _controllersArray = [[[CSRAppStateManager sharedInstance].selectedPlace.controllers allObjects] mutableCopy];
    [_controllersTableView reloadData];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _controllersTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

//    _controllersArray = @[@{@"name" : @"Kitchen's tablet"},
//                          @{ @"name" : @"Rose's phone"},
//                          @{ @"name" : @"John's iPhone"}];
//    
//    _styleArray = [NSMutableArray new];
//    
//    NSDictionary * wordToColorMapping = @{@"Up to date" : [UIColor blackColor], @"Never updated" : [UIColor redColor], [NSString stringWithFormat:@"Last update: %@", [NSDate date]] : [UIColor orangeColor]};
//    for (NSString * word in wordToColorMapping) {
//        UIColor * color = [wordToColorMapping objectForKey:word];
//        NSDictionary * attributes = [NSDictionary dictionaryWithObject:color forKey:NSForegroundColorAttributeName];
//        NSAttributedString * subString = [[NSAttributedString alloc] initWithString:word attributes:attributes];
//        [_styleArray addObject:subString];
//    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [_controllersArray count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"controllersTableCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"controllersTableCell"];
    }
    controllerEntity = [_controllersArray objectAtIndex:indexPath.row];
    cell.textLabel.text = controllerEntity.controllerName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", controllerEntity.updateDate];
    
    //Create accessory view for each cell
    UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 0, 60, 60)];
    [accessoryButton setBackgroundImage:[CSRmeshStyleKit imageOfIconExport] forState:UIControlStateNormal];
    [accessoryButton addTarget:self action:(@selector(refreshButtonTapped:)) forControlEvents:UIControlEventTouchUpInside];
    accessoryButton.tag = indexPath.row;
    cell.accessoryView = accessoryButton;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedIndex = indexPath.row;
    [self performSegueWithIdentifier:@"controllerDetailsSegue" sender:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Accessory type action

- (void)refreshButtonTapped:(UIButton*)sender
{
    [self performSegueWithIdentifier:@"databaseSharingSegue" sender:sender];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"controllerDetailsSegue"]) {
        CSRControllerDetailsVC *vc = [segue destinationViewController];
        
        controllerEntity = [_controllersArray objectAtIndex:selectedIndex];
        vc.controllerEntity = controllerEntity;

        
    } else if ([segue.identifier isEqualToString:@"newControllerSegue"]) {
        
    } else if ([segue.identifier isEqualToString:@"databaseSharingSegue"]) {
        CSRShareDatabaseVC *vc = segue.destinationViewController;
        vc.popoverPresentationController.delegate = self;
        vc.popoverPresentationController.presentedViewController.view.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        vc.popoverPresentationController.presentedViewController.view.layer.borderWidth = 0.5;
        vc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20, 190);
        
        vc.parentVC = self;
        vc.deviceID = controllerEntity.deviceId;

    }
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return NO;
}

- (IBAction)addControllerAction:(id)sender {
    
    [self performSegueWithIdentifier:@"newControllerSegue" sender:nil];
}

- (IBAction)unwindToMain:(UIStoryboardSegue*)sender {
    
}


@end
