//
//  Floor.m
//  BluetoothAcTEC
//
//  Created by hua on 10/19/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "Floor.h"

@implementation Floor

- (id)init {
    self = [super init];
    
    if (self) {
        _light = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    if (self) {
        self.floorImage = [UIImage imageWithData:[aDecoder decodeObjectForKey:@"com.actec.bluetooth.floorImage"]];
        self.light = [aDecoder decodeObjectForKey:@"com.actec.bluetooth.floorLight"];
        self.layoutSize = [aDecoder decodeCGSizeForKey:@"com.actec.bluetooth.floorLayoutSize"];
        self.floorIndex = [aDecoder decodeObjectForKey:@"com.actec.bluetooth.floorIndex"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:UIImageJPEGRepresentation(self.floorImage, 1.0)  forKey:@"com.actec.bluetooth.floorImage"];
    [aCoder encodeObject:self.light forKey:@"com.actec.bluetooth.floorLight"];
    [aCoder encodeCGSize:self.layoutSize forKey:@"com.actec.bluetooth.floorLayoutSize"];
    [aCoder encodeObject:self.floorIndex forKey:@"com.actec.bluetooth.floorIndex"];
}

-(NSData *)archive {
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

+(Floor *)unArchiveData:(NSData *)data {
    return (Floor *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
}

@end
