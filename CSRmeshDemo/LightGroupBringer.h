//
//  LightGroupBringer.h
//  BluetoothTest
//
//  Created by hua on 5/31/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LightGroupBringer : NSObject<NSCoding,NSCopying>
@property (nonatomic,strong) NSMutableArray *groupMember;
@property (nonatomic,strong) UIImage *groupImage;
@property (nonatomic,copy) NSString *profileName;
@property (nonatomic,strong) NSNumber *groupId;

-(NSData *)archive;
+(LightGroupBringer *)unArchiveData:(NSData *)data;

- (void)addLightMember:(NSString *)lightAddress;
- (void)removeLightMember:(NSString *)lightAddress;

@end
