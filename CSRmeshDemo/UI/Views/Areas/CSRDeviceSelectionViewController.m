//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRDeviceSelectionViewController.h"
#import "CSRDeviceEntity.h"
#import "CSRUtilities.h"
#import "CSRConstants.h"
#import "CSRmeshStyleKit.h"
#import "CSRDatabaseManager.h"
#import "CSRmeshDevice.h"
#import "CSRDevicesManager.h"
#import "CSRDeviceSelectionTableViewCell.h"
#import "CSRAppStateManager.h"

@interface CSRDeviceSelectionViewController ()
{
    NSUInteger selectedIndex;
}

@end

@implementation CSRDeviceSelectionViewController

- (void) viewWillAppear:(BOOL)animated
{
    _devicesArray = [[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //Set navigation buttons
//    _backButton = [[UIBarButtonItem alloc] init];
//    _backButton.image = [CSRmeshStyleKit imageOfBack_arrow];
//    _backButton.action = @selector(back:);
//    _backButton.target = self;
    //Added for automation
//    _backButton.isAccessibilityElement = YES;
//    _backButton.accessibilityLabel = @"back";
    
    
//    [super addCustomBackButtonItem:_backButton];

    _deviceSelctionTableView.dataSource = self;
    _deviceSelctionTableView.delegate = self;
    _deviceSelctionTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    _theDefaultArray = [NSMutableArray new];
    _theNewArray = [NSMutableArray new];
    _theAddArray = [NSMutableArray new];
    _theDeleteArray = [NSMutableArray new];

   
    NSSet *alreadyPresentDevicesSet = _areaEntity.devices;
    _listOfLocalDevices = [NSMutableArray array];
    for (CSRDeviceEntity *deviceObj in alreadyPresentDevicesSet) {
        [_listOfLocalDevices addObject:deviceObj];
        [_theDefaultArray addObject:deviceObj.deviceId];
    }
    [_theNewArray addObjectsFromArray:_theDefaultArray];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_devicesArray count];
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
    
    CSRDeviceSelectionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CSRDeviceSelectionTableViewCellIdentifier];
    
    if (!cell) {
        cell = [[CSRDeviceSelectionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRDeviceSelectionTableViewCellIdentifier];
    }
    
    
    CSRDeviceEntity *deviceEntity = [_devicesArray objectAtIndex:indexPath.row];
    
    if (deviceEntity) {
        
    if (deviceEntity.name != nil) {
        cell.deviceNameLabel.text = deviceEntity.name;
    } else {
        cell.deviceNameLabel.text = [NSString stringWithFormat:@"device %ld", (long)indexPath.row];
    }
    //Added for automation
        cell.deviceNameLabel.isAccessibilityElement = YES;
        cell.deviceNameLabel.accessibilityLabel = cell.deviceNameLabel.text;
        
        if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameLight)]) {
            cell.deviceIcon.image = [CSRmeshStyleKit imageOfLightDevice_on];
        } else if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameSensor)]) {
            cell.deviceIcon.image = [CSRmeshStyleKit imageOfSensorDevice];
        } else if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameHeater)]) {
            cell.deviceIcon.image = [CSRmeshStyleKit imageOfHeaterDevice];
        } else if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameSwitch)]) {
            cell.deviceIcon.image = [CSRmeshStyleKit imageOfOnOff];
        } else {
            cell.deviceIcon.image = [CSRmeshStyleKit imageOfMesh_device];
        }
    }
    
    if ([self hasAreaGotDeviceWithId:deviceEntity.deviceId]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    
    CSRDeviceEntity *deviceEntity = [_devicesArray objectAtIndex:indexPath.row];
    
    if ([_theNewArray containsObject:deviceEntity.deviceId]) {
        [_theNewArray removeObject:deviceEntity.deviceId];
        //[self deleteGroup:deviceEntity.deviceId];
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        [_theNewArray addObject:deviceEntity.deviceId];
        //[self writeGroup:deviceEntity.deviceId];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    selectedIndex = indexPath.row;
}


- (BOOL) isDeviceMemberOfArea:(NSNumber*)deviceId areaId:(NSNumber*)areaId
{
    CSRDeviceEntity *deviceEntity = [_devicesArray objectAtIndex:selectedIndex];
    uint16_t area = [areaId unsignedShortValue];
    uint16_t *areas = (uint16_t*)deviceEntity.groups.bytes;
    
    BOOL found = NO;
    for (int i =0; i < deviceEntity.groups.length/2; i++) {
        if (*areas == area) {
            return NO;
        }
        if (*areas == 0) {
            found = YES;
        
        }
    }
    
    return found;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveDevicesSelection:(id)sender
{
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:spinner];
    spinner.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [spinner startAnimating];
    
    
    [self sendOfData];
    
    [self performSelector:@selector(dismissViewController:) withObject:spinner afterDelay:4];
    
}

- (void) getAddArray
{
    //add - new to default

    [_theNewArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![_theDefaultArray containsObject:obj]) {
            [_theAddArray addObject:obj];
        }
    }];
    
}
- (void) getDeleteArray
{
    //delete - default to new
    [_theDefaultArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![_theNewArray containsObject:obj]) {
            [_theDeleteArray addObject:obj];
        }
        
    }];
}

//method to getIndexByValue
- (NSNumber *) getValueByIndex:(CSRDeviceEntity*)deviceEntity
{
    uint16_t *dataToModify = (uint16_t*)deviceEntity.groups.bytes;
    
    for (int count=0; count < deviceEntity.groups.length/2; count++, dataToModify++) {
        if (*dataToModify == [_areaEntity.areaID unsignedShortValue]) {
            return @(count);
            
        } else if (*dataToModify == 0){
            return @(count);
        }
    }
    
    return @(-1);
}

- (void) sendOfData
{
    if (![_theNewArray isEqualToArray:_theDefaultArray]) {
        if ([_theDefaultArray count] > [_theNewArray count]) {
            [self getDeleteArray];
        } else if ([_theDefaultArray count] < [_theNewArray count]) {
            [self getAddArray];
        }
    } else {
        NSLog(@"No changes");
    }
    
    if ([_theAddArray count] != 0 && _areaEntity != nil)
    {
        [_theAddArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSNumber *localDeviceId = (NSNumber*)obj;
            
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:localDeviceId];
            
            NSNumber *groupIndex = [self getValueByIndex:deviceEntity];
            if (![groupIndex  isEqual:@(-1)])
            {
                    [[GroupModelApi sharedInstance] setModelGroupId:deviceEntity.deviceId
                                                            modelNo:@(0xff)
                                                         groupIndex:groupIndex // index of the array where there is first 0 or -1
                                                           instance:@(0)
                                                            groupId:_areaEntity.areaID //id of area
                                                            success:^(NSNumber *deviceId,
                                                                      NSNumber *modelNo,
                                                                      NSNumber *groupIndex,
                                                                      NSNumber *instance,
                                                                      NSNumber *desired) {
                                                                
                                                                NSMutableData *myData = (NSMutableData*)deviceEntity.groups;
                                                                uint16_t desiredValue = [desired unsignedShortValue];
                                                                int groupIndexInt = [groupIndex intValue];
                                                                if (groupIndexInt>-1) {
                                                                    uint16_t *groups = (uint16_t *) myData.mutableBytes;
                                                                    *(groups + groupIndexInt) = desiredValue;
                                                                }
                                                                
                                                                deviceEntity.groups = (NSData*)myData;
                                                                NSLog(@"deviceEntity.groups :%@", myData);
                                                                CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId: desired];
                                                                
                                                                if (areaEntity) {
                                                                    //NSLog(@"deviceEntity2 :%@", deviceEntity);
                                                                    [_areaEntity addDevicesObject:deviceEntity];
                                                                }
                                                                [[CSRDatabaseManager sharedInstance] saveContext];
                                                                
                                                                
                                                            } failure:^(NSError *error) {
                                                                NSLog(@"mesh timeout");
                                                                
                                                            }];
            } else {
                NSLog(@"Device has 4 areas or something went wrong");
            }
          [NSThread sleepForTimeInterval:0.3];  
            
        }];
        
    }
    if ([_theDeleteArray count] != 0)
    {
        [_theDeleteArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSNumber *localDeviceId = (NSNumber*)obj;
            
            CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:localDeviceId];
            NSNumber *groupIndex = [self getValueByIndex:deviceEntity];
            
            [[GroupModelApi sharedInstance] setModelGroupId:deviceEntity.deviceId
                                                    modelNo:@(0xff)
                                                 groupIndex:groupIndex // index of the array where that value was located
                                                   instance:@(0)
                                                    groupId:@(0) //0 for deleting
                                                    success:^(NSNumber *deviceId,
                                                              NSNumber *modelNo,
                                                              NSNumber *groupIndex,
                                                              NSNumber *instance,
                                                              NSNumber *desired) {
                                                        
                                                        uint16_t *dataToModify = (uint16_t*)deviceEntity.groups.bytes;
                                                        NSMutableArray *desiredGroups = [NSMutableArray new];
                                                        for (int count=0; count < deviceEntity.groups.length/2; count++, dataToModify++) {
                                                            NSNumber *groupValue = @(*dataToModify);
                                                            [desiredGroups addObject:groupValue];
                                                        }
                                                        
                                                        NSNumber *areaValue = [desiredGroups objectAtIndex:[groupIndex integerValue]];
                                                        
                                                        CSRAreaEntity *areaEntity = [[CSRDatabaseManager sharedInstance] getAreaEntityWithId:areaValue];
                                                        
                                                        if (areaEntity) {
                                                            [_areaEntity removeDevicesObject:deviceEntity];
                                                            
                                                        }
                                                        NSMutableData *myData = (NSMutableData*)deviceEntity.groups;
                                                        uint16_t desiredValue = [desired unsignedShortValue];
                                                        int groupIndexInt = [groupIndex intValue];
                                                        if (groupIndexInt>-1) {
                                                            uint16_t *groups = (uint16_t *) myData.mutableBytes;
                                                            *(groups + groupIndexInt) = desiredValue;
                                                        }
                                                        
                                                        deviceEntity.groups = (NSData*)myData;
                                                        
                                                        [[CSRDatabaseManager sharedInstance] saveContext];
                                                        
                                                        
                                                    } failure:^(NSError *error) {
                                                        NSLog(@"mesh timeout");
                                                        
                                                    }];
            [NSThread sleepForTimeInterval:0.3];
            
        }];
    }
    
}

- (void) dismissViewController:(UIActivityIndicatorView*)spin
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRRefreshNotification object:self userInfo:nil];
    [spin stopAnimating];
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (IBAction)cancelAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Helper method

- (BOOL)hasAreaGotDeviceWithId:(NSNumber *)deviceId
{
    __block BOOL deviceFound = NO;
    
    [_listOfLocalDevices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([((CSRDeviceEntity *)obj).deviceId intValue] == [deviceId intValue]) {
            
            deviceFound = YES;
            
            *stop = YES;
            
        }
        
    }];
    
    return deviceFound;
}


@end
