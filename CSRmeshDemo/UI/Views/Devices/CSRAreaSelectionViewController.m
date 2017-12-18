//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRAreaSelectionViewController.h"
#import "CSRAreaSelectionSearchTableViewController.h"
#import "CSRAppStateManager.h"
#import "CSRMenuSlidingSegue.h"
#import "CSRmeshStyleKit.h"
#import "CSRUtilities.h"
#import "CSRConstants.h"
#import "CSRmeshArea.h"
#import "CSRDatabaseManager.h"
#import "CSRDeviceEntity.h"
#import "CSRDevicesManager.h"
#import "CSRAreaSelectionManager.h"

@interface CSRAreaSelectionViewController () <UISearchBarDelegate, UISearchControllerDelegate, UISearchDisplayDelegate, UISearchResultsUpdating>
{
    NSUInteger selectedIndex;
    NSUInteger wizardMode;
}

@property (nonatomic) UISearchController *searchController;
@property (nonatomic) CSRAreaSelectionSearchTableViewController *groupSelectionSearchTableViewController;

// for state restoration
@property BOOL searchControllerWasActive;
@property BOOL searchControllerSearchFieldWasFirstResponder;


@end

@implementation CSRAreaSelectionViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = _selectedDevice.name;
    
    //Adjust navigation controller appearance
    self.showNavMenuButton = NO;
    self.showNavSearchButton = YES;
    
    //Set navigation bar colour
    self.navigationController.navigationBar.barTintColor = [CSRUtilities colorFromHex:kColorAmber600];
    
    [super adjustNavigationControllerAppearance];
    
    //Add table delegates
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    _actualData = (NSMutableData*)_deviceEntity.groups;
    
    //Search controller details
    _groupSelectionSearchTableViewController = [[CSRAreaSelectionSearchTableViewController alloc] init];
    _searchController = [[UISearchController alloc] initWithSearchResultsController:_groupSelectionSearchTableViewController];
    self.searchController.searchResultsUpdater = self;
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.searchBar.placeholder = @"Search for groups";
    
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    
    //State control
    self.definesPresentationContext = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBarTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
    [self.tableView reloadData];
    
    self.areaIdArray = [NSMutableArray new];
    
    NSSet *alreadyPresentAreasSet = _deviceEntity.areas;
    _listOfLocalAreas = [NSMutableArray array];
    for (CSRAreaEntity *areaObj in alreadyPresentAreasSet) {
        [_listOfLocalAreas addObject:areaObj];
        [self.areaIdArray addObject:areaObj.areaID];
    }
    
    _areasArray = [NSMutableArray new];
    _areasArray = [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshGroups:) name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
    
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDataModelChange:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:[[CSRDatabaseManager sharedInstance] managedObjectContext]];
    
    
}

- (void)dealloc
{
    self.view = nil;
}

- (void)refreshGroups:(id)sender
{
    
    [self.tableView reloadData];
    
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupTableViewCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupTableViewCell"];
    }
    
    
    CSRAreaEntity *areaObj = [_areasArray objectAtIndex:indexPath.row];
    if (_areasArray.count != 0) {
        cell.textLabel.text = areaObj.areaName;
        
    } else {
        cell.textLabel.text = @"No Groups";

    }

    if ([self hasDeviceGotAreaWithId:areaObj.areaID] || [self.areaIdArray containsObject:areaObj.areaID]) {
        
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
   
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    
    CSRAreaEntity *area = [_areasArray objectAtIndex:indexPath.row];
    

    if (self.areaIdArray.count < [_deviceEntity.nGroups integerValue] || [_areaIdArray containsObject:area.areaID]) {
        if ([self.areaIdArray containsObject:area.areaID]) {
            [self.areaIdArray removeObject:area.areaID];
            [[CSRAreaSelectionManager sharedInstance] deleteAreaForDevice:_deviceEntity withAreaID:area.areaID];
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            [self.areaIdArray addObject:area.areaID];
            [[CSRAreaSelectionManager sharedInstance] writeAreaForDevice:_deviceEntity withAreaID:area.areaID];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Exceeded"
                                                        message:@"You exceeded your writes"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
    
    
    selectedIndex = indexPath.row;
    
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
    [self.tableView reloadData];
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
        
        // name field matching
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
    
    CSRAreaSelectionSearchTableViewController *tableController = (CSRAreaSelectionSearchTableViewController *)self.searchController.searchResultsController;
    tableController.deviceEntity = _deviceEntity;
    tableController.filteredGroupsArray = searchResults;
    tableController.areaIdArray = self.areaIdArray;
    [tableController.tableView reloadData];
}

#pragma mark - UIStateRestoration

//  we restore several items for state restoration:
//  1) Search controller's active state,
//  2) search text,
//  3) first responder

NSString *const GroupSelectionViewControllerTitleKey = @"GroupSelectionViewControllerTitleKey";
NSString *const GroupSelectionSearchControllerIsActiveKey = @"GroupSelectionSearchControllerIsActiveKey";
NSString *const GroupSelectionSearchBarTextKey = @"GroupSelectionSearchBarTextKey";
NSString *const GroupSelectionSearchBarIsFirstResponderKey = @"GroupSelectionSearchBarIsFirstResponderKey";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.title forKey:GroupSelectionViewControllerTitleKey];
    
    UISearchController *searchController = self.searchController;
    
    BOOL searchDisplayControllerIsActive = searchController.isActive;
    [coder encodeBool:searchDisplayControllerIsActive forKey:GroupSelectionSearchControllerIsActiveKey];
    
    if (searchDisplayControllerIsActive) {
        [coder encodeBool:[searchController.searchBar isFirstResponder] forKey:GroupSelectionSearchBarTextKey];
    }
    
    [coder encodeObject:searchController.searchBar.text forKey:GroupSelectionSearchBarTextKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.title = [coder decodeObjectForKey:GroupSelectionViewControllerTitleKey];
    _searchControllerWasActive = [coder decodeBoolForKey:GroupSelectionSearchControllerIsActiveKey];
    _searchControllerSearchFieldWasFirstResponder = [coder decodeBoolForKey:GroupSelectionSearchBarIsFirstResponderKey];
    
    // restore the text in the search field
    self.searchController.searchBar.text = [coder decodeObjectForKey:GroupSelectionSearchBarTextKey];
}

#pragma mark - Hide SearchBar

- (void)hideSearchBarWithAnimation:(BOOL)animated
{
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
    //Force the hide header animation - just in case
    [self.tableView setContentOffset:CGPointMake(0, 44) animated:animated];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue isKindOfClass:[CSRMenuSlidingSegue class]]) {
        [super showCoverView];
    }
}

- (IBAction)addAreaButtonTapped:(id)sender
{
    
    [self performSegueWithIdentifier:@"addAreaSegue" sender:sender];
    
}

- (void)handleDataModelChange:(NSNotification*)notification
{
    [_areasArray removeAllObjects];
    _areasArray = [[[CSRAppStateManager sharedInstance].selectedPlace.areas allObjects] mutableCopy];
    
    NSSet *alreadyPresentAreasSet = _deviceEntity.areas;
    [_listOfLocalAreas removeAllObjects];
    for (CSRAreaEntity *areaObj in alreadyPresentAreasSet) {
        [_listOfLocalAreas addObject:areaObj];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Pseudo Navigation Bar item menthods

//fill the _actualData
- (NSMutableArray*) fillTheActualData
{
    NSMutableArray *desiredGroups = [NSMutableArray array];
    uint16_t *actual = (uint16_t*)_actualData.bytes;
    
    for (int count=0; count < _actualData.length/2; count++, actual++) {
        NSNumber *desired = @(*actual);
        [desiredGroups addObject:desired];
    }
    return desiredGroups;
}

- (IBAction)save:(id)sender
{
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:spinner];
    spinner.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [spinner startAnimating];
    
    NSMutableArray *allGroupsData = [NSMutableArray new];
    allGroupsData = [self fillTheActualData];
    
    _deviceEntity.areas = nil;
    __block uint16_t groupIndex = 0;
    
    [allGroupsData enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *desired = (NSNumber*)obj;
        
        [[GroupModelApi sharedInstance] setModelGroupId:_deviceEntity.deviceId
                                                modelNo:@(0xff)
                                             groupIndex:@(groupIndex)
                                               instance:@(0)
                                                groupId:desired
                                                success:^(NSNumber * _Nullable deviceId,
                                                          NSNumber * _Nullable modelNo,
                                                          NSNumber * _Nullable groupIndex,
                                                          NSNumber * _Nullable instance,
                                                          NSNumber * _Nullable groupId) {
                                                    
                                                    NSMutableData *groups = [NSMutableData dataWithData:_deviceEntity.groups];
                                                    
                                                    // Add received group to array of groups for this device and save
                                                    int offset = (int) [groupIndex integerValue];
                                                    uint16_t *group = groups.mutableBytes;
                                                    group += offset;
                                                    uint16_t groupToBeReplaced = *group;
                                                    *group = [groupId unsignedShortValue];
                                                    
                                                    
                                                    // Add or remove area to device
                                                    if ([groupId unsignedShortValue] == 0) {
                                                        groupId = @(groupToBeReplaced);
                                                    }
                                                    
                                                    CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:desired];
                                                    
                                                    if (areaEntity) {
                                                        
                                                        if ([desired unsignedShortValue] == 0) {
                                                            
                                                            [_deviceEntity removeAreasObject:areaEntity];
                                                            
                                                        } else {
                                                            
                                                            [_deviceEntity addAreasObject:areaEntity];
                                                            
                                                        }
                                                    }
                                                    _deviceEntity.groups = groups;
                                                    [[CSRDatabaseManager sharedInstance] saveContext];
                                                    
                                                } failure:^(NSError * _Nullable error) {
                                                    
                                                    NSLog(@"mesh timeout");
                                                }];
    }];
    
    [self performSelector:@selector(dismissViewController:) withObject:spinner afterDelay:2];
    
}

- (void) dismissViewController:(UIActivityIndicatorView*)spin
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRRefreshNotification object:self userInfo:nil];
    [spin stopAnimating];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - search Action

- (IBAction)showSearch:(id)sender
{
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    [self.searchController setActive:YES];
    [self.searchBar becomeFirstResponder];
    
}

#pragma mark - Actions

- (IBAction)back:(id)sender
{
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Helper method

- (BOOL)hasDeviceGotAreaWithId:(NSNumber *)areaId
{
    __block BOOL areaFound = NO;
    
    [_listOfLocalAreas enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([((CSRAreaEntity *)obj).areaID intValue] == [areaId intValue]) {
            
            areaFound = YES;
            
            *stop = YES;
        
        }
        
    }];
    
    return areaFound;
}

@end
