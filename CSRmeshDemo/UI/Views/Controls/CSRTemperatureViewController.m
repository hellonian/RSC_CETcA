//
// Copyright 2014 - 2015 Qualcomm Technologies International, Ltd.
//

// This view is hardwired to display the internal air temperature and to allow the desired temperature to be set.
//
// Sensor Types
//  internal_air_temperature =  1,
//  desired_air_temperature  =  3
//

#import "CSRTemperatureViewController.h"
#import "CSRDevicesManager.h"
#import "CSRUtilities.h"
#import "CSRDatabaseManager.h"
#import "CSRConstants.h"
#import "CSRmeshStyleKit.h"
#import <QuartzCore/QuartzCore.h>
#import "CSRBluetoothLE.h"

@implementation CSRTemperatureViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (!_selectedArea.desiredTemperatureSetByUser)
        _selectedArea.desiredTemperatureSetByUser = @(kCSR_AirTemp_Default);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView) name:SENSOR_VALUE_CHANGED object:nil];
}



- (void)viewDidDisappear:(BOOL)animated {
    // Disable continuous scan
    [[CSRBluetoothLE sharedInstance]setScanner:NO source:self];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    _backButton = [[UIBarButtonItem alloc] init];
    _backButton.image = [CSRmeshStyleKit imageOfBack_arrow];
    _backButton.action = @selector(back:);
    _backButton.target = self;
    
    [super addCustomBackButtonItem:_backButton];
}


//============================================================================
-(void) viewDidAppear:(BOOL)animated
{
    // Enable continuous scan
    [[CSRBluetoothLE sharedInstance]setScanner:YES source:self];
    
    _selectedDevice = [[CSRDevicesManager sharedInstance] selectedDevice];
    _selectedArea = [[CSRDevicesManager sharedInstance] selectedArea];
    
    
    if (_selectedArea) {
        NSString *title = [_selectedArea areaName];
        self.title = title;
    }
    else if (_selectedDevice) {
        NSString *title = [_selectedDevice name];
        self.title = title;
    }
    else
        self.title = @"CSRmesh";
    
    [self.upButton setBackgroundImage:[CSRmeshStyleKit imageOfArrow_up] forState:UIControlStateNormal];
    [self.downButton setBackgroundImage:[CSRmeshStyleKit imageOfArrow_down] forState:UIControlStateNormal];

    
//    [self updateActualTemperatureValue];
    [self refreshView];
}

//============================================================================
// Add observers for selected area so that view components are automatically refreshed when the underlying property changes
-(void) createObserversForSelectedGroup {
    // create observer for actual temperature, refresh view if it changes
    if (_selectedArea) {
        [_selectedArea addObserver:self
                        forKeyPath:@"currentTemperature"
                           options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                           context:NULL];
        
        [_selectedArea addObserver:self
                        forKeyPath:@"desiredTemperatureAcknowledged"
                           options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                           context:NULL];
    }
}

//============================================================================
// Remove observers
-(void) removeObserversForSelectedGroup {
    [_selectedArea.currentTemperature removeObserver:self forKeyPath:@"currentTemperature"];
    [_selectedArea.desiredTemperatureAcknowledged removeObserver:self forKeyPath:@"desiredTemperatureAcknowledged"];
}

//============================================================================
// Update View
// Display actual temperature, if available
// Display desired temperature, set to 20 degrees initially, display in orange while unconfirmed
-(void)  refreshView {
    UIColor *textColor = [UIColor lightGrayColor];
    if (_selectedArea) {
        NSString *actualTemp;
        if (_selectedArea.currentTemperature) {
            float temp = [_selectedArea.currentTemperature floatValue];
            actualTemp = [NSString stringWithFormat:@"%0.1f",temp];
        }
        else {
            actualTemp = @"--.-";
        }
        _actualTemperatureLabel.text = [NSString stringWithFormat:@"Actual: %@ °C", actualTemp];
        
        NSString *desiredTemp;
        if (_selectedArea.desiredTemperatureSetByUser) {
            float temp = [_selectedArea.desiredTemperatureSetByUser floatValue];
            desiredTemp = [NSString stringWithFormat:@"%0.1f",temp];
        }
        else {
            desiredTemp = @"--.-";
        }
        _desiredTemperatureLabel.text = [NSString stringWithFormat:@"%@ °C",desiredTemp];
        
        if (_selectedArea.desiredTemperatureSetByUser) {
            if (!_selectedArea.desiredTemperatureAcknowledged || ![_selectedArea.desiredTemperatureSetByUser isEqualToNumber:_selectedArea.desiredTemperatureAcknowledged]) {
                textColor = [UIColor BACKGROUND_HIGHLIGHT];
            }
        }
    }
    else {
        _actualTemperatureLabel.text = [NSString stringWithFormat:@"Actual: %@ °C",  @"--.-"];
        _desiredTemperatureLabel.text = @"--.-";
    }
    
    _desiredTemperatureText.textColor = textColor;
}



//============================================================================
// KVO observer for groups->current temperature
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if ([keyPath isEqualToString:@"currentTemperature"]) {
        [self refreshView];
        _actualTemperatureLabel.text = [NSString stringWithFormat:@"Actual: %@ °C",  [change valueForKey:@"new"]];
        
    }
    else if ([keyPath isEqualToString:@"isDesiredTemperatureAcknowledged"]) {
        _desiredTemperatureLabel.backgroundColor = [UIColor whiteColor];
        _desiredTemperatureLabel.textColor = [UIColor blackColor];
    }
}

//============================================================================
// Set the desired temperature for the group and call a mesh command
-(void) setDesiredTemperatureForCurrentArea :(float) desiredTemperature {
    if (_selectedArea) {
        NSNumber *temperature = @(desiredTemperature);
        if (![_selectedArea.desiredTemperatureSetByUser isEqualToNumber:temperature]) {
            _selectedArea.desiredTemperatureSetByUser = temperature;
            [[CSRDevicesManager sharedInstance] setDesiredTemperatureForArea:_selectedArea];
        }
    }
    [self refreshView];
}


//============================================================================
// Increment the temperature by 0.5 for this group, ceiling is 30.0
- (IBAction)increaseTemperature:(id)sender
{
    float temperature = kCSR_AirTemp_Default;
    if (_selectedArea) {
        if (_selectedArea.desiredTemperatureSetByUser) {
            temperature = [_selectedArea.desiredTemperatureSetByUser floatValue];
            if (temperature < kCSR_AirTemp_MAX) {
                temperature += 0.5;
                if (temperature > kCSR_AirTemp_MAX)
                    temperature = kCSR_AirTemp_MAX;
            }
            else
                return;
        }
        [self setDesiredTemperatureForCurrentArea:temperature];
    }
    
    NSDictionary* userInfo = @{@"temperature": @(temperature)};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"temperatureIncreased" object:self userInfo:userInfo];

}

//============================================================================
// Decrement the temperature by 0.5 for this group, floor is 5.0
- (IBAction)decreaseTemperature:(id)sender
{
    float temperature = kCSR_AirTemp_Default;
    if (_selectedArea) {
        if (_selectedArea.desiredTemperatureSetByUser) {
            temperature = [_selectedArea.desiredTemperatureSetByUser floatValue];
            if (temperature > kCSR_AirTemp_MIN) {
                temperature -= 0.5;
                if (temperature < kCSR_AirTemp_MIN)
                    temperature = kCSR_AirTemp_MIN;
            }
            else
                return;
        }
        [self setDesiredTemperatureForCurrentArea:temperature];
    }
}

//- (IBAction)getSensorValueAction:(id)sender
//{
//    [[SensorModelApi sharedInstance] getValue:_selectedArea.areaNumber
//                                  sensorType1:@(1) sensorType2:@(2)
//                                      success:^(NSNumber *deviceId, NSDictionary *sensors) {
//                                          NSLog(@"deviceId :%@ and sensors :%@", deviceId, sensors);
//                                      } failure:^(NSError *error) {
//                                          NSLog(@"Error :%@", error);
//                                      }];
//}

#pragma mark - Actions

- (IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
