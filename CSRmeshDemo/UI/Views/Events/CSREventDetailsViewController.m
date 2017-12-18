//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSREventDetailsViewController.h"
#import "CSRmeshStyleKit.h"
#import "CSREventsTableViewCell.h"
#import "CSRDatabaseManager.h"
#import "CSRDeviceEntity.h"
#import "CSRConstants.h"
#import "CSREventEditViewController.h"
#import "CSREventConfigurationCell.h"
#import "CSREventTimeCell.h"
#import "CSRAppStateManager.h"
#import "CSRDeviceEventsEntity.h"
#import "CSRUtilities.h"
#import "CSREventDevicesCell.h"

@interface CSREventDetailsViewController ()

@property (nonatomic) NSMutableArray *selectedIndexes;
@property (nonatomic, strong) NSMutableArray *allDevicesArray;
@property (nonatomic, strong) NSMutableArray *allDeviceEventsArray;
@property (nonatomic, strong) NSMutableArray *allDeviceIds;

@property (nonatomic, strong) NSString *repeatString;

@property (nonatomic, strong) CSRDeviceEventsEntity *actionEntity;

@end

@implementation CSREventDetailsViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBarTintColor:[CSRUtilities colorFromHex:@"#409DFF"]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _allDevicesArray = [NSMutableArray new];
    _allDeviceEventsArray = [NSMutableArray new];
    
    _deleteToolBar.hidden = YES;
    _eventNameTextField.delegate = self;
    _eventNameTextField.text = _eventEntity.eventName;
    
    NSSet *devicesOfEvent = _eventEntity.devices;
    for (CSRDeviceEntity *deviceEntity in devicesOfEvent) {
        [_allDevicesArray addObject:deviceEntity];
    }
    _allDeviceIds = [NSMutableArray new];
    [_allDevicesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CSRDeviceEntity *localDeviceEntity = (CSRDeviceEntity *)obj;
        [_allDeviceIds addObject:localDeviceEntity.deviceId];
    }];

    
    NSSet *eventActions = _eventEntity.deviceEvents;
    for (CSRDeviceEventsEntity *deviceEvents in eventActions) {
        [_allDeviceEventsArray addObject:deviceEvents];
    }

    if (_allDeviceEventsArray.count) {
        _actionEntity = [_allDeviceEventsArray objectAtIndex:0];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDateFormat:@"EEE"];

    __block NSMutableArray *mArray = [NSMutableArray new];
    [_allDeviceEventsArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CSRDeviceEventsEntity *actionEnt = (CSRDeviceEventsEntity*)obj;
        double tot = [actionEnt.eventTime doubleValue]+ [actionEnt.eventRepeatMills doubleValue];
        NSLog(@"tot :%f", tot);
        NSDate *repeatDate = [NSDate dateWithTimeIntervalSince1970:(tot/1000)];
        NSString *repeatStr = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:repeatDate]];
        [mArray addObject:repeatStr];
        

    }];
    _repeatString = [mArray componentsJoinedByString:@","];
    NSLog(@"repeatString :%@", _repeatString);
    
    [self displayEventState:[_eventEntity.eventActive boolValue]];
    
}

-(void) displayEventState :(BOOL) state
{
    CSREventsTableViewCell *cell = (CSREventsTableViewCell*)[_eventsDetailTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if (state) {
        [cell.onOffSwitch setEnabled:YES];
    } else {
        [cell.onOffSwitch setEnabled:NO];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 2;
    } else if (section == 2) {
        return [_allDevicesArray count];
    } else {
        return 0;
    }
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section == 1) {
        return @"Configuration";
    } else if (section == 2) {
        return @"Devices";
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        return 2;
    }
    return UITableViewAutomaticDimension;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        return 80.;
    } else if (indexPath.section == 1) {
        return 100.;
    } else if (indexPath.section == 2) {
        return 44.;
    }
    return 0;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //OnOffCell
    if (indexPath.section == 0) {
         CSREventsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CSREventsTableViewCellIdentifier];
        if (!cell) {
            cell = [[CSREventsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSREventsTableViewCellIdentifier];
        }

        cell.eventNameLabel.text = [NSString stringWithFormat:@"Event %@", _eventEntity.eventActive ? @"On" : @"Off"];
        cell.eventDetailLabel.text = @"Tap to deactivate the event";
        cell.onOffSwitch.on = YES;
        cell.eventImageView.image = [CSRmeshStyleKit imageOfOnOff];

        return cell;
    }
   
    //ConfigurationCell
    if (indexPath.section == 1) {
        UITableViewCell *cell = nil;
        
        if (indexPath.row == 0) {
            CSREventConfigurationCell *cell = [tableView dequeueReusableCellWithIdentifier:CSREventConfigurationCellIdentifier];
            if (!cell) {
                cell = [[CSREventConfigurationCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CSREventConfigurationCellIdentifier];
            }
            
            if ([_eventEntity.eventType isEqualToNumber:@1]) {
                cell.eventConfigurationLabel.text = @"Light color event";
                
                NSData *colorData = [_eventEntity.eventValue subdataWithRange:NSMakeRange(0, _eventEntity.eventValue.length - 1)];
                NSData *intensityData = [_eventEntity.eventValue subdataWithRange:NSMakeRange(_eventEntity.eventValue.length - 1, 1)];
                int intensityInt = 0;
                [intensityData getBytes:&intensityInt length:1];

                cell.eventStateLabel.text = [NSString stringWithFormat:@"Colour %@", [[NSString alloc] initWithData:colorData encoding:NSUTF8StringEncoding]];
                cell.eventSubStateLabel.text = [NSString stringWithFormat:@"Intensity %i%%", intensityInt];
                cell.eventImageView.image = [UIImage imageNamed:@"colorPalette.png"];
                cell.eventStateView.layer.cornerRadius = cell.eventStateView.frame.size.width/2;
                //get color from nsdata
                NSString *colorString = [[NSString alloc] initWithData:colorData encoding:NSUTF8StringEncoding];
                NSString *colorValue = [CSRUtilities rgbFromColorName:colorString];
                [cell.eventStateView setBackgroundColor:[CSRUtilities colorFromHex:colorValue]];

                
            } else if ([_eventEntity.eventType isEqualToNumber:@2]){
                cell.eventConfigurationLabel.text = @"Light power event";
                NSInteger onOffInt;
                [_eventEntity.eventValue getBytes:&onOffInt length:sizeof(onOffInt)];
                cell.eventStateLabel.text = [NSString stringWithFormat:@"%i", onOffInt ? YES : NO];
                cell.eventStateView.hidden = YES;
                cell.eventSubStateLabel.hidden = YES;
                cell.eventImageView.image = [CSRmeshStyleKit imageOfOnOff];
                
            } else if ([_eventEntity.eventType isEqualToNumber:@3]) {
                cell.eventConfigurationLabel.text = @"Heating event";
                float tempFloat;
                [_eventEntity.eventValue getBytes:&tempFloat length:sizeof(tempFloat)];
                cell.eventStateLabel.text = [NSString stringWithFormat:@"%.f", tempFloat];
                cell.eventStateView.hidden = YES;
                cell.eventSubStateLabel.hidden = YES;
                cell.eventImageView.image = [CSRmeshStyleKit imageOfTemperature_off];
                
            }
            return cell;
        } else if (indexPath.row == 1) {
            CSREventTimeCell *cell = [tableView dequeueReusableCellWithIdentifier:CSREventTimeCellIdentifier];
            if (!cell) {
                cell = [[CSREventTimeCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CSREventTimeCellIdentifier];
            }
            cell.eventTimeLabel.hidden =YES;
            //CSREventTimeCell
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [dateFormatter setDateFormat:@"EEE,dd MMM yyyy hh:mm"];
            
            NSDate *eventDate = [NSDate dateWithTimeIntervalSince1970:([_actionEntity.eventTime doubleValue]/1000)];
            cell.eventTextLabel.text = [dateFormatter stringFromDate:eventDate];
            if ([_eventEntity.eventRepeatType isEqualToNumber:@0]) {
                double secValue =  [_actionEntity.eventRepeatMills doubleValue];
                
                cell.eventDateLabel.text = [NSString stringWithFormat:@"Repeats every %fseconds", secValue/1000];
            } else if ([_eventEntity.eventRepeatType isEqualToNumber:@1]){
                cell.eventDateLabel.text = [NSString stringWithFormat:@"Repeats every:\n(%@)",_repeatString];
            } else if ([_eventEntity.eventRepeatType isEqualToNumber:@-1]){
                cell.eventDateLabel.text = @"Doesn't Repeat";
            }
            return cell;
        }
        
        return cell;
    }
    //DevicesCell
    if (indexPath.section == 2) {
        
        CSREventDevicesCell *Cell = [tableView dequeueReusableCellWithIdentifier:CSREventDevicesCellIdentifier];
        if (!Cell) {
            Cell = [[CSREventDevicesCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSREventDevicesCellIdentifier];
        }
        Cell.selectionStyle = UITableViewCellSelectionStyleNone;
        CSRDeviceEntity *deviceEntity = [_allDevicesArray objectAtIndex:indexPath.row];
        Cell.deviceImage.image = [UIImage imageNamed:@"light.png"];
        
        Cell.deviceNameLabel.text = deviceEntity.name;
        
        if ([self hasEventGotDeviceWithId:deviceEntity.deviceId]) {
            [Cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            
        } else {
            [Cell setAccessoryType:UITableViewCellAccessoryNone];
        }

        
        return Cell;

    } else {
        return nil;
    }
    
    return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
}

#pragma mark - Helper method

- (BOOL)hasEventGotDeviceWithId:(NSNumber *)deviceId
{
    __block BOOL deviceFound = NO;
    
    [_allDeviceIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isEqualToNumber:deviceId]) {
            
            deviceFound = YES;
            
            *stop = YES;
            
        }
        
    }];
    
    return deviceFound;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"editEventSegue"]) {
        
        CSREventEditViewController *vc = (CSREventEditViewController*)segue.destinationViewController;
        vc.eventEntity = _eventEntity;
    }
}

#pragma mark - View Actions
- (IBAction)deleteEventAction:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Event"
                                                                             message:@"Do you want to delete the event completly?"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         
                                                         [[CSRAppStateManager sharedInstance].selectedPlace removeEventsObject:_eventEntity];
                                                         [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_eventEntity];
                                                         [self dismissViewControllerAnimated:YES completion:nil];
                                                     }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             
                                                         }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)doneAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)editAction:(id)sender {
    
    [self performSegueWithIdentifier:@"editEventSegue" sender:nil];
}

#pragma mark - Text Field Editing

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    return NO;
}


@end
