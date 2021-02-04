//
//  SonosSceneSettingVC.h
//  AcTECBLE
//
//  Created by AcTEC on 2020/11/2.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SonosSelectModel.h"


NS_ASSUME_NONNULL_BEGIN

@interface SonosSceneSettingVC : UIViewController

@property (nonatomic, strong) NSNumber *deviceID;
@property (nonatomic, copy) void(^sonosSceneSettingHandle)(NSArray *sModels);
@property (nonatomic, assign) NSInteger source;
@property (nonatomic, strong) NSArray *sModels;

@end

NS_ASSUME_NONNULL_END
