//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRSegmentDevicesViewController.h"
#import "CSRmeshStyleKit.h"
#import "CSRAppStateManager.h"
#import "CSRmeshDevice.h"
#import "CSRDeviceEntity.h"
#import "CSRAreaEntity.h"
#import "CSRDevicesManager.h"
#import "CSRmeshDevice.h"
#import "CSRDevicesManager.h"
#import "CSRUtilities.h"

@interface CSRSegmentDevicesViewController ()

@end

@implementation CSRSegmentDevicesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    CSRmeshArea *area = [[CSRDevicesManager sharedInstance] getAreaFromId:_areaEntity.areaID];
    
    if (area) {
        [[CSRDevicesManager sharedInstance] setSelectedDevice:area.areaDevice];
        [[CSRDevicesManager sharedInstance] setSelectedArea:area];
        
    }
    
    self.segmentSwitch.apportionsSegmentWidthsByContent = YES;
    _devicesMutableArray = [NSMutableArray new];
    [self refreshDevices:nil];
}

- (void)refreshDevices:(id)sender
{
    __block NSUInteger segmentIndex = 0;
    if (_areaEntity) {
        [_devicesMutableArray removeAllObjects];
        
        __block NSMutableDictionary *dict = [NSMutableDictionary new];
        _devicesMutableArray = [[_areaEntity.devices allObjects] mutableCopy];
        
        [_devicesMutableArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
            CSRDeviceEntity *deviceEntity = (CSRDeviceEntity*)obj;
            if ([deviceEntity.appearance isEqual:@(CSRApperanceNameLight)]) {
                [dict setValue:@"LightViewController" forKey:@"light"];
            }
            if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameHeater)]) {
                [dict setValue:@"TemperatureViewController" forKey:@"heater"];
            }
            if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameSensor)]) {
                [dict setValue:@"TemperatureViewController" forKey:@"sensor"];
            }
            if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameSwitch)]) {
                [dict setValue:@"LockViewController" forKey:@"switch"];
            }
            
        }];
        
        
        [self.segmentSwitch removeAllSegments];
        
        if (dict[@"light"]) {
            [self.segmentSwitch insertSegmentWithTitle:@"Light" atIndex:segmentIndex animated:NO];
            segmentIndex++;
        } else if (dict[@"heater"] && dict[@"sensor"]) {
            [self.segmentSwitch insertSegmentWithTitle:@"Heater" atIndex:segmentIndex animated:NO];
            segmentIndex++;
            
            [[SensorModelApi sharedInstance] getValue:_areaEntity.areaID
                                          withSensorType1:CSRsensorType_Desired_Air_Temperature
                                          withSensorType2:CSRsensorType_Unknown
                                              success:^(NSNumber * _Nullable deviceId, NSArray * _Nullable sensors) {
                                                  NSLog(@"DeviceId :%@ and Sensor array :%@", deviceId, sensors);
                                              } failure:^(NSError *error) {
                                                  NSLog(@"ERROR: %@", error);
                                                  
                                              }];
        } else if (dict[@"switch"]) {
            [self.segmentSwitch insertSegmentWithTitle:@"Switch" atIndex:segmentIndex animated:NO];
            segmentIndex++;
        } else {
            NSLog(@"There should be one device or group with heater and sensor");
        }
        if ([dict count] == 1) {
            self.segmentSwitch.hidden = YES;
        }
    }
    
    if (_areaEntity) {
        self.title = _areaEntity.areaName;
        [self.segmentSwitch setSelectedSegmentIndex:0];
        [self segmentSwitchAction:self.segmentSwitch];
    }
}

- (IBAction)segmentSwitchAction:(UISegmentedControl*)sender
{
    //TODO: crash with indexOutOfBounds
    if ([[sender titleForSegmentAtIndex:sender.selectedSegmentIndex] isEqualToString:@"Light"]) {
        
        [self instantiateView:@"LightViewController"];
        
    } else if ([[sender titleForSegmentAtIndex:sender.selectedSegmentIndex] isEqualToString:@"Heater"]) {
        
        [self instantiateView:@"TemperatureViewController"];
        
    } else if ([[sender titleForSegmentAtIndex:sender.selectedSegmentIndex] isEqualToString:@"Switch"]) {
        
        [self instantiateView:@"LockViewController"];
    } else {
        NSLog(@"There should be one device or group with heater and sensor");
    }
}

- (void) instantiateView:(NSString*)viewName
{
    _lightViewController.view = nil;
    _temperatureViewController.view = nil;
    _lockViewController.view = nil;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc1= (UIViewController*)[storyboard instantiateViewControllerWithIdentifier:viewName];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self addChildViewController:vc1];
        vc1.view.frame = CGRectMake(0, 0, _controlView.frame.size.width, _controlView.frame.size.height);
        [_controlView addSubview:vc1.view];
        [vc1 didMoveToParentViewController:self];
    });
}

- (IBAction)backForSelf:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}


@end
