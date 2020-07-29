//
//  SceneViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/6/10.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SceneViewController : UIViewController

@property (nonatomic, strong) NSNumber *sceneIndex;
@property (nonatomic, assign) BOOL forSceneRemote;
@property (nonatomic, assign) NSInteger keyNumber;
@property (nonatomic, assign) NSNumber *srDeviceId;
@property (nonatomic, copy) void (^sceneRemoteHandle)(NSInteger keyNumber, NSInteger sceneIndex);

@end

NS_ASSUME_NONNULL_END
