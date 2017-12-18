//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRPlacesSearchTableViewController.h"
#import "CSRPlaceTableViewCell.h"
#import "CSRPlaceDetailsViewController.h"
#import "CSRAppStateManager.h"
#import "CSRmeshStyleKit.h"
#import "CSRUtilities.h"
#import "CSRConstants.h"

@interface CSRPlacesSearchTableViewController ()
{
    NSUInteger selectedIndex;
}

@end

@implementation CSRPlacesSearchTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    //Initialize table cell
    [self.tableView registerNib:[UINib nibWithNibName:@"CSRPlaceTableViewCell" bundle:nil]
         forCellReuseIdentifier:CSRPlaceTableViewCellIdentifier];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _filteredPlacesArray.count;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    CSRPlaceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CSRPlaceTableViewCellIdentifier];
    
    if (!cell) {
        cell = [[CSRPlaceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRPlaceTableViewCellIdentifier];
    }
    
    if (_filteredPlacesArray && [_filteredPlacesArray count] > 0) {
        
        CSRPlaceEntity *placeEntity = [_filteredPlacesArray objectAtIndex:indexPath.row];
        
        if (placeEntity) {
            
            if (placeEntity.iconID) {
                
                NSArray *placeIcons = kPlaceIcons;
                
                [placeIcons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    
                    NSDictionary *placeDictionary = (NSDictionary *)obj;
                    
                    if ([placeDictionary[@"id"] integerValue] > -1 && [placeDictionary[@"id"] integerValue] == [placeEntity.iconID integerValue]) {
                        
                        SEL imageSelector = NSSelectorFromString(placeDictionary[@"iconImage"]);
                        
                        if ([CSRmeshStyleKit respondsToSelector:imageSelector]) {
                            
                            cell.placeIcon.image = [CSRmeshStyleKit performSelector:imageSelector];
                            
                        }
                        
                        *stop = YES;
                    }
                }];
                
            }
            
            cell.placeIcon.image = [cell.placeIcon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.placeIcon.tintColor = [UIColor whiteColor];
            
            cell.placeIcon.backgroundColor = [CSRUtilities colorFromRGB:[placeEntity.color integerValue]];
            cell.placeIcon.layer.cornerRadius = 5;
            cell.placeIcon.layer.borderColor = [[UIColor lightGrayColor] CGColor];
            cell.placeIcon.layer.borderWidth = .5;
            
            cell.placeNameLabel.text = placeEntity.name;
            cell.placeOwnerNameLabel.text = placeEntity.owner;
            
            if ([placeEntity isEqual:[CSRAppStateManager sharedInstance].selectedPlace]) {
                
                cell.currentPlaceIndicator.hidden = NO;
                cell.currentPlaceIndicator.image = [CSRmeshStyleKit imageOfThick_circle];
                
            }
            
        }
        
    }
    
    //Create accessory view for each cell
    UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(0., 0., 30., 30.)];
    [accessoryButton setBackgroundImage:[CSRmeshStyleKit imageOfGear] forState:UIControlStateNormal];
    [accessoryButton addTarget:self action:(@selector(accessoryButtonTapped:)) forControlEvents:UIControlEventTouchUpInside];
    accessoryButton.tag = indexPath.row;
    
    cell.accessoryView = accessoryButton;
    
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"searchedPlaceConfigurationSegue"]) {
        
        CSRPlaceDetailsViewController *vc = segue.destinationViewController;
        
        if ((int)selectedIndex > -1) {
            
            vc.placeEntity = [_filteredPlacesArray objectAtIndex:selectedIndex];
            
        }
        
    }
    
}

#pragma mark - Accessory type action

- (void)accessoryButtonTapped:(id)sender
{
    UIButton *accessoryButton = (UIButton *)sender;
    NSLog(@"Acessory button tapped at index: %li", (long)accessoryButton.tag);
    selectedIndex = accessoryButton.tag;
    [self performSegueWithIdentifier:@"searchedPlaceConfigurationSegue" sender:self];
}

@end
