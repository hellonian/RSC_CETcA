//
//  SceneViewController.h
//  AcTECBLE
//
//  Created by AcTEC on 2020/6/10.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SceneViewController : UIViewController

@property (nonatomic, strong) NSNumber *sceneIndex;
@property (nonatomic, assign) BOOL forSceneRemote;
@property (nonatomic, assign) NSInteger keyNumber;
@property (nonatomic, assign) NSNumber *srDeviceId;

@end

NS_ASSUME_NONNULL_END
