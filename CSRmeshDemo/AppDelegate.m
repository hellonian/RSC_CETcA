//
// Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import "CSRDatabaseManager.h"
#import "CSRAppStateManager.h"
#import "CSRUtilities.h"
#import "CSRmeshSettings.h"
#import "CSRMesh/TimeModelApi.h"

//#import "CSRBridgeRoaming.h"
//#import "CSRBluetoothLE.h"
#import <MBProgressHUD.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

static NSString *kLoadDefaultSceneProfile = @"com.actec.kLoadDefaultSceneProfile";
static NSString * const sceneListKey = @"com.actec.bluetooth.sceneListKey";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    
//    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

    NSString *language = [[NSUserDefaults standardUserDefaults] objectForKey:AppLanguageSwitchKey];
    if (!language) {
        NSArray *appLanguages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
        NSString *languageName = [appLanguages objectAtIndex:0];
        NSString *currentLanguage;
        if ([languageName containsString:@"zh-Hans"]) {
            currentLanguage = @"zh-Hans";
        }else {
            currentLanguage = @"en";
        }
        [[NSUserDefaults standardUserDefaults] setObject:currentLanguage forKey:AppLanguageSwitchKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // Set the global cloud host URL
    if ([CSRUtilities getValueFromDefaultsForKey:kCSRGlobalCloudHost]) {
        
        [CSRAppStateManager sharedInstance].globalCloudHost = [CSRUtilities getValueFromDefaultsForKey:kCSRGlobalCloudHost];
        
    } else {
        
        [CSRAppStateManager sharedInstance].globalCloudHost = kCloudServerUrl;
        
    }
    
    // Check if there is a place in DB
    [[CSRAppStateManager sharedInstance] createDefaultPlace];

    // Setup current place to be available from the start
    [[CSRAppStateManager sharedInstance] setupPlace];
    
    [[CSRAppStateManager sharedInstance] switchConnectionForSelectedBearerType:CSRSelectedBearerType_Bluetooth];
    
    // Check for externally passed URL - place import
    if (launchOptions[@"UIApplicationLaunchOptionsURLKey"])
    {
        [self application:application openURL:launchOptions[@"UIApplicationLaunchOptionsURLKey"] options:launchOptions];
    }
    
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
    
    [[UINavigationBar appearance] setTintColor:DARKORAGE];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1]}];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1]];
    
    
    self.mainTabBarController = [[MainTabBarController alloc] init];
    
    MainViewController *mainVC = [[MainViewController alloc] init];
    UINavigationController *mainNav = [[UINavigationController alloc] initWithRootViewController:mainVC];
    
    GalleryViewController *galleryVC = [[GalleryViewController alloc] init];
    UINavigationController *galleryNav = [[UINavigationController alloc] initWithRootViewController:galleryVC];
    
    MoreViewController *moreVC = [[MoreViewController alloc] init];
    
    NSArray *vcs = @[mainNav,galleryNav,moreVC];
    self.mainTabBarController.viewControllers = vcs;
    self.window.rootViewController = self.mainTabBarController;
    
    //全局修改菊花颜色
    [UIActivityIndicatorView appearanceWhenContainedInInstancesOfClasses:@[[MBProgressHUD class]]].color = [UIColor whiteColor];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
//    if ([[CSRBridgeRoaming sharedInstance] numberOfConnectedBridges] == 0) {
//        [[CSRBluetoothLE sharedInstance] startScan];
//    }
    
    // Broadcast time
//    [self broadcastTime];
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    
//    [[CSRDatabaseManager sharedInstance] saveContext];
    [[CSRAppStateManager sharedInstance] connectivityCheck];
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    
//    [[CSRConnectionManager sharedInstance] shutDown];
//    [[CSRDatabaseManager sharedInstance] saveContext];
}

/*
#define SecondsPerHour  3600

-(void)broadcastTime {
    
    // Compute timezone, BST -> GMT=1 | Delhi=+5.5
    
    [[TimeModelApi sharedInstance] broadcastTimeWithCurrentTime:@([[NSDate date] timeIntervalSince1970] * 1000)
                                                       timeZone:@(([[NSTimeZone localTimeZone] secondsFromGMT]) / SecondsPerHour)
                                                     masterFlag:@1];
    
}
*/

@end
