//
//  TimeSchedule.m
//  BluetoothTest
//
//  Created by hua on 6/12/16.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "TimeSchedule.h"

@implementation TimeSchedule

-(NSData *)archive {
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

+(TimeSchedule *)unArchiveData:(NSData *)data {
    return (TimeSchedule *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.deviceId = [aDecoder decodeObjectForKey:@"PrimaryKeyTimerDeviceId"];
        self.fireDate = [aDecoder decodeObjectForKey:@"PrimaryKeyTimerFireDate"];
        self.lightNickname = [aDecoder decodeObjectForKey:@"PrimaryKeyTimerLightNickname"];
        self.timerIndex = [aDecoder decodeIntegerForKey:@"PrimaryKeyTimerIndex"];
        self.repeat = [aDecoder decodeObjectForKey:@"PrimaryKeyTimerRepeat"];
        self.eveType = [aDecoder decodeObjectForKey:@"PrimaryKeyTimerEveType"];
        self.level = [aDecoder decodeIntegerForKey:@"PrimaryKeyTimerLevel"];
        self.state = [aDecoder decodeBoolForKey:@"PrimaryKeyTimerState"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.deviceId forKey:@"PrimaryKeyTimerDeviceId"];
    [aCoder encodeObject:self.fireDate forKey:@"PrimaryKeyTimerFireDate"];
    [aCoder encodeObject:self.lightNickname forKey:@"PrimaryKeyTimerLightNickname"];
    [aCoder encodeInteger:self.timerIndex forKey:@"PrimaryKeyTimerIndex"];
    [aCoder encodeObject:self.repeat forKey:@"PrimaryKeyTimerRepeat"];
    [aCoder encodeObject:self.eveType forKey:@"PrimaryKeyTimerEveType"];
    [aCoder encodeInteger:self.level forKey:@"PrimaryKeyTimerLevel"];
    [aCoder encodeBool:self.state forKey:@"PrimaryKeyTimerState"];
}

-(id)copyWithZone:(NSZone *)zone {
    TimeSchedule *copy = [[TimeSchedule alloc] init];
    
    if (copy) {
        copy.deviceId = self.deviceId;
        copy.fireDate = [self.fireDate copyWithZone:zone];
        copy.lightNickname = [self.lightNickname copyWithZone:zone];
        copy.timerIndex = self.timerIndex;
        copy.repeat = [self.repeat copyWithZone:zone];
        copy.eveType = [self.eveType copyWithZone:zone];
        copy.level = self.level;
        copy.state = self.state;
    }
    return copy;
}

@end
