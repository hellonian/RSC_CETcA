//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSREventEditViewController.h"
#import "CSRDatabaseManager.h"
#import "CSRmeshDevice.h"
#import "CSRmeshStyleKit.h"

//Cells for the tableView
#import "CSREventNameTextFieldCell.h"
#import "CSREventOnOffCell.h"
#import "CSREventConfigurationCell.h"
#import "CSREventTimeCell.h"
#import "CSREventRepeatCell.h"
#import "CSREventDevicesCell.h"

#import "CSREventTimeSelectorVC.h"
#import "CSREventControlVC.h"

//To find the source of the Segue
#import "CSREventsTableViewController.h"
#import "CSREventDetailsViewController.h"

//App State Manager
#import "CSRAppStateManager.h"
#import "CSRDevicesManager.h"

//Entities
#import "CSRDeviceEntity.h"
#import "CSRAreaEntity.h"
#import "CSRUtilities.h"
#import "CSREventsManager.h"
#import "CSRDeviceEventsEntity.h"

#define kDatePickerTag              99     // view tag identifiying the date picker view

static NSString *kDatePickerID = @"datePicker"; // the cell containing the date picker
static NSString *kCSREventTimeCellIdentifier = @"eventTimeCellIdentifier";

static NSString *kCSREventConfigurationCell = @"eventConfigurationCellIdentifier";


#pragma mark -

@interface CSREventEditViewController ()

@property (nonatomic, strong) NSArray *dataArray;

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) NSIndexPath *datePickerIndexPath;
@property (assign) NSInteger pickerCellRowHeight;

@property (assign) BOOL onOffBool;
@property (assign) BOOL repeatBool;

@property (nonatomic, strong) NSArray *allDevicesArray;
@property (nonatomic, strong) NSMutableArray *allDeviceIds;

@property (nonatomic, strong) NSNumber *secondsField;
@property (nonatomic, strong) NSData *weekDaysData;

@property (nonatomic, retain) NSMutableArray *selectedDevicesArray;

@property (nonatomic, strong) CSREventsManager *eventsManager;
@property (nonatomic, strong) CSRAreaEntity *areaEntity;

@property (nonatomic, strong) UIColor *eventColor;
@property (nonatomic) CGFloat intensityFloat;
@property (nonatomic, assign) BOOL eventOnOff;
@property (nonatomic, assign) float eventTemperature;

@property (nonatomic, strong) NSString *timeString;
@property (nonatomic, assign) BOOL repeatOnOff;
@end


@implementation CSREventEditViewController


- (void) viewDidLoad {
    
    [super viewDidLoad];
    
    // setup our data source

    NSSet *eventActions = _eventEntity.deviceEvents;
    CSRDeviceEventsEntity *actionEntity = [eventActions anyObject];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDateFormat:@"EEE,dd MMM yyyy"];
    
    NSDate *eventDate = [NSDate dateWithTimeIntervalSince1970:([actionEntity.eventTime doubleValue]/1000)];
    NSMutableDictionary *itemTwo = [@{@"date" : [dateFormatter stringFromDate:eventDate] } mutableCopy];
    self.dataArray = @[itemTwo];
    
    [dateFormatter setDateFormat:@"hh:mm"];
    _timeString = [dateFormatter stringFromDate:eventDate];
    
    if (actionEntity.eventRepeatMills) {
        _repeatOnOff = YES;
    } else {
        _repeatOnOff = NO;
    }
    
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];    // show medium-style date format
    [self.dateFormatter setDateFormat:@"EEE,dd MMM yyyy hh:mm"];
    
    _allDevicesArray = [NSArray new];
    _allDevicesArray = [[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects];
    
    _allDeviceIds = [NSMutableArray new];
    [_allDevicesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CSRDeviceEntity *localDeviceEntity = (CSRDeviceEntity *)obj;
        [_allDeviceIds addObject:localDeviceEntity.deviceId];
    }];
    
    _selectedDevicesArray = [NSMutableArray new];
    NSSet *devicesSet = _eventEntity.devices;
    [devicesSet enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        CSRDeviceEntity *devEnt = (CSRDeviceEntity*)obj;
        if ([self theArray:_allDeviceIds hasObject:devEnt.deviceId]) {
            [_selectedDevicesArray addObject:devEnt.deviceId];
        }
    }];

    //Date Picker View
    _datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    
    // obtain the picker view cell's height, works because the cell was pre-defined in our storyboard
    UITableViewCell *pickerViewCellToCheck = [_eventCreationTableView dequeueReusableCellWithIdentifier:kDatePickerID];
    self.pickerCellRowHeight = CGRectGetHeight(pickerViewCellToCheck.frame);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableViewWithColor:) name:@"colorTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableViewWithIntensity:) name:@"sliderTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableViewWithOnOff:) name:@"eventActivation" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableViewWithTemperature:) name:@"temperatureIncreased" object:nil];
    
}

- (BOOL)theArray:(NSMutableArray *)array hasObject:(id)customObj
{
    __block BOOL hasObj = NO;
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isEqual:customObj]) {
            
            hasObj = YES;
            *stop = YES;
        }
    }];
    return hasObj;
}


- (void) viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    //Clear Notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"colorTapped" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"sliderTapped" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"eventActivation" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"temperatureIncreased" object:nil];
}


- (void) reloadTableViewWithColor:(NSNotification*)notification {
    
    _eventColor = (UIColor*)notification.userInfo[@"color"];
    [_eventCreationTableView reloadData];
}

- (void) reloadTableViewWithIntensity:(NSNotification*)notification {

    _intensityFloat = [notification.userInfo[@"intensity"] floatValue];
    [_eventCreationTableView reloadData];
}

- (void) reloadTableViewWithOnOff:(NSNotification*)notification {
    
    _eventOnOff = [notification.userInfo[@"eventStatus"] boolValue];
    [_eventCreationTableView reloadData];
}

- (void) reloadTableViewWithTemperature:(NSNotification*)notification {
    
    _eventTemperature = [notification.userInfo[@"temperature"] floatValue];
    [_eventCreationTableView reloadData];
}


- (BOOL)hasPickerForIndexPath:(NSIndexPath *)indexPath
{
    BOOL hasDatePicker = NO;
    
    NSInteger targetedRow = indexPath.row;
    targetedRow++;
    
    UITableViewCell *checkDatePickerCell = [_eventCreationTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:targetedRow inSection:2]];
    UIDatePicker *checkDatePicker = (UIDatePicker *)[checkDatePickerCell viewWithTag:kDatePickerTag];
    
    hasDatePicker = (checkDatePicker != nil);
    return hasDatePicker;
}

- (void)updateDatePicker
{
    if (self.datePickerIndexPath != nil)
    {
        UITableViewCell *associatedDatePickerCell = [_eventCreationTableView cellForRowAtIndexPath:self.datePickerIndexPath];
        
        UIDatePicker *targetedDatePicker = (UIDatePicker *)[associatedDatePickerCell viewWithTag:kDatePickerTag];
        if (targetedDatePicker != nil)
        {
            // we found a UIDatePicker in this cell, so update it's date value
            //
            NSDictionary *itemData = self.dataArray[self.datePickerIndexPath.row - 2];
            [targetedDatePicker setDate:[itemData valueForKey:@"date"] animated:NO];
        }
    }
}

- (BOOL)hasInlineDatePicker
{
    return (self.datePickerIndexPath != nil);
}

- (BOOL)indexPathHasPicker:(NSIndexPath *)indexPath
{
    return ([self hasInlineDatePicker] && self.datePickerIndexPath.row == indexPath.row);
}

- (BOOL)indexPathHasDate:(NSIndexPath *)indexPath
{
    BOOL hasDate = NO;
    
    if ((indexPath.row == 1) || [self hasInlineDatePicker])
    {
        hasDate = YES;
    }
    
    return hasDate;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 1;
    } else if (section == 2) {
        if ([self hasInlineDatePicker]) {
            return 3;
        }
        return 2;
    } else if (section == 3) {
        return 1;
    } else if (section == 4) {
        return [_allDevicesArray count];
    }
   return 0;
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section == 2) {
        return LOCALIZEDSTRING(@"Configuration");
    } else if (section == 4) {
        return LOCALIZEDSTRING(@"Devices");
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 0) {
        return 2.;
    } else if (section == 1) {
        return 2.;
    } else if (section == 3) {
        return 2.;
    }
    return UITableViewAutomaticDimension;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        return 44.;
    } else if (indexPath.section == 1) {
        return 60.;
    } else if (indexPath.section == 2) {
        return ([self indexPathHasPicker:indexPath] ? self.pickerCellRowHeight : _eventCreationTableView.rowHeight);
    } else if (indexPath.section == 3) {
        return 44.;
    } else if (indexPath.section == 4) {
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
    
    UITableViewCell *Cell = nil;
    
    if (indexPath.section == 0) {
        //eventNameTextFieldCellIdentifier
        CSREventNameTextFieldCell *Cell = [tableView dequeueReusableCellWithIdentifier:CSREventNameTextFieldCellIdentifier];
        if (!Cell) {
            Cell = [[CSREventNameTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSREventNameTextFieldCellIdentifier];
        }
        Cell.eventNameTextField.delegate = self;
        if (_eventEntity) {
            Cell.eventNameTextField.text = _eventEntity.eventName;
        }
        
        return Cell;
        
    } else if (indexPath.section == 1) {
        //eventOnOffCellIdentifier
        CSREventOnOffCell *Cell = [tableView dequeueReusableCellWithIdentifier:CSREventOnOffCellIdentifier];
        if (!Cell) {
            Cell = [[CSREventOnOffCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSREventOnOffCellIdentifier];
        }
        Cell.eventNameLabel.text = LOCALIZEDSTRING(@"Event on");
        Cell.eventDescriptionLabel.text = LOCALIZEDSTRING(@"Tap to deactivate the event");
        Cell.onOffSwitch.enabled = YES;
        
        return Cell;
        
    } else if (indexPath.section == 2) {
        
        if (indexPath.row == 0) {
            //eventConfigurationCellIdentifier
            CSREventConfigurationCell *Cell = [tableView dequeueReusableCellWithIdentifier:CSREventConfigurationCellIdentifier];
            if (!Cell) {
                Cell = [[CSREventConfigurationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSREventConfigurationCellIdentifier];
            }
            
            if ([_eventEntity.eventType isEqualToNumber:@1]) {
                Cell.eventConfigurationLabel.text = @"Light color event";
                NSData *colorData = [_eventEntity.eventValue subdataWithRange:NSMakeRange(0, _eventEntity.eventValue.length - 1)];
                NSData *intensityData = [_eventEntity.eventValue subdataWithRange:NSMakeRange(_eventEntity.eventValue.length - 1, 1)];
                int intensityInt = 0;
                [intensityData getBytes:&intensityInt length:1];
                Cell.eventStateLabel.text = [NSString stringWithFormat:@"Colour %@", [[NSString alloc] initWithData:colorData encoding:NSUTF8StringEncoding]];
                Cell.eventSubStateLabel.text = [NSString stringWithFormat:@"Intensity %i%%", intensityInt];
                Cell.eventImageView.image = [CSRmeshStyleKit imageOfColorPalette];
                Cell.eventStateView.layer.cornerRadius = Cell.eventStateView.frame.size.width/2;
                //get color from nsdata
                NSString *colorString = [[NSString alloc] initWithData:colorData encoding:NSUTF8StringEncoding];
                NSString *colorValue = [CSRUtilities rgbFromColorName:colorString];
                [Cell.eventStateView setBackgroundColor:[CSRUtilities colorFromHex:colorValue]];
                
            } else if ([_eventEntity.eventType isEqualToNumber:@2]) {
                Cell.eventConfigurationLabel.text = @"Light power";
                Cell.eventSubStateLabel.text = @"Turn lights ON/OFF";
                Cell.eventStateLabel.hidden = YES;
                Cell.eventStateView.hidden = YES;
                Cell.eventImageView.image = [CSRmeshStyleKit imageOfOnOff];

            } else if ([_eventEntity.eventType isEqualToNumber:@3]) {
                Cell.eventConfigurationLabel.text = @"Heating Event";
                Cell.eventSubStateLabel.text = [NSString stringWithFormat:@"%.f", _eventTemperature];
                Cell.eventStateLabel.hidden = YES;
                Cell.eventStateView.hidden = YES;
                Cell.eventImageView.image = [CSRmeshStyleKit imageOfTemperature_off];

            } else {
                
            }
        return Cell;
            
        } else {
           
            if ([self indexPathHasPicker:indexPath])
            {
                // the indexPath is the one containing the inline date picker
                Cell = [tableView dequeueReusableCellWithIdentifier:kDatePickerID];
                
                return Cell;
                
            }
            else if ([self indexPathHasDate:indexPath])
            {
                // the indexPath is one that contains the date information
                CSREventTimeCell *Cell = [tableView dequeueReusableCellWithIdentifier:CSREventTimeCellIdentifier];
                if (!Cell) {
                    Cell = [[CSREventTimeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSREventTimeCellIdentifier];
                }
                
                // if we have a date picker open whose cell is above the cell we want to update,
                // then we have one more cell than the model allows
                //
                NSInteger modelRow = indexPath.row;
                if (self.datePickerIndexPath != nil && self.datePickerIndexPath.row <= indexPath.row)
                {
                    modelRow--;
                }
                NSDictionary *itemData = self.dataArray[modelRow-1];
                
                Cell.eventTextLabel.text = @"Time";
                Cell.eventDateLabel.text = [itemData valueForKey:@"date"];
                Cell.eventTimeLabel.text = _timeString;
                return Cell;

            }
            
            return nil;

        }
        
    } else if (indexPath.section == 3) {
        
        CSREventRepeatCell *Cell = [tableView dequeueReusableCellWithIdentifier:CSREventRepeatCellIdentifier];
        if (!Cell) {
            Cell = [[CSREventRepeatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSREventRepeatCellIdentifier];
        }
        Cell.repeatTextLabel.text = LOCALIZEDSTRING(@"Repeat");
        if (_repeatOnOff) {
            Cell.repeatSwitch.enabled = YES;
        } else {
            Cell.repeatSwitch.enabled = NO;
        }
        
        
        return Cell;
    }
    else if (indexPath.section == 4) {
        
        CSREventDevicesCell *Cell = [tableView dequeueReusableCellWithIdentifier:CSREventDevicesCellIdentifier];
        if (!Cell) {
            Cell = [[CSREventDevicesCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSREventDevicesCellIdentifier];
        }
        Cell.selectionStyle = UITableViewCellSelectionStyleNone;
        CSRDeviceEntity *deviceEntity = [_allDevicesArray objectAtIndex:indexPath.row];

        Cell.deviceImage.image = [UIImage imageNamed:@"light.png"];
        Cell.deviceNameLabel.text = deviceEntity.name;
        
        
        if ([self theArray:_selectedDevicesArray hasObject:deviceEntity.deviceId]) {
            [Cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            [Cell setAccessoryType:UITableViewCellAccessoryNone];
        }
        
        return Cell;
        
    } else {
        return nil;
    }
    return Cell;
}

- (void)toggleDatePickerForSelectedIndexPath:(NSIndexPath *)indexPath
{
    [_eventCreationTableView beginUpdates];
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:2]];
    
    // check if 'indexPath' has an attached date picker below it
    if ([self hasPickerForIndexPath:indexPath])
    {
        [_eventCreationTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {
        [_eventCreationTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [_eventCreationTableView endUpdates];
}

- (void)displayInlineDatePickerForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_eventCreationTableView beginUpdates];
    
    BOOL before = NO;
    if ([self hasInlineDatePicker])
    {
        before = self.datePickerIndexPath.row < indexPath.row;
    }
    
    BOOL sameCellClicked = (self.datePickerIndexPath.row - 1 == indexPath.row);
    
    if ([self hasInlineDatePicker])
    {
        [_eventCreationTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.datePickerIndexPath.row inSection:2]]
                                       withRowAnimation:UITableViewRowAnimationFade];
        self.datePickerIndexPath = nil;
    }
    
    if (!sameCellClicked)
    {
        NSInteger rowToReveal = (before ? indexPath.row - 1 : indexPath.row);
        NSIndexPath *indexPathToReveal = [NSIndexPath indexPathForRow:rowToReveal inSection:2];
        
        [self toggleDatePickerForSelectedIndexPath:indexPathToReveal];
        self.datePickerIndexPath = [NSIndexPath indexPathForRow:indexPathToReveal.row + 1 inSection:2];
    }

    [_eventCreationTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [_eventCreationTableView endUpdates];
    
// inform our date picker of the current date to match the current cell
//    [self updateDatePicker];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.reuseIdentifier == kCSREventTimeCellIdentifier) {
        
        [self displayInlineDatePickerForRowAtIndexPath:indexPath];

    }
    //For event on or off
    if (indexPath.section == 1) {
        
        CSREventOnOffCell *cell = (CSREventOnOffCell *)[tableView cellForRowAtIndexPath:indexPath];
        
        if (_onOffBool) {
            cell.onOffSwitch.on = YES;
            _onOffBool = NO;
        } else {
            cell.onOffSwitch.on = NO;
            _onOffBool = YES;
        }
    }
    
    if (cell.reuseIdentifier == kCSREventConfigurationCell) {
        
        
        [self performSegueWithIdentifier:@"eventControlSegue" sender:nil];
    }

    //For repeat action
    if (indexPath.section == 3) {
        
        CSREventRepeatCell *cell = (CSREventRepeatCell *)[tableView cellForRowAtIndexPath:indexPath];
        
        if (_repeatBool) {
            cell.repeatSwitch.on = NO;
            _repeatBool = NO;
        } else {
            cell.repeatSwitch.on = YES;
            _repeatBool = YES;
            [self performSegueWithIdentifier:@"repeatSegue" sender:nil];
        }
    }
    
    if (indexPath.section == 4) {
        
        CSREventDevicesCell *selectedCell = (CSREventDevicesCell*)[tableView cellForRowAtIndexPath:indexPath];
        
        CSRDeviceEntity *deviceEntity = [_allDevicesArray objectAtIndex:indexPath.row];
        
        if ([_selectedDevicesArray containsObject:deviceEntity.deviceId]) {
            [_selectedDevicesArray removeObject:deviceEntity.deviceId];
            selectedCell.accessoryType = UITableViewCellAccessoryNone;
        } else {
             [_selectedDevicesArray addObject:deviceEntity.deviceId];
            selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

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


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"repeatSegue"]) {
        CSREventTimeSelectorVC *vc = segue.destinationViewController;
        vc.popoverPresentationController.delegate = self;
        vc.popoverPresentationController.containerView.superview.layer.cornerRadius = 0;
        vc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20., 175.);
        
        vc.eventsDelegate = self;
    }
    
    if ([segue.identifier isEqualToString:@"eventControlSegue"]) {
        
        //Take a event type
        CSREventControlVC *vc = segue.destinationViewController;
        vc.typeOfEvent = [_eventEntity.eventType integerValue];
        
    }
}


#pragma mark - Actions

- (IBAction)dateAction:(id)sender
{
    NSIndexPath *targetedCellIndexPath = nil;
    
    if ([self hasInlineDatePicker])
    {
        targetedCellIndexPath = [NSIndexPath indexPathForRow:self.datePickerIndexPath.row - 1 inSection:2];
    }
    else
    {
        targetedCellIndexPath = [_eventCreationTableView indexPathForSelectedRow];
    }
    
    CSREventTimeCell *cell = [_eventCreationTableView cellForRowAtIndexPath:targetedCellIndexPath];
    UIDatePicker *targetedDatePicker = sender;
    
    NSMutableDictionary *itemData = self.dataArray[targetedCellIndexPath.row - 1];
    [itemData setValue:targetedDatePicker.date forKey:@"date"];
    
    cell.eventDateLabel.text = [self.dateFormatter stringFromDate:targetedDatePicker.date];
}


- (IBAction)saveEventAction:(id)sender {
    
    CSREventNameTextFieldCell *textFieldCell = (CSREventNameTextFieldCell*)[_eventCreationTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    _eventEntity.eventName = textFieldCell.eventNameTextField.text;
    _eventEntity.eventid = _eventEntity.eventid;
    _eventEntity.eventType = @(_typeOfEvent);
    
    _eventEntity.eventActive = [NSNumber numberWithBool:_onOffBool];
    
    //adding DeviceEntity as relation to EventEntity
    __block CSRDeviceEntity *localdeviceEntity;
    [_selectedDevicesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *localdeviceId = (NSNumber *)obj;
        localdeviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:localdeviceId];
        [_eventEntity addDevicesObject:localdeviceEntity];
        
    }];
    
    if (_typeOfEvent == 1) {
        
        NSString *colorName = [CSRUtilities colorNameForRGB:[CSRUtilities rgbFromColor:_eventColor]];
        NSString *intenString = [NSString stringWithFormat:@"%.0f",_intensityFloat *100];
        
        NSMutableData *mutableData = [[NSMutableData alloc] initWithData:[colorName dataUsingEncoding:NSUTF8StringEncoding]];
        [mutableData appendData:[intenString dataUsingEncoding:NSUTF8StringEncoding]];
        
        _eventEntity.eventValue = [mutableData copy];
        
    } else if (_typeOfEvent == 2) {
        
        NSInteger powerInt = @(_eventOnOff).integerValue;
        NSData *data = [NSData dataWithBytes: &powerInt length: sizeof(powerInt)];
        _eventEntity.eventValue = data;
        
    } else if (_typeOfEvent == 3) {
        
        NSData *data = [NSData dataWithBytes:&_eventTemperature length:sizeof(_eventTemperature)];
        _eventEntity.eventValue = data;
        
    }
    NSDictionary *itemData = self.dataArray[0];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE,dd MMM yyyy hh:mm"];
    id dateObject = [itemData valueForKey:@"date"];
    
    NSDate *dateFromString;
    if ([dateObject isKindOfClass:[NSString class]]) {
        dateFromString = [dateFormatter dateFromString:dateObject];
    } else {
        dateFromString = dateObject;
    }
    double timeInMills = [dateFromString timeIntervalSince1970]*1000;
    
    __block CSRMeshAction *meshAction;
    
    [_selectedDevicesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CSRDeviceEntity *devEntity = (CSRDeviceEntity *)obj;
        
        if (_typeOfEvent == 1) {
            CGFloat red=0, green=0, blue=0, alpha=0;
            [_eventColor getRed: &red
                          green: &green
                           blue: &blue
                          alpha: &alpha];
            
            meshAction = [CSRMeshAction initWithLightSetRgb:devEntity.deviceId
                                                      level:@(alpha*255)
                                                        red:@(red*255)
                                                      green:@(green*255)
                                                       blue:@(blue*255)
                                              colorDuration:@1
                                                acknowledge:NO];
            
        } else if (_typeOfEvent == 2) {
            
            NSInteger powerInt = @(_eventOnOff).integerValue;
            meshAction = [CSRMeshAction initWithPowerSetState:devEntity.deviceId
                                                        state:@(powerInt)
                                                  acknowledge:NO];
            
        } else if (_typeOfEvent == 3) {
            
            CSRsensorValue *sensor = [CSRsensorValue initWithTypeAndValue:(CSRsensorType)3 value:@(0x24a5)];
            meshAction = [CSRMeshAction initWithActuatorSetValue:devEntity.deviceId
                                                           value:sensor
                                                     acknowledge:NO];
            
        }
        
        [[ActionModelApi sharedInstance] setAction:devEntity.deviceId
                                          actionId:@1
                                        meshAction:meshAction
                               absoluteTriggerTime:dateObject
                                  recurringSeconds:@10
                                       recurrences:@(timeInMills)
                                           success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable actionId) {
                                               
                                           } failure:^(NSError * _Nullable error) {
                                               
                                           }];

    }];
    
    _eventsManager = [[CSREventsManager alloc] initWithData:_eventEntity withTimeInMills:timeInMills secondsData:_secondsField weekData:_weekDaysData];
    
    [[CSRAppStateManager sharedInstance].selectedPlace addEventsObject:_eventEntity];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRRefreshNotification object:self userInfo:nil];

    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)closeEventAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)deleteEventAction:(id)sender {
    
    [[CSRAppStateManager sharedInstance].selectedPlace.events enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        CSREventEntity *localEventEntity = (CSREventEntity *)obj;
        
        if ([localEventEntity.eventid isEqualToNumber:_eventEntity.eventid]) {
            
            [[CSRAppStateManager sharedInstance].selectedPlace removeEventsObject:localEventEntity];
            *stop = YES;
        }
    }];
    
    [[ActionModelApi sharedInstance] deleteAction:@0x8001
                                        actionIds:[NSArray arrayWithObjects:@1, nil]
                                          success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable actionIdsDeleted) {
                                              
                                          } failure:^(NSError * _Nullable error) {
                                              
                                          }];
    
    [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_eventEntity];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRRefreshNotification object:self userInfo:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Delegate Callbacks

- (void) repeatEverySeconds:(NSNumber *)seconds ofDays:(NSData *)data {
    
    //got the data now save to core data
    _weekDaysData = data;
    _secondsField = seconds;
}

#pragma mark --
#pragma marl UITextFieldDelegate

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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSCurrentLocaleDidChangeNotification
                                                  object:nil];
}

- (void)handleError:(NSError *)error
{
    NSString *errorMessage = [error localizedDescription];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot Send the data"
                                                                   message:errorMessage
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         // dissmissal of alert completed
                                                     }];
    
    [alert addAction:OKAction];
    [self presentViewController:alert animated:YES completion:nil];
}



@end
