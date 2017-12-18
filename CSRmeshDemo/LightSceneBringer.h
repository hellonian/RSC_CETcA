//
//  LightSceneBringer.h
//  BluetoothTest
//
//  Created by hua on 6/3/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LightSceneBringer : NSObject<NSCoding,NSCopying>
@property (nonatomic,strong) NSMutableDictionary *groupMember;  //different with LightGroupBringer
@property (nonatomic,assign) NSInteger sceneImage;
@property (nonatomic,copy) NSString *profileName;
@property (nonatomic,strong) NSNumber *sceneId;

-(NSData *)archive;
+(LightSceneBringer *)unArchiveData:(NSData *)data;

- (void)addLightMember:(NSNumber *)deviceId shortName:(NSString *)shortName poweState:(NSNumber *)state brightness:(NSNumber *)brightness;
- (void)removeLightMember:(NSString *)lightAddress;

@end
