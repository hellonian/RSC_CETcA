//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSREventsTableViewController.h"
#import "CSRUtilities.h"
#import "CSRConstants.h"
#import "CSREventsTableViewCell.h"
#import "CSRDevicesManager.h"
#import "CSRmeshStyleKit.h"
#import "CSRDevicesListViewController.h"
#import "CSRNewEventCreationViewController.h"
#import "CSRDatabaseManager.h"
#import "CSREventDetailsViewController.h"
#import "CSREventEditViewController.h"
#import "CSRAppStateManager.h"
#import "CSRMesh/TimeModelApi.h"

@interface CSREventsTableViewController ()

@property (nonatomic, strong) NSMutableArray *eventsArray;
@property (nonatomic, strong) NSMutableArray *colorEventsArray;
@property (nonatomic, strong) NSMutableArray *powerEventsArray;
@property (nonatomic, strong) NSMutableArray *heatingEventsArray;

@property (nonatomic) NSUInteger selectedTypeOfEvent;
@property (nonatomic, retain) CSREventEntity *eventEntity;

@end

@implementation CSREventsTableViewController


- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    _eventsArray = [NSMutableArray new];
    _colorEventsArray = [NSMutableArray new];
    _powerEventsArray = [NSMutableArray new];
    _heatingEventsArray = [NSMutableArray new];
    
    [self fetchEventEntityAndConstructTypeArrays];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView) name:kCSRRefreshNotification object:nil];
    
    _segmentControl.selectedSegmentIndex = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Set navigation bar colour
    self.navigationController.navigationBar.barTintColor = [CSRUtilities colorFromHex:kColorBlueCSR];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationItem.backBarButtonItem = nil;
    
    _eventsTableView.delegate = self;
    _eventsTableView.dataSource = self;
    _eventsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.definesPresentationContext = YES;
    
        //type to pass on to next view
    _selectedTypeOfEvent = 0;
    
    NSTimeInterval timeSince1970 = [[NSDate date] timeIntervalSince1970];
    NSInteger millisecondsSince1970 = timeSince1970 * 1000;
    
    // Compute timezone, GMT=1 for summer time, Delhi=+5.5
    NSTimeZone *zone = [NSTimeZone localTimeZone];
    NSTimeInterval secondsFromGMT = [zone secondsFromGMT];
    float timeZone = secondsFromGMT/3600;
    
    [[TimeModelApi sharedInstance] broadcastTimeWithCurrentTime:@(millisecondsSince1970)
                                                       timeZone:@(timeZone)
                                                     masterFlag:@(1)];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //Clear Notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCSRRefreshNotification object:nil];
}

- (void) fetchEventEntityAndConstructTypeArrays {
    
    _eventsArray = [[[CSRAppStateManager sharedInstance].selectedPlace.events allObjects] mutableCopy];
 
    [_eventsArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        CSREventEntity *eventEntity = (CSREventEntity*)evaluatedObject;
        if ([eventEntity.eventType intValue] == 1) {
            [_colorEventsArray addObject:eventEntity];
        } else if ([eventEntity.eventType intValue] == 2) {
            [_powerEventsArray addObject:eventEntity];
        } else if ([eventEntity.eventType intValue] == 3) {
            [_heatingEventsArray addObject:eventEntity];
        }
        return YES;
    }]];
}

- (void) reloadTableView
{
    _eventsArray = [[[CSRAppStateManager sharedInstance].selectedPlace.events allObjects] mutableCopy];
    [_eventsArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        CSREventEntity *eventEntity = (CSREventEntity*)evaluatedObject;
        if ([eventEntity.eventType intValue] == 1) {
            [_colorEventsArray addObject:eventEntity];
        } else if ([eventEntity.eventType intValue] == 2) {
            [_powerEventsArray addObject:eventEntity];
        } else if ([eventEntity.eventType intValue] == 3) {
            [_heatingEventsArray addObject:eventEntity];
        }
        return YES;
    }]];

    [_eventsTableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   
    if (_segmentControl.selectedSegmentIndex == 0) {
        
        return [_eventsArray count];
        
    } else if (_segmentControl.selectedSegmentIndex == 1) {
        
        return [_colorEventsArray count];
        
    } else if (_segmentControl.selectedSegmentIndex == 2) {

        return [_powerEventsArray count];
        
    } else if (_segmentControl.selectedSegmentIndex == 3) {
        
        return [_heatingEventsArray count];
        
    } else {
        return 0;
    }
}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Remove seperator inset
//    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
//        [cell setSeparatorInset:UIEdgeInsetsZero];
//    }
//    
//    // Prevent the cell from inheriting the Table View's margin settings
//    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
//        [cell setPreservesSuperviewLayoutMargins:NO];
//    }
//    
//    // Explictly set your cell's layout margins
//    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
//        [cell setLayoutMargins:UIEdgeInsetsZero];
//    }
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CSREventsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CSREventsTableViewCellIdentifier];

    if (!cell) {
        cell = [[CSREventsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CSREventsTableViewCellIdentifier];
    }
    if (_eventsArray.count) {
        _eventEntity = [_eventsArray objectAtIndex:indexPath.row];
    }
    cell.eventNameLabel.text = _eventEntity.eventName;
    [cell.onOffSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    NSData *colorData = [_eventEntity.eventValue subdataWithRange:NSMakeRange(0, _eventEntity.eventValue.length - 1)];
    NSData *intensityData = [_eventEntity.eventValue subdataWithRange:NSMakeRange(_eventEntity.eventValue.length - 1, 1)];

   
    if (_segmentControl.selectedSegmentIndex == 0) {
        
        if ([_eventEntity.eventType isEqualToNumber:@1]) {
            cell.eventImageView.image = [CSRmeshStyleKit imageOfColorPalette];
            int intensityInt;
            [intensityData getBytes:&intensityInt length:1];
            cell.eventDetailLabel.text = [NSString stringWithFormat:@"Color %@\rIntensity %i%%", [[NSString alloc] initWithData:colorData encoding:NSUTF8StringEncoding], intensityInt];

        } else if ([_eventEntity.eventType isEqualToNumber:@2]) {
            cell.eventImageView.image = [CSRmeshStyleKit imageOfOnOff];
            NSInteger onOffInt;
            [_eventEntity.eventValue getBytes:&onOffInt length:sizeof(onOffInt)];
            cell.eventDetailLabel.text = [NSString stringWithFormat:@"Turn %@ lights", onOffInt ? @"OFF" : @"ON"];

        } else if ([_eventEntity.eventType isEqualToNumber:@3]) {
            cell.eventImageView.image = [CSRmeshStyleKit imageOfTemperature_off];
            float tempFloat;
            [_eventEntity.eventValue getBytes:&tempFloat length:sizeof(tempFloat)];
            cell.eventDetailLabel.text = [NSString stringWithFormat:@"Set up to %.f", tempFloat];
        }         
        
    } else if (_segmentControl.selectedSegmentIndex == 1) {
        
        cell.eventImageView.image = [CSRmeshStyleKit imageOfColorPalette];
        
        int intensityInt;
        [intensityData getBytes:&intensityInt length:1];
        
        cell.eventDetailLabel.text = [NSString stringWithFormat:@"Color %@\n%i%%", [[NSString alloc] initWithData:colorData encoding:NSUTF8StringEncoding], intensityInt];
        
        
    } else if (_segmentControl.selectedSegmentIndex == 2) {
        
        NSInteger onOffInt;
        [_eventEntity.eventValue getBytes:&onOffInt length:sizeof(onOffInt)];
        cell.eventDetailLabel.text = [NSString stringWithFormat:@"%i", onOffInt ? YES : NO];

        cell.eventImageView.image = [CSRmeshStyleKit imageOfOnOff];
        
    } else if (_segmentControl.selectedSegmentIndex == 3) {
        
        float tempFloat;
        [_eventEntity.eventValue getBytes:&tempFloat length:sizeof(tempFloat)];
        cell.eventDetailLabel.text = [NSString stringWithFormat:@"%f", tempFloat];
        cell.eventImageView.image = [CSRmeshStyleKit imageOfTemperature_off];
        
    } else {
        return nil;
    }
    
    return cell;
}

- (void) switchChanged:(id)sender {
    
    UISwitch* switchControl = sender;
    _eventEntity.eventActive = switchControl.on ? @1 : @0;
    [[CSRDatabaseManager sharedInstance] saveContext];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _eventEntity = [_eventsArray objectAtIndex:indexPath.row];
    
    [self performSegueWithIdentifier:@"eventsDetailSegue" sender:nil];
}

#pragma mark - Alert Control

- (IBAction)showAlertControl:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Add Event"
                                                                   message:@"Which event you want to setup?"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
    alert.popoverPresentationController.barButtonItem = _addEventButton;
    alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionDown;
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * action) {
                                                                                                                          
                                                             
                                                         }];
    UIAlertAction *colorAction = [UIAlertAction actionWithTitle:@"Light Color Event" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  _selectedTypeOfEvent = 1;
                                                                  [self performSegueWithIdentifier:@"newEventSegue" sender:self];
                                                              }];
    UIAlertAction *powerAction = [UIAlertAction actionWithTitle:@"Light Power Event" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             _selectedTypeOfEvent = 2;
                                                             [self performSegueWithIdentifier:@"newEventSegue" sender:self];
                                                         }];
    UIAlertAction *heatingAction = [UIAlertAction actionWithTitle:@"Heating Event" style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                _selectedTypeOfEvent = 3;
                                                                [self performSegueWithIdentifier:@"newEventSegue" sender:self];
                                                            }];
    
    [colorAction setValue:[CSRmeshStyleKit imageOfColorPalette] forKey:@"image"];
    [powerAction setValue:[CSRmeshStyleKit imageOfOnOff] forKey:@"image"];
    [heatingAction setValue:[CSRmeshStyleKit imageOfTemperature_off] forKey:@"image"];
    
    [alert addAction:colorAction];
    [alert addAction:powerAction];
    [alert addAction:heatingAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"newEventSegue"]) {

        CSRNewEventCreationViewController *newEventsCretaionViewController = (CSRNewEventCreationViewController*)segue.destinationViewController;
        newEventsCretaionViewController.typeOfEvent = _selectedTypeOfEvent;
    }
    if ([segue.identifier isEqualToString:@"eventsDetailSegue"]) {
        
        CSREventDetailsViewController *eventsDetailViewController = (CSREventDetailsViewController*)segue.destinationViewController;
        
        if (_eventEntity) {
            eventsDetailViewController.eventEntity = _eventEntity;
        }
    }
    if ([segue.identifier isEqualToString:@"newEventShortcut"]) {
        
        CSREventEditViewController *shortcutVC = (CSREventEditViewController*)segue.destinationViewController;
        shortcutVC.typeOfEvent = _selectedTypeOfEvent;
    }
}


- (IBAction)segmentControlAction:(id)sender {
    
    [_eventsTableView reloadData];
}

@end
