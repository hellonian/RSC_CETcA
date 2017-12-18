//
//  LightBringer.h
//  BluetoothTest
//
//  Created by hua on 5/18/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LightBringer : NSObject<NSCopying,NSCoding>
@property (nonatomic,assign) BOOL isOnLine;
@property (nonatomic,assign) NSInteger isOpen;
@property (nonatomic,assign) NSInteger rssi;
@property (nonatomic,assign) uint16_t lightAddress;
@property (nonatomic,copy) NSString *macAddress;
@property (nonatomic,copy) NSString *lightName;
@property (nonatomic,copy) NSString *meshName;
@property (nonatomic,strong) NSMutableArray *groupId;
@property (nonatomic,strong) UIImage *lightImage;
@property (nonatomic,assign) BOOL isSwitch;

@end
