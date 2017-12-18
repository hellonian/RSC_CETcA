//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRAreasMainViewController.h"
#import "CSRDatabaseManager.h"
#import "CSRDevicesManager.h"
#import "CSRAreaTableViewCell.h"
#import "CSRmeshStyleKit.h"
#import "CSRmeshDevice.h"
#import "CSRAreasDetailViewController.h"
#import "CSRAreasSearchMainViewController.h"
#import "CSRLightViewController.h"
#import "CSRUtilities.h"
#import "CSRDeviceEntity.h"
#import "CSRConstants.h"
#import "CSRAppStateManager.h"
#import "CSRSegmentDevicesViewController.h"
#import "CSRMeshUtilities.h"

@interface CSRAreasMainViewController () <UISearchBarDelegate, UISearchControllerDelegate, UISearchDisplayDelegate, UISearchResultsUpdating, UIToolbarDelegate>

{
    NSUInteger selectedIndex;
}
@property (nonatomic) UISearchController *searchController;
@property (nonatomic) CSRAreasSearchMainViewController *areasSearchListTableViewController;

@property BOOL searchControllerWasActive;
@property BOOL searchControllerSearchFieldWasFirstResponder;

@end

@implementation CSRAreasMainViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Set navigation bar colour
    self.navigationController.navigationBar.barTintColor = [CSRUtilities colorFromHex:kColorBlueCSR];
//    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
//    self.navigationItem.backBarButtonItem = nil;
    
    _areasTableView.delegate = self;
    _areasTableView.dataSource = self;
    _areasTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //search View related calls
    _areasSearchListTableViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CSRAreasSearchMainViewController"];
    _searchController = [[UISearchController alloc] initWithSearchResultsController:_areasSearchListTableViewController];
    self.searchController.searchResultsUpdater = self;
    [self.searchController.searchBar sizeToFit];
    self.areasTableView.tableHeaderView = self.searchController.searchBar;
    self.searchBar.placeholder = @"Search for areas";
    
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barTintColor = [CSRUtilities colorFromHex:kColorBlueCSR];
    
    _areasArray = [NSMutableArray new];
    
    [self.areasTableView reloadData];
    
    // restore the searchController's active state
    if (self.searchControllerWasActive) {
        self.searchController.active = self.searchControllerWasActive;
        _searchControllerWasActive = NO;
        
        if (self.searchControllerSearchFieldWasFirstResponder) {
            [self.searchController.searchBar becomeFirstResponder];
            _searchControllerSearchFieldWasFirstResponder = NO;
        }
    }
    
    //Hide search bar
    [self hideSearchBarWithAnimation:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDataModelChange:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:[[CSRDatabaseManager sharedInstance] managedObjectContext]];
    [self refreshDevices:nil];

}

- (void)refreshDevices:(id)sender
{
    [_areasArray removeAllObjects];
    
    _areasArray = [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
    
   
    if (_areasArray != nil || [_areasArray count] != 0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"areaName" ascending:YES]; //@"name"
        [_areasArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
   
    }
    
    [self.areasTableView reloadData];
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_areasArray count];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    CSRAreaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CSRAreaTableViewCellIdentifier];
    
    if (!cell) {
        cell = [[CSRAreaTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRAreaTableViewCellIdentifier];
    }
    
    
    CSRAreaEntity *area = [_areasArray objectAtIndex:indexPath.row];
        
    if (area.areaName != nil){
        cell.areaNameLabel.text = area.areaName;
    }
    if (area.devices && [area.devices count] > 1) {
        cell.numberOfAreasLabel.text = [NSString stringWithFormat:@"%tu Devices", [area.devices count]];
    }
    if ([area.devices count] == 1) {
        cell.numberOfAreasLabel.text = [NSString stringWithFormat:@"%tu Device", [area.devices count]];
    }
    if ([area.devices count] < 1) {
        cell.numberOfAreasLabel.text = @"0 Devices";
    }

    //Create accessory view for each cell
    UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 0., 65., 65.)];
    [accessoryButton setBackgroundImage:[CSRmeshStyleKit imageOfAccessoryGear ] forState:UIControlStateNormal];
    [accessoryButton addTarget:self action:(@selector(accessoryButtonTapped:)) forControlEvents:UIControlEventTouchUpInside];
    accessoryButton.tag = indexPath.row;
    
    //Added for automation
//    accessoryButton.isAccessibilityElement = YES;
//    accessoryButton.accessibilityLabel = area.areaName;
    
    cell.accessoryView = accessoryButton;

    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSRAreaEntity *areaEntity = [_areasArray objectAtIndex:indexPath.row];
    selectedIndex = indexPath.row;
    
    if ([areaEntity.devices count] >= 1) {
        
        NSMutableArray *_devicesMutableArray = [[areaEntity.devices allObjects] mutableCopy];
        NSMutableArray *arrayForHeaterSensor = [NSMutableArray new];
        
        [_devicesMutableArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
            CSRDeviceEntity *deviceEntity = (CSRDeviceEntity*)obj;
            if ([deviceEntity.appearance isEqual:@(CSRApperanceNameLight)] || [deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameSwitch)]) {
                [self performSegueWithIdentifier:@"segmentToDevices" sender:self];
                
            } else if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameHeater)]) {
                [arrayForHeaterSensor addObject:@4];
                
            } else if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameSensor)]) {
                [arrayForHeaterSensor addObject:@5];
                
            }
        }];
        
        if (arrayForHeaterSensor.count == 2) {
            [self performSegueWithIdentifier:@"segmentToDevices" sender:self];
        }
        
    }
    
    return indexPath;
}

#pragma mark - Accessory type action

- (void)accessoryButtonTapped:(UIButton*)sender
{
    UIButton *accessoryButton = (UIButton *)sender;
    selectedIndex = accessoryButton.tag;
    [self performSegueWithIdentifier:@"addAreaSegue" sender:sender];
}

- (IBAction)addArea:(id)sender
{
    [self performSegueWithIdentifier:@"addAreaSegue" sender:sender];

}

- (void)handleDataModelChange:(NSNotification*)notification
{
    [_areasArray removeAllObjects];
    _areasArray = [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
        
    [_areasTableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([segue.identifier isEqualToString:@"addAreaSegue"] &&[sender isKindOfClass:[UIButton class]]) {
//        UINavigationController *navController = (UINavigationController*)[segue destinationViewController];
        CSRAreasDetailViewController *vc = segue.destinationViewController;
        
        CSRAreaEntity *area = [_areasArray objectAtIndex:selectedIndex];
        vc.areaEntity = area;
    }
    if ([segue.identifier isEqualToString:@"segmentToDevices"]) {
        
        CSRAreaEntity *areaEntity = [_areasArray objectAtIndex:selectedIndex];
        CSRSegmentDevicesViewController *vc = segue.destinationViewController;
        vc.areaEntity = areaEntity;
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self hideSearchBarWithAnimation:YES];
    [searchBar resignFirstResponder];
}


#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchText = searchController.searchBar.text;
    NSMutableArray *searchResults = _areasArray;
    
    NSString *strippedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSArray *searchItems = nil;
    if (strippedString.length > 0) {
        searchItems = [strippedString componentsSeparatedByString:@" "];
    }
    
    NSMutableArray *andMatchPredicates = [NSMutableArray array];
    
    for (NSString *searchString in searchItems) {
        
        NSMutableArray *searchItemsPredicate = [NSMutableArray array];
       
        NSExpression *seachFieldName = [NSExpression expressionForKeyPath:@"areaName"];
        NSExpression *searchStringName = [NSExpression expressionForConstantValue:searchString];
        NSPredicate *nameSearchPredicate = [NSComparisonPredicate
                                            predicateWithLeftExpression:seachFieldName
                                            rightExpression:searchStringName
                                            modifier:NSDirectPredicateModifier
                                            type:NSContainsPredicateOperatorType
                                            options:NSCaseInsensitivePredicateOption];
        [searchItemsPredicate addObject:nameSearchPredicate];
        
        NSCompoundPredicate *orMatchPredicates = [NSCompoundPredicate orPredicateWithSubpredicates:searchItemsPredicate];
        [andMatchPredicates addObject:orMatchPredicates];
    }
    
    NSCompoundPredicate *finalCompoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:andMatchPredicates];
    searchResults = [[searchResults filteredArrayUsingPredicate:finalCompoundPredicate] mutableCopy];
    
    // hand over the filtered results to our search results table
    
    CSRAreasSearchMainViewController *tableController = (CSRAreasSearchMainViewController *)self.searchController.searchResultsController;
    tableController.filteredAreasArray = searchResults;
    [tableController.tableView reloadData];
}

#pragma mark - UIStateRestoration

//  we restore several items for state restoration:
//  1) Search controller's active state,
//  2) search text,
//  3) first responder

NSString *const AreasListViewControllerTitleKey = @"AreasListViewControllerTitleKey";
NSString *const AreasListSearchControllerIsActiveKey = @"AreasListSearchControllerIsActiveKey";
NSString *const AreasListSearchBarTextKey = @"AreasListSearchBarTextKey";
NSString *const AreasListSearchBarIsFirstResponderKey = @"AreasListSearchBarIsFirstResponderKey";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.title forKey:AreasListViewControllerTitleKey];
    
    UISearchController *searchController = self.searchController;
    
    BOOL searchDisplayControllerIsActive = searchController.isActive;
    [coder encodeBool:searchDisplayControllerIsActive forKey:AreasListSearchControllerIsActiveKey];
    
    if (searchDisplayControllerIsActive) {
        [coder encodeBool:[searchController.searchBar isFirstResponder] forKey:AreasListSearchBarIsFirstResponderKey];
    }
    
    [coder encodeObject:searchController.searchBar.text forKey:AreasListSearchBarTextKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.title = [coder decodeObjectForKey:AreasListViewControllerTitleKey];
    _searchControllerWasActive = [coder decodeBoolForKey:AreasListSearchControllerIsActiveKey];
    _searchControllerSearchFieldWasFirstResponder = [coder decodeBoolForKey:AreasListSearchBarIsFirstResponderKey];
    
    // restore the text in the search field
    self.searchController.searchBar.text = [coder decodeObjectForKey:AreasListSearchBarTextKey];
}


#pragma mark - Hide SearchBar

- (void)hideSearchBarWithAnimation:(BOOL)animated
{
    if ([[CSRDevicesManager sharedInstance] getTotalAreas] > 0) {
        
        [self.areasTableView setContentOffset:CGPointMake(0, 44) animated:YES];
        
    }
}


#pragma mark - Navigation Bar item menthods

- (IBAction)showSearch:(id)sender
{
    [self.areasTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    [self.searchController setActive:YES];
    [self.searchBar becomeFirstResponder];
}


@end
