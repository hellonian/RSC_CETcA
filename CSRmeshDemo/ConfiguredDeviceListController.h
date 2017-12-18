//
//  ConfiguredDeviceListController.h
//  BluetoothAcTEC
//
//  Created by hua on 10/15/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "LightClusterViewController.h"

typedef NS_ENUM(NSInteger,SelectMode) {
    Single=0,
    Multiple,
};

typedef void(^ConfiguredDeviceListHandle)(NSArray *selectedDevice);

@interface ConfiguredDeviceListController : LightClusterViewController

@property (nonatomic,assign) BOOL isnewadd;
@property (nonatomic,copy) NSString *fromStr;
- (void)setSelectMode:(SelectMode)mode;
- (void)setSelectDeviceHandle:(ConfiguredDeviceListHandle)handle;

- (void)prepareEditingCurrentSceneProfile:(NSString*)sceneName sceneMemberInfo:(NSDictionary*)sceneMemberInfo isNewAdd:(BOOL)isnewadd image:(NSInteger)image;
@end
