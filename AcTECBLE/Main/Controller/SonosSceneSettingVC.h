//
//  SonosSceneSettingVC.h
//  AcTECBLE
//
//  Created by AcTEC on 2020/11/2.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface SonosSceneSettingVC : UIViewController

@property (nonatomic, strong) NSNumber *deviceID;
@property (nonatomic, copy) void(^sonosSceneSettingHandle)(NSArray *sModels);

@end

NS_ASSUME_NONNULL_END
