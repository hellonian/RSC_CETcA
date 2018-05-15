//
// Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "MainTabBarController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

//@property (nonatomic) BOOL updateInProgress;
//@property (nonatomic) NSString *updateFileName;
//@property (nonatomic) double updateProgress;

@property (nonatomic,strong) MainTabBarController *mainTabBarController;

@property (strong, atomic) NSNumber *peripheralInBoot;
@property (strong, nonatomic) CBService *targetService;
@property (strong, nonatomic) CBService *devInfoService;
@property (strong, atomic) NSNumber *discoveredChars;
@end


