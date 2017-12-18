//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//


#import "CSRAreaSelectionSearchTableViewController.h"
#import "CSRmeshStyleKit.h"
#import "CSRAreaEntity.h"
#import "CSRAreaSelectionManager.h"

@interface CSRAreaSelectionSearchTableViewController ()
{
    int selectedIndex;
}
@end

@implementation CSRAreaSelectionSearchTableViewController


- (void)viewWillAppear:(BOOL)animated
{
    self.areaIdArray = [NSMutableArray new];
    
    NSSet *alreadyPresentAreasSet = _deviceEntity.areas;
    _listOfLocalAreas = [NSMutableArray array];
    for (CSRAreaEntity *areaObj in alreadyPresentAreasSet) {
        [_listOfLocalAreas addObject:areaObj];
        [self.areaIdArray addObject:areaObj.areaID];
    }

}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
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
    return _filteredGroupsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupFilterTableViewCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupFilterTableViewCell"];
    }
    
    CSRAreaEntity *areaEntity;
    if (_filteredGroupsArray && [_filteredGroupsArray count] > 0) {
        
        areaEntity =  [_filteredGroupsArray objectAtIndex:indexPath.row];
        cell.textLabel.text = areaEntity.areaName;

        
    }
    
    if ([self hasDeviceGotAreaWithId:areaEntity.areaID]) {
        
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    if ([self.areaIdArray containsObject:areaEntity.areaID]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    
    CSRAreaEntity *area = [_filteredGroupsArray objectAtIndex:indexPath.row];
    
    
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
