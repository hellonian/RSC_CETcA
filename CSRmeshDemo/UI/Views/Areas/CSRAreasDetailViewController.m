//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRAreasDetailViewController.h"
#import "CSRAppStateManager.h"
#import "CSRDatabaseManager.h"
#import "CSRDeviceEntity.h"
#import "CSRmeshStyleKit.h"
#import "CSRUtilities.h"
#import "CSRDevicesManager.h"
#import "CSRDeviceSelectionViewController.h"

@interface CSRAreasDetailViewController () {

    id presenter;
}
@end

@implementation CSRAreasDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
    [self.navigationController.interactivePopGestureRecognizer setEnabled:YES];
    [self setNeedsStatusBarAppearanceUpdate];
    
    [self.view setNeedsLayout];
    
    // obtain Favourite state from Database and then update favourite button
    _favouritesButton.backgroundColor = [UIColor clearColor];
    
    if (_areaEntity) {
        [self displayFavouriteState:[_areaEntity.favourite boolValue]];
    }
    
    _areaTitleTextField.delegate = self;
    
    if (![CSRUtilities isStringEmpty:_areaEntity.areaName]) {
        _areaTitleTextField.text = _areaEntity.areaName;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshView)
                                                 name:kCSRRefreshNotification
                                               object:nil];

}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBarTintColor:[CSRUtilities colorFromHex:@"#409DFF"]];
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    _devicesArray = [NSMutableArray new];
    NSSet *deviceSet = _areaEntity.devices;
    
    for (CSRDeviceEntity *device in deviceSet) {
        [_devicesArray addObject:device];
    }
    
    [self adjustAppearance];
    //    [self displayAreas];
    
}

- (void)adjustAppearance
{
    if (_areaEntity) {
        [self displayFavouriteState:[_areaEntity.favourite boolValue]];
    }
    
    _areaTitleTextField.delegate = self;
    
    if (_areaEntity) {
        if (![CSRUtilities isStringEmpty:_areaEntity.areaName]) {
            _areaTitleTextField.text = _areaEntity.areaName;
        }
    } else {
        NSNumber *areaIdNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSRAreaEntity"];
        _areaTitleTextField.text = [NSString stringWithFormat:@"Area %d", [areaIdNumber intValue]];
    }
}

- (void) refreshView
{
    [_devicesArray removeAllObjects];
    
    NSSet *deviceSet = _areaEntity.devices;
    
    for (CSRDeviceEntity *device in deviceSet) {
        [_devicesArray addObject:device];
    }
    
    [self.tableView reloadData];
}

-(void) displayFavouriteState :(BOOL) state
{
    if (state) {
        [_favouritesButton setBackgroundImage:[CSRmeshStyleKit imageOfFavourites_on] forState:UIControlStateNormal];
    } else {
        [_favouritesButton setBackgroundImage:[CSRmeshStyleKit imageOfFavourites_off] forState:UIControlStateNormal];
    }
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

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width/2, 18)];
    [label setText:@"DEVICES"];
    label.backgroundColor=[UIColor clearColor];
    label.textColor = [UIColor orangeColor];
    [view addSubview:label];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 75., 5, 75., 18)];
    [button setTitle:@"EDIT" forState:UIControlStateNormal];
    
    button.layer.masksToBounds = NO;
    button.layer.shadowColor = [UIColor blackColor].CGColor;
    button.layer.shadowOpacity = 0.6;
    button.layer.shadowRadius = 1;
    button.layer.shadowOffset = CGSizeMake(1., 1.);
    
    [button setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(editDevices:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:button];
    
    return view;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceListCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DeviceListCell"];
        //Added for automation
        cell.isAccessibilityElement = YES;
    }
    
    CSRDeviceEntity *deviceEntity = [_devicesArray objectAtIndex:indexPath.row];
    
    if (deviceEntity.name != nil){
        cell.textLabel.text = deviceEntity.name;
        //Added for automation
        cell.isAccessibilityElement = YES;
    }
    
    if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameLight)]) {
        cell.imageView.image = [CSRmeshStyleKit imageOfLightDevice_on];
    } else if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameSensor)]) {
        cell.imageView.image = [CSRmeshStyleKit imageOfSensorDevice];
    } else if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameHeater)]) {
        cell.imageView.image = [CSRmeshStyleKit imageOfHeaterDevice];
    }  else if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameSwitch)]) {
        cell.imageView.image = [CSRmeshStyleKit imageOfOnOff];
    } else {
        cell.imageView.image = [CSRmeshStyleKit imageOfMesh_device];
    }
    
    return cell;
}


#pragma mark - Actions

- (IBAction)back:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)saveAreaConfiguration:(id)sender
{
    if(_areaEntity) {
        _areaEntity.areaName = _areaTitleTextField.text;
        [[CSRDatabaseManager sharedInstance] saveContext];
        
    } else {
        if (![CSRUtilities isStringEmpty:_areaTitleTextField.text]) {

            _areaEntity = [[CSRDevicesManager sharedInstance] addMeshArea:_areaTitleTextField.text];
            [[CSRAppStateManager sharedInstance].selectedPlace addAreasObject:_areaEntity];
            [[CSRDatabaseManager sharedInstance] saveContext];
        } else {
            NSLog(@"Alert: Enter some Value");
        }
        
    }
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

- (IBAction)cancelButtonClicked:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];

}

- (IBAction)toggleFavouriteState:(id)sender
{
    //
    // 1. Toggle favourite for this Device
    // 2. Update image for this device to inidicate new Favourite state
    //
    
    if (_areaEntity) {
        BOOL state = [_areaEntity.favourite boolValue];
        state = !state;
        [_areaEntity setFavourite:@(state)];
        [[CSRDatabaseManager sharedInstance] saveContext];
        
        // update Image
        [self displayFavouriteState:state];
        
        
    }
}

- (IBAction)editDevices:(id)sender
{
    if(_areaEntity) {
        
    } else {
        if (![CSRUtilities isStringEmpty:_areaTitleTextField.text]) {
            
            _areaEntity = [[CSRDevicesManager sharedInstance] addMeshArea:_areaTitleTextField.text];
            [[CSRAppStateManager sharedInstance].selectedPlace addAreasObject:_areaEntity];
            
        } else {
            NSLog(@"Alert: Please enter a valid name");
        }
    }
    [self performSegueWithIdentifier:@"selectOrAddDeviceSegue" sender:self];
}

-(IBAction)deleteArea:(id)sender
{
    
    
//    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//    [self.view addSubview:spinner];
//    spinner.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
//    [spinner startAnimating];

    
    if ([_devicesArray count] != 0)
    {
        [_devicesArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CSRDeviceEntity *localDeviceEntity = (CSRDeviceEntity*)obj;
            
            NSNumber *groupIndex = [self getValueByIndex:localDeviceEntity];
//            NSLog(@"groupIndex :%@", groupIndex);
            
                [[GroupModelApi sharedInstance] setModelGroupId:localDeviceEntity.deviceId
                                                        modelNo:@(0xff)
                                                     groupIndex:groupIndex // index of the array where that value was located
                                                       instance:@(0)
                                                        groupId:@(0) //0 for deleting
                                                        success:^(NSNumber *deviceId,
                                                                  NSNumber *modelNo,
                                                                  NSNumber *groupIndex,
                                                                  NSNumber *instance,
                                                                  NSNumber *desired) {
                                                            
                                                            uint16_t *dataToModify = (uint16_t*)localDeviceEntity.groups.bytes;
                                                            NSMutableArray *desiredGroups = [NSMutableArray new];
                                                            for (int count=0; count < localDeviceEntity.groups.length/2; count++, dataToModify++) {
                                                                NSNumber *groupValue = @(*dataToModify);
                                                                [desiredGroups addObject:groupValue];
                                                            }
                                                            
                                                            if (groupIndex && [groupIndex integerValue]<desiredGroups.count) {
                                                                
                                                                NSNumber *areaValue = [desiredGroups objectAtIndex:[groupIndex integerValue]];
                                                                
                                                                CSRAreaEntity *areaEntity = [[[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"CSRAreaEntity" withPredicate:@"areaID == %@", areaValue] firstObject];
                                                                
                                                                if (areaEntity) {
                                                                    
                                                                    [_areaEntity removeDevicesObject:localDeviceEntity];
                                                                }
                                                                
                                                                
                                                                NSMutableData *myData = (NSMutableData*)localDeviceEntity.groups;
                                                                uint16_t desiredValue = [desired unsignedShortValue];
                                                                int groupIndexInt = [groupIndex intValue];
                                                                if (groupIndexInt>-1) {
                                                                    uint16_t *groups = (uint16_t *) myData.mutableBytes;
                                                                    *(groups + groupIndexInt) = desiredValue;
                                                                }
                                                                localDeviceEntity.groups = (NSData*)myData;
                                                                
                                                                [[CSRDatabaseManager sharedInstance] saveContext];
                                                            }
                                                            
                                                            
                                                        } failure:^(NSError *error) {
                                                            NSLog(@"mesh timeout");
                                                            
                                                        }];
            
            [NSThread sleepForTimeInterval:0.3];
            
        }];
    }
    if(_areaEntity) {
        [[CSRDevicesManager sharedInstance] removeAreaWithAreaId:_areaEntity.areaID];
        [[CSRAppStateManager sharedInstance].selectedPlace removeAreasObject:_areaEntity];
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_areaEntity];
        
//        [self performSelector:@selector(dismissViewController:) withObject:spinner afterDelay:2];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void) dismissViewController:(UIActivityIndicatorView*)spin
{
    [spin stopAnimating];
    [self.navigationController popToRootViewControllerAnimated:YES];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"selectOrAddDeviceSegue"] && _areaEntity) {
        CSRDeviceSelectionViewController *vc = segue.destinationViewController;
        vc.areaEntity = _areaEntity;
    }
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.backgroundColor = [UIColor whiteColor];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    textField.backgroundColor = [UIColor clearColor];
    [textField resignFirstResponder];
    return NO;
}


@end
