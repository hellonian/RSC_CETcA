//
//  LightGroupBringer.m
//  BluetoothTest
//
//  Created by hua on 5/31/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "LightGroupBringer.h"

@implementation LightGroupBringer

- (instancetype)init {
    self = [super init];
    if (self) {
        _groupMember = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)addLightMember:(NSString *)lightAddress {
    [self.groupMember addObject:lightAddress];
}

- (void)removeLightMember:(NSString *)lightAddress {
    [self.groupMember removeObject:lightAddress];
}

-(NSData *)archive {
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

+(LightGroupBringer *)unArchiveData:(NSData *)data {
    return (LightGroupBringer *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.groupImage = [UIImage imageWithData:[aDecoder decodeObjectForKey:@"PrimaryKeyGroupImage"]];
        self.groupMember = [aDecoder decodeObjectForKey:@"PrimaryKeyGroupMember"];
        self.profileName = [aDecoder decodeObjectForKey:@"PrimaryKeyGroupProfileName"];
        self.groupId = [aDecoder decodeObjectForKey:@"PrimaryKeyGroupId"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:UIImageJPEGRepresentation(self.groupImage, 1.0) forKey:@"PrimaryKeyGroupImage"];
    [aCoder encodeObject:self.groupMember forKey:@"PrimaryKeyGroupMember"];
    [aCoder encodeObject:self.profileName forKey:@"PrimaryKeyGroupProfileName"];
    [aCoder encodeObject:self.groupId forKey:@"PrimaryKeyGroupId"];
}

-(id)copyWithZone:(NSZone *)zone {
    LightGroupBringer *copy = [[LightGroupBringer alloc] init];
    if (copy) {
        copy.groupImage = self.groupImage;
        copy.groupId = [self.groupId copyWithZone:zone];
        copy.groupMember = [self.groupMember copyWithZone:zone];
    }
    return copy;
}

@end
