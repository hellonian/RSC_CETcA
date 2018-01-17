//
//  LightSceneBringer.m
//  BluetoothTest
//
//  Created by hua on 6/3/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "LightSceneBringer.h"

@implementation LightSceneBringer

- (instancetype)init {
    self = [super init];
    if (self) {
        _groupMember = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)addLightMember:(NSNumber *)deviceId shortName:(NSString *)shortName poweState:(NSNumber *)state brightness:(NSNumber *)brightness {
    NSDictionary *dic = @{@"shortName":shortName,@"powerState":state,@"brightness":brightness};
    [self.groupMember setObject:dic forKey:deviceId];
}

- (void)removeLightMember:(NSString *)lightAddress {
    [self.groupMember removeObjectForKey:lightAddress];
}

-(NSData *)archive {
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

+(LightSceneBringer *)unArchiveData:(NSData *)data {
    return (LightSceneBringer *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
//        self.sceneImage = [UIImage imageWithData:[aDecoder decodeObjectForKey:@"PrimaryKeySceneImage"]];
        self.sceneImage = [aDecoder decodeIntegerForKey:@"PrimaryKeySceneImage"];
        self.groupMember = [aDecoder decodeObjectForKey:@"PrimaryKeySceneMember"];
        self.profileName = [aDecoder decodeObjectForKey:@"PrimaryKeySceneProfileName"];
        self.sceneId = [aDecoder decodeObjectForKey:@"PrimaryKeySceneId"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
//    [aCoder encodeObject:UIImageJPEGRepresentation(self.sceneImage, 1.0) forKey:@"PrimaryKeySceneImage"];
    [aCoder encodeInteger:self.sceneImage forKey:@"PrimaryKeySceneImage"];
    [aCoder encodeObject:self.groupMember forKey:@"PrimaryKeySceneMember"];
    [aCoder encodeObject:self.profileName forKey:@"PrimaryKeySceneProfileName"];
    [aCoder encodeObject:self.sceneId forKey:@"PrimaryKeySceneId"];
}

-(id)copyWithZone:(NSZone *)zone {
    LightSceneBringer *copy = [[LightSceneBringer alloc] init];
    
    if (copy) {
        copy.sceneImage = self.sceneImage;
        copy.sceneId = [self.sceneId copyWithZone:zone];
        copy.groupMember = [self.groupMember copyWithZone:zone];
    }
    return copy;
}

@end
