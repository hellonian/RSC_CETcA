//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSREventsManager.h"
#import "CSRmesh/ActionModelApi.h"
#import "CSRDeviceEntity.h"
#import "CSRDatabaseManager.h"
#import "CSRDeviceEventsEntity.h"
#import "CSRAppStateManager.h"

#define DAYINMILLISECONDS 24*60*60*1000
#define MilliSecondsPerHour  3600000
#define MilliSeconds 1000

@interface CSREventsManager ()

@property (nonatomic, strong) CSREventEntity *eventEntity;
@property (nonatomic) double timeInMills;
@property (nonatomic, strong) NSNumber *secondsField;
@property (nonatomic, strong) NSData *weekDaysData;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation CSREventsManager

- (instancetype)initWithData:(CSREventEntity *)eEntity withTimeInMills:(double)time secondsData:(NSNumber *)secondsField weekData:(NSData *)weekField
{
    self = [super init];
    if (self != nil)
    {
        _eventEntity = eEntity;
        _timeInMills = time;
        _secondsField = secondsField;
        _weekDaysData = weekField;
    }
    return self;
}

- (void)main
{
    __block NSInteger actionid = 1;
    for (CSRDeviceEntity *deviceEntity in _eventEntity.devices) {
       
        if ([_eventEntity.eventRepeatType isEqualToNumber:@(-1)]) {
            
            CSRDeviceEventsEntity *deviceEventEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRDeviceEventsEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
            
            deviceEventEntity.deviceID = deviceEntity.deviceId;
            deviceEventEntity.deviceEventID = _eventEntity.eventid;
            deviceEventEntity.actionID = @(actionid);
            actionid++;
            
            deviceEventEntity.eventTime = [NSNumber numberWithDouble:_timeInMills];
            deviceEventEntity.eventRepeatMills = @0;
            [_eventEntity addDeviceEventsObject:deviceEventEntity];
            
        } else if ([_eventEntity.eventRepeatType isEqualToNumber:@(0)]) {
            
            CSRDeviceEventsEntity *deviceEventEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRDeviceEventsEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
            
            deviceEventEntity.deviceID = deviceEntity.deviceId;
            deviceEventEntity.deviceEventID = _eventEntity.eventid;
            deviceEventEntity.actionID = @(actionid);
            actionid++;
            
            
            deviceEventEntity.eventTime = [NSNumber numberWithDouble:_timeInMills];
            double secondsGap = [_secondsField doubleValue];
            double secondsGapInMills = secondsGap*1000;
            deviceEventEntity.eventRepeatMills = [NSNumber numberWithDouble:secondsGapInMills];
            [_eventEntity addDeviceEventsObject:deviceEventEntity];
            
        } else if ([_eventEntity.eventRepeatType isEqualToNumber:@(1)]) {
            
            NSMutableArray *weekDaysArray = nil;
            if(_weekDaysData) {
                const uint8_t *bytes = [_weekDaysData bytes];
                weekDaysArray = [NSMutableArray array];
                
                for (int i = 0; i < _weekDaysData.length; i++) {
                    [weekDaysArray  addObject:@(*bytes++)];
                }
            }
            self.dateFormatter = [NSDateFormatter new];
            [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [self.dateFormatter setDateFormat:@"EE"];
            
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:(_timeInMills/ MilliSeconds)];
            NSString *dayString = [self.dateFormatter stringFromDate:date];
            
            NSMutableDictionary *weekDayDict = [NSMutableDictionary new];
            for (int i = 0; i < weekDaysArray.count; i++) {
                
                [weekDayDict setValue:weekDaysArray[i] forKey:[self weekDayString:i]];
            }
            
            double weekInMills = 7 * DAYINMILLISECONDS;
            NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:@[@"Mon",@"Tue",@"Wed",@"Thu",@"Fri",@"Sat",@"Sun"]];
            
            [weekDayDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                
                if ([(NSNumber *)obj integerValue] == 1) {
                    CSRDeviceEventsEntity *deviceEventEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRDeviceEventsEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
                    
                    deviceEventEntity.deviceID = deviceEntity.deviceId;
                    deviceEventEntity.deviceEventID = _eventEntity.eventid;
                    deviceEventEntity.actionID = @(actionid);
                    actionid++;
                    
                    
                    NSUInteger indexOfCurrentDay = [orderedSet indexOfObject:dayString]; //present day
                    NSUInteger indexOfActiveDay = [orderedSet indexOfObject:key]; //day where flag is 1
                    
                    
                    if (indexOfActiveDay == indexOfCurrentDay) {
                        deviceEventEntity.eventTime = [NSNumber numberWithDouble:_timeInMills];
                        deviceEventEntity.eventRepeatMills = [NSNumber numberWithDouble:weekInMills];
                        
                    } else  {
                        
                        NSUInteger valueToAdd = (7 - indexOfCurrentDay) + indexOfActiveDay;
                        NSTimeInterval futureTime = valueToAdd * DAYINMILLISECONDS;
                        deviceEventEntity.eventTime = [NSNumber numberWithDouble:_timeInMills];
                        deviceEventEntity.eventRepeatMills = [NSNumber numberWithDouble:futureTime];
                        
                    }
                    [_eventEntity addDeviceEventsObject:deviceEventEntity];
                }
            }];
        }
    }
}

- (NSString *) weekDayString:(NSInteger)value {
    NSString *dayString;
    if (value == 0) {
        dayString = @"Mon";
    } else if (value == 1) {
        dayString = @"Tue";
    } else if (value == 2) {
        dayString = @"Wed";
    } else if (value == 3) {
        dayString = @"Thu";
    } else if (value == 4) {
        dayString = @"Fri";
    } else if (value == 5) {
        dayString = @"Sat";
    } else if (value == 6) {
        dayString = @"Sun";
    }
    return dayString;
}

@end
