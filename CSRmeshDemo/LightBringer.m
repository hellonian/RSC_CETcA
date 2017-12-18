//
//  LightBringer.m
//  BluetoothTest
//
//  Created by hua on 5/18/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "LightBringer.h"

@interface LightBringer ()
@end

@implementation LightBringer

- (instancetype)init {
    self = [super init];
    if (self) {
        _isOnLine = NO;
        _isOpen = 0;
        _rssi = 0;
        _lightAddress = 0;
        _groupId = [[NSMutableArray alloc] init];
        _macAddress = [[NSString alloc]init];
        _lightName = [[NSString alloc]init];
        _meshName = [[NSString alloc]init];
        _lightImage = [UIImage imageNamed:@"light_image_default.png"];
        _isSwitch = NO;
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.isOnLine = [aDecoder decodeBoolForKey:@"PrimaryKeyIsOnline"];
        self.isOpen = [aDecoder decodeIntegerForKey:@"PrimaryKeyIsOpen"];
        self.rssi = [aDecoder decodeIntegerForKey:@"PrimaryKeyRSSI"];
        self.lightAddress = [[aDecoder decodeObjectForKey:@"PrimaryKeyLightAddress"] unsignedShortValue];
        self.macAddress = [aDecoder decodeObjectForKey:@"PrimaryKeyMacAddress"];
        self.lightName = [aDecoder decodeObjectForKey:@"PrimaryKeyLightName"];
        self.meshName = [aDecoder decodeObjectForKey:@"PrimaryKeyMeshName"];
        self.groupId = [aDecoder decodeObjectForKey:@"PrimaryKeyOwnToGroup"];
        self.lightImage = [UIImage imageWithData:[aDecoder decodeObjectForKey:@"PrimaryKeyLightImage"]];
        self.isSwitch = [aDecoder decodeBoolForKey:@"PrimaryKeyIsSwitch"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:self.isOnLine forKey:@"PrimaryKeyIsOnline"];
    [aCoder encodeInteger:self.isOpen forKey:@"PrimaryKeyIsOpen"];
    [aCoder encodeInteger:self.rssi forKey:@"PrimaryKeyRSSI"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedShort:self.lightAddress] forKey:@"PrimaryKeyLightAddress"];
    [aCoder encodeObject:self.macAddress forKey:@"PrimaryKeyMacAddress"];
    [aCoder encodeObject:self.lightName forKey:@"PrimaryKeyLightName"];
    [aCoder encodeObject:self.meshName forKey:@"PrimaryKeyMeshName"];
    [aCoder encodeObject:self.groupId forKey:@"PrimaryKeyOwnToGroup"];
    [aCoder encodeObject:UIImageJPEGRepresentation(self.lightImage, 1.0) forKey:@"PrimaryKeyLightImage"];
    [aCoder encodeBool:self.isSwitch forKey:@"PrimaryKeyIsSwitch"];
}

-(id)copyWithZone:(NSZone *)zone {
    LightBringer *copy = [[LightBringer alloc] init];
    if (copy) {
        copy.isOnLine = self.isOnLine;
        copy.isOpen = self.isOpen;
        copy.rssi = self.rssi;
        copy.lightAddress = self.lightAddress;
        copy.groupId = [self.groupId copyWithZone:zone];
        copy.lightImage = self.lightImage;
        copy.macAddress = [self.macAddress copyWithZone:zone];
        copy.lightName = [self.lightName copyWithZone:zone];
        copy.meshName = [self.meshName copyWithZone:zone];
        copy.isSwitch = self.isSwitch;
    }
    return copy;
}

@end
