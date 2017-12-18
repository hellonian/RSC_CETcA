//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSRNewEventCreationViewController.h"
#import "CSRmeshStyleKit.h"
#import "CSRUtilities.h"
#import "CSRUtilities.h"
#import "CSREventEntity.h"
#import "CSRDatabaseManager.h"
#import "CSRConstants.h"
#import "CSRmeshDevice.h"
#import "CSREventTimeCell.h"
#import "CSREventRepeatCell.h"
#import "CSRLightViewController.h"
#import "CSRDeviceEntity.h"
#import "CSRAppStateManager.h"
#import "CSREventsManager.h"
#import "CSREventsOnOffVC.h"
#import "CSRTemperatureViewController.h"
#import "CSRDeviceEventsEntity.h"
#import "CSREventDevicesCell.h"
#import "CSRDevicesManager.h"
#import "CSRMeshUtilities.h"

#define kDatePickerTag              99

#define kTitleKey       @"title"
#define kDateKey        @"date"

static NSString *kDatePickerID = @"datePicker";
static NSString *kCSREventTimeCellIdentifier = @"eventTimeCellIdentifier";
static NSString *kCSREventRepeatCellIdentifier = @"eventRepeatCellIdentifier";


@interface CSRNewEventCreationViewController () {
    CGFloat intensityLevel;
    CGPoint lastPosition;
    UIColor *chosenColor;
}

@property (nonatomic, strong) NSArray *dataArray;

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
    
@property (nonatomic, strong) NSIndexPath *datePickerIndexPath;
@property (assign) NSInteger pickerCellRowHeight;

@property (assign) BOOL repeatBool;

@property (nonatomic, strong) NSNumber *secondsField;
@property (nonatomic, strong) NSData *weekDaysData;

@property (nonatomic, retain) NSMutableArray *selectedDevicesArray;
@property (nonatomic, retain) NSMutableArray *actionSelectedDevicesArray;

@property (nonatomic, strong) NSArray *allDevicesArray;
@property (nonatomic, strong) NSMutableArray *allDeviceIds;

//eventValues
@property (nonatomic, strong) UIColor *eventColor;
@property (nonatomic) CGFloat intensityFloat;
@property (nonatomic, assign) BOOL eventOnOff;
@property (nonatomic, assign) float eventTemperature;

@property (nonatomic, strong) CSREventsManager *eventsManager;

//Action Support devices only
@property (nonatomic, retain) NSMutableArray *actionDevicesArray;

@end


@implementation CSRNewEventCreationViewController

- (void)viewWillAppear:(BOOL)animated {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // setup our data source
    NSMutableDictionary *dateDictionary = [@{ kTitleKey : @"Time", kDateKey : [NSDate date] } mutableCopy];
    self.dataArray = @[dateDictionary];
    
    self.dateFormatter = [NSDateFormatter new];
    [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [self.dateFormatter setDateFormat:@"EEE,dd MMM yyyy hh:mm"];
    
    if (pageNumber == 0) {
        [_backButton setEnabled:NO];
    }
    
    //Device Table View
    _devicesListTableView.delegate = self;
    _devicesListTableView.dataSource = self;
    
    //Time Table View
    _timeTableView.delegate = self;
    _timeTableView.dataSource = self;
    
    //Date Picker View
    _datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    
    // obtain the picker view cell's height, works because the cell was pre-defined in our storyboard
    UITableViewCell *pickerViewCellToCheck = [_timeTableView dequeueReusableCellWithIdentifier:kDatePickerID];
    self.pickerCellRowHeight = CGRectGetHeight(pickerViewCellToCheck.frame);
    
    //Set initial values
    _tapGesture.numberOfTapsRequired = 1;
    _tapGesture.numberOfTouchesRequired = 1;
    
    intensityLevel = 1.0;
    chosenColor = [UIColor whiteColor];
    lastPosition.x = 0;
    lastPosition.y = 0;
    
    // prevents the scroll view from swallowing up the touch event of child buttons
    _tapGesture.cancelsTouchesInView = NO;
    
    //Array for checkmarks in device selection view
    _selectedIndexes = [NSMutableArray new];
    
    
    //Loading the control View based on the type selected (which we get from previous view).
    if (_typeOfEvent == 1) {
        [self loadRequestedTypeView:@"LightViewController"];
    } else if (_typeOfEvent == 2) {
        [self loadRequestedTypeView:@"LightsOnOffViewController"];
    } else if (_typeOfEvent == 3) {
        [self loadRequestedTypeView:@"TemperatureViewController"];
    }
    
    _allDevicesArray = [NSArray new];
    _allDevicesArray = [[CSRAppStateManager sharedInstance].selectedPlace.devices allObjects];
    
    _allDeviceIds = [NSMutableArray new];
    [_allDevicesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CSRDeviceEntity *localDeviceEntity = (CSRDeviceEntity *)obj;
        [_allDeviceIds addObject:localDeviceEntity.deviceId];
    }];
    
    _actionDevicesArray = [NSMutableArray new];
    [_allDevicesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:((CSRDeviceEntity *)obj).deviceId];
        
        if ([device.modelsSet containsObject:@(CSRMeshModelACTION)]) {
            [_actionDevicesArray addObject:device];
        }
    }];

    _selectedDevicesArray = [NSMutableArray new];
    _actionSelectedDevicesArray = [NSMutableArray new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorNotification:) name:@"colorTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(intensityNotification:) name:@"sliderTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOffNotification:) name:@"eventActivation" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(temperatureNotification:) name:@"temperatureIncreased" object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    //Clear Notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"colorTapped" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"sliderTapped" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"eventActivation" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"temperatureIncreased" object:nil];
}


- (void) loadRequestedTypeView:(NSString*)viewControllerIdentifier
{
    
    if ([viewControllerIdentifier isEqualToString:@"LightViewController"]) {
        
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        CSRLightViewController *controlViewController = (CSRLightViewController *)[mainStoryBoard instantiateViewControllerWithIdentifier:viewControllerIdentifier];
        controlViewController.lightDevice = nil;
        [self addChildViewController:controlViewController];
        controlViewController.view.frame = CGRectMake(0, 0, _controlView.frame.size.width, _controlView.frame.size.height - 25);
        [_controlView addSubview:controlViewController.view];
        [controlViewController didMoveToParentViewController:self];
        controlViewController.lightCollectionView.hidden = YES;
        
    } else if ([viewControllerIdentifier isEqualToString:@"LightsOnOffViewController"]) {
        
        UIStoryboard *eventsStoryBoard = [UIStoryboard storyboardWithName:@"Events" bundle:nil];
        CSREventsOnOffVC *controlViewController = (CSREventsOnOffVC *)[eventsStoryBoard instantiateViewControllerWithIdentifier:viewControllerIdentifier];
        [self addChildViewController:controlViewController];
        controlViewController.view.frame = CGRectMake(0, 0, _controlView.frame.size.width, _controlView.frame.size.height - 25);
        [_controlView addSubview:controlViewController.view];
        [controlViewController didMoveToParentViewController:self];

    } else if ([viewControllerIdentifier isEqualToString:@"TemperatureViewController"]) {
        
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        CSRTemperatureViewController *controlViewController = (CSRTemperatureViewController *)[mainStoryBoard instantiateViewControllerWithIdentifier:viewControllerIdentifier];
        [self addChildViewController:controlViewController];
        controlViewController.view.frame = CGRectMake(0, 0, _controlView.frame.size.width, _controlView.frame.size.height - 25);
        [_controlView addSubview:controlViewController.view];
        [controlViewController didMoveToParentViewController:self];
        controlViewController.actualTemperatureLabel.hidden = YES;

    }
    
}

- (void) colorNotification:(NSNotification*)notification {
    
    _eventColor = (UIColor*)notification.userInfo[@"color"];
}

- (void) intensityNotification:(NSNotification*)notification {
    
    _intensityFloat = [notification.userInfo[@"intensity"] floatValue];
}

- (void) onOffNotification:(NSNotification*)notification {
    
    _eventOnOff = [notification.userInfo[@"eventStatus"] boolValue];
}
- (void) temperatureNotification:(NSNotification*)notification {
    
    _eventTemperature = [notification.userInfo[@"temperature"] floatValue];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
   
    CGFloat pageWidth = _eventCreationScrollView.frame.size.width;
    pageNumber = floor((_eventCreationScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    _eventPageControl.currentPage = pageNumber;   
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([tableView isEqual:_devicesListTableView]) {
        return 60.;
    } else if ([tableView isEqual:_timeTableView]) {
        if (indexPath.section == 0) {
            return ([self indexPathHasPicker:indexPath] ? self.pickerCellRowHeight : _timeTableView.rowHeight);
        } else if (indexPath.section == 1) {
            return 60.;
        }
    }
    return 0;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:_devicesListTableView]) {
        if (section == 0) {
            return @"Action Model Support Devices";
        } else if(section == 1){
            return @"All Devices";
        }
    }
    return @"";
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35.;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }
    
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(15, 8, 320, 20);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [CSRUtilities colorFromHex:kColorBlueCSR];
    label.font = [UIFont boldSystemFontOfSize:18];
    label.text = sectionTitle;
    
    UIView *view = [[UIView alloc] init];
    [view addSubview:label];
    
    return view;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if ([tableView isEqual:_devicesListTableView]) {
        return 2;
    } else if ([tableView isEqual:_timeTableView]) {
        return 2;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if ([tableView isEqual:_devicesListTableView]) {
        if (section == 0) {
            return [_actionDevicesArray count];
        } else if(section == 1){
            return [_allDevicesArray count];
        }
        
    } else if ([tableView isEqual:_timeTableView]) {
        if (section == 0) {
            if ([self hasInlineDatePicker]) {
                return 2;
            }
            return 1;

        } else if (section == 1) {
            return 1;
        }
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if ([tableView isEqual:_devicesListTableView]) {
        
        CSREventDevicesCell *Cell = [tableView dequeueReusableCellWithIdentifier:CSREventDevicesCellIdentifier];
        if (!Cell) {
            Cell = [[CSREventDevicesCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSREventDevicesCellIdentifier];
        }
        Cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (indexPath.section == 0) {
            CSRmeshDevice *meshDevice = [_actionDevicesArray objectAtIndex:indexPath.row];
            Cell.deviceImage.image = [CSRmeshStyleKit imageOfLightDevice_on];
            Cell.deviceNameLabel.text = meshDevice.name;
        } else if (indexPath.section == 1) {
            CSRmeshDevice *meshDevice = [_allDevicesArray objectAtIndex:indexPath.row];
            Cell.deviceImage.image = [CSRmeshStyleKit imageOfLightDevice_on];
            Cell.deviceNameLabel.text = meshDevice.name;

        }
        
        return Cell;

    }
    if ([tableView isEqual:_timeTableView] ) {
        if (indexPath.section == 0) {
            
            if ([self indexPathHasPicker:indexPath])
            {
                cell = [tableView dequeueReusableCellWithIdentifier:kDatePickerID];
                
                return cell;
                
            }
            else if ([self indexPathHasDate:indexPath])
            {
                CSREventTimeCell *Cell = [tableView dequeueReusableCellWithIdentifier:CSREventTimeCellIdentifier];
                if (!Cell) {
                    Cell = [[CSREventTimeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSREventTimeCellIdentifier];
                }
                
                NSInteger modelRow = indexPath.row;
                if (self.datePickerIndexPath != nil && self.datePickerIndexPath.row <= indexPath.row)
                {
                    modelRow--;
                }
                NSDictionary *itemData = self.dataArray[modelRow];
                
                Cell.eventTextLabel.text = [itemData valueForKey:kTitleKey];
                Cell.eventDateLabel.text = [self.dateFormatter stringFromDate:[itemData valueForKey:kDateKey]];
                Cell.eventTimeLabel.text = @"";
                return Cell;
                
            }
        }
        if (indexPath.section == 1) {
            CSREventRepeatCell *cell = [tableView dequeueReusableCellWithIdentifier:CSREventRepeatCellIdentifier];
            
            if (!cell) {
                cell = [[CSREventRepeatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSREventRepeatCellIdentifier];
            }
            
            cell.repeatTextLabel.text = LOCALIZEDSTRING(@"Repeat");
            cell.repeatSwitch.enabled = NO;
            
            return cell;
        } else {
            return nil;
        }
        
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:_devicesListTableView]) {
        if (indexPath.section == 0) {
            CSRDeviceEntity *deviceEntity = [_actionDevicesArray objectAtIndex:indexPath.row];
            
            UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
            if ([selectedCell accessoryType] == UITableViewCellAccessoryNone) {
                [selectedCell setAccessoryType:UITableViewCellAccessoryCheckmark];
                [_actionSelectedDevicesArray addObject:deviceEntity.deviceId];
                
            }
            else {
                [selectedCell setAccessoryType:UITableViewCellAccessoryNone];
                [_actionSelectedDevicesArray removeObject:deviceEntity.deviceId];
            }
            
        } else if (indexPath.section == 1) {
            CSRDeviceEntity *deviceEntity = [_allDevicesArray objectAtIndex:indexPath.row];
            
            UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
            
            if ([selectedCell accessoryType] == UITableViewCellAccessoryNone) {
                [selectedCell setAccessoryType:UITableViewCellAccessoryCheckmark];
                [_selectedDevicesArray addObject:deviceEntity.deviceId];
                
            }
            else {
                [selectedCell setAccessoryType:UITableViewCellAccessoryNone];
                [_selectedDevicesArray removeObject:deviceEntity.deviceId];
            }
        }
    
    } else if ([tableView isEqual:_timeTableView]) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell.reuseIdentifier == kCSREventTimeCellIdentifier) {
            
            [self displayInlineDatePickerForRowAtIndexPath:indexPath];
            
        }
        
        if (indexPath.section == 1) {
            
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
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Picker view convienence methods
- (void)toggleDatePickerForSelectedIndexPath:(NSIndexPath *)indexPath
{
    [_timeTableView beginUpdates];
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]];
    
    if ([self hasPickerForIndexPath:indexPath])
    {
        [_timeTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {
        [_timeTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [_timeTableView endUpdates];
}

- (void)displayInlineDatePickerForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_timeTableView beginUpdates];
    
    BOOL before = NO;
    if ([self hasInlineDatePicker])
    {
        before = self.datePickerIndexPath.row < indexPath.row;
    }
    
    BOOL sameCellClicked = (self.datePickerIndexPath.row - 1 == indexPath.row);
    
    if ([self hasInlineDatePicker])
    {
        [_timeTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.datePickerIndexPath.row inSection:0]]
                                       withRowAnimation:UITableViewRowAnimationFade];
        self.datePickerIndexPath = nil;
    }
    
    if (!sameCellClicked)
    {
        NSInteger rowToReveal = (before ? indexPath.row - 1 : indexPath.row);
        NSIndexPath *indexPathToReveal = [NSIndexPath indexPathForRow:rowToReveal inSection:0];
        
        [self toggleDatePickerForSelectedIndexPath:indexPathToReveal];
        self.datePickerIndexPath = [NSIndexPath indexPathForRow:indexPathToReveal.row + 1 inSection:0];
    }
    [_timeTableView deselectRowAtIndexPath:indexPath animated:YES];
    [_timeTableView endUpdates];
    [self updateDatePicker];
}

- (BOOL)hasPickerForIndexPath:(NSIndexPath *)indexPath
{
    BOOL hasDatePicker = NO;
    
    NSInteger targetedRow = indexPath.row;
    targetedRow++;
    
    UITableViewCell *checkDatePickerCell = [_timeTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:targetedRow inSection:0]];
    UIDatePicker *checkDatePicker = (UIDatePicker *)[checkDatePickerCell viewWithTag:kDatePickerTag];
    
    hasDatePicker = (checkDatePicker != nil);
    return hasDatePicker;
}

- (void)updateDatePicker
{
    if (self.datePickerIndexPath != nil)
    {
        UITableViewCell *associatedDatePickerCell = [_timeTableView cellForRowAtIndexPath:self.datePickerIndexPath];
        
        UIDatePicker *targetedDatePicker = (UIDatePicker *)[associatedDatePickerCell viewWithTag:kDatePickerTag];
        if (targetedDatePicker != nil)
        {
//            NSDictionary *itemData = self.dataArray[self.datePickerIndexPath.row - 1];
//            [targetedDatePicker setDate:[itemData valueForKey:kDateKey] animated:NO];
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
    
    if ((indexPath.row == 0) || [self hasInlineDatePicker])
    {
        hasDate = YES;
    }
    
    return hasDate;
}

- (IBAction)dateAction:(id)sender
{
    NSIndexPath *targetedCellIndexPath = nil;
    
    if ([self hasInlineDatePicker])
    {
        targetedCellIndexPath = [NSIndexPath indexPathForRow:self.datePickerIndexPath.row - 1 inSection:0];
    }
    else
    {
        targetedCellIndexPath = [_timeTableView indexPathForSelectedRow];
    }
    
    CSREventTimeCell *cell = [_timeTableView cellForRowAtIndexPath:targetedCellIndexPath];
    UIDatePicker *targetedDatePicker = sender;
    
    NSMutableDictionary *itemData = self.dataArray[targetedCellIndexPath.row];
    [itemData setValue:targetedDatePicker.date forKey:kDateKey];

    cell.eventDateLabel.text = [self.dateFormatter stringFromDate:targetedDatePicker.date];
}



#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"repeatSegue"]) {
        CSREventTimeSelectorVC *vc = segue.destinationViewController;
        vc.popoverPresentationController.delegate = self;
        vc.popoverPresentationController.presentedViewController.view.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        vc.popoverPresentationController.presentedViewController.view.layer.borderWidth = 0.5;
        vc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20., 175.);
        
        vc.eventsDelegate = self;
    }
}

#pragma mark - Helper Methods

- (BOOL)hasEventGotDeviceWithId:(NSNumber *)deviceId
{
    __block BOOL deviceFound = NO;
    
    [_allDevicesArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([((CSRDeviceEntity *)obj).deviceId intValue] == [deviceId intValue]) {
            
            deviceFound = YES;
            
            *stop = YES;
            
        }
        
    }];
    
    return deviceFound;
}



- (IBAction)eventPageControlAction:(id)sender {
    
}

- (IBAction)cancelAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)backAction:(id)sender {
    
    if (pageNumber == 1) {
        [_backButton setEnabled:NO];
        [_eventCreationScrollView setContentOffset:CGPointMake(_firstView.frame.origin.x, 0) animated:YES];
    } else if (pageNumber == 2) {
        [_eventCreationScrollView setContentOffset:CGPointMake(_secondView.frame.origin.x, 0) animated:YES];
    } else if (pageNumber == 3) {
        _nextButon.title = @"Next";
        [_eventCreationScrollView setContentOffset:CGPointMake(_thirdView.frame.origin.x, 0) animated:YES];
    }
}

- (IBAction)nextAction:(id)sender
{
    if (pageNumber == 0) {
        _nextButon.title = @"Next";
        [_backButton setEnabled:YES];
        if (![CSRUtilities isStringEmpty:_eventNameTextField.text]) {
            
            [_eventCreationScrollView setContentOffset:CGPointMake(_secondView.frame.origin.x, 0) animated:YES];
        } else {
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert!!"
                                                                           message:@"Event name should not be empty, please enter a name."
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 // dissmissal of alert completed
                                                             }];
            
            [alert addAction:OKAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else if (pageNumber == 1) {
        _nextButon.title = @"Next";
        //save the devices
        
        [_eventCreationScrollView setContentOffset:CGPointMake(_thirdView.frame.origin.x, 0) animated:YES];
    } else if (pageNumber == 2) {
        _nextButon.title = @"Validate";
        //save the time
        
        [_eventCreationScrollView setContentOffset:CGPointMake(_fourthView.frame.origin.x, 0) animated:YES];
    } else if (pageNumber == 3) {
        
        [self createEvent]; //call the Api's

        [[NSNotificationCenter defaultCenter] postNotificationName:kCSRRefreshNotification object:self userInfo:nil];
        [self.navigationController popViewControllerAnimated:YES];
    }
    [[CSRDatabaseManager sharedInstance] saveContext];
}

- (void) createEvent {
    
    //Check to see if there are devices selected in creation of event
    //Also check to see if the selected devices has atleast one device which has action model enabled.
    __block NSNumber *sourcedeviceId;
    __block NSNumber *targetdeviceId;
    
    if (_actionSelectedDevicesArray.count) {
        
        [_actionSelectedDevicesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            sourcedeviceId = obj;
        }];
        
    } else {
        NSString *errStr = @"None of the selected device has Action Model support";
        [self handleError:errStr];
        return;
    }
    
    if (_selectedDevicesArray.count) {
        
        [_selectedDevicesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            targetdeviceId = obj;
        }];
        
    } else {
        NSString *errStr = @"No target devices";
        [self handleError:errStr];
        return;
    }
    
    CSRMeshAction *meshAction;
    
    if (_typeOfEvent == 1) {
        CGFloat red=0, green=0, blue=0, alpha=0;
        [_eventColor getRed: &red
                      green: &green
                       blue: &blue
                      alpha: &alpha];
        
//        meshAction = [CSRMeshAction initWithLightSetRgb:targetdeviceId
//                                                  level:@(alpha*255)
//                                                    red:@(red*255)
//                                                  green:@(green*255)
//                                                   blue:@(blue*255)
//                                          colorDuration:@1
//                                            acknowledge:NO];

        meshAction = [CSRMeshAction initWithLightSetPowerLevel:targetdeviceId
                                                         power:Off
                                                         level:@100
                                                 levelDuration:@1
                                                       sustain:@1
                                                         decay:@1
                                                   acknowledge:NO];
    } else if (_typeOfEvent == 2) {
        
//        NSInteger powerInt = @(_eventOnOff).integerValue;
        meshAction = [CSRMeshAction initWithPowerSetState:targetdeviceId
                                                    state:On
                                              acknowledge:NO];
        
    } else if (_typeOfEvent == 3) {
        
        CSRsensorValue *sensor = [CSRsensorValue initWithTypeAndValue:(CSRsensorType)3 value:@(0x24a5)];
        meshAction = [CSRMeshAction initWithActuatorSetValue:targetdeviceId
                                                       value:sensor
                                                 acknowledge:NO];
        
    }

//    NSDictionary *itemData = self.dataArray[0];
//    NSDate *selectedDate = [itemData valueForKey:@"date"];

//    NSTimeZone *zone = [NSTimeZone localTimeZone];
//    NSTimeInterval secondsFromGMT = [zone secondsFromGMT];

//    double ac = [selectedDate timeIntervalSince1970] + secondsFromGMT;//seconds
//    NSDate *date = [NSDate dateWithTimeIntervalSince1970:ac];
    
    
//    [[ActionModelApi sharedInstance] getStatus:sourcedeviceId
//                                       success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable actionIds, NSNumber * _Nullable maxActions) {
//                                           
//                                           
//                                           
//                                       } failure:^(NSError * _Nullable error) {
//                                           
//                                           NSLog(@"error :%@", error);
//                                           
//                                       }];

    [[ActionModelApi sharedInstance] getAction:sourcedeviceId
                                      actionId:@1
                                       success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable actionId, CSRMeshAction * _Nullable meshAction, NSNumber * _Nullable timeType, NSNumber * _Nullable time, NSNumber * _Nullable recurringSeconds, NSNumber * _Nullable recurrences) {
                                           NSLog(@"meshAction :%@", meshAction);
                                           
                                       } failure:^(NSError * _Nullable error) {
                                           NSLog(@"error :%@", error);
                                       }];

//    [[ActionModelApi sharedInstance] setAction:sourcedeviceId
//                                      actionId:@1
//                                    meshAction:meshAction
//                           absoluteTriggerTime:date
//                              recurringSeconds:@1000
//                                   recurrences:@1
//                                       success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable actionId) {
//                                           
//                                           NSLog(@"succes on setAction :%@", actionId);
//                                           [self saveEventEntity];
//
//                                       } failure:^(NSError * _Nullable error) {
//                                           NSLog(@"failure on event creation :%@", error);
//                                       }];
//    [[ActionModelApi sharedInstance] setAction:sourcedeviceId
//                                      actionId:@1
//                                    meshAction:meshAction
//                           relativeTriggerTime:@10
//                              recurringSeconds:@10
//                                   recurrences:@1
//                                       success:^(NSNumber * _Nullable deviceId, NSNumber * _Nullable actionId) {
//                                           NSLog(@"succes on setAction :%@", actionId);
//                                           [self saveEventEntity];
//
//                                       } failure:^(NSError * _Nullable error) {
//                                           NSLog(@"failure on event creation :%@", error);
//                                       }];
 }

- (void) saveEventEntity {
    
    CSREventEntity *eventEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSREventEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
    eventEntity.eventName = _eventNameTextField.text;
    eventEntity.eventid = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"CSREventEntity"];
    eventEntity.eventType = @(_typeOfEvent);
    eventEntity.eventActive = [NSNumber numberWithBool:_eventOnOff];
    
    //adding DeviceEntity as relation to EventEntity
    __block CSRDeviceEntity *localdeviceEntity;
    [_selectedDevicesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *localdeviceId = (NSNumber *)obj;
        localdeviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:localdeviceId];
        [eventEntity addDevicesObject:localdeviceEntity];
        
    }];
    
    if (_typeOfEvent == 1) {
        
        NSString *colorName = [CSRUtilities colorNameForRGB:[CSRUtilities rgbFromColor:_eventColor]];
        
        NSMutableData *mutableData = [[NSMutableData alloc] initWithData:[colorName dataUsingEncoding:NSUTF8StringEncoding]];
        float percentFloat = _intensityFloat*100;
        int intensityInt = [[NSNumber numberWithFloat:percentFloat] intValue];
        [mutableData appendBytes:&intensityInt length:1];
        
        eventEntity.eventValue = [mutableData copy];
        
    } else if (_typeOfEvent == 2) {
        
        NSInteger powerInt = @(_eventOnOff).integerValue;
        NSData *data = [NSData dataWithBytes: &powerInt length:1];
        eventEntity.eventValue = data;
        
    } else if (_typeOfEvent == 3) {
        
        NSData *data = [NSData dataWithBytes:&_eventTemperature length:sizeof(_eventTemperature)];
        eventEntity.eventValue = data;
        
    }
    
    if (_repeatBool == NO) {
        eventEntity.eventRepeatType = @(-1);
    } else if (_secondsField){
        eventEntity.eventRepeatType = @(0);
        
    } else if (_weekDaysData) {
        eventEntity.eventRepeatType = @(1);
    }
    
    NSDictionary *itemData = self.dataArray[0];
    
    double timeInMills = [[itemData valueForKey:@"date"] timeIntervalSince1970]*1000;

    NSOperationQueue *eventsOperationQueue = [[NSOperationQueue alloc] init];
    _eventsManager = [[CSREventsManager alloc] initWithData:eventEntity withTimeInMills:timeInMills secondsData:_secondsField weekData:_weekDaysData];
    [eventsOperationQueue addOperation:_eventsManager];
    
    [[CSRAppStateManager sharedInstance].selectedPlace addEventsObject:eventEntity];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
    NSLog(@"Saved action to database");
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRRefreshNotification object:self userInfo:nil];
}
    
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (IBAction)textFieldOutsideTapAction:(id)sender {
    
    [_eventNameTextField resignFirstResponder];
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // Return no adaptive presentation style, use default presentation behaviour
    return UIModalPresentationNone;
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return NO;
}

#pragma mark - Delegate Callbacks

- (void) repeatEverySeconds:(NSNumber *)seconds ofDays:(NSData *)data {
    
    //got the data now save to core data
    _weekDaysData = data;
    _secondsField = seconds;
}


- (IBAction)panAction:(id)sender {
}

- (IBAction)tapAction:(id)sender {
    
    UITapGestureRecognizer *recogniser = sender;
    CGPoint touchPoint = [recogniser locationInView:_colorWheelView.viewForBaselineLayout];
    
    float frameWidth = _colorWheelView.viewForBaselineLayout.frame.size.width;
    float frameHeight = _colorWheelView.viewForBaselineLayout.frame.size.height;
    
    UIColor *pixel = [CSRUtilities colorFromImageAtPoint:&touchPoint frameWidth:frameWidth frameHeight:frameHeight];
    
    CGFloat red, green, blue, alpha;
    if ([pixel getRed:&red green:&green blue:&blue alpha:&alpha] && !(red<0.4 && green<0.4 && blue<0.4)) {
        
        // Send Color to selected light
//        if (_lightDevice) {
//            [_lightDevice setColorWithRed:red green:green blue:blue];
//        }
        
//        chosenColor = pixel;
        
        // update position of inidicator
        touchPoint.x += _colorWheelView.frame.origin.x;
        touchPoint.y += _colorWheelView.frame.origin.y;
        
        [self updateColorIndicatorPosition:touchPoint];
        
        // Update the device's copy of the color position
        //        [_lightDevice setColorPosition:[NSValue valueWithCGPoint:touchPoint]];
        
    }
}

#pragma mark - Color indicator update

- (void)updateColorIndicatorPosition:(CGPoint)position
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [_colorIndicatorView setCenter:position];
    });
    
    [_colorIndicatorView setCenter:position];
    lastPosition = position;
}

- (void)dealloc
{
}

- (void)handleError:(NSString *)errorString
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:errorString
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         // dissmissal of alert completed
                                                     }];
    
    [alert addAction:OKAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL) atLeastOneDeviceHasActionModel {
    
    __block BOOL actionModelFound = NO;
    [_selectedDevicesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:obj];
        
        if ([device.modelsSet containsObject:@(CSRMeshModelACTION)]) {
            actionModelFound = YES;
            *stop = YES;
        }
    }];
    return actionModelFound;
}

@end
